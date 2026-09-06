# -*- coding: utf-8 -*-
"""
렌더 결과 수평 반전(flop) 후처리.
315도 방위 렌더(X=좌하단, Y=우하단)를 게임 그리드 관례(X=우하단, Y=좌하단)로 변환.
room_manifest.json의 코너 x좌표도 함께 보정(x' = RES - x).
실행: python flop_sprites.py [--only room|sprites] [--skip room|sprites]
"""
import json
import os
import sys

from PIL import Image

DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender_output"))

only = None
skip = None
args = sys.argv[1:]
if "--only" in args:
    only = args[args.index("--only") + 1]
if "--skip" in args:
    skip = args[args.index("--skip") + 1]


def want_room(fname: str) -> bool:
    return fname.startswith("room_")


for fname in os.listdir(DIR):
    if not fname.endswith(".png"):
        continue
    is_room = want_room(fname)
    if only == "room" and not is_room:
        continue
    if only == "sprites" and is_room:
        continue
    if skip == "room" and is_room:
        continue
    if skip == "sprites" and not is_room:
        continue
    path = os.path.join(DIR, fname)
    img = Image.open(path)
    img.transpose(Image.FLIP_LEFT_RIGHT).save(path)
    print("flopped", fname)

if only in (None, "room"):
    mpath = os.path.join(DIR, "room_manifest.json")
    if os.path.exists(mpath):
        m = json.load(open(mpath, encoding="utf-8"))
        if not m.get("flopped"):
            res = m["resolution"]
            for key, xy in m["corners_img_px"].items():
                xy[0] = round(res - xy[0], 2)
            m["flopped"] = True
            json.dump(m, open(mpath, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
            print("room_manifest corners adjusted")
