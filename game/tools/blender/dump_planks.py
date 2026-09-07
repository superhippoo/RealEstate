import bpy, os, importlib.util
from mathutils import Vector
spec = importlib.util.spec_from_file_location("roommod", os.path.join(os.path.dirname(__file__), "generate_room_v3.py"))
rm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rm)
bpy.ops.wm.read_factory_settings(use_empty=True)
rm.build_room()
planks = [o for o in bpy.context.scene.objects if o.name.startswith("plank")]
print("PLANK_COUNT", len(planks))
xs = []; ys = []
for o in planks:
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        xs.append(w.x); ys.append(w.y)
print("PLANK_EXTENT x", round(min(xs),2), "-", round(max(xs),2), " y", round(min(ys),2), "-", round(max(ys),2))
names = sorted(planks, key=lambda o: o.name)
print("SAMPLE_NAMES", [o.name for o in names[:8]], "...", [o.name for o in names[-4:]])
