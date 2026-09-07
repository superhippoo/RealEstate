# -*- coding: utf-8 -*-
"""
3D 전환용 에셋 내보내기 — Godot 실시간 3D 파이프라인 (제안 A)
1) CC0 가구(Quaternius FBX) → 팔레트 재색상 + 실측 스케일 정규화 → glTF
2) SD 캐릭터(절차적) → 걷기/idle 애니메이션 키프레임 → glTF
출력: game/assets/models/*.glb
실행: blender -b --factory-startup -P export_gltf.py
"""
import bpy
import math
import os
from mathutils import Vector

MODELS = r"D:\works\realestate\game\tools\models\furniture_cc0\Furniture Pack by @Quaternius\FBX"
OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "models"))

PAL = {
    "wood_l": (0.850, 0.610, 0.380),
    "wood_d": (0.610, 0.380, 0.215),
    "linen":  (0.960, 0.920, 0.850),
    "cream":  (0.970, 0.900, 0.780),
    "sage":   (0.560, 0.660, 0.420),
    "plant":  (0.180, 0.420, 0.240),
    "brass":  (0.72, 0.55, 0.35),
}

FURNITURE = [
    ("bed_single", "Bed", {"fit_xy": (1.05, 2.05)}),
    ("sofa_two", "SofaDouble", {"fit_xy": (1.50, 0.78)}),
    ("chair_basic", "ChairCushioned", {"fit_xy": (0.50, 0.50)}),
    ("desk_table", "Table", {"fit_xy": (1.25, 0.55)}),
    ("floor_lamp", "Lamp", {"height": 1.30}),
    ("plant_monstera", "Plant", {"height": 0.62}),
]

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
                b.inputs["Roughness"].default_value = 0.65
                b.inputs["Specular IOR Level"].default_value = 0.2
                break


def export_furniture():
    for out_id, fbx, mode in FURNITURE:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=os.path.join(MODELS, fbx + ".fbx"))
        recolor()
        meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
        minv = Vector((1e9,) * 3); maxv = Vector((-1e9,) * 3)
        for o in meshes:
            for c in o.bound_box:
                w = o.matrix_world @ Vector(c)
                minv.x = min(minv.x, w.x); minv.y = min(minv.y, w.y); minv.z = min(minv.z, w.z)
                maxv.x = max(maxv.x, w.x); maxv.y = max(maxv.y, w.y); maxv.z = max(maxv.z, w.z)
        d = maxv - minv
        if "fit_xy" in mode:
            tx, ty = mode["fit_xy"]
            s = max(min(tx / max(d.x, 1e-6), ty / max(d.y, 1e-6)),
                    min(ty / max(d.x, 1e-6), tx / max(d.y, 1e-6)))
        else:
            s = mode["height"] / max(d.z, 1e-6)
        for o in meshes:
            o.scale = o.scale * s
        bpy.context.view_layer.update()
        minv = Vector((1e9,) * 3); maxv = Vector((-1e9,) * 3)
        for o in meshes:
            for c in o.bound_box:
                w = o.matrix_world @ Vector(c)
                minv.x = min(minv.x, w.x); minv.y = min(minv.y, w.y); minv.z = min(minv.z, w.z)
                maxv.x = max(maxv.x, w.x); maxv.y = max(maxv.y, w.y); maxv.z = max(maxv.z, w.z)
        for o in meshes:
            o.location.x -= (minv.x + maxv.x) / 2
            o.location.y -= (minv.y + maxv.y) / 2
            o.location.z -= minv.z
        bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, out_id + ".glb"))
        print("GLTF", out_id, "ok")


# ---------------------------------------------------------------- SD 캐릭터 + 애니메이션
def build_char():
    skin = mat("skin", (0.980, 0.850, 0.740))
    hair = mat("hair", (0.220, 0.160, 0.120))
    top = mat("top", (0.940, 0.760, 0.560))
    bottom = mat("bottom", (0.380, 0.420, 0.520))
    shoe = mat("shoe", (0.35, 0.28, 0.24))
    eye_m = mat("eye", (0.13, 0.11, 0.10))

    hip = empty("hip", (0, 0, 0.34))
    sph("c_hips", 0.15, (0, 0, -0.02), bottom, hip, scale=(1.0, 0.9, 0.8))
    torso = empty("torso", (0, 0, 0.06), parent=hip)
    sph("c_body", 0.175, (0, 0.004, 0.10), top, torso, scale=(1.0, 0.92, 1.15))
    head = empty("head", (0, 0.01, 0.28), parent=torso)
    sph("c_head", 0.21, (0, 0, 0.10), skin, head)
    sph("c_hair_cap", 0.222, (0, -0.012, 0.115), hair, head, scale=(1.0, 1.0, 0.94))
    sph("c_hair_back", 0.17, (0, -0.11, 0.10), hair, head, scale=(1.3, 0.85, 1.2))
    sph("c_hair_bun", 0.10, (0, -0.14, 0.31), hair, head)
    box("c_fringe", (0.33, 0.09, 0.10), (0, 0.165, 0.150), hair, head, rot=(math.radians(16), 0, 0))
    for sx, nm in ((-1, "l"), (1, "r")):
        sph("c_eye_" + nm, 0.048, (sx * 0.078, 0.185, 0.115), eye_m, head)
        sph("c_hi_" + nm, 0.014, (sx * 0.090, 0.212, 0.132), mat("hi_" + nm, (1, 1, 1)), head)
        sph("c_blush_" + nm, 0.032, (sx * 0.140, 0.15, 0.080), mat("bl_" + nm, (0.97, 0.62, 0.55)), head,
            scale=(1.1, 0.5, 0.7))
    sph("c_mouth", 0.022, (0, 0.207, 0.030), mat("mouth", (0.75, 0.42, 0.38)), head, scale=(1.4, 0.55, 0.8))
    parts = {}
    for sx, nm in ((-1, "l"), (1, "r")):
        sh = empty("sh_" + nm, (sx * 0.195, 0, 0.14), parent=torso)
        box("c_arm_" + nm, (0.058, 0.058, 0.16), (0, 0, -0.075), top, sh)
        sph("c_hand_" + nm, 0.038, (0, 0.01, -0.165), skin, sh)
        parts["sh_" + nm] = sh
        hp = empty("hp_" + nm, (sx * 0.072, 0, -0.20), parent=hip)
        box("c_leg_" + nm, (0.075, 0.065, 0.13), (0, 0, 0.025), bottom, hp)
        box("c_shoe_" + nm, (0.095, 0.14, 0.058), (0, 0.030, -0.105), shoe, hp)
        parts["hp_" + nm] = hp
    parts.update({"hip": hip, "torso": torso, "head": head})
    return parts


def mat(name, color):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = 0.65
    return m


def empty(name, loc, parent=None):
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 0.05
    e.location = loc
    if parent:
        e.parent = parent
    bpy.context.scene.collection.objects.link(e)
    return e


def sph(name, r, loc, m, parent, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=24, ring_count=14)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    o.parent = parent
    return o


def box(name, size, loc, m, parent, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    b = o.modifiers.new("b", "BEVEL")
    b.width = 0.02
    b.segments = 4
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    o.parent = parent
    return o


def make_anim(parts):
    """걷기(20프레임 루프) + idle(40프레임) 오브젝트 키프레임 애니메이션"""
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 60

    def rot(obj, frame, euler):
        obj.rotation_euler = euler
        obj.keyframe_insert(data_path="rotation_euler", frame=frame)

    def pos(obj, frame, v):
        obj.location = v
        obj.keyframe_insert(data_path="location", frame=frame)

    # Walk: frames 1-20 loop — 팔다리 스윙
    walk = bpy.data.actions.new("walk")
    for obj_name in ("sh_l", "sh_r", "hp_l", "hp_r", "torso"):
        ad = parts[obj_name].animation_data_create()
        ad.action = walk
    s = 0.55
    for f, sign in ((1, 1), (11, -1), (21, 1)):
        rot(parts["hp_l"], f, (sign * s, 0, 0))
        rot(parts["hp_r"], f, (-sign * s, 0, 0))
        rot(parts["sh_l"], f, (-sign * s * 0.7, 0, 0.10))
        rot(parts["sh_r"], f, (sign * s * 0.7, 0, -0.10))
        rot(parts["torso"], f, (0.05, 0, 0))

    # Idle: frames 31-60 — 살짝 숨쉬기(토르소/헤드 bob)
    idle = bpy.data.actions.new("idle")
    for obj_name in ("torso", "head"):
        ad = parts[obj_name].animation_data_create()
        ad.action = idle
    base_t = parts["torso"].location.copy()
    base_h = parts["head"].location.copy()
    for f, dz in ((31, 0.0), (46, 0.012), (61, 0.0)):
        pos(parts["torso"], f, base_t + Vector((0, 0, dz)))
        pos(parts["head"], f, base_h + Vector((0, 0, dz)))
    print("ANIMS created")


def export_char():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    parts = build_char()
    make_anim(parts)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "char.glb"),
                              export_animations=True,
                              export_animation_mode="ACTIONS")
    print("GLTF char ok")


def main():
    os.makedirs(OUT, exist_ok=True)
    export_furniture()
    export_char()
    print("GLTF_ALL_DONE")


if __name__ == "__main__":
    main()
