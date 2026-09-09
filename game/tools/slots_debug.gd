extends SceneTree
## 슬롯 배치 좌표 디버그 — godot --headless -s tools/slots_debug.gd --path .

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/concept_flow/concept_flow.tscn")
	var flow: Control = scene.instantiate()
	get_root().add_child(flow)
	await process_frame
	await process_frame
	flow.debug_set("room")
	await process_frame
	for fid in flow.slots["items"]:
		flow.econ.cash_balance += 10_000_000
		flow._try_buy(fid)
		flow._close_reaction()
		await process_frame
	flow._update_hud()
	await process_frame
	await process_frame
	print("=== window 1280x720 ===")
	var fl: Control = flow.get("furniture_layer")
	print("bg rect=", flow.get("bg").get_rect())
	for fid in flow.placed:
		var n: TextureRect = flow.placed[fid]
		print("%-16s rect=%s" % [fid, n.get_rect()])
	var cn: TextureRect = flow.get("char_node")
	print("character rect=", cn.get_rect())
	quit()
