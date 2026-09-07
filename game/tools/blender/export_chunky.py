# -*- coding: utf-8 -*-
"""
청키 가구 + 강화 캐릭터 glTF 내보내기 (벤치마크 승인 레시피 기반)
- 침대: 두꺼운 플랫폼(다리 없음) + 둥근 헤드보드 + 통통한 베개/듀벳
- 소파: 둥근 쿠션 + 원통 팔걸이 + 던지면
- 의자/책상/램프/식물: 청크 개선
- 캐릭터: 눈 2배 + 하이라이트 + 볼터치 + 헤어 볼륨 1.3배
"""
import bpy
import math
import os
from mathutils import Vector

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "models"))

PAL = {
    "wood_l": (0.90, 0.63, 0.32), "wood_d": (0.58, 0.33, 0.15),
    "cream": (0.97, 0.90, 0.75), "linen": (0.96, 0.92, 0.85),
    "sage": (0.48, 0.70, 0.32), "sage_deep": (0.42, 0.62, 0.28),
    "plant": (0.12, 0.48, 0.20), "terra": (0.92, 0.40, 0.25),
    "mustard": (0.90, 0.72, 0.35), "brass": (0.72, 0.55, 0.35),
    "skin": (0.98, 0.85, 0.74), "hair": (0.22, 0.16, 0.12),
    "top": (0.94, 0.76, 0.56), "bottom": (0.38, 0.42, 0.52),
    "shoe": (0.35, 0.28, 0.24), "eye": (0.13, 0.11, 0.10),
    "white": (0.98, 0.97, 0.95),
}


def _mat(color, rough=0.65):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Specular IOR Level"].default_value = 0.15
    return m


def _emit(color, strength, base_mat):
    b = base_mat.node_tree.nodes.get("Principled BSDF")
    b.inputs["Emission Color"].default_value = (*color, 1)
    b.inputs["Emission Strength"].default_value = strength
    return base_mat


def rbox(name, size, loc, m, parent=None, bevel=0.04, sub=2, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    if sub:
        s = o.modifiers.new("s", "SUBSURF"); s.levels = sub
    if bevel:
        b = o.modifiers.new("b", "BEVEL"); b.width = bevel; b.segments = 5
    for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(m)
    if parent: o.parent = parent
    return o


def rcyl(name, r, depth, loc, m, parent=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=28)
    o = bpy.context.active_object
    o.name = name
    b = o.modifiers.new("b", "BEVEL"); b.width = min(r, depth) * 0.25; b.segments = 4
    for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(m)
    if parent: o.parent = parent
    return o


def rsph(name, r, loc, m, parent=None, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=28, ring_count=18)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(m)
    if parent: o.parent = parent
    return o


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def export(name):
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"))
    print("CHUNKY", name, "ok")


# ================================================================ 침대
def build_bed():
    clear()
    m_wood = _mat(PAL["wood_l"]); m_wood_d = _mat(PAL["wood_d"])
    sage = _mat(PAL["sage"], 0.95); sage_deep = _mat(PAL["sage_deep"], 0.95)
    linen = _mat(PAL["linen"], 0.95); terra = _mat(PAL["terra"], 0.95)
    W, L = 1.05, 2.05
    # 두꺼운 플랫폼 (다리 없음!)
    rbox("bed_plinth", (W, L, 0.22), (0, 0, 0.11), m_wood_d, bevel=0.04)
    # 둥근 헤드보드
    rbox("bed_head", (W + 0.06, 0.14, 0.72), (0, -L/2 + 0.07, 0.46), m_wood, bevel=0.06)
    # 통통한 매트리스
    rbox("bed_mattress", (W - 0.08, L - 0.08, 0.28), (0, 0.01, 0.36), linen, bevel=0.10)
    # 통통한 베개 2개
    for sx in [-1, 1]:
        rbox(f"pillow_{sx}", (W/2 - 0.06, 0.44, 0.18), (sx * W/4, -L/2 + 0.42, 0.59), linen,
             bevel=0.08, rot=(math.radians(-8), 0, 0))
    # 진한 세이지 듀벳 (두껍고 부드럽게)
    rbox("bed_duvet", (W + 0.02, L * 0.60, 0.18), (0, L * 0.20, 0.56), sage_deep, bevel=0.09)
    # 테라코타 쿠션
    rbox("bed_cushion", (0.36, 0.36, 0.14), (W/5, L * 0.02, 0.68), terra, bevel=0.07,
         rot=(0, 0, math.radians(-10)))
    export("bed_single")


# ================================================================ 소파
def build_sofa():
    clear()
    cream = _mat(PAL["cream"], 0.95); terra = _mat(PAL["terra"], 0.95)
    mustard = _mat(PAL["mustard"], 0.95)
    W, D = 1.50, 0.78
    rbox("sofa_base", (W, D, 0.22), (0, 0, 0.17), cream, bevel=0.06)
    # 원통형 팔걸이 (둥근!)
    for sx in [-1, 1]:
        rcyl(f"arm_{sx}", 0.12, D, (sx * (W/2 - 0.09), 0, 0.42), cream)
    # 둥글고 통통한 좌석 쿠션 3개
    for i, sx in enumerate([-W/6, 0, W/6]):
        rbox(f"seat_{i}", (W/3 - 0.03, D - 0.12, 0.15), (sx, 0.02, 0.36), cream, bevel=0.07)
    # 둥글고 통통한 등받이 쿠션 3개
    for i, sx in enumerate([-W/6, 0, W/6]):
        rbox(f"back_{i}", (W/3 - 0.04, 0.16, 0.32), (sx, -D/2 + 0.11, 0.50), cream,
             bevel=0.07, rot=(math.radians(-6), 0, 0))
    # 던지면 쿠션 (테라코타, 둥근)
    rbox("throw", (0.32, 0.32, 0.14), (W/5, 0.04, 0.55), terra, bevel=0.07,
         rot=(0, 0, math.radians(-12)))
    # 담요 (머스터드)
    rbox("blanket", (0.10, D * 0.6, 0.22), (-W/2 + 0.09, -0.05, 0.55), mustard, bevel=0.04)
    export("sofa_two")


# ================================================================ 의자
def build_chair():
    clear()
    m_wood = _mat(PAL["wood_l"]); m_wood_d = _mat(PAL["wood_d"])
    S, H = 0.50, 0.42
    rbox("seat", (S, S, 0.06), (0, 0, H), m_wood, bevel=0.035)
    rbox("cushion", (S - 0.06, S - 0.06, 0.06), (0, 0, H + 0.05), _mat(PAL["terra"], 0.95), bevel=0.03)
    for x in [-1, 1]:
        for y in [-1, 1]:
            rcyl(f"leg_{x}{y}", 0.028, H, (x*(S/2-0.07), y*(S/2-0.07), H/2), m_wood_d)
    rbox("back", (S, 0.07, 0.48), (0, -S/2 + 0.06, H + 0.26), m_wood, bevel=0.04)
    export("chair_basic")


# ================================================================ 책상
def build_desk():
    clear()
    m_wood = _mat(PAL["wood_l"]); m_wood_d = _mat(PAL["wood_d"])
    W, D, H = 1.25, 0.55, 0.72
    rbox("top", (W, D, 0.05), (0, 0, H), m_wood, bevel=0.025)
    for x in [-W/2+0.08, W/2-0.08]:
        for y in [-D/2+0.07, D/2-0.07]:
            rcyl(f"leg_{x:.0f}{y:.0f}", 0.03, H, (x, y, H/2), m_wood_d)
    # 서랍
    rbox("drawer", (0.36, D-0.04, 0.38), (W/2-0.22, 0, H-0.21), m_wood, bevel=0.02)
    rbox("drawer_face", (0.02, D-0.10, 0.14), (W/2-0.035, 0, H-0.10), m_wood_d, bevel=0.008)
    # 모니터
    dark = _mat((0.24, 0.23, 0.22), 0.4)
    rbox("mon_frame", (0.48, 0.05, 0.32), (0, -D/2+0.14, H+0.35), dark, bevel=0.012)
    rbox("mon_screen", (0.43, 0.012, 0.27), (0, -D/2+0.17, H+0.35),
         _emit((0.55, 0.70, 0.75), 0.3, _mat((0.60, 0.75, 0.78), 0.1)), bevel=0.006)
    rcyl("mon_stand", 0.022, 0.13, (0, -D/2+0.14, H+0.13), dark)
    # 소품: 머그 + 책
    rcyl("mug", 0.035, 0.075, (W/2-0.42, 0.03, H+0.065), _mat(PAL["terra"]))
    rbox("book1", (0.16, 0.11, 0.03), (-W/2+0.18, 0, H+0.028), _mat(PAL["sage"]), bevel=0.006,
         rot=(0, 0, math.radians(10)))
    export("desk_table")


# ================================================================ 램프
def build_lamp():
    clear()
    brass = _mat(PAL["brass"], 0.5)
    rcyl("base", 0.14, 0.04, (0, 0, 0.02), brass)
    rcyl("pole", 0.018, 1.05, (0, 0, 0.55), brass)
    shade = rcyl("shade", 0.16, 0.26, (0, 0, 1.13), _mat(PAL["cream"], 0.9))
    shade.scale = (1.2, 1.2, 1.0)
    rcyl("glow", 0.11, 0.02, (0, 0, 1.01),
         _emit((1.0, 0.88, 0.62), 3.0, _mat((1, 0.95, 0.85))))
    export("floor_lamp")


# ================================================================ 식물
def build_plant():
    clear()
    pot = _mat((0.83, 0.50, 0.36), 0.75)
    leaf = _mat(PAL["plant"], 0.6)
    leaf_d = _mat((0.08, 0.38, 0.16), 0.6)
    rcyl("pot", 0.15, 0.28, (0, 0, 0.14), pot)
    rcyl("rim", 0.18, 0.05, (0, 0, 0.29), pot)
    rcyl("soil", 0.14, 0.02, (0, 0, 0.305), _mat((0.30, 0.22, 0.16), 0.95))
    # 크고 굵은 몬스테라 잎 (1.5배 증가)
    for i, (ang, h) in enumerate([(0, 0.55), (1.1, 0.75), (2.3, 0.60), (3.5, 0.80), (4.7, 0.55), (5.6, 0.45)]):
        leaf_s = rsph(f"leaf_{i}", 0.20, (math.cos(ang)*0.12, math.sin(ang)*0.09, 0.36 + h*0.55), leaf if i%2 else leaf_d)
        leaf_s.scale = (0.40, 1.5, 0.60)
        leaf_s.rotation_euler = (0, 0.08, ang)
    export("plant_monstera")


# ================================================================ 캐릭터 (강화)
def build_char():
    clear()
    skin = _mat(PAL["skin"], 0.55); hair = _mat(PAL["hair"], 0.6)
    top = _mat(PAL["top"], 0.95); bottom = _mat(PAL["bottom"], 0.9)
    shoe = _mat(PAL["shoe"], 0.6); eye_m = _mat(PAL["eye"], 0.2)
    white_m = _mat(PAL["white"], 0.1)
    blush_m = _mat((0.97, 0.55, 0.48), 0.85)

    # 루트 (애니메이션용)
    root = bpy.data.objects.new("Root", None)
    bpy.context.scene.collection.objects.link(root)

    hip = bpy.data.objects.new("hip", None); hip.location = (0, 0, 0.34); hip.parent = root
    bpy.context.scene.collection.objects.link(hip)
    rsph("c_hips", 0.15, (0, 0, -0.02), bottom, hip, scale=(1.0, 0.9, 0.8))
    torso = bpy.data.objects.new("torso", None); torso.location = (0, 0, 0.06); torso.parent = hip
    bpy.context.scene.collection.objects.link(torso)
    rsph("c_body", 0.18, (0, 0.004, 0.10), top, torso, scale=(1.0, 0.92, 1.15))
    head = bpy.data.objects.new("head", None); head.location = (0, 0.01, 0.28); head.parent = torso
    bpy.context.scene.collection.objects.link(head)

    # 헤더 (1.3배 볼륨!)
    rsph("c_head", 0.22, (0, 0, 0.10), skin, head)
    rsph("c_hair_cap", 0.235, (0, -0.012, 0.115), hair, head, scale=(1.0, 1.0, 0.94))
    rsph("c_hair_back", 0.19, (0, -0.12, 0.10), hair, head, scale=(1.35, 0.85, 1.2))
    rsph("c_hair_bun", 0.12, (0, -0.16, 0.32), hair, head)
    rbox("c_fringe", (0.36, 0.10, 0.11), (0, 0.17, 0.15), hair, head, bevel=0.04,
         rot=(math.radians(16), 0, 0))

    # 눈 (2배 크기!) + 하이라이트 (2배)
    for sx, nm in [(-1, "l"), (1, "r")]:
        rsph(f"c_eye_{nm}", 0.075, (sx * 0.075, 0.185, 0.115), eye_m, head)
        rsph(f"c_hi_{nm}", 0.028, (sx * 0.088, 0.215, 0.135), white_m, head)  # 큰 하이라이트
        rsph(f"c_blush_{nm}", 0.045, (sx * 0.145, 0.15, 0.08), blush_m, head, scale=(1.1, 0.5, 0.7))
    rsph("c_mouth", 0.025, (0, 0.207, 0.03), _mat((0.75, 0.42, 0.38), 0.6), head, scale=(1.4, 0.55, 0.8))

    # 팔/다리
    for sx, nm in [(-1, "l"), (1, "r")]:
        sh = bpy.data.objects.new(f"sh_{nm}", None); sh.location = (sx * 0.195, 0, 0.14); sh.parent = torso
        bpy.context.scene.collection.objects.link(sh)
        rbox(f"c_arm_{nm}", (0.058, 0.058, 0.16), (0, 0, -0.075), top, sh, bevel=0.03)
        rsph(f"c_hand_{nm}", 0.038, (0, 0.01, -0.165), skin, sh)
        hp = bpy.data.objects.new(f"hp_{nm}", None); hp.location = (sx * 0.072, 0, -0.20); hp.parent = hip
        bpy.context.scene.collection.objects.link(hp)
        rbox(f"c_leg_{nm}", (0.075, 0.065, 0.13), (0, 0, 0.025), bottom, hp, bevel=0.026)
        rbox(f"c_shoe_{nm}", (0.095, 0.14, 0.058), (0, 0.030, -0.105), shoe, hp, bevel=0.026)

    export("char")


def main():
    os.makedirs(OUT, exist_ok=True)
    build_bed()
    build_sofa()
    build_chair()
    build_desk()
    build_lamp()
    build_plant()
    build_char()
    print("CHUNKY_ALL_DONE")


if __name__ == "__main__":
    main()
