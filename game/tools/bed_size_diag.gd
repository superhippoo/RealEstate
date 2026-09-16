extends SceneTree
## 침대가 '작게+공중에' 렌더되는 버그 진단:
## A) 뒤벽 좌측 배치 크기/위치  B) 회전별 크기  C) 세이브→이어하기 후 크기/장애물
## 실행: godot --path . --resolution 1280x720 -s tools/bed_size_diag.gd

var flow: Control
const GameStateScript := preload("res://scripts/domain/game_state.gd")


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


func _dump(tag: String) -> void:
	for iid in flow.placed_nodes:
		var node: TextureRect = flow.placed_nodes[iid]
		var p = flow.grid.placements[iid]
		var r: Rect2 = node.get_global_rect()
		print("DIAG|%s|iid=%d %s rot=%d fp=%dx%d rect=(%.0f,%.0f %.0fx%.0f) sort_y=%.0f" % [
			tag, iid, p.def_id, p.rotation, p.def_w, p.def_h,
			r.position.x, r.position.y, r.size.x, r.size.y, node.get_meta("sort_y")])


func _astar_report(tag: String) -> void:
	# 침대 footprint 셀이 장애물로 등록됐는지
	for iid in flow.grid.placements:
		var p = flow.grid.placements[iid]
		var solid_cnt := 0
		for dy in p.def_h:
			for dx in p.def_w:
				if flow.agent.astar.is_point_solid(Vector2i(p.origin.x + dx, p.origin.y + dy)):
					solid_cnt += 1
		print("DIAG|%s|astar solid %d/%d @ origin %s" % [
			tag, solid_cnt, p.def_w * p.def_h, p.origin])


func _run() -> void:
	await _frames(5)
	await _click_node(_find_button(flow, "새 게임"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "광화문 안정기업"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "마포 한강뷰 옥탑"))
	await _frames(8)

	# A) 사용자와 같은 뒤벽 좌측 배치
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	await _click_node(_find_card_buy(flow, "싱글 침대"))
	await _frames(5)
	var pt: Vector2 = flow.grid_to_screen(Vector2i(3, 1))
	await _mouse_to(pt)
	await _frames(2)
	print("DIAG|A|ghost origin=%s rect=%s" % [flow.place_origin, flow.ghost.get_global_rect()])
	await _click_at(pt)
	await _frames(8)
	_dump("A_placed")
	_astar_report("A")
	var ok := _find_button(flow, "좋아!")
	if ok:
		await _mouse_to(Vector2(640, 200))
		await _frames(45)
		await _click_node(ok)
	await _frames(5)

	# C) 세이브 → 완전 재시작(동일 씬 재인스턴스) → 이어하기
	flow.gs.save_game_with(flow._placements_list())
	print("DIAG|C|saved placements=%s" % str(flow._placements_list()))
	get_root().remove_child(flow)
	flow.queue_free()
	await _frames(5)
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	flow = scene.instantiate()
	get_root().add_child(flow)
	await _frames(10)
	await _click_node(_find_button(flow, "이어하기"))
	await _frames(10)
	_dump("C_loaded")
	_astar_report("C")

	var img := get_root().get_texture().get_image()
	img.save_png("res://../review/bed_diag.png")
	print("DIAG|saved bed_diag.png")
	quit(0)
