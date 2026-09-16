extends SceneTree
## 착지 검증: 사용자 제보 위치(좌상단)에 침대 배치 후 화면 저장.
## 실행: godot --path . --resolution 1280x720 -s tools/grounding_check.gd

var flow: Control


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	flow = scene.instantiate()
	get_root().add_child(flow)
	await process_frame
	await process_frame
	_run()


func _find_button(parent: Node, text: String) -> Button:
	if parent is Button and (parent as Button).text == text:
		return parent
	for c in parent.get_children():
		var found := _find_button(c, text)
		if found:
			return found
	return null


func _find_by_child_text(parent: Node, part: String) -> Button:
	if parent is Button:
		for c in (parent as Button).get_children():
			if c is Label and part in (c as Label).text:
				return parent
	for c in parent.get_children():
		var found := _find_by_child_text(c, part)
		if found:
			return found
	return null


func _find_card_buy(parent: Node, item_name: String) -> Button:
	if parent is VBoxContainer:
		var has := false
		for c in parent.get_children():
			if c is Label and item_name in (c as Label).text:
				has = true
		if has:
			return _find_button(parent, "구매")
	for c in parent.get_children():
		var found := _find_card_buy(c, item_name)
		if found:
			return found
	return null


func _mouse_to(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	Input.parse_input_event(ev)
	await process_frame


func _click_at(p: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = p
	ev.global_position = p
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = p
	ev.global_position = p
	Input.parse_input_event(ev)
	await process_frame


func _click_node(node: CanvasItem) -> void:
	var c: Vector2 = node.get_global_rect().get_center()
	await _mouse_to(c)
	await _click_at(c)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	await _frames(5)
	await _click_node(_find_button(flow, "새 게임"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "광화문 안정기업"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "마포 한강뷰 옥탑"))
	await _frames(8)
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	await _click_node(_find_card_buy(flow, "싱글 침대"))
	await _frames(5)
	# 사용자 제보와 동일한 좌상단 배치
	var pt: Vector2 = flow.grid_to_screen(Vector2i(3, 2))
	await _mouse_to(pt)
	await _click_at(pt)
	await _frames(10)
	var ok := _find_button(flow, "좋아!")
	if ok:
		await _mouse_to(Vector2(640, 200))
		await _frames(40)
		await _click_node(ok)
	await _frames(10)
	var img := get_root().get_texture().get_image()
	img.save_png("res://../review/grounding_after.png")
	print("GROUND|saved|bed cell (3,2) placements=%d" % flow.grid.placements.size())
	quit(0)
