# -*- coding: utf-8 -*-
"""
방 셸(바닥 플랭크 + 벽 2면 + 걸레받이 + 창문 + 커튼) 렌더러
- 게임 그리드 16x12셀(4m x 3m)과 정확히 정렬: 코너 이미지좌표를 manifest에 기록
- 가구 스프라이트와 동일 2:1 아이소 카메라, Filmic, 3점 조명
실행: blender -b --factory-startup -P generate_room_v2.py
"""
import bpy
import json
import math
import os
from mathutils import Vector

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output"))
RES = 2048
CELL = 0.25
GW, GH = 16, 12          # 그리드 셀 수
ROOM_W, ROOM_H = GW * CELL, GH * CELL
WALL_H = 1.15
WALL_T = 0.08

PALETTE = {
    "wood":      (0.847, 0.659, 0.424),
    "wood_mid":  (0.780, 0.590, 0.370),
    "wood_dark": (0.640, 0.462, 0.262),
    "wall":      (0.937, 0.878, 0.745),
    "wall2":     (0.905, 0.838, 0.694),
    "trim":      (0.824, 0.741, 0.588),
    "glass":     (0.85, 0.90, 0.96),
    "curtain":   (0.965, 0.945, 0.905),
}


def mat_base(color, rough=0.6, bump_scale=0.0):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    if bump_scale > 0:
        nt = m.node_tree
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 60.0
        noise.inputs["Detail"].default_value = 8.0
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nm.inputs["Strength"].default_value = bump_scale
        height_in = None
        for inp in nm.inputs:
            if inp.name in ("Height", "Color") and inp.type == "RGBA":
                height_in = inp
                break
        if height_in is not None:
            nt.links.new(noise.outputs["Fac"], height_in)
        nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def mat_wood(color, scale=18.0, rough=0.45):
    m = mat_base(color, rough)
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    rgb = nt.nodes.new("ShaderNodeRGB")
    rgb.outputs[0].default_value = (*color, 1.0)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 6.0
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (1.0, 8.0, 1.0)
    coord = nt.nodes.new("ShaderNodeTexCoord")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.42
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


def box(name, size, loc, material, bevel=0.0, rot=(0, 0, 0), sub=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    if sub:
        s = o.modifiers.new("sub", "SUBSURF")
        s.levels = sub
    if bevel:
        b = o.modifiers.new("bevel", "BEVEL")
        b.width = bevel
        b.segments = 4
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(material)
    return o


def build_room():
    import random
    rng = random.Random(20260906)
    # 어두운 베이스 슬래브(플랭크 사이 틈)
    box("base_slab", (ROOM_W + 0.02, ROOM_H + 0.02, 0.02), (ROOM_W / 2, ROOM_H / 2, -0.012),
        mat_base((0.30, 0.22, 0.15), 0.9))
    # 플랭크: x축 방향, 4셀(1m) 길이, 행별 스태거
    plank_len = 4 * CELL
    for row in range(GH):
        stagger = (row * 2) % 4
        x = -stagger * CELL
        while x < ROOM_W:
            x0 = max(x, 0.0)
            x1 = min(x + plank_len, ROOM_W)
            if x1 - x0 > 0.05:
                v = rng.uniform(-0.055, 0.055)
                warm = rng.uniform(-0.02, 0.02)
                col = (PALETTE["wood"][0] + v + warm, PALETTE["wood"][1] + v, PALETTE["wood"][2] + v - warm)
                m = mat_wood(tuple(max(0.1, c) for c in col), scale=rng.uniform(14, 22),
                             rough=rng.uniform(0.38, 0.55))
                z_off = rng.uniform(0.000, 0.0025)  # 미세 단차
                box("plank_%d_%d" % (row, int(x0 * 100)), (x1 - x0 - 0.006, CELL - 0.008, 0.018),
                    ((x0 + x1) / 2, (row + 0.5) * CELL, 0.009 + z_off), m, bevel=0.004)
            x += plank_len
    # 벽 2면 (-Y측: gy=0 변 / -X측: gx=0 변)
    wall_m = mat_base(PALETTE["wall"], 0.85, bump_scale=0.25)
    wall_m2 = mat_base(PALETTE["wall2"], 0.85, bump_scale=0.25)
    box("wall_y0", (ROOM_W + WALL_T, WALL_T, WALL_H), (ROOM_W / 2, -WALL_T / 2, WALL_H / 2), wall_m, bevel=0.01)
    box("wall_x0", (WALL_T, ROOM_H + WALL_T, WALL_H), (-WALL_T / 2, ROOM_H / 2, WALL_H / 2), wall_m2, bevel=0.01)
    # 걸레받이 + 상단 몰딩
    trim_m = mat_wood(PALETTE["wood_dark"], scale=26.0)
    box("bb_y0", (ROOM_W, 0.035, 0.10), (ROOM_W / 2, 0.018, 0.05), trim_m, bevel=0.008)
    box("bb_x0", (0.035, ROOM_H, 0.10), (0.018, ROOM_H / 2, 0.05), trim_m, bevel=0.008)
    box("trim_y0", (ROOM_W, 0.03, 0.03), (ROOM_W / 2, -WALL_T - 0.005, WALL_H - 0.015), mat_base(PALETTE["trim"], 0.7), bevel=0.006)
    box("trim_x0", (0.03, ROOM_H, 0.03), (-WALL_T - 0.005, ROOM_H / 2, WALL_H - 0.015), mat_base(PALETTE["trim"], 0.7), bevel=0.006)
    build_window()
    build_kitchen()


def build_window():
    """-X 벽(걸그리드 gx=0 변) 중앙: 프레임 + 유리 + 시어 커튼 + 외부광"""
    wy0, wy1 = ROOM_H * 0.28, ROOM_H * 0.72
    wz0, wz1 = 0.42, 1.02
    frame_m = mat_wood(PALETTE["wood_dark"], scale=30.0)
    # 뒤 유리광(외부 하늘)
    sky = box("sky_glow", (0.02, wy1 - wy0, wz1 - wz0), (-WALL_T - 0.12, (wy0 + wy1) / 2, (wz0 + wz1) / 2),
              mat_base((1.0, 0.97, 0.90), 1.0))
    b = sky.data.materials[0].node_tree.nodes.get("Principled BSDF")
    b.inputs["Emission Color"].default_value = (1.0, 0.96, 0.86, 1)
    b.inputs["Emission Strength"].default_value = 4.0
    # 유리
    glass = mat_base(PALETTE["glass"], 0.05)
    glass.node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value = 0.25
    glass.blend_method = "BLEND"
    box("glass", (0.01, wy1 - wy0 - 0.06, wz1 - wz0 - 0.06), (-WALL_T + 0.005, (wy0 + wy1) / 2, (wz0 + wz1) / 2), glass)
    # 프레임(사변 + 중간 몰딩)
    fw, fh = 0.05, 0.05
    box("win_top", (0.06, wy1 - wy0 + 0.08, fh), (-WALL_T + 0.02, (wy0 + wy1) / 2, wz1), frame_m, bevel=0.008)
    box("win_bot", (0.06, wy1 - wy0 + 0.08, fh), (-WALL_T + 0.02, (wy0 + wy1) / 2, wz0 - 0.02), frame_m, bevel=0.008)
    box("win_left", (0.06, fw, wz1 - wz0), (-WALL_T + 0.02, wy0 - 0.02, (wz0 + wz1) / 2), frame_m, bevel=0.008)
    box("win_right", (0.06, fw, wz1 - wz0), (-WALL_T + 0.02, wy1 + 0.02, (wz0 + wz1) / 2), frame_m, bevel=0.008)
    box("win_mid", (0.05, 0.03, wz1 - wz0 - 0.06), (-WALL_T + 0.02, (wy0 + wy1) / 2, (wz0 + wz1) / 2), frame_m, bevel=0.006)
    # 시어 커튼(양쪽, 살짝 주름)
    cur = mat_base(PALETTE["curtain"], 0.95, bump_scale=0.9)
    for i, wy in enumerate((wy0 - 0.10, wy1 + 0.10)):
        c = box("curtain_%d" % i, (0.025, 0.16, wz1 - wz0 + 0.16), (-WALL_T + 0.05, wy, (wz0 + wz1) / 2 - 0.02), cur, sub=3)
        tex = bpy.data.textures.new("cur_wave", type="CLOUDS")
        dis = c.modifiers.new("displace", "DISPLACE")
        dis.texture = tex
        dis.strength = 0.008




def build_kitchen():
    """붙박이 주방(고정설비, 06_house_grid: 욕실/주방은 고정용도) - -Y 벽(gy=0 변)을 따라 L자"""
    wood_m = mat_wood(PALETTE["wood_mid"], scale=20.0, rough=0.5)
    wood_d = mat_wood(PALETTE["wood_dark"], scale=24.0)
    counter_m = mat_base((0.93, 0.88, 0.80), 0.30, bump_scale=0.15)  # 인공대리석
    cream_m = mat_base((0.945, 0.905, 0.855), 0.7)
    steel = mat_base((0.75, 0.76, 0.78), 0.25)
    tile = mat_base((0.95, 0.93, 0.89), 0.25, bump_scale=0.4)
    KD = 0.62  # 주방 깊이

    # --- 하부 캐비닛 (x 0~3.2m, -Y 벽 따라) ---
    cab_h = 0.82
    for i in range(4):
        seg_w = 0.78
        x0 = 0.05 + i * (seg_w + 0.015)
        if x0 + seg_w > 3.25:
            seg_w = 3.25 - x0
        box("kcab_%d" % i, (seg_w, KD, cab_h - 0.10), (x0 + seg_w / 2, KD / 2 + 0.02, (cab_h - 0.10) / 2 + 0.08), wood_m, bevel=0.012)
        # 슬릿 손잡이
        box("khandle_%d" % i, (seg_w - 0.12, 0.015, 0.018), (x0 + seg_w / 2, KD + 0.028, cab_h - 0.16), wood_d, bevel=0.004)
    # 카운터
    box("kcounter", (3.35, KD + 0.06, 0.045), (3.35 / 2, KD / 2 + 0.02, cab_h), counter_m, bevel=0.010)
    # 싱크(원형 보울) + 도마 + 커피머신
    bpy.ops.mesh.primitive_cylinder_add(radius=0.16, depth=0.02, location=(0.55, KD / 2 + 0.02, cab_h + 0.012))
    sink = bpy.context.active_object
    sink.name = "ksink"
    sink.data.materials.append(steel)
    box("kboard", (0.34, 0.24, 0.018), (1.55, KD / 2 + 0.02, cab_h + 0.022), mat_wood((0.78, 0.72, 0.60), scale=40.0), bevel=0.008)
    box("kcoffee", (0.16, 0.14, 0.24), (2.35, KD / 2 - 0.02, cab_h + 0.13), mat_base((0.25, 0.24, 0.23), 0.4), bevel=0.010)
    box("kmug_a", (0.05, 0.05, 0.06), (2.12, KD / 2, cab_h + 0.03), mat_base((0.85, 0.50, 0.38), 0.6), bevel=0.006)
    box("kplate", (0.14, 0.14, 0.012), (1.15, KD / 2 + 0.05, cab_h + 0.02), mat_base((0.96, 0.94, 0.90), 0.3), bevel=0.004, rot=(0, 0, 0.5))

    # --- 백스플래시 타일 ---
    box("ktile", (3.35, 0.02, 0.52), (3.35 / 2, 0.045, cab_h + 0.27), tile)
    # --- 상부 캐비닛(크림) x 일부 + 후드 ---
    box("kupper", (1.35, 0.34, 0.62), (0.75, 0.19, cab_h + 0.27 + 0.62 / 2 + 0.28), cream_m, bevel=0.012)
    hood = box("khood", (0.55, 0.36, 0.42), (2.05, 0.20, cab_h + 0.55), steel, bevel=0.014)
    box("khood_duct", (0.22, 0.22, 0.35), (2.05, 0.20, cab_h + 0.95), steel, bevel=0.010)
    # --- 냉장고(끝에, 크림 프런치도어) ---
    box("kfridge", (0.62, 0.66, 1.72), (3.25 - 0.31, 0.35, 1.72 / 2), cream_m, bevel=0.020)
    box("kf_handle1", (0.02, 0.04, 0.55), (2.95, 0.69, 1.30), mat_base((0.72, 0.70, 0.66), 0.3), bevel=0.006)
    box("kf_handle2", (0.02, 0.04, 0.38), (2.95, 0.69, 0.75), mat_base((0.72, 0.70, 0.66), 0.3), bevel=0.006)
    # --- 펜던트 조명 2(글로브) + 에미션 ---
    for i, px in enumerate((1.05, 1.75)):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.075, location=(px, KD / 2 + 0.02, cab_h + 0.72))
        g = bpy.context.active_object
        g.name = "kpendant_%d" % i
        gm = mat_base((1.0, 0.96, 0.88), 0.5)
        gb = gm.node_tree.nodes.get("Principled BSDF")
        gb.inputs["Emission Color"].default_value = (1.0, 0.90, 0.70, 1)
        gb.inputs["Emission Strength"].default_value = 1.2
        g.data.materials.append(gm)
        for p in g.data.polygons:
            p.use_smooth = True
        bpy.ops.mesh.primitive_cylinder_add(radius=0.004, depth=0.5, location=(px, KD / 2 + 0.02, cab_h + 1.0))
        w = bpy.context.active_object
        w.data.materials.append(mat_base((0.2, 0.2, 0.2), 0.4))
    # --- 대형 몬스테라(주방 끝 코너) ---
    rc = rcyl_k("kplant_pot", 0.14, 0.30, (3.55, 0.5, 0.15), mat_base((0.80, 0.55, 0.45), 0.7))
    for i in range(7):
        ang = i * 0.9
        leaf = sp_k("kleaf_%d" % i, 0.11, (3.55 + math.cos(ang) * 0.16, 0.5 + math.sin(ang) * 0.10, 0.52 + i * 0.045),
                    mat_base((0.22, 0.42, 0.25), 0.55))
        leaf.scale = (0.45, 1.5, 0.75)
        leaf.rotation_euler = (0, 0, ang)


def rcyl_k(name, r, depth, loc, m):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, vertices=24)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(m)
    return o


def sp_k(name, r, loc, m):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=24, ring_count=14)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(m)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 128
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = RES
    scene.render.resolution_y = RES
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Filmic"
    try:
        scene.view_settings.look = "Medium High Contrast"
    except Exception:
        pass
    scene.view_settings.exposure = 1.32
    # 가구 스프라이트와 동일 조명 레시피
    sun = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "SUN"))
    sun.data.energy = 3.5
    sun.data.angle = math.radians(16)
    sun.data.color = (1.0, 0.93, 0.82)
    sun.rotation_euler = (math.radians(66), 0, math.radians(35))
    scene.collection.objects.link(sun)
    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = 6.0
    fill_data.energy = 90
    fill_data.color = (0.85, 0.90, 1.0)
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = (-4.5, 4.5, 2.8)
    fill.rotation_euler = (math.radians(50), 0, math.radians(-45))
    scene.collection.objects.link(fill)
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.98, 0.955, 0.90, 1.0)
    bg.inputs["Strength"].default_value = 0.42
    scene.world = world
    cam_data = bpy.data.cameras.new("IsoCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 6.4
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return scene, cam


def place_camera(cam, focus):
    d = 12.0
    az = math.radians(315)  # 코너 정면 시점 — 렌더 후 수포반전(flop)하면 게임 그리드 관례와 일치
    el = math.radians(30.0)  # 2:1 다이아몬드(기울기 0.5) 정확 고도각
    cam.location = Vector((focus.x + d * math.cos(el) * math.cos(az),
                           focus.y - d * math.cos(el) * math.sin(az),
                           focus.z + d * math.sin(el)))
    direction = focus - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    scene, cam = setup_scene()
    build_room()
    focus = Vector((ROOM_W / 2, ROOM_H / 2, 0.25))
    place_camera(cam, focus)
    bpy.context.view_layer.update()
    scene.render.filepath = os.path.join(OUT_DIR, "room_shell.png")
    bpy.ops.render.render(write_still=True)

    # 그리드 코너 4개의 이미지 px 좌표 기록 (Godot 정렬용)
    from bpy_extras.object_utils import world_to_camera_view
    corners = {}
    for key, (cx, cy) in {"c00": (0, 0), "cW0": (ROOM_W, 0), "c0H": (0, ROOM_H), "cWH": (ROOM_W, ROOM_H)}.items():
        v = world_to_camera_view(scene, cam, Vector((cx, cy, 0)))
        corners[key] = [round(v.x * RES, 2), round((1.0 - v.y) * RES, 2)]
    manifest = {
        "resolution": RES,
        "ortho_scale": cam.data.ortho_scale,
        "grid": [GW, GH],
        "corners_img_px": corners,
        "wall_height_m": WALL_H,
    }
    with open(os.path.join(OUT_DIR, "room_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("ROOM_DONE", json.dumps(corners))


if __name__ == "__main__":
    main()
