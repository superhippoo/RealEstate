extends SceneTree
## S9b 렌더링 프로브: 상점 열어둔 채 월 경계 → 정산 팝업이 "실제 픽셀로" 상점 위에 그려지는지 검증.
## 실행: godot --path . --resolution 1280x720 -s tools/render_probe.gd

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


func _find_by_child_text(parent: Node, text_part: String) -> Button:
	if parent is Button:
		for c in (parent as Button).get_children():
			if c is Label and text_part in (c as Label).text:
				return parent
	for c in parent.get_children():
		var found := _find_by_child_text(c, text_part)
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
	print("PROBE|boot|state=%s" % flow.state)

	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	flow.gs.month_seconds = GameStateScript.MONTH_SECONDS - 0.3

	var waited := 0.0
	while not flow.popup.visible and waited < 3.0:
		await process_frame
		waited += 1.0 / 60.0

	# ---- 상태 덤프 ----
	print("PROBE|state|popup.visible=%s popup.index=%d shop.visible=%s shop.index=%d children=%d" % [
		flow.popup.visible, flow.popup.get_index(),
		flow.shop_panel.visible, flow.shop_panel.get_index(), flow.get_child_count()])
	print("PROBE|state|popup.rect=%s shop.rect=%s" % [
		flow.popup.get_global_rect(), flow.shop_panel.get_global_rect()])
	print("PROBE|state|time_running=%s month=%d title='%s'" % [
		flow.time_running, flow.gs.month, flow.popup_title.text])
	var order: Array = []
	for i in flow.get_child_count():
		var c := flow.get_child(i)
		order.append("%d:%s(v=%s)" % [i, c.name, c.visible])
	print("PROBE|order|%s" % " | ".join(order))

	# ---- 실 렌더 픽셀 검사: 팝업 중앙 상단(제목 줄) 픽셀 색 ----
	await _frames(5)
	var img := get_root().get_texture().get_image()
	var pr: Rect2 = flow.popup.get_global_rect()
	var probe_pts: Array = [
		pr.position + Vector2(pr.size.x * 0.5, 30),      # 제목 근처
		pr.position + Vector2(pr.size.x * 0.5, pr.size.y - 40),  # 버튼 근처
		pr.get_center(),
	]
	for i in probe_pts.size():
		var p: Vector2 = probe_pts[i]
		var col: Color = img.get_pixel(int(p.x), int(p.y))
		print("PROBE|pixel|%d at(%d,%d) rgba=(%.2f,%.2f,%.2f,%.2f)" % [
			i, int(p.x), int(p.y), col.r, col.g, col.b, col.a])
	img.save_png("res://../review/render_probe.png")
	print("PROBE|saved|render_probe.png")
	quit(0)
