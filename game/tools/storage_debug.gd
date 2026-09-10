extends SceneTree
func _initialize() -> void:
	var GS := load("res://scripts/domain/game_state.gd")
	if FileAccess.file_exists(GS.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GS.SAVE_PATH))
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	var flow: Control = scene.instantiate()
	get_root().add_child(flow)
	await process_frame
	await process_frame
	flow._show_job_select()
	flow._pick_job(flow.gs.COMPANIES[0].duplicate())
	flow._pick_listing(flow.gs.LISTINGS[0].duplicate())
	await process_frame
	flow.gs.cash_balance += 6_000_000
	flow._try_buy("sofa_two")
	await process_frame
	print("1) placing=", flow.placing, " spend_ok")
	flow._store_placing()
	await process_frame
	print("2) storage=", flow.gs.storage, " purchased=", flow.gs.purchased.keys())
	flow._open_storage()
	await process_frame
	await process_frame
	var sp: PanelContainer = flow.get("storage_panel")
	print("3) visible=", sp.visible, " rect=", sp.get_rect(), " global_visible=", sp.is_visible_in_tree())
	for i in 8:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("res://../review/_storage_dbg.png")
	print("4) shot saved")
	quit()
