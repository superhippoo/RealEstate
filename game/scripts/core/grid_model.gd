class_name GridModel
## 방 하나의 논리 그리드 상태: 가구 배치, 충돌, 회전 footprint, interaction cell.
## 순수 로직(노드 아님) — 헤드리스 단위테스트 대상.
## 1 cell = 25cm (06_house_grid.md)
## 배치 레이어(06 §14): FLOOR(일반 가구) / WALL(벽걸이 — 벽면 행만, FLOOR와 무충돌) /
## UNDERLAY(러그 — 아무것도 차단하지 않음, FLOOR 아래에 그려짐)

enum Layer { FLOOR, WALL, UNDERLAY }

var width: int
var height: int
var _occupied_floor := {}   # Vector2i -> instance_id
var _occupied_wall := {}   # Vector2i -> instance_id
var placements := {}
var next_instance_id := 1


class Placement:
	var instance_id: int
	var def_id: String
	var def_w: int
	var def_h: int
	var origin: Vector2i
	var rotation: int  # 0/90/180/270
	var layer: int     # GridModel.Layer

	func _init(p_id: int, p_def: String, p_w: int, p_h: int, p_origin: Vector2i, p_rot: int, p_layer: int) -> void:
		instance_id = p_id
		def_id = p_def
		def_w = p_w
		def_h = p_h
		origin = p_origin
		rotation = p_rot
		layer = p_layer


func _init(p_width: int = 16, p_height: int = 12) -> void:
	width = p_width
	height = p_height


static func footprint_size(def_w: int, def_h: int, rotation: int) -> Vector2i:
	if rotation == 90 or rotation == 270:
		return Vector2i(def_h, def_w)
	return Vector2i(def_w, def_h)


func _map_for(layer: int) -> Dictionary:
	return _occupied_wall if layer == Layer.WALL else _occupied_floor


## 배치 가능 검사. layer별 규칙:
## - FLOOR: 그리드 내 + FLOOR끼리 무충돌
## - WALL: 벽면 행(gx==0 또는 gy==0 변) + WALL끼리 무충돌
## - UNDERLAY: 그리드 내이면 항상 가능(충돌 없음)
func can_place(def_w: int, def_h: int, origin: Vector2i, rotation: int, layer: int = Layer.FLOOR, ignore_instance := -1) -> bool:
	var fp := footprint_size(def_w, def_h, rotation)
	if origin.x < 0 or origin.y < 0 or origin.x + fp.x > width or origin.y + fp.y > height:
		return false
	if layer == Layer.UNDERLAY:
		return true
	if layer == Layer.WALL:
		# 두 후면 벽(gx=0 변 / gy=0 변)에만 부착 가능
		if origin.x != 0 and origin.y != 0:
			return false
	var occ := _map_for(layer)
	for x in range(origin.x, origin.x + fp.x):
		for y in range(origin.y, origin.y + fp.y):
			var occupant: int = occ.get(Vector2i(x, y), -1)
			if occupant != -1 and occupant != ignore_instance:
				return false
	return true


func place(def_id: String, def_w: int, def_h: int, origin: Vector2i, rotation: int, layer: int = Layer.FLOOR) -> int:
	if not can_place(def_w, def_h, origin, rotation, layer):
		return -1
	var id := next_instance_id
	next_instance_id += 1
	var p := Placement.new(id, def_id, def_w, def_h, origin, rotation, layer)
	placements[id] = p
	_mark(p, id)
	return id


func move(instance_id: int, origin: Vector2i, rotation: int) -> bool:
	if not placements.has(instance_id):
		return false
	var p: Placement = placements[instance_id]
	if not can_place(p.def_w, p.def_h, origin, rotation, p.layer, instance_id):
		return false
	_mark(p, -1)
	p.origin = origin
	p.rotation = rotation
	_mark(p, instance_id)
	return true


func remove(instance_id: int) -> void:
	if not placements.has(instance_id):
		return
	var p: Placement = placements[instance_id]
	_mark(p, -1)
	placements.erase(instance_id)


func get_placement(instance_id: int) -> Placement:
	return placements.get(instance_id)


## 경로찾기 장애물(FLOOR만 통행 차단)
func occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for key in _occupied_floor.keys():
		cells.append(key)
	return cells


func cells_of(instance_id: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var p := get_placement(instance_id)
	if p == null:
		return cells
	var fp := footprint_size(p.def_w, p.def_h, p.rotation)
	for x in range(p.origin.x, p.origin.x + fp.x):
		for y in range(p.origin.y, p.origin.y + fp.y):
			cells.append(Vector2i(x, y))
	return cells


## 로컬 상대좌표(정의 기준, 회전 전)를 회전/원점 적용해 방 좌표로 변환.
static func local_to_room(origin: Vector2i, local: Vector2i, def_w: int, def_h: int, rotation: int) -> Vector2i:
	match rotation:
		0:
			return origin + local
		90:
			return origin + Vector2i(def_h - 1 - local.y, local.x)
		180:
			return origin + Vector2i(def_w - 1 - local.x, def_h - 1 - local.y)
		270:
			return origin + Vector2i(local.y, def_w - 1 - local.x)
		_:
			return origin + local


func _mark(p: Placement, value: int) -> void:
	if p.layer == Layer.UNDERLAY:
		return  # 러그는 점유 맵에 기록하지 않음
	var occ := _map_for(p.layer)
	var fp := footprint_size(p.def_w, p.def_h, p.rotation)
	for x in range(p.origin.x, p.origin.x + fp.x):
		for y in range(p.origin.y, p.origin.y + fp.y):
			var key := Vector2i(x, y)
			if value == -1:
				occ.erase(key)
			else:
				occ[key] = value
