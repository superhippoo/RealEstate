extends SceneTree
## 회귀 테스트: "상점 열어둔 채 월 정산 발동" 시나리오 (QA 2차가 발견한 치명 UX 결함)
## 결함: 정산 팝업이 상점을 강제로 닫고 [확인]이 카드 클릭을 흡수 → "카드 무반응"처럼 보임
## 수정: 정산 팝업은 상점을 닫지 않고 위에 겹치며, [확인]은 350ms 클릭 가드 적용,
##       확인 후 상점 세션 복원. 배치 모드 중에는 시간이 얼어 정산이 끼어들지 않음.
## 실행: godot --path . --resolution 1280x720 -s tools/settle_during_shop_test.gd

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


func _click_node(node: CanvasItem) -> void:
	var c: Vector2 = node.get_global_rect().get_center()
	await _mouse_to(c)
	await _click_at(c)
	await process_frame


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
	# --- 부팅: 새 게임 → 광화문 → 마포 (실클릭) ---
	await _click_node(_find_button(flow, "새 게임"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "광화문 안정기업"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "마포 한강뷰 옥탑"))
	await _frames(8)
	_check("T0_boot", flow.state == "room", "state=%s month=%d" % [flow.state, flow.gs.month])

	# --- 침대 구매+배치 (기본 전제, 실클릭) ---
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	await _click_node(_find_card_buy(flow, "싱글 침대"))
	await _frames(5)
	await _mouse_to(Vector2(650, 400))
	await _click_at(Vector2(650, 400))
	await _frames(8)
	var okb := _find_button(flow, "좋아!")
	if okb:
		await _frames(25)  # 클릭 가드(350ms) 이후 클릭
		await _click_node(okb)
	_check("T1_bed_placed", flow.grid.placements.size() == 1 and flow.placing.is_empty(),
		"placements=%d placing='%s'" % [flow.grid.placements.size(), flow.placing])

	# ===== 핵심 재현: 상점 연 채 월 경계 도래 =====
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	_check("T2_shop_open", flow.shop_panel.visible and flow.popup.visible == false,
		"shop=%s popup=%s" % [flow.shop_panel.visible, flow.popup.visible])

	flow.gs.month_seconds = GameStateScript.MONTH_SECONDS - 0.2  # 0.2초 후 월 경계
	# 팝업이 뜨는 즉시 잡아서 클릭 가드를 실제로 시험
	var waited := 0.0
	while not flow.popup.visible and waited < 3.0:
		await process_frame
		waited += 1.0 / 60.0
	_check("T3_settle_keeps_shop", flow.popup.visible and flow.shop_panel.visible,
		"정산 팝업=%s 상점 유지=%s (구버그: 상점 강제폐쇄) month=%d waited=%.2fs" % [
			flow.popup.visible, flow.shop_panel.visible, flow.gs.month, waited])

	# ===== 클릭 가드: 팝업 직후(<350ms) 스친 [확인] 클릭은 무시되어야 함 =====
	var ok_btn := _find_button(flow, "확인")
	if ok_btn == null:
		_check("T4_guard", false, "확인 버튼 없음")
		_finish()
		return
	await _click_at(ok_btn.get_global_rect().get_center())  # 팝업 오픈 직후 즉시 클릭
	await _frames(3)
	_check("T4_guard", flow.popup.visible, "가드 후에도 팝업 유지=%s (스친 클릭 방지)" % flow.popup.visible)

	# ===== 확인 후 상점 세션 복원 =====
	await _wait_sec(0.6)
	ok_btn = _find_button(flow, "확인")
	await _click_node(ok_btn)
	await _frames(3)
	await _frames(5)
	_check("T5_shop_restored", flow.shop_panel.visible and flow.popup.visible == false,
		"복원 후 상점=%s 팝업=%s month=%d" % [flow.shop_panel.visible, flow.popup.visible, flow.gs.month])

	# ===== 복원된 상점에서 TV 구매 시도 (구버그 재현 지점: 카드 무반응) =====
	# 정산 반영 후 사용 가능 ~2,330,000 < TV 2,900,000 → 부족액 팝업이 떠야 정상 (QA S9)
	var tv_buy := _find_card_buy(flow, "43인치 TV")
	if tv_buy == null:
		_check("T6_shortfall", false, "TV 구매 버튼 없음")
		_finish()
		return
	await _click_node(tv_buy)
	await _frames(5)
	_check("T6_shortfall", flow.popup.visible and "갖고 싶은데" in flow.popup_title.text,
		"부족 팝업=%s 제목='%s' spendable=%d (구버그: 클릭 무반응)" % [
			flow.popup.visible, flow.popup_title.text, flow.gs.spendable_cash()])
	var wait_btn := _find_button(flow, "다음 월급까지 기다리기")
	if wait_btn:
		await _click_node(wait_btn)
		await _frames(3)

	# ===== 부업: 하단 [부업 (N/6회)] → 시작 → 보상 → 그만두기 (QA S9 이어서) =====
	var sj_open := _find_button_prefix(flow, "부업")
	if sj_open:
		await _click_node(sj_open)
		await _frames(3)
	var sj_start := _find_button(flow, "부업 시작")
	if sj_start:
		await _click_node(sj_start)
		await _frames(5)
	_check("T6b_sidejob", flow.gs.sidejobs_used == 1 and flow.popup.visible
			and "일 끝" in flow.popup_title.text + str(flow.popup_body.get_child(1).text if flow.popup_body.get_child_count() > 1 else ""),
		"부업=%d/6 팝업=%s" % [flow.gs.sidejobs_used, flow.popup.visible])
	var stop_btn := _find_button(flow, "그만두기")
	if stop_btn:
		await _click_node(stop_btn)
		await _frames(3)

	# ===== 소파 구매 → 배치 모드 =====
	await _click_node(_find_button(flow, "가구 상점"))
	await _frames(3)
	var sofa_buy := _find_card_buy(flow, "2인 소파")
	if sofa_buy == null:
		_check("T7_sofa_buy", false, "소파 구매 버튼 없음")
		_finish()
		return
	await _click_node(sofa_buy)
	await _frames(5)
	_check("T7_sofa_buy", flow.placing == "sofa_two",
		"placing='%s' (구버그: 클릭 무반응)" % flow.placing)

	# ===== 배치 모드 중 정산 끼어듦 없음 (시간 정지) =====
	flow.gs.month_seconds = GameStateScript.MONTH_SECONDS - 0.5
	await _wait_sec(1.5)
	_check("T8a_no_settle_while_placing", flow.popup.visible == false and flow.placing == "sofa_two",
		"배치 중 팝업=%s placing='%s'" % [flow.popup.visible, flow.placing])

	# ===== 소파 배치 완료 (침대 x7-10·y4-11 피해 왼쪽 빈 셀 (2,6) 클릭) =====
	var sofa_cell := Vector2i(2, 10)   # 침대(x4-7,y1-8) 회피: 소파 x0-5,y9-11
	var sofa_pt: Vector2 = flow.grid_to_screen(sofa_cell)
	await _mouse_to(sofa_pt)
	await _frames(2)
	print("TEST|DBG|sofa pt=%s roundtrip=%s origin=%s mod=%s bed_place=%s" % [
		sofa_pt, flow.screen_to_cell(sofa_pt), flow.place_origin, flow.ghost.modulate,
		grid_origin_of(0)])
	await _click_at(sofa_pt)
	await _frames(3)
	print("TEST|DBG|after click placing='%s' origin=%s" % [flow.placing, flow.place_origin])
	await _frames(8)
	_check("T8b_sofa_placed", flow.grid.placements.size() == 2 and flow.placing.is_empty(),
		"placements=%d placing='%s'" % [flow.grid.placements.size(), flow.placing])

	# ===== 배치 끝나면 대기 중이던 정산이 이어서 도래 (시간 해제) =====
	await _wait_sec(2.5)
	_check("T9_settle_after_placing", flow.popup.visible,
		"월 경과 후 정산 팝업=%s month=%d" % [flow.popup.visible, flow.gs.month])
	if flow.popup.visible:
		await _wait_sec(0.6)
		var ok2 := _find_button(flow, "확인")
		if ok2:
			await _click_node(ok2)
			await _frames(3)

	# ===== 캐릭터 자율생홨 회귀: 액션 완료 후 갇히지 않고 idle 복귀 (char_agent 수정 검증) =====
	var stuck_check_start := Time.get_ticks_msec()
	var saw_idle_after_using := false
	while Time.get_ticks_msec() - stuck_check_start < 30000:
		await process_frame
		if flow.agent.get("state") == "idle":
			saw_idle_after_using = true
			break
	_check("T10_agent_not_stuck", saw_idle_after_using,
		"30초 내 idle 복귀=%s state=%s (구버그: using에 영구 갇힘)" % [
			saw_idle_after_using, flow.agent.get("state")])

	var verdict := "PASS" if fails == 0 else "FAIL"
	print("TEST|RESULT|%s fails=%d" % [verdict, fails])
	_finish()


func grid_origin_of(idx: int) -> Vector2i:
	var i := 0
	for iid in flow.grid.placements:
		if i == idx:
			return flow.grid.placements[iid]["origin"]
		i += 1
	return Vector2i(-1, -1)


func _finish() -> void:
	await process_frame
	quit(fails)
