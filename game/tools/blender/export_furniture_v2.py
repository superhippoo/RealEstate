# -*- coding: utf-8 -*-
"""
가구 Anchor Export v2 — master_camera 기반
각 가구를 4방향 렌더하고 anchor_px를 포함한 metadata JSON 생성.

출력:
  assets/v2_sprites/{id}_{rot}.png  (transparent, alpha 정리됨)
  assets/v2_sprites/anchors.json    (배치 메타데이터)
"""
import bpy
import json
import math
import os
import sys
from mathutils import Vector
# PIL은 후처리 스크립트에서 사용

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from master_camera import (
    SPEC, apply_camera, apply_lighting, apply_render_settings,
    create_material, measure_anchor
)

OUT_DIR = os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "v2_sprites"))
STAGE = os.path.join(OUT_DIR, "_staging")

CELL = 0.25

# 팔레트 — 레퍼런스 이미지 대표색 직접 반영 (고채도/고웜톤)
# 레퍼런스 대표색: #a09070 #b09070 #a07040 #704020 #b0a080
PAL = {
    "wood":   (0.75, 0.52, 0.28), "wood_d": (0.55, 0.35, 0.18),  # 더 진한 웜우드
    "cream":  (0.96, 0.88, 0.72),  # 크림에 옐로우 티
    "linen":  (0.95, 0.87, 0.75),  # 따뜻한 린넨
    "sage":   (0.50, 0.72, 0.38), "sage_d": (0.42, 0.62, 0.30),  # 더 비비드 세이지
    "plant":  (0.22, 0.52, 0.22),  # 더 진한 그린
    "terra":  (0.88, 0.42, 0.25),  # 더 비비드 테라코타
    "brass":  (0.70, 0.55, 0.35),
    "charcoal": (0.28, 0.25, 0.22),
    "skin":   (0.96, 0.82, 0.68),
    "hair":   (0.20, 0.15, 0.11),
    "knit":   (0.94, 0.78, 0.55),  # 머스터드 크림 니트
    "pants":  (0.38, 0.36, 0.40),
    "shoe":   (0.35, 0.28, 0.23),
    "eye":    (0.14, 0.12, 0.10),
    "white":  (0.98, 0.96, 0.90),  # 웜 화이트
}

# 가구 정의: (id, footprint_cells [w,h], builder_function)
FURNITURE = []


def reg(id, w, h):
    def decorator(fn):
        FURNITURE.append((id, w, h, fn))
        return fn
    return decorator


# ================================================================ 지오메트리
def rbox(name, size, loc, m, parent, bevel=0.035, sub=2, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = size
    if sub:
        s = o.modifiers.new("s", "SUBSURF"); s.levels = sub
    if bevel:
        b = o.modifiers.new("b", "BEVEL"); b.width = bevel; b.segments = 4
    for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(m); o.parent = parent
    return o


def rcyl(name, r, depth, loc, m, parent, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=24)
    o = bpy.context.active_object; o.name = name
    for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(m); o.parent = parent
    return o


def rsph(name, r, loc, m, parent, scale=(1,1,1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=24, ring_count=16)
    o = bpy.context.active_object; o.name = name; o.scale = scale
    for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(m); o.parent = parent
    return o


# ================================================================ 가구 빌더 (Root 원점 = footprint center)
@reg("chair_basic", 2, 2)
def build_chair(root):
    m_wood = create_material(PAL["wood"])
    m_wood_d = create_material(PAL["wood_d"])
    S, H = 0.44, 0.42
    rbox("seat", (S, S, 0.05), (0, 0, H), m_wood, root, bevel=0.030)
    rbox("cushion", (S-0.05, S-0.05, 0.05), (0, 0, H+0.04), create_material(PAL["terra"]), root, bevel=0.025)
    for x in [-1,1]:
        for y in [-1,1]:
            rcyl(f"leg{x}{y}", 0.024, H, (x*(S/2-0.06), y*(S/2-0.06), H/2), m_wood_d, root)
    rbox("back", (S, 0.06, 0.42), (0, -S/2+0.05, H+0.23), m_wood, root, bevel=0.03)


@reg("bed_single", 4, 8)
def build_bed(root):
    m_wood = create_material(PAL["wood"])
    m_wood_d = create_material(PAL["wood_d"])
    sage = create_material(PAL["sage_d"]); linen = create_material(PAL["linen"])
    W, L = 1.0, 2.0
    rbox("plinth", (W, L, 0.18), (0, 0, 0.09), m_wood_d, root, bevel=0.04)
    rbox("head", (W+0.04, 0.12, 0.62), (0, -L/2+0.06, 0.40), m_wood, root, bevel=0.05)
    rbox("mattress", (W-0.06, L-0.06, 0.24), (0, 0, 0.30), linen, root, bevel=0.08)
    for sx in [-1,1]:
        rbox(f"pillow_{sx}", (W/2-0.04, 0.36, 0.14), (sx*W/4, -L/2+0.34, 0.49), linen,
             root, bevel=0.06, rot=(math.radians(-8), 0, 0))
    rbox("duvet", (W+0.01, L*0.58, 0.15), (0, L*0.20, 0.50), sage, root, bevel=0.07)
    rbox("cushion", (0.30, 0.30, 0.12), (W/5, L*0.02, 0.60), create_material(PAL["terra"]), root,
         bevel=0.06, rot=(0, 0, math.radians(-8)))


@reg("sofa_two", 6, 3)
def build_sofa(root):
    cream = create_material(PAL["cream"])
    terra = create_material(PAL["terra"])
    W, D = 1.44, 0.75
    rbox("base", (W, D, 0.20), (0, 0, 0.16), cream, root, bevel=0.06)
    for sx in [-1,1]:
        rcyl(f"arm_{sx}", 0.12, D, (sx*(W/2-0.09), 0, 0.40), cream, root)
    for i, sx in enumerate([-W/6, 0, W/6]):
        rbox(f"seat_{i}", (W/3-0.02, D-0.10, 0.14), (sx, 0.02, 0.35), cream, root, bevel=0.07)
        rbox(f"back_{i}", (W/3-0.03, 0.14, 0.30), (sx, -D/2+0.10, 0.48), cream, root, bevel=0.07)
    rbox("throw", (0.30, 0.30, 0.13), (W/5, 0.04, 0.53), terra, root, bevel=0.06)


@reg("plant_monstera", 2, 2)
def build_plant(root):
    pot = create_material(PAL["terra"])
    leaf = create_material(PAL["plant"])
    rcyl("pot", 0.14, 0.26, (0, 0, 0.13), pot, root)
    rcyl("rim", 0.17, 0.04, (0, 0, 0.27), pot, root)
    for i, (ang, h) in enumerate([(0,0.5),(1.1,0.7),(2.3,0.55),(3.5,0.75),(4.7,0.5)]):
        l = rsph(f"leaf_{i}", 0.18, (math.cos(ang)*0.08, math.sin(ang)*0.06, 0.33+h*0.50), leaf, root)
        l.scale = (0.42, 1.4, 0.60); l.rotation_euler = (0, 0.08, ang)


@reg("floor_lamp", 2, 2)
def build_lamp(root):
    brass = create_material(PAL["brass"])
    rcyl("base", 0.13, 0.04, (0, 0, 0.02), brass, root)
    rcyl("pole", 0.016, 1.00, (0, 0, 0.52), brass, root)
    rcyl("shade", 0.15, 0.24, (0, 0, 1.08), create_material(PAL["cream"]), root)
    # 발광은 calibration 단계에서 제외 (alpha 정리 후 개별 처리)


@reg("rug_oval", 6, 4)
def build_rug(root):
    outer = rcyl("outer", 0.50, 0.025, (0, 0, 0.012), create_material(PAL["sage"]), root)
    outer.scale = (1.5, 1.0, 1.0)
    inner = rcyl("inner", 0.42, 0.032, (0, 0, 0.016), create_material(PAL["cream"]), root)
    inner.scale = (1.5, 1.0, 1.0)


# ================================================================ 캐릭터
def build_char(root):
    skin = create_material(PAL["skin"]); hair = create_material(PAL["hair"])
    knit = create_material(PAL["knit"]); pants = create_material(PAL["pants"])
    shoe = create_material(PAL["shoe"]); eye = create_material(PAL["eye"])

    rsph("c_body", 0.17, (0, 0, 0.28), knit, root, scale=(1.0, 0.92, 1.12))
    rsph("c_hips", 0.14, (0, 0, 0.14), pants, root, scale=(1.0, 0.9, 0.75))
    rsph("c_head", 0.22, (0, 0.01, 0.58), skin, root)
    rsph("c_hair_cap", 0.235, (0, -0.01, 0.60), hair, root, scale=(1.0,1.0,0.94))
    rsph("c_hair_back", 0.185, (0, -0.12, 0.58), hair, root, scale=(1.3,0.85,1.15))
    rsph("c_hair_bun", 0.10, (0, -0.15, 0.78), hair, root)
    rbox("c_fringe", (0.34, 0.09, 0.10), (0, 0.17, 0.66), hair, root, bevel=0.035,
         rot=(math.radians(15), 0, 0))
    for sx, nm in [(-1,"l"),(1,"r")]:
        rsph(f"c_eye_{nm}", 0.062, (sx*0.072, 0.185, 0.60), eye, root)
        rsph(f"c_hi_{nm}", 0.022, (sx*0.085, 0.210, 0.617), create_material(PAL["white"]), root)
        rsph(f"c_blush_{nm}", 0.038, (sx*0.14, 0.15, 0.565),
             create_material((0.92,0.62,0.55)), root, scale=(1.1,0.5,0.7))
    for sx, nm in [(-1,"l"),(1,"r")]:
        rbox(f"c_arm_{nm}", (0.055,0.055,0.15), (sx*0.185, 0, 0.26), knit, root, bevel=0.028)
        rsph(f"c_hand_{nm}", 0.036, (sx*0.185, 0.01, 0.175), skin, root)
        rbox(f"c_leg_{nm}", (0.07,0.06,0.11), (sx*0.065, 0, 0.065), pants, root, bevel=0.024)
        rbox(f"c_shoe_{nm}", (0.088,0.13,0.052), (sx*0.065, 0.025, 0.028), shoe, root, bevel=0.024)


# ================================================================ 후처리
def clean_alpha(png_path, threshold=8):
    """alpha 노이즈 정리: < threshold → 0, > threshold → 255, 경계 부드럽게"""
    img = Image.open(png_path).convert("RGBA")
    a = img.split()[3]
    # 이진화
    binary = a.point(lambda v: 255 if v > threshold else 0)
    # 경계 살짝 부드럽게
    smoothed = binary.filter(ImageFilter.GaussianBlur(1.0))
    # 다시 이진화 (soft edge 유지하면서 노이즈 제거)
    final = smoothed.point(lambda v: 255 if v > 128 else 0)
    # 원본 alpha의 밝기는 유지하면서 binary mask로 클리핑
    img.putalpha(final)
    img.save(png_path)


def trim_to_bbox(png_path):
    """bbox로 crop하고 새 anchor 위치 반환"""
    img = Image.open(png_path)
    bbox = img.split()[3].getbbox()
    if bbox:
        # 원본 중심 (footprint center)의 새로운 위치 계산
        old_cx = img.width / 2
        old_cy = img.height / 2
        img = img.crop(bbox)
        new_cx = old_cx - bbox[0]
        new_cy = old_cy - bbox[1]
        img.save(png_path)
        return (new_cx, new_cy), (img.width, img.height)
    return (img.width/2, img.height/2), (img.width, img.height)


# ================================================================ 메인
def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(STAGE, exist_ok=True)

    all_meta = {}

    for item_id, fp_w, fp_h, builder in FURNITURE + [("char", 2, 2, build_char)]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        root = bpy.data.objects.new("Root", None)
        bpy.context.scene.collection.objects.link(root)
        builder(root)
        bpy.context.view_layer.update()

        scene = bpy.context.scene
        focus = Vector((0, 0, 0.35))
        cam = apply_camera(scene, focus=focus)
        apply_lighting(scene)
        apply_render_settings(scene, transparent=True)

        # footprint center (원점)의 이미지 내 픽셀 위치
        from bpy_extras.object_utils import world_to_camera_view
        res = SPEC["resolution"]
        v = world_to_camera_view(scene, cam, Vector((0, 0, 0)))
        origin_px = (v.x * res, (1.0 - v.y) * res)  # 이미지 중앙 부근

        all_meta[item_id] = {
            "footprint_cells": [fp_w, fp_h],
            "real_size_m": [fp_w * CELL, fp_h * CELL],
            "origin_px_raw": [round(origin_px[0], 1), round(origin_px[1], 1)],
            "rotations": {}
        }

        for rot in [0, 90, 180, 270]:
            root.rotation_euler = (0, 0, math.radians(rot))
            bpy.context.view_layer.update()

            # 렌더
            fname = f"{item_id}_{rot}.png"
            raw_path = os.path.join(STAGE, fname)
            scene.render.filepath = raw_path
            bpy.ops.render.render(write_still=True)

            # 원시 PNG 저장 (후처리는 별도 스크립트)
            os.rename(raw_path, os.path.join(OUT_DIR, fname))
            all_meta[item_id]["rotations"][str(rot)] = {
                "file": fname,
                "needs_postprocess": True
            }

            print(f"EXPORT_RAW {item_id}_{rot}")

        # 원점 픽셀 위치는 rotation 무관 (Root가 원점이므로)
        all_meta[item_id]["origin_px"] = all_meta[item_id]["origin_px_raw"]

    # metadata 저장
    meta_path = os.path.join(OUT_DIR, "anchors.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(all_meta, f, ensure_ascii=False, indent=2)
    print("EXPORT_ALL_DONE", meta_path)


if __name__ == "__main__":
    main()
