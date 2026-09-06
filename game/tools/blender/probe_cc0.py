import bpy, os, sys
from mathutils import Vector
MODELS = r"D:\works\realestate\game\tools\models\furniture_cc0\Furniture Pack by @Quaternius\FBX"
targets = ["Bed", "BedKing", "Sofa", "SofaDouble", "ChairCushioned", "Chair", "Table", "CoffeeTable", "Lamp", "Plant", "Stool", "Vase"]
for name in targets:
    path = os.path.join(MODELS, name + ".fbx")
    if not os.path.exists(path):
        print(name, "MISSING")
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.fbx(filepath=path)
    except Exception as e:
        print(name, "IMPORT_FAIL", e)
        continue
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    if not meshes:
        print(name, "NO_MESH")
        continue
    minv = Vector((1e9, 1e9, 1e9)); maxv = Vector((-1e9, -1e9, -1e9))
    mats = set()
    for o in meshes:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            minv.x = min(minv.x, w.x); minv.y = min(minv.y, w.y); minv.z = min(minv.z, w.z)
            maxv.x = max(maxv.x, w.x); maxv.y = max(maxv.y, w.y); maxv.z = max(maxv.z, w.z)
        for m in o.data.materials:
            if m: mats.add(m.name)
    d = maxv - minv
    print(f"{name}: dims=({d.x:.2f}, {d.y:.2f}, {d.z:.2f})m mats={sorted(mats)[:4]}")
