# 06_house_grid.md
기준일: 2026-08-25
상태: V0.2 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 주택 내부 구조, 평면도, 방/공간 단위, Grid 규칙, 가구 배치, 공간 제약, 주거단계별 가구·인테리어 해금 구조를 정의한다.

핵심 목표는 다음과 같다.

- 집마다 실제로 다른 공간감과 배치 선택이 느껴질 것
- 가구 배치가 답답한 퍼즐이 아니라 생활공간을 설계하는 재미가 될 것
- 더 크고 좋은 집으로 갈수록 단순 면적 증가가 아니라 새로운 가구와 생활방식이 열릴 것
- 다주택 이후에도 각 보유주택의 서로 다른 배치상태가 독립적으로 유지될 것

핵심 원칙:

> 집의 가치는 숫자보다 `무엇을 놓고 어떤 생활을 만들 수 있는가`에서 느끼게 한다.

---

# 2. 주택 구조의 기본 단위

```text
House
└─ Floor
   └─ Space
      └─ Grid
         └─ Furniture
```

- `House`: 하나의 매물/보유주택
- `Floor`: 복층 등 다층 구조 확장 단위
- `Space`: 배치와 생활 공간
- `Grid`: 배치 충돌/위치 최소 단위
- `Furniture`: Grid 위 가구 인스턴스

MVP 대부분 `1 House = 1 Floor`로 시작하고 복층 본격 구현은 후속 확장으로 둔다.

다주택에서는 각 `House/Property`가 자신의 Grid/Space/Furniture state를 독립적으로 저장한다.

---

# 3. Space 개념

모든 일반 공간을 고정된 방 용도로 정의하지 않는다.

기본 `space_type` 예:

```text
MAIN_ROOM
ROOM
LIVING
KITCHEN
BATHROOM
ENTRY
BALCONY
TERRACE
MULTI
```

욕실·주방처럼 설비 때문에 용도가 고정되는 공간은 예외다.

일반 방은 가구 배치를 바탕으로 실제 생활용도를 자동 인식한다.

---

# 4. 원룸

원룸은 하나의 주생활 공간에 여러 기능이 겹친다.

```text
원룸
- MAIN_ROOM
- KITCHEN 또는 주방 코너
- BATHROOM
- ENTRY
```

MAIN_ROOM에서 수면/작업/식사/휴식을 해결한다.

초반 핵심 감정:

> 침대, 책상, 작은 소파를 놓으니 금방 꽉 찬다.

이 공간부족이 다음 집 욕망을 만든다.

---

# 5. 투룸부터 공간 분리의 재미

예:

```text
투룸
- LIVING/KITCHEN
- ROOM 1
- ROOM 2
- BATHROOM
```

ROOM의 용도는 시스템이 선지정하지 않는다.

```text
책상 + 사무의자 + PC + 책장
→ OFFICE / STUDY
```

```text
옷장 + 화장대 + 전신거울
→ DRESSING
```

집은 공간을 제공하고 플레이어는 가구로 그 공간의 삶을 결정한다.

---

# 6. 쓰리룸 이상

독립 생활기능을 본격적으로 분리한다.

가능한 공간:

- 독립 침실
- 서재/홈오피스
- 드레스룸
- 취미방
- 홈짐
- 게스트룸
- FAMILY 상태의 아이공간

총면적뿐 아니라 독립공간 수가 집의 가치다.

---

# 7. 같은 평수라도 평면도가 다름

같은 지역·평수·주택유형에도 여러 floorplan template를 사용한다.

예: 15평 투룸

### A
거실 큼 / 방 작음

### B
거실 작음 / 방 큼

### C
거실·주방 일체형 / 두 방 균형

플레이어가 가격/평수뿐 아니라 자신의 가구와 생활방식으로 평면도를 선택하게 한다.

---

# 8. 주택유형별 구조 경향

### 빌라
- 방 분리 경향
- 벽/복도 많음
- 공간효율 편차

### 오피스텔
- 단순/오픈형
- 붙박이 비중 높음

### 아파트
- 거실 중심 정형평면
- 독립방 안정적
- 중대형 가구 유리

### 옥탑
- 작은 면적
- 비정형 가능
- 테라스/옥상 Feature 가능

특정 지역을 특정 평면도로 고정하지 않는다.

---

# 9. Grid 기본 단위

> 1 Grid Cell ≈ 25cm × 25cm

1평 ≈ 약 53 Grid Cell은 물리 환산 참고값일 뿐 `평수 × 53 = playable cell` 공식으로 사용하지 않는다.

실제 자유배치영역은 벽/욕실/현관/복도/고정설비 등을 제외한 floorplan으로 결정한다.

예:

```text
싱글침대 100×200cm → 약 4×8
2인 소파 150×75cm → 약 6×3
책상 120×60cm → 약 5×2~3
```

사용자에게 Grid 숫자를 직접 강조하지 않는다.

---

# 10. 가구 배치 데이터

```text
grid_x
grid_y
grid_width
grid_height
rotation
layer
```

4방향 회전:

```text
0 / 90 / 180 / 270
```

회전 시 footprint도 함께 변경한다.

---

# 11. 벽·문·창문

### 문
- 출입구 완전차단 불가
- 문 열림영역 최소 보호

### 창문
- window segment 저장
- 대형가구 완전차단 제한 가능
- 낮은 가구 허용 가능

### 벽
- 그림/벽선반/벽걸이TV/붙박이 등의 기준

```text
wall_segments
door_segments
window_segments
```

---

# 12. 통행 규칙

현실적 통로폭을 모두 강제하지 않는다.

우선순위:

> 재미 > 직관성 > 현실성

최소 보장:

- 현관문 완전차단 불가
- 방 출입문 완전차단 불가
- 주요 기능가구 interaction point 완전차단 불가

소파-테이블 80cm 같은 현실규칙은 기본 강제하지 않는다.

---

# 13. Interaction Point

```text
interaction_direction
interaction_points
```

예:

```text
SOFA: seat_left / seat_center / seat_right
BED: sleep_left / sleep_right
DESK: chair_position
```

캐릭터 사용 불가능한 방향은 배치과정에서 경고/제한한다.

PARTNER/FAMILY 복수 캐릭터도 동일 interaction point 체계를 사용한다.

---

# 14. 배치 레이어

### FLOOR
침대/소파/책상/테이블

### WALL
그림/벽시계/벽선반/벽걸이TV

### CEILING
천장조명/실링팬

레이어가 다르면 같은 평면위치 중첩 가능.

---

# 15. 작은 장식물과 Surface Slot

MVP는 테이블/선반 위 소품을 완전 자유좌표보다 surface slot 방식으로 시작한다.

```text
surface_id
parent_furniture_instance_id
slot_id
slot_type
occupied_by
```

후속 고도화에서 자유배치 가능.

---

# 16. 공간 용도 자동 인식

```text
BEDROOM
OFFICE
DRESSING
HOBBY
GYM
RELAX
MIXED
CHILD_ROOM
```

판정 입력:

- 핵심 기능가구
- 수량
- interaction 가능성
- 생활행동

사용자가 방 용도를 먼저 지정하지 않아도 된다.

향후 이름붙이기는 별도 가능.

---

# 17. 공간환경 효과

내부 점수 후보:

```text
sleep_environment_score
work_environment_score
relax_environment_score
storage_score
```

사용자 표현:

```text
수면환경 좋음
작업환경 보통
휴식환경 매우 좋음
```

RPG식 침실 Lv3 전면노출은 사용하지 않는다.

---

# 18. 주거단계가 콘텐츠를 해금

> 더 크고 좋은 집으로 이동하면 새로운 가구군과 인테리어 콘텐츠가 실제로 열린다.

예:

### 원룸
소형 생활가구 + 투룸 일부 미리보기

### 투룸
3인소파/식탁/큰책장/본격 홈오피스/확장수납

### 쓰리룸
서재/드레스룸/취미방/홈짐/대형 가구

### 아파트
대형 거실/프리미엄 주방/대형수납

### 프리미엄
홈바/와인셀러/대형오디오/홈카페/테라스 가구 등

목적은 반복적인 집 구매·인테리어 욕망이다.

다주택 이후에는 이미 해금된 콘텐츠를 여러 집에 서로 다른 컨셉으로 배치하는 수평 progression도 추가된다.

---

# 19. 다음 주거단계 가구 미리보기

현재단계 구매가구 + 다음단계 일부를 함께 보여준다.

```text
현재 집에는 공간이 부족해요.
더 넓은 집에서 사용할 수 있어요.
[이 가구를 놓을 수 있는 집 보기]
```

가구 → 더 큰 집 탐색 루프를 만든다.

---

# 20. 자연적 제약과 콘텐츠 해금 병행

실제 배치 가능여부:

- 면적
- 방 수
- Grid
- 창/문
- 구조
- Feature
- 독립공간

`주거단계 해금`은 콘텐츠 접근조건, `Grid/floorplan`은 실제 배치조건.

---

# 21. 설치 가능 Feature

예:

```text
BATHTUB_INSTALLABLE
ISLAND_KITCHEN_AVAILABLE
BUILTIN_WARDROBE_SLOT
TERRACE
BALCONY
LARGE_WINDOW
HOME_GYM_SPACE
```

같은 평수라도 Feature가 다르면 가능한 인테리어/생활씬이 다르다.

---

# 22. 전월세와 자가 인테리어 권한

### 전월세
- 이동가구
- 러그/커튼/소품/식물
- 이동조명
- 원상복구 가능한 꾸미기

### 자가
추가:
- 벽/바닥
- 붙박이
- 욕실/욕조
- 주방/아일랜드
- 고정조명
- 전체 인테리어

후속 구조변경:
- 가벽
- 벽철거
- 방합치기

자가는 경제단계뿐 아니라 집꾸미기 콘텐츠의 큰 progression이다.

---

# 23. 욕실/주방

고정설비 비중이 높은 공간.

자가에서 본격 시공 가능.

이동가전/가구는 05/09 규칙을 따른다.

---

# 24. Built-in

집귀속:

- 붙박이장
- 싱크대
- 욕실장
- 아일랜드
- 고정조명

이사 시 가져갈 수 없다.

다주택에서 집을 보유하면 해당 집에 그대로 유지되고 매도하면 최종 스냅샷에 남는다.

---

# 25. 구조 변경은 MVP 이후

MVP 자가시공:

- 벽/바닥
- 주방
- 욕실
- 붙박이
- 조명

벽철거/가벽/방합치기는 후속.

---

# 26. 특수 평면/희귀 구조

- 코너창
- 테라스
- 큰 욕실
- 팬트리
- 알파룸
- 드레스룸
- 복층
- 다락
- 대형창

새 가구/생활씬/다주택 주거도감의 Feature 축이 된다.

---

# 27. 매물 상세 평면도

확인 가능:

- 전체 평면도
- 방/공간
- 창/문
- Feature
- 독립공간 수
- 큰가구 배치 가능성

계약 전에 내 가구와의 적합성을 상상할 수 있어야 한다.

---

# 28. 보유가구와 새집 호환성

최소 footprint/유효 Grid로 일부 사전판정 가능.

```text
✓ 더블침대
✓ 책상
△ 3인소파 공간 제한
✕ 6인식탁 어려움
```

다주택에서는 보관함뿐 아니라 다른 보유집에 배치중인 가구도 위치를 표시한 뒤 이동 가능 여부를 볼 수 있다.

자동배치는 하지 않는다.

---

# 29. 공간 때문에 생기는 이사욕망

현재 집에 안 들어가는 가구를 보여주어 더 큰 집/좋은 평면/자가 욕망으로 연결한다.

다주택 이후에는 `현재 거주지를 바꾸지 않아도 갖고 싶은 특별한 평면/Feature 집`이라는 추가 구매욕망도 생긴다.

---

# 30. 집 크기보다 독립공간도 중요

총면적만으로 상하위 판단하지 않는다.

가치 입력:

- 면적
- usable Grid
- 방 수
- 독립공간
- Feature
- 구조효율

---

# 31. 자동배치 정책

**MVP/V0.1에서는 전체 자동배치나 추천배치를 제공하지 않는다.**

새집은 빈 상태로 시작하고 플레이어가 직접 배치한다.

이유:

- 직접 꾸미기가 핵심 플레이이기 때문
- 이전집 좌표/컨셉을 자동복원하면 새 평면을 다시 꾸미는 재미가 줄기 때문
- 다주택에서도 집마다 서로 다른 컨셉을 직접 만드는 가치를 유지해야 하기 때문

다만 `자동배치`와 다른 편의기능은 제공할 수 있다.

- Grid snap
- 자동 회전 **제안**
- 들어가는 위치 하이라이트
- 충돌/접근불가 이유 표시
- 더 작은 유사 가구 추천

후속에서 플레이어가 명시적으로 요청하는 제한적 배치도우미를 검토할 수 있지만 기본/자동 실행은 하지 않는다.

---

# 32. 배치 실패 스트레스 완화

- Grid snap
- 회전 제안
- 가능위치 하이라이트
- 불가 이유
- 작은 유사가구
- 놓을 수 있는 집 보기

배치 실패를 다음 행동으로 연결한다.

---

# 33. 이사와 배치상태

## 33.1 집을 매도/퇴거하는 이사

```text
해당 집 이동가구
→ 전량회수
→ 보관함
→ 새집 직접배치
```

최종 배치를 스냅샷으로 보존.

## 33.2 기존집을 보유하는 다주택 이사

```text
기존집 가구
→ 기본적으로 그 집에 유지

가져갈 가구만 선택
→ 이동/보관함
→ 새집 직접배치
```

기존 보유집의 Grid state를 초기화하지 않는다.

상세는 `09_moving_inventory.md`, `16_multi_property.md`가 기준이다.

---

# 34. 평면도 템플릿 운영

고정 템플릿 풀에서 매물에 배정한다.

예:

```text
ONE_ROOM_A/B/C
TWO_ROOM_A/B/C
THREE_ROOM_A/...
```

템플릿마다 Grid/방/창문/문/설비/Feature가 다름.

MVP 가안 총 25~35개.

---

# 35. 핵심 데이터 구조

## House / Space

```text
house_id
property_id
floor_id
space_id
space_type
grid_width
grid_height
wall_segments
door_segments
window_segments
obstacle_cells
feature_tags
ownership_type
housing_progression_tier
```

## Furniture Instance

```text
furniture_instance_id
furniture_id
placed_house_id
space_id
grid_x
grid_y
rotation
layer
color_variant
interaction_points_state
```

## Space Analysis

```text
space_usage
sleep_environment_score
work_environment_score
relax_environment_score
storage_score
```

## Floorplan Template

```text
floorplan_template_id
market_type
layout_type
area_band
space_layout
feature_tags
```

---

# 36. 시스템 연결

## 02
매물/floorplan/Feature

## 05
가구 footprint/rotation/interaction

## 07
current residence 공간의 자율생활/환경효과

## 09
전량회수 vs 기존집 보유 선택이동

## 14
Photo/스냅샷/주거도감

## 16
보유주택별 독립 Grid state와 Live Property

---

# 37. QA

1. 25cm Grid가 적절한가.
2. 같은 평수 평면차이가 선택을 만드는가.
3. 원룸 공간부족이 이사욕망을 만드는가.
4. 일반방 자동용도 인식이 자연스러운가.
5. 주거단계 해금과 Grid 제약이 이해되는가.
6. 전월세/자가 시공차이가 자가욕망을 만드는가.
7. 문/창/interaction 제약이 과하지 않은가.
8. Surface Slot이 충분한가.
9. 매물 평면도가 계약결정에 도움되는가.
10. 자동배치 없이도 초반 배치 UX가 어렵지 않은가.
11. 배치보조가 직접 꾸미기를 침범하지 않는가.
12. 다주택 각 집의 Grid/가구/시공상태가 독립 보존되는가.
13. 가구 한 인스턴스가 여러 집에 중복되지 않는가.
14. 기존집 보유이사에서 집 상태가 초기화되지 않는가.
15. 100채 이상 보유 시 집별 state 저장/로드가 가능한가.

---

# 38. V0.2 확정 정책

- House → Floor → Space → Grid → Furniture 구조.
- 대부분 단층으로 시작.
- 일반방은 가구배치 기반 자동용도 인식, 욕실/주방은 고정용도.
- 1 Grid ≈ 25cm, 1평≈53 Cell은 참고값.
- 4방향 회전.
- 벽/문/창/고정설비 포함.
- 핵심 출입구/interaction point만 통행 강제.
- 소형 장식은 Surface Slot.
- 공간효과는 내부점수 + 자연어 표현.
- 주거단계 상승 시 가구/인테리어 실제 해금.
- 다음 단계 가구 일부 미리보기.
- 주거단계 해금과 실제 Grid 배치조건 분리.
- 전월세는 이동/원상복구 꾸미기 중심, 자가는 본격 집귀속 시공.
- 구조변경은 MVP 이후.
- Feature/희귀평면은 가구·생활씬·주거도감의 축.
- 매물상세에서 평면도/Feature/가구 호환성을 확인할 수 있다.
- **MVP/V0.1 전체 자동배치·추천배치는 사용하지 않는다.**
- Grid snap/회전제안/가능위치 하이라이트 등 배치보조는 허용한다.
- 매도/퇴거 이사는 이동가구 전량회수 후 새집 직접배치.
- 기존집 보유 다주택 이사는 기존집 배치상태를 유지하고 선택한 가구만 이동.
- 각 보유주택의 Grid/인테리어/가구상태를 독립적으로 동시에 보존한다.
