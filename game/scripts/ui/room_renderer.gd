extends Node2D
## 방 바닥(다이아몬드 셀) + 후면 벽 2면을 그리는 렌더러.
## 컷어웨이 스타일: gx=0(북) / gy=0(서) 변에 낮은 벽.
## 논리 그리드는 GridModel이 소유하며 이 노드는 표현만 담당.

var grid: GridModel
var wall_height_px := 1.15 * 589.0  # 1.15m 벽, 세로 px/m ≈ 지면 px/m * 1.154 (2:1 iso)

# 컨셉 팔레트
const FLOOR_BASE := Color(0.847, 0.659, 0.424)   # 허니우드
const FLOOR_VAR := 0.045
const WALL_N := Color(0.937, 0.878, 0.745)
const WALL_W := Color(0.898, 0.827, 0.678)
const WALL_TOP := Color(0.780, 0.702, 0.553)
const HIGHLIGHT_OK := Color(0.61, 0.69, 0.38, 0.45)   # 세이지
const HIGHLIGHT_BAD := Color(0.85, 0.35, 0.25, 0.45)

## 배치 모드 하이라이트 셀 (origin, footprint, rotation)
var preview_origin: Vector2i = Vector2i(-1, -1)
var preview_fp: Vector2i = Vector2i.ZERO
var preview_valid := false
var preview_active := false


func _draw() -> void:
	if grid == null:
		return
	_draw_walls()
	_draw_floor()
	_draw_preview()


func _draw_floor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for x in range(grid.width):
		for y in range(grid.height):
			var poly := IsoProjector.cell_polygon()
			var offset := IsoProjector.grid_to_screen(x, y)
			var c := FLOOR_BASE.darkened(rng.randf_range(-FLOOR_VAR, FLOOR_VAR))
			# 셀 테두리(타일 감)
			var pts := PackedVector2Array()
			for p in poly:
				pts.append(p + offset)
			draw_colored_polygon(pts, c)
			draw_polyline(pts, FLOOR_BASE.darkened(0.12), 1.5)


func _wall_quad(origin: Vector2i, dir_x: int, dir_y: int, length_cells: int, color: Color) -> void:
	## 후면 벽 한 변: 바닥 변에서 위로 세워진 사각형
	var a := IsoProjector.grid_to_screen(origin.x, origin.y)
	var b := IsoProjector.grid_to_screen(origin.x + dir_x * length_cells, origin.y + dir_y * length_cells)
	var pts := PackedVector2Array([
		a,
		b,
		b + Vector2(0, -wall_height_px),
		a + Vector2(0, -wall_height_px),
	])
	draw_colored_polygon(pts, color)
	draw_polyline(PackedVector2Array([a, b, b + Vector2(0, -wall_height_px), a + Vector2(0, -wall_height_px)]),
			WALL_TOP, 3.0)


func _draw_walls() -> void:
	# 서쪽 벽 (gy=0 변, x 0→width) — 화면 좌상단 사선
	_wall_quad(Vector2i(0, 0), 1, 0, grid.width, WALL_W)
	# 북쪽 벽 (gx=0 변, y 0→height)
	_wall_quad(Vector2i(0, 0), 0, 1, grid.height, WALL_N)


func set_preview(origin: Vector2i, fp: Vector2i, valid: bool) -> void:
	preview_origin = origin
	preview_fp = fp
	preview_valid = valid
	preview_active = true
	queue_redraw()


func clear_preview() -> void:
	preview_active = false
	queue_redraw()


func _draw_preview() -> void:
	if not preview_active:
		return
	for x in range(preview_origin.x, preview_origin.x + preview_fp.x):
		for y in range(preview_origin.y, preview_origin.y + preview_fp.y):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				continue
			var offset := IsoProjector.grid_to_screen(x, y)
			var pts := PackedVector2Array()
			for p in IsoProjector.cell_polygon():
				pts.append(p + offset)
			draw_colored_polygon(pts, HIGHLIGHT_OK if preview_valid else HIGHLIGHT_BAD)
