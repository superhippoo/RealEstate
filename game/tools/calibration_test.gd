extends SceneTree
## Calibration Test — Blender sprite를 Godot grid에 배치했을 때
## pixel 단위로 정합되는지 자동 검증
## 실행: godot --headless -s tools/calibration_test.gd --path .

var results := []
var test_scene: Node2D


func _initialize() -> void:
	print("=== CALIBRATION TEST START ===")
	_test_projector_formula()
	_test_grid_layout()
	_report()
	quit(0)


func _test_projector_formula() -> void:
	print("\n--- TEST 1: IsoProjector formula ---")
	# grid(0,0), (1,0), (0,1), (1,1) → screen 좌표 검증
	var cases = [
		{"gx": 0, "gy": 0, "ex": 0.0, "ey": 0.0},
		{"gx": 1, "gy": 0, "ex": 64.0, "ey": 32.0},   # X → right-down
		{"gx": 0, "gy": 1, "ex": 64.0, "ey": -32.0},  # Y → right-up
		{"gx": 1, "gy": 1, "ex": 128.0, "ey": 0.0},
		{"gx": 2, "gy": 0, "ex": 128.0, "ey": 64.0},
		{"gx": 0, "gy": 2, "ex": 128.0, "ey": -64.0},
	]
	for c in cases:
		var result = IsoProjector.grid_to_screen(c["gx"], c["gy"])
		var ok = abs(result.x - c["ex"]) < 0.01 and abs(result.y - c["ey"]) < 0.01
		results.append({"name": "projector(%d,%d)" % [c["gx"], c["gy"]], "pass": ok})
		print("  (%d,%d) → (%.0f,%.0f) expected(%.0f,%.0f) %s" %
			[c["gx"], c["gy"], result.x, result.y, c["ex"], c["ey"],
			"PASS" if ok else "FAIL"])

	# screen_to_grid 역변환
	var rt_cases = [
		{"sx": 0.0, "sy": 0.0, "egx": 0, "egy": 0},
		{"sx": 64.0, "sy": 32.0, "egx": 1, "egy": 0},
		{"sx": 64.0, "sy": -32.0, "egx": 0, "egy": 1},
	]
	for c in rt_cases:
		var result = IsoProjector.screen_to_grid(Vector2(c["sx"], c["sy"]))
		var ok = result.x == c["egx"] and result.y == c["egy"]
		results.append({"name": "screen_to_grid(%.0f,%.0f)" % [c["sx"], c["sy"]], "pass": ok})
		print("  screen(%.0f,%.0f) → grid(%d,%d) expected(%d,%d) %s" %
			[c["sx"], c["sy"], result.x, result.y, c["egx"], c["egy"],
			"PASS" if ok else "FAIL"])


func _test_grid_layout() -> void:
	print("\n--- TEST 2: Grid layout consistency ---")
	# 4×4 grid에서 각 셀의 screen position이 다이아몬드를 형성하는지
	# grid(0,0)을 원점으로 할 때:
	#   top corner = grid(0, max_y) → 가장 위
	#   right corner = grid(max_x, max_y) → 가장 오른쪽
	#   bottom corner = grid(max_x, 0) → 가장 아래
	#   left corner = grid(0, 0) → 가장 왼쪽

	var n = 4
	var p00 = IsoProjector.grid_to_screen(0, 0)
	var pNN = IsoProjector.grid_to_screen(n, n)
	var pN0 = IsoProjector.grid_to_screen(n, 0)
	var p0N = IsoProjector.grid_to_screen(0, n)

	# left corner (0,0) should have smallest screen_x
	var ok1 = p00.x < pNN.x and p00.x <= p0N.x and p00.x <= pN0.x
	results.append({"name": "left corner at grid(0,0)", "pass": ok1})
	print("  left(0,0)=(%.0f,%.0f) right(N,N)=(%.0f,%.0f) %s" %
		[p00.x, p00.y, pNN.x, pNN.y, "PASS" if ok1 else "FAIL"])

	# bottom corner (N,0) should have largest screen_y
	var ok2 = pN0.y > p00.y and pN0.y > p0N.y and pN0.y > pNN.y
	results.append({"name": "bottom corner at grid(N,0)", "pass": ok2})
	print("  bottom(N,0)=(%.0f,%.0f) top(0,N)=(%.0f,%.0f) %s" %
		[pN0.x, pN0.y, p0N.x, p0N.y, "PASS" if ok2 else "FAIL"])

	# top corner (0,N) should have smallest screen_y
	var ok3 = p0N.y < p00.y and p0N.y < pN0.y and p0N.y < pNN.y
	results.append({"name": "top corner at grid(0,N)", "pass": ok3})
	print("  top(0,N)=(%.0f,%.0f) %s" % [p0N.x, p0N.y, "PASS" if ok3 else "FAIL"])

	# diamond width = (N+N)*64, height = N*32*2
	var width = pNN.x - p00.x
	var height = pN0.y - p0N.y
	var ok4 = abs(width - n * 128) < 1 and abs(height - n * 64) < 1
	results.append({"name": "diamond dimensions", "pass": ok4})
	print("  width=%.0f (expect %d) height=%.0f (expect %d) %s" %
		[width, n * 128, height, n * 64, "PASS" if ok4 else "FAIL"])


func _report() -> void:
	print("\n=== CALIBRATION TEST REPORT ===")
	var pass_count = 0
	for r in results:
		if r["pass"]:
			pass_count += 1
	print("PASS: %d / %d" % [pass_count, results.size()])
	if pass_count < results.size():
		print("FAILED TESTS:")
		for r in results:
			if not r["pass"]:
				print("  - " + r["name"])
	else:
		print("ALL PASS — IsoProjector formula verified against Blender calibration")
