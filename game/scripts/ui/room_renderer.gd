extends Node2D
## 방 바닥(우드 플랭크) + 후면 벽 2면 + 걸레받이 + 창문 렌더러 v2
## 논리 그리드는 GridModel이 소유하며 이 노드는 표현만 담당.

var grid: GridModel
var wall_height_px := 380.0   # ≈1.15m (인게인 세로 px/m ≈ 330)

# 컨셉 팔레트
const FLOOR_BASE := Color(0.847, 0.659, 0.424)   # 허니우드
const FLOOR_SEAM := Color(0.66, 0.48, 0.30)
const WALL_N := Color(0.937, 0.878, 0.745)
const WALL_W := Color(0.905, 0.838, 0.694)
const WALL_TOP := Color(0.824, 0.741, 0.588)
const BASEBOARD := Color(0.725, 0.541, 0.310)
const WINDOW_GLOW := Color(1.0, 0.965, 0.88)
const WINDOW_FRAME := Color(0.725, 0.541, 0.310)
const HIGHLIGHT_OK := Color(0.61, 0.69, 0.38, 0.45)
const HIGHLIGHT_BAD := Color(0.85, 0.35, 0.25, 0.45)

var preview_origin: Vector2i = Vector2i(-1, -1)
var preview_fp: Vector2i = Vector2i.ZERO
var preview_valid := false
var preview_active := false

var _rng := RandomNumberGenerator.new()


func _draw() -> void:
	if grid == null:
		return
	_rng.seed = 20260905
	_draw_floor()
	_draw_walls()


func _corner(gx: float, gy: float) -> Vector2:
	return Vector2((gx - gy) * IsoProjector.TILE_WIDTH * 0.5,
			(gx + gy) * IsoProjector.TILE_HEIGHT * 0.5)


# ---------------------------------------------------------------- 바닥: 플랭크
func _draw_floor() -> void:
	var plank_len := 4  # 셀 단위
	for y in range(grid.height):
		var stagger := (y * 2) % plank_len
		var x := -stagger
		while x < grid.width:
			var x0 := maxi(x, 0)
			var x1 := mini(x + plank_len, grid.width)
			if x1 > x0:
				var shade := _rng.randf_range(-0.05, 0.05)
				var c := FLOOR_BASE.darkened(shade)
				# 벽 인접 AO
				if y == 0 or x0 == 0:
					c = c.darkened(0.06)
				var pts := PackedVector2Array([
					_corner(x0, y), _corner(x1, y), _corner(x1, y + 1), _corner(x0, y + 1)])
				draw_colored_polygon(pts, c)
				# 플랭크 세로 이음선
				draw_line(_corner(x1, y), _corner(x1, y + 1), FLOOR_SEAM, 1.5)
			x += plank_len
		# 행 이음선
		draw_line(_corner(0, y), _corner(grid.width, y), FLOOR_SEAM, 2.0)
	# 외곽 라인
	var outline := PackedVector2Array([
		_corner(0, 0), _corner(grid.width, 0), _corner(grid.width, grid.height), _corner(0, grid.height)])
	draw_polyline(outline, FLOOR_SEAM.darkened(0.15), 2.5)
	_draw_preview()


# ---------------------------------------------------------------- 벽/창문
func _wall_quad(origin: Vector2i, dir: Vector2i, length_cells: int, color_bottom: Color, color_top: Color) -> void:
	var a := _corner(origin.x, origin.y)
	var b := _corner(origin.x + dir.x * length_cells, origin.y + dir.y * length_cells)
	var h := wall_height_px
	# 정점 색 그라디언트 (아래 밝게 → 위 살짝 어둡게)
	draw_polygon(PackedVector2Array([a, b, b + Vector2(0, -h), a + Vector2(0, -h)]),
			PackedColorArray([color_bottom, color_bottom, color_top, color_top]))
	draw_line(a, b, BASEBOARD, 14.0)  # 걸레받이
	draw_line(a + Vector2(0, -h), b + Vector2(0, -h), WALL_TOP, 5.0)
	draw_line(a, a + Vector2(0, -h), WALL_TOP, 3.0)
	draw_line(b, b + Vector2(0, -h), WALL_TOP, 3.0)


func _draw_walls() -> void:
	_wall_quad(Vector2i(0, 0), Vector2i(0, 1), grid.height, WALL_W, WALL_W.darkened(0.10))
	_wall_quad(Vector2i(0, 0), Vector2i(1, 0), grid.width, WALL_N, WALL_N.darkened(0.10))
	_draw_window(Vector2i(0, 3), 5)  # 서쪽 벽(y축) 중앙에 창문


func _draw_window(origin: Vector2i, width_cells: int) -> void:
	var h := wall_height_px
	var win_h := h * 0.62
	var y_off := h * 0.16
	var a := _corner(origin.x, origin.y)
	var b := _corner(origin.x, origin.y + width_cells)
	# 창 프레임(바깥)
	var outer := PackedVector2Array([
		a + Vector2(0, -y_off - win_h), b + Vector2(0, -y_off - win_h),
		b + Vector2(0, -y_off), a + Vector2(0, -y_off)])
	draw_colored_polygon(outer, WINDOW_GLOW)
	draw_polyline(outer, WINDOW_FRAME, 8.0)
	# 중간 몰딩
	var mid_a := a.lerp(b, 0.5) + Vector2(0, -y_off - win_h)
	var mid_b := a.lerp(b, 0.5) + Vector2(0, -y_off)
	draw_line(mid_a, mid_b, WINDOW_FRAME, 4.0)
	# 바닥으로 떨어지는 따뜻한 빛 패치: 창면(x=0)에서 방 안(+x)으로 사각형 투영
	var depth := 3  # 빛이 스며드는 셀 깊이
	var light_patch := PackedVector2Array([
		_corner(origin.x, origin.y),
		_corner(origin.x, origin.y + width_cells),
		_corner(origin.x + depth, origin.y + width_cells + 0.8),
		_corner(origin.x + depth, origin.y - 0.8)])
	draw_colored_polygon(light_patch, Color(1.0, 0.95, 0.82, 0.13))


# ---------------------------------------------------------------- 배치 프리뷰
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
