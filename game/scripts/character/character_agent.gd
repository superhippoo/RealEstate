extends Sprite2D
## 캐릭터 자율생활 v0 (07_character_life.md의 MVP 축소판)
## 상태 → 행동 후보 → 경로 → 이동 → 포즈 → 대기 → 반복
## 조작 대상이 아니라 스스로 살아가는 모습을 보여주는 관찰 대상.

const WALK_SPEED := 2.6          # cells/sec
const USE_DURATION := 5.0        # 가구 사용 시간 (초)
const IDLE_THINK_TIME := 1.2

var main  # Main 참조 (grid/economy/db 접근)
var grid_pos := Vector2i(6, 8)   # 현재 셀
var _path: Array[Vector2i] = []
var _state := "IDLE"             # IDLE / WALK / USING
var _timer := 0.0
var _anim_timer := 0.0
var _anim_frame := 0
var _using_action := ""
var _last_furniture_id := -1     # 반복 방지 v0
var _facing := 1                 # 0:E 1:S 2:W 3:N

static var godot_scale := 1.0
static var _ai_char_tex: Texture2D
static var _ai_char_scale := 1.0
static var _ai_char_checked := false


static func _load_ai_char() -> void:
	if _ai_char_checked:
		return
	_ai_char_checked = true
	var tex := load("res://assets/ai_sprites/char.png")
	if tex:
		_ai_char_tex = tex
		var f := FileAccess.open("res://assets/ai_sprites/manifest.json", FileAccess.READ)
		var target_h := 340.0
		if f:
			var m = JSON.parse_string(f.get_as_text())
			if m is Dictionary and m.has("char") and m["char"].has("target_h"):
				target_h = float(m["char"]["target_h"])
		_ai_char_scale = target_h / float(tex.get_height())


func setup(p_main) -> void:
	main = p_main
	FurnitureSprite.load_manifest()
	godot_scale = FurnitureSprite.godot_scale
	_load_ai_char()
	if _ai_char_tex:
		scale = Vector2(_ai_char_scale, _ai_char_scale)
	else:
		scale = Vector2(godot_scale, godot_scale)
	centered = true
	_refresh_pos()
	_set_texture("char_idle_%d" % _facing)


func _refresh_pos() -> void:
	position = IsoProjector.gridf_to_screen(grid_pos.x + 0.5, grid_pos.y + 0.5)
	z_index = int(position.y)


func _process(delta: float) -> void:
	_anim_timer += delta
	match _state:
		"IDLE":
			_timer -= delta
			if _timer <= 0.0:
				_decide()
		"WALK":
			_walk_step(delta)
		"USING":
			_timer -= delta
			if _timer <= 0.0:
				_end_use()


# ---------------------------------------------------------------- 행동 선택
func _decide() -> void:
	var candidates: Array = []  # [instance_id, interaction_cell, action]
	for iid in main.grid.placements.keys():
		if iid == _last_furniture_id and main.grid.placements.size() > 1:
			continue
		var p: GridModel.Placement = main.grid.placements[iid]
		var def: Dictionary = main.db.get_def(p.def_id)
		for local in def["interaction_locals"]:
			var cell := GridModel.local_to_room(p.origin, Vector2i(local[0], local[1]),
					p.def_w, p.def_h, p.rotation)
			if _cell_walkable(cell):
				candidates.append([iid, cell, def["action"]])
	if candidates.is_empty():
		_wander()
		return
	var pick: Array = candidates[randi() % candidates.size()]
	_last_furniture_id = pick[0]
	_using_action = pick[2]
	_goto(pick[1])


func _wander() -> void:
	# 가구가 없거나 접근 불가 → 빈집 배회 (07 §22 '빈 집' 연출)
	for i in 12:
		var cell := Vector2i(randi() % main.grid.width, randi() % main.grid.height)
		if _cell_walkable(cell):
			_using_action = ""
			_goto(cell)
			return
	_timer = IDLE_THINK_TIME


func _cell_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= main.grid.width or cell.y >= main.grid.height:
		return false
	return not main.astar.is_point_solid(cell)


func _goto(target: Vector2i) -> void:
	var path: Array[Vector2i] = main.astar.get_id_path(grid_pos, target)
	_path.clear()
	for c in path:
		if c != grid_pos:
			_path.append(c)
	if _path.is_empty():
		if target == grid_pos:
			_arrive()
		else:
			_state = "IDLE"
			_timer = IDLE_THINK_TIME
		return
	_state = "WALK"
	_set_texture("char_walk_%d_%d" % [_facing, 0])


# ---------------------------------------------------------------- 이동
func _walk_step(delta: float) -> void:
	if _path.is_empty():
		_arrive()
		return
	var next: Vector2i = _path[0]
	var target := IsoProjector.gridf_to_screen(next.x + 0.5, next.y + 0.5)
	var step := WALK_SPEED * delta * Vector2(IsoProjector.TILE_WIDTH * 0.5, IsoProjector.TILE_HEIGHT).length()
	var to_target := target - position
	if to_target.length() <= step:
		grid_pos = next
		_path.remove_at(0)
		_refresh_pos()
		if _path.is_empty():
			_arrive()
	else:
		position += to_target.normalized() * step
		_facing = _dir_from_delta(next - grid_pos)
		z_index = int(position.y)
		if _anim_timer > 0.22:
			_anim_timer = 0.0
			_anim_frame = 1 - _anim_frame
			_set_texture("char_walk_%d_%d" % [_facing, _anim_frame])


func _dir_from_delta(d: Vector2i) -> int:
	if d.x >= d.y and d.x >= -d.y:
		return 0  # E
	if d.y >= d.x and d.y >= -d.x:
		return 1  # S
	if d.x <= d.y and d.x <= -d.y:
		return 2  # W
	return 3      # N


func _arrive() -> void:
	_refresh_pos()
	_start_use()


# ---------------------------------------------------------------- 가구 사용
func _start_use() -> void:
	if _using_action == "":
		_state = "IDLE"
		_timer = IDLE_THINK_TIME
		_set_texture("char_idle_%d" % _facing)
		return
	_state = "USING"
	_timer = USE_DURATION
	match _using_action:
		"SLEEP":
			_set_texture("char_lie_0")
			# 침대 위로 올라간 위치 연출
			var p: GridModel.Placement = main.grid.get_placement(_last_furniture_id)
			if p:
				var fp := GridModel.footprint_size(p.def_w, p.def_h, p.rotation)
				position = IsoProjector.gridf_to_screen(p.origin.x + fp.x / 2.0, p.origin.y + fp.y / 2.0)
				z_index = int(position.y) + 1
		"REST", "SIT", "WATCH_TV":
			_set_texture("char_sit_270")
		"STUDY":
			_set_texture("char_sit_270")
		_:
			_set_texture("char_idle_%d" % _facing)


func _end_use() -> void:
	_refresh_pos()
	_state = "IDLE"
	_timer = 0.4
	_set_texture("char_idle_%d" % _facing)


# ---------------------------------------------------------------- 이동 중 장애물 재계산
func notify_grid_changed() -> void:
	if _state == "WALK" and not _path.is_empty():
		var next: Vector2i = _path[0]
		if not _cell_walkable(next):
			_path.clear()
			_state = "IDLE"
			_timer = 0.2


func _set_texture(path: String) -> void:
	# AI 캐릭터가 있으면 단일 스프라이트 사용(포즈 전환은 후속 과제)
	if _ai_char_tex:
		texture = _ai_char_tex
		return
	var tex := load("res://assets/sprites/%s.png" % path)
	if tex:
		texture = tex
