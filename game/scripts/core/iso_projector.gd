class_name IsoProjector
## 논리 Grid 좌표(25cm 셀)와 아이소메트릭 화면 좌표의 유일한 변환 지점.
## 2:1 다이아몬드 타일. 모든 렌더링/입력 좌표 변환은 이 클래스를 통해서만 한다.

const TILE_WIDTH := 128.0
const TILE_HEIGHT := 64.0


static func grid_to_screen(gx: int, gy: int) -> Vector2:
	return Vector2(
		(gx - gy) * (TILE_WIDTH * 0.5),
		(gx + gy) * (TILE_HEIGHT * 0.5)
	)


## 실수 그리드 좌표(셀 중심 등) 변환
static func gridf_to_screen(fx: float, fy: float) -> Vector2:
	return Vector2(
		(fx - fy) * (TILE_WIDTH * 0.5),
		(fx + fy) * (TILE_HEIGHT * 0.5)
	)


static func screen_to_grid(screen: Vector2) -> Vector2i:
	var fx := (screen.x / (TILE_WIDTH * 0.5) + screen.y / (TILE_HEIGHT * 0.5)) * 0.5
	var fy := (screen.y / (TILE_HEIGHT * 0.5) - screen.x / (TILE_WIDTH * 0.5)) * 0.5
	return Vector2i(floori(fx), floori(fy))


## 셀의 다이아몬드 폴리곤(로컬 기준, 중심 = grid_to_screen 결과)
static func cell_polygon() -> PackedVector2Array:
	var hw := TILE_WIDTH * 0.5
	var hh := TILE_HEIGHT * 0.5
	return PackedVector2Array([
		Vector2(0, -hh),
		Vector2(hw, 0),
		Vector2(0, hh),
		Vector2(-hw, 0),
	])
