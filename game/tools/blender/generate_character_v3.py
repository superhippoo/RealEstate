# -*- coding: utf-8 -*-
"""
캐릭터 v4 — 5두신 스타일라이즈드 휴먼(컨셉 기준 재설계)
- 관절 그룹 구조: hip > torso > head / arm_l(shoulder>elbow) / leg_l(hip>knee)
- 포즈: idle/걷기2프레임/앉기(의자)/앉기(소파)/눕기/타이핑
- 클레이 렌더: 무광 스킨+니트+슬랙스, 큰 눈+단발머리
실행: blender -b --factory-startup -P generate_character_v3.py [-- --only <pose>]
"""
import bpy
import json
import math
import os
from mathutils import Vector

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output"))
RES = 1024

PALETTE = {
    "skin":   (0.965, 0.835, 0.730),
    "hair":   (0.180, 0.130, 0.100),
    "knit":   (0.930, 0.878, 0.790),
    "slack":  (0.420, 0.360, 0.290),
    "shoe":   (0.300, 0.260, 0.220),
    "eye":    (0.12, 0.10, 0.09),
    "sclera": (0.98, 0.97, 0.95),
    "lip":    (0.80, 0.52, 0.45),
}

JOINTS = {}
JOINT_BASE = {}


def save_joint_base():
    JOINT_BASE.clear()
    for k, j in JOINTS.items():
        JOINT_BASE[k] = j.location.copy()


def _mat(color, rough=0.65):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    return m


def _smooth(o):
    for p in o.data.polygons:
        p.use_smooth = True


def _sub(o, lv=2):
    s = o.modifiers.new("s", "SUBSURF")
    s.levels = lv
    s.render_levels = lv


def _bev(o, w=0.012):
    b = o.modifiers.new("b", "BEVEL")
    b.width = w
    b.segments = 4


def part(name, kind, size, loc, m, parent, bevel=0.012, sub=2, rot=(0, 0, 0), scale=(1, 1, 1)):
    if kind == "sphere":
        bpy.ops.mesh.primitive_uv_sphere_add(radius=size[0], location=loc, segments=32, ring_count=20)
    elif kind == "cyl":
        bpy.ops.mesh.primitive_cylinder_add(radius=size[0], depth=size[1], location=loc, vertices=24)
    else:
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    if kind == "box":
        o.scale = size
    elif kind == "sphere":
        o.scale = scale
    if sub:
        _sub(o, sub)
    if bevel and kind == "box":
        _bev(o, bevel)
    _smooth(o)
    o.data.materials.append(m)
    o.parent = parent
    o.matrix_parent_inverse = parent.matrix_world.inverted()
    return o


def joint(name, loc, parent):
    j = bpy.data.objects.new(name, None)
    j.empty_display_size = 0.05
    j.location = loc
    j.parent = parent
    j.matrix_parent_inverse = parent.matrix_world.inverted()
    bpy.context.collection.objects.link(j)
    return j


# ---------------------------------------------------------------- 모델 (키 ~1.62m, 5두신)
def build_human(root):
    skin = _mat(PALETTE["skin"], 0.55)
    hair = _mat(PALETTE["hair"], 0.60)
    knit = _mat(PALETTE["knit"], 0.92)
    slack = _mat(PALETTE["slack"], 0.85)
    shoe = _mat(PALETTE["shoe"], 0.55)
    eye = _mat(PALETTE["eye"], 0.25)
    lip = _mat(PALETTE["lip"], 0.6)

    hip = joint("hip", (0, 0, 0.86), root)
    # 골반+엉덩이
    part("pelvis", "sphere", (0.115,), (0, 0, -0.02), slack, hip, scale=(1.0, 0.85, 0.75))
    # 상체(니트): 가슴~배
    torso = joint("torso", (0, 0, 0.10), hip)
    part("chest", "sphere", (0.125,), (0, 0.004, 0.16), knit, torso, scale=(1.0, 0.80, 1.25))
    part("belly", "sphere", (0.105,), (0, 0, 0.03), knit, torso, scale=(1.0, 0.85, 1.0))
    # 목
    part("neck", "cyl", (0.030, 0.07), (0, 0, 0.32), skin, torso)
    # 머리(5두신: 두부 지름 ~0.21)
    head = joint("head", (0, 0.004, 0.42), torso)
    part("skull", "sphere", (0.105,), (0, 0, 0.085), skin, head, scale=(0.92, 0.94, 1.0))
    # 헤어: 캡 + 옆볼륨 + 뒷머리 + 앞머리
    part("hair_cap", "sphere", (0.112,), (0, -0.008, 0.095), hair, head, scale=(0.95, 1.0, 0.98))
    part("hair_back", "sphere", (0.085,), (0, -0.055, 0.02), hair, head, scale=(1.15, 0.75, 1.3))
    part("hair_side_l", "sphere", (0.048,), (-0.088, -0.01, 0.015), hair, head, scale=(0.55, 0.9, 1.5))
    part("hair_side_r", "sphere", (0.048,), (0.088, -0.01, 0.015), hair, head, scale=(0.55, 0.9, 1.5))
    part("fringe", "box", (0.150, 0.045, 0.045), (0, 0.083, 0.115), hair, head, bevel=0.02, rot=(math.radians(14), 0, 0))
    # 얼굴: 눈(흰자+동공), 눈썹, 코, 입, 볼
    for sx, nm in ((-1, "l"), (1, "r")):
        part("sclera_" + nm, "sphere", (0.020,), (sx * 0.038, 0.085, 0.088), _mat(PALETTE["sclera"], 0.2), head, scale=(1, 0.65, 1))
        part("pupil_" + nm, "sphere", (0.0115,), (sx * 0.040, 0.098, 0.086), eye, head)
        part("brow_" + nm, "box", (0.030, 0.008, 0.010), (sx * 0.040, 0.088, 0.115), hair, head, bevel=0.004)
        bsh = part("blush_" + nm, "sphere", (0.016,), (sx * 0.066, 0.070, 0.062), _mat((0.95, 0.66, 0.58), 0.8), head, scale=(1.2, 0.5, 0.8))
    part("nose", "sphere", (0.012,), (0, 0.100, 0.070), skin, head, scale=(0.8, 1.1, 0.9))
    part("mouth", "box", (0.026, 0.006, 0.008), (0, 0.097, 0.040), lip, head, bevel=0.003)
    # 팔: 어깨>팔꿈치>손 (니트 소매+손)
    for sx, nm in ((-1, "l"), (1, "r")):
        sh = joint("sh_" + nm, (sx * 0.125, 0, 0.26), torso)
        part("uarm_" + nm, "cyl", (0.034, 0.20), (0, 0, -0.10), knit, sh)
        el = joint("el_" + nm, (0, 0, -0.20), sh)
        part("farm_" + nm, "cyl", (0.028, 0.19), (0, 0, -0.095), knit, el)
        part("hand_" + nm, "sphere", (0.033,), (0, 0, -0.20), skin, el, scale=(0.85, 0.8, 1.15))
        JOINTS["sh_" + nm] = sh
        JOINTS["el_" + nm] = el
    # 다리: 힙>무릎+발
    for sx, nm in ((-1, "l"), (1, "r")):
        hp = joint("hp_" + nm, (sx * 0.062, 0, -0.03), hip)
        part("thigh_" + nm, "cyl", (0.048, 0.34), (0, 0, -0.17), slack, hp)
        kn = joint("kn_" + nm, (0, 0, -0.34), hp)
        part("calf_" + nm, "cyl", (0.038, 0.34), (0, 0, -0.17), slack, kn)
        part("shoe_" + nm, "box", (0.072, 0.16, 0.055), (0, 0.035, -0.365), shoe, kn, bevel=0.02)
        JOINTS["hp_" + nm] = hp
        JOINTS["kn_" + nm] = kn
    JOINTS["hip"] = hip
    JOINTS["torso"] = torso
    JOINTS["head"] = head


# ---------------------------------------------------------------- 포즈
def reset_pose():
    for k, j in JOINTS.items():
        j.rotation_euler = (0, 0, 0)
        if k in JOINT_BASE:
            j.location = JOINT_BASE[k].copy()


def pose_idle():
    reset_pose()
    JOINTS["sh_l"].rotation_euler = (0.06, 0, 0.10)
    JOINTS["sh_r"].rotation_euler = (0.06, 0, -0.10)
    JOINTS["el_l"].rotation_euler = (-0.18, 0, 0)
    JOINTS["el_r"].rotation_euler = (-0.18, 0, 0)


def pose_walk(phase):
    pose_idle()
    s = 0.55 if phase == 0 else -0.55
    JOINTS["hp_l"].rotation_euler = (s, 0, 0)
    JOINTS["hp_r"].rotation_euler = (-s, 0, 0)
    JOINTS["kn_l"].rotation_euler = (max(0.0, -s * 0.9), 0, 0)
    JOINTS["kn_r"].rotation_euler = (max(0.0, s * 0.9), 0, 0)
    JOINTS["sh_l"].rotation_euler = (-s * 0.7, 0, 0.10)
    JOINTS["sh_r"].rotation_euler = (s * 0.7, 0, -0.10)
    JOINTS["torso"].rotation_euler = (0.05, 0, 0)


def pose_sit_chair():
    """책상 의자: 무릎 90도, 상체 약간 앞으로"""
    reset_pose()
    JOINTS["hip"].location = (0, 0, 0.50)
    for nm in ("l", "r"):
        JOINTS["hp_" + nm].rotation_euler = (math.radians(-78), 0, 0)
        JOINTS["kn_" + nm].rotation_euler = (math.radians(78), 0, 0)
        JOINTS["sh_" + nm].rotation_euler = (math.radians(-38), 0, 0.08 if nm == "l" else -0.08)
        JOINTS["el_" + nm].rotation_euler = (math.radians(-42), 0, 0)
    JOINTS["torso"].rotation_euler = (0.10, 0, 0)


def pose_sit_sofa():
    """소파: 무릎 100도, 상체 뒤로 기대"""
    reset_pose()
    JOINTS["hip"].location = (0, 0, 0.44)
    for nm in ("l", "r"):
        JOINTS["hp_" + nm].rotation_euler = (math.radians(-62), 0, 0)
        JOINTS["kn_" + nm].rotation_euler = (math.radians(66), 0, 0)
        JOINTS["sh_" + nm].rotation_euler = (math.radians(-18), 0, 0.16 if nm == "l" else -0.16)
        JOINTS["el_" + nm].rotation_euler = (math.radians(-55), 0, 0)
    JOINTS["torso"].rotation_euler = (-0.06, 0, 0)


def pose_lie():
    """침대: 바로 눕기"""
    reset_pose()
    JOINTS["hip"].location = (0, 0, 0.22)
    JOINTS["torso"].rotation_euler = (math.radians(90), 0, 0)
    JOINTS["head"].rotation_euler = (math.radians(-14), 0, 0)
    for nm in ("l", "r"):
        JOINTS["hp_" + nm].rotation_euler = (0, 0, 0.06 if nm == "l" else -0.06)
        JOINTS["sh_" + nm].rotation_euler = (0, 0, 0.5 if nm == "l" else -0.5)


def pose_typing():
    """책상에서 타이핑/필기"""
    pose_sit_chair()
    for nm in ("l", "r"):
        JOINTS["sh_" + nm].rotation_euler = (math.radians(-62), 0, 0.10 if nm == "l" else -0.10)
        JOINTS["el_" + nm].rotation_euler = (math.radians(-70), 0, 0)
    JOINTS["head"].rotation_euler = (0.22, 0, 0)
    JOINTS["torso"].rotation_euler = (0.14, 0, 0)


# ---------------------------------------------------------------- 씬
def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 160
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

    sun = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "SUN"))
    sun.data.energy = 3.5
    sun.data.angle = math.radians(16)
    sun.data.color = (1.0, 0.93, 0.82)
    sun.rotation_euler = (math.radians(66), 0, math.radians(35))
    scene.collection.objects.link(sun)
    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = 4.0
    fill_data.energy = 60
    fill_data.color = (0.85, 0.90, 1.0)
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = (-3.5, 3.5, 2.2)
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
    cam_data.ortho_scale = 3.2
    cam = bpy.data.objects.new("IsoCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    place_camera(cam, 0.45)
    return scene, cam


def place_camera(cam, focus_z):
    d = 10.0
    az = math.radians(315)
    el = math.radians(30.0)
    cam.location = Vector((d * math.cos(el) * math.cos(az), -d * math.cos(el) * math.sin(az), d * math.sin(el) + focus_z))
    direction = Vector((0, 0, focus_z)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    scene, cam = setup_scene()
    root = bpy.data.objects.new("Root", None)
    bpy.context.scene.collection.objects.link(root)
    build_human(root)
    save_joint_base()

    sets = []
    for d in range(4):
        sets.append((pose_walk, "char_walk_%d_0" % d, d * 90, 0))
        sets.append((pose_walk, "char_walk_%d_1" % d, d * 90, 1))
        sets.append((pose_idle, "char_idle_%d" % d, d * 90, None))
    sets.append((pose_sit_chair, "char_sit_0", 0, None))
    sets.append((pose_sit_chair, "char_sit_270", 270, None))
    sets.append((pose_sit_sofa, "char_sit_sofa_0", 0, None))
    sets.append((pose_sit_sofa, "char_sit_sofa_270", 270, None))
    sets.append((pose_typing, "char_typing_270", 270, None))
    sets.append((pose_lie, "char_lie_0", 0, None))
    sets.append((pose_lie, "char_lie_180", 180, None))

    for pose_fn, name, rot, phase in sets:
        if phase is None:
            pose_fn()
        else:
            pose_fn(phase)
        root.rotation_euler = (0, 0, math.radians(rot))
        bpy.context.view_layer.update()
        scene.render.filepath = os.path.join(OUT_DIR, name + ".png")
        bpy.ops.render.render(write_still=True)
        print("CHAR4", name)
    print("CHAR4_DONE")


if __name__ == "__main__":
    main()
