# -*- coding: utf-8 -*-
"""GPT 스프라이트 후처리: 접촉그림자 합성 + 배치 슬롯 메타데이터 생성.
- 입력: review/gpt_batch/*.png (마젠타 배경 원본)
- 출력: game/assets/gpt_sprites/*.png (투명 스프라이트, 그림자 포함)
        game/data/gpt_slots.json (방 상대좌표 배치 정보)

방 상대좌표 계산 근거:
- 08(가구 있는 방) room bbox = (258,47)-(1499,972) / 1536x1024
- room_empty room bbox = (65,28)-(1411,1074) / 1448x1086
- 08의 가구 위치(비전 측정)를 room-relative 분수로 변환해 슬롯 지정
- 화면 폭: 방 4m = 1346px → 1셀(0.25m) = 84px
"""
from PIL import Image, ImageFilter, ImageDraw
import numpy as np
import json, os

SRC = r'D:/works/realestate/review/gpt_batch'
OUT = r'D:/works/realestate/game/assets/gpt_sprites'
os.makedirs(OUT, exist_ok=True)

PX_PER_CELL = 1346 / 16.0   # 방 가로 16셀 = 1346px
ROOM_W_PX, ROOM_H_PX = 1346, 1046  # empty 방 bbox 크기

# id: (name, grid_w, grid_h, price, slot_x, slot_y, layer, shadow)
# slot = 방 bbox 기준 분수 (앵커: 가구 바닥 중앙). layer: floor(러그) < normal < wall
SLOTS = {
    "rug_oval":       ("타원 러그", 6, 4, 350_000, 0.44, 0.62, "floor", False),
    "bed_single":     ("싱글 침대", 4, 8, 800_000, 0.62, 0.63, "normal", True),
    "sofa_two":       ("2인 소파", 6, 3, 1_200_000, 0.20, 0.56, "normal", True),
    "desk_small":     ("책상", 5, 2, 400_000, 0.46, 0.40, "normal", True),
    "chair_basic":    ("의자", 2, 2, 150_000, 0.49, 0.47, "normal", True),
    "tv_43":          ("43인치 TV", 4, 2, 2_900_000, 0.83, 0.50, "normal", True),
    "plant_monstera": ("몬스테라", 2, 2, 80_000, 0.09, 0.50, "normal", True),
    "floor_lamp":     ("플로어 램프", 2, 2, 250_000, 0.70, 0.50, "normal", True),
    "picture_frame":  ("벽 액자", 2, 2, 120_000, 0.42, 0.20, "wall", False),
    "wall_shelf":     ("벽 선반", 4, 1, 180_000, 0.56, 0.13, "wall", False),
    "armchair":       ("안락의자", 2, 2, 180_000, 0.27, 0.46, "normal", True),
}

# 캐릭터 (구매 아님, 상시 배치)
CHAR = {"c_idle": (0.13, 0.60)}


def keyout_magenta(src_path):
    im = Image.open(src_path).convert('RGBA')
    a = np.array(im)
    r, g, b = a[:, :, 0].astype(np.int32), a[:, :, 1].astype(np.int32), a[:, :, 2].astype(np.int32)
    mag = (r > 170) & (b > 170) & (g < 120) & (np.abs(r - b) < 70)
    alpha = np.where(mag, 0, 255).astype(np.uint8)
    m = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(1.0))
    aa = np.where(np.array(m) > 128, 255, 0).astype(np.uint8)
    a[:, :, 3] = aa
    out = Image.fromarray(a)
    ys, xs = np.where(aa > 0)
    return out.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def bake_shadow(chair_img, shadow_w_ratio=0.86):
    """바닥 접촉 그림자 타원을 하단에 추가한 캔버스 반환"""
    cw, ch = chair_img.size
    pad_b = int(ch * 0.13) + 14
    pad_x = 18
    canvas = Image.new('RGBA', (cw + pad_x * 2, ch + pad_b), (0, 0, 0, 0))
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    ew = int(cw * shadow_w_ratio)
    eh = max(int(ch * 0.07), 10)
    cx = pad_x + cw // 2
    cy = ch + pad_b // 2 - 2
    sd.ellipse([cx - ew // 2, cy - eh // 2, cx + ew // 2, cy + eh // 2], fill=(60, 38, 20, 120))
    sh = sh.filter(ImageFilter.GaussianBlur(max(eh // 2, 4)))
    canvas.alpha_composite(sh)
    canvas.alpha_composite(chair_img, (pad_x, 0))
    return canvas


meta = {"px_per_cell": PX_PER_CELL, "room": {"x": 65, "y": 28, "w": ROOM_W_PX, "h": ROOM_H_PX,
         "src": "res://assets/concept_room/room_empty.png"}, "items": {}}

os.makedirs(r'D:/works/realestate/game/assets/concept_room', exist_ok=True)
# 방 배경 복사 (Godot 임포트용)
Image.open(os.path.join(SRC, 'room_empty.png')).save(r'D:/works/realestate/game/assets/concept_room/room_empty.png')

for fid, (name, gw, gh, price, sx, sy, layer, shadow) in SLOTS.items():
    img = keyout_magenta(os.path.join(SRC, f'f_{fid}.png'))
    if shadow:
        img = bake_shadow(img)
    img.save(os.path.join(OUT, f'f_{fid}.png'))
    # 화면 폭: (gw+gh) 대각 성분 × 셀당 px × 등각 보정 0.35
    width_px = int((gw + gh) * PX_PER_CELL * 0.35)
    meta["items"][fid] = {
        "name": name, "price": price, "grid": [gw, gh],
        "slot": [sx, sy], "layer": layer, "width_px": width_px,
        "sprite": f"res://assets/gpt_sprites/f_{fid}.png",
    }
    print(f'{fid:16s} sprite={img.size}  screen_w={width_px}px')

# 캐릭터
for cid, (sx, sy) in CHAR.items():
    img = bake_shadow(keyout_magenta(os.path.join(SRC, f'{cid}.png')), 0.6)
    img.save(os.path.join(OUT, f'{cid}.png'))
    meta.setdefault("characters", {})[cid] = {
        "slot": [sx, sy], "width_px": int(PX_PER_CELL * 1.3),
        "sprite": f"res://assets/gpt_sprites/{cid}.png"}
    print(cid, img.size)

# 반응용 happy도 저장
img = keyout_magenta(os.path.join(SRC, 'c_happy.png'))
img.save(os.path.join(OUT, 'c_happy.png'))
meta.setdefault("characters", {})["c_happy"] = {
    "slot": [0.5, 0.5], "width_px": int(PX_PER_CELL * 1.3),
    "sprite": "res://assets/gpt_sprites/c_happy.png"}

json.dump(meta, open(r'D:/works/realestate/game/data/gpt_slots.json', 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)
print('slots json saved')
