extends Node2D
## 캐릭터 자율생활 에이전트 (07§10-13) — A* 걷기 + 가구 사용 + 행동 말풍선.
## 부모(concept_flow)가 제공: grid, furniture placements, grid_to_screen(), spawn_floaty()

signal action_started(label: String)
signal action_finished(effects: Dictionary)   # {"energy":+x, "stress":-y, "happiness":+z, "label":...}

const WALK_SPEED := 95.0        # 화면 px/s
const IDLE_WANDER := true

# 가구 action → 생활행동 정의 (07§9/§15)
const ACTIONS := {
	"SLEEP":    {"label": "Zzz… 잠자는 중", "dur": 10.0, "pose": "lie",
				"energy": 25, "stress": -10, "happiness": 2},
	"REST":     {"label": "소파에서 늘어져 쉬는 중", "dur": 8.0, "pose": "sit",
				"energy": 8, "stress": -12, "happiness": 4},
	"WATCH_TV": {"label": "TV 보는 중", "dur": 8.0, "pose": "sit",
				"energy": 3, "stress": -7, "happiness": 8},
	"STUDY":    {"label": "책상에서 업무 중", "dur": 8.0, "pose": "sit",
				"energy": -5, "stress": 3, "happiness": 2},
	"SIT":      {"label": "앉아서 쉬는 중", "dur": 5.0, "pose": "sit",
				"energy": 4, "stress": -4, "happiness": 1},
	"LOOK":     {"label": "러그 위에서 스트레칭", "dur": 4.0, "pose": "stand",
				"energy": 2, "stress": -2, "happiness": 1},
	"CARE":     {"label": "식물에 물 주는 중", "dur": 5.0, "pose": "stand",
				"energy": -2, "stress": -5, "happiness": 4},
}

var flow: Node                        # concept_flow 레퍼런스
var tex_idle: Texture2D
var tex_walk: Texture2D
var walk_frames: Array[Texture2D] = []
var tex_sit: Texture2D
var tex_lie: Texture2D
var sprite: TextureRect
var bubble: Label
var bubble_bg: PanelContainer

var base_width := 70.0                # 캐릭터 화면 폭 (텍스처 교체시 유지)
var state := "idle"                   # idle / walking / using
var step_t := 0.0                     # 스텝 애니메이션 타이머
var walk_frame := false               # true=걷기폰(다리벌림) false=기립(다리모음)
const STEP_INTERVAL := 0.14           # 스텝 주기(초)
var path: Array[Vector2i] = []
var path_idx := 0
var use_action: Dictionary = {}
var use_target_fid := ""
var use_iid := -1
var use_timer := 0.0
var use_base_sprite_y := 0.0
var recent_actions: Array[String] = []
var force_fid := ""                   # 새로 배치한 가구 즉시 사용
var idle_timer := 1.0
var bob_t := 0.0
var astar: AStarGrid2D


func setup(p_flow: Node) -> void:
	flow = p_flow
	tex_idle = load("res://assets/gpt_sprites/c_idle.png")
	tex_walk = load("res://assets/gpt_sprites/c_walk.png")
	for i in 4:
		var t: Texture2D = load("res://assets/gpt_sprites/c_walk_%d.png" % i)
		if t:
			walk_frames.append(t)
	tex_sit = load("res://assets/gpt_sprites/c_sit.png")
	tex_lie = load("res://assets/gpt_sprites/c_lie.png")

	sprite = TextureRect.new()
	sprite.texture = tex_idle
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sprite)

	bubble_bg = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.99, 0.95, 0.95)
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12; sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 4; sb.content_margin_bottom = 4
	bubble_bg.add_theme_stylebox_override("panel", sb)
	add_child(bubble_bg)
	bubble = Label.new()
	bubble.add_theme_font_override("font", load("res://assets/fonts/NotoSansKR.ttf"))
	bubble.add_theme_font_size_override("font_size", 14)
	bubble.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	bubble_bg.add_child(bubble)
	bubble_bg.visible = false

	_rebuild_astar()


## 텍스처 교체 (캐릭터 폭 유지, 발중심 앵커 유지)
func _apply_texture(tex: Texture2D) -> void:
	sprite.texture = tex
	var h: float = base_width * tex.get_height() / tex.get_width()
	sprite.size = Vector2(base_width, h)
	sprite.position = Vector2(-base_width * 0.5, -h)
	sprite.pivot_offset = sprite.size * 0.5


func _resize(w: float) -> void:
	base_width = w
	_apply_texture(sprite.texture if sprite.texture else tex_idle)


func place_at_cell(cell: Vector2i) -> void:
	position = flow.grid_to_screen(cell)
	_resize(flow.char_width_px())


## 가구 배치 변경 시 재호출 — 통행 맵 갱신 (06§12: FLOOR 레이어만 벽)
func _rebuild_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, flow.grid.width, flow.grid.height)
	astar.cell_size = Vector2.ONE
	astar.update()
	for gy in flow.grid.height:
		for gx in flow.grid.width:
			astar.set_point_solid(Vector2i(gx, gy), false)
	for iid in flow.grid.placements:
		var p = flow.grid.placements[iid]
		if p.layer != flow.GridModel.Layer.FLOOR:
			continue    # 러그(UNDERLAY)/벽(WALL)은 통행 가능
		var fp: Vector2i = flow.GridModel.footprint_size(p.def_w, p.def_h, p.rotation)
		for x in range(p.origin.x, p.origin.x + fp.x):
			for y in range(p.origin.y, p.origin.y + fp.y):
				astar.set_point_solid(Vector2i(x, y), true)


func on_furniture_changed() -> void:
	_rebuild_astar()


## 새로 배치한 가구는 즉시 사용 (구매→생활변화 즉시 체감)
func notify_new_furniture(fid: String) -> void:
	force_fid = fid
	if state == "idle":
		_begin_next_action()
	elif state == "walking" and use_action.get("action") == "LOOK":
		_begin_next_action()   # 배회 중이라면 새 가구 사용으로 즉시 전환


# ---------------------------------------------------------------- 행동 선택 (07§11 가중치)
func _available_actions() -> Array:
	var out: Array = []
	for iid in flow.grid.placements:
		var p = flow.grid.placements[iid]
		var action_name: String = flow.furniture_action(p.def_id)
		if not ACTIONS.has(action_name):
			continue
		var cell: Vector2i = flow.interaction_cell_for(iid)
		if cell.x < 0:
			continue
		out.append({"fid": p.def_id, "action": action_name, "cell": cell, "iid": iid})
	return out


func _pick_action() -> Dictionary:
	var avail := _available_actions()
	if avail.is_empty():
		return {}
	# 강제 대상 (새 가구)
	if not force_fid.is_empty():
		for a in avail:
			if a["fid"] == force_fid:
				force_fid = ""
				return a
		force_fid = ""
	# 가중치 (07§11: 스탯 기반)
	var best: Dictionary = {}
	var best_w := -1.0
	for a in avail:
		var act: Dictionary = ACTIONS[a["action"]]
		var w := 10.0
		match a["action"]:
			"SLEEP": w = 8.0 + (100.0 - flow.gs.energy) * 0.6
			"REST": w = 6.0 + flow.gs.stress * 0.35
			"WATCH_TV": w = 8.0 + (100.0 - flow.gs.stress) * 0.15
			"STUDY": w = 12.0 if (flow.gs.energy > 50 and flow.gs.stress < 60) else 2.0
			"CARE": w = 7.0
		if force_recent(a["action"]):
			w *= 0.15
		if a["fid"] == use_target_fid:
			w *= 0.3
		w *= randf() * 0.5 + 0.75
		if w > best_w:
			best_w = w
			best = a
	return best


func force_recent(action_name: String) -> bool:
	return action_name in recent_actions


# ---------------------------------------------------------------- 이동
func _walk_to(cell: Vector2i) -> bool:
	var from: Vector2i = flow.screen_to_cell(Vector2(position.x, position.y))
	if from.x < 0:
		from = Vector2i(0, 0)
	var p := astar.get_id_path(from, cell)
	if p.is_empty():
		# 직선 근접 강제 (막힌 경우 상호작용 접근 불가 처리: 06§12 완화)
		p = [cell]
	path = []
	for c in p:
		path.append(c)
	path_idx = 0
	state = "walking"
	step_t = 0.0
	walk_frame = true
	sprite.texture = tex_walk
	return true


func _process(delta: float) -> void:
	if flow == null or not is_visible_in_tree():
		return
	bob_t += delta
	flow._sort_with_agent()   # 이동/사용 중 y 변화를 z에 반영
	match state:
		"idle":
			idle_timer -= delta
			if idle_timer <= 0:
				_begin_next_action()
		"walking":
			_walk_step(delta)
		"using":
			_use_step(delta)


func _walk_step(delta: float) -> void:
	if path_idx >= path.size():
		_start_using()
		return
	var target: Vector2 = flow.grid_to_screen(path[path_idx])
	var speed := WALK_SPEED
	var d: float = position.distance_to(target)
	if d < speed * delta + 1.0:
		position = target
		path_idx += 1
		return
	var dir := (target - position) / d
	position += dir * speed * delta
	sprite.flip_h = dir.x < 0
	# 2프레임 스텝: 걷기폰(다리벌림) ↔ 기립(다리모음) 교대 + 스텝마다 살짝 점프
	step_t += delta
	if walk_frames.size() == 4:
		var idx := int(step_t / STEP_INTERVAL) % 4
		sprite.texture = walk_frames[idx]
		sprite.position.y = -sprite.size.y - (3.0 if idx % 2 == 1 else 0.0)
	else:
		if step_t >= STEP_INTERVAL:
			step_t -= STEP_INTERVAL
			walk_frame = not walk_frame
		sprite.texture = tex_walk if walk_frame else tex_idle
		sprite.position.y = -sprite.size.y - (3.0 if walk_frame else 0.0)


func _start_using() -> void:
	state = "using"
	walk_frame = false
	_apply_texture(tex_idle)
	sprite.position.y = -sprite.size.y
	# 포즈별 전용 스프라이트 — 앉음(c_sit)은 스프라이트에 소파가 통째로 박혀 있어
	# '유령 소파'처럼 보이는 문제로 사용 중단. 앉음 행동도 누움(c_lie: 사람만)으로
	# 처리해 가구 위에 늘어져 쉬는 연출로 통일 (말풍선 텍스트와도 일치).
	if tex_lie and (use_action.get("pose") == "lie" or use_action.get("pose") == "sit"):
		_apply_texture(tex_lie)
		sprite.position.y = -sprite.size.y * 0.5   # 누운 몸 중심이 앵커에 오게
		# 가구(침대/소파 등) 스프라이트 rect 중앙 위에 몸이 얹히도록
		if use_iid >= 0 and flow.placed_nodes.has(use_iid):
			var fur_rect: Rect2 = flow.placed_nodes[use_iid].get_rect()
			position = fur_rect.get_center() + Vector2(0, -10)
	use_timer = float(use_action["dur"])
	bubble.text = use_action["label"]
	bubble_bg.visible = true
	use_base_sprite_y = sprite.position.y
	_bubble_follow()
	action_started.emit(use_action["label"])


func _bubble_follow() -> void:
	# 캐릭터 몸통 위쪽에 항상 위치 + 화면 상단(HUD)과 겹치지 않게 클램프
	var by: float = -sprite.size.y - 36.0
	bubble_bg.position = Vector2(-bubble_bg.size.x * 0.5, maxf(by, 150.0 - position.y))


func _use_step(delta: float) -> void:
	use_timer -= delta
	_bubble_follow()
	# 사용 중 호흡 — 기준 높이에서 절대값 진동(눈에 보이는 폭, 드리프트 없음)
	sprite.position.y = use_base_sprite_y + sin(bob_t * 3.0) * 1.6
	if use_timer <= 0:
		_finish_using()


func _finish_using() -> void:
	var eff: Dictionary = {
		"energy": int(use_action.get("energy", 0)),
		"stress": int(use_action.get("stress", 0)),
		"happiness": int(use_action.get("happiness", 0)),
	}
	var act_name := str(use_action.get("action", ""))
	# 상태 복구를 최우선: 이후 처리에서 에러가 나도 캐릭터가 using에 갇히지 않게
	_apply_texture(tex_idle)
	sprite.scale = Vector2.ONE
	sprite.rotation_degrees = 0.0
	bubble_bg.visible = false
	use_target_fid = ""
	use_action = {}
	state = "idle"
	idle_timer = 1.2
	action_finished.emit(eff)
	if not act_name.is_empty():
		recent_actions.append(act_name)
		if recent_actions.size() > 3:
			recent_actions.pop_front()


func _begin_next_action() -> void:
	var pick := _pick_action()
	if pick.is_empty():
		idle_timer = 2.0
		# 갈 곳 없으면 방 안 배회 (07§10)
		if IDLE_WANDER:
			var cell := Vector2i(randi() % flow.grid.width, randi() % flow.grid.height)
			if not astar.is_point_solid(cell):
				use_action = ACTIONS["LOOK"].duplicate()
				use_action["action"] = "LOOK"   # _finish_using의 recent_actions 기록용
				use_target_fid = ""
				_walk_to(cell)
		return
	use_action = ACTIONS[pick["action"]].duplicate()
	use_action["action"] = pick["action"]   # ACTIONS 항목엔 이 키가 없으므로 명시 저장
	use_target_fid = pick["fid"]
	use_iid = int(pick["iid"])
	_walk_to(pick["cell"])
