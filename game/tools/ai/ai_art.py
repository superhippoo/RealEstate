# -*- coding: utf-8 -*-
"""
AI 아트 파이프라인 — Pollinations 익명 엔드포인트 (키 없이 무료)
- 스타일 레시피 기반 생성 + 속도제한 준수 + 재시도
- 흰 배경 스프라이트 컷아웃(가장자리 flood-fill) + 트림
실행: python ai_art.py [--only room|<asset_id>|all]
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

from PIL import Image, ImageFilter

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
STAGE = os.path.join(ROOT, "tools", "ai", "staging")
OUT = os.path.join(ROOT, "assets", "ai_sprites")

BASE_STYLE = (
    "cozy mobile game illustration style, 2D isometric dollhouse view, "
    "warm pastel palette, chunky rounded toy-like shapes, soft global illumination, "
    "very soft contact shadows, clean edges, high detail, no text"
)

ROOM_PROMPT = (
    "empty small studio apartment room interior, isometric 2:1 dollhouse cutaway view from front corner, "
    "warm honey wood plank floor, peach colored walls on two back sides with baseboard trim, "
    "one window with sheer curtains on the left wall, small kitchenette along back wall, "
    "no furniture, no people" + ", " + BASE_STYLE
)

# (프롬프트, 실제 크기meter 기준: footprint cells w,h)
ASSETS = {
    "bed_single": ("single bed with sage green duvet, cream pillows, wooden frame, warm honey wood", 4, 8),
    "sofa_two": ("two-seat cream sofa with terracotta throw cushion and mustard blanket", 6, 3),
    "desk_small": ("small wooden desk with monitor, mug and books, warm wood", 5, 2),
    "chair_basic": ("wooden chair with mustard seat cushion", 2, 2),
    "tv_43": ("low wooden TV console with TV screen and small plant", 4, 2),
    "rug_oval": ("oval rug, sage green border with cream center, flat top view slightly angled", 6, 4),
    "plant_monstera": ("potted monstera plant in terracotta pot, deep green leaves", 2, 2),
    "floor_lamp": ("floor lamp with warm glowing cream shade, brass pole", 2, 2),
    "side_table": ("round wooden side table with coffee mug and small book", 2, 2),
    "picture_frame": ("framed abstract art picture with sage and terracotta shapes, front view", 2, 2),
    "wall_shelf": ("floating wooden wall shelf with books, small plant and mini frame, front view", 4, 1),
}

RATE_LIMIT_SEC = 6.0


def fetch(prompt: str, seed: int, width: int, height: int, out_path: str) -> bool:
    q = urllib.parse.quote(prompt)
    url = (f"https://image.pollinations.ai/prompt/{q}"
           f"?width={width}&height={height}&nologo=true&seed={seed}")
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            if len(data) > 8000:
                with open(out_path, "wb") as f:
                    f.write(data)
                return True
        except Exception as e:
            print("  retry", attempt + 1, e)
            time.sleep(10)
        time.sleep(RATE_LIMIT_SEC)
    return False


def cutout_white(src: str, dst: str, tol: int = 235) -> None:
    """가장자리 flood-fill 기반 흰배경 제거 + 트림 + 스무딩"""
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    px = img.load()
    visited = [[False] * w for _ in range(h)]
    stack = []
    for x in range(w):
        stack.append((x, 0))
        stack.append((x, h - 1))
    for y in range(h):
        stack.append((0, y))
        stack.append((w - 1, y))
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
            continue
        visited[y][x] = True
        r, g, b, a = px[x, y]
        if r >= tol and g >= tol and b >= tol:
            px[x, y] = (r, g, b, 0)
            stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    # 알파 가장자리 부드럽게
    alpha = img.split()[3].filter(ImageFilter.GaussianBlur(1.2))
    img.putalpha(alpha)
    img.save(dst)


def main():
    os.makedirs(STAGE, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    only = "all"
    args = sys.argv[1:]
    if "--only" in args:
        only = args[args.index("--only") + 1]

    manifest = {}
    if only in ("all", "room"):
        print("ROOM bg generating...")
        p = os.path.join(STAGE, "room_bg_raw.png")
        if fetch(ROOM_PROMPT, seed=1001, width=1280, height=640, out_path=p):
            Image.open(p).save(os.path.join(OUT, "room_bg.png"))
            manifest["room_bg"] = {"seed": 1001}
            print("  room_bg ok")
        time.sleep(RATE_LIMIT_SEC)

    if only in ("all",) or only in ASSETS:
        for i, (aid, (desc, cw, ch)) in enumerate(ASSETS.items()):
            if only != "all" and only != aid:
                continue
            print(f"{aid} generating...")
            prompt = (f"{desc}, single game asset sprite centered, isolated on pure white background, "
                      "isometric 2:1 view" + ", " + BASE_STYLE)
            raw = os.path.join(STAGE, f"{aid}_raw.png")
            seed = 2000 + i * 17
            if fetch(prompt, seed=seed, width=768, height=768, out_path=raw):
                cut = os.path.join(OUT, f"{aid}.png")
                cutout_white(raw, cut)
                manifest[aid] = {"seed": seed, "cells": [cw, ch]}
                print(f"  {aid} ok")
            time.sleep(RATE_LIMIT_SEC)

    mp = os.path.join(OUT, "manifest.json")
    old = {}
    if os.path.exists(mp):
        old = json.load(open(mp, encoding="utf-8"))
    old.update(manifest)
    json.dump(old, open(mp, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print("AI_ART_DONE", list(manifest.keys()))


if __name__ == "__main__":
    main()
