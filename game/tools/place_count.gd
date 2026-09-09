extends SceneTree
func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	var flow: Control = scene.instantiate()
	get_root().add_child(flow)
	await process_frame
	await process_frame
	flow.debug_set("room")
	await process_frame
	var n := 0
	for pairs in [["bed_single", [9, 2]], ["desk_small", [2, 2]], ["chair_basic", [2, 5]],
			["sofa_two", [2, 8]], ["rug_oval", [7, 7]], ["armchair", [9, 10]],
			["plant_monstera", [15, 4]], ["floor_lamp", [15, 9]], ["tv_43", [15, 1]],
			["picture_frame", [12, 1]], ["wall_shelf", [1, 2]]]:
		flow.econ.cash_balance += 2_000_000
		flow._try_buy(pairs[0])
		await process_frame
		var tex_w: float = flow.bg.texture.get_width()
		var img: Vector2 = flow.FloorProjector.cell_center(pairs[1][0], pairs[1][1])
		flow._try_place_here(flow.bg.position + img * (flow.bg.size.x / tex_w))
		await process_frame
		flow._close_reaction()
		await process_frame
		var ok: bool = flow.grid.placements.size() > n
		n = flow.grid.placements.size()
		print(pairs[0], " → ", "OK" if ok else "FAIL")
	print("placed_nodes=", flow.placed_nodes.size(), " placing='", flow.placing, "'")
	print("grid placements=", flow.grid.placements.size())
	quit()
