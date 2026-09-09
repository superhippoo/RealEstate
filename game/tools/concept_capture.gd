extends Node
## 컨셉 플로우 자동 캡처:
## godot --path . res://tools/concept_capture.tscn --headless --rendering-driver opengl3
## 각 화면 상태를 순회하며 review/concept_flow_*.png 저장 (window mode 필요 → 비headless 권장)

var flow: Control
var step := 0

const STEPS := [
	["title", "01_title"],
	["map", "02_map"],
	["filter", "03_filter"],
	["listing", "04_listing"],
	["house", "05_house"],
	["room", "06_room"],
	["room+shop", "07_shop"],
	["room+chair", "08_chair_placed"],
	["reaction", "09_reaction"],
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
	var state: String = entry[0]
	var fname: String = entry[1]
	match state:
		"room+shop":
			flow.debug_set("room")
			await _frames(2)
			flow._open_shop()
		"room+chair":
			flow.debug_set("room")
			await _frames(2)
			flow._try_buy({"id": "armchair", "name": "안락의자", "price": 180_000,
					"icon": "res://assets/concept/icon_armchair.png"},
					Button.new(), Label.new())
			await _frames(4)
			flow._close_reaction()
		_:
			flow.debug_set(state)
	await _frames(8)
	var img := get_viewport().get_texture().get_image()
	var out := "res://../review/concept_%s.png" % fname
	img.save_png(out)
	print("saved ", out)
	step += 1
	_next()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
