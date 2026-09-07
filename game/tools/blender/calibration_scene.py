# -*- coding: utf-8 -*-
"""
CALIBRATION SCENE — 좌표 파이프라인 검증
4×4 grid 바닥 + 각 셀 경계에 marker + cube 3개

출력:
- calibration_grid.png: grid 바닥 + markers
- calibration_cube_{pos}_{rot}.png: cube 개별 sprite
- calibration_meta.json: 모든 측정값
"""
import bpy
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from master_camera import (
    SPEC, apply_camera, apply_lighting, apply_render_settings,
    create_material, calibrate_px_per_meter, measure_anchor
)

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "review"))
CELL = 0.25  # 1 cell = 25cm
GRID_N = 4   # 4×4 grid

# 캘리브레이션용 컬러
COL_FLOOR = (0.80, 0.60, 0.35)
COL_MARKER = (1.0, 0.0, 0.0)  # 빨강 marker (픽셀 검출용)
COL_CUBE = (0.2, 0.5, 0.9)     # 파랑 cube


def rbox(name, size, loc, m, parent=None, bevel=0.01):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    if bevel > 0:
        b = o.modifiers.new("b", "BEVEL")
        b.width = bevel
        b.segments = 3
    o.data.materials.append(m)
    if parent:
        o.parent = parent
    return o


def build_grid():
    """4×4 grid 바닥 + 교차점 marker"""
    m_floor = create_material(COL_FLOOR, 0.85)
    m_marker = create_material(COL_MARKER, 0.5)

    total = GRID_N * CELL
    # 바닥 (얇은 판)
    rbox("cal_floor", (total, total, 0.01), (total/2, total/2, -0.005), m_floor, bevel=0.002)

    # 각 grid 교차점에 작은 빨간 구 (marker)
    for gx in range(GRID_N + 1):
        for gy in range(GRID_N + 1):
            wx = gx * CELL
            wy = gy * CELL
            bpy.ops.mesh.primitive_uv_sphere_add(radius=0.008, location=(wx, wy, 0.008))
            s = bpy.context.active_object
            s.name = f"marker_{gx}_{gy}"
            s.data.materials.append(m_marker)
            for p in s.data.polygons:
                p.use_smooth = True


def build_cube_at(gx, gy, rot=0):
    """지정 grid 셀 중심에 1m cube 배치"""
    m_cube = create_material(COL_CUBE, 0.6)
    cx = (gx + 0.5) * CELL
    cy = (gy + 0.5) * CELL
    root = bpy.data.objects.new("CubeRoot", None)
    root.location = (cx, cy, 0)
    root.rotation_euler = (0, 0, math.radians(rot))
    bpy.context.scene.collection.objects.link(root)
    rbox("cal_cube", (0.20, 0.20, 0.20), (0, 0, 0.10), m_cube, parent=root)
    return root


def clear_cube():
    for o in list(bpy.context.scene.objects):
        if o.name.startswith(("cal_cube", "CubeRoot")):
            bpy.data.objects.remove(o, do_unlink=True)


def render_png(scene, path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # 마스터 카메라/조명/렌더 설정
    focus = bpy.mathutils.Vector((GRID_N * CELL / 2, GRID_N * CELL / 2, 0.05)) if hasattr(bpy, 'mathutils') else None
    from mathutils import Vector
    focus = Vector((GRID_N * CELL / 2, GRID_N * CELL / 2, 0.05))

    # Grid 씬 렌더
    build_grid()
    scene = bpy.context.scene
    cam = apply_camera(scene, focus=focus)
    apply_lighting(scene)
    apply_render_settings(scene, transparent=False)
    render_png(scene, os.path.join(OUT_DIR, "cal_grid.png"))

    # 캘리브레이션 측정
    ppm_x, ppm_y = calibrate_px_per_meter(scene, cam)
    print(f"CALIBRATION ppm_x={ppm_x:.2f} ppm_y={ppm_y:.2f}")

    # Grid 코너의 픽셀 위치 측정
    corners = {}
    for gx in [0, GRID_N]:
        for gy in [0, GRID_N]:
            pos = measure_anchor(scene, cam, (gx * CELL, gy * CELL, 0))
            corners[f"c{gx}{gy}"] = pos
            print(f"CAL_CORNER ({gx},{gy}) → px{pos}")

    # Cube 테스트: 여러 위치 × 회전
    apply_render_settings(scene, transparent=True)
    meta = {
        "spec": {k: v for k, v in SPEC.items() if not isinstance(v, tuple)},
        "ppm_x": ppm_x,
        "ppm_y": ppm_y,
        "corners_px": corners,
        "grid_size_cells": GRID_N,
        "cell_m": CELL,
        "cubes": {}
    }

    tests = [
        ("A", 0, 0, 0),    # origin
        ("B", 3, 0, 0),    # far X
        ("C", 0, 3, 0),    # far Y
        ("D", 2, 2, 0),    # center
        ("E", 1, 1, 90),   # rotated 90°
    ]

    for label, gx, gy, rot in tests:
        clear_cube()
        root = build_cube_at(gx, gy, rot)
        bpy.context.view_layer.update()
        fname = f"cal_cube_{label}.png"
        render_png(scene, os.path.join(OUT_DIR, fname))
        # anchor 측정 (grid 셀 중심)
        anchor_px = measure_anchor(scene, cam, ((gx + 0.5) * CELL, (gy + 0.5) * CELL, 0))
        meta["cubes"][label] = {
            "grid": [gx, gy],
            "rotation": rot,
            "anchor_px": anchor_px,
            "file": fname
        }
        print(f"CAL_CUBE {label} grid=({gx},{gy}) rot={rot} anchor={anchor_px}")

    clear_cube()

    # metadata 저장
    meta_path = os.path.join(OUT_DIR, "calibration_meta.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2, default=str)
    print("CALIBRATION_DONE", meta_path)


if __name__ == "__main__":
    main()
