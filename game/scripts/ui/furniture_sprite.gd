class_name FurnitureSprite
extends Sprite2D
## 가구 인스턴스의 표현. 논리 상태는 GridModel.Placement가 소유.
## 스프라이트: assets/sprites/{def_id}_{rot}.png (Blender 파이프라인 산출물)

const SPRITE_DIR := "res://assets/sprites/"
const MANIFEST_PATH := "res://assets/sprites/manifest.json"

static var godot_scale := 1.0
static var _manifest_loaded := false


static func load_manifest() -> void:
	if _manifest_loaded:
		return
	var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if f == null:
		push_warning("sprites manifest 없음 — 기본 스케일 사용")
		_manifest_loaded = true
		return
	var m = JSON.parse_string(f.get_as_text())
	if m and m.has("godot_scale"):
		godot_scale = float(m["godot_scale"])
	_manifest_loaded = true


var instance_id: int
var def_id: String


func setup(p_instance_id: int, p_def_id: String) -> void:
	load_manifest()
	instance_id = p_instance_id
	def_id = p_def_id
	scale = Vector2(godot_scale, godot_scale)
	centered = true


## GridModel.Placement 기준으로 위치/텍스처 갱신
func refresh(placement: GridModel.Placement) -> void:
	var fp := GridModel.footprint_size(placement.def_w, placement.def_h, placement.rotation)
	var center_x := placement.origin.x + fp.x / 2.0
	var center_y := placement.origin.y + fp.y / 2.0
	# 다이아 셀 (x,y)의 중심은 (x+0.5, y+0.5)
	position = IsoProjector.gridf_to_screen(center_x, center_y)
	match placement.layer:
		GridModel.Layer.UNDERLAY:
			z_index = -50   # 러그: 방 이미지(-100) 위, 모든 가구 아래
		_:
			z_index = int(position.y)
	var tex_path := SPRITE_DIR + "%s_%d.png" % [def_id, placement.rotation]
	var tex := load(tex_path)
	if tex:
		texture = tex
	else:
		push_warning("스프라이트 없음: " + tex_path)
