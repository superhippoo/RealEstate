extends Control
## 원본 기획 이미지로 구성하는 수직 슬라이스 (Vertical Slice).
## 기획 목업 01→03→04→05→06→08 화면 흐름 + MiniEconomy + 가구 상점 + 캐릭터 반응.

const Econ := preload("res://scripts/domain/mini_economy.gd")

const SCREENS := {
	"title":  "res://assets/concept/01_cover_house_concept.png",
	"map":    "res://assets/concept/03_seoul_map_district_selection.png",
	"filter": "res://assets/concept/04_housing_condition_selection.png",
	"listing": "res://assets/concept/05_listing_comparison_house_tour.png",
	"house":  "res://assets/concept/06_whole_house_living_screen.png",
	"room":   "res://assets/concept/08_room_unfolded_edit_view.png",
	"reaction": "res://assets/concept/10_character_reaction_after_completion.png",
}

const SHOP_ITEMS := [
	{"id": "armchair", "name": "안락의자", "price": 180_000, "icon": "res://assets/concept/icon_armchair.png"},
	{"id": "lamp", "name": "플로어램프", "price": 90_000, "icon": "res://assets/concept/icon_lamp.png"},
	{"id": "plant", "name": "화분 스탠드", "price": 45_000, "icon": "res://assets/concept/icon_plant.png"},
	{"id": "sidetable", "name": "사이드 테이블", "price": 70_000, "icon": "res://assets/concept/icon_sidetable.png"},
	{"id": "rug", "name": "러그", "price": 60_000, "icon": "res://assets/concept/icon_rug.png"},
]

# 안락의자 — 상점 카드에서 잘라낸 불투명 스프라이트를 식물과 침대 사이 빈 바닥에 놓음
const ARMCHAIR_SPOT := Vector2(0.415, 0.53)     # 이미지 비율: 의자 발판 중심
const ARMCHAIR_SIZE := Vector2(140, 140)        # 화면 px

var state := "title"
var econ := Econ.new()
var purchased := {}          # id -> true
var bg: TextureRect
var hud: VBoxContainer
var hud_panel: PanelContainer
var toast: Label
var shop_panel: PanelContainer
var shop_cash_label: Label
var reaction_dim: ColorRect
var reaction_img: TextureRect
var placed_armchair: TextureRect
var sfx_label: Label

var font: FontFile


func _ready() -> void:
	font = load("res://assets/fonts/NotoSansKR.ttf")
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

	# 상단 HUD — 좌상단 미니맵과 겹치지 않게 상단 중앙 패널
	hud = VBoxContainer.new()
	hud.name = "HudPanel"
	var hud_bg := PanelContainer.new()
	var hud_style := _pill_style(Color(0.99, 0.96, 0.90, 0.92))
	hud_style.content_margin_left = 22; hud_style.content_margin_right = 22
	hud_style.content_margin_top = 10; hud_style.content_margin_bottom = 12
	hud_bg.add_theme_stylebox_override("panel", hud_style)
	hud_bg.position = Vector2(640 - 200, 14)
	hud_bg.size = Vector2(400, 110)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("separation", 2)
	hud_bg.add_child(hud)
	add_child(hud_bg)
	hud_panel = hud_bg

	# 하단 버튼 row (방 화면용) — 앵커 없이 수동 좌표 (preset이 size를 덮어쓰는 문제 회피)
	var bottom := HBoxContainer.new()
	bottom.name = "BottomBar"
	bottom.position = Vector2(24, 720 - 92)
	bottom.size = Vector2(1232, 80)
	bottom.add_theme_constant_override("separation", 16)
	bottom.alignment = BoxContainer.ALIGNMENT_BEGIN
	var bl := Control.new(); bl.custom_minimum_size.x = 24  # 여백
	bottom.add_child(bl)
	bottom.add_child(_mk_button("가구 상점", Callable(self, "_open_shop")))
	bottom.add_child(_mk_button("다음 달", Callable(self, "_next_month")))
	bottom.add_child(_mk_button("집 전체", Callable(self, "_goto_house")))
	add_child(bottom)

	# 안락의자 (구매 시 표시)
	placed_armchair = TextureRect.new()
	placed_armchair.texture = load("res://assets/concept/sprite_armchair.png")
	placed_armchair.visible = false
	placed_armchair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(placed_armchair)

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
	sb.content_margin_left = 28; sb.content_margin_right = 28
	sb.content_margin_top = 22; sb.content_margin_bottom = 24
	shop_panel.add_theme_stylebox_override("panel", sb)
	shop_panel.offset_left = -600; shop_panel.offset_right = 600
	shop_panel.offset_top = -225; shop_panel.offset_bottom = 225

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	shop_panel.add_child(col)

	var title := Label.new()
	title.text = "가구 상점"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	col.add_child(title)

	var cash_line := Label.new()
	cash_line.name = "ShopCash"
	cash_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cash_line.add_theme_font_override("font", font)
	cash_line.add_theme_font_size_override("font_size", 20)
	cash_line.add_theme_color_override("font_color", Color(0.55, 0.44, 0.30))
	col.add_child(cash_line)
	shop_cash_label = cash_line

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)

	for item in SHOP_ITEMS:
		row.add_child(_mk_shop_card(item))

	var close := _mk_button("닫기", Callable(self, "_close_shop"))
	col.add_child(close)
	add_child(shop_panel)


func _mk_shop_card(item: Dictionary) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 6)
	card.set_meta("item_id", item["id"])

	var img := TextureRect.new()
	img.texture = load(item["icon"])
	img.custom_minimum_size = Vector2(120, 132)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(img)

	var name_l := Label.new()
	name_l.text = item["name"]
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_override("font", font)
	name_l.add_theme_font_size_override("font_size", 17)
	name_l.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	card.add_child(name_l)

	var price_l := Label.new()
	price_l.text = "%s원" % _fmt(item["price"])
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_l.add_theme_font_override("font", font)
	price_l.add_theme_font_size_override("font_size", 15)
	price_l.add_theme_color_override("font_color", Color(0.55, 0.44, 0.30))
	card.add_child(price_l)

	var buy := Button.new()
	buy.text = "구매"
	buy.custom_minimum_size = Vector2(110, 44)
	buy.add_theme_font_override("font", font)
	buy.add_theme_font_size_override("font_size", 19)
	buy.add_theme_color_override("font_color", Color(1, 1, 0.98))
	buy.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	buy.add_theme_color_override("font_pressed_color", Color(0.95, 0.98, 0.9))
	buy.add_theme_color_override("font_disabled_color", Color(0.98, 0.98, 0.96))
	buy.add_theme_stylebox_override("normal", _pill_style(Color(0.72, 0.80, 0.58)))
	buy.add_theme_stylebox_override("hover", _pill_style(Color(0.78, 0.86, 0.64)))
	buy.add_theme_stylebox_override("pressed", _pill_style(Color(0.64, 0.72, 0.50)))
	buy.add_theme_stylebox_override("focus", _pill_style(Color(0.72, 0.80, 0.58)))
	buy.pressed.connect(func(): _try_buy(item, buy, name_l))
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
	placed_armchair.visible = is_room and purchased.has("armchair")
	if is_room:
		_place_armchair()
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
	# 3:2(1536x1024) 이미지를 1280x720 커버핏: 세로 크롭
	var win := Vector2(1280, 720)
	var scale: float = maxf(win.x / tex.get_width(), win.y / tex.get_height())
	var dw: float = tex.get_width() * scale
	var dh: float = tex.get_height() * scale
	bg.position = Vector2((win.x - dw) * 0.5, (win.y - dh) * 0.5)
	bg.size = Vector2(dw, dh)


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
	var month_l := _hud_line("%d월차" % econ.month, 30)
	var cash_l := _hud_line("보유  %s원" % _fmt(econ.cash_balance), 22)
	var spend_l := _hud_line("사용 가능  %s원" % _fmt(econ.spendable_cash()), 22, Color(0.45, 0.56, 0.30))
	hud.add_child(month_l)
	hud.add_child(cash_l)
	hud.add_child(spend_l)


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
	shop_panel.visible = true


func _close_shop() -> void:
	shop_panel.visible = false


func _try_buy(item: Dictionary, buy_btn: Button, name_l: Label) -> void:
	if purchased.has(item["id"]):
		_show_toast("이미 구입한 가구예요", 1.6)
		return
	if econ.try_spend(item["price"]):
		purchased[item["id"]] = true
		buy_btn.text = "구매됨"
		buy_btn.disabled = true
		_update_hud()
		if state == "room":
			_update_hud()
		_close_shop()
		if item["id"] == "armchair":
			placed_armchair.visible = true
			_place_armchair()
		_show_toast("%s 구매 완료!" % item["name"], 1.6)
		# 구매 직후 캐릭터 반응 팝업
		_open_reaction()
	else:
		_show_toast("돈이 부족해요... 다음 달 월급을 기다려볼까요? (부족 %s원)" % _fmt(econ.shortfall(item["price"])), 2.8)


func _place_armchair() -> void:
	if not purchased.has("armchair"):
		return
	# 08 배경과 같은 커버핏 변환으로 09의 배치 지점에 하단중앙 기준 배치
	var win := Vector2(1280, 720)
	var scale: float = maxf(win.x / bg.texture.get_width(), win.y / bg.texture.get_height())
	var dw: float = bg.texture.get_width() * scale
	var dh: float = bg.texture.get_height() * scale
	var ox: float = (win.x - dw) * 0.5
	var oy: float = (win.y - dh) * 0.5
	var anchor := Vector2(ox + ARMCHAIR_SPOT.x * dw, oy + ARMCHAIR_SPOT.y * dh)
	placed_armchair.size = ARMCHAIR_SIZE
	placed_armchair.position = anchor - Vector2(ARMCHAIR_SIZE.x * 0.5, ARMCHAIR_SIZE.y - 14)
	move_child(placed_armchair, get_node("BottomBar").get_index())


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


# 테스트/캡처용: 강제 상태 진입
func debug_set(next: String) -> void:
	show_screen(next)
