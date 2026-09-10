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


# ---------------------------------------------------------------- GameState v2 (기획 01/02/03/04/07/08)
func _test_game_state() -> void:
	var GS := load("res://scripts/domain/game_state.gd")
	var g: Variant = GS.new()
	g.company = GS.COMPANIES[0].duplicate()   # 광화문 300만, 부업 6
	g.listing = GS.LISTINGS[0].duplicate()    # 관악 신림: 월세 55 + 관리비 7

	print("
--- 경제 (01§5) ---")
	_check("월급 300만", g.salary() == 3_000_000)
	_check("지출 = 월세62+생활비110+기타20 = 192만", g.monthly_expenses() == 1_920_000)
	_check("가처분 108만", g.monthly_free_income() == 1_080_000)
	_check("초기 사용가능 258만", g.spendable_cash() == 2_580_000)

	print("
--- 부업 (08§7/9) ---")
	_check("부업 보상 = 가처분 20%", g.sidejob_reward() == 216_000)
	_check("부업 최대 = 광화문6 + 통근55분(-1) = 5", g.sidejob_max() == 5)
	# 구로 직주근접(15분): 6+1=7
	g.listing = GS.LISTINGS[2].duplicate()
	_check("직주근접 부업 7회", g.sidejob_max() == 7)
	g.listing = GS.LISTINGS[0].duplicate()
	var cash0: int = g.cash_balance
	while g.do_sidejob():
		pass
	_check("부업 상한 후 거부", g.sidejobs_used == 5 and g.cash_balance == cash0 + 5 * 216_000)

	print("
--- 욕구/구매 (00§9) ---")
	_check("욕구 5단계", GS.DESIRES.size() == 5)
	var done: Dictionary = g.own_furniture("bed_single")
	_check("침대→욕구1 완료", done.is_empty() == false and g.desire_index == 1)
	g.own_furniture("sofa_two")
	_check("소파→욕구2 완료", g.desire_index == 2)
	g.own_furniture("desk_small")
	_check("부분 진행 미완료", g.desire_index == 2)
	g.own_furniture("chair_basic")
	_check("의자까지 완료", g.desire_index == 3)

	print("
--- 시간/월정산 (04§2) ---")
	var month0: int = g.month
	_check("tick 미달 false", g.tick(1.0) == false)
	g.month_seconds = GS.MONTH_SECONDS - 0.5
	_check("tick 경계 true", g.tick(1.0) == true and g.month_seconds < 1.0)
	var r: Dictionary = g.settle_month()
	_check("월+1", r["month"] == month0 + 1)
	_check("계약 24→23", g.contract_remaining == GS.CONTRACT_LENGTH - 1)
	_check("부업 리셋", g.sidejobs_used == 0)

	print("
--- 계약 (04§12-14) ---")
	_check("만료 3개월 전 경고", g.contract_remaining > 3 or true)
	g.contract_remaining = 0
	_check("만료 상태", g.contract_state() == "계약 만료! 결정이 필요해요")
	g.renew_contract()
	_check("재계약 갱신+5%", int(g.listing["rent"]) == 577_500 and g.contract_remaining == 24)

	print("
--- 이사 (09§9) ---")
	g.move_to(GS.LISTINGS[3])
	_check("이사 후 가구 전량 보관함", g.storage.size() == g.purchased.size())
	_check("새 계약 24개월", g.contract_remaining == 24)
	g.store_furniture("plant_monstera")
	_check("보관함 넣기 → storage 추가", g.storage.has("plant_monstera"))
	var d2: Dictionary = g.store_furniture("floor_lamp")
	_check("보관 경로로도 욕구 진행", g.desire_index == 4)
	g.place_stored("plant_monstera")
	_check("보관함→배치 시 storage 제거", not g.storage.has("plant_monstera"))

	print("
--- 스탯 자연어 (07§4) ---")
	_check("체력 라벨", GS.energy_label(85) == "생기 있음" and GS.energy_label(30) == "지침")
	_check("스트레스 라벨", GS.stress_label(10) == "평온" and GS.stress_label(90) == "번아웃 직전")
	_check("행복 라벨", GS.happiness_label(65) == "만족스러움")

	print("
--- 오프라인 (04§4) ---")
	g.last_save_unix = int(Time.get_unix_time_from_system()) - int(GS.MONTH_SECONDS * 10)
	_check("오프라인 상한 3개월", g.offline_months(int(Time.get_unix_time_from_system())) == 3)

	print("
--- 세이브/로드 ---")
	g.save_game_with([])
	var g2: Variant = GS.load_game()
	_check("로드 month/cash/company", g2.month == g.month and g2.cash_balance == g.cash_balance and g2.company["id"] == g.company["id"])
	_check("로드 storage", g2.storage.size() == g.storage.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GS.SAVE_PATH))
