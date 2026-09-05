extends SceneTree
## 헤드리스 단위테스트 러너 (GUT 도입 전 MVP용)
## 실행: godot --headless -s tests/run_tests.gd --path .

var passed := 0
var failed := 0


func _initialize() -> void:
	_test_iso_projector()
	_test_grid_place_and_collision()
	_test_grid_rotation()
	_test_local_to_room()
	_test_economy()
	print("\n========================================")
	print("PASSED %d / FAILED %d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + name)


# ---------------------------------------------------------------- IsoProjector
func _test_iso_projector() -> void:
	_check("iso (0,0)->(0,0)", IsoProjector.grid_to_screen(0, 0) == Vector2(0, 0))
	_check("iso (1,0)->(64,32)", IsoProjector.grid_to_screen(1, 0) == Vector2(64, 32))
	_check("iso (0,1)->(-64,32)", IsoProjector.grid_to_screen(0, 1) == Vector2(-64, 32))
	_check("iso roundtrip", IsoProjector.screen_to_grid(IsoProjector.grid_to_screen(7, 3)) == Vector2i(7, 3))
	_check("iso gridf", IsoProjector.gridf_to_screen(0.5, 0.5) == Vector2(0, 32))


# ---------------------------------------------------------------- Grid
func _test_grid_place_and_collision() -> void:
	var g := GridModel.new(13, 10)
	var id := g.place("bed", 4, 8, Vector2i(0, 0), 0)
	_check("place ok", id > 0)
	_check("collide same spot", g.can_place(4, 8, Vector2i(0, 0), 0) == false)
	_check("collide partial", g.can_place(4, 8, Vector2i(3, 0), 0) == false)
	_check("no collide elsewhere", g.can_place(4, 8, Vector2i(5, 0), 0) == true)
	_check("out of bounds", g.can_place(4, 8, Vector2i(10, 0), 0) == false)
	_check("occupied cells count", g.occupied_cells().size() == 32)
	_check("move ok", g.move(id, Vector2i(9, 1), 0) == true)
	_check("old cells freed", g.can_place(4, 8, Vector2i(0, 0), 0) == true)
	g.remove(id)
	_check("remove frees", g.occupied_cells().size() == 0)


func _test_grid_rotation() -> void:
	var g := GridModel.new(13, 10)
	_check("footprint rot0", GridModel.footprint_size(4, 8, 0) == Vector2i(4, 8))
	_check("footprint rot90", GridModel.footprint_size(4, 8, 90) == Vector2i(8, 4))
	var id := g.place("sofa", 6, 3, Vector2i(0, 0), 0)
	_check("rotate in place fits", g.move(id, Vector2i(0, 0), 90) == true)
	var p := g.get_placement(id)
	_check("cells after rot", g.occupied_cells().size() == 18)


func _test_local_to_room() -> void:
	# rot0: 단순 이동
	_check("local rot0", GridModel.local_to_room(Vector2i(2, 2), Vector2i(-1, 0), 4, 8, 0) == Vector2i(1, 2))
	# rot90: (x,y) -> (def_h-1-y, x), 4x8 그리드에서 def_h=8
	_check("local rot90", GridModel.local_to_room(Vector2i(0, 0), Vector2i(0, 0), 4, 8, 90) == Vector2i(7, 0))
	_check("local rot180", GridModel.local_to_room(Vector2i(0, 0), Vector2i(0, 0), 4, 8, 180) == Vector2i(3, 7))
	_check("local rot270", GridModel.local_to_room(Vector2i(0, 0), Vector2i(0, 0), 4, 8, 270) == Vector2i(0, 3))


# ---------------------------------------------------------------- Economy
func _test_economy() -> void:
	var e := MiniEconomy.new()
	_check("initial spendable", e.spendable_cash() == 1550000)
	_check("cannot buy TV", e.try_spend(2900000) == false)
	_check("shortfall TV", e.shortfall(2900000) == 1350000)
	_check("buy sofa ok", e.try_spend(1200000) == true)
	_check("cash after sofa", e.cash_balance == 3300000)
	var r := e.settle_month()
	_check("settle net", r["net"] == 50000)
	_check("month advanced", e.month == 2)
	_check("cash after settle", e.cash_balance == 3350000)
