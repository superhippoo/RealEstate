extends Node
## 컨셉 플로우 자동 캡처 (GPT 스프라이트 버전)
## 각 상태를 순회하며 review/concept2_*.png 저장

var flow: Control
var step := 0

const STEPS := [
	["room_empty", "01_room_empty"],
	["room+shop", "02_shop"],
	["room+bed", "03_bed"],
	["room+half", "04_half"],
	["room+all", "05_all"],
	["reaction", "06_reaction"],
]


func _ready() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	flow = scene.instantiate()
	add_child(flow)
	await get_tree().process_frame
	await get_tree().process_frame
	_next()


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
		"room+shop":
			flow.debug_set("room")
			await _frames(2)
			flow._open_shop()
		"room+bed":
			flow._close_shop()
			await _frames(1)
			flow._try_buy("bed_single")
			await _frames(2)
			flow._close_reaction()
		"room+half":
			flow.econ.cash_balance += 5_000_000
			flow._update_hud()
			for fid in ["rug_oval", "sofa_two", "plant_monstera", "floor_lamp"]:
				flow._try_buy(fid)
				await _frames(2)
				flow._close_reaction()
				await _frames(1)
		"room+all":
			flow.econ.cash_balance += 5_000_000
			flow._update_hud()
			for fid in ["desk_small", "chair_basic", "tv_43", "picture_frame",
					"wall_shelf", "armchair"]:
				flow._try_buy(fid)
				await _frames(2)
				flow._close_reaction()
				await _frames(1)
		"reaction":
			flow._open_reaction()
			await _frames(3)
	await _frames(8)
	var img := get_viewport().get_texture().get_image()
	var out := "res://../review/concept2_%s.png" % fname
	img.save_png(out)
	print("saved ", out)
	step += 1
	_next()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
