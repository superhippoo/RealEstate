extends SceneTree
## 디버그: 안락의자 배치 상태 검증 — godot --headless -s tools/concept_debug.gd --path .

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	var flow: Control = scene.instantiate()
	var root := Node.new()
	root.add_child(flow)
	get_root().add_child(root)
	await process_frame
	await process_frame
	flow.debug_set("room")
	await process_frame
	await process_frame
	flow._try_buy({"id": "armchair", "name": "안락의자", "price": 180_000,
			"icon": "res://assets/concept/icon_armchair.png"}, Button.new(), Label.new())
	flow._close_reaction()
	await process_frame
	await process_frame
	var chair: TextureRect = flow.get("placed_armchair")
	print("chair node found: ", chair != null)
	if chair:
		print("visible=", chair.visible, " rect=", chair.get_rect(),
			" tex_size=", chair.texture.get_size() if chair.texture else Vector2.ZERO)
		print("purchased=", flow.purchased)
		print("modulate=", chair.modulate, " self_modulate=", chair.self_modulate)
		print("child order:", flow.get_children().map(func(c): return c.name))
		var bg: TextureRect = flow.get("bg")
		print("bg rect=", bg.get_rect(), " pos=", bg.position, " size=", bg.size)
	# 스프라이트 텍스처 자체 검증
	var tex: Texture2D = load("res://assets/concept/sprite_armchair.png")
	var img := tex.get_image()
	var solid := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a >= 0.98:
				solid += 1
	print("texture solid px:", solid, "/", img.get_width() * img.get_height())
	quit()
