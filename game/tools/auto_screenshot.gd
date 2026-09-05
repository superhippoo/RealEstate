extends Node
## CLI 자동 스크린샷: godot --path . -- --screenshot out.png --secs 6
## MVP 시각 검증용. 씬에 오토포드 없이 main.tscn 다음에 이 노드로 씬 교체 실행:
## godot --path . res://tools/auto_screenshot.tscn

var main_scene: Node2D
var elapsed := 0.0
var shot_at := 5.0
var out_path := "user://mvp_screenshot.png"
var placed := false


func _ready() -> void:
	print("SHOT: boot")
	main_scene = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_scene)
	print("SHOT: main added")
	# 검증용: 침대+소파 자동 배치 (캐릭터 사용 모습 확인)
	await get_tree().process_frame
	await get_tree().process_frame
	_place_debug_furniture()
	print("SHOT: furniture placed")


func _place_debug_furniture() -> void:
	var main = main_scene
	var spots := {
		"bed_single": Vector2i(1, 0),
		"sofa_two": Vector2i(4, 4),
		"tv_43": Vector2i(0, 7),
	}
	for def_id in ["bed_single", "sofa_two", "tv_43"]:
		var def: Dictionary = main.db.get_def(def_id)
		var origin: Vector2i = spots[def_id]
		if main.grid.can_place(def["grid_w"], def["grid_h"], origin, 0):
			var iid: int = main.grid.place(def_id, def["grid_w"], def["grid_h"], origin, 0)
			var fs := FurnitureSprite.new()
			fs.setup(iid, def_id)
			main.furniture_layer.add_child(fs)
			fs.refresh(main.grid.get_placement(iid))
			main.sprites[iid] = fs
	main._rebuild_astar()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= shot_at:
		print("SHOT: capturing")
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_path)
		print("SCREENSHOT_SAVED ", ProjectSettings.globalize_path(out_path))
		get_tree().quit()
