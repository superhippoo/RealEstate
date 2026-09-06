# -*- coding: utf-8 -*-
"""
CC0 가구(Quaternius, opengameart) 스프라이트 렌더 — 그리드 정합 파이프라인
- FBX import → 실측 치수로 스케일 정규화(그리드 셀=25cm) → 지면 정렬 → 중심 원점
- 재질을 프로젝트 팔레트로 재색상(스타일 통일)
- 30도/315도 아이소 카메라 + 소프트 2점 조명 + shadow catcher (v3 파이프라인 동일)
- 출력 {id}_{rot}.png → 이후 flop_sprites.py --skip room
실행: blender -b --factory-startup -P generate_cc0_sprites.py
"""
import bpy
import math
import os
from mathutils import Vector

MODELS = r"D:\works\realestate\game\tools\models\furniture_cc0\Furniture Pack by @Quaternius\FBX"
OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output"))
RES = 1024

PAL = {
    "wood_l": (0.850, 0.610, 0.380),
    "wood_d": (0.610, 0.380, 0.215),
    "linen":  (0.960, 0.920, 0.850),
    "cream":  (0.970, 0.900, 0.780),
    "sage":   (0.560, 0.660, 0.420),
    "plant":  (0.180, 0.420, 0.240),
    "brass":  (0.72, 0.55, 0.35),
}

# out_id, fbx 이름, 정규화 방식
#  fit_xy=(가로m,세로m): 두 축 모두 target 이하가 되는 최대 균일 스케일
#  height=h: 높이를 h로
ASSETS = [
    ("bed_single", "Bed", {"fit_xy": (1.05, 2.05)}),
    ("sofa_two", "SofaDouble", {"fit_xy": (1.50, 0.78)}),
    ("chair_basic", "ChairCushioned", {"fit_xy": (0.50, 0.50)}),
    ("floor_lamp", "Lamp", {"height": 1.30}),
    ("plant_monstera", "Plant", {"height": 0.62}),
]

# 재질명 키워드 → 팔레트 재색상 (스타일 통일)
MAT_MAP = [
    ("dark", PAL["wood_d"]),
    ("wood", PAL["wood_l"]),
    ("sheet", PAL["linen"]),
    ("white", PAL["linen"]),
    ("sofa", PAL["cream"]),
    ("red", (0.860, 0.470, 0.340)),
    ("green", PAL["plant"]),
    ("metal", PAL["brass"]),
    ("top", PAL["cream"]),
    ("vase", (0.830, 0.500, 0.360)),
    ("brown", PAL["wood_d"]),
]


def recolor():
    for m in bpy.data.materials:
        if not m.use_nodes:
            m.use_nodes = True
        b = m.node_tree.nodes.get("Principled BSDF")
        if b is None:
            continue
        name = m.name.lower()
        for key, col in MAT_MAP:
            if key in name:
                b.inputs["Base Color"].default_value = (*col, 1.0)
                b.inputs["Roughness"].default_value = 0.6
                b.inputs["Specular IOR Level"].default_value = 0.15
                break


def normalize(mode):
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    if not meshes:
        return False
    minv = Vector((1e9,) * 3)
    maxv = Vector((-1e9,) * 3)
    for o in meshes:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            minv.x = min(minv.x, w.x); minv.y = min(minv.y, w.y); minv.z = min(minv.z, w.z)
            maxv.x = max(maxv.x, w.x); maxv.y = max(maxv.y, w.y); maxv.z = max(maxv.z, w.z)
    d = maxv - minv
    if "fit_xy" in mode:
        tx, ty = mode["fit_xy"]
        o1 = min(tx / max(d.x, 1e-6), ty / max(d.y, 1e-6))
        o2 = min(ty / max(d.x, 1e-6), tx / max(d.y, 1e-6))
        s = max(o1, o2)  # 긴 축을 긴 축에: 실제 크기감 유지
    else:
        s = mode["height"] / max(d.z, 1e-6)
    root = bpy.data.objects.new("Root", None)
    bpy.context.scene.collection.objects.link(root)
    for o in meshes:
        o.scale = o.scale * s
        bpy.context.view_layer.update()
        o.parent = root
    bpy.context.view_layer.update()
    # 지면 정렬 + xy 중심 (스케일 반영 후 재계산)
    minv = Vector((1e9,) * 3); maxv = Vector((-1e9,) * 3)
    for o in meshes:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            minv.x = min(minv.x, w.x); minv.y = min(minv.y, w.y); minv.z = min(minv.z, w.z)
            maxv.x = max(maxv.x, w.x); maxv.y = max(maxv.y, w.y); maxv.z = max(maxv.z, w.z)
    cx = (minv.x + maxv.x) / 2
    cy = (minv.y + maxv.y) / 2
    for o in meshes:
        o.location.x -= cx
        o.location.y -= cy
        o.location.z -= minv.z
    return root


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 96
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = RES
    scene.render.resolution_y = RES
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = 1.0

    key_data = bpy.data.lights.new("Key", "AREA")
    key_data.size = 7.0
    key_data.energy = 125
    key_data.color = (1.0, 0.95, 0.88)
    key = bpy.data.objects.new("Key", key_data)
    key.location = (3.0, -3.2, 4.2)
    key.rotation_euler = (math.radians(62), 0, math.radians(-40))
    scene.collection.objects.link(key)

    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = 9.0
    fill_data.energy = 60
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
    focus_z = 0.45
    d = 10.0
    az = math.radians(315)
    el = math.radians(30.0)
    cam.location = (d * math.cos(el) * math.cos(az), -d * math.cos(el) * math.sin(az), d * math.sin(el) + focus_z)
    direction = Vector((0, 0, focus_z)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, -0.002))
    sc = bpy.context.active_object
    sc.name = "ShadowCatcher"
    sc.is_shadow_catcher = True
    return scene


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for out_id, fbx_name, mode in ASSETS:
        path = os.path.join(MODELS, fbx_name + ".fbx")
        print("CC0", out_id, "import...")
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=path)
        recolor()
        root = normalize(mode)
        if not root:
            print("CC0", out_id, "NO_MESH")
            continue
        scene = setup_scene()
        bpy.context.view_layer.update()
        for rot in (0, 90, 180, 270):
            root.rotation_euler = (0, 0, math.radians(rot))
            bpy.context.view_layer.update()
            scene.render.filepath = os.path.join(OUT_DIR, f"{out_id}_{rot}.png")
            bpy.ops.render.render(write_still=True)
        print("CC0", out_id, "DONE")
    print("CC0_ALL_DONE")


if __name__ == "__main__":
    main()
