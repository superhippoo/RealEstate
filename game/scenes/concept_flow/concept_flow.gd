extends Control
## 원본 기획 이미지 + GPT 스프라이트 파이프라인으로 구성하는 수직 슬라이스.
## 표지→지도→필터→매물→전체집→방(빈 방 + 가구 배치) 흐름 + MiniEconomy + 상점 + 반응.

const Econ := preload("res://scripts/domain/mini_economy.gd")

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
var purchased := {}          # furniture id -> true
var bg: TextureRect
var hud: VBoxContainer
var hud_panel: PanelContainer
var furniture_layer: Control
var placed: Dictionary = {}  # id -> TextureRect
var toast: Label
var shop_panel: PanelContainer
var shop_cash_label: Label
var reaction_dim: ColorRect
var reaction_img: TextureRect
var char_node: TextureRect

var slots: Dictionary = {}   # gpt_slots.json 내용
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

	# 가구 레이어 (배경 위, UI 아래)
	furniture_layer = Control.new()
	furniture_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(furniture_layer)

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
	hud.name = "HudPanel"
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

	# 하단 버튼 row (앵커 없이 수동 좌표)
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
		var item: Dictionary = slots["items"][fid]
		row.add_child(_mk_shop_card(fid, item))

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
	get_node("BottomBar").visible = is_room
	hud_panel.visible = is_room
	furniture_layer.visible = is_room
	char_node.visible = is_room
	if is_room:
		_layout_room()
		_update_hud()

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


# 방 콘텐츠(가구/캐릭터)를 bg 커버핏 변환에 맞춰 배치
func _room_transform() -> Dictionary:
	var tex := bg.texture
	var win := Vector2(1280, 720)
	var scale: float = maxf(win.x / tex.get_width(), win.y / tex.get_height())
	var dw: float = tex.get_width() * scale
	var dh: float = tex.get_height() * scale
	var ox: float = (win.x - dw) * 0.5
	var oy: float = (win.y - dh) * 0.5
	var r: Dictionary = slots["room"]
	return {
		"scale": scale,
		"rx": ox + float(r["x"]) * scale,
		"ry": oy + float(r["y"]) * scale,
		"rw": float(r["w"]) * scale,
		"rh": float(r["h"]) * scale,
	}


func _layout_room() -> void:
	var t := _room_transform()
	# 캐릭터
	var c: Dictionary = slots["characters"]["c_idle"]
	var cw: float = c["width_px"] * t["scale"]
	var chh: float = cw * char_node.texture.get_height() / char_node.texture.get_width()
	char_node.size = Vector2(cw, chh)
	char_node.position = Vector2(
		t["rx"] + c["slot"][0] * t["rw"] - cw * 0.5,
		t["ry"] + c["slot"][1] * t["rh"] - chh + 10.0 * t["scale"])
	# 구매된 가구 재배치
	for fid in placed:
		_place_furniture(fid)


func _place_furniture(fid: String) -> void:
	var item: Dictionary = slots["items"][fid]
	var t := _room_transform()
	var node: TextureRect
	if placed.has(fid):
		node = placed[fid]
	else:
		node = TextureRect.new()
		node.texture = load(item["sprite"])
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.stretch_mode = TextureRect.STRETCH_SCALE
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		furniture_layer.add_child(node)
		placed[fid] = node
	var w: float = item["width_px"] * t["scale"]
	var h: float = w * node.texture.get_height() / node.texture.get_width()
	node.size = Vector2(w, h)
	var sx: float = item["slot"][0]
	var sy: float = item["slot"][1]
	if item["layer"] == "wall":
		node.position = Vector2(
			t["rx"] + sx * t["rw"] - w * 0.5,
			t["ry"] + sy * t["rh"] - h * 0.5)
	else:
		node.position = Vector2(
			t["rx"] + sx * t["rw"] - w * 0.5,
			t["ry"] + sy * t["rh"] - h + 12.0 * t["scale"])
	_sort_furniture()


# 화가 기법 정렬: 바닥 앵커 y 순 (러그는 항상 최하위, 벽은 y 값 자체가 작아 자연히 뒤)
func _sort_furniture() -> void:
	var nodes: Array = []
	for fid in placed:
		var item: Dictionary = slots["items"][fid]
		var y: float = item["slot"][1]
		if item["layer"] == "floor":
			y = -1.0
		nodes.append([y, placed[fid]])
	nodes.sort_custom(func(a, b): return a[0] < b[0])
	for i in nodes.size():
		furniture_layer.move_child(nodes[i][1], i)
	# 캐릭터는 가구 레이어 뒤(부모 기준 furniture_layer 다음)에 위치시킴
	if char_node.get_index() < furniture_layer.get_index():
		# char_node가 먼저 추가돼 있으므로 furniture_layer를 char 앞으로 이동
		pass


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match state:
			"title": show_screen("map")
			"map": show_screen("filter")
			"filter": show_screen("listing")
			"listing": show_screen("house")
			"house": show_screen("room")


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
	# 구매 완료 카드 상태 갱신
	for row in [shop_panel.get_child(0).get_child(2)]:
		for card in row.get_children():
			var fid: String = card.get_meta("item_id")
			var buy: Button = card.get_meta("buy_btn")
			if purchased.has(fid):
				buy.text = "구매됨"
				buy.disabled = true
	hud_panel.visible = false  # 패널 뒤 HUD 글자 잘림 방지
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
		_place_furniture(fid)
		_show_toast("%s 구매 완료!" % item["name"], 1.6)
		_open_reaction()
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
