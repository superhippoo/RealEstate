extends SceneTree
func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	var flow: Control = scene.instantiate()
	get_root().add_child(flow)
	await process_frame
	await process_frame
	flow._show_job_select()
	flow._pick_job(flow.gs.COMPANIES[0].duplicate())
	flow._pick_listing(flow.gs.LISTINGS[0].duplicate())
	await process_frame
	flow._try_buy("bed_single")
	await process_frame
	flow._try_place_here(flow.grid_to_screen(Vector2i(9, 2)))
	flow._close_all_popups()
	# 사용 상태까지 대기
	var t := 0.0
	while t < 10.0:
		await process_frame
		t += 1.0/60.0
		if flow.agent.get("state") == "using":
			break
	await process_frame
	print("BG=", flow.bg.size, " TEX=", flow.bg.texture.get_size(), " POS=", flow.bg.position)
	print("CENTER=", flow.furniture_center_screen(int(flow.agent.get("use_iid"))))
	print("STATE=", flow.agent.get("state"), " pos=", flow.agent.position,
		" rot=", flow.agent.sprite.rotation_degrees, " scale=", flow.agent.sprite.scale,
		" bubble_vis=", flow.agent.bubble_bg.visible, " bubble_txt=", flow.agent.bubble.text)
	for i in 20:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("res://../review/_agent_dbg.png")
	print("SHOT saved")
	quit()
