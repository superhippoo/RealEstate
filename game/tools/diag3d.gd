extends Node
var main_scene: Node
var elapsed := 0.0

func _ready() -> void:
	main_scene = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("DIAG children=", main_scene.get_child_count())
	for c in main_scene.get_children():
		print("  - ", c.name, " (", c.get_class(), ") visible=", c.visible if c is CanvasItem or c is Node3D else "-")
	var cam := get_viewport().get_camera_3d()
	print("DIAG cam3d=", cam, " current=", cam.current if cam else "-", " pos=", cam.global_position if cam else "-")
	var fl = main_scene.get_node_or_null("FurnitureLayer") if main_scene.has_node("FurnitureLayer") else null
	print("DIAG furniture_layer=", fl)
	var env = main_scene.get_node_or_null("WorldEnvironment")
	print("DIAG world_env=", env)
	get_tree().quit()
