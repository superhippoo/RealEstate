extends Node3D
func _ready() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2, 3)
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	cam.make_current()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.5, 1.5, 1.5)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.4, 0.2)
	mi.material_override = m
	add_child(mi)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-45, -30, 0)
	add_child(l)
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://mini3d.png")
	print("MINI3D_SAVED ", ProjectSettings.globalize_path("user://mini3d.png"))
	get_tree().quit()
