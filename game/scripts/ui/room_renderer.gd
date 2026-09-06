extends Node2D
## 방 렌더러 v3 — Blender 렌더 room_shell.png를 그리드에 정렬해 표시.
## 논리 그리드는 GridModel 소유. 렌더 이미지가 없으면 구 플랭크 폴백.

var grid: GridModel

const ROOM_TEX := "res://assets/sprites/room_shell.png"
const ROOM_MANIFEST := "res://assets/sprites/room_manifest.json"

# 폴백 팔레트
const FLOOR_BASE := Color(0.847, 0.659, 0.424)
const FLOOR_SEAM := Color(0.66, 0.48, 0.30)
const HIGHLIGHT_OK := Color(0.61, 0.69, 0.38, 0.45)
const HIGHLIGHT_BAD := Color(0.85, 0.35, 0.25, 0.45)

var room_tex: Texture2D
var room_draw: Rect2
var preview_origin: Vector2i = Vector2i(-1, -1)
var preview_fp: Vector2i = Vector2i.ZERO
var preview_valid := false
var preview_active := false


func _ready() -> void:
	_load_room()


func _load_room() -> void:
	var f := FileAccess.open(ROOM_MANIFEST, FileAccess.READ)
	if f == null:
		return
	var m = JSON.parse_string(f.get_as_text())
	if m == null or not m.has("corners_img_px"):
		return
	var tex := load(ROOM_TEX)
	if tex == null:
		return
	room_tex = tex
	var cimg: Dictionary = m["corners_img_px"]
	# 그리드 코너의 게임 화면 좌표
	var t00 := _corner(0, 0)
	var twh := _corner(grid.width, grid.height)
	var tw0 := _corner(grid.width, 0)
	var i00 := Vector2(cimg["c00"][0], cimg["c00"][1])
	var iwh := Vector2(cimg["cWH"][0], cimg["cWH"][1])
	var iw0 := Vector2(cimg["cW0"][0], cimg["cW0"][1])
	var s := (twh - t00).length() / (iwh - i00).length()
	# 정합 검증: 다른 코너쌍 오차가 크면 스케일 평균 사용
	var s2 := (tw0 - t00).length() / (iw0 - i00).length()
	if abs(s - s2) / s > 0.02:
		s = (s + s2) * 0.5
	var origin := t00 - i00 * s
	room_draw = Rect2(origin, Vector2(tex.get_width(), tex.get_height()) * s)


func _draw() -> void:
	if grid == null:
		return
	if room_tex:
		draw_texture_rect(room_tex, room_draw, false)
	else:
		_draw_fallback_floor()
	_draw_preview()


func _corner(gx: float, gy: float) -> Vector2:
	return Vector2((gx - gy) * IsoProjector.TILE_WIDTH * 0.5,
			(gx + gy) * IsoProjector.TILE_HEIGHT * 0.5)


## 정점 기준 셀 다이아몬드: (x,y)..(x+1,y+1)
func _cell_poly(x: int, y: int) -> PackedVector2Array:
	return PackedVector2Array([
		_corner(x, y), _corner(x + 1, y), _corner(x + 1, y + 1), _corner(x, y + 1)])


# ---------------------------------------------------------------- 폴백(구 방식)
func _draw_fallback_floor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260905
	var plank_len := 4
	for y in range(grid.height):
		var stagger := (y * 2) % plank_len
		var x := -stagger
		while x < grid.width:
			var x0 := maxi(x, 0)
			var x1 := mini(x + plank_len, grid.width)
			if x1 > x0:
				var c := FLOOR_BASE.darkened(rng.randf_range(-0.05, 0.05))
				if y == 0 or x0 == 0:
					c = c.darkened(0.06)
				draw_colored_polygon(PackedVector2Array([
					_corner(x0, y), _corner(x1, y), _corner(x1, y + 1), _corner(x0, y + 1)]), c)
			x += plank_len
		draw_line(_corner(0, y), _corner(grid.width, y), FLOOR_SEAM, 2.0)


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
			draw_colored_polygon(_cell_poly(x, y),
					HIGHLIGHT_OK if preview_valid else HIGHLIGHT_BAD)
	draw_polyline(PackedVector2Array([
		_corner(preview_origin.x, preview_origin.y),
		_corner(preview_origin.x + preview_fp.x, preview_origin.y),
		_corner(preview_origin.x + preview_fp.x, preview_origin.y + preview_fp.y),
		_corner(preview_origin.x, preview_origin.y + preview_fp.y),
		_corner(preview_origin.x, preview_origin.y)]),
			Color(1, 1, 1, 0.8) if preview_valid else Color(1, 0.5, 0.4, 0.9), 2.0)
