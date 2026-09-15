extends SceneTree
## 실제 입력 이벤트(Input.parse_input_event)로 사람처럼 플레이하는 드라이버.
## 함수 직접 호출이 아닌 진짜 마우스 이벤트 → GUI 파이프라인 전체를 탐다.
## 실행: godot --path . --resolution 1280x720 -s tools/human_play_driver.gd

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


func _click_node(node: CanvasItem) -> void:
	var r: Rect2 = node.get_global_rect()
	var c: Vector2 = r.get_center()
	_mouse_to(c)
	await process_frame
	_click_at(c)
	await process_frame
	await process_frame


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


func _p(tag: String, msg: String) -> void:
	print("PLAY|%s|%s" % [tag, msg])


func _run() -> void:
	# ===== 1. 타이틀: 새 게임 클릭 =====
	await _frames(5)
	var btn := _find_button(flow, "새 게임")
	if btn == null:
		_p("S1", "FAIL 새 게임 버튼 없음")
		_finish()
		return
	_p("S1", "새 게임 버튼 발견 rect=%s — 클릭" % btn.get_global_rect())
	await _click_node(btn)
	await _frames(5)
	_p("S1b", "클릭 후 popup_title='%s' state=%s" % [flow.popup_title.text, flow.state])
	btn = _find_by_child_text(flow, "광화문 안정기업")
	_p("S2", "직장 선택 화면 %s" % ("도달" if btn else "미도달"))
	if btn == null:
		_finish()
		return

	# ===== 2. 광화문 선택 =====
	await _click_node(btn)
	await _frames(3)
	# 직장/매물 버튼은 텍스트 자식 Label 구조 — 이름으로 검색
	var listing_btn := _find_by_child_text(flow, "마포 한강뷰 옥탑")
	_p("S3", "매물 선택 화면 %s" % ("도달" if listing_btn else "미도달"))
	if listing_btn == null:
		_finish()
		return

	# ===== 3. 마포 옥탑 선택 =====
	await _click_node(listing_btn)
	await _frames(8)
	_p("S4", "방 입주 state=%s cash=%d" % [flow.state, flow.gs.cash_balance])

	# ===== 4. 가구 상점 열기 (하단바 버튼 실클릭) =====
	var shop_btn := _find_button(flow, "가구 상점")
	await _click_node(shop_btn)
	await _frames(3)
	_p("S5", "상점 열림 panel=%s" % flow.shop_panel.visible)

	# ===== 5. 싱글 침대 구매 버튼 실클릭 =====
	# 상점 카드의 구매 버튼은 text "구매" 여러 개 — 침대 카드 찾아서 그 카드의 버튼
	var bed_buy := _find_card_buy(flow, "싱글 침대")
	if bed_buy == null:
		_p("S6", "FAIL 침대 구매 버튼 없음")
		_finish()
		return
	_p("S6", "침대 구매 클릭")
	await _click_node(bed_buy)
	await _frames(5)
	_p("S7", "배치 모드 진입 placing='%s' ghost=%s grid=%s" % [
			flow.placing, flow.ghost.visible, flow.overlay.visible])

	# ===== 6. 마우스 이동으로 고스트 따라다니기 (진짜 모션 이벤트) =====
	for pt in [Vector2(700, 450), Vector2(500, 400), Vector2(650, 380)]:
		await _mouse_to(pt)
		await _frames(2)
	_p("S8", "고스트 이동 추적 origin=%s mod=%s" % [flow.place_origin, flow.ghost.modulate])

	# ===== 7. 클릭 배치 =====
	await _click_at(Vector2(650, 380))
	await _frames(8)
	_p("S9", "배치 결과 placing='%s' placements=%d error_check" % [flow.placing, flow.grid.placements.size()])

	# ===== 8. 축하 팝업 확인 =====
	var ok_btn := _find_button(flow, "좋아!")
	if ok_btn:
		_p("S10", "욕구 완료 팝업 표시 — 확인 클릭")
		await _click_node(ok_btn)
	else:
		_p("S10", "팝업 없음 (직행)")
	await _frames(10)
	_p("S11", "캐릭터 상태=%s pos=%s" % [flow.agent.get("state"), flow.agent.position])

	# 캐릭터가 침대 사용까지 관찰 (최대 15초)
	var t := 0.0
	while t < 15.0:
		await process_frame
		t += 1.0 / 60.0
		if flow.agent.get("state") == "using":
			break
	_p("S12", "캐릭터 사용 상태=%s tex=%s" % [flow.agent.get("state"),
			flow.agent.sprite.texture.resource_path.get_file() if flow.agent.sprite.texture else "none"])
	var img := get_root().get_texture().get_image()
	img.save_png("res://../review/human_play_result.png")
	_p("DONE", "전 시나리오 완료")
	_finish()


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


func _find_card_buy(parent: Node, item_name: String) -> Button:
	# item_name 라벨을 가진 VBox 카드의 구매 버튼
	var cards := _collect_cards(parent, item_name)
	for card in cards:
		var b := _find_button(card, "구매")
		if b:
			return b
	return null


func _collect_cards(parent: Node, item_name: String) -> Array:
	var out: Array = []
	_collect_cards_r(parent, item_name, out)
	return out


func _collect_cards_r(parent: Node, item_name: String, out: Array) -> void:
	if parent is VBoxContainer:
		var has_item := false
		for c in parent.get_children():
			if c is Label and item_name in (c as Label).text:
				has_item = true
		if has_item:
			out.append(parent)
	for c in parent.get_children():
		_collect_cards_r(c, item_name, out)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _finish() -> void:
	await process_frame
	quit()
