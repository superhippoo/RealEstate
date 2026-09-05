# -*- coding: utf-8 -*-
"""
절차적 아이소메트릭 스프라이트 생성기 v2 — 품질 오버홀
- 베벨/서브서프/프로시저럴 재질(목재 그레인, 패브릭 범프)
- 3점 조명(따뜻한 키 + 창가 필 + 시원한 림) + Filmic + exposure 1.15
- Cycles 96샘플 + denoise, shadow catcher, 투명 배경
- 프리뷰 모드: blender -P generate_sprites_v2.py -- --only bed_single
실행: blender -b --factory-startup -P generate_sprites_v2.py [-- --only <id>]
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

PALETTE = {
    "wood":       (0.847, 0.659, 0.424),
    "wood_mid":   (0.780, 0.590, 0.370),
    "wood_dark":  (0.640, 0.462, 0.262),
    "cream":      (0.949, 0.902, 0.816),
    "cream_deep": (0.910, 0.852, 0.755),
    "sage":       (0.612, 0.686, 0.384),
    "white":      (0.970, 0.965, 0.940),
    "charcoal":   (0.236, 0.222, 0.198),
    "terracotta": (0.851, 0.490, 0.353),
    "mustard":    (0.902, 0.702, 0.322),
    "linen":      (0.918, 0.874, 0.800),
    "skin":       (0.965, 0.830, 0.715),
    "hair":       (0.215, 0.172, 0.140),
    "top":        (0.918, 0.874, 0.800),   # 크림 니트
    "bottom":     (0.360, 0.410, 0.500),   # 네이비 슬랙스
}


# ---------------------------------------------------------------- 재질
def _mat_base(color, rough=0.6):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    return m


def mat_wood(color, scale=18.0, rough=0.45):
    """프로시저럴 목재 그레인: 노이즈를 좌표로 늘여 결 만들기"""
    m = _mat_base(color, rough)
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    rgb = nt.nodes.new("ShaderNodeRGB")
    rgb.outputs[0].default_value = (*color, 1.0)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 6.0
    noise.inputs["Roughness"].default_value = 0.55
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (1.0, 8.0, 1.0)  # 한 축으로 늘임 = 결
    coord = nt.nodes.new("ShaderNodeTexCoord")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0, 0, 0, 1)
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[1].color = (1, 1, 1, 1)
    ramp.color_ramp.elements[1].position = 0.62
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 0.35
    nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(rgb.outputs[0], mix.inputs["Color1"])
    nt.links.new(ramp.outputs["Color"], mix.inputs["Color2"])
    nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    return m


def mat_fabric(color, rough=0.92):
    """패브릭: 노이즈 범프 + 높은 거칠기"""
    m = _mat_base(color, rough)
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 120.0
    noise.inputs["Detail"].default_value = 8.0
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nm.inputs["Strength"].default_value = 0.6
    # 노멀맵 높이 입력 소켓은 버전별 명칭이 달라 탐색해서 연결
    height_in = None
    for inp in nm.inputs:
        if inp.name in ("Height", "Color") and inp.type == "RGBA":
            height_in = inp
            break
    if height_in is not None:
        nt.links.new(noise.outputs["Fac"], height_in)
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def mat_plain(color, rough=0.6):
    return _mat_base(color, rough)


# ---------------------------------------------------------------- 지오메트리 유틸
def _smooth(obj):
    for p in obj.data.polygons:
        p.use_smooth = True


def _bevel(obj, width=0.014, segments=4):
    b = obj.modifiers.new("bevel", "BEVEL")
    b.width = width
    b.segments = segments
    b.harden_normals = True
    return b


def _subsurf(obj, level=2):
    s = obj.modifiers.new("sub", "SUBSURF")
    s.levels = level
    s.render_levels = level
    return s


def rbox(name, size, loc, material, root, bevel=0.018, subsurf=0, rot=(0, 0, 0)):
    """rounded box"""
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    if subsurf:
        _subsurf(o, subsurf)
    if bevel:
        _bevel(o, bevel)
    _smooth(o)
    o.data.materials.append(material)
    _parent(o, root)
    return o


def rcyl(name, r, depth, loc, material, root, rot=(0, 0, 0), bevel=0.012):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=32)
    o = bpy.context.active_object
    o.name = name
    if bevel:
        _bevel(o, bevel, 3)
    _smooth(o)
    o.data.materials.append(material)
    _parent(o, root)
    return o


def rsphere(name, r, loc, material, root, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=32, ring_count=20)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    _subsurf(o, 2)
    _smooth(o)
    o.data.materials.append(material)
    _parent(o, root)
    return o


def _parent(o, root):
    o.parent = root
    o.matrix_parent_inverse = root.matrix_world.inverted()


def leg_set(root, material, positions, r=0.026, h=0.12, taper=True):
    for i, (x, y) in enumerate(positions):
        cyl = rcyl("leg%d" % i, r, h, (x, y, h / 2), material, root)
        if taper:
            cyl.scale = (1.0, 0.82, 1.0)  # 아래로 갈수록 얇은 느낌(근사)


# ---------------------------------------------------------------- 가구 v2
def build_bed(root):
    W, L = 1.0, 2.0
    wood = mat_wood(PALETTE["wood_mid"])
    wood_d = mat_wood(PALETTE["wood_dark"], scale=26.0)
    fabric_cream = mat_fabric(PALETTE["cream"])
    fabric_sage = mat_fabric(PALETTE["sage"])
    # 다리
    leg_set(root, wood_d, [(-W / 2 + 0.07, -L / 2 + 0.07), (W / 2 - 0.07, -L / 2 + 0.07),
                           (-W / 2 + 0.07, L / 2 - 0.07), (W / 2 - 0.07, L / 2 - 0.07)], r=0.028, h=0.16)
    # 프레임
    rbox("frame", (W, L, 0.09), (0, 0, 0.20), wood, root, bevel=0.02)
    # 헤드보드(라운드)
    hb = rbox("headboard", (W - 0.04, 0.09, 0.55), (0, -L / 2 + 0.055, 0.44), wood, root, bevel=0.035, subsurf=2)
    # 매트리스(라운드 + 베벨)
    rbox("mattress", (W - 0.09, L - 0.09, 0.17), (0, 0.01, 0.33), mat_fabric(PALETTE["white"]), root,
         bevel=0.05, subsurf=2)
    # 배개 2개
    rbox("pillow1", (W / 2 - 0.16, 0.34, 0.09), (-W / 4 + 0.01, -L / 2 + 0.33, 0.46), mat_fabric(PALETTE["linen"]), root,
         bevel=0.045, subsurf=2, rot=(math.radians(-8), 0, 0))
    rbox("pillow2", (W / 2 - 0.16, 0.34, 0.09), (W / 4 - 0.01, -L / 2 + 0.33, 0.46), mat_fabric(PALETTE["linen"]), root,
         bevel=0.045, subsurf=2, rot=(math.radians(-8), 0, 0))
    # 듀벳(접힌 이불, 라운드 + 은은한 주름)
    duvet = rbox("duvet", (W - 0.02, L * 0.52, 0.10), (0, L * 0.21, 0.44), fabric_sage, root,
                 bevel=0.05, subsurf=2)
    tex = bpy.data.textures.new("duvet_folds", type="CLOUDS")
    tex.noise_depth = 4
    dis = duvet.modifiers.new("displace", "DISPLACE")
    dis.texture = tex
    dis.strength = 0.018
    # 듀벳 위 데코 쿠션
    rbox("cushion", (0.30, 0.30, 0.09), (-W / 4, L * 0.02, 0.52), mat_fabric(PALETTE["terracotta"]), root,
         bevel=0.05, subsurf=2, rot=(0, 0, math.radians(12)))


def build_sofa(root):
    W, D = 1.5, 0.75
    fabric = mat_fabric(PALETTE["cream_deep"])
    fabric_accent = mat_fabric(PALETTE["terracotta"])
    wood_d = mat_wood(PALETTE["wood_dark"], scale=26.0)
    leg_set(root, wood_d, [(-W / 2 + 0.09, -D / 2 + 0.07), (W / 2 - 0.09, -D / 2 + 0.07),
                           (-W / 2 + 0.09, D / 2 - 0.07), (W / 2 - 0.09, D / 2 - 0.07)], r=0.02, h=0.10)
    rbox("base", (W, D, 0.16), (0, 0, 0.18), fabric, root, bevel=0.035)
    # 좌석 쿠션 3개
    for i, sx in enumerate((-W / 6 - 0.015, 0.0, W / 6 + 0.015)):
        rbox("seat%d" % i, (W / 3 - 0.05, D - 0.16, 0.10), (sx, 0.015, 0.31), fabric, root,
             bevel=0.04, subsurf=2)
    # 등받이 쿠션 3개
    for i, sx in enumerate((-W / 6 - 0.015, 0.0, W / 6 + 0.015)):
        rbox("back%d" % i, (W / 3 - 0.06, 0.13, 0.26), (sx, -D / 2 + 0.10, 0.44), fabric, root,
             bevel=0.04, subsurf=2, rot=(math.radians(-8), 0, 0))
    # 팔걸이(라운드)
    rbox("arm_l", (0.13, D - 0.02, 0.22), (-W / 2 + 0.075, 0, 0.37), fabric, root, bevel=0.045, subsurf=2)
    rbox("arm_r", (0.13, D - 0.02, 0.22), (W / 2 - 0.075, 0, 0.37), fabric, root, bevel=0.045, subsurf=2)
    # 던지면 쿠션(테라코타)
    rbox("throw", (0.34, 0.34, 0.10), (W / 5, 0.03, 0.43), fabric_accent, root,
         bevel=0.045, subsurf=2, rot=(0, 0, math.radians(-14)))
    # 팔걸이에 걸친 담요
    rbox("blanket", (0.05, D * 0.7, 0.24), (W / 2 - 0.075, -0.05, 0.47), mat_fabric(PALETTE["mustard"]), root,
         bevel=0.02, subsurf=2, rot=(0, 0, math.radians(4)))


def build_desk(root):
    W, D, H = 1.25, 0.5, 0.72
    wood = mat_wood(PALETTE["wood"])
    wood_d = mat_wood(PALETTE["wood_dark"], scale=26.0)
    leg_set(root, wood_d, [(-W / 2 + 0.06, -D / 2 + 0.05), (W / 2 - 0.06, -D / 2 + 0.05),
                           (-W / 2 + 0.06, D / 2 - 0.05), (W / 2 - 0.06, D / 2 - 0.05)], r=0.018, h=H)
    rbox("top", (W, D, 0.035), (0, 0, H), wood, root, bevel=0.012)
    # 서랍 유닛
    rbox("drawer_unit", (0.34, D - 0.04, 0.34), (W / 2 - 0.20, 0, H - 0.19), mat_wood(PALETTE["wood_mid"]), root, bevel=0.012)
    for i in range(2):
        rbox("drawer_face%d" % i, (0.02, 0.30, 0.13), (W / 2 - 0.035, 0, H - 0.10 - i * 0.16),
             mat_wood(PALETTE["wood_dark"], scale=30.0), root, bevel=0.006)
        rcyl("knob%d" % i, 0.012, 0.02, (W / 2 - 0.028, 0, H - 0.10 - i * 0.16), mat_plain((0.35, 0.33, 0.30)), root,
             rot=(0, math.radians(90), 0))
    # 모니터(얇은 프레임 + 은은한 화면광)
    dark = mat_plain((0.24, 0.235, 0.225), rough=0.4)
    rbox("mon_frame", (0.46, 0.025, 0.28), (0, -D / 2 + 0.13, H + 0.32), dark, root, bevel=0.006)
    screen = rbox("mon_screen", (0.42, 0.005, 0.25), (0, -D / 2 + 0.148, H + 0.32), mat_plain((0.35, 0.48, 0.55), rough=0.1), root)
    screen.data.materials[0].node_tree.nodes.get("Principled BSDF").inputs["Emission Color"].default_value = (0.25, 0.42, 0.5, 1)
    screen.data.materials[0].node_tree.nodes.get("Principled BSDF").inputs["Emission Strength"].default_value = 0.6
    rcyl("mon_stand", 0.015, 0.14, (0, -D / 2 + 0.13, H + 0.12), dark, root)
    rbox("mon_foot", (0.16, 0.10, 0.015), (0, -D / 2 + 0.13, H + 0.055), dark, root, bevel=0.006)
    # 머그컵 + 책 몇 권
    rcyl("mug", 0.035, 0.08, (W / 2 - 0.42, 0.02, H + 0.06), mat_plain(PALETTE["terracotta"]), root)
    rbox("book1", (0.16, 0.11, 0.025), (-W / 2 + 0.20, 0.0, H + 0.017), mat_plain(PALETTE["sage"]), root, bevel=0.004)
    rbox("book2", (0.14, 0.10, 0.022), (-W / 2 + 0.20, 0.01, H + 0.040), mat_plain((0.75, 0.80, 0.88)), root, bevel=0.004,
         rot=(0, 0, math.radians(6)))
    # 디자인 소품: 작은 화분
    rcyl("pot", 0.04, 0.07, (W / 2 - 0.10, -0.08, H + 0.052), mat_plain((0.80, 0.55, 0.45)), root)
    rsphere("plant", 0.055, (W / 2 - 0.10, -0.08, H + 0.13), mat_plain((0.35, 0.55, 0.35)), root)


def build_chair(root):
    S, H = 0.5, 0.45
    wood = mat_wood(PALETTE["wood_mid"])
    wood_d = mat_wood(PALETTE["wood_dark"], scale=28.0)
    leg_set(root, wood_d, [(-S / 2 + 0.06, -S / 2 + 0.06), (S / 2 - 0.06, -S / 2 + 0.06),
                           (-S / 2 + 0.06, S / 2 - 0.06), (S / 2 - 0.06, S / 2 - 0.06)], r=0.017, h=H)
    rbox("seat", (S - 0.05, S - 0.05, 0.045), (0, 0, H), wood, root, bevel=0.018, subsurf=1)
    # 등받이(가운데 살 2개 + 상판)
    rcyl("spine1", 0.014, 0.42, (-S / 2 + 0.11, -S / 2 + 0.055, H + 0.21), wood_d, root)
    rcyl("spine2", 0.014, 0.42, (S / 2 - 0.11, -S / 2 + 0.055, H + 0.21), wood_d, root)
    rbox("crest", (S - 0.05, 0.045, 0.09), (0, -S / 2 + 0.055, H + 0.40), wood, root, bevel=0.016, subsurf=1)
    # 방석
    rbox("cushion", (S - 0.11, S - 0.11, 0.03), (0, 0.005, H + 0.037), mat_fabric(PALETTE["mustard"]), root,
         bevel=0.02, subsurf=2)


def build_tv(root):
    W, D = 1.0, 0.5
    wood_d = mat_wood(PALETTE["wood_dark"], scale=24.0)
    wood_m = mat_wood(PALETTE["wood_mid"])
    leg_set(root, mat_plain((0.28, 0.26, 0.24), 0.4),
            [(-W / 2 + 0.09, -D / 2 + 0.07), (-W / 2 + 0.09, D / 2 - 0.07),
             (W / 2 - 0.09, -D / 2 + 0.07), (W / 2 - 0.09, D / 2 - 0.07)], r=0.018, h=0.09)
    # 미디어 콘솔(수납)
    rbox("console", (W, D, 0.30), (0, 0, 0.24), wood_m, root, bevel=0.016)
    for i in range(2):
        rbox("console_door%d" % i, (W / 2 - 0.06, 0.015, 0.22), ((i - 0.5) * (W / 2 + 0.005), D / 2, 0.24),
             wood_d, root, bevel=0.008)
    # TV 패널
    dark = mat_plain((0.20, 0.195, 0.185), rough=0.35)
    rbox("tv_frame", (W - 0.16, 0.035, 0.58), (0, 0, 0.70), dark, root, bevel=0.008)
    screen = rbox("tv_screen", (W - 0.24, 0.008, 0.52), (0, 0.020, 0.70), mat_plain((0.30, 0.45, 0.55), rough=0.08), root)
    bsdf = screen.data.materials[0].node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Emission Color"].default_value = (0.22, 0.40, 0.52, 1)
    bsdf.inputs["Emission Strength"].default_value = 0.35
    rcyl("tv_foot", 0.02, 0.10, (0, 0, 0.44), dark, root)
    # 사운드바
    rbox("soundbar", (W - 0.34, 0.07, 0.06), (0, 0.10, 0.42), mat_plain((0.25, 0.24, 0.23), 0.5), root, bevel=0.012)
    # 콘솔 위 데코(작은 화분 + 리모컨)
    rcyl("pot2", 0.035, 0.06, (-W / 2 + 0.14, 0.04, 0.42), mat_plain((0.80, 0.55, 0.45)), root)
    rsphere("plant2", 0.05, (-W / 2 + 0.14, 0.04, 0.49), mat_plain((0.35, 0.55, 0.35)), root)
    rbox("remote", (0.05, 0.16, 0.015), (W / 2 - 0.16, 0.10, 0.398), mat_plain((0.25, 0.24, 0.23)), root,
         bevel=0.006, rot=(0, 0, math.radians(18)))


FURNITURE = {
    "bed_single": build_bed,
    "sofa_two": build_sofa,
    "desk_small": build_desk,
    "chair_basic": build_chair,
    "tv_43": build_tv,
}


# ---------------------------------------------------------------- 캐릭터 v2
CHAR_PARTS = {}


def build_character(root):
    skin = mat_plain(PALETTE["skin"], 0.55)
    hair = mat_plain(PALETTE["hair"], 0.6)
    top = mat_fabric(PALETTE["top"])
    bottom = mat_plain(PALETTE["bottom"], 0.7)
    shoe = mat_plain((0.30, 0.27, 0.25), 0.5)
    # 몸(타원 캡슐 느낌)
    rsphere("body", 0.155, (0, 0, 0.322), top, root, scale=(1.0, 0.92, 1.15))
    # 목/머리
    rsphere("head", 0.134, (0, 0.005, 0.583), skin, root)
    # 머리카락(캡 + 앞머리)
    rsphere("hair_cap", 0.141, (0, -0.008, 0.604), hair, root, scale=(1.0, 1.0, 0.92))
    rbox("fringe", (0.214, 0.064, 0.075), (0, 0.112, 0.614), hair, root, bevel=0.02, subsurf=2,
         rot=(math.radians(12), 0, 0))
    # 팔(소매 없는 간단 봉)
    CHAR_PARTS["arm_l"] = rbox("arm_l", (0.048, 0.048, 0.182), (-0.187, 0, 0.364), top, root, bevel=0.02)
    CHAR_PARTS["arm_r"] = rbox("arm_r", (0.048, 0.048, 0.182), (0.187, 0, 0.364), top, root, bevel=0.02)
    rsphere("hand_l", 0.03, (-0.187, 0, 0.262), skin, root)
    rsphere("hand_r", 0.03, (0.187, 0, 0.262), skin, root)
    # 다리 + 신발
    CHAR_PARTS["leg_l"] = rbox("leg_l", (0.064, 0.059, 0.203), (-0.077, 0, 0.107), bottom, root, bevel=0.018)
    CHAR_PARTS["leg_r"] = rbox("leg_r", (0.064, 0.059, 0.203), (0.077, 0, 0.107), bottom, root, bevel=0.018)
    rbox("shoe_l", (0.080, 0.112, 0.048), (-0.077, 0.019, 0.030), shoe, root, bevel=0.02)
    rbox("shoe_r", (0.080, 0.112, 0.048), (0.077, 0.019, 0.030), shoe, root, bevel=0.02)


REST = {"arm_l": (-0.187, 0, 0.364), "arm_r": (0.187, 0, 0.364),
        "leg_l": (-0.077, 0, 0.107), "leg_r": (0.077, 0, 0.107)}


def pose_neutral():
    for k, o in CHAR_PARTS.items():
        o.rotation_euler = (0, 0, 0)
        o.location = Vector(REST[k])


def pose_walk(phase):
    pose_neutral()
    s = 0.55 if phase == 0 else -0.55
    CHAR_PARTS["leg_l"].rotation_euler = (s, 0, 0)
    CHAR_PARTS["leg_r"].rotation_euler = (-s, 0, 0)
    CHAR_PARTS["arm_l"].rotation_euler = (-s * 0.75, 0, 0)
    CHAR_PARTS["arm_r"].rotation_euler = (s * 0.75, 0, 0)


def pose_sit():
    pose_neutral()
    for k in ("leg_l", "leg_r"):
        CHAR_PARTS[k].rotation_euler = (math.radians(-78), 0, 0)
        CHAR_PARTS[k].location += Vector((0, 0.075, -0.025))
    for k in ("arm_l", "arm_r"):
        CHAR_PARTS[k].rotation_euler = (math.radians(-30), 0, 0)


def pose_lie():
    pose_neutral()
    for k in ("arm_l", "arm_r"):
        CHAR_PARTS[k].rotation_euler = (0, 0, math.radians(80))


# ---------------------------------------------------------------- 씬
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
    # Filmic + 노출
    scene.view_settings.view_transform = "Filmic"
    try:
        scene.view_settings.look = "Medium High Contrast"
    except Exception:
        pass
    scene.view_settings.exposure = 1.32

    # 키 라이트(따뜻한 오후 햇살)
    sun = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "SUN"))
    sun.data.energy = 3.5
    sun.data.angle = math.radians(16)
    sun.data.color = (1.0, 0.93, 0.82)
    sun.rotation_euler = (math.radians(66), 0, math.radians(35))
    scene.collection.objects.link(sun)
    # 필(창가 확산광 — 큰 에리어)
    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = 4.0
    fill_data.energy = 60
    fill_data.color = (0.85, 0.90, 1.0)
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = (-3.5, 3.5, 2.2)
    fill.rotation_euler = (math.radians(50), 0, math.radians(-45))
    scene.collection.objects.link(fill)
    # 림(뒤쪽 시원한 라임)
    rim_data = bpy.data.lights.new("Rim", "AREA")
    rim_data.size = 2.0
    rim_data.energy = 25
    rim_data.color = (1.0, 0.96, 0.88)
    rim = bpy.data.objects.new("Rim", rim_data)
    rim.location = (2.5, -3.0, 1.8)
    rim.rotation_euler = (math.radians(65), 0, math.radians(140))
    scene.collection.objects.link(rim)
    # 월드(부드러운 하늘)
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.98, 0.955, 0.90, 1.0)
    bg.inputs["Strength"].default_value = 0.42
    scene.world = world

    cam_data = bpy.data.cameras.new("IsoCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 3.2
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    place_camera(cam, 0.35)
    return scene, cam


def place_camera(cam, focus_z):
    d = 10.0
    az = math.radians(45)
    el = math.atan(0.5)
    cam.location = (d * math.cos(el) * math.cos(az), -d * math.cos(el) * math.sin(az), d * math.sin(el) + focus_z)
    direction = Vector((0, 0, focus_z)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def add_shadow_catcher():
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, -0.002))
    o = bpy.context.active_object
    o.name = "ShadowCatcher"
    o.is_shadow_catcher = True
    return o


def new_root():
    root = bpy.data.objects.new("Root", None)
    bpy.context.scene.collection.objects.link(root)
    return root


def clear_root(root):
    for o in list(root.children):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.objects.remove(root, do_unlink=True)
    CHAR_PARTS.clear()


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
    add_shadow_catcher()
    ppm_x, ppm_y = calibrate_px_per_meter(scene, cam)
    manifest = {
        "resolution": RES,
        "ortho_scale": 3.2,
        "px_per_meter_x": ppm_x,
        "px_per_meter_y": ppm_y,
        "godot_scale": 286.2167 / ((ppm_x + ppm_y) * 0.5),
        "sprites": {},
    }

    # --- 가구 ---
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

    # --- 캐릭터 ---
    if not ONLY or ONLY == "char":
        root = new_root()
        build_character(root)
        for d in range(4):
            rot = d * 90
            for f in (0, 1):
                pose_walk(f)
                root.rotation_euler = (0, 0, math.radians(rot))
                bpy.context.view_layer.update()
                render(scene, f"char_walk_{d}_{f}.png")
            pose_neutral()
            root.rotation_euler = (0, 0, math.radians(rot))
            bpy.context.view_layer.update()
            render(scene, f"char_idle_{d}.png")
        for pose, base, rots in ((pose_sit, "char_sit", (0, 270)), (pose_lie, "char_lie", (0, 180))):
            pose()
            for rot in rots:
                root.rotation_euler = (0, 0, math.radians(rot))
                bpy.context.view_layer.update()
                render(scene, f"{base}_{rot}.png")
        clear_root(root)
        manifest["sprites"]["char"] = {"type": "character"}

    if not ONLY:
        with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("V2_DONE godot_scale=%.4f" % manifest["godot_scale"])


if __name__ == "__main__":
    main()
