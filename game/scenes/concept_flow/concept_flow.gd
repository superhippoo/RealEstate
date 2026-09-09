extends Control
## 원본 기획 이미지 + GPT 스프라이트 수직 슬라이스.
## 표지→지도→필터→매물→전체집→방 흐름 + MiniEconomy + 상점 + 그리드 배치(이동/회전/충돌).

const Econ := preload("res://scripts/domain/mini_economy.gd")
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
	"reaction": "res://assets/concept/10_character_reaction_after_completion.png",
}

var state := "title"
var econ := Econ.new()
var grid := GridModel.new(16, 12)
var purchased := {}          # furniture id -> true
var bg: TextureRect
var hud: VBoxContainer
var hud_panel: PanelContainer
var furniture_layer: Control
var placed_nodes := {}       # instance_id -> TextureRect
var toast: Label
var shop_panel: PanelContainer
var shop_cash_label: Label
var reaction_dim: ColorRect
var reaction_img: TextureRect
var char_node: TextureRect

# 배치 모드
var placing: String = ""     # 배치 중인 furniture id (빈 문자열 = 배치 아님)
var place_origin := Vector2i(6, 5)
var place_rotation := 0
var ghost: TextureRect
var overlay: Control
var place_btns: HBoxContainer

var slots: Dictionary = {}
var font: FontFile


func _ready() -> void:
	font = load("res://assets/fonts/NotoSansKR.ttf")
	var f := FileAccess.open("res://data/gpt_slots.json", FileAccess.READ)
	slots = JSON.parse_string(f.get_as_text())
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	show_screen("title")


# ---------------------------------------------------------------- UI 구성
func _build_ui() -> void:
	bg = TextureRect.new()
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_bg_input)
	add_child(bg)

	furniture_layer = Control.new()
	furniture_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(furniture_layer)

	# 배치 그리드 오버레이
	overlay = GridOverlayScript.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)

	# 배치 고스트
	ghost = TextureRect.new()
	ghost.visible = false
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_SCALE
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost)

	# 캐릭터 (방 화면 상시)
	char_node = TextureRect.new()
	char_node.texture = load(slots["characters"]["c_idle"]["sprite"])
	char_node.visible = false
	char_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_node.stretch_mode = TextureRect.STRETCH_SCALE
	char_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_node)

	# 상단 HUD
	hud = VBoxContainer.new()
	var hud_bg := PanelContainer.new()
	var hud_style := _pill_style(Color(0.99, 0.96, 0.90, 0.92))
	hud_style.content_margin_left = 22; hud_style.content_margin_right = 22
	hud_style.content_margin_top = 10; hud_style.content_margin_bottom = 12
	hud_bg.add_theme_stylebox_override("panel", hud_style)
	hud_bg.position = Vector2(640 - 200, 12)
	hud_bg.size = Vector2(400, 100)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("separation", 2)
	hud_bg.add_child(hud)
	add_child(hud_bg)
	hud_panel = hud_bg

	# 하단 버튼 row
	var bottom := HBoxContainer.new()
	bottom.name = "BottomBar"
	bottom.position = Vector2(24, 720 - 92)
	bottom.size = Vector2(1232, 80)
	bottom.add_theme_constant_override("separation", 16)
	var bl := Control.new(); bl.custom_minimum_size.x = 24
	bottom.add_child(bl)
	bottom.add_child(_mk_button("가구 상점", Callable(self, "_open_shop")))
	bottom.add_child(_mk_button("다음 달", Callable(self, "_next_month")))
	bottom.add_child(_mk_button("집 전체", Callable(self, "_goto_house")))
	add_child(bottom)

	# 배치 모드 버튼 (회전/취소)
	place_btns = HBoxContainer.new()
	place_btns.name = "PlaceBar"
	place_btns.position = Vector2(24, 720 - 92)
	place_btns.size = Vector2(1232, 80)
	place_btns.add_theme_constant_override("separation", 16)
	var pl := Control.new(); pl.custom_minimum_size.x = 24
	place_btns.add_child(pl)
	var rot := _mk_button("회전 ↻", Callable(self, "_rotate_placing"))
	rot.custom_minimum_size = Vector2(150, 64)
	place_btns.add_child(rot)
	var cancel := _mk_button("취소 (환불)", Callable(self, "_cancel_placing"))
	cancel.custom_minimum_size = Vector2(210, 64)
	place_btns.add_child(cancel)
	var hint_l := Label.new()
	hint_l.name = "PlaceHint"
	hint_l.text = "빈 칸을 눌러 배치"
	hint_l.add_theme_font_override("font", font)
	hint_l.add_theme_font_size_override("font_size", 22)
	hint_l.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	hint_l.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.94))
	hint_l.add_theme_constant_override("outline_size", 8)
	place_btns.add_child(hint_l)
	place_btns.visible = false
	add_child(place_btns)

	# 토스트
	toast = Label.new()
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_CENTER)
	toast.offset_left = -320; toast.offset_right = 320
	toast.offset_top = -34; toast.offset_bottom = 34
	toast.add_theme_font_override("font", font)
	toast.add_theme_font_size_override("font_size", 26)
	toast.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	toast.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.94))
	toast.add_theme_constant_override("outline_size", 10)
	add_child(toast)

	_build_shop_panel()
	_build_reaction()


func _mk_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 64)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	b.add_theme_color_override("font_hover_color", Color(0.2, 0.14, 0.09))
	b.add_theme_stylebox_override("normal", _pill_style(Color(0.98, 0.94, 0.86)))
	b.add_theme_stylebox_override("hover", _pill_style(Color(1.0, 0.97, 0.91)))
	b.add_theme_stylebox_override("pressed", _pill_style(Color(0.93, 0.87, 0.76)))
	b.add_theme_stylebox_override("focus", _pill_style(Color(0.98, 0.94, 0.86)))
	b.pressed.connect(cb)
	return b


func _pill_style(bg_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.corner_radius_top_left = 18; s.corner_radius_top_right = 18
	s.corner_radius_bottom_left = 18; s.corner_radius_bottom_right = 18
	s.border_width_bottom = 5
	s.border_color = Color(0.85, 0.72, 0.55)
	s.content_margin_left = 20; s.content_margin_right = 20
	s.content_margin_top = 8; s.content_margin_bottom = 8
	return s


# ---------------------------------------------------------------- 상점 팝업
func _build_shop_panel() -> void:
	shop_panel = PanelContainer.new()
	shop_panel.visible = false
	shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	var sb := _pill_style(Color(0.99, 0.96, 0.90))
	sb.content_margin_left = 24; sb.content_margin_right = 24
	sb.content_margin_top = 18; sb.content_margin_bottom = 20
	shop_panel.add_theme_stylebox_override("panel", sb)
	shop_panel.offset_left = -620; shop_panel.offset_right = 620
	shop_panel.offset_top = -240; shop_panel.offset_bottom = 240

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	shop_panel.add_child(col)

	var title := Label.new()
	title.text = "가구 상점"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	col.add_child(title)

	var cash_line := Label.new()
	cash_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cash_line.add_theme_font_override("font", font)
	cash_line.add_theme_font_size_override("font_size", 20)
	cash_line.add_theme_color_override("font_color", Color(0.55, 0.44, 0.30))
	col.add_child(cash_line)
	shop_cash_label = cash_line

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)

	for fid in slots["items"]:
		row.add_child(_mk_shop_card(fid, slots["items"][fid]))

	var close := _mk_button("닫기", Callable(self, "_close_shop"))
	col.add_child(close)
	add_child(shop_panel)


func _mk_shop_card(fid: String, item: Dictionary) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 6)
	card.set_meta("item_id", fid)

	var img := TextureRect.new()
	img.texture = load(item["sprite"])
	img.custom_minimum_size = Vector2(96, 110)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(img)

	var name_l := Label.new()
	name_l.text = item["name"]
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_override("font", font)
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	card.add_child(name_l)

	var price_l := Label.new()
	price_l.text = "%s원" % _fmt(item["price"])
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_l.add_theme_font_override("font", font)
	price_l.add_theme_font_size_override("font_size", 14)
	price_l.add_theme_color_override("font_color", Color(0.55, 0.44, 0.30))
	card.add_child(price_l)

	var buy := Button.new()
	buy.text = "구매"
	buy.custom_minimum_size = Vector2(96, 42)
	buy.add_theme_font_override("font", font)
	buy.add_theme_font_size_override("font_size", 18)
	buy.add_theme_color_override("font_color", Color(1, 1, 0.98))
	buy.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	buy.add_theme_color_override("font_pressed_color", Color(0.95, 0.98, 0.9))
	buy.add_theme_color_override("font_disabled_color", Color(0.98, 0.98, 0.96))
	buy.add_theme_stylebox_override("normal", _pill_style(Color(0.72, 0.80, 0.58)))
	buy.add_theme_stylebox_override("hover", _pill_style(Color(0.78, 0.86, 0.64)))
	buy.add_theme_stylebox_override("pressed", _pill_style(Color(0.64, 0.72, 0.50)))
	buy.add_theme_stylebox_override("focus", _pill_style(Color(0.72, 0.80, 0.58)))
	buy.pressed.connect(func(): _try_buy(fid, buy))
	card.add_child(buy)
	card.set_meta("buy_btn", buy)
	return card


# ---------------------------------------------------------------- 반응 팝업
func _build_reaction() -> void:
	reaction_dim = ColorRect.new()
	reaction_dim.color = Color(0, 0, 0, 0.45)
	reaction_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	reaction_dim.visible = false
	reaction_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(reaction_dim)

	reaction_img = TextureRect.new()
	reaction_img.texture = load(SCREENS["reaction"])
	reaction_img.visible = false
	reaction_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reaction_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reaction_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	reaction_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reaction_img)

	var ok := _mk_button("좋아!", Callable(self, "_close_reaction"))
	ok.name = "ReactionOk"
	ok.position = Vector2(640 - 90, 720 - 110)
	ok.visible = false
	add_child(ok)


# ---------------------------------------------------------------- 화면 전환
func show_screen(next: String) -> void:
	state = next
	var tex: Texture2D = load(SCREENS[next])
	_fit_bg(tex)

	var is_room := next == "room"
	get_node("BottomBar").visible = is_room and placing.is_empty()
	get_node("PlaceBar").visible = is_room and not placing.is_empty()
	hud_panel.visible = is_room
	furniture_layer.visible = is_room
	char_node.visible = is_room
	overlay.visible = is_room and not placing.is_empty()
	ghost.visible = is_room and not placing.is_empty()
	if is_room:
		_layout_room()
		_update_hud()
		if not placing.is_empty():
			_update_overlay_transform()
			_update_ghost()

	if next == "reaction":
		reaction_dim.visible = true
		reaction_img.visible = true
		get_node("ReactionOk").visible = true
	else:
		reaction_dim.visible = false
		reaction_img.visible = false
		get_node("ReactionOk").visible = false

	var hint: String = {
		"title": "아무 곳이나 눌러 시작",
		"map": "관악구 선택 (화면을 누르세요)",
		"filter": "조건 확정 (화면을 누르세요)",
		"listing": "이 집 구경하기 (화면을 누르세요)",
		"house": "침실로 이동 (화면을 누르세요)",
	}.get(next, "")
	_show_toast(hint, 2.2)


func _fit_bg(tex: Texture2D) -> void:
	bg.texture = tex
	var win := Vector2(1280, 720)
	var scale: float = maxf(win.x / tex.get_width(), win.y / tex.get_height())
	var dw: float = tex.get_width() * scale
	var dh: float = tex.get_height() * scale
	bg.position = Vector2((win.x - dw) * 0.5, (win.y - dh) * 0.5)
	bg.size = Vector2(dw, dh)


# 이미지px → 화면 변환
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
	# 이미 배치된 가구 재배치
	for iid in placed_nodes:
		var p: GridModel.Placement = grid.placements[iid]
		_apply_placement_transform(placed_nodes[iid], p)
	_sort_furniture()


# ---------------------------------------------------------------- 배치 모드
func _item_layer(fid: String) -> int:
	var item: Dictionary = slots["items"][fid]
	match item["layer"]:
		"floor": return GridModel.Layer.UNDERLAY  # 러그
		"wall": return GridModel.Layer.WALL
	return GridModel.Layer.FLOOR


func _start_placing(fid: String) -> void:
	placing = fid
	place_rotation = 0
	var item: Dictionary = slots["items"][fid]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], 0)
	# 방 중앙 근처 빈 자리 탐색
	place_origin = _find_free_origin(fp, _item_layer(fid))
	ghost.texture = load(item["sprite"])
	ghost.flip_h = false
	_close_shop()
	show_screen("room")
	_update_overlay_transform()
	_update_ghost()


func _find_free_origin(fp: Vector2i, layer: int) -> Vector2i:
	for gy in range(grid.height - fp.y + 1):
		for gx in range(grid.width - fp.x + 1):
			var oy := 2 + gy
			var ox := 3 + gx
			if ox + fp.x > grid.width - 1: break
			if oy + fp.y > grid.height - 1: break
			if grid.can_place(fp.x, fp.y, Vector2i(ox, oy), 0, layer):
				return Vector2i(ox, oy)
	return Vector2i(0, 0)


func _rotate_placing() -> void:
	place_rotation = (place_rotation + 90) % 360
	ghost.flip_h = place_rotation == 90 or place_rotation == 270
	_update_ghost()


func _cancel_placing() -> void:
	var item: Dictionary = slots["items"][placing]
	econ.cash_balance += item["price"]  # 환불
	purchased.erase(placing)
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
	var ok := grid.can_place(fp.x, fp.y, place_origin, place_rotation, _item_layer(placing))
	# 위치
	var anchor: Vector2
	if item["layer"] == "wall":
		anchor = FloorProjector.grid_to_img(place_origin.x + fp.x * 0.5, place_origin.y + fp.y)
	else:
		anchor = FloorProjector.footprint_front_center(place_origin, fp.x, fp.y)
	var wpx: float = FloorProjector.footprint_width_px(place_origin, fp.x, fp.y)
	var scr := _img_to_screen(Vector2(anchor.x, anchor.y))
	var sc: float = bg.size.x / bg.texture.get_width()
	var w := wpx * sc
	var h := w * ghost.texture.get_height() / ghost.texture.get_width()
	ghost.size = Vector2(w, h)
	ghost.position = scr - Vector2(w * (0.5 if ghost.flip_h else 0.5), h - 12.0 * sc)
	ghost.modulate = Color(0.6, 1.0, 0.6, 0.75) if ok else Color(1.0, 0.5, 0.45, 0.75)
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
			"title": show_screen("map")
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
		# 벽 아이템: 후면 벽 변에 스냅
		if ox > 1: oy = 0
		else: ox = 0
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
	var node := TextureRect.new()
	node.texture = load(item["sprite"])
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.flip_h = ghost.flip_h
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	furniture_layer.add_child(node)
	placed_nodes[iid] = node
	_apply_placement_transform(node, grid.placements[iid])
	_sort_furniture()
	placing = ""
	_show_toast("%s 배치 완료!" % item["name"], 1.6)
	show_screen("room")
	_open_reaction()


func _apply_placement_transform(node: TextureRect, p: GridModel.Placement) -> void:
	var fp := GridModel.footprint_size(p.def_w, p.def_h, p.rotation)
	var anchor: Vector2
	var item: Dictionary = slots["items"][p.def_id]
	if p.layer == GridModel.Layer.WALL:
		anchor = FloorProjector.grid_to_img(p.origin.x + fp.x * 0.5, p.origin.y + fp.y)
	else:
		anchor = FloorProjector.footprint_front_center(p.origin, fp.x, fp.y)
	var wpx: float = FloorProjector.footprint_width_px(p.origin, fp.x, fp.y)
	var sc: float = bg.size.x / bg.texture.get_width()
	var w := wpx * sc
	var h := w * node.texture.get_height() / node.texture.get_width()
	node.size = Vector2(w, h)
	node.position = _img_to_screen(Vector2(anchor.x, anchor.y)) - Vector2(w * 0.5, h - 12.0 * sc)
	if p.layer == GridModel.Layer.WALL:
		node.position.y -= h * 0.55  # 바닥이 아닌 벽 높이에 걸기
	node.set_meta("sort_y", anchor.y)


# 화가 기법 정렬: 앞변 y (벽/러그는 자연히 위쪽)
func _sort_furniture() -> void:
	var nodes: Array = []
	for iid in placed_nodes:
		nodes.append([placed_nodes[iid].get_meta("sort_y", 0.0), placed_nodes[iid]])
	nodes.sort_custom(func(a, b): return a[0] < b[0])
	for i in nodes.size():
		furniture_layer.move_child(nodes[i][1], i)


func _goto_house() -> void:
	show_screen("house")


# ---------------------------------------------------------------- 경제/HUD
func _update_hud() -> void:
	for c in hud.get_children():
		hud.remove_child(c)
		c.queue_free()
	hud.add_child(_hud_line("%d월차" % econ.month, 30))
	hud.add_child(_hud_line("보유  %s원" % _fmt(econ.cash_balance), 22))
	hud.add_child(_hud_line("사용 가능  %s원" % _fmt(econ.spendable_cash()), 22, Color(0.45, 0.56, 0.30)))


func _hud_line(text: String, size: int, color := Color(0.35, 0.26, 0.18)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.94, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	return l


func _next_month() -> void:
	var r := econ.settle_month()
	_update_hud()
	_show_toast("%d월 정산: +%s원 / -%s원" % [_fmt(r["month"]), _fmt(r["income"]), _fmt(r["expenses"])], 2.5)


# ---------------------------------------------------------------- 상점 로직
func _open_shop() -> void:
	shop_cash_label.text = "사용 가능 %s원" % _fmt(econ.spendable_cash())
	for card in shop_panel.get_child(0).get_child(2).get_children():
		var fid: String = card.get_meta("item_id")
		var buy: Button = card.get_meta("buy_btn")
		buy.text = "구매됨" if purchased.has(fid) else "구매"
		buy.disabled = purchased.has(fid)
	hud_panel.visible = false
	shop_panel.visible = true


func _close_shop() -> void:
	shop_panel.visible = false
	if state == "room":
		hud_panel.visible = true


func _try_buy(fid: String, buy_btn: Button = null) -> void:
	if purchased.has(fid):
		_show_toast("이미 구입한 가구예요", 1.6)
		return
	var item: Dictionary = slots["items"][fid]
	if econ.try_spend(item["price"]):
		purchased[fid] = true
		if buy_btn != null:
			buy_btn.text = "구매됨"
			buy_btn.disabled = true
		_update_hud()
		_close_shop()
		_show_toast("%s 구매! 위치를 선택하세요" % item["name"], 1.8)
		_start_placing(fid)
	else:
		_show_toast("돈이 부족해요... 다음 달 월급을 기다려볼까요? (부족 %s원)" % _fmt(econ.shortfall(item["price"])), 2.8)


func _open_reaction() -> void:
	show_screen("reaction")
	_show_toast("설치를 마쳤어요! 기분이 좋아진다", 2.5)


func _close_reaction() -> void:
	show_screen("room")


# ---------------------------------------------------------------- 유틸
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


# 테스트/캡처용
func debug_set(next: String) -> void:
	show_screen(next)
