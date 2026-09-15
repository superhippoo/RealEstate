extends SceneTree
## 5차 QA 결함 재현: 침대→부업→정산→소파→회전2→취소(환불)→상점 재오픈 → 엔진/시간 60초 생존 검증.
## 실행: godot --path . --resolution 1280x720 -s tools/refund_freeze_repro.gd

var flow: Control
var fails := 0
const GameStateScript := preload("res://scripts/domain/game_state.gd")


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	flow = scene.instantiate()
	get_root().add_child(flow)
	await process_frame
	await process_frame
	_run()


func _check(tag: String, cond: bool, detail: String) -> void:
	if cond:
		print("TEST|%s|PASS|%s" % [tag, detail])
	else:
		fails += 1
		print("TEST|%s|FAIL|%s" % [tag, detail])


func _find_button(parent: Node, text: String) -> Button:
	if parent is Button and (parent as Button).text == text:
		return parent
	for c in parent.get_children():
		var found := _find_button(c, text)
		if found:
			return found
	return null


func _find_button_prefix(parent: Node, prefix: String) -> Button:
	if parent is Button and (parent as Button).text.begins_with(prefix):
		return parent
	for c in parent.get_children():
		var found := _find_button_prefix(c, prefix)
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

	# 침대 구매+배치
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	await _click_node(_find_card_buy(flow, "싱글 침대"))
	await _frames(5)
	var bed_cell := Vector2i(8, 1)
	var bed_pt: Vector2 = flow.grid_to_screen(bed_cell)
	await _mouse_to(bed_pt)
	await _click_at(bed_pt)
	await _frames(8)
	var okb := _find_button(flow, "좋아!")
	if okb:
		await _wait_sec(0.6)
		await _click_node(okb)
	_check("R1_bed", flow.grid.placements.size() == 1, "placements=%d" % flow.grid.placements.size())

	# 부업 1회
	await _click_node(_find_button_prefix(flow, "부업"))
	await _frames(3)
	var start_b := _find_button(flow, "부업 시작")
	if start_b:
		await _click_node(start_b)
		await _frames(4)
	var stop_b := _find_button(flow, "그만두기")
	if stop_b:
		await _click_node(stop_b)
		await _frames(3)
	_check("R2_sidejob", flow.gs.sidejobs_used == 1, "used=%d" % flow.gs.sidejobs_used)

	# 정산 (강제) 후 [확인]
	flow.gs.month_seconds = GameStateScript.MONTH_SECONDS - 0.2
	var w := 0.0
	while not flow.popup.visible and w < 3.0:
		await process_frame
		w += 1.0 / 60.0
	await _wait_sec(0.6)
	var ok2 := _find_button(flow, "확인")
	if ok2:
		await _click_node(ok2)
	await _frames(3)
	_check("R3_settle", flow.gs.month == 2 and flow.time_running, "month=%d time=%s" % [
		flow.gs.month, flow.time_running])

	# 소파 구매 → 회전 2회 → 취소(환불)
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	await _click_node(_find_card_buy(flow, "2인 소파"))
	await _frames(5)
	_check("R4_sofa_mode", flow.placing == "sofa_two", "placing='%s'" % flow.placing)
	var rot := _find_button(flow, "회전 ↻")
	if rot == null:
		_check("R5_rotate_btn", false, "회전 버튼 없음")
		_finish()
		return
	await _click_node(rot)
	await _click_node(rot)
	_check("R5_rotated", flow.place_rotation == 180, "rot=%d toast=%s" % [
		flow.place_rotation, flow.toast.visible])
	var cancel := _find_button(flow, "취소 (환불)")
	if cancel == null:
		_check("R6_cancel", false, "취소 버튼 없음")
		_finish()
		return
	var cash_before: int = flow.gs.cash_balance
	await _click_node(cancel)
	await _frames(5)
	_check("R6_refund", flow.placing.is_empty() and flow.gs.cash_balance == cash_before + 1200000,
		"placing='%s' cash=%d→%d" % [flow.placing, cash_before, flow.gs.cash_balance])
	_check("R7_time_resumed", flow.time_running and flow.bottom_bar.visible,
		"time=%s bottom=%s" % [flow.time_running, flow.bottom_bar.visible])

	# ===== 핵심: 환불 직후 상점 재오픈 + 60초 생존 =====
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(5)
	_check("R8_shop_reopen", flow.shop_panel.visible and flow.popup.visible == false,
		"shop=%s popup=%s" % [flow.shop_panel.visible, flow.popup.visible])

	var f0: int = Engine.get_process_frames()
	var ms0: float = flow.gs.month_seconds
	var alive := true
	var t := 0.0
	var frames_advanced := true
	var month_advanced := true
	var last_agent_pos: Vector2 = flow.agent.position
	var agent_moved := false
	while t < 60.0:
		await process_frame
		t += 1.0 / 60.0
		if int(t) % 10 == 0 and absf(t - roundf(t)) < 0.009:
			var df: int = Engine.get_process_frames() - f0
			var dm: float = flow.gs.month_seconds - ms0
			if df < 300:
				frames_advanced = false
			if dm < float(int(t)) * 0.3:
				month_advanced = false
			if flow.agent.position.distance_to(last_agent_pos) > 5.0:
				agent_moved = true
				last_agent_pos = flow.agent.position
			print("TEST|R9_alive|t=%ds frames+%d month_s+%.1f agent_moved=%s" % [
				int(t), df, dm, agent_moved])
	_check("R9_engine_alive", frames_advanced and month_advanced,
		"60초간 프레임/시간 진행=%s/%s" % [frames_advanced, month_advanced])
	# 상점이 계속 열려있고 클릭 가능해야
	var tv_buy := _find_card_buy(flow, "43인치 TV")
	if tv_buy:
		await _click_node(tv_buy)
		await _frames(5)
	_check("R10_cards_alive", flow.popup.visible or not flow.placing.is_empty(),
		"TV 클릭 반응 popup=%s placing='%s'" % [flow.popup.visible, flow.placing])
	var verdict := "PASS" if fails == 0 else "FAIL"
	print("TEST|RESULT|%s fails=%d" % [verdict, fails])
	_finish()


func _finish() -> void:
	await process_frame
	quit(fails)
