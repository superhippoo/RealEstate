extends Control
## 배치 모드 시각화: 바닥 셀 다이아몬드 + 발판 하이라이트.

var valid_cells: Array[Vector2i] = []
var highlight_origin := Vector2i(-1, -1)
var highlight_size := Vector2i(0, 0)
var highlight_ok := true
var bg_transform: Transform2D  # 이미지px → 화면

var line_col := Color(1, 1, 1, 0.30)
var cell_col := Color(1, 1, 1, 0.10)
var ok_col := Color(0.55, 0.85, 0.40, 0.45)
var bad_col := Color(0.95, 0.40, 0.35, 0.45)


func _draw() -> void:
	# 전체 셀 다이아몬드
	for c in valid_cells:
		_draw_cell(c, cell_col, line_col)
	# 발판 하이라이트
	if highlight_origin.x >= 0:
		var col := ok_col if highlight_ok else bad_col
		for x in highlight_size.x:
			for y in highlight_size.y:
				_draw_cell(highlight_origin + Vector2i(x, y), col, Color(col.r, col.g, col.b, 0.8))


func _draw_cell(cell: Vector2i, fill: Color, line: Color) -> void:
	var u0 := float(cell.x)
	var v0 := float(cell.y)
	var p := [
		_to_screen(FloorProjector.grid_to_img(u0, v0)),
		_to_screen(FloorProjector.grid_to_img(u0 + 1, v0)),
		_to_screen(FloorProjector.grid_to_img(u0 + 1, v0 + 1)),
		_to_screen(FloorProjector.grid_to_img(u0, v0 + 1)),
	]
	draw_colored_polygon(p, fill)
	for i in 4:
		draw_line(p[i], p[(i + 1) % 4], line, 1.0)


func _to_screen(img_px: Vector2) -> Vector2:
	return bg_transform * img_px
