# -*- coding: utf-8 -*-
"""
Quality Benchmark Scene — 아트 디렉션 리셋 v5
"2D Isometric Dollhouse / cozy mobile game / stylized miniature interior"

레퍼런스 코너(침대 구역 1/3) 재현:
  침대1 + 협탁1 + 램프1 + 러그1 + 화분1 + SD캐릭터1 + 벽2면 + 우드바닥

스타일 원칙 (사용자 지시):
  - chunky / rounded / toy-like proportion (가구 실제보다 10~25% 크게)
  - 색면 블로킹: warm orange-brown 우드 / peach 벽 / sage 침구 / cream 러그 / deep green 식물
  - 재질: 스타일라이즈드 평색 + 미세 그레인 (realistic PBR 아님)
  - 조명: 대형 소프트 에리어 + warm ambient, 긴 그림자 금지, 접촉그림자만
  - SD 캐릭터: 머리 = 전체 키의 ~40%
실행: blender -b --factory-startup -P benchmark_scene.py
"""
import bpy
import math
import os
from mathutils import Vector

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output", "benchmark.png"))
RES_X, RES_Y = 1600, 1200

# ---------------------------------------------------------------- 팔레트 (고채도 웜 색면)
PAL = {
    "wood":     (0.820, 0.540, 0.310),   # warm orange-brown
    "wood_d":   (0.610, 0.380, 0.215),   # deep wood
    "wood_l":   (0.850, 0.610, 0.380),   # light wood
    "wall":     (1.000, 0.820, 0.700),   # peach / salmon
    "wall_d":   (0.930, 0.720, 0.620),
    "bedding":  (0.560, 0.660, 0.420),   # sage
    "linen":    (0.960, 0.920, 0.850),
    "cream":    (0.970, 0.900, 0.780),
    "plant":    (0.180, 0.420, 0.240),   # deep green
    "pot":      (0.830, 0.500, 0.360),
    "lamp":     (1.000, 0.930, 0.780),
    "skin":     (0.980, 0.850, 0.740),
    "hair":     (0.220, 0.160, 0.120),
    "top":      (0.940, 0.760, 0.560),   # 머스터드 니트
    "bottom":   (0.380, 0.420, 0.520),
    "terracotta": (0.860, 0.470, 0.340),
}


# ---------------------------------------------------------------- 재질: 평색 스타일라이즈드
def flat(color, rough=0.62):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Specular IOR Level"].default_value = 0.12
    return m


def wood(color, rough=0.55):
    """스타일라이즈드 우드: 평색 + 아주 미세한 그레인"""
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
    mix.inputs["Fac"].default_value = 0.12  # 아주 은은하게
    nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(rgb.outputs[0], mix.inputs["Color1"])
    nt.links.new(ramp.outputs["Color"], mix.inputs["Color2"])
    nt.links.new(mix.outputs["Color"], b.inputs["Base Color"])
    return m


# ---------------------------------------------------------------- 지오메트리 유틸 (chunky)
def rbox(name, size, loc, m, bevel=0.03, sub=2, rot=(0, 0, 0)):
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
    return o


def rcyl(name, r, depth, loc, m, rot=(0, 0, 0), taper=1.0):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=28)
    o = bpy.context.active_object
    o.name = name
    if taper != 1.0:
        o.scale = (1.0, 1.0, 1.0)
        b = o.modifiers.new("t", "BEVEL")
        b.width = min(r, depth) * 0.3
        b.segments = 4
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    return o


def rsph(name, r, loc, m, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=28, ring_count=18)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    return o


def emit(color, strength, m):
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Emission Color"].default_value = (*color, 1)
    b.inputs["Emission Strength"].default_value = strength
    return m


# ---------------------------------------------------------------- 씬 오브젝트
FLOOR_W, FLOOR_H = 3.4, 3.0   # 코너 바닥
WALL_H = 1.35


def build_floor():
    base = rbox("base", (FLOOR_W + 0.05, FLOOR_H + 0.05, 0.10), (FLOOR_W / 2, FLOOR_H / 2, -0.055),
                flat(PAL["wood_d"], 0.8), bevel=0.02)
    # 청크시 플랭크: 폭 0.5m, 두께 0.045, 명확한 이음, 색 변주 크게
    import random
    rng = random.Random(7)
    pw = 0.5
    for row in range(int(FLOOR_H / pw)):
        y0 = row * pw
        x = -(row % 2) * 0.9
        while x < FLOOR_W:
            x0, x1 = max(x, 0.0), min(x + 1.35, FLOOR_W)
            if x1 - x0 > 0.1:
                v = rng.uniform(-0.07, 0.07)
                c = (min(1, PAL["wood"][0] + v), min(1, PAL["wood"][1] + v * 0.8), min(1, PAL["wood"][2] + v * 0.6))
                rbox("plank_%d_%d" % (row, int(x0 * 10)), (x1 - x0 - 0.012, pw - 0.014, 0.045),
                     ((x0 + x1) / 2, y0 + pw / 2, 0.022), wood(c), bevel=0.010)
            x += 1.35


def build_walls():
    w = flat(PAL["wall"], 0.9)
    rbox("wall_y0", (FLOOR_W + 0.14, 0.10, WALL_H), (FLOOR_W / 2, -0.05, WALL_H / 2), w, bevel=0.02)
    rbox("wall_x0", (0.10, FLOOR_H + 0.14, WALL_H), (-0.05, FLOOR_H / 2, WALL_H / 2), w, bevel=0.02)
    # 몰딩: 걸레받이 + 상단 트림 (chunky)
    bb = flat(PAL["wood_l"], 0.6)
    rbox("bb_y0", (FLOOR_W, 0.05, 0.14), (FLOOR_W / 2, 0.026, 0.07), bb, bevel=0.014)
    rbox("bb_x0", (0.05, FLOOR_H, 0.14), (0.026, FLOOR_H / 2, 0.07), bb, bevel=0.014)
    tr = flat(PAL["wall_d"], 0.85)
    rbox("tr_y0", (FLOOR_W + 0.14, 0.12, 0.05), (FLOOR_W / 2, -0.05, WALL_H - 0.025), tr, bevel=0.012)
    rbox("tr_x0", (0.12, FLOOR_H + 0.14, 0.05), (-0.05, FLOOR_H / 2, WALL_H - 0.025), tr, bevel=0.012)


def build_bed():
    """청키 베드: 두꺼운 플랫폼(다리 없음) + 둥근 헤드보드 + 통통한 매트리스/베개"""
    W, L = 1.30, 2.10  # 실제보다 크게
    sage = flat(PAL["bedding"], 0.95)
    linen = flat(PAL["linen"], 0.95)
    m_wood = wood(PAL["wood_l"])
    m_wood_d = wood(PAL["wood_d"])
    # 플랫폼 (플린스)
    rbox("bed_plinth", (W, L, 0.22), (0, 0, 0.11), m_wood_d, bevel=0.035)
    # 헤드보드 (둥글고 두껍게)
    rbox("bed_head", (W + 0.06, 0.14, 0.72), (0, -L / 2 + 0.07, 0.36 + 0.10), m_wood, bevel=0.06)
    # 매트리스 (통통)
    rbox("bed_mattress", (W - 0.10, L - 0.10, 0.26), (0, 0.01, 0.22 + 0.13), linen, bevel=0.09)
    # 베개 2 (아주 통통)
    rbox("bed_pillow1", (W / 2 - 0.10, 0.42, 0.16), (-W / 4 + 0.01, -L / 2 + 0.38, 0.48 + 0.06), linen,
         bevel=0.07, rot=(math.radians(-10), 0, 0))
    rbox("bed_pillow2", (W / 2 - 0.10, 0.42, 0.16), (W / 4 - 0.01, -L / 2 + 0.38, 0.48 + 0.06), linen,
         bevel=0.07, rot=(math.radians(-10), 0, 0))
    # 듀벳 (청크, sage)
    rbox("bed_duvet", (W + 0.02, L * 0.58, 0.16), (0, L * 0.20, 0.22 + 0.26 + 0.02), sage, bevel=0.08)
    # 데코 쿠션 (테라코타)
    rbox("bed_cushion", (0.38, 0.38, 0.14), (W / 5, L * 0.02, 0.60), flat(PAL["terracotta"], 0.95),
         bevel=0.07, rot=(0, 0, math.radians(-10)))
    # 벽 위치: 헤드보드가 -Y 벽에 붙게
    return Vector((W / 2 + 0.28, L / 2 + 0.10))


def build_nightstand():
    """청키 협탁"""
    S, H = 0.55, 0.52
    m_wood = wood(PAL["wood_l"])
    m_wood_d = wood(PAL["wood_d"])
    rbox("ns_body", (S, S, H), (0, 0, H / 2 + 0.06), m_wood, bevel=0.045)
    rbox("ns_plinth", (S - 0.10, S - 0.10, 0.10), (0, 0, 0.05), m_wood_d, bevel=0.025)
    rbox("ns_drawer", (S - 0.08, 0.035, H * 0.52), (0, S / 2 + 0.005, H * 0.68), m_wood_d, bevel=0.018)
    rcyl("ns_knob", 0.030, 0.035, (0, S / 2 + 0.035, H * 0.68), flat((0.95, 0.88, 0.78), 0.4),
         rot=(math.radians(90), 0, 0))
    # 책 + 작은 화분
    rbox("ns_book", (0.20, 0.14, 0.035), (-0.10, 0.02, H + 0.085), flat(PAL["bedding"]), bevel=0.008)
    rcyl("ns_vase", 0.045, 0.11, (0.13, -0.06, H + 0.12), flat((0.94, 0.90, 0.84), 0.5))
    rsph("ns_vase_leaf", 0.05, (0.13, -0.06, H + 0.20), flat(PAL["plant"]), scale=(0.7, 0.7, 1.0))


def build_lamp():
    """청키 플로어 램프(따뜻한 발광)"""
    rcyl("lamp_base", 0.16, 0.05, (0, 0, 0.025), flat((0.62, 0.44, 0.30), 0.5))
    rcyl("lamp_pole", 0.022, 1.05, (0, 0, 0.55), flat((0.62, 0.44, 0.30), 0.5))
    shade = rcyl("lamp_shade", 0.17, 0.26, (0, 0, 1.12), flat(PAL["cream"], 0.9))
    shade.scale = (1.15, 1.15, 1.0)
    g = rcyl("lamp_glow", 0.12, 0.02, (0, 0, 1.01), emit((1.0, 0.88, 0.62), 3.0, flat((1, 0.95, 0.85))))


def build_rug():
    """타원 러그: warm cream + 세이지 보더 (청크 두께)"""
    o = rcyl("rug_outer", 0.62, 0.035, (0, 0, 0.028), flat(PAL["bedding"], 0.98))
    o.scale = (1.55, 1.0, 1.0)
    i = rcyl("rug_inner", 0.50, 0.042, (0, 0, 0.034), flat(PAL["cream"], 0.98))
    i.scale = (1.55, 1.0, 1.0)


def build_plant():
    """대형 화분: 통통한 화분 + 큼직한 잎 5장"""
    rcyl("plant_pot", 0.17, 0.30, (0, 0, 0.15), flat(PAL["pot"], 0.75))
    rcyl("plant_rim", 0.20, 0.06, (0, 0, 0.31), flat(PAL["pot"], 0.75))
    rcyl("plant_soil", 0.15, 0.02, (0, 0, 0.325), flat((0.30, 0.22, 0.16), 0.95))
    leaves = [(0.0, 0.55), (1.3, 0.78), (2.6, 0.62), (3.9, 0.85), (5.1, 0.60), (5.8, 0.45)]
    for i, (ang, h) in enumerate(leaves):
        leaf = rsph("leaf%d" % i, 0.16, (math.cos(ang) * 0.10, math.sin(ang) * 0.10, 0.38 + h * 0.55),
                    flat(PAL["plant"], 0.6))
        leaf.scale = (0.42, 1.5, 0.62)
        leaf.rotation_euler = (0.0, 0.12, ang)


def build_character():
    """SD 캐릭터: 머리 = 키의 ~40%, 통통한 몸, 큰 눈, 명확한 헤어 실루엣"""
    skin = flat(PAL["skin"], 0.55)
    hair = flat(PAL["hair"], 0.6)
    top = flat(PAL["top"], 0.95)
    bottom = flat(PAL["bottom"], 0.9)
    shoe = flat((0.35, 0.28, 0.24), 0.6)
    eye_m = flat((0.13, 0.11, 0.10), 0.2)
    # 몸 (통통, ~0.42m)
    rsph("c_body", 0.175, (0, 0, 0.27), top, scale=(1.0, 0.92, 1.15))
    rsph("c_hips", 0.15, (0, 0, 0.15), bottom, scale=(1.0, 0.9, 0.8))
    # 머리 (지름 ~0.42 → 키 1.05의 40%)
    rsph("c_head", 0.21, (0, 0.01, 0.62), skin)
    rsph("c_hair_cap", 0.222, (0, -0.012, 0.635), hair, scale=(1.0, 1.0, 0.94))
    rsph("c_hair_back", 0.17, (0, -0.11, 0.61), hair, scale=(1.3, 0.85, 1.2))
    rsph("c_hair_bun", 0.10, (0, -0.14, 0.82), hair)
    rbox("c_fringe", (0.33, 0.09, 0.10), (0, 0.165, 0.665), hair, bevel=0.035, rot=(math.radians(16), 0, 0))
    # 얼굴: 큰 눈 + 볼 + 입
    for sx, nm in ((-1, "l"), (1, "r")):
        rsph("c_eye_%s" % nm, 0.048, (sx * 0.078, 0.185, 0.635), eye_m)
        rsph("c_hi_%s" % nm, 0.014, (sx * 0.090, 0.212, 0.652), flat((1, 1, 1), 0.1))
        rsph("c_brow_%s" % nm, 0.030, (sx * 0.078, 0.175, 0.695), hair, scale=(1.3, 0.35, 0.5))
        rsph("c_blush_%s" % nm, 0.032, (sx * 0.140, 0.15, 0.60), flat((0.97, 0.62, 0.55), 0.85), scale=(1.1, 0.5, 0.7))
    rsph("c_mouth", 0.022, (0, 0.207, 0.555), flat((0.75, 0.42, 0.38), 0.6), scale=(1.4, 0.55, 0.8))
    # 팔 (짧고 통통) + 다리
    rbox("c_arm_l", (0.058, 0.058, 0.16), (-0.195, 0, 0.30), top, bevel=0.028)
    rbox("c_arm_r", (0.058, 0.058, 0.16), (0.195, 0, 0.30), top, bevel=0.028)
    rsph("c_hand_l", 0.038, (-0.195, 0.01, 0.20), skin)
    rsph("c_hand_r", 0.038, (0.195, 0.01, 0.20), skin)
    rbox("c_leg_l", (0.075, 0.065, 0.12), (-0.072, 0, 0.055), bottom, bevel=0.026)
    rbox("c_leg_r", (0.075, 0.065, 0.12), (0.072, 0, 0.055), bottom, bevel=0.026)
    rbox("c_shoe_l", (0.095, 0.14, 0.058), (-0.072, 0.025, 0.030), shoe, bevel=0.026)
    rbox("c_shoe_r", (0.095, 0.14, 0.058), (0.072, 0.025, 0.030), shoe, bevel=0.026)


# ---------------------------------------------------------------- 배치 + 조명 + 카메라

def build_extra_props():
    """생활감 소품: 침대 위 책, 러그 위 슬리퍼, 협탁 컵, 벽 액자, 벽 미니 선반"""
    rbox("book_on_bed", (0.16, 0.12, 0.035), (0.55, 0.85, 0.70), flat(PAL["terracotta"]), bevel=0.008,
         rot=(0, 0, math.radians(18)))
    for sx in (-1, 1):
        rbox("slipper_%d" % sx, (0.085, 0.17, 0.030), (1.15 + sx * 0.11, 2.05, 0.065), flat(PAL["bedding"]),
             bevel=0.018, rot=(0, 0, math.radians(-12 + sx * 14)))
    rcyl("ns_cup", 0.038, 0.09, (2.02, 0.30, 0.665), flat(PAL["terracotta"]))
    # 벽 액자 (-Y 벽)
    rbox("wall_frame", (0.30, 0.038, 0.38), (2.10, 0.075, 0.95), wood(PAL["wood_d"]), bevel=0.016)
    rbox("wall_frame_art", (0.24, 0.020, 0.31), (2.10, 0.098, 0.95), flat(PAL["cream"]), bevel=0.004)
    rbox("wall_frame_dot", (0.07, 0.012, 0.07), (2.10, 0.110, 1.02), flat(PAL["bedding"]), bevel=0.003)
    # 벽 미니 선반 + 소품 (-X 벽)
    rbox("wall_shelf_b", (0.035, 0.55, 0.045), (0.075, 1.75, 1.02), wood(PAL["wood_l"]), bevel=0.010)
    rcyl("shelf_plant_pot", 0.040, 0.075, (0.075, 1.62, 1.08), flat(PAL["pot"]))
    rsph("shelf_plant", 0.05, (0.075, 1.62, 1.145), flat(PAL["plant"]))
    rbox("shelf_book1", (0.028, 0.10, 0.13), (0.075, 1.87, 1.105), flat(PAL["bedding"]), bevel=0.005)
    rbox("shelf_book2", (0.028, 0.085, 0.11), (0.075, 1.90, 1.095), flat((0.90, 0.75, 0.60)), bevel=0.005)


def build_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    build_floor()
    build_walls()

    # 침대: -Y 벽에 헤드 붙임, -X 벽에 붙임
    bpy.ops.object.select_all(action="DESELECT")
    build_bed()
    build_nightstand()
    build_lamp()
    build_rug()
    build_plant()
    build_character()
    build_extra_props()
    for name in ("bed_plinth", "bed_head", "bed_mattress", "bed_pillow1", "bed_pillow2", "bed_duvet", "bed_cushion"):
        o = bpy.data.objects[name]
        o.location += Vector((0.28, 0.08, 0.0))
    # 협탁: 침대 오른쪽
    for name in ("ns_body", "ns_plinth", "ns_drawer", "ns_knob", "ns_book", "ns_vase", "ns_vase_leaf"):
        o = bpy.data.objects[name]
        o.location += Vector((1.85, 0.42, 0.0))
    # 램프: 협탁 오른쪽 뒤
    for name in ("lamp_base", "lamp_pole", "lamp_shade", "lamp_glow"):
        o = bpy.data.objects[name]
        o.location += Vector((2.62, 0.22, 0.0))
    # 러그: 침대 앞
    for name in ("rug_outer", "rug_inner"):
        o = bpy.data.objects[name]
        o.location += Vector((1.15, 1.72, 0.0))
    # 화분: 우하단 코너
    for o in [obj for obj in bpy.data.objects if obj.name.startswith("plant_")]:
        o.location += Vector((2.95, 2.35, 0.0))
    # 캐릭터: 러그 위, 침대 옆
    for o in [obj for obj in bpy.data.objects if obj.name.startswith("c_")]:
        o.location += Vector((0.72, 1.55, 0.0))


def setup_light_camera():
    scene = bpy.context.scene
    # 조명: 태양 없음. 대형 소프트 에리어 2 + warm world ambient → 짧고 부드러운 접촉그림자만
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

    # 카메라: 30도/315도 아이소 (게임 관례), 코너 중심 프레이밍
    cam_data = bpy.data.cameras.new("IsoCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 4.6
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    focus = Vector((1.5, 1.3, 0.45))
    d = 12.0
    az = math.radians(315)
    el = math.radians(30)
    cam.location = focus + Vector((d * math.cos(el) * math.cos(az), -d * math.cos(el) * math.sin(az), d * math.sin(el)))
    direction = focus - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    # 그림자 캐처 (접촉 그림자용)
    bpy.ops.mesh.primitive_plane_add(size=30, location=(FLOOR_W / 2, FLOOR_H / 2, -0.001))
    sc = bpy.context.active_object
    sc.name = "ShadowCatcher"
    sc.is_shadow_catcher = True

    scene.render.engine = "CYCLES"
    scene.cycles.samples = 128
    scene.cycles.use_denoising = True
    scene.render.film_transparent = False
    scene.render.resolution_x = RES_X
    scene.render.resolution_y = RES_Y
    scene.render.image_settings.file_format = "PNG"
    # 일러스트 필: Standard 뷰트랜스폼(과다 디졸브 없음) + 낮은 대비
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = 1.15
    scene.view_settings.gamma = 1.02
    return scene


def main():
    build_scene()
    scene = setup_light_camera()
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("BENCH_DONE", OUT)


if __name__ == "__main__":
    main()
