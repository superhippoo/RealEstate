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
	flow._try_place_here(flow.grid_to_screen(Vector2i(1, 9)))   # 먼 곳: 걷는 구간 확보
	flow._close_all_popups()
	# 걷는 중 2컷 (0.16s 간격)
	var shots := []
	for i in 40:
		await process_frame
		if flow.agent.get("state") == "walking" and i in [10, 20]:
			shots.append(get_root().get_texture().get_image())
	for j in shots.size():
		shots[j].save_png("res://../review/_walk_%d.png" % j)
	print("SHOTS=", shots.size())
	quit()
