extends Node
## 진짜 MVP 전체 흐름 자동 캡처 → review/mvp_*.png

var flow: Control
var step := 0

const STEPS := [
	["title", "01_title_menu"],
	["room_desire", "02_desire_panel"],
	["shop", "03_shop"],
	["shortfall", "04_shortfall_sidejob"],
	["sidejob", "05_sidejob"],
	["placing", "06_placing"],
	["celebrate", "07_desire_done"],
	["settle", "08_month_settle"],
	["goal", "09_goal"],
]


func _ready() -> void:
	# 세이브 초기화 후 새 게임
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
	var img: Vector2 = flow.FloorProjector.cell_center(gx, gy)
	var tex_w: float = flow.bg.texture.get_width()
	return flow.bg.position + img * (flow.bg.size.x / tex_w)


func _next() -> void:
	if step >= STEPS.size():
		print("CAPTURE DONE")
		get_tree().quit()
		return
	var st: String = STEPS[step][0]
	var fname: String = STEPS[step][1]
	match st:
		"title":
			pass  # _ready 상태 그대로 (타이틀 + 메뉴 팝업)
		"room_desire":
			flow._start_new_game()
			await _frames(1)
			flow.show_screen("filter")   # 지도→필터→매물→집 스킵
			flow.show_screen("listing")
			flow.show_screen("house")
			flow.show_screen("room")
		"shop":
			flow._open_shop()
		"shortfall":
			flow._close_popup()
			await _frames(1)
			flow._try_buy("tv_43")   # 290만 > 사용가능 225만 → 부족 팝업
		"sidejob":
			flow._open_sidejob()
			await _frames(1)
		"placing":
			flow._close_popup()
			await _frames(1)
			flow._try_buy("bed_single")
		"celebrate":
			await _frames(1)
			flow._try_place_here(_cell_screen(9, 2))
			await _frames(2)   # 욕구 완료 축하 팝업
		"settle":
			flow._close_popup()
			await _frames(1)
			flow._next_month()
		"goal":
			# 골 직전까지 빠르게 진행
			flow._close_popup()
			await _frames(1)
			for pairs in [["sofa_two", [2, 8]], ["desk_small", [2, 2]], ["chair_basic", [2, 5]],
					["plant_monstera", [15, 4]], ["floor_lamp", [15, 9]]]:
				flow.gs.cash_balance += 3_000_000
				flow._try_buy(pairs[0])
				await _frames(1)
				flow._try_place_here(_cell_screen(pairs[1][0], pairs[1][1]))
				await _frames(1)
				flow._close_popup()
				await _frames(1)
			flow.gs.cash_balance += 3_000_000
			flow._try_buy("tv_43")
			await _frames(1)
			flow._try_place_here(_cell_screen(15, 1))
			await _frames(2)
	await _frames(8)
	var img := get_viewport().get_texture().get_image()
	var out := "res://../review/mvp_%s.png" % fname
	img.save_png(out)
	print("saved ", out)
	step += 1
	_next()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
