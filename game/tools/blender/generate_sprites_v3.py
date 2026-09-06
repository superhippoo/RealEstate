# -*- coding: utf-8 -*-
"""
스프라이트 생성기 v3 — 벤치마크 승인 레시피 이식
"2D Isometric Dollhouse / chunky rounded / flat color / soft GI / SD character"
- 카메라/캘리브레이션/flop/manifest: v2 파이프라인 유지 (30도/315도, 이후 수평반전)
- 재질/조명/비율: benchmark_scene.py 레시피
실행: blender -b --factory-startup -P generate_sprites_v3.py [-- --only <id>]
"""
import bpy
import json
import math
import os
import sys
from mathutils import Vector

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output"))
RES = 1024
SAMPLES = 96

ONLY = None
argv = sys.argv
if "--" in argv:
    rest = argv[argv.index("--") + 1:]
    for i, a in enumerate(rest):
        if a == "--only" and i + 1 < len(rest):
            ONLY = rest[i + 1]

PAL = {
    "wood":    (0.820, 0.540, 0.310),
    "wood_l":  (0.850, 0.610, 0.380),
    "wood_d":  (0.610, 0.380, 0.215),
    "cream":   (0.970, 0.900, 0.780),
    "linen":   (0.960, 0.920, 0.850),
    "sage":    (0.560, 0.660, 0.420),
    "white":   (0.975, 0.960, 0.930),
    "charcoal": (0.290, 0.265, 0.240),
    "terracotta": (0.860, 0.470, 0.340),
    "plant":   (0.180, 0.420, 0.240),
    "pot":     (0.830, 0.500, 0.360),
    "skin":    (0.980, 0.850, 0.740),
    "hair":    (0.220, 0.160, 0.120),
    "top":     (0.940, 0.760, 0.560),
    "bottom":  (0.380, 0.420, 0.520),
}


# ---------------------------------------------------------------- 재질 (평색 스타일라이즈드)
def flat(color, rough=0.62):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Specular IOR Level"].default_value = 0.12
    return m


def wood(color, rough=0.55):
    m = flat(color, rough)
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    rgb = nt.nodes.new("ShaderNodeRGB")
    rgb.outputs[0].default_value = (*color, 1.0)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 6.0
    noise.inputs["Detail"].default_value = 2.0
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (1.0, 5.0, 1.0)
    coord = nt.nodes.new("ShaderNodeTexCoord")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.45
    ramp.color_ramp.elements[1].position = 0.58
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 0.12
    nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(rgb.outputs[0], mix.inputs["Color1"])
    nt.links.new(ramp.outputs["Color"], mix.inputs["Color2"])
    nt.links.new(mix.outputs["Color"], b.inputs["Base Color"])
    return m


def emit(color, strength, base):
    b = base.node_tree.nodes.get("Principled BSDF")
    b.inputs["Emission Color"].default_value = (*color, 1)
    b.inputs["Emission Strength"].default_value = strength
    return base


# ---------------------------------------------------------------- 청키 지오메트리 유틸
def rbox(name, size, loc, m, root, bevel=0.03, sub=2, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    if sub:
        s = o.modifiers.new("s", "SUBSURF")
        s.levels = sub
    b = o.modifiers.new("b", "BEVEL")
    b.width = bevel
    b.segments = 5
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    parent(o, root)
    return o


def rcyl(name, r, depth, loc, m, root, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=28)
    o = bpy.context.active_object
    o.name = name
    b = o.modifiers.new("b", "BEVEL")
    b.width = min(r, depth) * 0.25
    b.segments = 4
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    parent(o, root)
    return o


def rsph(name, r, loc, m, root, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=28, ring_count=18)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    parent(o, root)
    return o


def parent(o, root):
    o.parent = root
    o.matrix_parent_inverse = root.matrix_world.inverted()


# ---------------------------------------------------------------- 가구 (청키, 벤치마크 레시피)
def build_bed(root):
    W, L = 1.05, 2.05   # 4x8 셀
    m_wood = wood(PAL["wood_l"])
    m_wood_d = wood(PAL["wood_d"])
    sage = flat(PAL["sage"], 0.95)
    linen = flat(PAL["linen"], 0.95)
    rbox("bed_plinth", (W, L, 0.20), (0, 0, 0.10), m_wood_d, root, bevel=0.035)
    rbox("bed_head", (W + 0.06, 0.14, 0.68), (0, -L / 2 + 0.07, 0.44), m_wood, root, bevel=0.06)
    rbox("bed_mattress", (W - 0.10, L - 0.10, 0.24), (0, 0.01, 0.34), linen, root, bevel=0.09)
    rbox("bed_pillow1", (W / 2 - 0.08, 0.40, 0.15), (-W / 4 + 0.01, -L / 2 + 0.36, 0.55), linen, root,
         bevel=0.07, rot=(math.radians(-10), 0, 0))
    rbox("bed_pillow2", (W / 2 - 0.08, 0.40, 0.15), (W / 4 - 0.01, -L / 2 + 0.36, 0.55), linen, root,
         bevel=0.07, rot=(math.radians(-10), 0, 0))
    rbox("bed_duvet", (W + 0.02, L * 0.58, 0.15), (0, L * 0.20, 0.56), sage, root, bevel=0.08)
    rbox("bed_cushion", (0.36, 0.36, 0.13), (W / 5, L * 0.02, 0.65), flat(PAL["terracotta"], 0.95), root,
         bevel=0.07, rot=(0, 0, math.radians(-10)))


def build_sofa(root):
    W, D = 1.50, 0.78   # 6x3 셀
    cream = flat(PAL["cream"], 0.95)
    rbox("sofa_base", (W, D, 0.20), (0, 0, 0.16), cream, root, bevel=0.05)
    rbox("sofa_plinth", (W - 0.12, D - 0.12, 0.10), (0, 0, 0.05), wood(PAL["wood_d"]), root, bevel=0.025)
    for i, sx in enumerate((-W / 6 - 0.015, 0.0, W / 6 + 0.015)):
        rbox("sofa_seat%d" % i, (W / 3 - 0.04, D - 0.14, 0.13), (sx, 0.02, 0.33), cream, root, bevel=0.06)
        rbox("sofa_back%d" % i, (W / 3 - 0.05, 0.15, 0.28), (sx, -D / 2 + 0.10, 0.45), cream, root,
             bevel=0.06, rot=(math.radians(-6), 0, 0))
    rbox("sofa_arm_l", (0.16, D, 0.26), (-W / 2 + 0.09, 0, 0.39), cream, root, bevel=0.06)
    rbox("sofa_arm_r", (0.16, D, 0.26), (W / 2 - 0.09, 0, 0.39), cream, root, bevel=0.06)
    rbox("sofa_throw", (0.32, 0.32, 0.12), (W / 5, 0.04, 0.50), flat(PAL["terracotta"], 0.95), root,
         bevel=0.06, rot=(0, 0, math.radians(-12)))


def build_desk(root):
    W, D, H = 1.25, 0.55, 0.72   # 5x2 셀
    m_wood = wood(PAL["wood_l"])
    m_wood_d = wood(PAL["wood_d"])
    rbox("desk_top", (W, D, 0.06), (0, 0, H), m_wood, root, bevel=0.025)
    for x in (-W / 2 + 0.08, W / 2 - 0.08):
        for y in (-D / 2 + 0.07, D / 2 - 0.07):
            rcyl("desk_leg", 0.030, H, (x, y, H / 2), m_wood_d, root)
    rbox("desk_drawer", (0.36, D - 0.04, 0.36), (W / 2 - 0.22, 0, H - 0.20), m_wood, root, bevel=0.02)
    rbox("desk_dface1", (0.02, 0.30, 0.14), (W / 2 - 0.035, 0, H - 0.10), m_wood_d, root, bevel=0.008)
    rbox("desk_dface2", (0.02, 0.30, 0.14), (W / 2 - 0.035, 0, H - 0.28), m_wood_d, root, bevel=0.008)
    # 청키 모니터 + 소품
    dark = flat(PAL["charcoal"], 0.4)
    rbox("mon_frame", (0.48, 0.05, 0.32), (0, -D / 2 + 0.14, H + 0.34), dark, root, bevel=0.012)
    emit((0.55, 0.70, 0.75), 0.35, flat((0.60, 0.75, 0.78), 0.1))
    screen = rbox("mon_screen", (0.43, 0.012, 0.27), (0, -D / 2 + 0.165, H + 0.34),
                  emit((0.55, 0.70, 0.75), 0.35, flat((0.60, 0.75, 0.78), 0.1)), root, bevel=0.006)
    rcyl("mon_stand", 0.022, 0.13, (0, -D / 2 + 0.14, H + 0.13), dark, root)
    rbox("mon_foot", (0.18, 0.11, 0.02), (0, -D / 2 + 0.14, H + 0.055), dark, root, bevel=0.008)
    rcyl("desk_mug", 0.038, 0.09, (W / 2 - 0.45, 0.03, H + 0.075), flat(PAL["terracotta"]), root)
    rbox("desk_book", (0.17, 0.12, 0.035), (-W / 2 + 0.18, 0.0, H + 0.03), flat(PAL["sage"]), root,
         bevel=0.008, rot=(0, 0, math.radians(10)))


def build_chair(root):
    S, H = 0.50, 0.42   # 2x2 셀
    m_wood = wood(PAL["wood"])
    m_wood_d = wood(PAL["wood_d"])
    rbox("chair_seat", (S - 0.03, S - 0.03, 0.06), (0, 0, H), m_wood, root, bevel=0.028)
    rbox("chair_cushion", (S - 0.09, S - 0.09, 0.05), (0, 0.005, H + 0.05), flat(PAL["terracotta"], 0.95),
         root, bevel=0.024)
    for x in (-1, 1):
        for y in (-1, 1):
            rcyl("chair_leg", 0.026, H, (x * (S / 2 - 0.07), y * (S / 2 - 0.07), H / 2), m_wood_d, root)
    rbox("chair_back", (S - 0.03, 0.06, 0.44), (0, -S / 2 + 0.06, H + 0.24), m_wood, root, bevel=0.03)


def build_tv(root):
    W, D = 1.00, 0.50   # 4x2 셀
    m_wood = wood(PAL["wood"])
    m_wood_d = wood(PAL["wood_d"])
    rbox("tv_console", (W, D, 0.30), (0, 0, 0.20), m_wood, root, bevel=0.028)
    rbox("tv_plinth", (W - 0.14, D - 0.14, 0.08), (0, 0, 0.04), m_wood_d, root, bevel=0.02)
    for i in range(2):
        rbox("tv_door%d" % i, (W / 2 - 0.07, 0.02, 0.22), ((i - 0.5) * (W / 2 + 0.006), D / 2, 0.20),
             m_wood_d, root, bevel=0.012)
    dark = flat((0.24, 0.23, 0.22), 0.35)
    rbox("tv_panel", (W - 0.14, 0.06, 0.56), (0, 0, 0.68), dark, root, bevel=0.014)
    rbox("tv_screen", (W - 0.24, 0.014, 0.48), (0, 0.034, 0.68),
          emit((0.45, 0.60, 0.65), 0.35, flat((0.50, 0.65, 0.70), 0.08)), root, bevel=0.008)
    rcyl("tv_pot", 0.036, 0.07, (-W / 2 + 0.14, 0.02, 0.385), flat(PAL["pot"]), root)
    rsph("tv_plant", 0.05, (-W / 2 + 0.14, 0.02, 0.455), flat(PAL["plant"]), root)


def build_rug(root):
    o = rcyl("rug_outer", 0.50, 0.035, (0, 0, 0.028), flat(PAL["sage"], 0.98), root)
    o.scale = (1.5, 1.0, 1.0)
    i = rcyl("rug_inner", 0.415, 0.042, (0, 0, 0.034), flat(PAL["cream"], 0.98), root)
    i.scale = (1.5, 1.0, 1.0)


def build_plant(root):
    rcyl("plant_pot", 0.16, 0.28, (0, 0, 0.14), flat(PAL["pot"], 0.75), root)
    rcyl("plant_rim", 0.19, 0.06, (0, 0, 0.29), flat(PAL["pot"], 0.75), root)
    rcyl("plant_soil", 0.14, 0.02, (0, 0, 0.305), flat((0.30, 0.22, 0.16), 0.95), root)
    for i, (ang, h) in enumerate([(0.0, 0.5), (1.1, 0.7), (2.3, 0.55), (3.5, 0.75), (4.7, 0.5), (5.6, 0.4)]):
        leaf = rsph("pleaf%d" % i, 0.15, (math.cos(ang) * 0.09, math.sin(ang) * 0.09, 0.36 + h * 0.5),
                    flat(PAL["plant"], 0.6), root)
        leaf.scale = (0.42, 1.5, 0.62)
        leaf.rotation_euler = (0.0, 0.10, ang)


def build_floor_lamp(root):
    brass = flat((0.62, 0.44, 0.30), 0.5)
    rcyl("lamp_base", 0.15, 0.05, (0, 0, 0.025), brass, root)
    rcyl("lamp_pole", 0.021, 1.02, (0, 0, 0.54), brass, root)
    shade = rcyl("lamp_shade", 0.16, 0.25, (0, 0, 1.09), flat(PAL["cream"], 0.9), root)
    shade.scale = (1.15, 1.15, 1.0)
    rcyl("lamp_glow", 0.11, 0.02, (0, 0, 0.985), emit((1.0, 0.88, 0.62), 3.0, flat((1, 0.95, 0.85))), root)


def build_side_table(root):
    m_wood = wood(PAL["wood"])
    m_wood_d = wood(PAL["wood_d"])
    rcyl("st_top", 0.24, 0.045, (0, 0, 0.44), m_wood, root)
    for i in range(3):
        ang = i * 2.094
        rcyl("st_leg", 0.022, 0.44, (math.cos(ang) * 0.14, math.sin(ang) * 0.14, 0.22), m_wood_d, root)
    rcyl("st_cup", 0.035, 0.085, (0.06, 0.02, 0.505), flat(PAL["terracotta"]), root)
    rbox("st_book", (0.15, 0.10, 0.03), (-0.07, -0.03, 0.478), flat(PAL["sage"]), root,
         bevel=0.006, rot=(0, 0, math.radians(20)))


def build_picture(root):
    m_wood_d = wood(PAL["wood_d"])
    rbox("pic_frame", (0.44, 0.54, 0.04), (0, 0, 1.18), m_wood_d, root, bevel=0.018)
    rbox("pic_canvas", (0.38, 0.48, 0.014), (0, 0.020, 1.18), flat((0.965, 0.95, 0.91), 0.85), root, bevel=0.004)
    rbox("pic_art1", (0.14, 0.20, 0.008), (-0.07, 0.030, 1.23), flat(PAL["sage"]), root, bevel=0.004)
    rbox("pic_art2", (0.10, 0.13, 0.008), (0.08, 0.030, 1.13), flat(PAL["terracotta"]), root, bevel=0.004)


def build_wall_shelf(root):
    rbox("shelf_board", (1.00, 0.19, 0.05), (0, 0, 1.12), wood(PAL["wood"]), root, bevel=0.014)
    for x in (-0.42, 0.42):
        rbox("shelf_bracket", (0.035, 0.03, 0.11), (x, 0.0, 1.055), wood(PAL["wood_d"]), root, bevel=0.008)
    rbox("shelf_b1", (0.032, 0.13, 0.16), (-0.30, 0, 1.225), flat(PAL["sage"]), root, bevel=0.006)
    rbox("shelf_b2", (0.032, 0.11, 0.14), (-0.25, 0.004, 1.215), flat((0.90, 0.75, 0.60)), root, bevel=0.006)
    rbox("shelf_frame", (0.13, 0.17, 0.014), (0.10, 0.025, 1.225), wood(PAL["wood_d"]), root,
         bevel=0.006, rot=(0.28, 0, 0))
    rcyl("shelf_pot", 0.040, 0.075, (0.38, 0, 1.18), flat(PAL["pot"]), root)
    rsph("shelf_plant", 0.05, (0.38, 0, 1.245), flat(PAL["plant"]), root)


FURNITURE = {
    "bed_single": build_bed,
    "sofa_two": build_sofa,
    "desk_small": build_desk,
    "chair_basic": build_chair,
    "tv_43": build_tv,
    "rug_oval": build_rug,
    "plant_monstera": build_plant,
    "floor_lamp": build_floor_lamp,
    "side_table": build_side_table,
    "picture_frame": build_picture,
    "wall_shelf": build_wall_shelf,
}


# ---------------------------------------------------------------- SD 캐릭터 v5 (관절)
JOINTS = {}
JOINT_BASE = {}


def joint(name, loc, root):
    j = bpy.data.objects.new(name, None)
    j.empty_display_size = 0.05
    j.location = loc
    j.parent = root
    j.matrix_parent_inverse = root.matrix_world.inverted()
    bpy.context.collection.objects.link(j)
    return j


def build_character(root):
    skin = flat(PAL["skin"], 0.55)
    hair = flat(PAL["hair"], 0.6)
    top = flat(PAL["top"], 0.95)
    bottom = flat(PAL["bottom"], 0.9)
    shoe = flat((0.35, 0.28, 0.24), 0.6)
    eye_m = flat((0.13, 0.11, 0.10), 0.2)

    hip = joint("hip", (0, 0, 0.34), root)
    rsph("c_hips", 0.15, (0, 0, -0.02), bottom, hip, scale=(1.0, 0.9, 0.8))
    torso = joint("torso", (0, 0, 0.06), hip)
    rsph("c_body", 0.175, (0, 0.004, 0.10), top, torso, scale=(1.0, 0.92, 1.15))
    head = joint("head", (0, 0.01, 0.28), torso)
    rsph("c_head", 0.21, (0, 0, 0.10), skin, head)
    rsph("c_hair_cap", 0.222, (0, -0.012, 0.115), hair, head, scale=(1.0, 1.0, 0.94))
    rsph("c_hair_back", 0.17, (0, -0.11, 0.10), hair, head, scale=(1.3, 0.85, 1.2))
    rsph("c_hair_bun", 0.10, (0, -0.14, 0.31), hair, head)
    rbox("c_fringe", (0.33, 0.09, 0.10), (0, 0.165, 0.150), hair, head, bevel=0.035, rot=(math.radians(16), 0, 0))
    for sx, nm in ((-1, "l"), (1, "r")):
        rsph("c_eye_%s" % nm, 0.048, (sx * 0.078, 0.185, 0.115), eye_m, head)
        rsph("c_hi_%s" % nm, 0.014, (sx * 0.090, 0.212, 0.132), flat((1, 1, 1), 0.1), head)
        rsph("c_blush_%s" % nm, 0.032, (sx * 0.140, 0.15, 0.080), flat((0.97, 0.62, 0.55), 0.85), head,
             scale=(1.1, 0.5, 0.7))
    rsph("c_mouth", 0.022, (0, 0.207, 0.030), flat((0.75, 0.42, 0.38), 0.6), head, scale=(1.4, 0.55, 0.8))
    for sx, nm in ((-1, "l"), (1, "r")):
        sh = joint("sh_" + nm, (sx * 0.195, 0, 0.14), torso)
        rbox("c_arm_" + nm, (0.058, 0.058, 0.16), (0, 0, -0.075), top, sh, bevel=0.028)
        rsph("c_hand_" + nm, 0.038, (0, 0.01, -0.165), skin, sh)
        JOINTS["sh_" + nm] = sh
        hp = joint("hp_" + nm, (sx * 0.072, 0, -0.20), hip)
        rbox("c_leg_" + nm, (0.075, 0.065, 0.13), (0, 0, 0.025), bottom, hp, bevel=0.026)
        rbox("c_shoe_" + nm, (0.095, 0.14, 0.058), (0, 0.030, -0.105), shoe, hp, bevel=0.026)
        JOINTS["hp_" + nm] = hp
    JOINTS["hip"] = hip
    JOINTS["torso"] = torso
    JOINTS["head"] = head
    JOINT_BASE.clear()
    for k, j in JOINTS.items():
        JOINT_BASE[k] = j.location.copy()


def reset_pose():
    for k, j in JOINTS.items():
        j.rotation_euler = (0, 0, 0)
        if k in JOINT_BASE:
            j.location = JOINT_BASE[k].copy()


def pose_idle():
    reset_pose()
    JOINTS["sh_l"].rotation_euler = (0.06, 0, 0.10)
    JOINTS["sh_r"].rotation_euler = (0.06, 0, -0.10)


def pose_walk(phase):
    pose_idle()
    s = 0.55 if phase == 0 else -0.55
    JOINTS["hp_l"].rotation_euler = (s, 0, 0)
    JOINTS["hp_r"].rotation_euler = (-s, 0, 0)
    JOINTS["sh_l"].rotation_euler = (-s * 0.7, 0, 0.10)
    JOINTS["sh_r"].rotation_euler = (s * 0.7, 0, -0.10)
    JOINTS["torso"].rotation_euler = (0.05, 0, 0)


def pose_sit_chair():
    reset_pose()
    JOINTS["hip"].location = (0, 0, 0.52)
    for nm in ("l", "r"):
        JOINTS["hp_" + nm].rotation_euler = (math.radians(-80), 0, 0)
    JOINTS["torso"].rotation_euler = (0.08, 0, 0)


def pose_sit_sofa():
    reset_pose()
    JOINTS["hip"].location = (0, 0, 0.46)
    for nm in ("l", "r"):
        JOINTS["hp_" + nm].rotation_euler = (math.radians(-64), 0, 0)
    for nm in ("l", "r"):
        JOINTS["sh_" + nm].rotation_euler = (math.radians(-16), 0, 0.18 if nm == "l" else -0.18)
    JOINTS["torso"].rotation_euler = (-0.05, 0, 0)


def pose_typing():
    pose_sit_chair()
    for nm in ("l", "r"):
        JOINTS["sh_" + nm].rotation_euler = (math.radians(-55), 0, 0.10 if nm == "l" else -0.10)
    JOINTS["head"].rotation_euler = (0.20, 0, 0)


def pose_lie():
    reset_pose()
    JOINTS["hip"].location = (0, 0, 0.58)
    JOINTS["torso"].rotation_euler = (math.radians(90), 0, 0)
    JOINTS["head"].rotation_euler = (math.radians(-12), 0, 0)
    for nm in ("l", "r"):
        JOINTS["sh_" + nm].rotation_euler = (0, 0, 0.55 if nm == "l" else -0.55)


# ---------------------------------------------------------------- 씬 (소프트 GI)
def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = RES
    scene.render.resolution_y = RES
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = 1.15

    key_data = bpy.data.lights.new("Key", "AREA")
    key_data.size = 7.0
    key_data.energy = 160
    key_data.color = (1.0, 0.95, 0.88)
    key = bpy.data.objects.new("Key", key_data)
    key.location = (3.0, -3.2, 4.2)
    key.rotation_euler = (math.radians(62), 0, math.radians(-40))
    scene.collection.objects.link(key)

    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = 9.0
    fill_data.energy = 70
    fill_data.color = (0.92, 0.90, 1.0)
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = (-3.5, 3.0, 3.0)
    fill.rotation_euler = (math.radians(55), 0, math.radians(140))
    scene.collection.objects.link(fill)

    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (1.0, 0.93, 0.87, 1.0)
    bg.inputs["Strength"].default_value = 0.62
    scene.world = world

    cam_data = bpy.data.cameras.new("IsoCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 3.2
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    place_camera(cam, 0.45)

    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, -0.002))
    sc = bpy.context.active_object
    sc.name = "ShadowCatcher"
    sc.is_shadow_catcher = True
    return scene, cam


def place_camera(cam, focus_z):
    d = 10.0
    az = math.radians(315)  # 렌더 후 수평반전(flop)으로 게임 그리드 관례와 일치
    el = math.radians(30.0)
    cam.location = (d * math.cos(el) * math.cos(az), -d * math.cos(el) * math.sin(az), d * math.sin(el) + focus_z)
    direction = Vector((0, 0, focus_z)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def new_root():
    root = bpy.data.objects.new("Root", None)
    bpy.context.scene.collection.objects.link(root)
    return root


def clear_root(root):
    for o in list(root.children):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.objects.remove(root, do_unlink=True)
    JOINTS.clear()


def calibrate_px_per_meter(scene, cam):
    from bpy_extras.object_utils import world_to_camera_view

    def s2p(v):
        return Vector((v.x * RES, (1.0 - v.y) * RES))

    origin = Vector((0, 0, 0))
    px_o = s2p(world_to_camera_view(scene, cam, origin))
    px_x1 = s2p(world_to_camera_view(scene, cam, origin + Vector((1, 0, 0))))
    px_y1 = s2p(world_to_camera_view(scene, cam, origin + Vector((0, 1, 0))))
    return (px_x1 - px_o).length, (px_y1 - px_o).length


def render(scene, fname):
    scene.render.filepath = os.path.join(OUT_DIR, fname)
    bpy.ops.render.render(write_still=True)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    scene, cam = setup_scene()
    ppm_x, ppm_y = calibrate_px_per_meter(scene, cam)
    manifest = {
        "resolution": RES,
        "ortho_scale": 3.2,
        "px_per_meter_x": ppm_x,
        "px_per_meter_y": ppm_y,
        "godot_scale": 286.2167 / ((ppm_x + ppm_y) * 0.5),
        "sprites": {},
    }

    for def_id, builder in FURNITURE.items():
        if ONLY and def_id != ONLY and ONLY != "char":
            continue
        root = new_root()
        builder(root)
        bpy.context.view_layer.update()
        files = []
        for rot in (0, 90, 180, 270):
            root.rotation_euler = (0, 0, math.radians(rot))
            bpy.context.view_layer.update()
            fname = f"{def_id}_{rot}.png"
            render(scene, fname)
            files.append(fname)
        manifest["sprites"][def_id] = {"frames": files, "type": "furniture"}
        clear_root(root)
        if ONLY:
            break

    if not ONLY or ONLY == "char":
        root = new_root()
        build_character(root)
        sets = []
        for d in range(4):
            sets += [(pose_walk, "char_walk_%d_0" % d, d * 90, 0),
                     (pose_walk, "char_walk_%d_1" % d, d * 90, 1),
                     (pose_idle, "char_idle_%d" % d, d * 90, None)]
        sets += [(pose_sit_chair, "char_sit_0", 0, None), (pose_sit_chair, "char_sit_270", 270, None),
                 (pose_sit_sofa, "char_sit_sofa_0", 0, None), (pose_sit_sofa, "char_sit_sofa_270", 270, None),
                 (pose_typing, "char_typing_270", 270, None),
                 (pose_lie, "char_lie_0", 0, None), (pose_lie, "char_lie_180", 180, None)]
        for pose_fn, name, rot, phase in sets:
            pose_fn(phase) if phase is not None else pose_fn()
            root.rotation_euler = (0, 0, math.radians(rot))
            bpy.context.view_layer.update()
            render(scene, name + ".png")
        clear_root(root)
        manifest["sprites"]["char"] = {"type": "character"}

    if not ONLY:
        with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("V3_DONE godot_scale=%.4f" % manifest["godot_scale"])


if __name__ == "__main__":
    main()
