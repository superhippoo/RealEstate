extends Control
## "방 한 칸에서 한남동까지" 진짜 MVP — 기획문서(00/01/04/07/08/10) 기반 완전 루프.
## 표지(새게임/이어하기) → 지도→필터→매물→전체집 → 방: 욕구→구매→배치→만족→부업/기다림→월정산 → 목표달성

const GameStateScript := preload("res://scripts/domain/game_state.gd")
const GridModel := preload("res://scripts/core/grid_model.gd")
const FloorProjector := preload("res://scripts/core/floor_projector.gd")
const GridOverlayScript := preload("res://scenes/concept_flow/grid_overlay.gd")

const SCREENS := {
	"title":  "res://assets/concept/01_cover_house_concept.png",
	"map":    "res://assets/concept/03_seoul_map_district_selection.png",
	"filter": "res://assets/concept/04_housing_condition_selection.png",
	"listing": "res://assets/concept/05_listing_comparison_house_tour.png",
	"house":  "res://assets/concept/06_whole_house_living_screen.png",
	"room":   "res://assets/concept_room/room_empty.png",
}

var state := "title"
var gs: GameState
var grid := GridModel.new(16, 12)
var bg: TextureRect
var hud: VBoxContainer
var hud_panel: PanelContainer
var desire_panel: PanelContainer
var furniture_layer: Control
var placed_nodes := {}
var toast: Label
var shop_panel: PanelContainer
var shop_cash_label: Label
var dim: ColorRect                    # 공용 딤 (팝업 배경)
var popup: PanelContainer             # 공용 팝업 (부족/부업/정산/목표/반응)
var popup_title: Label
var popup_body: VBoxContainer
var char_node: TextureRect

var placing: String = ""
var place_origin := Vector2i(6, 5)
var place_rotation := 0
var ghost: TextureRect
var overlay: Control
var bottom_bar: HBoxContainer
var place_bar: HBoxContainer

var slots: Dictionary = {}
var font: FontFile


func _ready() -> void:
	font = load("res://assets/fonts/NotoSansKR.ttf")
	var f := FileAccess.open("res://data/gpt_slots.json", FileAccess.READ)
	slots = JSON.parse_string(f.get_as_text())
	gs = GameStateScript.new()
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	show_screen("title")


# ================================================================ UI 구성
func _build_ui() -> void:
	bg = TextureRect.new()
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_bg_input)
	add_child(bg)

	furniture_layer = Control.new()
	furniture_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(furniture_layer)

	overlay = GridOverlayScript.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)

	ghost = TextureRect.new()
	ghost.visible = false
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_SCALE
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost)

	char_node = TextureRect.new()
	char_node.texture = load(slots["characters"]["c_idle"]["sprite"])
	char_node.visible = false
	char_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_node.stretch_mode = TextureRect.STRETCH_SCALE
	char_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_node)

	# 상단 HUD (월/현금/스탯)
	hud = VBoxContainer.new()
	var hud_bg := PanelContainer.new()
	hud_bg.add_theme_stylebox_override("panel", _pill(Color(0.99, 0.96, 0.90, 0.92)))
	hud_bg.position = Vector2(640 - 230, 10)
	hud_bg.size = Vector2(460, 132)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("separation", 2)
	hud_bg.add_child(hud)
	add_child(hud_bg)
	hud_panel = hud_bg

	# 욕구 패널 (우측)
	desire_panel = PanelContainer.new()
	desire_panel.add_theme_stylebox_override("panel", _pill(Color(0.99, 0.96, 0.90, 0.94)))
	desire_panel.position = Vector2(1280 - 320, 160)
	desire_panel.size = Vector2(300, 210)
	desire_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desire_panel)

	# 하단 버튼
	bottom_bar = HBoxContainer.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.position = Vector2(24, 720 - 92)
	bottom_bar.size = Vector2(1232, 80)
	bottom_bar.add_theme_constant_override("separation", 14)
	var bl := Control.new(); bl.custom_minimum_size.x = 24
	bottom_bar.add_child(bl)
	bottom_bar.add_child(_mk_button("가구 상점", Callable(self, "_open_shop")))
	bottom_bar.add_child(_mk_button("부업", Callable(self, "_open_sidejob")))
	bottom_bar.add_child(_mk_button("다음 달", Callable(self, "_next_month")))
	bottom_bar.add_child(_mk_button("집 전체", Callable(self, "_goto_house")))
	add_child(bottom_bar)

	# 배치 모드 버튼
	place_bar = HBoxContainer.new()
	place_bar.name = "PlaceBar"
	place_bar.position = Vector2(24, 720 - 92)
	place_bar.size = Vector2(1232, 80)
	place_bar.add_theme_constant_override("separation", 14)
	var pl := Control.new(); pl.custom_minimum_size.x = 24
	place_bar.add_child(pl)
	var rot := _mk_button("회전 ↻", Callable(self, "_rotate_placing"))
	rot.custom_minimum_size = Vector2(150, 64)
	place_bar.add_child(rot)
	var cancel := _mk_button("취소 (환불)", Callable(self, "_cancel_placing"))
	cancel.custom_minimum_size = Vector2(210, 64)
	place_bar.add_child(cancel)
	var hint_l := _label("빈 칸을 눌러 배치", 22)
	place_bar.add_child(hint_l)
	place_bar.visible = false
	add_child(place_bar)

	toast = _label("", 26)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_CENTER)
	toast.offset_left = -340; toast.offset_right = 340
	toast.offset_top = -34; toast.offset_bottom = 34
	add_child(toast)

	_build_shop_panel()

	# 공용 팝업
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	popup = PanelContainer.new()
	popup.add_theme_stylebox_override("panel", _pill(Color(0.99, 0.96, 0.90)))
	popup.position = Vector2(640 - 330, 200)
	popup.size = Vector2(660, 360)
	popup.visible = false
	add_child(popup)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	popup.add_child(col)
	popup_title = _label("제목", 28)
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(popup_title)
	popup_body = col


func _label(text: String, size: int, color := Color(0.35, 0.26, 0.18)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.94, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _mk_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(160, 64)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	b.add_theme_stylebox_override("normal", _pill(Color(0.98, 0.94, 0.86)))
	b.add_theme_stylebox_override("hover", _pill(Color(1.0, 0.97, 0.91)))
	b.add_theme_stylebox_override("pressed", _pill(Color(0.93, 0.87, 0.76)))
	b.add_theme_stylebox_override("focus", _pill(Color(0.98, 0.94, 0.86)))
	b.pressed.connect(cb)
	return b


func _pill(bg_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.corner_radius_top_left = 18; s.corner_radius_top_right = 18
	s.corner_radius_bottom_left = 18; s.corner_radius_bottom_right = 18
	s.border_width_bottom = 5
	s.border_color = Color(0.85, 0.72, 0.55)
	s.content_margin_left = 18; s.content_margin_right = 18
	s.content_margin_top = 8; s.content_margin_bottom = 8
	return s


# ================================================================ 상점
func _build_shop_panel() -> void:
	shop_panel = PanelContainer.new()
	shop_panel.visible = false
	shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	var sb := _pill(Color(0.99, 0.96, 0.90))
	sb.content_margin_left = 20; sb.content_margin_right = 20
	sb.content_margin_top = 14; sb.content_margin_bottom = 16
	shop_panel.add_theme_stylebox_override("panel", sb)
	shop_panel.offset_left = -620; shop_panel.offset_right = 620
	shop_panel.offset_top = -235; shop_panel.offset_bottom = 235

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	shop_panel.add_child(col)

	var title := _label("가구 상점", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var cash_line := _label("", 18, Color(0.55, 0.44, 0.30))
	cash_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cash_line)
	shop_cash_label = cash_line

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)

	for fid in slots["items"]:
		row.add_child(_mk_shop_card(fid, slots["items"][fid]))

	var close := _mk_button("닫기", Callable(self, "_close_popup"))
	col.add_child(close)
	add_child(shop_panel)


func _mk_shop_card(fid: String, item: Dictionary) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 5)
	card.set_meta("item_id", fid)

	var img := TextureRect.new()
	img.texture = load(item["sprite"])
	img.custom_minimum_size = Vector2(92, 104)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(img)

	var name_l := _label(item["name"], 15)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_l)

	var price_l := _label("%s원" % _fmt(item["price"]), 13, Color(0.55, 0.44, 0.30))
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(price_l)

	var buy := Button.new()
	buy.text = "구매"
	buy.custom_minimum_size = Vector2(92, 40)
	buy.add_theme_font_override("font", font)
	buy.add_theme_font_size_override("font_size", 17)
	buy.add_theme_color_override("font_color", Color(1, 1, 0.98))
	buy.add_theme_color_override("font_disabled_color", Color(0.98, 0.98, 0.96))
	buy.add_theme_stylebox_override("normal", _pill(Color(0.72, 0.80, 0.58)))
	buy.add_theme_stylebox_override("hover", _pill(Color(0.78, 0.86, 0.64)))
	buy.add_theme_stylebox_override("pressed", _pill(Color(0.64, 0.72, 0.50)))
	buy.add_theme_stylebox_override("focus", _pill(Color(0.72, 0.80, 0.58)))
	buy.pressed.connect(func(): _try_buy(fid, buy))
	card.add_child(buy)
	card.set_meta("buy_btn", buy)
	return card


# ================================================================ 화면 전환
func show_screen(next: String) -> void:
	state = next
	var tex: Texture2D = load(SCREENS[next])
	_fit_bg(tex)

	var is_room := next == "room"
	bottom_bar.visible = is_room and placing.is_empty()
	place_bar.visible = is_room and not placing.is_empty()
	hud_panel.visible = is_room
	desire_panel.visible = is_room
	furniture_layer.visible = is_room
	char_node.visible = is_room
	overlay.visible = is_room and not placing.is_empty()
	ghost.visible = is_room and not placing.is_empty()
	if next == "title":
		_show_title_menu()
	if is_room:
		_layout_room()
		_update_hud()
		_update_desire_panel()
		if not placing.is_empty():
			_update_overlay_transform()
			_update_ghost()

	var hint: String = {
		"map": "관악구 선택 (화면을 누르세요)",
		"filter": "조건 확정 (화면을 누르세요)",
		"listing": "이 집 구경하기 (화면을 누르세요)",
		"house": "침실로 이동 (화면을 누르세요)",
	}.get(next, "")
	_show_toast(hint, 2.2)


func _show_title_menu() -> void:
	_open_popup("방 한 칸에서 한남동까지",
		["서울에서 첫 직장을 얻었어요.", "가진 돈 4,500,000원. 좋은 집을 만들어봐요."])
	var new_b := _mk_button("새 게임", Callable(self, "_start_new_game"))
	new_b.custom_minimum_size = Vector2(280, 60)
	popup_body.add_child(new_b)
	if gs.has_save():
		var cont := _mk_button("이어하기", Callable(self, "_continue_game"))
		cont.custom_minimum_size = Vector2(280, 60)
		popup_body.add_child(cont)


func _start_new_game() -> void:
	_close_popup()
	gs = GameStateScript.new()
	purchased_from_load_clear()
	_show_toast("관악구 원룸에 입주했어요. 월세 80만원.", 2.5)
	show_screen("map")


func _continue_game() -> void:
	_close_popup()
	gs = GameStateScript.load_game()
	_apply_loaded_game()
	show_screen("room")
	_show_toast("%d월차로 돌아왔어요" % gs.month, 2.0)


func _apply_loaded_game() -> void:
	# 저장된 placements 복원
	var f := FileAccess.open(GameStateScript.SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data == null or not data.has("placements"):
		return
	for p in data["placements"]:
		var origin := Vector2i(int(p["ox"]), int(p["oy"]))
		var layer := int(p["layer"])
		var fp := GridModel.footprint_size(int(p["w"]), int(p["h"]), int(p["rot"]))
		if grid.can_place(fp.x, fp.y, origin, int(p["rot"]), layer, -1):
			var iid := grid.place(p["fid"], fp.x, fp.y, origin, int(p["rot"]), layer)
			if iid > 0:
				_add_furniture_node(iid, p["fid"])


func purchased_from_load_clear() -> void:
	for iid in placed_nodes.keys():
		placed_nodes[iid].queue_free()
	placed_nodes.clear()
	grid = GridModel.new(16, 12)


func _fit_bg(tex: Texture2D) -> void:
	bg.texture = tex
	var win := Vector2(1280, 720)
	var scale: float = maxf(win.x / tex.get_width(), win.y / tex.get_height())
	var dw: float = tex.get_width() * scale
	var dh: float = tex.get_height() * scale
	bg.position = Vector2((win.x - dw) * 0.5, (win.y - dh) * 0.5)
	bg.size = Vector2(dw, dh)


func _img_to_screen(p: Vector2) -> Vector2:
	return bg.position + p * (bg.size.x / bg.texture.get_width())


func _screen_to_img(p: Vector2) -> Vector2:
	return (p - bg.position) * (bg.texture.get_width() / bg.size.x)


func _layout_room() -> void:
	var c: Dictionary = slots["characters"]["c_idle"]
	var r: Dictionary = slots["room"]
	var cw: float = c["width_px"] * (bg.size.x / bg.texture.get_width())
	var chh: float = cw * char_node.texture.get_height() / char_node.texture.get_width()
	var cx: float = bg.position.x + (float(r["x"]) + c["slot"][0] * float(r["w"])) * (bg.size.x / bg.texture.get_width())
	var cy: float = bg.position.y + (float(r["y"]) + c["slot"][1] * float(r["h"])) * (bg.size.y / bg.texture.get_height())
	char_node.size = Vector2(cw, chh)
	char_node.position = Vector2(cx - cw * 0.5, cy - chh + 10.0)
	for iid in placed_nodes:
		_apply_placement_transform(placed_nodes[iid], grid.placements[iid])
	_sort_furniture()


# ================================================================ HUD / 욕구
func _update_hud() -> void:
	for c in hud.get_children():
		hud.remove_child(c)
		c.queue_free()
	var l1 := _label("%d월차  ·  지금 집 만족도: %s" % [gs.month, gs.satisfaction_label()], 24)
	var l2 := _label("보유 %s원  ·  사용 가능 %s원" % [_fmt(gs.cash_balance), _fmt(gs.spendable_cash())], 19, Color(0.45, 0.35, 0.22))
	var l3 := _label("체력 %d  스트레스 %d  행복 %d" % [gs.energy, gs.stress, gs.happiness], 17, Color(0.32, 0.24, 0.16))
	hud.add_child(l1)
	hud.add_child(l2)
	hud.add_child(l3)


func _update_desire_panel() -> void:
	for c in desire_panel.get_children():
		desire_panel.remove_child(c)
		c.queue_free()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	desire_panel.add_child(col)

	if gs.goal_done:
		col.add_child(_label("♥ 모든 소원 완성!", 22, Color(0.72, 0.35, 0.30)))
		col.add_child(_label("방이 완성됐어요. 이제 다음 목표는\n더 좋은 집!", 16))
		return

	var d: Dictionary = GameStateScript.DESIRES[gs.desire_index]
	col.add_child(_label("지금 갖고 싶어요 (%d/%d)" % [gs.desire_index + 1, GameStateScript.DESIRES.size()], 19))
	var line := _label(d["line"], 15)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 260
	col.add_child(line)
	for fid in d["items"]:
		var item: Dictionary = slots["items"][fid]
		var mark := "○" if not gs.purchased.has(fid) else "✔"
		var need := _label("%s %s — %s원" % [mark, item["name"], _fmt(item["price"])], 15,
				Color(0.3, 0.5, 0.3) if gs.purchased.has(fid) else Color(0.55, 0.44, 0.30))
		col.add_child(need)


# ================================================================ 배치 모드
func _item_layer(fid: String) -> int:
	var item: Dictionary = slots["items"][fid]
	match item["layer"]:
		"floor": return GridModel.Layer.UNDERLAY
		"wall": return GridModel.Layer.WALL
	return GridModel.Layer.FLOOR


func _start_placing(fid: String) -> void:
	placing = fid
	place_rotation = 0
	var item: Dictionary = slots["items"][fid]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], 0)
	place_origin = _find_free_origin(fp, _item_layer(fid))
	ghost.texture = load(item["sprite"])
	ghost.flip_h = false
	_close_popup()
	show_screen("room")
	_update_overlay_transform()
	_update_ghost()


func _find_free_origin(fp: Vector2i, layer: int) -> Vector2i:
	for gy in range(grid.height - fp.y):
		for gx in range(grid.width - fp.x):
			var oy := 2 + gy
			var ox := 3 + gx
			if ox + fp.x > grid.width - 1:
				break
			if oy + fp.y > grid.height - 1:
				break
			if grid.can_place(fp.x, fp.y, Vector2i(ox, oy), 0, layer):
				return Vector2i(ox, oy)
	return Vector2i(0, 0)


func _rotate_placing() -> void:
	place_rotation = (place_rotation + 90) % 360
	ghost.flip_h = place_rotation == 90 or place_rotation == 270
	_update_ghost()


func _cancel_placing() -> void:
	var item: Dictionary = slots["items"][placing]
	gs.cash_balance += item["price"]   # 구매 취소 = 전액 환불 (on_furniture_owned는 배치 확정 시에만 호출됨)
	_update_hud()
	placing = ""
	_show_toast("구매를 취소했어요 (환불 완료)", 1.8)
	show_screen("room")


func _update_overlay_transform() -> void:
	var scale_x: float = bg.size.x / bg.texture.get_width()
	var scale_y: float = bg.size.y / bg.texture.get_height()
	var xform := Transform2D.IDENTITY
	xform.x = Vector2(scale_x, 0.0)
	xform.y = Vector2(0.0, scale_y)
	xform.origin = bg.position
	overlay.bg_transform = xform
	var cells: Array[Vector2i] = []
	for gy in grid.height:
		for gx in grid.width:
			cells.append(Vector2i(gx, gy))
	overlay.valid_cells = cells


func _update_ghost() -> void:
	if placing.is_empty():
		ghost.visible = false
		overlay.highlight_origin = Vector2i(-1, -1)
		overlay.queue_redraw()
		return
	var item: Dictionary = slots["items"][placing]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], place_rotation)
	var ok: bool = grid.can_place(fp.x, fp.y, place_origin, place_rotation, _item_layer(placing))
	var anchor := FloorProjector.footprint_front_center(place_origin, fp.x, fp.y)
	if item["layer"] == "wall":
		anchor = FloorProjector.grid_to_img(place_origin.x + fp.x * 0.5, place_origin.y + fp.y)
	var wpx: float = FloorProjector.footprint_width_px(place_origin, fp.x, fp.y)
	var scr := _img_to_screen(anchor)
	var sc: float = bg.size.x / bg.texture.get_width()
	var w := wpx * sc
	var h := w * ghost.texture.get_height() / ghost.texture.get_width()
	ghost.size = Vector2(w, h)
	ghost.position = scr - Vector2(w * 0.5, h - 12.0 * sc)
	ghost.modulate = Color(0.5, 1.0, 0.5, 0.85) if ok else Color(1.0, 0.35, 0.3, 0.85)
	if item["layer"] == "wall":
		ghost.position.y -= h * 0.55
	overlay.highlight_origin = place_origin
	overlay.highlight_size = fp
	overlay.highlight_ok = ok
	overlay.queue_redraw()


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not placing.is_empty():
		_ghost_follow(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if not placing.is_empty():
			_try_place_here(event.position)
			return
		match state:
			"title": pass  # 타이틀은 팝업 버튼으로
			"map": show_screen("filter")
			"filter": show_screen("listing")
			"listing": show_screen("house")
			"house": show_screen("room")


func _ghost_follow(screen_pos: Vector2) -> void:
	if placing.is_empty():
		return
	var cell := FloorProjector.img_to_cell(_screen_to_img(screen_pos))
	if cell.x < 0:
		return
	var item: Dictionary = slots["items"][placing]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], place_rotation)
	var ox: int = clampi(cell.x - fp.x / 2, 0, grid.width - fp.x)
	var oy: int = clampi(cell.y - fp.y / 2, 0, grid.height - fp.y)
	if item["layer"] == "wall":
		if ox > 1:
			oy = 0
		else:
			ox = 0
	place_origin = Vector2i(ox, oy)
	_update_ghost()


func _try_place_here(screen_pos: Vector2) -> void:
	_ghost_follow(screen_pos)
	var item: Dictionary = slots["items"][placing]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], place_rotation)
	var layer := _item_layer(placing)
	if not grid.can_place(fp.x, fp.y, place_origin, place_rotation, layer):
		_show_toast("여기엔 놓을 수 없어요", 1.2)
		return
	var iid := grid.place(placing, fp.x, fp.y, place_origin, place_rotation, layer)
	if iid < 0:
		return
	var node := _add_furniture_node(iid, placing)
	_apply_placement_transform(node, grid.placements[iid])
	_sort_furniture()
	var done_desire: Dictionary = gs.on_furniture_owned(placing)
	placing = ""
	overlay.visible = false
	ghost.visible = false
	place_bar.visible = false
	bottom_bar.visible = true
	gs.save_game_with(_placements_list())
	_update_hud()
	_update_desire_panel()
	if not done_desire.is_empty():
		_desire_celebration(done_desire)
	else:
		_show_toast("%s 배치 완료!" % item["name"], 1.6)


func _add_furniture_node(iid: int, fid: String) -> TextureRect:
	var item: Dictionary = slots["items"][fid]
	var node := TextureRect.new()
	node.texture = load(item["sprite"])
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	furniture_layer.add_child(node)
	placed_nodes[iid] = node
	return node


func _placements_list() -> Array:
	var out: Array = []
	for iid in grid.placements:
		var p: GridModel.Placement = grid.placements[iid]
		out.append({"fid": p.def_id, "ox": p.origin.x, "oy": p.origin.y,
				"rot": p.rotation, "layer": p.layer, "w": p.def_w, "h": p.def_h})
	return out


func _apply_placement_transform(node: TextureRect, p: GridModel.Placement) -> void:
	var fp := GridModel.footprint_size(p.def_w, p.def_h, p.rotation)
	var anchor := FloorProjector.footprint_front_center(p.origin, fp.x, fp.y)
	if p.layer == GridModel.Layer.WALL:
		anchor = FloorProjector.grid_to_img(p.origin.x + fp.x * 0.5, p.origin.y + fp.y)
	var wpx: float = FloorProjector.footprint_width_px(p.origin, fp.x, fp.y)
	var sc: float = bg.size.x / bg.texture.get_width()
	var w := wpx * sc
	var h := w * node.texture.get_height() / node.texture.get_width()
	node.size = Vector2(w, h)
	node.position = _img_to_screen(anchor) - Vector2(w * 0.5, h - 12.0 * sc)
	if p.layer == GridModel.Layer.WALL:
		node.position.y -= h * 0.55
		node.position.y = maxf(node.position.y, 6.0)
	node.set_meta("sort_y", anchor.y)
	node.flip_h = p.rotation == 90 or p.rotation == 270


func _sort_furniture() -> void:
	var nodes: Array = []
	for iid in placed_nodes:
		nodes.append([placed_nodes[iid].get_meta("sort_y", 0.0), placed_nodes[iid]])
	nodes.sort_custom(func(a, b): return a[0] < b[0])
	for i in nodes.size():
		furniture_layer.move_child(nodes[i][1], i)


func _goto_house() -> void:
	show_screen("house")


# ================================================================ 구매/부족/부업
func _open_shop() -> void:
	shop_cash_label.text = "사용 가능 %s원" % _fmt(gs.spendable_cash())
	for card in shop_panel.get_child(0).get_child(2).get_children():
		var fid: String = card.get_meta("item_id")
		var buy: Button = card.get_meta("buy_btn")
		buy.text = "구매됨" if gs.purchased.has(fid) else "구매"
		buy.disabled = gs.purchased.has(fid)
	_close_popup()
	dim.visible = true
	shop_panel.visible = true


func _close_shop() -> void:
	shop_panel.visible = false
	dim.visible = false


func _try_buy(fid: String, buy_btn: Button = null) -> void:
	if gs.purchased.has(fid):
		_show_toast("이미 구입한 가구예요", 1.6)
		return
	var item: Dictionary = slots["items"][fid]
	if gs.try_spend(item["price"]):
		if buy_btn != null:
			buy_btn.text = "구매됨"
			buy_btn.disabled = true
		_close_shop()
		_show_toast("%s 구매! 위치를 선택하세요" % item["name"], 1.8)
		_update_hud()
		_start_placing(fid)
	else:
		# 08 §2: 부족액 안내 → 기다리기 / 부업하기
		var lack := gs.shortfall(item["price"])
		_open_popup("%s — 갖고 싶은데…" % item["name"],
			["%s원이 필요해요." % _fmt(item["price"]),
			 "사용 가능 현금 %s원" % _fmt(gs.spendable_cash()),
			 "%s원이 부족해요." % _fmt(lack)])
		var sj := _mk_button("부업하기 (+%s원)" % _fmt(GameStateScript.SIDEJOB_REWARD),
				Callable(self, "_open_sidejob"))
		sj.custom_minimum_size = Vector2(400, 58)
		popup_body.add_child(sj)
		var wait := _mk_button("다음 월급까지 기다리기", Callable(self, "_close_popup"))
		wait.custom_minimum_size = Vector2(400, 58)
		popup_body.add_child(wait)


func _open_sidejob() -> void:
	var remain: int = GameStateScript.SIDEJOB_MAX_PER_MONTH - gs.sidejobs_used
	_open_popup("부업하기", [
		"오늘 할 수 있는 부업",
		"%s — 보상 %s원" % [GameStateScript.SIDEJOBS[gs.sidejobs_used % GameStateScript.SIDEJOBS.size()],
				_fmt(GameStateScript.SIDEJOB_REWARD)],
		"이번 달 부업 %d/%d회 · 오늘 번 돈 %s원" % [gs.sidejobs_used,
				GameStateScript.SIDEJOB_MAX_PER_MONTH, _fmt(gs.month_sidejob_income)],
	])
	var do_b := _mk_button("부업 시작", Callable(self, "_do_sidejob"))
	do_b.custom_minimum_size = Vector2(400, 58)
	popup_body.add_child(do_b)
	if remain <= 0:
		do_b.disabled = true
		do_b.text = "오늘은 끝! (월 %d회)" % GameStateScript.SIDEJOB_MAX_PER_MONTH
	var close := _mk_button("그만두기", Callable(self, "_close_popup"))
	close.custom_minimum_size = Vector2(400, 58)
	popup_body.add_child(close)


func _do_sidejob() -> void:
	if gs.do_sidejob():
		_open_sidejob()
		_update_hud()
		gs.save_game_with(_placements_list())
	else:
		_show_toast("오늘은 부업을 다 했어요", 1.5)


# ================================================================ 월 정산 / 목표
func _next_month() -> void:
	var r: Dictionary = gs.settle_month()
	var ev: Dictionary = r.get("event", {})
	var lines: Array = [
		"— %d월 정산 —" % r["month"],
		"월급 +%s원  ·  생활비 -%s원" % [_fmt(r["income"]), _fmt(r["expenses"])],
	]
	if r["sidejob"] > 0:
		lines.append("부업 수입 +%s원" % _fmt(r["sidejob"]))
	if not ev.is_empty():
		lines.append("이번 달: %s" % ev["text"])
	lines.append("체력 %d · 스트레스 %d · 행복 %d" % [r["energy"], r["stress"], r["happiness"]])
	lines.append("보유 %s원 · 사용 가능 %s원" % [_fmt(gs.cash_balance), _fmt(gs.spendable_cash())])
	_open_popup("%d월이 되었어요" % r["month"], lines)
	var ok := _mk_button("확인", Callable(self, "_close_popup"))
	ok.custom_minimum_size = Vector2(300, 58)
	popup_body.add_child(ok)
	_update_hud()
	_update_desire_panel()
	gs.save_game_with(_placements_list())


func _desire_celebration(d: Dictionary) -> void:
	_open_popup("소원이 이뤄졌어요! ♥", [
		"%s 완성!" % d["name"],
		"행복이 크게 올랐어요. 방이 점점 좋아지고 있어요.",
		"다음 소원도 기대돼요.",
	])
	var ok := _mk_button("좋아!", Callable(self, "_close_popup"))
	ok.custom_minimum_size = Vector2(300, 58)
	popup_body.add_child(ok)
	if gs.goal_done:
		_show_goal()


func _show_goal() -> void:
	_open_popup("🏆 첫 방 완성!", [
		"5개의 소원을 모두 이뤘어요!",
		"체력 %d · 스트레스 %d · 행복 %d" % [gs.energy, gs.stress, gs.happiness],
		"이사 자금을 모으면 더 좋은 집으로 갈 수 있어요. (다음 목표 예고)",
	])
	var keep := _mk_button("계속 꾸미기", Callable(self, "_close_popup"))
	keep.custom_minimum_size = Vector2(400, 58)
	popup_body.add_child(keep)


# ================================================================ 공용 팝업
func _open_popup(title_text: String, lines: Array) -> void:
	popup_title.text = title_text
	for c in popup_body.get_children():
		if c == popup_title:
			continue
		popup_body.remove_child(c)
		c.queue_free()
	for line in lines:
		var l := _label(str(line), 19)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		popup_body.add_child(l)
	_close_shop()
	dim.visible = true
	popup.visible = true


func _close_popup() -> void:
	popup.visible = false
	shop_panel.visible = false
	dim.visible = false


# ================================================================ 유틸
func _show_toast(text: String, dur: float) -> void:
	if text.is_empty():
		toast.visible = false
		return
	toast.text = text
	toast.visible = true
	var tw := create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func(): toast.visible = false)


func _fmt(v: int) -> String:
	var s := str(v)
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "," + out
	return out


func debug_set(next: String) -> void:
	show_screen(next)
