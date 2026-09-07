extends Node3D
## 3D 메인 씬 — 실시간 3D 렌더링 (제안 A)
## 게임 로직(GridModel/MiniEconomy/FurnitureDB)은 2D와 동일, 표현 계층만 3D.

const ROOM_W := 16
const ROOM_H := 12
const CELL := 0.25

# 컨셉 팔레트 (채도 상향 +20%)
const C_WOOD := Color(0.88, 0.52, 0.24)
const C_WOOD_L := Color(0.92, 0.62, 0.30)
const C_WOOD_D := Color(0.58, 0.33, 0.15)
const C_WALL := Color(1.0, 0.78, 0.62)
const C_WALL2 := Color(0.97, 0.75, 0.60)
const C_TRIM := Color(0.93, 0.68, 0.55)
const C_SAGE := Color(0.50, 0.70, 0.34)
const C_CREAM := Color(1.0, 0.92, 0.75)
const C_PLANT := Color(0.12, 0.48, 0.20)
const C_TERRA := Color(0.92, 0.40, 0.25)

var grid: GridModel
var db: FurnitureDB
var economy := MiniEconomy.new()
var astar := AStarGrid2D.new()

var furniture_layer: Node3D
var preview_layer: Node3D
var agent: Node3D

var sprites := {}          # instance_id -> Node3D
var placement_def_id := ""
var placement_rot := 0

# UI
var ui: CanvasLayer
var label_month: Label
var label_cash: Label
var label_hint: Label
var shop_panel: PanelContainer
var shop_rows: VBoxContainer
var settle_popup: PanelContainer
var settle_text: Label

# 배치 프리뷰 풀
var _preview_pool: Array[MeshInstance3D] = []


func _ready() -> void:
	randomize()
	var font := load("res://assets/fonts/NotoSansKR.ttf")
	if font:
		ThemeDB.fallback_font = font
		ThemeDB.fallback_font_size = 18
	db = FurnitureDB.load_default()
	grid = GridModel.new(ROOM_W, ROOM_H)
	astar.region = Rect2i(0, 0, ROOM_W, ROOM_H)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	_build_world()
	_build_ui()
	_update_hud()


# ================================================================ 월드
var _cozy_shader: Shader

func _get_cozy_shader() -> Shader:
	if _cozy_shader == null:
		_cozy_shader = load("res://shaders/cozy_toon.gdshader")
	return _cozy_shader


func _mat(color: Color, rough := 0.9) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _get_cozy_shader()
	m.set_shader_parameter("albedo", Color(color.r, color.g, color.b, 1.0))
	m.set_shader_parameter("roughness", rough)
	m.set_shader_parameter("rim_strength", 0.5)
	m.set_shader_parameter("warmth", 0.12)
	m.set_shader_parameter("saturation_boost", 1.35)
	m.set_shader_parameter("brightness_target", 0.60)
	return m


func _emat(color: Color, emission_color: Color, energy: float) -> StandardMaterial3D:
	"""발광 재질 (램프/창문/펜던트) — StandardMaterial3D 유지"""
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = emission_color
	m.emission_energy_multiplier = energy
	return m


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rough := 0.9) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color, rough)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_world() -> void:
	# 조명/환경 (저녁 램프 아래 아늑한 방 감 — 레퍼런스 정량 매칭)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.06, 0.05)  # 어두운 배경 (방이 돋보이게)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.85, 0.72)  # 따뜻한 앰비언트
	env.ambient_light_energy = 0.18  # 낮게 → 그림자 대비 강화
	# 글로우 (램프/창문 발광이 크게 퍼짐 — 아늑함 핵심)
	env.glow_enabled = true
	env.glow_intensity = 1.2
	env.glow_strength = 1.3
	env.glow_bloom = 0.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.8
	# 색보정 (레퍼런스 채도 0.42 매칭 + 대비)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.45  # 어둡게 → 레퍼런스 평균 144 매칭
	env.tonemap_white = 4.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.65  # 0.26→0.42 목표
	env.adjustment_contrast = 1.15
	env.adjustment_saturation = 1.25
	env.adjustment_contrast = 1.05
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.88, 0.75)  # 따뜻한 저녁 햇살
	sun.light_energy = 2.5  # 강하게 → 대비 (밝은 곳/그림자 차이)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 12.0
	sun.shadow_blur = 3.0
	sun.rotation_degrees = Vector3(-55, -35, 0)
	add_child(sun)

	# 보조 필 (시원한 산란광 — 그림자가 완전 검정이 되지 않게)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.60, 0.65, 0.85)
	fill.light_energy = 0.55
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-40, 120, 0)
	add_child(fill)

	# 카메라: 직교 아이소(요 45도, 피치 30도)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 4.1
	var center := Vector3(ROOM_W * CELL / 2.0, 0.4, ROOM_H * CELL / 2.0)
	var dir := Vector3(1, 1.1, 1).normalized()
	cam.position = center + dir * 10.0
	add_child(cam)
	cam.look_at(center, Vector3.UP)
	cam.make_current()

	# 바닥 베이스 + 플랭크
	var floor_n := Node3D.new()
	add_child(floor_n)
	_box(floor_n, Vector3(2, -0.01, 1.5), Vector3(4.06, 0.02, 3.06), C_WOOD_D)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var pw := 0.5
	for row in range(7):
		var y0 := row * pw
		var x := -(row % 2) * 0.9
		while x < 4.0:
			var x0: float = maxf(x, 0.0)
			var x1: float = minf(x + 1.35, 4.0)
			if x1 - x0 > 0.1:
				var v := rng.randf_range(-0.05, 0.05)
				var c := Color(C_WOOD.r + v, C_WOOD.g + v * 0.8, C_WOOD.b + v * 0.6)
				_box(floor_n, Vector3((x0 + x1) / 2, 0.022, y0 + pw / 2),
					Vector3(x1 - x0 - 0.004, 0.045, pw - 0.005), c)
			x += 1.35

	# 벽 2면 + 몰딩
	var walls := Node3D.new()
	add_child(walls)
	_box(walls, Vector3(2, 0.575, -0.04), Vector3(4.08, 1.15, 0.08), C_WALL)
	_box(walls, Vector3(-0.04, 0.575, 1.5), Vector3(0.08, 1.15, 3.08), C_WALL2)
	_box(walls, Vector3(2, 0.065, 0.025), Vector3(4.0, 0.13, 0.05), C_WOOD_L)
	_box(walls, Vector3(0.025, 0.065, 1.5), Vector3(0.05, 0.13, 3.0), C_WOOD_L)
	_box(walls, Vector3(2, 1.125, -0.06), Vector3(4.08, 0.05, 0.12), C_TRIM)
	_box(walls, Vector3(-0.06, 1.125, 1.5), Vector3(0.12, 0.05, 3.08), C_TRIM)

	# 창문 (-X 벽): 프레임 + 발광 유리
	var win := Node3D.new()
	add_child(win)
	var wy := 0.9
	var wz := 1.5
	_box(win, Vector3(0.06, 1.15, wz), Vector3(0.06, 0.62, 1.0), C_WOOD_L)
	var pane := MeshInstance3D.new()
	var pq_mesh := BoxMesh.new()
	pq_mesh.size = Vector3(0.02, 0.56, 0.94)
	pane.mesh = pq_mesh
	pane.material_override = _emat(Color(1, 0.96, 0.9), Color(1.0, 0.94, 0.82), 1.4)
	pane.position = Vector3(0.03, 1.15, wz)
	win.add_child(pane)
	_box(win, Vector3(0.06, 0.86, wz), Vector3(0.07, 0.06, 1.06), C_WOOD_L)
	_box(win, Vector3(0.06, 1.45, wz), Vector3(0.07, 0.06, 1.06), C_WOOD_L)
	_box(win, Vector3(0.06, 1.15, wz - 0.5), Vector3(0.07, 0.62, 0.06), C_WOOD_L)
	_box(win, Vector3(0.06, 1.15, wz + 0.5), Vector3(0.07, 0.62, 0.06), C_WOOD_L)
	_box(win, Vector3(0.06, 1.15, wz), Vector3(0.06, 0.62, 0.05), C_WOOD_L)

	# 주방 (-Z 벽): 카운터/상부장/후드/냉장고 + 소품/타일/손잡이
	var kit := Node3D.new()
	add_child(kit)
	_box(kit, Vector3(1.6, 0.38, 0.33), Vector3(3.1, 0.68, 0.6), C_WOOD)
	_box(kit, Vector3(1.6, 0.75, 0.33), Vector3(3.15, 0.06, 0.66), C_CREAM, 0.5)
	# 백스플래시 타일 (세이지)
	_box(kit, Vector3(1.6, 1.05, 0.05), Vector3(3.15, 0.48, 0.02), Color(0.48, 0.68, 0.36), 0.3)
	_box(kit, Vector3(0.7, 1.55, 0.19), Vector3(1.3, 0.56, 0.34), C_CREAM)
	_box(kit, Vector3(2.05, 1.5, 0.2), Vector3(0.52, 0.4, 0.36), C_CREAM)
	_box(kit, Vector3(3.6, 0.85, 0.35), Vector3(0.62, 1.7, 0.68), C_CREAM)
	_box(kit, Vector3(3.6, 1.25, 0.70), Vector3(0.04, 0.5, 0.05), Color(0.75, 0.72, 0.68), 0.4)
	_box(kit, Vector3(3.6, 0.55, 0.70), Vector3(0.04, 0.36, 0.05), Color(0.75, 0.72, 0.68), 0.4)
	# 캐비닛 슬릿 손잡이 4개
	for i in range(4):
		_box(kit, Vector3(0.35 + i * 0.75, 0.62, 0.638), Vector3(0.48, 0.02, 0.015), C_WOOD_D)
	# 싱크 + 수도꼭지
	var sink_m := MeshInstance3D.new()
	var sink_mesh := CylinderMesh.new()
	sink_mesh.top_radius = 0.13; sink_mesh.bottom_radius = 0.11; sink_mesh.height = 0.03
	sink_m.mesh = sink_mesh
	sink_m.material_override = _mat(Color(0.75, 0.77, 0.80), 0.3)
	sink_m.position = Vector3(0.55, 0.775, 0.33)
	kit.add_child(sink_m)
	_box(kit, Vector3(0.55, 0.88, 0.15), Vector3(0.015, 0.16, 0.015), Color(0.72, 0.74, 0.76), 0.3)
	_box(kit, Vector3(0.55, 0.95, 0.22), Vector3(0.015, 0.015, 0.14), Color(0.72, 0.74, 0.76), 0.3)
	# 소품: 도마 + 커피머신 + 머그 + 그릇
	_box(kit, Vector3(1.5, 0.80, 0.30), Vector3(0.30, 0.018, 0.20), Color(0.82, 0.72, 0.55), 0.6)
	_box(kit, Vector3(2.30, 0.88, 0.30), Vector3(0.14, 0.20, 0.13), Color(0.25, 0.23, 0.21), 0.4)
	_box(kit, Vector3(2.10, 0.81, 0.32), Vector3(0.06, 0.07, 0.06), C_TERRA)
	_box(kit, Vector3(1.15, 0.80, 0.38), Vector3(0.12, 0.012, 0.12), Color(0.96, 0.94, 0.90), 0.3)
	# 펜던트 2
	for px in [1.05, 1.72]:
		var glow := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.13, 0.1, 0.13)
		glow.mesh = gm
		glow.material_override = _emat(Color(1, 0.95, 0.85), Color(1.0, 0.9, 0.7), 1.8)
		glow.position = Vector3(px, 1.5, 0.33)
		kit.add_child(glow)

	# 시어 커튼 (창문 양옆)
	for sz in [-0.62, 0.62]:
		_box(win, Vector3(0.08, 1.15, wz + sz), Vector3(0.04, 0.55, 0.14), Color(0.97, 0.94, 0.88), 0.95)
	# 창문 빛 패치 (바닥에 떨어지는 따뜻한 빛)
	var light_patch := MeshInstance3D.new()
	var pq := PlaneMesh.new()
	pq.size = Vector2(0.6, 1.4)
	light_patch.mesh = pq
	var lm := StandardMaterial3D.new()
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.albedo_color = Color(1.0, 0.92, 0.75, 0.12)
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.emission_enabled = true
	lm.emission = Color(1.0, 0.90, 0.70)
	lm.emission_energy_multiplier = 0.15
	light_patch.material_override = lm
	light_patch.rotation_degrees = Vector3(-90, 0, 0)
	light_patch.position = Vector3(0.35, 0.055, wz)
	add_child(light_patch)

	# 가구 레이어 + 프리뷰 풀
	furniture_layer = Node3D.new()
	add_child(furniture_layer)
	preview_layer = Node3D.new()
	add_child(preview_layer)
	for i in range(48):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(CELL * 0.96, 0.02, CELL * 0.96)
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.61, 0.69, 0.38, 0.55)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = m
		mi.visible = false
		preview_layer.add_child(mi)
		_preview_pool.append(mi)

	# 캐릭터
	var agent_script := load("res://scripts/character/char_agent_3d.gd")
	agent = Node3D.new()
	agent.set_script(agent_script)
	add_child(agent)
	agent.setup(self)


func cell_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= ROOM_W or cell.y >= ROOM_H:
		return false
	return not astar.is_point_solid(cell)


func _rebuild_astar() -> void:
	astar.update()
	for cell in grid.occupied_cells():
		astar.set_point_solid(cell, true)
	agent.notify_grid_changed()


# ================================================================ 가구 표현
func _make_furniture_node(def_id: String, placement: GridModel.Placement) -> Node3D:
	var def: Dictionary = db.get_def(def_id)
	var node := Node3D.new()
	var model_id: String = def.get("model", "")
	if model_id != "" and FileAccess.file_exists("res://assets/models/%s.glb" % model_id):
		var scene: PackedScene = load("res://assets/models/%s.glb" % model_id)
		node = scene.instantiate()
		# CC0 모델 재질을 팔레트로 오버라이드
		_recolor_glb(node)
		# 가구별 소품 추가 (표면 위)
		_add_props_to_glb(node, def_id)
	else:
		node = _procedural_furniture(def_id, def)
	# 접촉 그림자 (가구 밑 어두운 타원)
	_add_contact_shadow(node, def, placement.rotation)
	# 위치/회전: footprint 중심
	var fp := GridModel.footprint_size(def["grid_w"], def["grid_h"], placement.rotation)
	node.position = Vector3((placement.origin.x + fp.x / 2.0) * CELL, 0,
			(placement.origin.y + fp.y / 2.0) * CELL)
	node.rotation_degrees.y = -placement.rotation
	return node


func _recolor_glb(node: Node) -> void:
	"""glTF 모델의 재질을 프로젝트 팔레트로 교체 (색감 통일)"""
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := mi.material_override
		if mat == null and mi.mesh and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			var c: Color = sm.albedo_color
			# 재질명 기반 대응은 어려우므로 색 기반 히스토그램 매칭
			var lum := (c.r + c.g + c.b) / 3.0
			if lum > 0.8:
				sm.albedo_color = Color(0.95, 0.90, 0.80)  # 크림/시트
			elif lum > 0.5:
				if c.g > c.r:
					sm.albedo_color = Color(0.50, 0.68, 0.36)  # 세이지
				else:
					sm.albedo_color = Color(0.85, 0.58, 0.32)  # 우드 라이트
			elif lum > 0.25:
				sm.albedo_color = Color(0.60, 0.38, 0.20)  # 우드 다크
			else:
				sm.albedo_color = Color(0.25, 0.22, 0.20)  # 다크
			sm.roughness = 0.75
			sm.metallic = 0.0
	for c in node.get_children():
		_recolor_glb(c)


func _add_props_to_glb(node: Node3D, def_id: String) -> void:
	"""CC0 가구 위에 소품 추가 (생활감)"""
	match def_id:
		"bed_single":
			# 침대 위: 책 + 베개 옆 작은 쿠션
			_box(node, Vector3(0.18, 0.62, 0.30), Vector3(0.15, 0.03, 0.11), C_TERRA, 0.9)
			_box(node, Vector3(-0.20, 0.66, -0.45), Vector3(0.28, 0.10, 0.24), Color(0.95, 0.75, 0.55), 0.95)
		"sofa_two":
			# 소파: 던지면 쿠션(테라코타) + 담요(머스터드)
			_box(node, Vector3(0.15, 0.52, 0.0), Vector3(0.30, 0.10, 0.30), C_TERRA, 0.95)
			_box(node, Vector3(-0.48, 0.55, 0.0), Vector3(0.10, 0.20, 0.45), Color(0.90, 0.72, 0.35), 0.95)
		"chair_basic":
			# 의자 방석 위 작은 쿠션
			pass
		"desk_table":
			# 책상: 컵 + 책 2권
			var cup := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.032
			cyl.bottom_radius = 0.028
			cyl.height = 0.07
			cup.mesh = cyl
			cup.material_override = _mat(C_TERRA)
			cup.position = Vector3(0.25, 0.80, 0.05)
			node.add_child(cup)
			_box(node, Vector3(-0.20, 0.78, 0.0), Vector3(0.14, 0.028, 0.10), C_SAGE, 0.9)
			_box(node, Vector3(-0.18, 0.81, 0.01), Vector3(0.12, 0.025, 0.09), Color(0.80, 0.75, 0.65), 0.9)
		"plant_monstera":
			# 화분 옆 작은 화분
			_box(node, Vector3(0.22, 0.05, 0.12), Vector3(0.08, 0.08, 0.08), C_WOOD_D)
			_box(node, Vector3(0.22, 0.11, 0.12), Vector3(0.06, 0.06, 0.06), C_PLANT)


func _add_contact_shadow(node: Node3D, def: Dictionary, rot: int) -> void:
	"""가구 밑에 어두운 반투명 타원 (접촉 그림자 효과)"""
	var fp := GridModel.footprint_size(def["grid_w"], def["grid_h"], rot)
	var w: float = fp.x * CELL * 0.9
	var d: float = fp.y * CELL * 0.9
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 0.008
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.12, 0.08, 0.04, 0.50)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.render_priority = -1
	mi.material_override = m
	mi.scale = Vector3(w, 1, d)
	mi.position = Vector3(0, 0.004, 0)
	node.add_child(mi)


func _procedural_furniture(def_id: String, def: Dictionary) -> Node3D:
	"""glb 없는 가구: 청키 박스 조합(3D 절차적)"""
	var n := Node3D.new()
	match def_id:
		"rug_oval":
			# 보더 (진한 세이지)
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.5; cm.bottom_radius = 0.5; cm.height = 0.04
			mi.mesh = cm
			mi.scale = Vector3(1.5, 1, 1.0)
			mi.material_override = _mat(Color(0.42, 0.62, 0.28), 0.98)
			mi.position.y = 0.020
			n.add_child(mi)
			# 중심 (밝은 크림) — 명확한 색 대비
			var inner := mi.duplicate()
			(inner.mesh as CylinderMesh).top_radius = 0.40
			(inner.mesh as CylinderMesh).bottom_radius = 0.40
			inner.material_override = _mat(Color(0.98, 0.93, 0.80), 0.98)
			inner.position.y = 0.025
			n.add_child(inner)
			# 내부 링 (미세 패턴 대체)
			var ring := mi.duplicate()
			(ring.mesh as CylinderMesh).top_radius = 0.45
			(ring.mesh as CylinderMesh).bottom_radius = 0.45
			ring.material_override = _mat(Color(0.85, 0.78, 0.62), 0.98)
			ring.position.y = 0.024
			ring.scale = Vector3(1.5, 1, 0.3)
			n.add_child(ring)
			# 소품: 슬리퍼 2컬레
			for sx in [-0.09, 0.09]:
				_box(n, Vector3(sx, 0.045, 0.35), Vector3(0.07, 0.03, 0.14), C_TERRA, 0.95)
		"tv_43":
			_box(n, Vector3(0, 0.20, 0), Vector3(1.0, 0.36, 0.5), C_WOOD)
			_box(n, Vector3(0, 0.70, 0), Vector3(0.86, 0.56, 0.06), Color(0.24, 0.23, 0.22), 0.4)
			var scr := MeshInstance3D.new()
			var scm := BoxMesh.new()
			scm.size = Vector3(0.76, 0.48, 0.02)
			scr.mesh = scm
			scr.material_override = _emat(Color(0.5, 0.65, 0.7), Color(0.45, 0.6, 0.65), 0.5)
			scr.position = Vector3(0, 0.70, 0.035)
			n.add_child(scr)
			# 소품: 화분 + 리모컨 + 책
			_box(n, Vector3(-0.36, 0.42, 0.02), Vector3(0.10, 0.09, 0.10), C_TERRA)
			_box(n, Vector3(-0.36, 0.49, 0.02), Vector3(0.08, 0.07, 0.08), C_PLANT)
			_box(n, Vector3(0.15, 0.40, 0.10), Vector3(0.24, 0.05, 0.08), Color(0.25, 0.24, 0.23))
			_box(n, Vector3(0.32, 0.40, -0.08), Vector3(0.10, 0.03, 0.14), C_SAGE)
		"side_table":
			_box(n, Vector3(0, 0.42, 0), Vector3(0.42, 0.04, 0.42), C_WOOD_L)
			for v in [Vector3(-0.13, 0.21, -0.13), Vector3(0.13, 0.21, -0.13), Vector3(0, 0.21, 0.15)]:
				_box(n, v, Vector3(0.04, 0.42, 0.04), C_WOOD_D)
			# 소품: 컵 + 책 + 작은 화분
			var cup := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.035
			cyl.bottom_radius = 0.03
			cyl.height = 0.075
			cup.mesh = cyl
			cup.material_override = _mat(C_TERRA)
			cup.position = Vector3(0.06, 0.48, 0.03)
			n.add_child(cup)
			_box(n, Vector3(-0.07, 0.46, -0.03), Vector3(0.14, 0.028, 0.10), C_SAGE)
			_box(n, Vector3(-0.12, 0.47, 0.10), Vector3(0.07, 0.06, 0.07), C_WOOD_D)
		"picture_frame":
			_box(n, Vector3(0, 1.18, 0), Vector3(0.05, 0.56, 0.46), C_WOOD_D)
			_box(n, Vector3(0.035, 1.18, 0), Vector3(0.02, 0.48, 0.38), Color(0.965, 0.95, 0.91))
			_box(n, Vector3(0.05, 1.24, -0.07), Vector3(0.02, 0.2, 0.14), C_SAGE)
			_box(n, Vector3(0.05, 1.12, 0.08), Vector3(0.02, 0.13, 0.1), C_TERRA)
		"wall_shelf":
			_box(n, Vector3(0, 1.12, 0), Vector3(0.06, 0.05, 1.0), C_WOOD_L)
			_box(n, Vector3(0, 1.24, -0.30), Vector3(0.05, 0.17, 0.13), C_SAGE)
			_box(n, Vector3(0, 1.23, -0.10), Vector3(0.05, 0.15, 0.11), Color(0.9, 0.75, 0.6))
			_box(n, Vector3(0.02, 1.23, 0.14), Vector3(0.04, 0.17, 0.14), C_WOOD_D)
			_box(n, Vector3(0, 1.17, 0.38), Vector3(0.10, 0.10, 0.10), C_TERRA)
		_:
			_box(n, Vector3(0, 0.25, 0), Vector3(0.4, 0.5, 0.4), C_WOOD_L)
	return n


# ================================================================ UI (2D와 동일 구조)
func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var top := HBoxContainer.new()
	top.position = Vector2(16, 12)
	top.add_theme_constant_override("separation", 24)
	ui.add_child(top)
	label_month = _label(top, "1월차")
	label_cash = _label(top, "")
	_button(top, "가구 상점", func() -> void: _toggle_shop(true))
	_button(top, "다음 달 ▶", _on_next_month)
	label_hint = _label(top, "")
	label_hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))

	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(640 - 240, 120)
	var margin := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(k, 16)
	shop_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var title := _label(vbox, "가구 상점")
	title.add_theme_font_size_override("font_size", 24)
	shop_rows = VBoxContainer.new()
	shop_rows.add_theme_constant_override("separation", 10)
	vbox.add_child(shop_rows)
	_button(vbox, "닫기", func() -> void: _toggle_shop(false))
	ui.add_child(shop_panel)
	shop_panel.visible = false

	settle_popup = PanelContainer.new()
	settle_popup.position = Vector2(640 - 220, 220)
	var s_margin := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		s_margin.add_theme_constant_override(k, 16)
	settle_popup.add_child(s_margin)
	var s_vbox := VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 14)
	s_margin.add_child(s_vbox)
	var s_title := _label(s_vbox, "월간 정산")
	s_title.add_theme_font_size_override("font_size", 24)
	settle_text = _label(s_vbox, "")
	settle_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settle_text.custom_minimum_size = Vector2(380, 0)
	_button(s_vbox, "확인", func() -> void: settle_popup.visible = false)
	ui.add_child(settle_popup)
	settle_popup.visible = false
	_rebuild_shop()


func _label(parent: Node, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _toggle_shop(open: bool) -> void:
	shop_panel.visible = open
	if open:
		_rebuild_shop()


func _rebuild_shop() -> void:
	for c in shop_rows.get_children():
		c.queue_free()
	for id in db.all_ids():
		var def: Dictionary = db.get_def(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var name_l := _label(row, "%s  —  %s원" % [def["name"], _fmt(def["price"])])
		name_l.custom_minimum_size = Vector2(280, 0)
		var short := economy.shortfall(def["price"])
		if short > 0:
			var warn := _label(row, "사용 가능 현금 부족 %s원" % _fmt(short))
			warn.add_theme_color_override("font_color", Color(0.78, 0.3, 0.2))
		else:
			_button(row, "구매", func() -> void: _start_placement(id))
		shop_rows.add_child(row)


func _fmt(v: int) -> String:
	var s := str(v)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


func _layer_of(def: Dictionary) -> int:
	match String(def.get("layer", "FLOOR")):
		"WALL":
			return GridModel.Layer.WALL
		"UNDERLAY":
			return GridModel.Layer.UNDERLAY
		_:
			return GridModel.Layer.FLOOR


func _update_hud() -> void:
	label_month.text = "%d월차" % economy.month
	label_cash.text = "보유 %s원  ·  사용 가능 %s원" % [_fmt(economy.cash_balance), _fmt(economy.spendable_cash())]


# ================================================================ 배치 (레이캐스트)
func _mouse_to_cell() -> Vector2i:
	var cam := get_viewport().get_camera_3d()
	var mp := get_viewport().get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(mp)
	var dir: Vector3 = cam.project_ray_direction(mp)
	if absf(dir.y) < 1e-6:
		return Vector2i(-1, -1)
	var t: float = -origin.y / dir.y
	if t < 0:
		return Vector2i(-1, -1)
	var hit: Vector3 = origin + dir * t
	return Vector2i(int(floor(hit.x / CELL)), int(floor(hit.z / CELL)))


func _process(_delta: float) -> void:
	if placement_def_id == "":
		_hide_preview()
		return
	var def: Dictionary = db.get_def(placement_def_id)
	var fp := GridModel.footprint_size(def["grid_w"], def["grid_h"], placement_rot)
	var hover := _mouse_to_cell()
	var origin := hover - Vector2i(fp.x / 2, fp.y / 2)
	var valid := grid.can_place(def["grid_w"], def["grid_h"], origin, placement_rot, _layer_of(def))
	var idx := 0
	for x in range(origin.x, origin.x + fp.x):
		for y in range(origin.y, origin.y + fp.y):
			if idx >= _preview_pool.size():
				break
			var mi := _preview_pool[idx]
			if x >= 0 and y >= 0 and x < ROOM_W and y < ROOM_H:
				mi.visible = true
				mi.position = Vector3((x + 0.5) * CELL, 0.05, (y + 0.5) * CELL)
				var m: StandardMaterial3D = mi.material_override
				m.albedo_color = Color(0.61, 0.69, 0.38, 0.55) if valid else Color(0.85, 0.35, 0.25, 0.55)
			idx += 1
	for i in range(idx, _preview_pool.size()):
		_preview_pool[i].visible = false


func _hide_preview() -> void:
	for mi in _preview_pool:
		mi.visible = false


func _start_placement(def_id: String) -> void:
	placement_def_id = def_id
	placement_rot = 0
	_toggle_shop(false)
	label_hint.text = "클릭: 배치  /  R: 회전  /  ESC: 취소"


func _cancel_placement() -> void:
	placement_def_id = ""
	_hide_preview()
	label_hint.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if placement_def_id == "":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var def: Dictionary = db.get_def(placement_def_id)
		var fp := GridModel.footprint_size(def["grid_w"], def["grid_h"], placement_rot)
		var hover := _mouse_to_cell()
		var origin := hover - Vector2i(fp.x / 2, fp.y / 2)
		var layer := _layer_of(def)
		if not grid.can_place(def["grid_w"], def["grid_h"], origin, placement_rot, layer):
			return
		if not economy.try_spend(def["price"]):
			_rebuild_shop()
			return
		var iid := grid.place(placement_def_id, def["grid_w"], def["grid_h"], origin, placement_rot, layer)
		var node := _make_furniture_node(placement_def_id, grid.get_placement(iid))
		furniture_layer.add_child(node)
		sprites[iid] = node
		_rebuild_astar()
		_update_hud()
		_cancel_placement()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			placement_rot = (placement_rot + 90) % 360
		elif event.keycode == KEY_ESCAPE:
			_cancel_placement()


# ================================================================ 월 정산
func _on_next_month() -> void:
	var r: Dictionary = economy.settle_month()
	settle_text.text = "%d월 정산\n\n월급 +%s원\n주거/생활비 -%s원\n────────\n순 %s%s원\n\n남은 사용 가능 현금 %s원" % [
		r["month"], _fmt(r["income"]), _fmt(r["expenses"]),
		"+" if r["net"] >= 0 else "-", _fmt(abs(r["net"])), _fmt(economy.spendable_cash())]
	settle_popup.visible = true
	_update_hud()
	_rebuild_shop()
