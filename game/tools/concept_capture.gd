extends Node
## 배치 모드 자동 캡처
## review/place_*.png 저장

var flow: Control
var step := 0

const STEPS := [
	["room_empty", "01_room_empty"],
	["shop", "02_shop"],
	["placing", "03_placing_bed"],
	["placed_bed", "04_bed_placed"],
	["placed_all", "05_all_placed"],
	["collision", "06_collision_red"],
]


func _ready() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	flow = scene.instantiate()
	add_child(flow)
	await get_tree().process_frame
	await get_tree().process_frame
	_next()


func _cell_screen(gx: int, gy: int) -> Vector2:
	# FloorProjector는 이미지 px 반환 → 화면 변환은 flow가 가진 bg 변환 사용
	var img: Vector2 = flow.FloorProjector.cell_center(gx, gy)
	var tex_w: float = flow.bg.texture.get_width()
	return flow.bg.position + img * (flow.bg.size.x / tex_w)


func _next() -> void:
	if step >= STEPS.size():
		print("CAPTURE DONE")
		get_tree().quit()
		return
	var entry: Array = STEPS[step]
	var st: String = entry[0]
	var fname: String = entry[1]
	match st:
		"room_empty":
			flow.debug_set("room")
		"shop":
			flow._open_shop()
		"placing":
			flow._close_shop()
			await _frames(1)
			flow.econ.cash_balance += 1_000_000
			flow._try_buy("bed_single")
		"placed_bed":
			flow._close_reaction()
			await _frames(2)
			flow._try_place_here(_cell_screen(9, 2))  # 침대: 우측 벽쪽 셀
		"placed_all":
			flow._close_reaction()
			await _frames(1)
			# 축: gx=뒤→오른쪽, gy=뒤→왼쪽. gy=0행=뒤오른벽, gx=0열=뒤왼벽
			for pairs in [["rug_oval", [7, 7]], ["desk_small", [2, 2]], ["chair_basic", [2, 5]],
					["sofa_two", [2, 8]], ["armchair", [9, 10]],
					["plant_monstera", [15, 4]], ["floor_lamp", [15, 9]], ["tv_43", [15, 1]],
					["picture_frame", [12, 1]], ["wall_shelf", [1, 2]]]:
				flow.econ.cash_balance += 2_000_000
				flow._try_buy(pairs[0])
				await _frames(1)
				flow._try_place_here(_cell_screen(pairs[1][0], pairs[1][1]))
				await _frames(1)
				flow._close_reaction()
				await _frames(1)
		"collision":
			# 점유 셀 위 배치 시도 → 빨간 고스트. (책상 재구매 시뮬레이션)
			flow.purchased.erase("desk_small")
			flow.econ.cash_balance += 2_000_000
			flow._try_buy("desk_small")
			await _frames(2)
			flow._ghost_follow(_cell_screen(2, 7))
	await _frames(8)
	var img := get_viewport().get_texture().get_image()
	var out := "res://../review/place_%s.png" % fname
	img.save_png(out)
	print("saved ", out)
	step += 1
	_next()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
