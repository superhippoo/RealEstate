# -*- coding: utf-8 -*-
"""
ART BENCHMARK — 레퍼런스 침실 재현
"Stylized 3D → 2D Isometric Dollhouse 모바일 게임 일러스트"

파이프라인: Blender → Cycles 고품질 렌더 → PNG → Godot Sprite2D
스타일: soft stylized shading (flat toon 아님, photoreal 아님)

레퍼런스 정책:
- 색상 수 감소 목표 아님
- 표면 variance 낮추지 않음
- toon ramp/posterize 사용 안 함
- 부드러운 material gradient + soft ambient + contact shadow
"""
import bpy
import math
import os
import random
from mathutils import Vector

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "review", "art_benchmark.png"))
RES_X, RES_Y = 1600, 1200

# ================================================================ PALETTE
# 레퍼런스 기준: warm peach 벽, medium orange-brown 바닥, sage 침구, muted green 식물
# 채도: 낮추고 따뜻하게. Pure orange/neon/blown white 금지.
PAL = {
    "wall":      (0.93, 0.78, 0.68),   # warm peach/salmon (매우 채도 낮음)
    "wall_dim":  (0.85, 0.70, 0.62),   # 은은한 gradient용
    "floor":     (0.72, 0.52, 0.33),   # warm medium orange-brown
    "floor_var": (0.68, 0.48, 0.30),   # 플랭크 변주
    "wood":      (0.76, 0.55, 0.35),   # warm natural wood
    "wood_d":    (0.60, 0.42, 0.26),   # dark wood
    "sage":      (0.62, 0.72, 0.52),   # sage green (muted)
    "sage_d":    (0.54, 0.64, 0.44),   # sage deep
    "cream":     (0.94, 0.88, 0.78),   # warm cream
    "linen":     (0.93, 0.89, 0.83),   # linen white
    "plant":     (0.28, 0.45, 0.28),   # muted deep green
    "plant_d":   (0.22, 0.38, 0.22),
    "terra":     (0.80, 0.52, 0.40),   # soft terracotta
    "yellow":    (0.88, 0.76, 0.50),   # soft yellow
    "brass":     (0.68, 0.56, 0.42),   # muted brass
    "charcoal":  (0.28, 0.26, 0.24),   # soft charcoal (not pure black)
    # 캐릭터
    "skin":      (0.95, 0.82, 0.71),
    "hair":      (0.22, 0.17, 0.14),
    "knit":      (0.92, 0.82, 0.68),   # warm cream knit
    "pants":     (0.40, 0.38, 0.42),   # warm grey
    "shoe":      (0.36, 0.30, 0.26),
}


# ================================================================ MATERIALS
def mat(color, rough=0.72, sub=0.0):
    """Stylized PBR — 높은 roughness, 미묘한 specular, 부드러운 질감"""
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Specular IOR Level"].default_value = 0.25
    b.inputs["Sheen Weight"].default_value = 0.1
    if sub > 0:
        # 미세 노이즈 (매우 약한 질감)
        nt = m.node_tree
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 80.0
        noise.inputs["Detail"].default_value = 1.0
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nm.inputs["Strength"].default_value = 0.08
        h = None
        for inp in nm.inputs:
            if inp.name in ("Height", "Color") and inp.type == "RGBA":
                h = inp; break
        if h:
            nt.links.new(noise.outputs["Fac"], h)
        nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return m


def wood_mat(color, rough=0.60):
    """Simplified wood grain — 매우 은은한 결"""
    m = mat(color, rough)
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    rgb = nt.nodes.new("ShaderNodeRGB")
    rgb.outputs[0].default_value = (*color, 1.0)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 4.0
    noise.inputs["Detail"].default_value = 2.0
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (1.0, 6.0, 1.0)
    coord = nt.nodes.new("ShaderNodeTexCoord")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.45
    ramp.color_ramp.elements[1].position = 0.55
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 0.08  # 아주 은은하게
    nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(rgb.outputs[0], mix.inputs["Color1"])
    nt.links.new(ramp.outputs["Color"], mix.inputs["Color2"])
    nt.links.new(mix.outputs["Color"], b.inputs["Base Color"])
    return m


def emit_mat(color, emission, energy, rough=0.5):
    m = mat(color, rough)
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Emission Color"].default_value = (*emission, 1)
    b.inputs["Emission Strength"].default_value = energy
    return m


# ================================================================ GEOMETRY
def _smooth(o):
    for p in o.data.polygons:
        p.use_smooth = True


def _sub(o, lv=2):
    s = o.modifiers.new("s", "SUBSURF"); s.levels = lv; s.render_levels = lv


def _bev(o, w=0.035):
    b = o.modifiers.new("b", "BEVEL"); b.width = w; b.segments = 4; b.harden_normals = True


def rbox(name, size, loc, m, parent=None, bevel=0.035, sub=2, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = size
    if sub: _sub(o, sub)
    if bevel: _bev(o, bevel)
    _smooth(o)
    o.data.materials.append(m)
    if parent: o.parent = parent
    return o


def rcyl(name, r, depth, loc, m, parent=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=28)
    o = bpy.context.active_object; o.name = name
    b = o.modifiers.new("b", "BEVEL"); b.width = min(r, depth) * 0.2; b.segments = 4
    _smooth(o)
    o.data.materials.append(m)
    if parent: o.parent = parent
    return o


def rsph(name, r, loc, m, parent=None, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=28, ring_count=18)
    o = bpy.context.active_object; o.name = name; o.scale = scale
    _sub(o, 2); _smooth(o)
    o.data.materials.append(m)
    if parent: o.parent = parent
    return o


# ================================================================ SCENE BUILD
FW, FH = 3.4, 3.0  # floor width/height (m)
WALL_H = 1.20


def build_floor():
    rng = random.Random(42)
    m_wood = PAL["floor"]
    # 베이스
    rbox("floor_base", (FW + 0.03, FH + 0.03, 0.04), (FW/2, FH/2, -0.022),
         mat(PAL["floor_var"], 0.85), bevel=0.01)
    # 플랭크
    pw = 0.5
    for row in range(7):
        y0 = row * pw
        x = -(row % 2) * 0.9
        while x < FW:
            x0, x1 = max(x, 0.0), min(x + 1.35, FW)
            if x1 - x0 > 0.1:
                v = rng.uniform(-0.04, 0.04)
                c = (min(1, m_wood[0]+v), min(1, m_wood[1]+v*0.8), min(1, m_wood[2]+v*0.6))
                rbox(f"plank_{row}_{int(x0*10)}",
                     (x1-x0-0.003, pw-0.004, 0.04),
                     ((x0+x1)/2, y0+pw/2, 0.020),
                     wood_mat(c, 0.62), bevel=0.006, sub=1)
            x += 1.35


def build_walls():
    w1 = mat(PAL["wall"], 0.88, sub=0.04)  # peach + 미세 noise
    w2 = mat((PAL["wall"][0]*0.97, PAL["wall"][1]*0.96, PAL["wall"][2]*0.96), 0.88, sub=0.04)
    rbox("wall_back", (FW+0.08, 0.08, WALL_H), (FW/2, -0.04, WALL_H/2), w1, bevel=0.015, sub=1)
    rbox("wall_left", (0.08, FH+0.08, WALL_H), (-0.04, FH/2, WALL_H/2), w2, bevel=0.015, sub=1)
    # 걸레받이
    bb = mat(PAL["wood"], 0.65)
    rbox("bb_back", (FW, 0.04, 0.11), (FW/2, 0.022, 0.055), bb, bevel=0.012)
    rbox("bb_left", (0.04, FH, 0.11), (0.022, FH/2, 0.055), bb, bevel=0.012)
    # 상단 몰딩
    tm = mat(PAL["wall_dim"], 0.85)
    rbox("trim_back", (FW+0.08, 0.10, 0.04), (FW/2, -0.05, WALL_H-0.022), tm, bevel=0.008)
    rbox("trim_left", (0.10, FH+0.08, 0.04), (-0.05, FH/2, WALL_H-0.022), tm, bevel=0.008)


def build_window():
    wy, wz = 0.7, 1.5
    m_frame = mat(PAL["wood"], 0.65)
    # 발광 유리 (따뜻한 창밖)
    glass = emit_mat((0.95, 0.92, 0.86), (0.95, 0.88, 0.75), 2.5, 0.3)
    rbox("win_glass", (0.015, 0.62, 0.58), (0.045, wz, wy+0.28), glass, bevel=0.003, sub=1)
    # 프레임
    for dx, dy, sx, sy in [(0, -0.33, 0.06, 0.05), (0, 0.33, 0.06, 0.05)]:
        rbox(f"wf_h{dy}", (0.06, sx, 0.05), (0.06, wz+dy, wy+0.28), m_frame, bevel=0.010)
    rbox("wf_top", (0.06, 0.72, 0.06), (0.06, wz, wy+0.58), m_frame, bevel=0.010)
    rbox("wf_bot", (0.06, 0.72, 0.06), (0.06, wz, wy-0.02), m_frame, bevel=0.010)
    rbox("wf_mid", (0.05, 0.03, 0.55), (0.06, wz, wy+0.28), m_frame, bevel=0.006)
    # 커튼 (부드러운 시어)
    cur_m = mat((0.94, 0.91, 0.86), 0.92, sub=0.3)
    for sz in [-0.38, 0.38]:
        c = rbox(f"curtain_{sz}", (0.025, 0.12, 0.62), (0.09, wz+sz, wy+0.28), cur_m, bevel=0.02, sub=3)
        tex = bpy.data.textures.new("cw", type="CLOUDS")
        dis = c.modifiers.new("d", "DISPLACE"); dis.texture = tex; dis.strength = 0.006


def build_bed():
    W, L = 1.30, 2.10
    m_wood = wood_mat(PAL["wood"], 0.62)
    m_wood_d = wood_mat(PAL["wood_d"], 0.62)
    sage = mat(PAL["sage"], 0.88, sub=0.15)
    sage_d = mat(PAL["sage_d"], 0.88, sub=0.15)
    linen = mat(PAL["linen"], 0.90, sub=0.15)
    terra = mat(PAL["terra"], 0.88, sub=0.15)
    ox, oy = 0.15, 1.05  # bed origin

    # 두꺼운 플랫폼
    rbox("bed_plinth", (W, L, 0.18), (ox, oy, 0.09), m_wood_d, bevel=0.035)
    # 둥근 헤드보드
    rbox("bed_head", (W+0.04, 0.12, 0.65), (ox, oy-L/2+0.06, 0.38), m_wood, bevel=0.05)
    # 매트리스
    rbox("bed_mattress", (W-0.06, L-0.06, 0.24), (ox, oy, 0.30), linen, bevel=0.08)
    # 통통한 베개 2
    for sx in [-1, 1]:
        rbox(f"pillow_{sx}", (W/2-0.05, 0.38, 0.14), (ox+sx*W/4, oy-L/2+0.36, 0.49), linen,
             bevel=0.06, rot=(math.radians(-8), 0, 0))
    # 듀벳 (부드럽게 굴러감)
    duvet = rbox("bed_duvet", (W+0.01, L*0.58, 0.15), (ox, oy+L*0.18, 0.50), sage_d, bevel=0.07)
    tex = bpy.data.textures.new("duvet_f", type="CLOUDS")
    tex.noise_depth = 3
    dis = duvet.modifiers.new("d", "DISPLACE"); dis.texture = tex; dis.strength = 0.012
    # 쿠션
    rbox("bed_cushion", (0.32, 0.32, 0.12), (ox+W/5, oy+L*0.02, 0.60), terra, bevel=0.06,
         rot=(0, 0, math.radians(-8)))


def build_wardrobe():
    ox, oy = 2.85, 0.42
    m_wood = wood_mat(PAL["wood"], 0.62)
    m_wood_d = wood_mat(PAL["wood_d"], 0.62)
    W, D, H = 0.75, 0.42, 1.05
    rbox("wardrobe", (W, D, H), (ox, oy, H/2+0.02), m_wood, bevel=0.03)
    rbox("wardrobe_plinth", (W-0.06, D-0.06, 0.06), (ox, oy, 0.03), m_wood_d, bevel=0.015)
    # 문
    for dx in [-0.18, 0.18]:
        rbox(f"wdoor_{dx}", (W/2-0.03, 0.015, H-0.10), (ox+dx, oy+D/2, H/2+0.02), m_wood_d, bevel=0.012)
        rcyl(f"whandle_{dx}", 0.015, 0.03, (ox+dx+0.12, oy+D/2+0.02, H/2), mat(PAL["brass"], 0.4),
             rot=(math.radians(90), 0, 0))


def build_nightstand():
    ox, oy = 1.75, 0.30
    m_wood = wood_mat(PAL["wood"], 0.62)
    m_wood_d = wood_mat(PAL["wood_d"], 0.62)
    S, H = 0.48, 0.50
    rbox("ns_body", (S, S, H), (ox, oy, H/2+0.03), m_wood, bevel=0.035)
    rbox("ns_plinth", (S-0.08, S-0.08, 0.06), (ox, oy, 0.03), m_wood_d, bevel=0.02)
    rbox("ns_drawer", (S-0.05, 0.025, H*0.45), (ox, oy+S/2, H*0.70), m_wood_d, bevel=0.015)
    rcyl("ns_knob", 0.025, 0.03, (ox, oy+S/2+0.02, H*0.70), mat(PAL["brass"], 0.4),
         rot=(math.radians(90), 0, 0))
    # 책 + 컵
    rbox("ns_book", (0.16, 0.12, 0.025), (ox-0.06, oy, H+0.015), mat(PAL["sage"], 0.85), bevel=0.006)
    rcyl("ns_mug", 0.032, 0.07, (ox+0.10, oy, H+0.055), mat(PAL["terra"], 0.7))


def build_lamp():
    ox, oy = 1.65, 0.90
    brass = mat(PAL["brass"], 0.45)
    rcyl("lamp_base", 0.12, 0.04, (ox, oy, 0.02), brass)
    rcyl("lamp_pole", 0.015, 1.00, (ox, oy, 0.52), brass)
    shade = rcyl("lamp_shade", 0.14, 0.24, (ox, oy, 1.08), mat(PAL["cream"], 0.88))
    shade.scale = (1.15, 1.15, 1.0)
    rcyl("lamp_glow", 0.10, 0.015, (ox, oy, 0.97),
         emit_mat((1, 0.95, 0.85), (0.95, 0.82, 0.60), 2.0))


def build_rug():
    ox, oy = 1.30, 1.80
    outer = rcyl("rug_outer", 0.52, 0.025, (ox, oy, 0.012), mat(PAL["cream"], 0.95, sub=0.5))
    outer.scale = (1.5, 1.0, 1.0)
    inner = rcyl("rug_inner", 0.43, 0.032, (ox, oy, 0.016), mat((0.88, 0.80, 0.68), 0.95, sub=0.5))
    inner.scale = (1.5, 1.0, 1.0)
    ring = rcyl("rug_ring", 0.47, 0.030, (ox, oy, 0.015), mat(PAL["sage"], 0.95, sub=0.5))
    ring.scale = (1.5, 1.0, 1.0)


def build_plant():
    ox, oy = 3.10, 2.10
    pot_m = mat(PAL["terra"], 0.75)
    leaf_m = mat(PAL["plant"], 0.62, sub=0.1)
    leaf_d = mat(PAL["plant_d"], 0.62, sub=0.1)
    rcyl("plant_pot", 0.14, 0.26, (ox, oy, 0.13), pot_m)
    rcyl("plant_rim", 0.17, 0.04, (ox, oy, 0.27), pot_m)
    rcyl("plant_soil", 0.12, 0.02, (ox, oy, 0.28), mat((0.30, 0.24, 0.20), 0.90))
    for i, (ang, h) in enumerate([(0, 0.5), (1.1, 0.7), (2.3, 0.55), (3.5, 0.75), (4.7, 0.5), (5.5, 0.4)]):
        l = rsph(f"pleaf_{i}", 0.17, (ox+math.cos(ang)*0.08, oy+math.sin(ang)*0.06, 0.33+h*0.50),
                 leaf_m if i % 2 else leaf_d)
        l.scale = (0.42, 1.4, 0.60)
        l.rotation_euler = (0, 0.08, ang)


def build_picture():
    m_frame = wood_mat(PAL["wood_d"], 0.60)
    ox, oz = 0.06, 0.85
    wz = 2.30
    rbox("pic_frame", (0.035, 0.38, 0.48), (ox, wz, oz), m_frame, bevel=0.015)
    rbox("pic_canvas", (0.02, 0.32, 0.42), (ox+0.02, wz, oz), mat((0.94, 0.92, 0.88), 0.85), bevel=0.004)
    rbox("pic_art1", (0.01, 0.18, 0.20), (ox+0.03, wz-0.05, oz+0.05), mat(PAL["sage"], 0.85), bevel=0.003)
    rbox("pic_art2", (0.01, 0.10, 0.12), (ox+0.03, wz+0.08, oz-0.08), mat(PAL["terra"], 0.85), bevel=0.003)


def build_shelf():
    ox, wz = 0.06, 1.40
    wy = 0.85
    m_shelf = wood_mat(PAL["wood"], 0.62)
    rbox("shelf_board", (0.04, 0.16, 0.55), (ox, wy, wz), m_shelf, bevel=0.012)
    rbox("shelf_br1", (0.03, 0.02, 0.08), (ox, wy-0.06, wz-0.05), m_shelf, bevel=0.005)
    rbox("shelf_br2", (0.03, 0.02, 0.08), (ox, wy+0.06, wz-0.05), m_shelf, bevel=0.005)
    # 소품
    rbox("shelf_book1", (0.025, 0.10, 0.14), (ox, wy-0.03, wz+0.085), mat(PAL["sage"], 0.85), bevel=0.005)
    rbox("shelf_book2", (0.025, 0.09, 0.12), (ox, wy+0.01, wz+0.08), mat(PAL["yellow"], 0.85), bevel=0.005)
    rcyl("shelf_pot", 0.035, 0.06, (ox, wy+0.08, wz+0.035), mat(PAL["terra"], 0.75))
    rsph("shelf_plant", 0.045, (ox, wy+0.08, wz+0.09), mat(PAL["plant"], 0.65))


def build_char():
    skin = mat(PAL["skin"], 0.58)
    hair = mat(PAL["hair"], 0.60)
    knit = mat(PAL["knit"], 0.90, sub=0.2)
    pants = mat(PAL["pants"], 0.85)
    shoe = mat(PAL["shoe"], 0.60)
    eye_m = mat((0.15, 0.13, 0.12), 0.25)
    white_m = mat((0.97, 0.96, 0.94), 0.10)
    blush_m = mat((0.92, 0.62, 0.55), 0.82)

    cx, cy = 1.30, 2.10  # 러그 위

    # 몸 (통통)
    rsph("c_body", 0.17, (cx, cy, 0.28), knit, scale=(1.0, 0.92, 1.12))
    rsph("c_hips", 0.14, (cx, cy, 0.14), pants, scale=(1.0, 0.9, 0.75))

    # 머리 (SD 큰 머리)
    rsph("c_head", 0.22, (cx, cy+0.01, 0.58), skin)
    # 헤어 (볼륨!)
    rsph("c_hair_cap", 0.235, (cx, cy-0.01, 0.60), hair, scale=(1.0, 1.0, 0.94))
    rsph("c_hair_back", 0.185, (cx, cy-0.12, 0.58), hair, scale=(1.3, 0.85, 1.15))
    rsph("c_hair_bun", 0.10, (cx, cy-0.15, 0.78), hair)
    rbox("c_fringe", (0.34, 0.09, 0.10), (cx, cy+0.17, 0.66), hair, bevel=0.035,
         rot=(math.radians(15), 0, 0))

    # 얼굴 (큰 눈 + 하이라이트 + 볼터치)
    for sx, nm in [(-1, "l"), (1, "r")]:
        rsph(f"c_eye_{nm}", 0.062, (cx+sx*0.072, cy+0.185, 0.60), eye_m)
        rsph(f"c_hi_{nm}", 0.022, (cx+sx*0.085, cy+0.210, 0.617), white_m)
        rsph(f"c_blush_{nm}", 0.038, (cx+sx*0.14, cy+0.15, 0.565), blush_m, scale=(1.1, 0.5, 0.7))
    rsph("c_mouth", 0.020, (cx, cy+0.205, 0.535), mat((0.72, 0.42, 0.38), 0.60), scale=(1.4, 0.55, 0.8))

    # 팔/다리 (짧고 통통)
    for sx, nm in [(-1, "l"), (1, "r")]:
        rbox(f"c_arm_{nm}", (0.055, 0.055, 0.15), (cx+sx*0.185, cy, 0.26), knit, bevel=0.028)
        rsph(f"c_hand_{nm}", 0.036, (cx+sx*0.185, cy+0.01, 0.175), skin)
        rbox(f"c_leg_{nm}", (0.07, 0.06, 0.11), (cx+sx*0.065, cy, 0.065), pants, bevel=0.024)
        rbox(f"c_shoe_{nm}", (0.088, 0.13, 0.052), (cx+sx*0.065, cy+0.025, 0.028), shoe, bevel=0.024)


# ================================================================ LIGHTING & CAMERA
def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 192
    scene.cycles.use_denoising = True
    scene.render.film_transparent = False
    scene.render.resolution_x = RES_X
    scene.render.resolution_y = RES_Y
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"  # 부드러운 톤 커브
    scene.view_settings.look = "AgX - Punchy"    # 채도 살짝 부스트
    scene.view_settings.exposure = 0.8
    scene.view_settings.gamma = 1.05

    # 부드러운 대형 에어리어 라이트 (키)
    key_data = bpy.data.lights.new("Key", "AREA")
    key_data.size = 8.0
    key_data.energy = 140
    key_data.color = (1.0, 0.94, 0.86)
    key = bpy.data.objects.new("Key", key_data)
    key.location = (3.5, -3.0, 4.5)
    key.rotation_euler = (math.radians(58), 0, math.radians(-38))
    scene.collection.objects.link(key)

    # 소프트 필 (창문 방향 산란광)
    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = 10.0
    fill_data.energy = 45
    fill_data.color = (0.85, 0.88, 1.0)
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = (-4.0, 3.5, 3.0)
    fill.rotation_euler = (math.radians(52), 0, math.radians(142))
    scene.collection.objects.link(fill)

    # 웜 앰비언트
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.95, 0.88, 0.80, 1.0)
    bg.inputs["Strength"].default_value = 0.50
    scene.world = world

    # 직교 아이소 카메라 (요 45도, 피치 30도)
    cam_data = bpy.data.cameras.new("IsoCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 4.4
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    focus = Vector((FW/2, FH/2, 0.30))
    d = 12.0
    az = math.radians(45)  # NE에서 봄
    el = math.radians(30)
    cam.location = focus + Vector((d*math.cos(el)*math.cos(az), -d*math.cos(el)*math.sin(az), d*math.sin(el)))
    # look_at: direction 벡터로 회전 계산
    direction = focus - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    return scene


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    build_floor()
    build_walls()
    build_window()
    build_bed()
    build_wardrobe()
    build_nightstand()
    build_lamp()
    build_rug()
    build_plant()
    build_picture()
    build_shelf()
    build_char()

    scene = setup_render()
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("BENCH_DONE", OUT)


if __name__ == "__main__":
    main()
