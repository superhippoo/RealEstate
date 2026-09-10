extends Node
## MVP v4 전체 시나리오 자동 캡처 → review/mvp2_*.png

var flow: Control
var step := 0

const STEPS := [
	["title", "01_title"],
	["job", "02_job_select"],
	["listing", "03_listing_select"],
	["room", "04_room_start"],
	["buy_bed", "05_placing_bed"],
	["bed_placed", "06_bed_placed"],
	["char_walking", "07_char_walking"],
	["char_using", "08_char_using_bed"],
	["settle", "09_month_settle"],
	["sidejob", "10_sidejob"],
	["shortfall", "11_shortfall_tv"],
	["storage", "12_storage"],
	["contract", "13_contract_expiry"],
	["moved", "14_moved_new_room"],
]


func _ready() -> void:
	var GS := load("res://scripts/domain/game_state.gd")
	if FileAccess.file_exists(GS.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GS.SAVE_PATH))
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	flow = scene.instantiate()
	add_child(flow)
	await get_tree().process_frame
	await get_tree().process_frame
	_next()


func _cell_screen(gx: int, gy: int) -> Vector2:
	return flow.grid_to_screen(Vector2i(gx, gy))


func _wait_state(node: Node, prop: String, val: String, timeout_s: float = 6.0) -> bool:
	var t := 0.0
	while t < timeout_s:
		await get_tree().process_frame
		t += get_process_delta_time()
		if node.get(prop) == val:
			return true
	return false


func _next() -> void:
	if step >= STEPS.size():
		print("CAPTURE DONE")
		get_tree().quit()
		return
	var st: String = STEPS[step][0]
	var fname: String = STEPS[step][1]
	match st:
		"title":
			pass
		"job":
			flow._show_job_select()
		"listing":
			flow._pick_job(flow.gs.COMPANIES[0])   # 광화문
		"room":
			flow._pick_listing(flow.gs.LISTINGS[0])  # 관악 신림
			await _frames(10)
		"buy_bed":
			flow._try_buy("bed_single")
		"bed_placed":
			flow._try_place_here(_cell_screen(9, 2))
			flow._close_all_popups()
			await _frames(2)
		"char_walking":
			await _wait_state(flow.agent, "state", "walking", 3.0)
		"char_using":
			await _wait_state(flow.agent, "state", "using", 8.0)
			await _frames(20)   # 말풍선 표시 후
		"settle":
			flow.gs.month_seconds = flow.gs.MONTH_SECONDS - 0.4
			await _frames(40)   # _process에서 boundary 발생
		"sidejob":
			flow._open_sidejob()
			flow._do_sidejob()
			await _frames(6)
		"shortfall":
			flow.gs.cash_balance = 2_000_000   # TV 못 사게
			flow._update_hud()
			flow._try_buy("tv_43")
		"storage":
			flow._close_all_popups()
			flow.gs.cash_balance += 6_000_000
			flow._try_buy("sofa_two")
			await _frames(2)
			flow._store_placing()   # 보관함에 넣기
			await _frames(2)
			flow._open_storage()
		"contract":
			flow._close_all_popups()
			flow.gs.contract_remaining = 0
			flow._contract_expiry()
		"moved":
			flow._do_move(flow.gs.LISTINGS[2])   # 구로 직주근접
			await _frames(6)
	await _frames(6)
	var img := get_viewport().get_texture().get_image()
	var out := "res://../review/mvp2_%s.png" % fname
	img.save_png(out)
	print("saved ", out)
	step += 1
	_next()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
