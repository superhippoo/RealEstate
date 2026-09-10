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
var sprite: TextureRect
var bubble: Label
var bubble_bg: PanelContainer

var state := "idle"                   # idle / walking / using
var path: Array[Vector2i] = []
var path_idx := 0
var use_action: Dictionary = {}
var use_target_fid := ""
var use_iid := -1
var use_timer := 0.0
var recent_actions: Array[String] = []
var force_fid := ""                   # 새로 배치한 가구 즉시 사용
var idle_timer := 1.0
var bob_t := 0.0
var astar: AStarGrid2D


func setup(p_flow: Node) -> void:
	flow = p_flow
	tex_idle = load("res://assets/gpt_sprites/c_idle.png")
	tex_walk = load("res://assets/gpt_sprites/c_walk.png")

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


func _resize(w: float) -> void:
	var h: float = w * tex_idle.get_height() / tex_idle.get_width()
	sprite.size = Vector2(w, h)
	sprite.position = Vector2(-w * 0.5, -h)   # 발 중심 앵커
	sprite.pivot_offset = sprite.size * 0.5   # 회전은 스프라이트 중심 기준


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
	sprite.position.y = -sprite.size.y + sin(bob_t * 12.0) * 2.5   # 걷기 바운스


func _start_using() -> void:
	state = "using"
	sprite.texture = tex_idle
	sprite.position.y = -sprite.size.y
	# 누운 포즈(침대): 실제 렌더된 가구 스프라이트 rect 중앙에 몸이 얹히도록
	if use_action.get("pose") == "lie" and use_iid >= 0 and flow.placed_nodes.has(use_iid):
		var bed_rect: Rect2 = flow.placed_nodes[use_iid].get_rect()
		var hh: float = sprite.size.y
		# 중심 피벗 회전 → 몸통 중심 = position + (0, -hh/2) 를 침대 중앙에 맞춤
		position = bed_rect.get_center() + Vector2(8, hh * 0.5 - 12)
	use_timer = float(use_action["dur"])
	bubble.text = use_action["label"]
	bubble_bg.visible = true
	_bubble_follow()
	action_started.emit(use_action["label"])


func _bubble_follow() -> void:
	# 캐릭터 몸통 위쪽에 항상 위치 (누운 포즈 포함)
	bubble_bg.position = Vector2(-bubble_bg.size.x * 0.5, -sprite.size.y - 36)


func _use_step(delta: float) -> void:
	use_timer -= delta
	_bubble_follow()
	# 사용 중 미세 몸짓
	if use_action.get("pose") == "sit":
		sprite.scale = Vector2(1.0, 0.94)
	elif use_action.get("pose") == "lie":
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, 90.0, 0.25)
		sprite.scale = Vector2(1.3, 1.3)   # 누운 포즈 가독성
	else:
		sprite.position.y = -sprite.size.y + sin(bob_t * 3.0) * 1.0
	if use_timer <= 0:
		_finish_using()


func _finish_using() -> void:
	sprite.scale = Vector2.ONE
	sprite.rotation_degrees = 0.0
	bubble_bg.visible = false
	var eff: Dictionary = {
		"energy": int(use_action.get("energy", 0)),
		"stress": int(use_action.get("stress", 0)),
		"happiness": int(use_action.get("happiness", 0)),
	}
	action_finished.emit(eff)
	recent_actions.append(use_action["action"])
	if recent_actions.size() > 3:
		recent_actions.pop_front()
	use_target_fid = ""
	use_action = {}
	state = "idle"
	idle_timer = 1.2


func _begin_next_action() -> void:
	var pick := _pick_action()
	if pick.is_empty():
		idle_timer = 2.0
		# 갈 곳 없으면 방 안 배회 (07§10)
		if IDLE_WANDER:
			var cell := Vector2i(randi() % flow.grid.width, randi() % flow.grid.height)
			if not astar.is_point_solid(cell):
				use_action = ACTIONS["LOOK"].duplicate()
				use_target_fid = ""
				_walk_to(cell)
		return
	use_action = ACTIONS[pick["action"]].duplicate()
	use_target_fid = pick["fid"]
	use_iid = int(pick["iid"])
	_walk_to(pick["cell"])
