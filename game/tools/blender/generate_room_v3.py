# -*- coding: utf-8 -*-
"""
방 셸 v4 — 벤치마크 승인 레시피 이식 (청크 플랭크/피치 벽/소프트 GI/스타일 주방)
게임 그리드 16x12셀(4x3m) 코너 정합 유지(30도/315도 + flop).
실행: blender -b --factory-startup -P generate_room_v3.py
"""
import bpy
import json
import math
import os
from mathutils import Vector

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output"))
RES = 2048
CELL = 0.25
GW, GH = 16, 12
ROOM_W, ROOM_H = GW * CELL, GH * CELL
WALL_H = 1.15
WALL_T = 0.08

PAL = {
    "wood":    (0.820, 0.540, 0.310),
    "wood_l":  (0.850, 0.610, 0.380),
    "wood_d":  (0.610, 0.380, 0.215),
    "wall":    (1.000, 0.820, 0.700),
    "wall_d":  (0.930, 0.720, 0.620),
    "cream":   (0.970, 0.900, 0.780),
    "sage":    (0.560, 0.660, 0.420),
    "plant":   (0.180, 0.420, 0.240),
    "pot":     (0.830, 0.500, 0.360),
    "terracotta": (0.860, 0.470, 0.340),
}


def flat(color, rough=0.62, bump=0.0):
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
    mix.inputs["Fac"].default_value = 0.14
    nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(rgb.outputs[0], mix.inputs["Color1"])
    nt.links.new(ramp.outputs["Color"], mix.inputs["Color2"])
    nt.links.new(mix.outputs["Color"], b.inputs["Base Color"])
    return m


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


def rcyl(name, r, depth, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=28)
    o = bpy.context.active_object
    o.name = name
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    return o


def build_room():
    import random
    rng = random.Random(11)
    rbox("base", (ROOM_W + 0.03, ROOM_H + 0.03, 0.05), (ROOM_W / 2, ROOM_H / 2, -0.0252), flat(PAL["wood_d"], 0.85), bevel=0.015)
    # 청크 플랭크: 폭 0.5m(2셀), 두께 0.045, 큰 색 변주, 명확한 이음
    pw = 0.5
    for row in range(math.ceil(ROOM_H / pw) + 1):
        y0 = row * pw
        x = -(row % 2) * 0.9
        while x < ROOM_W:
            x0, x1 = max(x, 0.0), min(x + 1.35, ROOM_W)
            if x1 - x0 > 0.1:
                v = rng.uniform(-0.06, 0.06)
                c = (min(1, PAL["wood"][0] + v), min(1, PAL["wood"][1] + v * 0.8), min(1, PAL["wood"][2] + v * 0.6))
                rbox("plank_%d_%d" % (row, int(x0 * 10)), (x1 - x0 - 0.004, pw - 0.005, 0.045),
                     ((x0 + x1) / 2, y0 + pw / 2, 0.024), wood(c), bevel=0.010)
            x += 1.35
    # 벽 2면 (피치) + 청크 몰딩
    w1 = flat(PAL["wall"], 0.9)
    w2 = flat((0.97, 0.79, 0.68), 0.9)
    rbox("wall_y0", (ROOM_W + WALL_T, WALL_T, WALL_H), (ROOM_W / 2, -WALL_T / 2, WALL_H / 2), w1, bevel=0.02)
    rbox("wall_x0", (WALL_T, ROOM_H + WALL_T, WALL_H), (-WALL_T / 2, ROOM_H / 2, WALL_H / 2), w2, bevel=0.02)
    bb = flat(PAL["wood_l"], 0.6)
    rbox("bb_y0", (ROOM_W, 0.05, 0.13), (ROOM_W / 2, 0.026, 0.065), bb, bevel=0.014)
    rbox("bb_x0", (0.05, ROOM_H, 0.13), (0.026, ROOM_H / 2, 0.065), bb, bevel=0.014)
    tr = flat(PAL["wall_d"], 0.85)
    rbox("tr_y0", (ROOM_W + WALL_T, 0.12, 0.05), (ROOM_W / 2, -WALL_T / 2, WALL_H - 0.025), tr, bevel=0.012)
    rbox("tr_x0", (0.12, ROOM_H + WALL_T, 0.05), (-WALL_T / 2, ROOM_H / 2, WALL_H - 0.025), tr, bevel=0.012)
    build_window()
    build_kitchen()


def build_window():
    """-X 벽 중앙: 청크 프레임 + 유리 + 2단 커튼"""
    wy0, wy1 = ROOM_H * 0.30, ROOM_H * 0.72
    wz0, wz1 = 0.40, 1.02
    glow = rbox("win_sky", (0.02, wy1 - wy0, wz1 - wz0), (-WALL_T - 0.10, (wy0 + wy1) / 2, (wz0 + wz1) / 2),
                flat((1.0, 0.96, 0.90), 1.0), bevel=0.008)
    b = glow.data.materials[0].node_tree.nodes.get("Principled BSDF")
    b.inputs["Emission Color"].default_value = (1.0, 0.95, 0.85, 1)
    b.inputs["Emission Strength"].default_value = 3.5
    glass = flat((0.88, 0.92, 0.96), 0.05)
    glass.node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value = 0.25
    glass.blend_method = "BLEND"
    rbox("win_glass", (0.01, wy1 - wy0 - 0.07, wz1 - wz0 - 0.07), (-WALL_T + 0.006, (wy0 + wy1) / 2, (wz0 + wz1) / 2), glass, bevel=0.004)
    fr = wood(PAL["wood_l"])
    rbox("win_top", (0.07, wy1 - wy0 + 0.10, 0.06), (-WALL_T + 0.025, (wy0 + wy1) / 2, wz1), fr, bevel=0.010)
    rbox("win_bot", (0.07, wy1 - wy0 + 0.10, 0.06), (-WALL_T + 0.025, (wy0 + wy1) / 2, wz0 - 0.02), fr, bevel=0.010)
    rbox("win_left", (0.07, 0.06, wz1 - wz0), (-WALL_T + 0.025, wy0 - 0.02, (wz0 + wz1) / 2), fr, bevel=0.010)
    rbox("win_right", (0.07, 0.06, wz1 - wz0), (-WALL_T + 0.025, wy1 + 0.02, (wz0 + wz1) / 2), fr, bevel=0.010)
    rbox("win_mid", (0.06, 0.035, wz1 - wz0 - 0.07), (-WALL_T + 0.025, (wy0 + wy1) / 2, (wz0 + wz1) / 2), fr, bevel=0.008)
    cur = flat((0.965, 0.945, 0.905), 0.95)
    for i, wy in enumerate((wy0 - 0.11, wy1 + 0.11)):
        c = rbox("curtain_%d" % i, (0.028, 0.17, wz1 - wz0 + 0.18), (-WALL_T + 0.055, wy, (wz0 + wz1) / 2 - 0.02), cur, sub=3)
        tex = bpy.data.textures.new("cw", type="CLOUDS")
        dis = c.modifiers.new("d", "DISPLACE")
        dis.texture = tex
        dis.strength = 0.008


def build_kitchen():
    """붙박이 주방 (스타일: 평색 청크) — -Y 벽"""
    KD = 0.60
    cab_h = 0.80
    m_wood = wood(PAL["wood"])
    m_wood_d = wood(PAL["wood_d"])
    counter = flat((0.95, 0.90, 0.83), 0.30)
    cream = flat((0.95, 0.90, 0.84), 0.75)
    sage = flat(PAL["sage"], 0.85)
    for i in range(4):
        seg_w = 0.76
        x0 = 0.06 + i * (seg_w + 0.015)
        if x0 + seg_w > 3.20:
            seg_w = 3.20 - x0
        rbox("kcab_%d" % i, (seg_w, KD, cab_h - 0.10), (x0 + seg_w / 2, KD / 2 + 0.02, (cab_h - 0.10) / 2 + 0.07), m_wood, bevel=0.018)
        rbox("khandle_%d" % i, (seg_w - 0.14, 0.02, 0.022), (x0 + seg_w / 2, KD + 0.032, cab_h - 0.17), m_wood_d, bevel=0.006)
    rbox("kcounter", (3.30, KD + 0.07, 0.05), (3.30 / 2, KD / 2 + 0.02, cab_h + 0.025), counter, bevel=0.012)
    # 싱크(청크 사각 보울) + 수도꼭지 + 소품
    rbox("ksink", (0.34, 0.28, 0.03), (0.55, KD / 2 + 0.02, cab_h + 0.035), flat((0.80, 0.82, 0.84), 0.25), bevel=0.012)
    rcyl("kfaucet", 0.014, 0.16, (0.55, KD - 0.06, cab_h + 0.11), flat((0.72, 0.74, 0.76), 0.3))
    rbox("kboard", (0.32, 0.22, 0.02), (1.50, KD / 2 + 0.02, cab_h + 0.055), wood((0.78, 0.72, 0.60)), bevel=0.010)
    rbox("kcoffee", (0.15, 0.13, 0.21), (2.30, KD / 2 - 0.01, cab_h + 0.13), flat((0.30, 0.28, 0.26), 0.4), bevel=0.012)
    rcyl("kmug", 0.035, 0.075, (2.10, KD / 2, cab_h + 0.04), flat(PAL["terracotta"]))
    # 백스플래시(세이지 타일) + 상부(크림) + 청크 후드
    rbox("ktile", (3.30, 0.025, 0.44), (3.30 / 2, 0.042, cab_h + 0.28), sage, bevel=0.004)
    rbox("kupper", (1.30, 0.32, 0.56), (0.72, 0.18, cab_h + 0.28 + 0.56 / 2 + 0.24), cream, bevel=0.014)
    rbox("khood", (0.52, 0.34, 0.36), (2.02, 0.19, cab_h + 0.52), cream, bevel=0.016)
    rbox("kduct", (0.20, 0.20, 0.32), (2.02, 0.19, cab_h + 0.88), cream, bevel=0.012)
    # 냉장고(크림, 청크)
    rbox("kfridge", (0.62, 0.66, 1.68), (3.25 - 0.33, 0.34, 1.68 / 2), cream, bevel=0.024)
    rbox("kf_h1", (0.025, 0.05, 0.52), (2.96, 0.70, 1.28), flat((0.75, 0.72, 0.68), 0.3), bevel=0.008)
    rbox("kf_h2", (0.025, 0.05, 0.36), (2.96, 0.70, 0.74), flat((0.75, 0.72, 0.68), 0.3), bevel=0.008)
    # 펜던트 2 (따뜻한 글로브)
    for i, px in enumerate((1.05, 1.72)):
        g = rcyl("kpend_%d" % i, 0.075, 0.05, (px, KD / 2 + 0.02, cab_h + 0.70), flat((1.0, 0.96, 0.88), 0.5))
        gb = g.data.materials[0].node_tree.nodes.get("Principled BSDF")
        gb.inputs["Emission Color"].default_value = (1.0, 0.90, 0.70, 1)
        gb.inputs["Emission Strength"].default_value = 1.6
        rcyl("kwire_%d" % i, 0.004, 0.45, (px, KD / 2 + 0.02, cab_h + 0.95), flat((0.2, 0.2, 0.2)))
    # 대형 몬스테라
    rcyl("kplant_pot", 0.15, 0.27, (3.58, 0.55, 0.135), flat(PAL["pot"], 0.75))
    rcyl("kplant_rim", 0.18, 0.05, (3.58, 0.55, 0.29), flat(PAL["pot"], 0.75))
    for i, (ang, h) in enumerate([(0.0, 0.55), (1.2, 0.75), (2.4, 0.6), (3.6, 0.8), (4.8, 0.55), (5.7, 0.45)]):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.15, location=(3.58 + math.cos(ang) * 0.10, 0.55 + math.sin(ang) * 0.07, 0.34 + h * 0.55))
        leaf = bpy.context.active_object
        leaf.name = "kleaf_%d" % i
        leaf.scale = (0.42, 1.5, 0.62)
        leaf.rotation_euler = (0.0, 0.10, ang)
        for p in leaf.data.polygons:
            p.use_smooth = True
        leaf.data.materials.append(flat(PAL["plant"], 0.6))


def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 256
    scene.cycles.use_denoising = False
    scene.render.film_transparent = False
    scene.render.resolution_x = RES
    scene.render.resolution_y = RES
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = 1.15

    key_data = bpy.data.lights.new("Key", "AREA")
    key_data.size = 9.0
    key_data.energy = 220
    key_data.color = (1.0, 0.95, 0.88)
    key = bpy.data.objects.new("Key", key_data)
    key.location = (4.0, -4.0, 5.0)
    key.rotation_euler = (math.radians(62), 0, math.radians(-40))
    scene.collection.objects.link(key)

    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = 11.0
    fill_data.energy = 95
    fill_data.color = (0.92, 0.90, 1.0)
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = (-5.0, 4.5, 3.5)
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
    cam_data.ortho_scale = 6.4
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return scene, cam


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    scene, cam = setup_scene()
    build_room()
    focus = Vector((ROOM_W / 2, ROOM_H / 2, 0.25))
    d = 12.0
    az = math.radians(315)
    el = math.radians(30.0)
    cam.location = focus + Vector((d * math.cos(el) * math.cos(az), -d * math.cos(el) * math.sin(az), d * math.sin(el)))
    direction = focus - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    scene.render.filepath = os.path.join(OUT_DIR, "room_shell.png")
    bpy.ops.render.render(write_still=True)

    from bpy_extras.object_utils import world_to_camera_view
    corners = {}
    for key, (cx, cy) in {"c00": (0, 0), "cW0": (ROOM_W, 0), "c0H": (0, ROOM_H), "cWH": (ROOM_W, ROOM_H)}.items():
        v = world_to_camera_view(scene, cam, Vector((cx, cy, 0)))
        corners[key] = [round(v.x * RES, 2), round((1.0 - v.y) * RES, 2)]
    manifest = {"resolution": RES, "ortho_scale": 6.4, "grid": [GW, GH], "corners_img_px": corners, "wall_height_m": WALL_H}
    with open(os.path.join(OUT_DIR, "room_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("ROOM_V4_DONE", json.dumps(corners))


if __name__ == "__main__":
    main()
