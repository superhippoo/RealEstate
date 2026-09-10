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
	_test_game_state()
	_test_layers()
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
	_check("iso (0,1)->(64,-32)", IsoProjector.grid_to_screen(0, 1) == Vector2(64, -32))
	_check("iso roundtrip", IsoProjector.screen_to_grid(IsoProjector.grid_to_screen(7, 3)) == Vector2i(7, 3))
	_check("iso gridf", IsoProjector.gridf_to_screen(0.5, 0.5) == Vector2(64, 0))


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


func _test_layers() -> void:
	var g := GridModel.new(16, 12)
	# 러그(UNDERLAY): 어디든, 무충돌
	_check("rug place under bed area", g.place("rug", 6, 4, Vector2i(4, 4), 0, GridModel.Layer.UNDERLAY) > 0)
	var bed := g.place("bed", 4, 8, Vector2i(1, 0), 0, GridModel.Layer.FLOOR)
	_check("bed over rug ok", bed > 0)
	_check("rug not blocking pathfinding", g.occupied_cells().size() == 32)  # 침대만
	# 벽걸이(WALL): 벽면 행만, FLOOR와 무충돌
	_check("wall item at gx=0 ok", g.place("pic", 2, 2, Vector2i(0, 2), 0, GridModel.Layer.WALL) > 0)
	_check("wall item mid-room rejected", g.can_place(2, 2, Vector2i(5, 5), 0, GridModel.Layer.WALL) == false)
	_check("wall collides with wall", g.can_place(2, 2, Vector2i(0, 2), 0, GridModel.Layer.WALL) == false)
	_check("floor item under wall item ok", g.can_place(2, 2, Vector2i(0, 9), 0, GridModel.Layer.FLOOR) == true)
	_check("wall item not in pathfinding", g.occupied_cells().size() == 32)


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


# ---------------------------------------------------------------- GameState (진짜 MVP)
func _test_game_state() -> void:
	var GS := load("res://scripts/domain/game_state.gd")
	var g: Variant = GS.new()
	print("
--- GameState: 기획 밸런스 (01/08) ---")
	_check("월급 300만", GS.SALARY == 3_000_000)
	_check("월 지출 225만", GS.MONTHLY_EXPENSES == 2_250_000)
	_check("가처분 75만", GS.SALARY - GS.MONTHLY_EXPENSES == 750_000)
	_check("부업 보상 20만", GS.SIDEJOB_REWARD == 200_000)
	_check("부업 월 5회 제한", GS.SIDEJOB_MAX_PER_MONTH == 5)
	_check("초기 사용가능 225만", g.spendable_cash() == 2_250_000)

	print("
--- GameState: 욕구 체인 (00 §9) ---")
	_check("욕구 수 5", GS.DESIRES.size() == 5)
	_check("첫 욕구 침대", GS.DESIRES[0]["items"] == ["bed_single"])
	var done: Dictionary = g.on_furniture_owned("bed_single")
	_check("침대로 첫 욕구 완료", done.is_empty() == false and g.desire_index == 1)
	_check("행복 상승", g.happiness > 55)
	# 욕구 2: 소파
	var d2: Dictionary = g.on_furniture_owned("sofa_two")
	_check("소파로 욕구2 완료", d2.is_empty() == false and g.desire_index == 2)
	# 욕구 3: 책상+의자 (부분 진행)
	g.on_furniture_owned("desk_small")
	_check("책상만으로는 미완료", g.desire_index == 2)
	g.on_furniture_owned("chair_basic")
	_check("의자까지 완료", g.desire_index == 3)

	print("
--- GameState: 부업 (08) ---")
	var cash0: int = g.cash_balance
	for i in 5:
		_check("부업 %d회 성공" % (i + 1), g.do_sidejob() == true)
	_check("부업 6회째 거부", g.do_sidejob() == false)
	_check("부업 수입 +100만", g.cash_balance == cash0 + 1_000_000)
	_check("부업 체력 소모", g.energy < 70)

	print("
--- GameState: 월 정산 (01/04) ---")
	var c1: int = g.cash_balance
	var r: Dictionary = g.settle_month()
	_check("월 경과", r["month"] == 2 and g.month == 2)
	_check("월 순수입 +75만", g.cash_balance == c1 + 750_000 + int(r["event"].get("cash", 0)))
	_check("부업 리셋", g.sidejobs_used == 0 and g.month_sidejob_income == 0)

	print("
--- GameState: 만족도/목표 (07) ---")
	g.on_furniture_owned("plant_monstera")
	g.on_furniture_owned("floor_lamp")
	g.on_furniture_owned("tv_43")
	_check("모든 욕구 완료 → goal_done", g.goal_done == true and g.desire_index == 5)
	_check("만족도 100%", absf(g.room_satisfaction() - 1.0) < 0.01)
	_check("만족도 라벨 매우 좋음", g.satisfaction_label() == "매우 좋음")

	print("
--- GameState: 세이브/로드 ---")
	g.save_game_with([])
	var g2: Variant = GS.load_game()
	_check("로드 month", g2.month == g.month)
	_check("로드 cash", g2.cash_balance == g.cash_balance)
	_check("로드 purchased", g2.purchased.size() == g.purchased.size())
	_check("로드 desire_index", g2.desire_index == g.desire_index)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GS.SAVE_PATH))
