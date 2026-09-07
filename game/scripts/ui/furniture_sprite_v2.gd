class_name FurnitureV2
extends Sprite2D
## Anchor 기반 가구 스프라이트 v2
## PNG의 이미지 중심이 아니라 anchor_px(가구 바닥 중심)를 grid 투영 위치에 맞춤.

const SPRITE_DIR := "res://assets/v2_sprites/"
const META_PATH := "res://assets/v2_sprites/anchors.json"

static var _meta: Dictionary = {}
static var _meta_loaded := false


static func load_meta() -> void:
	if _meta_loaded:
		return
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f:
		_meta = JSON.parse_string(f.get_as_text())
		if _meta == null:
			_meta = {}
	_meta_loaded = true


## 가구 배치: anchor_px를 grid 투영 위치에 정확히 맞춤
static func place(parent: Node2D, def_id: String, rot: int, grid_origin: Vector2i,
		fp_w: int, fp_h: int, layer: int = 0) -> FurnitureV2:
	load_meta()
	var spr := FurnitureV2.new()
	parent.add_child(spr)

	var fname := "%s_%d.png" % [def_id, rot]
	var tex := load(SPRITE_DIR + fname)
	if tex == null:
		push_warning("FurnitureV2: sprite not found: " + fname)
		return spr
	spr.texture = tex
	spr.centered = false  # offset 기준으로 배치

	# grid footprint 중심 → screen 좌표
	var cx := grid_origin.x + fp_w / 2.0
	var cy := grid_origin.y + fp_h / 2.0
	var screen := IsoProjector.gridf_to_screen(cx, cy)

	# anchor_px: PNG 내에서 가구 바닥 중심의 위치
	# Sprite2D.position = 화면상 가구 바닥 위치 - anchor_px
	if _meta.has(def_id) and _meta[def_id]["rotations"].has(str(rot)):
		var a: Array = _meta[def_id]["rotations"][str(rot)]["anchor_px"]
		spr.position = screen - Vector2(a[0], a[1])
	else:
		# 폴백: 이미지 중심을 anchor로 가정
		spr.position = screen - Vector2(tex.get_width() / 2.0, tex.get_height() / 2.0)

	# depth: 바닥 anchor의 screen_y 기준
	spr.z_index = int(screen.y)

	# 러그는 다른 가구 아래
	if layer == GridModel.Layer.UNDERLAY:
		spr.z_index = -100

	return spr


## 회전 갱신 (sprite 교체 + anchor 재계산)
func update_rotation(def_id: String, rot: int, grid_origin: Vector2i, fp_w: int, fp_h: int) -> void:
	var fname := "%s_%d.png" % [def_id, rot]
	var tex := load(SPRITE_DIR + fname)
	if tex:
		texture = tex
		var cx := grid_origin.x + fp_w / 2.0
		var cy := grid_origin.y + fp_h / 2.0
		var screen := IsoProjector.gridf_to_screen(cx, cy)
		if _meta.has(def_id) and _meta[def_id]["rotations"].has(str(rot)):
			var a: Array = _meta[def_id]["rotations"][str(rot)]["anchor_px"]
			position = screen - Vector2(a[0], a[1])
		else:
			position = screen - Vector2(tex.get_width() / 2.0, tex.get_height() / 2.0)
		z_index = int(screen.y)
