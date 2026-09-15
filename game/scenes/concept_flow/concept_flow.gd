extends Control
## "방 한 칸에서 한남동까지" MVP v4 — 실시간 시간/직장·매물 선택/자율생활/계약/보관함.
## 기획: 00§9 첫 세션, 02§9 첫 매물, 03§3 첫 직장, 04 시간·계약, 07 자율생활, 08 부업, 09 이사·보관함

const GameStateScript := preload("res://scripts/domain/game_state.gd")
const GridModel := preload("res://scripts/core/grid_model.gd")
const FloorProjector := preload("res://scripts/core/floor_projector.gd")
const GridOverlayScript := preload("res://scenes/concept_flow/grid_overlay.gd")
const CharAgentScript := preload("res://scripts/character/char_agent.gd")

const SCREENS := {
	"title":  "res://assets/concept/01_cover_house_concept.png",
	"room":   "res://assets/concept_room/room_empty.png",
}

var state := "title"
var gs: GameState
var grid := GridModel.new(16, 12)
var bg: TextureRect
var hud: VBoxContainer
var hud_panel: PanelContainer
var month_bar: ProgressBar
var desire_panel: PanelContainer
var furniture_layer: Control
var placed_nodes := {}
var toast: Label
var shop_panel: PanelContainer
var shop_cash_label: Label
var storage_panel: PanelContainer
var dim: ColorRect
var rotate_hint: ColorRect
var sidejob_btn: Button
var popup: PanelContainer
var popup_title: Label
var popup_body: VBoxContainer
var agent: Node2D

var placing: String = ""
var placing_from_storage := false
var place_origin := Vector2i(6, 5)
var place_rotation := 0
var ghost: TextureRect
var overlay: Control
var bottom_bar: HBoxContainer
var place_bar: HBoxContainer
var floaties: Control

var slots: Dictionary = {}
var font: FontFile
var time_running := false
var popup_opened_ms := 0            # 팝업 직후 스친 클릭 방지(클릭 통과 확인 방지)용
var restore_panel_after_settle := ""  # 정산 팝업 뒤에 그대로 둘 패널(shop/storage)


func _ready() -> void:
	font = load("res://assets/fonts/NotoSansKR.ttf")
	var f := FileAccess.open("res://data/gpt_slots.json", FileAccess.READ)
	slots = JSON.parse_string(f.get_as_text())
	gs = GameStateScript.new()
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	show_screen("title")


func _process(delta: float) -> void:
	# 세로 화면(모바일 정자세) 안내 — 가로 설계 게임이 잘리지 않게
	var vp_size := get_viewport_rect().size
	var portrait := vp_size.x < vp_size.y * 0.9
	if portrait != rotate_hint.visible:
		rotate_hint.visible = portrait
		if portrait:
			time_running = false
			_close_all_popups()
	# 와치독: 어떤 모달도 보이지 않는데 입력이 잠겨있으면 스스로 복구 (soft-lock 방지)
	if dim.visible and not popup.visible and not shop_panel.visible \
			and not storage_panel.visible and placing.is_empty() and not portrait:
		_watchdog_ms += int(delta * 1000.0)
		if _watchdog_ms > 1000:
			_watchdog_ms = 0
			dim.visible = false
			time_running = state == "room"
			_show_toast("화면이 잠깐 멈췄어요 — 다시 시도해 주세요", 1.5)
	else:
		_watchdog_ms = 0
	if time_running and state == "room":
		if gs.tick(delta):
			_on_month_boundary()


var _watchdog_ms := 0


# ================================================================ UI 구성
func _build_ui() -> void:
	bg = TextureRect.new()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_bg_input)
	add_child(bg)

	furniture_layer = Control.new()
	furniture_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(furniture_layer)

	# 캐릭터 (07§10 자율생활)
	agent = CharAgentScript.new()
	furniture_layer.add_child(agent)
	agent.setup(self)
	agent.action_finished.connect(_on_action_finished)

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

	# HUD
	hud = VBoxContainer.new()
	var hud_bg := PanelContainer.new()
	hud_bg.add_theme_stylebox_override("panel", _pill(Color(0.99, 0.96, 0.90, 0.93)))
	hud_bg.position = Vector2(640 - 250, 8)
	hud_bg.size = Vector2(500, 128)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("separation", 2)
	hud_bg.add_child(hud)
	add_child(hud_bg)
	hud_panel = hud_bg

	month_bar = ProgressBar.new()
	month_bar.custom_minimum_size = Vector2(468, 10)
	month_bar.show_percentage = false
	month_bar.modulate = Color(1, 1, 1, 0.9)
	hud.add_child(month_bar)

	# 욕구 패널 (우측)
	desire_panel = PanelContainer.new()
	desire_panel.add_theme_stylebox_override("panel", _pill(Color(0.99, 0.96, 0.90, 0.94)))
	desire_panel.position = Vector2(1280 - 320, 150)
	desire_panel.size = Vector2(300, 200)
	desire_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desire_panel)

	# 하단 버튼
	bottom_bar = HBoxContainer.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.position = Vector2(24, 720 - 92)
	bottom_bar.size = Vector2(1232, 80)
	bottom_bar.add_theme_constant_override("separation", 12)
	var bl := Control.new(); bl.custom_minimum_size.x = 24
	bottom_bar.add_child(bl)
	bottom_bar.add_child(_mk_button("가구 상점", Callable(self, "_open_shop")))
	bottom_bar.add_child(_mk_button("보관함", Callable(self, "_open_storage")))
	sidejob_btn = _mk_button("부업", Callable(self, "_open_sidejob"))
	bottom_bar.add_child(sidejob_btn)
	add_child(bottom_bar)

	# 배치 모드 버튼
	place_bar = HBoxContainer.new()
	place_bar.name = "PlaceBar"
	place_bar.position = Vector2(24, 720 - 92)
	place_bar.size = Vector2(1232, 80)
	place_bar.add_theme_constant_override("separation", 12)
	var pl := Control.new(); pl.custom_minimum_size.x = 24
	place_bar.add_child(pl)
	var rot := _mk_button("회전 ↻", Callable(self, "_rotate_placing"))
	rot.custom_minimum_size = Vector2(150, 64)
	place_bar.add_child(rot)
	var keep := _mk_button("보관함에 넣기", Callable(self, "_store_placing"))
	keep.custom_minimum_size = Vector2(210, 64)
	place_bar.add_child(keep)
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
	toast.offset_top = -110; toast.offset_bottom = -40
	add_child(toast)

	_build_shop_panel()
	_build_storage_panel()

	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	popup = PanelContainer.new()
	popup.add_theme_stylebox_override("panel", _pill(Color(0.99, 0.96, 0.90)))
	popup.position = Vector2(640 - 350, 150)
	popup.size = Vector2(700, 430)
	popup.visible = false
	add_child(popup)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	popup.add_child(col)
	popup_title = _label("제목", 26)
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(popup_title)
	popup_body = col

	# 패널들은 dim 위에, 플로팅/토스트는 그 위에 (피드백 가림 방지)
	move_child(shop_panel, get_child_count() - 1)
	move_child(storage_panel, get_child_count() - 1)
	# 정산 팝업은 상점/보관함 위에 떠야 한다 (세션을 닫지 않고 겹쳐 보여줌)
	move_child(popup, get_child_count() - 1)
	floaties = Control.new()
	floaties.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floaties)
	move_child(toast, get_child_count() - 1)

	# 세로 화면 안내 오버레이 (최상위, 입력 차단) — 모바일 정자세 대응
	rotate_hint = ColorRect.new()
	rotate_hint.color = Color(0.13, 0.11, 0.09, 0.97)
	rotate_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	rotate_hint.visible = false
	add_child(rotate_hint)
	var rh_col := VBoxContainer.new()
	rh_col.set_anchors_preset(Control.PRESET_CENTER)
	rh_col.add_theme_constant_override("separation", 14)
	rotate_hint.add_child(rh_col)
	var rh_icon := _label("📱↻", 84)
	rh_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rh_col.add_child(rh_icon)
	var rh_t := _label("기기를 가로로 회전해 주세요", 30)
	rh_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rh_col.add_child(rh_t)
	var rh_s := _label("이 게임은 가로 화면으로 플레이해요", 18, Color(0.72, 0.66, 0.55))
	rh_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rh_col.add_child(rh_s)


func _label(text: String, size: int, color := Color(0.35, 0.26, 0.18)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.94, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l


## 모든 버튼에 눌림 피드백 (스케일 트윈)
func _mk_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 60)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
	b.add_theme_stylebox_override("normal", _pill(Color(0.98, 0.94, 0.86)))
	b.add_theme_stylebox_override("hover", _pill(Color(1.0, 0.97, 0.91)))
	b.add_theme_stylebox_override("pressed", _pill(Color(0.88, 0.80, 0.68)))
	b.add_theme_stylebox_override("focus", _pill(Color(0.98, 0.94, 0.86)))
	b.pivot_offset = Vector2(75, 30)
	if cb.is_valid():
		b.pressed.connect(cb)
	b.button_down.connect(func(): _btn_anim(b, 0.92, Color(1, 0.95, 0.85)))
	b.button_up.connect(func(): _btn_anim(b, 1.0, Color(1, 1, 1)))
	b.mouse_exited.connect(func():
		if not b.button_pressed:
			_btn_anim(b, 1.0, Color(1, 1, 1)))
	return b


func _btn_anim(b: Button, sc: float, mod: Color) -> void:
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(sc, sc), 0.07)
	b.modulate = mod


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


# ================================================================ 상점 / 보관함
func _build_shop_panel() -> void:
	shop_panel = PanelContainer.new()
	shop_panel.visible = false
	var sb := _pill(Color(0.99, 0.96, 0.90))
	sb.content_margin_left = 20; sb.content_margin_right = 20
	sb.content_margin_top = 14; sb.content_margin_bottom = 16
	shop_panel.add_theme_stylebox_override("panel", sb)
	shop_panel.position = Vector2(640 - 620, 105)
	shop_panel.size = Vector2(1240, 500)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	shop_panel.add_child(col)

	var title := _label("가구 상점", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var cash_line := _label("", 18, Color(0.55, 0.44, 0.30))
	cash_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cash_line)
	shop_cash_label = cash_line

	var row := GridContainer.new()
	row.columns = 7
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 10)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(row)

	for fid in slots["items"]:
		row.add_child(_mk_shop_card(fid, slots["items"][fid]))

	var close := _mk_button("닫기", Callable(self, "_close_all_popups"))
	col.add_child(close)
	add_child(shop_panel)


func _mk_shop_card(fid: String, item: Dictionary) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 5)
	card.set_meta("item_id", fid)

	var img := TextureRect.new()
	img.texture = load(item["sprite"])
	img.custom_minimum_size = Vector2(92, 88)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(img)

	var name_l := _label(item["name"], 14)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_l)

	var price_l := _label("%s원" % _fmt(item["price"]), 14, Color(0.42, 0.30, 0.15))
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(price_l)

	var buy := Button.new()
	buy.text = "구매"
	buy.custom_minimum_size = Vector2(92, 38)
	buy.pivot_offset = Vector2(46, 19)
	buy.add_theme_font_override("font", font)
	buy.add_theme_font_size_override("font_size", 17)
	buy.add_theme_color_override("font_color", Color(1, 1, 0.98))
	buy.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.5))
	buy.add_theme_stylebox_override("normal", _pill(Color(0.72, 0.80, 0.58)))
	buy.add_theme_stylebox_override("hover", _pill(Color(0.78, 0.86, 0.64)))
	buy.add_theme_stylebox_override("pressed", _pill(Color(0.60, 0.68, 0.47)))
	buy.add_theme_stylebox_override("focus", _pill(Color(0.72, 0.80, 0.58)))
	buy.button_down.connect(func(): _btn_anim(buy, 0.92, Color(1, 0.97, 0.9)))
	buy.button_up.connect(func(): _btn_anim(buy, 1.0, Color(1, 1, 1)))
	buy.pressed.connect(func(): _try_buy(fid, buy))
	card.add_child(buy)
	card.set_meta("buy_btn", buy)
	return card


func _build_storage_panel() -> void:
	storage_panel = PanelContainer.new()
	storage_panel.visible = false
	var sb := _pill(Color(0.99, 0.96, 0.90))
	sb.content_margin_left = 24; sb.content_margin_right = 24
	sb.content_margin_top = 16; sb.content_margin_bottom = 16
	storage_panel.add_theme_stylebox_override("panel", sb)
	storage_panel.position = Vector2(640 - 420, 160)
	storage_panel.size = Vector2(840, 400)
	add_child(storage_panel)


func _open_storage() -> void:
	_close_all_popups()
	for c in storage_panel.get_children():
		storage_panel.remove_child(c)
		c.queue_free()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	storage_panel.add_child(col)
	var title := _label("보관함", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	if gs.storage.is_empty():
		var empty := _label("보관함이 비었어요. 가구를 사서 넣어보세요!", 17)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(empty)
	else:
		var info := _label("보관함은 전역 공용이며 무제한이에요", 14, Color(0.55, 0.44, 0.30))
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(info)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(row)
		for fid in gs.storage:
			var item: Dictionary = slots["items"][fid]
			var card := VBoxContainer.new()
			card.add_theme_constant_override("separation", 4)
			var img := TextureRect.new()
			img.texture = load(item["sprite"])
			img.custom_minimum_size = Vector2(90, 100)
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card.add_child(img)
			var nl := _label(item["name"], 14)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(nl)
			var put := _mk_button("배치", Callable())
			put.pressed.connect(func(): _start_placing_from_storage(fid))
			put.custom_minimum_size = Vector2(90, 38)
			card.add_child(put)
			row.add_child(card)
	var close := _mk_button("닫기", Callable(self, "_close_all_popups"))
	col.add_child(close)
	dim.visible = true
	storage_panel.visible = true
	storage_panel.mouse_filter = Control.MOUSE_FILTER_STOP


# ================================================================ 화면 전환
func show_screen(next: String) -> void:
	state = next
	time_running = false
	var tex: Texture2D = load(SCREENS[next])
	_fit_bg(tex)

	var is_room := next == "room"
	bottom_bar.visible = is_room and placing.is_empty()
	place_bar.visible = is_room and not placing.is_empty()
	hud_panel.visible = is_room
	desire_panel.visible = is_room
	furniture_layer.visible = is_room
	overlay.visible = is_room and not placing.is_empty()
	ghost.visible = is_room and not placing.is_empty()
	if next == "title":
		_show_title_menu()
	if is_room:
		_layout_room()
		_update_hud()
		_update_desire_panel()
		time_running = true


func _show_title_menu() -> void:
	_open_popup("방 한 칸에서 한남동까지",
		["서울에서 첫 직장을 얻었어요.", "가진 돈 4,500,000원.", "첫 직장과 첫 집을 골라 새 삶을 시작해요."])
	var new_b := _mk_button("새 게임", Callable(self, "_show_job_select"))
	new_b.custom_minimum_size = Vector2(300, 60)
	popup_body.add_child(new_b)
	if gs.has_save():
		var cont := _mk_button("이어하기", Callable(self, "_continue_game"))
		cont.custom_minimum_size = Vector2(300, 60)
		popup_body.add_child(cont)


# ---------------------------------------------------------------- 직장 선택 (03§3)
func _show_job_select() -> void:
	show_screen("title")
	_open_popup("첫 직장을 선택하세요",
		["월급 · 업무강도 · 부업 기회가 모두 달라요.", "나중에 이직할 수도 있어요."])
	for c in GameStateScript.COMPANIES:
		var comp: Dictionary = c
		var btn := _mk_button("", Callable())
		btn.pressed.connect(func(): _pick_job(comp))
		btn.custom_minimum_size = Vector2(560, 74)
		var rich := Label.new()
		rich.text = "%s — 월급 %s · 부업 %d회/월 · 통근지 %s" % [
			comp["name"], _fmt(comp["salary"]), comp["sidejobs"], comp["district"]]
		rich.add_theme_font_override("font", font)
		rich.add_theme_font_size_override("font_size", 19)
		rich.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
		btn.add_child(rich)
		var desc := _label(comp["desc"], 14, Color(0.5, 0.42, 0.32))
		desc.position = Vector2(20, 42)
		btn.add_child(desc)
		popup_body.add_child(btn)


func _pick_job(comp: Dictionary) -> void:
	gs.company = comp.duplicate()
	_show_listing_select()


# ---------------------------------------------------------------- 매물 선택 (02§9)
func _show_listing_select() -> void:
	_open_popup("첫 집을 고르세요",
		["월세가 싸면 통근이 길고, 가까우면 비싸요.", "월 생활비가 달라집니다."])
	for l in GameStateScript.LISTINGS:
		var li: Dictionary = l
		var btn := _mk_button("", Callable())
		btn.pressed.connect(func(): _pick_listing(li))
		btn.custom_minimum_size = Vector2(560, 84)
		var rich := Label.new()
		rich.text = "%s (%s · %s) — 월세 %s + 관리비 %s" % [
			li["name"], li["region"], li["size"], _fmt(li["rent"]), _fmt(li["maintenance"])]
		rich.add_theme_font_override("font", font)
		rich.add_theme_font_size_override("font_size", 19)
		rich.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
		btn.add_child(rich)
		var desc := _label("%s · 통근 %d분 (부업 %d회/월)" % [
			li["desc"], li["commute"],
			gs.company["sidejobs"] + GameStateScript.commute_sidejob_adj(li["commute"])], 14,
			Color(0.5, 0.42, 0.32))
		desc.position = Vector2(20, 48)
		btn.add_child(desc)
		popup_body.add_child(btn)


func _pick_listing(li: Dictionary) -> void:
	gs.listing = li.duplicate()
	gs.contract_remaining = GameStateScript.CONTRACT_LENGTH
	_close_all_popups()
	gs = _reset_run_state()
	show_screen("room")
	_show_toast("%s 입주! 계약 24개월 · 월 지출 %s원" % [
		li["name"], _fmt(gs.monthly_expenses())], 3.0)
	agent.place_at_cell(Vector2i(8, 8))


func _reset_run_state() -> GameState:
	var n := GameStateScript.new()
	n.company = gs.company
	n.listing = gs.listing
	for iid in placed_nodes.keys():
		placed_nodes[iid].queue_free()
	placed_nodes.clear()
	grid = GridModel.new(16, 12)
	return n


func _continue_game() -> void:
	_close_all_popups()
	gs = GameStateScript.load_game()
	_apply_loaded_game()
	show_screen("room")
	# 오프라인 정산 (04§4/§10)
	var off := gs.offline_months(int(Time.get_unix_time_from_system()))
	if off > 0:
		var reports := []
		for i in off:
			reports.append(gs.settle_month())
		var r0: Dictionary = reports[0]
		_open_popup("돌아왔어요 — %d개월이 지났어요" % off, [
			"월급 총 +%s원" % _fmt(int(r0["income"]) * off),
			"지출 총 -%s원" % _fmt(int(r0["expenses"]) * off),
			"계약 잔여 %d개월" % gs.contract_remaining,
			"체력 %d · 스트레스 %d · 행복 %d" % [gs.energy, gs.stress, gs.happiness],
		])
		var ok := _mk_button("확인", Callable(self, "_close_all_popups"))
		ok.custom_minimum_size = Vector2(300, 56)
		popup_body.add_child(ok)
	_show_toast("%d월차로 돌아왔어요" % gs.month, 2.0)


func _apply_loaded_game() -> void:
	for p in GameStateScript.load_placements():
		var origin := Vector2i(int(p["ox"]), int(p["oy"]))
		var layer := int(p["layer"])
		var fp := GridModel.footprint_size(int(p["w"]), int(p["h"]), int(p["rot"]))
		if grid.can_place(fp.x, fp.y, origin, int(p["rot"]), layer, -1):
			var iid := grid.place(p["fid"], fp.x, fp.y, origin, int(p["rot"]), layer)
			if iid > 0:
				_add_furniture_node(iid, p["fid"])
	agent.on_furniture_changed()


# ---------------------------------------------------------------- 좌표 유틸
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


func grid_to_screen(cell: Vector2i) -> Vector2:
	return _img_to_screen(FloorProjector.cell_center(cell.x, cell.y))


func screen_to_cell(p: Vector2) -> Vector2i:
	var img := (p - bg.position) * (bg.texture.get_width() / bg.size.x)
	return FloorProjector.img_to_cell(img)


func char_width_px() -> float:
	return float(slots["characters"]["c_idle"]["width_px"]) * (bg.size.x / bg.texture.get_width())


func furniture_action(fid: String) -> String:
	return str(slots["items"][fid].get("action", ""))


## 가구 footprint 중심 화면좌표 (누운 포즈용)
func furniture_center_screen(iid: int) -> Vector2:
	var p: GridModel.Placement = grid.placements[iid]
	var fp := GridModel.footprint_size(p.def_w, p.def_h, p.rotation)
	return grid_to_screen(Vector2i(p.origin.x + fp.x / 2, p.origin.y + fp.y / 2))


## 가구 인스턴스의 상호작용 셀 (06§13) — 도달 가능한 것 우선
func interaction_cell_for(iid: int) -> Vector2i:
	var p: GridModel.Placement = grid.placements[iid]
	var item: Dictionary = slots["items"][p.def_id]
	var locals: Array = item.get("interaction_locals", [])
	var fp := GridModel.footprint_size(p.def_w, p.def_h, p.rotation)
	var best := Vector2i(-1, -1)
	var best_d := 1e9
	for local in locals:
		var cell: Vector2i = GridModel.local_to_room(Vector2i(local[0], local[1]),
				p.origin, fp.x, fp.y, p.rotation)
		if cell.x < 0 or cell.x >= grid.width or cell.y < 0 or cell.y >= grid.height:
			continue
		var screen := grid_to_screen(cell)
		var d: float = Vector2(agent.position.x, agent.position.y).distance_to(screen)
		if d < best_d:
			best_d = d
			best = cell
	return best


func _layout_room() -> void:
	for iid in placed_nodes:
		_apply_placement_transform(placed_nodes[iid], grid.placements[iid])
	_sort_furniture()
	agent._resize(char_width_px())


# ================================================================ HUD / 욕구
func _update_hud() -> void:
	for c in hud.get_children():
		if c == month_bar:
			continue
		hud.remove_child(c)
		c.queue_free()
	var l1 := _label("%d월차 · 만족도 %s · 계약 %d개월 남음" % [
			gs.month, gs.satisfaction_label(), gs.contract_remaining], 22)
	var l2 := _label("보유 %s원 · 사용 가능 %s원" % [_fmt(gs.cash_balance), _fmt(gs.spendable_cash())], 17,
			Color(0.45, 0.35, 0.22))
	var l3 := _label("체력 %d(%s) · 스트레스 %d(%s) · 행복 %d(%s)" % [
			gs.energy, GameStateScript.energy_label(gs.energy),
			gs.stress, GameStateScript.stress_label(gs.stress),
			gs.happiness, GameStateScript.happiness_label(gs.happiness)], 15, Color(0.32, 0.24, 0.16))
	hud.add_child(l1)
	hud.add_child(l2)
	hud.add_child(l3)
	hud.move_child(month_bar, 3)
	month_bar.max_value = GameStateScript.MONTH_SECONDS
	month_bar.value = gs.month_seconds
	if sidejob_btn != null:
		sidejob_btn.text = "부업 (%d/%d회)" % [gs.sidejobs_used, gs.sidejob_max()]


func _update_desire_panel() -> void:
	for c in desire_panel.get_children():
		desire_panel.remove_child(c)
		c.queue_free()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	desire_panel.add_child(col)

	if gs.goal_done:
		col.add_child(_label("♥ 모든 소원 완성!", 22, Color(0.72, 0.35, 0.30)))
		col.add_child(_label("방이 완성됐어요. 다음 목표는\n더 좋은 집!", 16))
		return

	var d: Dictionary = GameStateScript.DESIRES[gs.desire_index]
	col.add_child(_label("지금 갖고 싶어요 (%d/%d)" % [gs.desire_index + 1, GameStateScript.DESIRES.size()], 18))
	var line := _label(d["line"], 16)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 258
	col.add_child(line)
	for fid in d["items"]:
		var item: Dictionary = slots["items"][fid]
		var mark := "○" if not gs.purchased.has(fid) else "✔"
		var need := _label("%s %s — %s원" % [mark, item["name"], _fmt(item["price"])], 14,
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
	placing_from_storage = false
	place_rotation = 0
	var item: Dictionary = slots["items"][fid]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], 0)
	place_origin = _find_free_origin(fp, _item_layer(fid))
	ghost.texture = load(item["sprite"])
	ghost.flip_h = false
	_close_all_popups()
	time_running = false   # 04§2.4: 중요 결정 중 시간 정지
	show_screen("room")
	time_running = false
	_update_overlay_transform()
	_update_ghost()


func _start_placing_from_storage(fid: String) -> void:
	gs.place_stored(fid)   # 배치 시작 시 보관함에서 꺼냄
	placing = fid
	placing_from_storage = true
	place_rotation = 0
	var item: Dictionary = slots["items"][fid]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], 0)
	place_origin = _find_free_origin(fp, _item_layer(fid))
	ghost.texture = load(item["sprite"])
	ghost.flip_h = false
	_close_all_popups()
	time_running = false
	show_screen("room")
	time_running = false
	_update_overlay_transform()
	_update_ghost()


func _find_free_origin(fp: Vector2i, layer: int) -> Vector2i:
	for gy in range(grid.height - fp.y):
		for gx in range(grid.width - fp.x):
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
	_show_toast("%d도 회전했어요" % place_rotation, 1.2)


func _store_placing() -> void:
	# 05§16: [보관함에 넣기]
	var fid := placing
	var done: Dictionary = gs.store_furniture(fid)
	gs.save_game_with(_placements_list())
	placing = ""
	_show_toast("%s를 보관함에 넣었어요" % slots["items"][fid]["name"], 1.8)
	_update_hud()
	_update_desire_panel()
	show_screen("room")
	if not done.is_empty():
		_desire_celebration(done)


func _cancel_placing() -> void:
	if placing_from_storage:
		gs.storage.append(placing)   # 보관함 행：환불 없이 재보관
		_show_toast("다시 보관함에 넣었어요", 1.5)
	else:
		gs.cash_balance += slots["items"][placing]["price"]
		_show_toast("구매를 취소했어요 (환불 완료)", 1.8)
	placing = ""
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
	ghost.position = scr - Vector2(w * 0.5, h - GROUND_LIFT_IMG_PX * sc)
	ghost.modulate = Color(0.5, 1.0, 0.5, 0.85) if ok else Color(1.0, 0.35, 0.3, 0.85)
	if item["layer"] == "wall":
		ghost.position.y -= h * 0.55
	overlay.highlight_origin = place_origin
	overlay.highlight_size = fp
	overlay.highlight_ok = ok
	overlay.queue_redraw()


func _on_bg_input(event: InputEvent) -> void:
	# gui_input의 event.position은 bg 로컬 좌표 — 화면 좌표로 변환해서 써야 한다
	# (bg는 중앙정렬 여백이 있어 로컬≠화면; 과거 고스트가 커서에서 좌상단으로 떠 있던 원인)
	if event is InputEventMouseMotion and not placing.is_empty():
		_ghost_follow(bg.get_global_rect().position + event.position)
	elif event is InputEventMouseButton and event.pressed:
		if not placing.is_empty():
			_try_place_here(bg.get_global_rect().position + event.position)


func _ghost_follow(screen_pos: Vector2) -> void:
	if placing.is_empty():
		return
	var cell := screen_to_cell(screen_pos)
	if cell.x < 0:
		return
	var item: Dictionary = slots["items"][placing]
	var fp := GridModel.footprint_size(item["grid"][0], item["grid"][1], place_rotation)
	var ox: int = clampi(cell.x - fp.x / 2, 0, grid.width - fp.x)
	var oy: int = clampi(cell.y - fp.y / 2, 0, grid.height - fp.y)
	if item["layer"] == "wall":
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
		_show_toast("여기엔 놓을 수 없어요", 1.0)
		return
	var iid := grid.place(placing, fp.x, fp.y, place_origin, place_rotation, layer)
	if iid < 0:
		return
	var node := _add_furniture_node(iid, placing)
	_apply_placement_transform(node, grid.placements[iid])
	_sort_furniture()
	var done_desire: Dictionary = gs.own_furniture(placing)
	var placed_fid := placing
	placing = ""
	overlay.visible = false
	ghost.visible = false
	place_bar.visible = false
	bottom_bar.visible = true
	time_running = true
	gs.save_game_with(_placements_list())
	_update_hud()
	_update_desire_panel()
	agent.on_furniture_changed()
	agent.notify_new_furniture(placed_fid)   # 즉시 사용하러 감 (07§13)
	_spawn_floaty(agent.position + Vector2(0, -120), "%s 배치!" % item["name"], Color(0.3, 0.5, 0.3))
	if not done_desire.is_empty():
		_desire_celebration(done_desire)


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


## 가구 착지 보정(이미지 px): 스프라이트 하단을 발판 앞변에서 얼마나 들어올릴까.
## 12였으나 바닥에서 떠 보이는 갭의 원인 — 0(밀착)으로 캘리브레이션됨.
const GROUND_LIFT_IMG_PX := 0.0


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
	node.position = _img_to_screen(anchor) - Vector2(w * 0.5, h - GROUND_LIFT_IMG_PX * sc)
	if p.layer == GridModel.Layer.WALL:
		node.position.y -= h * 0.55
		node.position.y = maxf(node.position.y, 6.0)
	node.set_meta("sort_y", _img_to_screen(anchor).y)   # 화면 y로 통일 (캐릭터와 같은 단위)
	node.flip_h = p.rotation == 90 or p.rotation == 270


func _sort_furniture() -> void:
	# 화가 기법 정렬 — 전부 화면 y 동일 단위로 비교 (캐릭터 포함)
	var nodes: Array = []
	for iid in placed_nodes:
		nodes.append([placed_nodes[iid].get_meta("sort_y", 0.0), placed_nodes[iid]])
	# 가구 '사용 중'에는 항상 최상단(가구 위에 얹혀 보임), 이동 중에는 발 y 기준
	var ay: float = 1e9 if agent.get("state") == "using" else agent.position.y
	nodes.append([ay, agent])
	nodes.sort_custom(func(a, b): return a[0] < b[0])
	for i in nodes.size():
		furniture_layer.move_child(nodes[i][1], i)


func _sort_with_agent() -> void:
	_sort_furniture()


# ================================================================ 구매/부업
func _open_shop() -> void:
	shop_cash_label.text = "사용 가능 %s원 · 부업 %d/%d회" % [
		_fmt(gs.spendable_cash()), gs.sidejobs_used, gs.sidejob_max()]
	for card in shop_panel.get_child(0).get_child(2).get_children():
		var fid: String = card.get_meta("item_id")
		var buy: Button = card.get_meta("buy_btn")
		buy.text = "구매됨" if gs.purchased.has(fid) else "구매"
		buy.disabled = gs.purchased.has(fid)
	_close_all_popups()
	dim.visible = true
	shop_panel.visible = true
	shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _try_buy(fid: String, buy_btn: Button = null) -> void:
	if gs.purchased.has(fid):
		_show_toast("이미 구입한 가구예요", 1.4)
		return
	var item: Dictionary = slots["items"][fid]
	if gs.try_spend(item["price"]):
		if buy_btn != null:
			buy_btn.text = "구매됨"
			buy_btn.disabled = true
		_spawn_floaty(Vector2(640, 300), "-%s원" % _fmt(item["price"]), Color(0.75, 0.4, 0.3))
		_update_hud()
		_start_placing(fid)
	else:
		var lack := gs.shortfall(item["price"])
		_open_popup("%s — 갖고 싶은데…" % item["name"], [
			"%s원이 필요해요." % _fmt(item["price"]),
			"사용 가능 현금 %s원" % _fmt(gs.spendable_cash()),
			"%s원이 부족해요." % _fmt(lack),
			"이번 달 부업으로 최대 +%s원 더 벌 수 있어요." % _fmt(
				gs.sidejob_reward() * maxi(0, gs.sidejob_max() - gs.sidejobs_used)),
		])
		var sj := _mk_button("부업하기", Callable(self, "_open_sidejob"))
		sj.custom_minimum_size = Vector2(420, 56)
		popup_body.add_child(sj)
		var wait := _mk_button("다음 월급까지 기다리기", Callable(self, "_close_all_popups"))
		wait.custom_minimum_size = Vector2(420, 56)
		popup_body.add_child(wait)


func _open_sidejob(just_earned := 0) -> void:
	var remain: int = gs.sidejob_max() - gs.sidejobs_used
	var lines: Array = []
	if just_earned > 0:
		lines.append("일 끝!  +%s원" % _fmt(just_earned))
	lines.append("오늘 할 수 있는 부업: %s" % GameStateScript.SIDEJOB_NAMES[
			gs.sidejobs_used % GameStateScript.SIDEJOB_NAMES.size()])
	lines.append("보상 %s원 · 이번 달 %d/%d회" % [_fmt(gs.sidejob_reward()), gs.sidejobs_used, gs.sidejob_max()])
	_open_popup("부업하기", lines)
	if just_earned > 0:
		# 첫 줄(수입)을 큰 초록으로 강조
		for c in popup_body.get_children():
			if c is Label and str(c.text).begins_with("일 끝"):
				c.add_theme_font_size_override("font_size", 30)
				c.add_theme_color_override("font_color", Color(0.25, 0.55, 0.25))
				break
	var do_b := _mk_button("부업 시작", Callable())
	do_b.pressed.connect(func(): _do_sidejob())
	do_b.custom_minimum_size = Vector2(420, 56)
	popup_body.add_child(do_b)
	if remain <= 0:
		do_b.disabled = true
		do_b.text = "오늘은 끝! (달 %d회)" % gs.sidejob_max()
	var more := _mk_button("한 번 더", Callable())
	more.pressed.connect(func(): _do_sidejob())
	more.custom_minimum_size = Vector2(420, 56)
	if remain <= 1:
		more.disabled = true
	popup_body.add_child(more)
	var close := _mk_button("그만두기", Callable(self, "_close_all_popups"))
	close.custom_minimum_size = Vector2(420, 56)
	popup_body.add_child(close)


func _do_sidejob() -> void:
	if gs.do_sidejob():
		_open_sidejob(gs.sidejob_reward())
		_update_hud()
		gs.save_game_with(_placements_list())
	else:
		_show_toast("오늘은 부업을 다 했어요", 1.4)


# ================================================================ 월 정산 / 계약
func _on_month_boundary() -> void:
	time_running = false
	var r: Dictionary = gs.settle_month()
	var ev: Dictionary = r.get("event", {})
	# 상점/보관함을 보는 중이라면 세션을 닫지 않고 팝업만 위에 겹친다 (04§2.3: 쇼핑 중에도 시간은 흐름)
	restore_panel_after_settle = "shop" if shop_panel.visible else (
		"storage" if storage_panel.visible else "")
	var lines: Array = [
		"— %d월 정산 —" % r["month"],
		"월급 +%s원 · 지출 -%s원 (월세·관리비 %s + 생활비 1,300,000)" % [
			_fmt(r["income"]), _fmt(r["expenses"]), _fmt(gs.rent_total())],
	]
	if r["sidejob"] > 0:
		lines.append("부업 수입 +%s원" % _fmt(r["sidejob"]))
	if not ev.is_empty():
		var ec := int(ev.get("cash", 0))
		if ec != 0:
			lines.append("이번 달: %s (%s%s원)" % [ev["text"],
				"+" if ec > 0 else "-", _fmt(abs(ec))])
		else:
			lines.append("이번 달: %s" % ev["text"])
	lines.append("체력 %d(%s) · 스트레스 %d(%s) · 행복 %d(%s)" % [
			r["energy"], GameStateScript.energy_label(r["energy"]),
			r["stress"], GameStateScript.stress_label(r["stress"]),
			r["happiness"], GameStateScript.happiness_label(r["happiness"])])
	lines.append("보유 %s원 · 사용 가능 %s원" % [_fmt(gs.cash_balance), _fmt(gs.spendable_cash())])
	_open_popup("%d월이 되었어요" % r["month"], lines,
		restore_panel_after_settle != "")
	var ok := _mk_button("확인", Callable())
	ok.pressed.connect(func(): _after_settle())
	ok.custom_minimum_size = Vector2(300, 56)
	popup_body.add_child(ok)
	_update_hud()
	_update_desire_panel()
	gs.save_game_with(_placements_list())
	if gs.contract_remaining == 3:
		_show_toast("⚠ 3개월 후 계약 만료! 재계약/이사를 준비하세요", 3.0)
	elif gs.contract_remaining == 0:
		_contract_expiry()


func _after_settle() -> void:
	# 팝업이 뜬 직후 스친 클릭(카드/바닥 클릭의 잔탄)이 정산을 몰래 넘기지 않게 한다
	if Time.get_ticks_msec() - popup_opened_ms < 350:
		return
	_close_all_popups()
	if gs.contract_remaining <= 0:
		_contract_expiry()
	else:
		time_running = true
		match restore_panel_after_settle:
			"shop":
				_open_shop()
			"storage":
				_open_storage()
		restore_panel_after_settle = ""


## 안내 팝업(소원 달성 등) 확인 — 같은 클릭 가드 적용
func _confirm_info_popup() -> void:
	if Time.get_ticks_msec() - popup_opened_ms < 350:
		return
	_close_all_popups()


# ---------------------------------------------------------------- 계약 만료 (04§14)
func _contract_expiry() -> void:
	_open_popup("계약이 만료되었어요", [
		"어떻게 할지 결정해야 해요. 결정하는 동안 시간은 멈춰요.",
		"재계약: 월세 5% 인상 갱신 (24개월)",
		"이사: 가구는 전부 보관함으로 옮겨져 새 집에서 다시 배치해요",
	])
	var renew := _mk_button("재계약하기", Callable())
	renew.pressed.connect(func(): _renew())
	renew.custom_minimum_size = Vector2(440, 56)
	popup_body.add_child(renew)
	var move := _mk_button("다른 집 알아보기", Callable())
	move.pressed.connect(func(): _move_flow())
	move.custom_minimum_size = Vector2(440, 56)
	popup_body.add_child(move)


func _renew() -> void:
	gs.renew_contract()
	_close_all_popups()
	time_running = true
	_show_toast("재계약 완료! 월세 %s원 · 24개월" % _fmt(int(gs.listing["rent"])), 2.5)
	_update_hud()
	gs.save_game_with(_placements_list())


func _move_flow() -> void:
	_close_all_popups()
	_open_popup("새 집을 고르세요", ["가구는 모두 보관함으로 옮겨져 새 집에서 다시 배치해요."])
	for l in GameStateScript.LISTINGS:
		var li: Dictionary = l
		var btn := _mk_button("", Callable())
		btn.pressed.connect(func(): _do_move(li))
		btn.custom_minimum_size = Vector2(560, 84)
		var rich := Label.new()
		rich.text = "%s (%s · %s) — 월세 %s + 관리비 %s · 통근 %d분" % [
			li["name"], li["region"], li["size"], _fmt(li["rent"]), _fmt(li["maintenance"]), li["commute"]]
		rich.add_theme_font_override("font", font)
		rich.add_theme_font_size_override("font_size", 18)
		rich.add_theme_color_override("font_color", Color(0.35, 0.26, 0.18))
		btn.add_child(rich)
		popup_body.add_child(btn)


func _do_move(li: Dictionary) -> void:
	gs.move_to(li)
	for iid in placed_nodes.keys():
		placed_nodes[iid].queue_free()
	placed_nodes.clear()
	grid = GridModel.new(16, 12)
	_close_all_popups()
	show_screen("room")
	agent.on_furniture_changed()
	agent.place_at_cell(Vector2i(8, 8))
	_show_toast("%s으로 이사! 가구 %d개가 보관함에 있어요" % [li["name"], gs.storage.size()], 3.5)
	_update_hud()
	_update_desire_panel()
	gs.save_game_with(_placements_list())


# ================================================================ 자율생활 연결
func _on_action_finished(eff: Dictionary) -> void:
	gs.energy = clampi(gs.energy + int(eff.get("energy", 0)), 0, 100)
	gs.stress = clampi(gs.stress + int(eff.get("stress", 0)), 0, 100)
	gs.happiness = clampi(gs.happiness + int(eff.get("happiness", 0)), 0, 100)
	var txt := ""
	if int(eff.get("happiness", 0)) >= 4: txt = "행복 +%d" % int(eff["happiness"])
	elif int(eff.get("stress", 0)) <= -6: txt = "스트레스 %d" % int(eff["stress"])
	elif int(eff.get("energy", 0)) >= 8: txt = "체력 +%d" % int(eff["energy"])
	if not txt.is_empty():
		_spawn_floaty(agent.position + Vector2(0, -110), txt, Color(0.45, 0.6, 0.4))
	_update_hud()
	_sort_furniture()


func _desire_celebration(d: Dictionary) -> void:
	_open_popup("소원이 이뤄졌어요! ♥", [
		"%s 완성!" % d["name"],
		"행복이 크게 올랐어요. 방이 점점 좋아지고 있어요.",
		"캐릭터가 새 가구를 사용하기 시작했어요!",
	])
	var ok := _mk_button("좋아!", Callable(self, "_confirm_info_popup"))
	ok.custom_minimum_size = Vector2(300, 56)
	popup_body.add_child(ok)
	if gs.goal_done:
		_show_goal()


func _show_goal() -> void:
	_open_popup("🏆 첫 방 완성!", [
		"5개의 소원을 모두 이뤘어요!",
		"체력 %d · 스트레스 %d · 행복 %d" % [gs.energy, gs.stress, gs.happiness],
		"계약 만료 시 더 좋은 집으로 이사할 수 있어요.",
	])
	var keep := _mk_button("계속 꾸미기", Callable(self, "_confirm_info_popup"))
	keep.custom_minimum_size = Vector2(420, 56)
	popup_body.add_child(keep)


# ================================================================ 팝업/피드백
func _open_popup(title_text: String, lines: Array, keep_panels := false) -> void:
	toast.visible = false
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
	_close_all_popups()
	dim.visible = true
	popup.visible = true
	if keep_panels:
		match restore_panel_after_settle:
			"shop":
				shop_panel.visible = true
			"storage":
				storage_panel.visible = true
		# 팝업이 열려 있는 동안 뒤 상점/보관함 카드 클릭 차단 (정산 확인 우회 방지)
		shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		storage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		restore_panel_after_settle = ""
	time_running = false
	popup_opened_ms = Time.get_ticks_msec()


func _close_all_popups() -> void:
	popup.visible = false
	shop_panel.visible = false
	storage_panel.visible = false
	dim.visible = false
	if state == "room" and placing.is_empty():
		time_running = true


## 플로팅 효과 텍스트 (피드백 강화)
func _spawn_floaty(pos: Vector2, text: String, color: Color) -> void:
	var l := _label(text, 22, color)
	l.position = pos - Vector2(80, 0)
	floaties.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 70, 1.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


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
