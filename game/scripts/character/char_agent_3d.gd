extends Node3D
## 3D 캐릭터 에이전트 — glTF 모델 + 걷기/idle 애니메이션 + 그리드 경로 이동

const CELL := 0.25
const WALK_SPEED := 2.4  # cells/sec

var main
var grid_pos := Vector2i(6, 8)
var _path: Array[Vector2i] = []
var _state := "IDLE"
var _timer := 0.0
var _last_furniture_id := -1
var _using_action := ""
var _target_yaw := 0.0

var anim: AnimationPlayer
var _walk_name := ""
var _idle_name := ""


func cell_world(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5) * CELL, 0, (c.y + 0.5) * CELL)


func setup(p_main) -> void:
	main = p_main
	var model: Node = load("res://assets/models/char.glb").instantiate()
	add_child(model)
	anim = _find_anim(model)
	if anim:
		for name in anim.get_animation_list():
			if "walk" in name:
				_walk_name = name
			elif "idle" in name:
				_idle_name = name
	position = cell_world(grid_pos)
	if anim and _idle_name:
		anim.play(_idle_name)


func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r = _find_anim(c)
		if r:
			return r
	return null


func _process(delta: float) -> void:
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
	# 부드러운 회전
	rotation.y = lerp_angle(rotation.y, _target_yaw, delta * 10.0)


func _decide() -> void:
	var candidates: Array = []
	for iid in main.grid.placements.keys():
		if iid == _last_furniture_id and main.grid.placements.size() > 1:
			continue
		var p: GridModel.Placement = main.grid.placements[iid]
		var def: Dictionary = main.db.get_def(p.def_id)
		for local in def["interaction_locals"]:
			var cell := GridModel.local_to_room(p.origin, Vector2i(local[0], local[1]),
					p.def_w, p.def_h, p.rotation)
			if main.cell_walkable(cell):
				candidates.append([iid, cell, def["action"]])
	if candidates.is_empty():
		_wander()
		return
	var pick: Array = candidates[randi() % candidates.size()]
	_last_furniture_id = pick[0]
	_using_action = pick[2]
	_goto(pick[1])


func _wander() -> void:
	for i in 12:
		var cell := Vector2i(randi() % main.ROOM_W, randi() % main.ROOM_H)
		if main.cell_walkable(cell):
			_using_action = ""
			_goto(cell)
			return
	_timer = 1.2


func _goto(target: Vector2i) -> void:
	if target == grid_pos:
		_arrive()
		return
	var path = main.astar.get_id_path(grid_pos, target)
	_path.clear()
	for c in path:
		if c != grid_pos:
			_path.append(c)
	if _path.is_empty():
		_state = "IDLE"
		_timer = 1.0
		return
	_state = "WALK"
	if anim and _walk_name != "":
		anim.play(_walk_name)


func _walk_step(delta: float) -> void:
	if _path.is_empty():
		_arrive()
		return
	var next: Vector2i = _path[0]
	var target := cell_world(next)
	var step := WALK_SPEED * CELL * delta
	var to_target := target - position
	to_target.y = 0
	if to_target.length() <= step:
		grid_pos = next
		_path.remove_at(0)
		position = target
		if _path.is_empty():
			_arrive()
	else:
		position += to_target.normalized() * step
		_target_yaw = atan2(to_target.x, to_target.z)


func _arrive() -> void:
	_start_use()


func _start_use() -> void:
	if _using_action == "":
		_state = "IDLE"
		_timer = 0.8
		if anim and _idle_name != "":
			anim.play(_idle_name)
		return
	_state = "USING"
	_timer = 5.0
	if anim and _idle_name != "":
		anim.play(_idle_name)


func _end_use() -> void:
	_state = "IDLE"
	_timer = 0.5


func notify_grid_changed() -> void:
	if _state == "WALK" and not _path.is_empty():
		var next: Vector2i = _path[0]
		if not main.cell_walkable(next):
			_path.clear()
			_state = "IDLE"
			_timer = 0.2
