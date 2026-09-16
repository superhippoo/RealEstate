extends SceneTree
## 착지 수치 측정: 13종 가구를 여러 셀에 배치하며 스프라이트 하단(평평)과
## 바닥 접촉선(발판 앞변 대각선)의 좌우 갭을 렌더러와 동일한 수학으로 계산해 출력한다.
## 판정 기준(픽셀): 공중부양(어느 쪽 끝이든) <= 8px, 파묻힘 <= 45px
## 실행: godot --path . --resolution 1280x720 -s tools/grounding_measure.gd

var flow: Control
const GameStateScript := preload("res://scripts/domain/game_state.gd")
const FloorProjector := preload("res://scripts/core/floor_projector.gd")
const GridModel := preload("res://scripts/core/grid_model.gd")

# [fid, 배치셀, 태그]
const CASES := [
	["bed_single", Vector2i(3, 1), "back"],
	["bed_single", Vector2i(8, 1), "back2"],
	["bed_single", Vector2i(1, 4), "left"],
	["sofa_two", Vector2i(6, 8), "front"],
	["sofa_two", Vector2i(8, 5), "mid"],
	["desk_small", Vector2i(11, 1), "back"],
	["desk_small", Vector2i(5, 5), "mid"],
	["chair_basic", Vector2i(12, 9), "front"],
	["tv_43", Vector2i(8, 0), "back"],
	["wardrobe", Vector2i(0, 7), "left"],
	["rug_oval", Vector2i(5, 7), "mid"],
	["plant_monstera", Vector2i(13, 3), "right"],
	["floor_lamp", Vector2i(0, 2), "backleft"],
	["side_table", Vector2i(13, 6), "right"],
	["armchair", Vector2i(1, 9), "frontleft"],
]


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


func _screen(img_pt: Vector2) -> Vector2:
	var bg: TextureRect = flow.bg
	return bg.position + img_pt * (bg.size.x / bg.texture.get_width())


func _run() -> void:
	await _frames(5)
	await _click_node(_find_button(flow, "새 게임"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "광화문 안정기업"))
	await _frames(3)
	await _click_node(_find_by_child_text(flow, "마포 한강뷰 옥탑"))
	await _frames(8)
	flow.gs.cash_balance = 500_000_000   # 측정용: 예산 무제한

	var idx := 0
	for case in CASES:
		var fid: String = case[0]
		var cell: Vector2i = case[1]
		var tag: String = case[2]
		idx += 1
		var item_name: String = flow.slots["items"][fid]["name"]
		# 케이스 시작 전 잔여 팝업/배치모드 정리
		if not flow.placing.is_empty():
			flow.placing = ""
			flow.show_screen("room")
			await _frames(2)
		for bn in ["좋아!", "확인", "계속 꾸미기"]:
			var qb := _find_button(flow, bn)
			if qb:
				await _frames(45)
				await _click_node(qb)
				await _frames(2)
		await _click_node(_find_button(flow, "가구 상점"))
		await _frames(3)
		var buy := _find_card_buy(flow, item_name)
		if buy == null:
			print("MEAS|%s|%s|ERR|카드없음" % [fid, tag])
			continue
		await _click_node(buy)
		await _frames(4)
		var pt: Vector2 = flow.grid_to_screen(cell)
		await _mouse_to(pt)
		await _frames(2)
		await _click_at(pt)
		await _frames(6)

		# 측정
		var placed_iid := -1
		for iid in flow.placed_nodes:
			placed_iid = int(iid)
		if placed_iid < 0 or not flow.placing.is_empty():
			print("MEAS|%s|%s|ERR|배치실패 placing='%s' toast='%s'" % [fid, tag, flow.placing, flow.toast.text])
			flow._cancel_placing()
			await _frames(3)
			continue
		var node: TextureRect = flow.placed_nodes[placed_iid]
		var p = flow.grid.placements[placed_iid]
		var r: Rect2 = node.get_global_rect()
		var west: Vector2 = _screen(FloorProjector.grid_to_img(p.origin.x, p.origin.y + p.def_h))
		var east: Vector2 = _screen(FloorProjector.grid_to_img(p.origin.x + p.def_w, p.origin.y + p.def_h))
		var bottom: float = r.position.y + r.size.y
		# 양수=공중부양(스프라이트 하단이 접촉선보다 위), 음수=파묻힘
		var gap_west: float = west.y - bottom
		var gap_east: float = east.y - bottom
		var max_float: float = maxf(gap_west, gap_east)
		var max_bury: float = maxf(-gap_west, -gap_east)
		var shadow_ok: bool = node.has_meta("ground_shadow") and node.has_meta("shadow_bridge")
		print("MEAS|%s|%s|origin=%s|rect=(%.0f,%.0f %.0fx%.0f)|west_gap=%+.1f east_gap=%+.1f|float=%.1f bury=%.1f|shadow=%s" % [
			fid, tag, p.origin, r.position.x, r.position.y, r.size.x, r.size.y,
			gap_west, gap_east, max_float, max_bury, shadow_ok])
		var img := get_root().get_texture().get_image()
		img.save_png("res://../review/meas_%02d_%s_%s.png" % [idx, fid, tag])

		# 배치 후 뜨는 소원/안내 팝업 닫기 (다음 클릭 차단 방지)
		for btn_name in ["좋아!", "확인", "계속 꾸미기"]:
			var pb := _find_button(flow, btn_name)
			if pb:
				await _frames(45)   # 클릭 가드(350ms) 이후
				await _click_node(pb)
				await _frames(3)
		# 정리: 게임의 이사 로직과 동일하게 그리드 전체 교체(내부 점유맵 포함)
		flow.grid = GridModel.new(16, 12)
		for n in flow.placed_nodes.values():
			n.queue_free()
		flow.placed_nodes.clear()
		flow.gs.purchased.erase(fid)
		flow.agent.on_furniture_changed()
		await _frames(4)
	print("MEAS|DONE")
	quit(0)
