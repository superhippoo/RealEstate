class_name FloorProjector
## room_empty 이미지의 바닥 다이아몬드 위에 16x12 논리 그리드(06_house_grid.md)를 얹는 투영기.
## 바닥이 완전 평행사변형이 아니므로(약간의 사다리꼴) 4모서리 이중선형 보간 사용.
## 좌표계: 함수는 '방 이미지 픽셀'로 반환 — 화면 변환(커버핏)은 호출측에서 적용.

const GRID_W := 16
const GRID_H := 12

# room_empty.png(1448x1086) 실측 바닥 꼭짓점 (이미지 픽셀)
# 비전 정밀 측정: 벽 junction 다크라인 끝점/외곽 아웃라인 피팅 (좌우 대칭 검증됨)
const BACK := Vector2(766, 288)
const RIGHT := Vector2(1381, 640)
const FRONT := Vector2(721, 1045)
const LEFT := Vector2(100, 650)


## 그리드 연속 좌표(셀 단위) → 이미지 픽셀. u:[0,16], v:[0,12]
static func grid_to_img(u: float, v: float) -> Vector2:
	var t := u / GRID_W
	var s := v / GRID_H
	var top := BACK.lerp(RIGHT, t)          # 뒷변(벽 junction)
	var bot := LEFT.lerp(FRONT, t)          # 앞변
	return top.lerp(bot, s)


## 셀 좌표(정수) 중심 → 이미지 픽셀
static func cell_center(gx: int, gy: int) -> Vector2:
	return grid_to_img(gx + 0.5, gy + 0.5)


## 이미지 픽셀 → 가장 가까운 그리드 셀. 방 밖이면 (-1,-1).
static func img_to_cell(p: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 1e9
	for gy in GRID_H:
		for gx in GRID_W:
			var d: float = cell_center(gx, gy).distance_squared_to(p)
			if d < best_d:
				best_d = d
				best = Vector2i(gx, gy)
	# 방 다이아몬드 내부인지 확인: 셀 중심에서 너무 멀면 밖으로 판정
	if best_d > 90.0 * 90.0:
		return Vector2i(-1, -1)
	return best


## 발판(w×h셀, origin 좌상단)의 화면 폭: 앞변 양끝 투영 거리
static func footprint_width_px(origin: Vector2i, w: int, h: int) -> float:
	var a := grid_to_img(origin.x, origin.y + h)
	var b := grid_to_img(origin.x + w, origin.y)
	return a.distance_to(b)


## 발판 앞변 중심 (스프라이트 바닥 앵커용) + 착지 보정.
## 바닥 앞변은 우측으로 갈수록 화면에서 낮아지는 대각선이라, 평평한 하단의
## 스프라이트를 중심점에만 얹으면 왼쪽이 뜬다. 낙차의 절반만큼 내려서
## 좌우 공극/매립을 균형 잡는다(그림자 다이아몬드가 나머지를 시각적으로 메움).
static func footprint_front_center(origin: Vector2i, w: int, h: int) -> Vector2:
	var west := grid_to_img(origin.x, origin.y + h)
	var east := grid_to_img(origin.x + w, origin.y + h)
	var mid := (west + east) * 0.5
	mid.y += (east.y - west.y) * 0.30   # 낙차의 절반 × 싱크 바이어스 — 브리지 그림자가 잔여 갭을 메움
	return mid
