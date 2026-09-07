import bpy, math, os, sys
sys.path.insert(0, '.')
# generate_room_v3의 build_room 재사용
import importlib.util
spec = importlib.util.spec_from_file_location("roommod", os.path.join(os.path.dirname(__file__), "generate_room_v3.py"))
rm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rm)

bpy.ops.wm.read_factory_settings(use_empty=True)
rm.build_room()
scene = bpy.context.scene
# 진짜 탑다운 카메라
cam_data = bpy.data.cameras.new("Top")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 4.6
cam = bpy.data.objects.new("Top", cam_data)
scene.collection.objects.link(cam)
cam.location = (2.0, 1.5, 10.0)
cam.rotation_euler = (0, 0, 0)
scene.camera = cam
# 균일 조명
w = bpy.data.worlds.new("W")
w.use_nodes = True
w.node_tree.nodes.get("Background").inputs["Strength"].default_value = 1.2
scene.world = w
scene.render.engine = 'CYCLES'
scene.cycles.samples = 32
scene.render.film_transparent = False
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.view_settings.view_transform = 'Standard'
scene.render.filepath = os.path.abspath("../blender_output/debug_topdown.png")
bpy.ops.render.render(write_still=True)
print("TOPDOWN_DONE")
