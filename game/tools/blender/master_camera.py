# -*- coding: utf-8 -*-
"""
MASTER CAMERA — 모든 에셋이 공유하는 단일 렌더링 규격
이 파일이 유일한 Camera/Lighting/Material 기준이다.
다른 스크립트는 이 파일을 import해서 사용한다.

원칙:
- yaw/pitch/ortho_scale/resolution을 절대 하드코딩하지 않는다
- 이 파일에서 정의한 값을 모든 에셋이 동일하게 사용한다
- 캘리브레이션 결과(px_per_meter)도 이 파일에서 측정한다
"""
import bpy
import math
import os
from mathutils import Vector

# ================================================================ 규격 (유일 소스)
SPEC = {
    "yaw_deg": 45.0,          # 방위각 (NE에서 조망)
    "pitch_deg": 30.0,        # 고도각 (2:1 isometric 검증됨)
    "ortho_scale": 3.2,       # 가구 렌더용 (3.2m 가시범위)
    "room_ortho_scale": 6.4,  # 방 shell 렌더용 (6.4m)
    "resolution": 1024,       # 가구 sprite 해상도
    "room_resolution": 2048,  # 방 shell 해상도
    "samples": 128,
    "use_denoise": False,     # alpha 노이즈 방지를 위해 OFF
    "film_transparent": True, # 가구용 (방은 별도)
    # 조명 (레퍼런스 정량 매칭: 채도 0.42, R/B 1.68, 그림자75%/하이라이트125%)
    "key_size": 7.0,
    "key_energy": 200,          # 더 강하게 → 하이라이트 상향
    "key_color": (1.00, 0.88, 0.72),  # 더 따뜻하게 (R/B ↑)
    "key_rot": (58, 0, -38),
    "key_pos": (3.0, -3.2, 4.2),
    "fill_size": 12.0,          # 더 크게 → 부드러운 그림자
    "fill_energy": 35,          # 약하게 → 그림자 더 깊게
    "fill_color": (0.82, 0.86, 1.0),
    "fill_rot": (55, 0, 140),
    "fill_pos": (-3.5, 3.0, 3.0),
    "world_color": (1.00, 0.85, 0.70),   # 따뜻한 앰비언트
    "world_strength": 0.35,      # 낮게 → 그림자 대비 증가
    # 재질 기본값 (채도 상향)
    "default_roughness": 0.68,
    "default_specular": 0.35,   # 하이라이트 강화
}


def apply_camera(scene, focus=Vector((0, 0, 0.35)), ortho_scale=None, resolution=None):
    """마스터 카메라를 씬에 배치하고 scene.camera로 설정"""
    if ortho_scale is None:
        ortho_scale = SPEC["ortho_scale"]
    if resolution is None:
        resolution = SPEC["resolution"]

    cam_data = bpy.data.cameras.new("MasterCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_scale
    cam = bpy.data.objects.new("MasterCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

    d = 12.0
    az = math.radians(SPEC["yaw_deg"])
    el = math.radians(SPEC["pitch_deg"])
    cam.location = focus + Vector((
        d * math.cos(el) * math.cos(az),
        -d * math.cos(el) * math.sin(az),
        d * math.sin(el)
    ))
    direction = focus - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    return cam


def apply_lighting(scene):
    """마스터 조명을 씬에 적용"""
    key_data = bpy.data.lights.new("Key", "AREA")
    key_data.size = SPEC["key_size"]
    key_data.energy = SPEC["key_energy"]
    key_data.color = SPEC["key_color"]
    key = bpy.data.objects.new("Key", key_data)
    key.location = SPEC["key_pos"]
    key.rotation_euler = tuple(math.radians(r) for r in SPEC["key_rot"])
    scene.collection.objects.link(key)

    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.size = SPEC["fill_size"]
    fill_data.energy = SPEC["fill_energy"]
    fill_data.color = SPEC["fill_color"]
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = SPEC["fill_pos"]
    fill.rotation_euler = tuple(math.radians(r) for r in SPEC["fill_rot"])
    scene.collection.objects.link(fill)

    world = bpy.data.worlds.new("Master")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (*SPEC["world_color"], 1.0)
    bg.inputs["Strength"].default_value = SPEC["world_strength"]
    scene.world = world


def apply_render_settings(scene, transparent=True, resolution=None):
    """렌더 설정 적용"""
    scene.render.engine = "CYCLES"
    scene.cycles.samples = SPEC["samples"]
    scene.cycles.use_denoising = SPEC["use_denoise"]
    scene.render.film_transparent = transparent
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    if resolution:
        scene.render.resolution_x = resolution
        scene.render.resolution_y = resolution
    scene.view_settings.view_transform = "Standard"  # 색 보존 (AgX는 채도 감소)
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 1.0


def create_material(color, rough=None):
    """마스터 재질 생성 — 채도 부스트 포함 (레퍼런스 채도 0.42 매칭)"""
    if rough is None:
        rough = SPEC["default_roughness"]
    # 채도 부스트: 원본 색의 채도를 약 2배로
    import colorsys
    r, g, b = color
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    s = min(s * 1.6, 1.0)  # 팔레트 자체가 이미 고채도이므로 1.6배만
    r, g, b = colorsys.hsv_to_rgb(h, s, v)

    m = bpy.data.materials.new("mat")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Specular IOR Level"].default_value = SPEC["default_specular"]
    bsdf.inputs["Sheen Weight"].default_value = 0.15
    bsdf.inputs["Coat Weight"].default_value = 0.08
    return m


def calibrate_px_per_meter(scene, cam):
    """1m X/Y축 이동이 화면에서 몇 px인지 측정"""
    from bpy_extras.object_utils import world_to_camera_view
    res = scene.render.resolution_x

    origin = Vector((0, 0, 0))
    px_o = world_to_camera_view(scene, cam, origin)
    px_x1 = world_to_camera_view(scene, cam, origin + Vector((1, 0, 0)))
    px_y1 = world_to_camera_view(scene, cam, origin + Vector((0, 1, 0)))

    def to_px(v):
        return Vector((v.x * res, (1.0 - v.y) * res))

    p_o = to_px(px_o)
    p_x = to_px(px_x1)
    p_y = to_px(px_y1)

    ppm_x = (p_x - p_o).length
    ppm_y = (p_y - p_o).length
    return ppm_x, ppm_y


def measure_anchor(scene, cam, world_pos):
    """월드 좌표가 PNG 안에서 몇 px 위치인지 측정"""
    from bpy_extras.object_utils import world_to_camera_view
    res = scene.render.resolution_x
    v = world_to_camera_view(scene, cam, Vector(world_pos))
    return (round(v.x * res, 1), round((1.0 - v.y) * res, 1))
