extends Node2D
## Micro MVP 메인 — 방 1개 + 가구 배치 + 자율 캐릭터 + 미니 경제.
## UI는 코드 생성(MVP 한정), 본 게임은 씬/테마 분리 예정.

const ROOM_W := 16
const ROOM_H := 12

var grid: GridModel
var db: FurnitureDB
var economy := MiniEconomy.new()
var astar := AStarGrid2D.new()

var room_root: Node2D
var room_renderer: Node2D
var furniture_layer: Node2D
var agent: Sprite2D
var ghost: Sprite2D

var sprites := {}          # instance_id -> FurnitureSprite
var placement_def_id := "" # 배치 모드 중인 가구
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


func _ready() -> void:
	randomize()
	# 한글 폰트 전역 적용 (OFL)
	var font := load("res://assets/fonts/NotoSansKR.ttf")
	if font:
		ThemeDB.fallback_font = font
		ThemeDB.fallback_font_size = 18

	db = FurnitureDB.load_default()
	grid = GridModel.new(ROOM_W, ROOM_H)
	_setup_astar()
	_build_world()
	_build_ui()
	_update_hud()


func _setup_astar() -> void:
	astar.region = Rect2i(0, 0, ROOM_W, ROOM_H)
	astar.cell_size = Vector2(1, 1)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()


func _rebuild_astar() -> void:
	astar.update()
	for cell in grid.occupied_cells():
		astar.set_point_solid(cell, true)
	if agent:
		agent.notify_grid_changed()


func _build_world() -> void:
	room_root = Node2D.new()
	add_child(room_root)

	room_renderer = load("res://scripts/ui/room_renderer.gd").new()
	room_renderer.grid = grid
	room_renderer.z_index = -100  # 방 이미지가 모든 배치물 아래에 그려지도록
	room_root.add_child(room_renderer)

	furniture_layer = Node2D.new()
	furniture_layer.y_sort_enabled = true
	room_root.add_child(furniture_layer)

	var agent_script := load("res://scripts/character/character_agent.gd")
	agent = Sprite2D.new()
	agent.set_script(agent_script)
	room_root.add_child(agent)
	agent.setup(self)

	# 카메라: 방 전체가 화면에 맞도록 자동 줌
	var cam := Camera2D.new()
	add_child(cam)
	var c000 := IsoProjector.gridf_to_screen(0, 0)
	var c_w0 := IsoProjector.gridf_to_screen(ROOM_W, 0)
	var c0h := IsoProjector.gridf_to_screen(0, ROOM_H)
	var cwh := IsoProjector.gridf_to_screen(ROOM_W, ROOM_H)
	var min_p := Vector2(minf(c000.x, c0h.x), c000.y - 400.0) - Vector2(40, 40)
	var max_p := Vector2(maxf(c_w0.x, cwh.x), maxf(c_w0.y, cwh.y)) + Vector2(40, 40)
	var size := max_p - min_p
	var zoom: float = minf(1280.0 / size.x, 720.0 / size.y)
	cam.zoom = Vector2(zoom, zoom)
	cam.position = (min_p + max_p) / 2.0
	cam.make_current()


# ================================================================ UI
func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	var top := HBoxContainer.new()
	top.position = Vector2(16, 12)
	top.add_theme_constant_override("separation", 24)
	ui.add_child(top)

	label_month = _label(top, "1월차")
	label_cash = _label(top, "")

	var shop_btn := _button(top, "가구 상점", func() -> void: _toggle_shop(true))
	var month_btn := _button(top, "다음 달 ▶", _on_next_month)

	label_hint = _label(top, "")
	label_hint.add_theme_color_override("font_color", Color(0.4, 0.35, 0.25))

	# 상점 패널
	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(640 - 240, 120)
	shop_panel.size = Vector2(480, 420)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	shop_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var title := _label(vbox, "가구 상점")
	title.add_theme_font_size_override("font_size", 24)
	shop_rows = VBoxContainer.new()
	shop_rows.add_theme_constant_override("separation", 10)
	vbox.add_child(shop_rows)
	var close_btn := _button(vbox, "닫기", func() -> void: _toggle_shop(false))
	ui.add_child(shop_panel)
	shop_panel.visible = false

	# 정산 팝업
	settle_popup = PanelContainer.new()
	settle_popup.position = Vector2(640 - 220, 220)
	var s_margin := MarginContainer.new()
	s_margin.add_theme_constant_override("margin_left", 20)
	s_margin.add_theme_constant_override("margin_right", 20)
	s_margin.add_theme_constant_override("margin_top", 16)
	s_margin.add_theme_constant_override("margin_bottom", 16)
	settle_popup.add_child(s_margin)
	var s_vbox := VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 14)
	s_margin.add_child(s_vbox)
	var s_title := _label(s_vbox, "월간 정산")
	s_title.add_theme_font_size_override("font_size", 24)
	settle_text = _label(s_vbox, "")
	settle_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settle_text.custom_minimum_size = Vector2(380, 0)
	var ok_btn := _button(s_vbox, "확인", func() -> void: settle_popup.visible = false)
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


func _layer_of(def: Dictionary) -> int:
	match String(def.get("layer", "FLOOR")):
		"WALL":
			return GridModel.Layer.WALL
		"UNDERLAY":
			return GridModel.Layer.UNDERLAY
		_:
			return GridModel.Layer.FLOOR


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


func _update_hud() -> void:
	label_month.text = "%d월차" % economy.month
	label_cash.text = "보유 %s원  ·  사용 가능 %s원" % [_fmt(economy.cash_balance), _fmt(economy.spendable_cash())]


# ================================================================ 배치 모드
func _start_placement(def_id: String) -> void:
	placement_def_id = def_id
	placement_rot = 0
	_toggle_shop(false)
	label_hint.text = "클릭: 배치  /  R: 회전  /  ESC: 취소"
	if ghost == null:
		ghost = Sprite2D.new()
		ghost.centered = true
		room_root.add_child(ghost)
	FurnitureSprite.load_manifest()
	var def0: Dictionary = db.get_def(def_id)
	var ti := FurnitureSprite.load_texture(def_id, 0, def0["grid_w"], def0["grid_h"])
	if not ti.is_empty():
		ghost.texture = ti["texture"]
		ghost.scale = Vector2(ti["scale"], ti["scale"])
	ghost.modulate = Color(1, 1, 1, 0.6)


func _cancel_placement() -> void:
	placement_def_id = ""
	ghost.visible = false
	room_renderer.clear_preview()
	label_hint.text = ""


func _process(_delta: float) -> void:
	if placement_def_id == "":
		return
	var def: Dictionary = db.get_def(placement_def_id)
	var mouse_local := room_root.get_global_mouse_position()
	var fp := GridModel.footprint_size(def["grid_w"], def["grid_h"], placement_rot)
	var hover := IsoProjector.screen_to_grid(mouse_local)
	var origin := hover - Vector2i(fp.x / 2, fp.y / 2)
	var valid := grid.can_place(def["grid_w"], def["grid_h"], origin, placement_rot, _layer_of(def))
	room_renderer.set_preview(origin, fp, valid)

	var center := IsoProjector.gridf_to_screen(origin.x + fp.x / 2.0, origin.y + fp.y / 2.0)
	ghost.position = center
	ghost.z_index = 2000
	ghost.visible = true
	var ti := FurnitureSprite.load_texture(placement_def_id, placement_rot, def["grid_w"], def["grid_h"])
	if not ti.is_empty():
		ghost.texture = ti["texture"]
		ghost.scale = Vector2(ti["scale"], ti["scale"])
		ghost.flip_h = ti["flip_h"]
	ghost.modulate = Color(1, 1, 1, 0.6) if valid else Color(1, 0.4, 0.35, 0.55)


func _unhandled_input(event: InputEvent) -> void:
	if placement_def_id == "":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_at_mouse()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			placement_rot = (placement_rot + 90) % 360
		elif event.keycode == KEY_ESCAPE:
			_cancel_placement()


func _try_place_at_mouse() -> void:
	var def: Dictionary = db.get_def(placement_def_id)
	var fp := GridModel.footprint_size(def["grid_w"], def["grid_h"], placement_rot)
	var hover := IsoProjector.screen_to_grid(room_root.get_global_mouse_position())
	var origin := hover - Vector2i(fp.x / 2, fp.y / 2)
	var layer := _layer_of(def)
	if not grid.can_place(def["grid_w"], def["grid_h"], origin, placement_rot, layer):
		return
	if not economy.try_spend(def["price"]):
		# 이 지점에 도달했다면 상점 열린 뒤 경제가 변한 경우 — 이중 방어
		_rebuild_shop()
		return
	var iid := grid.place(placement_def_id, def["grid_w"], def["grid_h"], origin, placement_rot, layer)
	var fs := FurnitureSprite.new()
	fs.setup(iid, placement_def_id)
	furniture_layer.add_child(fs)
	fs.refresh(grid.get_placement(iid))
	sprites[iid] = fs
	_rebuild_astar()
	_update_hud()
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
