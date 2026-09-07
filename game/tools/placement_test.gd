extends Node2D
## 가구 배치 정합 테스트 — anchor 기반 sprite가 grid 위치에 정확히 놓이는지 확인
## 실행: godot --path . res://tools/placement_test.tscn --resolution 1280x720

var elapsed := 0.0
var shot_at := 3.0


func _ready() -> void:
	var font := load("res://assets/fonts/NotoSansKR.ttf")
	if font:
		ThemeDB.fallback_font = font

	# 방 바닥 (IsoProjector 다이아몬드)
	var floor_node := Node2D.new()
	add_child(floor_node)
	var floor := Polygon2D.new()
	floor.color = Color(0.72, 0.55, 0.35)
	floor.polygon = _diamond_polygon(16, 12)
	floor_node.add_child(floor)

	# grid 라인
	for x in range(17):
		var p1 := IsoProjector.gridf_to_screen(x, 0)
		var p2 := IsoProjector.gridf_to_screen(x, 12)
		var line := Line2D.new()
		line.points = PackedVector2Array([p1, p2])
		line.width = 1.0
		line.default_color = Color(0.5, 0.4, 0.25, 0.5)
		floor_node.add_child(line)
	for y in range(13):
		var p1 := IsoProjector.gridf_to_screen(0, y)
		var p2 := IsoProjector.gridf_to_screen(16, y)
		var line := Line2D.new()
		line.points = PackedVector2Array([p1, p2])
		line.width = 1.0
		line.default_color = Color(0.5, 0.4, 0.25, 0.5)
		floor_node.add_child(line)

	# 카메라 (방 전체가 보이게)
	var cam := Camera2D.new()
	
	add_child(cam)
	var c00 := IsoProjector.gridf_to_screen(0, 0)
	var cW0 := IsoProjector.gridf_to_screen(16, 0)
	var c0H := IsoProjector.gridf_to_screen(0, 12)
	var cWH := IsoProjector.gridf_to_screen(16, 12)
	var min_p := Vector2(min(c00.x, c0H.x), min(c00.y, cW0.y)) - Vector2(50, 50)
	var max_p := Vector2(max(cW0.x, cWH.x), max(c0H.y, cWH.y)) + Vector2(50, 50)
	var size := max_p - min_p
	var zoom := minf(1280.0 / size.x, 720.0 / size.y)
	cam.zoom = Vector2(zoom, zoom)
	cam.position = (min_p + max_p) / 2.0
	cam.make_current()

	# 가구 배치 (anchor 기반)
	var furn_layer := Node2D.new()
	furn_layer.y_sort_enabled = false  # z_index로 직접 정렬
	add_child(furn_layer)

	# 침대: grid(1,0), rot 0, footprint 4x8
	FurnitureV2.place(furn_layer, "bed_single", 0, Vector2i(1, 0), 4, 8)
	# 소파: grid(9,7), rot 0, footprint 6x3
	FurnitureV2.place(furn_layer, "sofa_two", 0, Vector2i(9, 7), 6, 3)
	# 의자: grid(14,3), rot 0, footprint 2x2
	FurnitureV2.place(furn_layer, "chair_basic", 0, Vector2i(14, 3), 2, 2)
	# 식물: grid(14,0), rot 0, footprint 2x2
	FurnitureV2.place(furn_layer, "plant_monstera", 0, Vector2i(14, 0), 2, 2)
	# 러그: grid(8,4), rot 0, footprint 6x4 (UNDERLAY)
	FurnitureV2.place(furn_layer, "rug_oval", 0, Vector2i(8, 4), 6, 4, GridModel.Layer.UNDERLAY)
	# 캐릭터: grid(5,8)
	FurnitureV2.place(furn_layer, "char", 0, Vector2i(5, 8), 2, 2)

	# 라벨 (디버깅용)
	_add_label(furn_layer, "bed", Vector2i(1, 0), 4, 8)
	_add_label(furn_layer, "sofa", Vector2i(9, 7), 6, 3)
	_add_label(furn_layer, "chair", Vector2i(14, 3), 2, 2)
	_add_label(furn_layer, "char", Vector2i(5, 8), 2, 2)


func _diamond_polygon(w: int, h: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(IsoProjector.gridf_to_screen(0, 0))
	pts.append(IsoProjector.gridf_to_screen(w, 0))
	pts.append(IsoProjector.gridf_to_screen(w, h))
	pts.append(IsoProjector.gridf_to_screen(0, h))
	return pts


func _add_label(parent: Node2D, text: String, origin: Vector2i, w: int, h: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	var cx := origin.x + w / 2.0
	var cy := origin.y + h / 2.0
	lbl.position = IsoProjector.gridf_to_screen(cx, cy) - Vector2(20, 10)
	lbl.z_index = 5000
	parent.add_child(lbl)


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= shot_at:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://placement_test.png")
		print("PLACEMENT_TEST_SAVED")
		get_tree().quit()
