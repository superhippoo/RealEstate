# -*- coding: utf-8 -*-
"""
절차적 아이소메트릭 스프라이트 생성기 v2
- 컨셉 팔레트(크림/허니우드/세이지/테라코타) 적용
- 가구 5종 x 4방향 + 캐릭터(걷기/idle/앉기/눕기) 스프라이트
- Cycles + shadow catcher, 투명 배경 PNG
- 전 렌더 공유 ortho scale → 상대 크기 보존
- 2:1 아이소 카메라(고도 atan(0.5)) + px/m 캘리브레이션 → manifest.json
실행: blender -b --factory-startup -P generate_sprites.py
"""
import bpy
import json
import math
import os
from mathutils import Vector

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output"))
RES = 1024

PALETTE = {
    "wood":       (0.847, 0.659, 0.424),
    "wood_dark":  (0.725, 0.541, 0.310),
    "cream":      (0.949, 0.902, 0.816),
    "sage":       (0.612, 0.686, 0.384),
    "white":      (0.980, 0.980, 0.960),
    "charcoal":   (0.290, 0.267, 0.235),
    "screen_glow":(0.15, 0.30, 0.38),
    "terracotta": (0.851, 0.490, 0.353),
    "skin":       (0.960, 0.820, 0.700),
    "hair":       (0.240, 0.200, 0.170),
    "top":        (0.384, 0.455, 0.596),
    "bottom":     (0.420, 0.400, 0.370),
}


# ---------------------------------------------------------------- 유틸
def mat(color, rough=0.65):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    return m


def _parent_to_root(o, root):
    o.parent = root
    o.matrix_parent_inverse = root.matrix_world.inverted()


def box(name, size, loc, color, rough=0.65, root=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    o.data.materials.append(mat(color, rough))
    if root:
        _parent_to_root(o, root)
    return o


def cyl(name, r, depth, loc, color, root=None):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat(color))
    if root:
        _parent_to_root(o, root)
    return o


def sphere(name, r, loc, color, root=None):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=24, ring_count=16)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat(color))
    bpy.ops.object.shade_smooth()
    if root:
        _parent_to_root(o, root)
    return o


# ---------------------------------------------------------------- 가구 (Root 원점 = footprint 중심)
def build_bed(root):
    W, L, H = 1.0, 2.0, 0.12
    box("bed_frame", (W, L, H), (0, 0, H / 2), PALETTE["wood"], root=root)
    box("bed_mattress", (W - 0.10, L - 0.10, 0.16), (0, 0, H + 0.08), PALETTE["cream"], root=root)
    box("bed_pillow", (W - 0.24, 0.35, 0.07), (0, -L / 2 + 0.28, H + 0.19), PALETTE["white"], root=root)
    box("bed_blanket", (W - 0.08, L * 0.45, 0.05), (0, L * 0.22, H + 0.19), PALETTE["sage"], root=root)
    box("bed_headboard", (W, 0.08, 0.5), (0, -L / 2 + 0.04, 0.25), PALETTE["wood_dark"], root=root)


def build_sofa(root):
    W, D, H = 1.5, 0.75, 0.35
    box("sofa_base", (W, D, H), (0, 0, H / 2), PALETTE["cream"], root=root)
    box("sofa_seat", (W - 0.12, D - 0.16, 0.14), (0, 0.02, H + 0.07), PALETTE["cream"], root=root)
    box("sofa_back", (W, 0.16, 0.38), (0, -D / 2 + 0.08, H + 0.19), PALETTE["cream"], root=root)
    box("sofa_arm_l", (0.14, D, 0.24), (-W / 2 + 0.07, 0, H + 0.12), PALETTE["cream"], root=root)
    box("sofa_arm_r", (0.14, D, 0.24), (W / 2 - 0.07, 0, H + 0.12), PALETTE["cream"], root=root)
    box("sofa_cushion", (0.5, 0.4, 0.08), (0, 0.05, H + 0.18), PALETTE["terracotta"], root=root)


def build_desk(root):
    W, D, H = 1.25, 0.5, 0.72
    box("desk_top", (W, D, 0.05), (0, 0, H), PALETTE["wood"], root=root)
    for x in (-W / 2 + 0.06, W / 2 - 0.06):
        for y in (-D / 2 + 0.05, D / 2 - 0.05):
            cyl("desk_leg", 0.02, H, (x, y, H / 2), PALETTE["wood_dark"], root=root)
    box("desk_monitor", (0.45, 0.03, 0.28), (0, -D / 2 + 0.15, H + 0.30), PALETTE["charcoal"], root=root)
    box("desk_monitor_stand", (0.10, 0.08, 0.16), (0, -D / 2 + 0.15, H + 0.13), PALETTE["charcoal"], root=root)


def build_chair(root):
    S, H = 0.5, 0.45
    box("chair_seat", (S - 0.06, S - 0.06, 0.06), (0, 0, H), PALETTE["wood"], root=root)
    box("chair_back", (S - 0.06, 0.05, 0.5), (0, -S / 2 + 0.05, H + 0.25), PALETTE["wood_dark"], root=root)
    for x in (-1, 1):
        for y in (-1, 1):
            cyl("chair_leg", 0.018, H, (x * (S / 2 - 0.07), y * (S / 2 - 0.07), H / 2),
                PALETTE["wood_dark"], root=root)


def build_tv(root):
    W, D = 1.0, 0.5
    box("tv_stand", (W, D, 0.35), (0, 0, 0.175), PALETTE["wood_dark"], root=root)
    box("tv_panel", (W - 0.18, 0.05, 0.62), (0, 0, 0.71), PALETTE["charcoal"], root=root)
    box("tv_screen", (W - 0.24, 0.055, 0.55), (0, 0.006, 0.71), PALETTE["screen_glow"], rough=0.15, root=root)
    box("tv_foot", (0.2, 0.16, 0.04), (0, 0, 0.37), PALETTE["charcoal"], root=root)


FURNITURE = {
    "bed_single": build_bed,
    "sofa_two": build_sofa,
    "desk_small": build_desk,
    "chair_basic": build_chair,
    "tv_43": build_tv,
}


# ---------------------------------------------------------------- 캐릭터
CHAR_PARTS = {}


def build_character(root):
    sphere("char_body", 0.16, (0, 0, 0.34), PALETTE["top"], root=root)
    sphere("char_head", 0.155, (0, 0, 0.62), PALETTE["skin"], root=root)
    sphere("char_hair", 0.16, (0, -0.015, 0.66), PALETTE["hair"], root=root)
    CHAR_PARTS["arm_l"] = box("char_arm_l", (0.055, 0.055, 0.20), (-0.20, 0, 0.36), PALETTE["top"], root=root)
    CHAR_PARTS["arm_r"] = box("char_arm_r", (0.055, 0.055, 0.20), (0.20, 0, 0.36), PALETTE["top"], root=root)
    CHAR_PARTS["leg_l"] = box("char_leg_l", (0.07, 0.07, 0.22), (-0.08, 0, 0.11), PALETTE["bottom"], root=root)
    CHAR_PARTS["leg_r"] = box("char_leg_r", (0.07, 0.07, 0.22), (0.08, 0, 0.11), PALETTE["bottom"], root=root)


REST_POSE = {"arm_l": ((-0.20, 0, 0.36)), "arm_r": ((0.20, 0, 0.36)),
             "leg_l": ((-0.08, 0, 0.11)), "leg_r": ((0.08, 0, 0.11))}


def pose_neutral():
    for k, o in CHAR_PARTS.items():
        o.rotation_euler = (0, 0, 0)
        o.location = Vector(REST_POSE[k])


def pose_walk(phase):
    pose_neutral()
    s = 0.5 if phase == 0 else -0.5
    CHAR_PARTS["leg_l"].rotation_euler = (s, 0, 0)
    CHAR_PARTS["leg_r"].rotation_euler = (-s, 0, 0)
    CHAR_PARTS["arm_l"].rotation_euler = (-s * 0.7, 0, 0)
    CHAR_PARTS["arm_r"].rotation_euler = (s * 0.7, 0, 0)


def pose_sit():
    pose_neutral()
    for k in ("leg_l", "leg_r"):
        CHAR_PARTS[k].rotation_euler = (math.radians(-70), 0, 0)
        CHAR_PARTS[k].location += Vector((0, 0.07, -0.02))
    for k in ("arm_l", "arm_r"):
        CHAR_PARTS[k].rotation_euler = (math.radians(-25), 0, 0)


def pose_lie():
    pose_neutral()
    for k in ("arm_l", "arm_r"):
        CHAR_PARTS[k].rotation_euler = (0, 0, math.radians(75))
    for k in ("leg_l", "leg_r"):
        CHAR_PARTS[k].rotation_euler = (0, 0, 0)


# ---------------------------------------------------------------- 씬
def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = RES
    scene.render.resolution_y = RES
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"

    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 2.6
    sun.data.angle = math.radians(12)
    sun.rotation_euler = (math.radians(55), 0, math.radians(30))
    scene.collection.objects.link(sun)

    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (1.0, 0.98, 0.92, 1.0)
    bg.inputs["Strength"].default_value = 0.55
    scene.world = world

    cam_data = bpy.data.cameras.new("IsoCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 3.2  # 전 렌더 공유 (bed 대각 포함 마진)
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    place_camera(cam, 0.35)
    return scene, cam


def place_camera(cam, focus_z):
    """2:1 아이소: 방위 45도, 고도 atan(0.5) = 26.565도"""
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
    root.empty_display_size = 0.3
    return root


def clear_root(root):
    for o in list(root.children):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.objects.remove(root, do_unlink=True)
    CHAR_PARTS.clear()


def render(scene, fname):
    scene.render.filepath = os.path.join(OUT_DIR, fname)
    bpy.ops.render.render(write_still=True)


def calibrate_px_per_meter(scene, cam):
    """원점에서 X/Y축으로 1m 떨어진 점의 화면 투영 거리(px)로 px_per_meter 계산."""
    from bpy_extras.object_utils import world_to_camera_view

    def s2p(v):
        return Vector((v.x * RES, (1.0 - v.y) * RES))

    origin = Vector((0, 0, 0))
    px_o = s2p(world_to_camera_view(scene, cam, origin))
    px_x1 = s2p(world_to_camera_view(scene, cam, origin + Vector((1, 0, 0))))
    px_y1 = s2p(world_to_camera_view(scene, cam, origin + Vector((0, 1, 0))))
    return (px_x1 - px_o).length, (px_y1 - px_o).length


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    scene, cam = setup_scene()
    add_shadow_catcher()

    ppm_x, ppm_y = calibrate_px_per_meter(scene, cam)
    manifest = {
        "resolution": RES,
        "ortho_scale": cam.data.ortho_scale,
        "px_per_meter_x": ppm_x,
        "px_per_meter_y": ppm_y,
        # Godot: 1m = 4셀, 셀 폭 128px → 인게인 1m 폭 = 512px
        "godot_scale": 512.0 / ((ppm_x + ppm_y) * 0.5),
        "sprites": {},
    }

    # --- 가구 4방향 ---
    for def_id, builder in FURNITURE.items():
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

    # --- 캐릭터 ---
    root = new_root()
    build_character(root)

    def char_set(pose_fn, base_name, rotations):
        files = []
        for rot in rotations:
            pose_fn()
            root.rotation_euler = (0, 0, math.radians(rot))
            bpy.context.view_layer.update()
            fname = f"{base_name}_{rot}.png"
            render(scene, fname)
            files.append(fname)
        return files

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
    char_set(pose_sit, "char_sit", (0, 270))
    char_set(pose_lie, "char_lie", (0, 180))
    clear_root(root)

    manifest["sprites"]["char"] = {"type": "character"}
    with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("SPRITES_DONE", json.dumps({k: manifest[k] for k in ("px_per_meter_x", "px_per_meter_y", "godot_scale")}))


if __name__ == "__main__":
    main()
