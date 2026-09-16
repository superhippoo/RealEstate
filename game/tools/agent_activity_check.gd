extends SceneTree
## 가구 많은 방에서 캐릭터 자율생활 관찰 (전가구 QA의 '가구 미사용' 재현 시도)
## 실행: godot --path . --resolution 1280x720 -s tools/agent_activity_check.gd

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


func _buy_place(item_name: String, cell: Vector2i) -> void:
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	var b := _find_card_buy(flow, item_name)
	if b == null:
		print("ACT|ERR|구매버튼없음 %s" % item_name)
		return
	await _click_node(b)
	await _frames(5)
	var pt: Vector2 = flow.grid_to_screen(cell)
	await _mouse_to(pt)
	await _click_at(pt)
	await _frames(6)
	var ok := _find_button(flow, "좋아!")
	if ok:
		await _wait_sec(0.6)
		await _click_node(ok)
	await _frames(4)
	print("ACT|placed|%s@%s n=%d" % [item_name, cell, flow.grid.placements.size()])


func _wait_sec(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += 1.0 / 60.0


func _run() -> void:
	await _frames(5)
	await _click_node(_find_button(flow, "새 게임"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "광화문 안정기업"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "마포 한강뷰 옥탑"))
	await _frames(8)

	# 저가 가구 6종을 방에 고르게 배치 (총 예산 1.75M < 2.29M)
	await _buy_place("화분 식물", Vector2i(13, 9))
	await _buy_place("원목 의자", Vector2i(6, 3))
	await _buy_place("사이드 테이블", Vector2i(13, 5))
	await _buy_place("플로어 램프", Vector2i(1, 2))
	await _buy_place("타원 러그", Vector2i(6, 7))
	await _buy_place("책상", Vector2i(11, 1))
	# 침대 (남은 예산 ~0.54M... 부족하면 부업)
	var cash: int = flow.gs.spendable_cash()
	if cash < 800000:
		await _click_node(_find_button_prefix(flow, "부업"))
		await _frames(3)
		var sb := _find_button(flow, "부업 시작")
		if sb:
			await _click_node(sb)
			await _frames(4)
		var st := _find_button(flow, "그만두기")
		if st:
			await _click_node(st)
			await _frames(3)
	await _buy_place("싱글 침대", Vector2i(1, 4))

	# ===== 3분 관찰: 10초마다 상태 로깅 =====
	var seen_actions := {}
	var t := 0.0
	var next_log := 10.0
	while t < 180.0:
		await process_frame
		t += 1.0 / 60.0
		var st: String = flow.agent.get("state")
		var ua: Dictionary = flow.agent.use_action
		if st == "using" and not ua.is_empty():
			seen_actions[ua.get("label", "?")] = true
		if t >= next_log:
			next_log += 10.0
			print("ACT|t=%03d|state=%s bubble='%s' energy=%d placing='%s'" % [
				int(t), st, flow.agent.bubble.text, flow.gs.energy, flow.placing])
	print("ACT|RESULT|distinct_actions=%d %s" % [seen_actions.size(), str(seen_actions.keys())])
	quit(0)


func _find_button_prefix(parent: Node, prefix: String) -> Button:
	if parent is Button and (parent as Button).text.begins_with(prefix):
		return parent
	for c in parent.get_children():
		var found := _find_button_prefix(c, prefix)
		if found:
			return found
	return null
