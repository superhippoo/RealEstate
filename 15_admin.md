# 15_admin.md
기준일: 2026-08-25
상태: V0.2 운영/어드민 통합 정리

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 상세기획 00~16에서 운영 중 조정하거나 추가/비활성화할 가능성이 있는 콘텐츠·수치·조건·노출정책을 통합 관리한다.

각 시스템의 의미와 상태전이 구조는 해당 상세 MD가 Source of Truth이며, 이 문서는 `운영값`의 Source of Truth다.

핵심 원칙:

> 게임 규칙의 구조와 계산 엔진은 코드로 구현하고, 운영 중 바꿀 필요가 있는 콘텐츠·수치·확률·조건·문구·가중치는 어드민에서 관리한다.

---

# 2. 문서 운영 규칙

상세기획 변경 시:

```text
상세 MD 수정
→ 15_admin.md 동시 수정
→ 실제 어드민 스키마/데이터 반영
```

순서로 관리한다.

16까지 상세기획이 확정되었으므로 현재 번호형 핵심 상세문서 중 `추후 상세기획 확정 후 추가`로 남겨둘 항목은 없다.

16의 후속 확장인 임대사업/복수주담대/자동관리/별장생활 등은 해당 기능을 실제 기획할 때 본 문서를 다시 확장한다.

---

# 3. 어드민 대상 / 코드 대상

## 3.1 어드민 관리

- 콘텐츠 활성/비활성
- 이름/설명/문구
- 가격/보상/비용
- 확률/가중치
- 기간/횟수/cooldown
- 임계값
- 해금/노출/추천 조건
- 카테고리/태그
- 콘텐츠 연결관계
- 운영 적용기간
- 이벤트 결과/후속체인

## 3.2 코드 관리

- Grid 충돌/회전/pathfinding
- interaction point 접근판정
- 월 경계/온라인·오프라인 시간엔진
- 상태머신
- 저장/로드/DB/네트워크
- 자동배치 금지 등 구조정책
- 이벤트 조건매칭/예약큐/Property 순회 엔진
- 대출 원리금/한도/spendable_cash 계산
- 고정 Market Cycle

단 엔진이 사용하는 값은 가능한 범위에서 어드민으로 분리한다.

---

# 4. 공통 시간 설정

출처: `04_time_contract.md`

현재 기본값:

```text
GAME_MONTH_REAL_SECONDS = 1800
OFFLINE_MAX_SECONDS = 5400
OFFLINE_MAX_GAME_MONTHS = 3
DEFAULT_RENTAL_CONTRACT_MONTHS = 24
CONTRACT_NOTICE_MONTHS = 3
CONTRACT_FINAL_NOTICE_MONTHS = 1
```

추가 관리 후보:

```text
SALARY_COUNTDOWN_ALERT_SECONDS
TEMPORARY_STAY_MAX_MONTHS
TEMPORARY_STAY_RENT_SURCHARGE_RATE
TEMPORARY_STAY_JEONSE_FEE
```

월 경계에서 모든 OWNED_PROPERTY를 순회해 시세와 Maintenance를 처리하는 구조 자체는 코드다.

---

# 5. 경제 밸런스

출처: `01_economy_balance.md`, `03_career.md`, `11_loan.md`, `13_life_stage.md`, `16_multi_property.md`

## 5.1 시작자산

```text
starting_cash = 25,000,000  // 현재 가안
```

직장별 시작자금은 동일.

## 5.2 월 생활비 목표

- 정기지출 목표: 월급 약 65~80%
- 가처분소득 목표: 약 20~35%

관리:

- 소득구간별 기본 생활비
- 생활비 scaling
- 라이프스타일 인플레이션
- 보험/기타 고정비
- 주거단계 보정
- Household State 생활비 modifier

## 5.3 현금 안전장치

```text
spendable_cash
= max(0, cash_balance - reserved_mandatory_expenses)
```

관리:

- mandatory expense 포함항목
- 낮은 spendable cash 경고
- 구매 부족 CTA threshold
- 계약 후 낮은 현금 경고

가구/인테리어/추가주택/수동상환/수리비 등 수동지출은 `spendable_cash`를 사용한다.

## 5.4 장기 명목경제

수백 게임년 동안 주택가격이 계속 우상향하므로 커리어 급여를 Lv5 값에 영구고정하지 않는다.

관리 후보:

```text
long_term_nominal_income_enabled
long_term_nominal_income_start_month
long_term_nominal_income_update_interval_months
long_term_nominal_income_growth_rate
```

적용 원칙:

```text
actual_salary
= company_level_base_salary
× long_term_nominal_income_index
```

- career_level은 1~5 유지
- 명목소득 조정은 승진이 아님
- 직급/업무강도를 자동 변경하지 않음
- 같은 시점의 이직 offer salary에도 동일 index 적용
- 정확한 시작시점/주기/상승률은 50/100/300/500년 통합 시뮬레이션 후 확정
- Market Cycle과 동일 비율로 강제하지 않음

향후 필요하면 생활비/신규 콘텐츠 가격의 장기 명목보정도 별도 index로 확장할 수 있으나 현재 가장 우선하는 것은 income index다.

---

# 6. 광고 / 부업

출처: `08_ads_sidejob.md`

현재 V0.1 테스트:

- 1회 보상 = 예상 월 가처분소득 약 15~20%
- 우선값 20%
- 일반 약 5회/게임월
- 적극 부업플레이 성장속도 목표: 무광고 대비 약 1.7~2.2배

관리:

```text
reward_formula_type
reward_ratio
minimum_reward
maximum_reward
freeze_for_game_month
company_sidejob_base_count
commute_sidejob_modifier
minimum_sidejob_count
maximum_sidejob_count
```

진입점:

- 가구
- 인테리어
- 이사비
- 월세/전세/매매 부족
- 대출비용
- 이벤트/Property 수리비
- 상시 부업메뉴

광고가 대출잔액이나 생활스탯을 직접 바꾸는 기능은 만들지 않는다.

---

# 7. 직장 / 커리어

출처: `03_career.md`, `10_events.md`

회사 관리:

```text
company_id
company_name
company_type
company_tier
work_district
salary_table
workload
stability
growth_rate
sidejob_base
bonus_profile
benefit_profile
event_profile
is_active
```

첫 직장 테스트:

| 직장 | 월급 | 근무지 | 업무강도 | 안정성 | 성장성 | 부업 |
|---|---:|---|---:|---:|---:|---:|
| 광화문 안정기업 | 300만 | 광화문 | 2 | 4 | 2 | 6 |
| 구로 IT기업 | 330만 | 구로 | 3 | 3 | 4 | 5 |
| 강남 스타트업 | 370만 | 강남 | 4 | 2 | 5 | 3 |

현재 이벤트 기간 시작값:

- 첫 승진 최소 재직 12개월
- PROMOTION→PROMOTION 12개월 hard block
- JOB_CHANGE→JOB_CHANGE 12개월 hard block
- JOB_CHANGE→PROMOTION 6개월 hard block
- PROMOTION→JOB_CHANGE 3개월간 weight ×0.5
- JOB_CHANGE→RESTRUCTURING_MAJOR 3개월 block
- RESTRUCTURING_MAJOR→동일 12개월 block

기간/가중치는 어드민.

Lv5 이후 급여의 장기 명목성장은 `#5.4`의 index를 사용하며 career level 자체를 무한확장하지 않는다.

---

# 8. 업무지구 / 통근

업무지구:

- 광화문
- 여의도
- 구로
- 강남
- 판교

MVP:

```text
residential_region_id
work_district_id
commute_minutes
```

통근 보정:

- 20분 이하 +1
- 21~40 0
- 41~60 -1
- 61~80 -2
- 81+ -3

실제 영향값은 생활/부업/자기계발 관리표에서 운영한다.

---

# 9. 부동산 지역

출처: `02_real_estate.md`

초기 생활권:

- 금천·구로
- 영등포
- 서대문
- 마포
- 종로·중구
- 성동
- 강남
- 송파
- 용산
- 한남 프리미엄

관리:

```text
region_id
name
region_group
premium_segment
sort_order
is_active
```

현실/게임용 지역가격지수를 분리 보관 가능.

기준지역 V1: 서대문 1.00.

현실→게임 압축계수 초기값:

```text
real_to_game_compression_exponent = 0.65
```

---

# 10. 시장유형 계수

```text
MULTIFAMILY
OFFICETEL
APARTMENT
```

계약유형별 현실/게임 coefficient를 별도 관리한다.

V1 게임용:

| 계약 | MULTIFAMILY | OFFICETEL | APARTMENT |
|---|---:|---:|---:|
| SALE | 1.00 | 0.84 | 1.46 |
| JEONSE | 1.00 | 1.11 | 1.34 |
| RENT | 1.00 | 1.14 | 1.09 |

---

# 11. 주택유형 / Layout

표시유형:

- 옥탑
- 원룸
- 투룸
- 오피스텔
- 빌라
- 아파트

Layout 후보:

```text
ROOFTOP
ONE_ROOM
TWO_ROOM
ETC
```

관리:

```text
housing_type_id
market_type
layout_type
housing_progression_tier
base_traits
is_active
```

옥탑 modifier는 별도 게임값.

---

# 12. 한남 프리미엄

```text
HANNAM_PREMIUM
```

관리:

- 계약유형별 가격지수
- 등장/노출 조건
- progression tier
- floorplan pool
- 프리미엄 가구/시공 연결
- 희귀 Feature pool

한남은 1주택 progression milestone이며 다주택/컬렉션의 hard gate는 아니다.

---

# 13. 매물 / 특별매물

관리 후보:

```text
house_id
region_id
housing_type
market_type
layout_type
floorplan_template_id
size_pyeong
room_count
build_age
condition
deposit
monthly_rent
maintenance_fee
jeonse_price
sale_price
special_features
listing_duration
rarity
housing_progression_tier
is_active
```

첫 추천매물 4~6개.

기간:

- 추천 2~4게임개월
- 특별 기본 1~2게임개월

특별매물은 가격이 싸서가 아니라 희귀한 공간/생활기회를 제공하는 집.

Feature:

```text
feature_id
rarity_score
standalone_special_enabled
rarity_weight
price_modifier
allowed_housing_types
allowed_regions
special_reason_copy
unlockable_scene_ids
collection_tag
```

다주택 이후 특별매물은 컬렉션용 구매대상으로도 기능한다.

---

# 14. 부동산 가격공식 파라미터

```text
Snapshot 기준가격
× 지역/시장유형
× 면적
× 연식
× Feature
× 기타 02 보정
× 플레이어 시장지수
```

계수값은 어드민, 계산구조는 코드.

---

# 15. 계약 / 이사 시간

출처: `04_time_contract.md`, `09_moving_inventory.md`, `16_multi_property.md`

임대:

- 기본 24개월
- 3개월 전 안내
- 1개월 전 재강조
- TEMPORARY_STAY 최대 3개월

자가 current residence 매도 안전정책:

> 매도 후 current residence가 0개가 되지 않게 한다.

1주택 갈아타기는 새 거주지 확정 후 기존집 매도.

다주택에서는:

- 기존집 매도
- 기존집 보유
- 다른 보유집으로 current residence 변경

을 허용한다.

기존집 보유 시 예상 매도순자산은 신규구매 자금에 사용하지 않는다.

거주지 변경 운영값:

```text
owned_residence_move_cost_profile
residence_change_cooldown_months   // 초기 후보 3개월
```

---

# 16. 가구 카탈로그

출처: `05_furniture.md`, `06_house_grid.md`, `09_moving_inventory.md`

관리:

```text
furniture_id
name
category
subcategory
price
price_tier
grid_width
grid_height
rotation_allowed
layer
color_variants
style_tags
movable
required_household_state
requires_feature
required_housing_progression_tier
interaction_types
interaction_direction
interaction_points
recovery_effect
stress_effect
happiness_effect
study_effect
available_from
available_until
is_active
```

BASIC/STANDARD/PREMIUM/DESIGNER는 내부 상품군.

가구 한 인스턴스의 위치/상태 엔진은 코드로 관리한다.

---

# 17. 가구 가격밴드

- 소품: 가처분소득 5~20%
- 일반가구: 30~100%
- 욕망가구: 1~3개월
- 프리미엄: 여러 달 저축/부업

관리:

```text
price_tier
min_ratio
max_ratio
category
housing_progression_tier
```

---

# 18. 주거 Progression 해금

관리:

```text
housing_progression_tier
content_type
content_id
purchase_enabled
preview_enabled
unlock_priority
```

현재단계 + 다음단계 일부 미리보기.

다주택 이후 이미 해금한 콘텐츠는 여러 보유집에서 사용할 수 있다.

---

# 19. 가구 추천 / 상점

상점 section:

```text
section_id
name
sort_order
exposure_rule
item_limit
is_active
```

추천 rule:

```text
condition_tags
recommended_category_or_item
priority
copy
```

다주택 방문 중에는 현재 편집중인 집을 기준으로 가구 추천 가능.

추천은 자동배치가 아니다.

---

# 20. 생활씬 마스터

출처: `07_character_life.md`, `13_life_stage.md`, `14_healing_social.md`

```text
scene_id
name
scene_type
required_furniture_tags
required_space_usage
required_feature_tags
required_household_state
required_actor_roles
season_condition
weather_condition
time_condition
life_rhythm_condition
reward_profile
first_discovery_reward
album_enabled
cooldown
priority
is_active
```

발생엔진 07, 발견/앨범/공유 14.

---

# 21. 평면도 템플릿

```text
floorplan_template_id
name
market_type
layout_type
housing_type
area_band
housing_progression_tier
space_layout
grid_width
grid_height
wall_segments
door_segments
window_segments
obstacle_cells
feature_tags
rarity
recommended_household_size
is_active
```

MVP 총 25~35개 가안.

다주택 도감의 대표 floorplan slot과 연결 가능.

---

# 22. Grid / 공간 기준값

- 1 Grid ≈ 25cm × 25cm
- 1평≈53 Cell은 참고값

환경표시:

- 매우 좋음
- 좋음
- 보통
- 부족

관리:

- sleep/work/relax/storage score 구간
- household_space/privacy/family_storage 구간
- space usage 판정 tag/threshold

Grid 알고리즘/자동배치 금지는 코드.

---

# 23. 주택 Feature

대표:

```text
BATHTUB_INSTALLABLE
ISLAND_KITCHEN_AVAILABLE
BUILTIN_WARDROBE_SLOT
TERRACE
BALCONY
LARGE_WINDOW
HOME_GYM_SPACE
CORNER_WINDOW
PANTRY
ALPHA_ROOM
DRESSROOM
ATTIC
DUPLEX
```

관리:

```text
feature_id
allowed_housing_types
allowed_floorplans
rarity_weight
price_modifier
unlockable_furniture_tags
unlockable_scene_ids
collection_tag
maintenance_event_profile
is_active
```

Feature는 가격뿐 아니라 생활씬/주거도감/Maintenance 연결축이다.

---

# 24. 전월세 / 자가 인테리어 권한

전월세: 이동/원상복구 꾸미기.

자가: 벽/바닥/붙박이/욕실/주방/고정조명/전체시공.

관리:

```text
ownership_type
interior_action_id
is_allowed
required_housing_progression_tier
required_feature_id
required_household_state
```

---

# 25. 시공 콘텐츠

```text
interior_action_id
name
category
price
required_ownership_type
required_feature_id
required_housing_progression_tier
required_household_state
space_type
visual_result_key
effect_profile
is_active
```

예시 가안:

- 도배 250만
- 바닥 400만
- 욕실 1,000만
- 주방 1,500만
- 전체 4,000만

시공비를 주택 매매가에 직접 더하지 않는다.

---

# 26. 콘텐츠 제작량 목표

가구 약 100종 전후.

평면도 약 25~35개.

운영 KPI/제작목표로 사용.

---

# 27. 코드/기획으로 고정할 핵심 규칙

현재 00~16 확정기준:

- 광고수입은 일반머니, 직접 스탯/승진/대출잔액 보상 금지
- 온라인/오프라인 공통 게임달력
- 오프라인 최대 3개월
- 중요 CHOICE 자동확정 금지
- TEMPORARY_STAY 3개월 후 필요 시 hard stop
- 랜덤 영구 주택/가구/대형자산 손실 금지
- 일반방 용도는 배치 기반 자동인식
- 전월세/자가 인테리어 권한 차등
- 중고가구 판매 없음
- 보관함은 게임적으로 무제한
- 자동배치/추천배치 기본실행 없음
- 이동가구 한 인스턴스는 한 위치에만 존재
- 매도/퇴거 이사에서는 이동가구 전량회수
- 기존집 보유 다주택 이사에서는 선택가구만 이동
- 보유주택별 Grid/가구/시공상태 동시보존
- 플레이어 전체 활성 주거대출 V0.1 최대 1개
- 전세대출 일부상환 금지
- HOME_LOAN 원리금균등/360개월/다음월 첫상환
- HOME_LOAN 일부상환 시 잔여만기 유지 + 월상환 재계산
- 일반 연체/압류/경매/파산 상태 없음
- 실직 즉시 대출회수/강제매도 없음
- Market Cycle은 고정, Seed/random 없음
- REGION 이벤트 시세 직접효과 없음 V0.1
- Cycle 누적가격 초기화 없음, 장기 완만한 우상향, Hard Cap 없음
- 매물가격 생성 후 LOCK
- 임대계약 가격 계약기간 고정
- 모든 OWNED_PROPERTY current_market_value 월별 갱신
- Snapshot 신규유저만 적용
- Household State = SOLO/PARTNER/FAMILY_WITH_CHILD, 생물학적 노화 없음
- PARTNER/FAMILY 비필수
- 작은집 가족거주 가능, recommended size는 soft pressure
- 랜덤 이별/가족사망/영구손실 없음
- 현실 계절/날씨와 게임 연출 강제연동 없음
- 생활씬 발생 07, 기록/공유 14
- 수동 Photo만 저장한도 적용
- 자산순위 랭킹 없음
- current residence 항상 1개
- 다주택 보유수 gameplay Hard Cap 없음
- 단순 보유집 방문은 current residence 변경 아님
- 추가주택 V0.1 현금구매
- V0.1 임대수익/고정보유세 없음
- 주거 도감은 한번 획득하면 영구
- 모든 OWNED_PROPERTY는 Maintenance 후보
- Property Maintenance 발생량은 보유수에 따라 실제 증가
- Property 이벤트는 글로벌 중요 CHOICE cap과 분리
- Property Issue는 linked_property_id 단위
- 오프라인에서도 모든 Property를 월별 순차처리
- 수백 게임년 플레이에서 career level은 1~5로 유지하되 명목소득을 영구고정하지 않음

---

# 28. 향후 확장 영역

핵심 번호형 상세기획 00~16은 현재 확정 완료.

향후 16 후속으로 필요할 수 있는 별도 확장:

```text
SECOND_HOME_STAY
RENT_OUT
PROPERTY_MANAGER
MULTI_HOME_LOAN
HOLDING_COST
```

이들은 현재 V0.1 운영항목이 아니다.

---

# 29. 관리 우선순위

## P0 — 출시 전

- 시간/경제
- 직장/급여/통근
- 부동산 가격/Starting Market Snapshot
- 매물/floorplan
- 가구/해금/시공
- 광고/부업
- 이사/보관
- 핵심 이벤트
- 대출
- 계절/날씨
- 생활앨범/Photo/외부공유

## P1 — 라이브 운영 중요

- 시즌가구
- 특별매물
- 추천
- 생활씬 신규콘텐츠
- 이벤트/후속체인/밸런스
- Snapshot 분기운영/재계약 cap
- Household 프로필/콘텐츠
- 신규 회사/지역/가구/floorplan
- 장기 명목소득 index 운영값(기능 활성 시)

## P2 — 고도화

- 게임 내 집구경/Reaction/Featured
- 소셜 moderation
- 다주택/주거도감/Property 관리 UI
- 고급 인테리어/구조변경

후속 투자확장(RENT_OUT/MULTI_HOME_LOAN 등)은 P2 이후 별도 판단.

---

# 30. 운영 Source of Truth

1. 해당 시스템 상세 MD
2. 본 `15_admin.md`
3. 실제 어드민 데이터

상충 시 최신 상세 MD 정책을 우선하고 본 문서를 즉시 동기화한다.

---

# 31. 캐릭터 생활 상세 관리

출처: `07_character_life.md`, `14_healing_social.md`

핵심 스탯:

```text
ENERGY
STRESS
HAPPINESS
```

범위 기본 0~100.

관리:

```text
life_stat_type
min_value
max_value
status_range_min
status_range_max
status_label
```

업무/통근 영향:

```text
impact_profile_id
source_type
source_key
energy_delta
stress_delta
happiness_delta
free_time_modifier
```

생활행동:

```text
life_action_id
category
required_furniture_tags
required_space_usage
required_feature_tags
required_energy
required_free_time
energy_delta
stress_delta
happiness_delta
career_growth_delta
auto_action_weight
season_conditions
weather_conditions
time_conditions
life_rhythm_conditions
cooldown
```

반복방지:

```text
recent_action_history_count
same_action_repeat_penalty
same_furniture_repeat_penalty
unused_space_weight_bonus
```

최근행동 3~5개 테스트.

계절:

```text
SPRING / SUMMER / AUTUMN / WINTER
season_duration_game_months = 3
```

날씨:

```text
CLEAR / CLOUDY / RAIN / SNOW
```

계절별 weight를 관리하고 현실날씨와 연동하지 않는다.

생활리듬 초기 가안:

- 월 30분
- 약 4 life cycle
- cycle 약 7.5분
- weekday 약5 / holiday 약2.5

번아웃 threshold/지속/회복/패널티도 어드민.

오프라인 특수 생활씬 실제 발견은 자동처리하지 않는다.

---

# 32. 광고/부업 상세 관리

보상 profile:

```text
profile_id
reward_formula_type
reward_ratio
minimum_reward
maximum_reward
freeze_for_game_month
```

횟수:

- 회사 기본
- 통근보정
- 생활환경
- 이벤트 추가
- min/max

부족 CTA:

```text
purchase_context
cta_enabled
priority
copy
show_possible_monthly_earning
```

문맥:

```text
FURNITURE_PURCHASE
INTERIOR_PURCHASE
MOVE_CONTRACT
JEONSE_CONTRACT
HOME_PURCHASE
EVENT_COST
PROPERTY_REPAIR
```

추적:

- 시작/완료율
- CTA→부업
- 광고 후 구매
- 저축형 사용
- progression 속도

---

# 33. 이사 / 보관함 상세 관리

출처: `09_moving_inventory.md`, `16_multi_property.md`

이사비:

```text
move_cost_profile_id
housing_progression_tier
base_move_cost
```

가구:

```text
furniture_id
movable
storage_enabled
discard_enabled
discard_protection_type
```

다주택 위치 filter:

- GLOBAL STORAGE
- 각 property
- 다른 집에 배치중

MVP/매도/임대퇴거:

```text
해당 집 PLACED → MOVING → STORED
```

기존집 보유이사:

```text
미선택 가구 → 기존 property에 PLACED 유지
선택 가구 → MOVING → STORAGE/새집 직접배치
```

관리 가능한 copy:

- 기존집 매도/보유 선택
- 가져갈 가구 선택
- 집에 남는 시공
- 새집 빈공간
- 위치충돌

과거 final snapshot은 매도/퇴거 시 생성한다.

보유중 property는 Live House이며 final snapshot으로 닫지 않는다.

---

# 34. 이벤트 상세 관리

출처: `10_events.md`, `16_multi_property.md`

## 34.1 Event Master

```text
event_id
name
category
event_type
occurrence_type
event_scope
event_group
priority
condition_profile
weight
cooldown_months
group_cooldown_months
available_from
available_until
max_per_month
max_lifetime
blocks_same_event_chain
is_negative_major
is_positive_major
is_active
```

`event_type`:

```text
AUTO / RECORD / CHOICE
```

`occurrence_type`:

```text
RANDOM / SCHEDULED / FOLLOWUP
```

`event_scope`:

```text
PLAYER
CAREER
CURRENT_RESIDENCE
OWNED_PROPERTY
REGION
```

주택 이벤트 인스턴스에는 `linked_property_id`를 보존한다.

## 34.2 글로벌 빈도

- 글로벌 RANDOM 약 40~60%
- 글로벌 중요 CHOICE 월 0~1개 목표
- SCHEDULED/FOLLOWUP 별도

Property Maintenance는 이 cap과 별도.

## 34.3 Event Relation

```text
source_event_group
target_event_group
block_months
modifier_months
weight_modifier
condition_profile
```

Property 중복/cooldown은 `event_group + linked_property_id` 범위를 지원한다.

## 34.4 Property Maintenance Profile

```text
property_event_profile_id
event_id
housing_type
build_age_min
build_age_max
condition_grade
base_weight
season_modifier_profile
feature_modifier_profile
is_active
```

모든 owned property를 각각 판정한다.

## 34.5 Property Issue

```text
issue_type
severity_profile
repair_cost_profile
escalation_profile
blocked_scene_ids
batch_repair_enabled
is_active
```

악화 profile:

```text
base_probability
probability_per_month
max_probability
cost_multiplier
stress_per_month
environment_penalty
max_defer_months
escalated_event_id
```

비거주집 stress는 0 또는 매우 낮게 설정 가능.

## 34.6 Property 관리 UI

관리:

- NORMAL / NEEDS_ATTENTION / ISSUE_ACTIVE 문구
- 현재 residence 우선표시
- 관리리포트 제목/요약
- 일괄수리 대상/문구
- Property Queue badge

발생건수 자체를 UI 편의를 이유로 cap하지 않는다.

## 34.7 Followup

```text
followup_rule_id
source_event_id
source_choice_id
followup_type
delay_min_months
delay_max_months
followup_event_id
base_probability
required_state_ids
condition_profile
weight
preserve_linked_property
```

Property followup은 기본적으로 linked property를 유지한다.

## 34.8 Event KPI

기존 글로벌 KPI +:

- 보유주택 수별 Maintenance 발생수
- 신규/미해결 Issue 수
- 평균 수리비
- 일괄수리율
- 미루기/악화율
- 1/3/10/30/100/300채 월 기대비용
- Property Queue 처리시간

---

# 35. 대출 상세 관리

출처: `11_loan.md`, `16_multi_property.md`

상품:

```text
JEONSE_LOAN
HOME_LOAN
```

V0.1 구조정책:

```text
active_housing_loan_count <= 1 per player
```

즉 current residence가 아니라 플레이어 전체 기준.

HOME_LOAN 담보집이 비거주 OWNED_PROPERTY가 되어도 대출은 유지한다.

신규금리:

```text
loan_product_id
new_loan_interest_rate
effective_from
effective_until
```

HOME_LOAN:

```text
repayment_type = EQUAL_TOTAL_PAYMENT
default_term_months = 360
partial_repayment_enabled = true
full_repayment_enabled = true
minimum_partial_repayment_amount = 1000000
partial_repayment_term_policy = KEEP_REMAINING_TERM
prepayment_fee_rate = 0
first_payment_offset_months = 1
proration_enabled = false
```

JEONSE:

```text
repayment_type = INTEREST_ONLY
partial_repayment_enabled = false
principal_settlement_trigger = JEONSE_CONTRACT_END
```

한도:

```text
maximum_loan = min(property_based_limit, affordability_based_limit)
```

관리:

- property value ratio
- equity ratio
- minimum_free_income
- safety_buffer
- Household contribution 인정률
- 재직/소득조건
- 이직 affordability threshold

다주택 추가주택 V0.1은 현금구매이며 `additional_property_loan_enabled=false`.

---

# 36. 부동산 시세 상세 관리

출처: `12_market_price.md`, `16_multi_property.md`

핵심 운영대상은 신규게임 Starting Market Snapshot.

## 36.1 Snapshot

```text
snapshot_id
name
effective_from
effective_until
status
data_reference_period
operator_note
created_at
published_at
```

상태:

```text
DRAFT / PUBLISHED / RETIRED
```

기본 분기검토 추천.

## 36.2 Snapshot Price

```text
snapshot_id
region_id
contract_type
market_type
base_unit_price
```

## 36.3 Publish 검증

- 기간 중복/공백
- 필수 region/contract/market type 누락
- 0/음수 가격
- 이전 Snapshot 변화율 경고
- 첫 월세 선택 가능성
- 첫 전세/자가 progression 변화

## 36.4 Renewal

```text
contract_type
renewal_increase_cap
renewal_decrease_cap
```

## 36.5 모든 보유주택 평가

모든 OWNED_PROPERTY의 current_market_value를 개인 SALE market index로 월별 갱신한다.

관리 UI/KPI:

- 보유집별 구입가/현재가/보유기간
- property net equity
- total home equity
- Snapshot별 progression
- 50/100/300년 가격표시
- 100채 이상 평가성능

Market Cycle 순서/36개월/랜덤 없음/Hard Cap 없음 등은 코드정책.

---

# 37. 라이프스테이지 상세 관리

출처: `13_life_stage.md`

상태:

```text
SOLO
PARTNER
FAMILY_WITH_CHILD
```

Profile:

```text
household_state
name
living_cost_modifier
partner_contribution
recognized_loan_income_ratio
recommended_household_size
sort_order
is_active
```

PARTNER 제안:

```text
minimum_social_months
condition_profile
proposal_event_id
reproposal_cooldown_months
reproposal_enabled
```

FAMILY 제안:

```text
required_household_state = PARTNER
minimum_partner_months
condition_profile
proposal_event_id
reproposal_cooldown_months
```

Housing preference:

```text
space_weight
storage_weight
privacy_weight
education_weight
bathroom_weight
living_environment_weight
recommended_room_count
```

교육환경:

```text
region_id
education_environment_score
education_label
```

Household Content Unlock:

```text
household_state
content_type
content_id
purchase_enabled
preview_enabled
priority
```

PARTNER/FAMILY는 current residence에서만 실제 Household 생활효과를 적용한다.

---

# 38. 힐링 / 생활앨범 / 공유 / 소셜 상세 관리

출처: `14_healing_social.md`, `16_multi_property.md`

## 38.1 계절 / 날씨

```text
season_duration_game_months = 3
```

계절별 weather weight / visual / sound를 관리.

## 38.2 생활앨범

탭/카테고리:

```text
CURRENT_HOME
LIFE_SCENES
OWNED_PROPERTIES
PROPERTY_COLLECTION
HOUSING_HISTORY
```

생활씬 설정:

```text
life_scene_id
album_enabled
album_category_id
album_title
album_description
first_discovery_reward_profile
silhouette_enabled
hint_enabled
hint_copy
representative_frame_profile
```

PARTNER/FAMILY 미선택을 전체 미완성으로 계산하지 않는다.

다주택 주거도감은 completion % 허용.

## 38.3 Photo

```text
manual_photo_save_limit_per_game_month = 3
manual_photo_save_limit_per_house = 20
```

월한도는 플레이어 전체, house 한도는 property별.

## 38.4 Share Card

```text
HOME_CARD
MOVE_CARD
MILESTONE_CARD
LIFE_SCENE_CARD
HISTORY_CARD
MARKET_HISTORY_CARD
PROPERTY_COLLECTION_CARD
```

관리:

```text
share_card_template_id
card_type
layout_profile_key
visible_field_ids
copy_profile_id
background_profile_key
is_active
```

## 38.5 Featured Property / 향후 Social

FEATURED_PROPERTY는 공유대표집이며 gameplay effect 없음.

향후 Featured House Theme / Reaction / 다양성 가중치 / moderation을 관리한다.

자산/보유주택 수 랭킹은 만들지 않는다.

---

# 39. 다주택 / 주거 컬렉션 / 주택관리 상세 관리

출처: `16_multi_property.md`

`16_multi_property.md` V0.1 상세기획이 다주택의 Source of Truth다.

## 39.1 다주택 해금 / 노출

관리 후보:

```text
multi_property_enabled
minimum_owned_home_history
minimum_social_months
multi_property_tutorial_enabled
unlock_copy_profile
```

구조적으로 첫 자가 이후부터 가능하며 한남 도달을 hard gate로 만들지 않는다.

## 39.2 Current Residence 변경

관리:

```text
owned_residence_move_cost_profile
residence_change_cooldown_months
residence_change_copy_profile
```

초기 cooldown 테스트 후보:

```text
3 game months
```

단순 방문은 residence 변경이 아니다.

## 39.3 추가주택 구매

V0.1 정책값:

```text
additional_property_cash_only = true
additional_property_loan_enabled = false
```

관리 가능한 표시/검증값:

- 구매 CTA 노출
- 현금 부족 안내
- 기존집 보유/매도 copy
- sale cost profile

기존집 보유 시 예상 매도 순자산을 자금으로 선반영하지 않는 것은 코드규칙.

## 39.4 보유주택 / 대표집

관리 UI:

- current residence badge
- FEATURED_PROPERTY badge
- purchase/current value 표시
- ownership duration 표시
- Maintenance 상태
- 방문/꾸미기/이사/매도 CTA

보유주택 수 gameplay hard cap은 두지 않는다.

## 39.5 주거 도감

관리:

```text
collection_category_id
collection_type
name
sort_order
completion_display_enabled
is_active
```

slot:

```text
collection_slot_id
collection_category_id
collection_key
condition_profile
badge_asset_key
completion_reward_profile
is_active
```

기본 축:

```text
REGION
HOUSING_TYPE
FEATURE
FLOORPLAN_TEMPLATE
```

한 번 획득한 도감 slot은 매도 후에도 유지.

현재 `내 집` 목록은 실제 OWNED만 표시.

## 39.6 컬렉션 보상

비경제 보상 중심:

- 배지
- 공유프레임
- 오브제
- 장식품
- Photo/앨범 요소

큰 현금보상은 사용하지 않는다.

## 39.7 집별 가구상태

관련 어드민값은 16/33에 연결하되 위치 엔진은 코드다.

운영 가능한 항목:

- 위치 표시명
- 다른 집에서 가져오기 확인문구
- 기존집 보유 이사 가구선택 문구
- 위치 filter 활성화

가구복제 기능은 제공하지 않는다.

## 39.8 Property Maintenance Event

관리 profile:

```text
property_event_profile_id
event_id
housing_type
build_age_min
build_age_max
condition_grade
base_weight
season_modifier_profile
feature_modifier_profile
is_active
```

집별 확률은 장기 보유규모를 고려해 낮게 설계하고 다음 규모를 필수 QA한다.

```text
1 / 3 / 10 / 30 / 100 / 300채
```

## 39.9 Property Issue / Repair

```text
issue_type
severity_profile
repair_cost_profile
escalation_profile
batch_repair_enabled
blocked_scene_ids
is_active
```

관리:

- 초기수리비
- 미루기 가능여부
- 악화확률
- 월별 비용 증가
- current residence 환경패널티
- 비거주집 stress 여부
- 일괄수리 대상 여부

영구 자산손실은 운영토글로도 제공하지 않는다.

## 39.10 Property Management Report

관리:

```text
property_report_enabled
summary_copy
current_residence_priority
sort_profile
batch_repair_copy
issue_count_badge_profile
```

여러 집에서 발생한 사건은 한 리포트에 묶어 표시한다.

발생량 자체는 UI 때문에 cap하지 않는다.

## 39.11 Offline

운영 가능한 것은 copy/표시/확률 profile.

코드규칙:

- 최대 3게임개월
- 각 월 모든 owned property 순회
- 신규 Maintenance 판정
- 기존 Issue 악화
- CHOICE 자동확정 없음
- 복귀 통합리포트

## 39.12 KPI

- 다주택 최초해금/첫 추가구매 시점
- 보유주택 수 분포
- 기존집 매도 vs 보유 비율
- 추가주택 현금구매율
- 지역/유형/Feature/Floorplan 도감 완성률
- 특별매물 컬렉션 구매율
- 집별 재방문/꾸미기율
- 다른 집 가구이동률
- 평균/최대 보유주택 수
- 1/3/10/30/100/300채 Maintenance 발생량
- 평균 수리비/미해결 Issue/악화율
- 일괄수리 사용률
- Property Queue 누적량
- 관리부담으로 인한 다주택 구매중단/이탈
- 100채 이상 월경계 처리성능

## 39.13 V0.1에서 코드로 고정

- current residence 항상 1개
- 보유주택 gameplay hard cap 없음
- 구매와 residence 변경 분리
- 기존집 보유 시 미실현 순자산 구매자금 사용 금지
- 이동가구 인스턴스 한 위치
- property별 Grid/인테리어/가구상태 보존
- 매도 시 가구 전량회수
- 보유이사 시 선택가구만 이동
- V0.1 추가주택 현금구매
- 플레이어 전체 활성 주거대출 최대 1개
- V0.1 임대수익 없음
- V0.1 고정 다주택 보유세/관리비 없음
- 모든 OWNED_PROPERTY 월별 시세평가
- 주거 도감 영구발견
- 모든 OWNED_PROPERTY Maintenance 후보
- Property 발생량이 보유수에 따라 증가
- 글로벌 중요 CHOICE cap과 Property 이벤트 분리
- duplicate/cooldown 범위 `event_group + linked_property_id`
- 비거주 Issue는 해당 Property 중심 영향
- 랜덤 영구 주택/가구 손실 금지
- 오프라인 모든 property 월별 순차처리

---

# 40. 최종 운영 체크

00~16 상세기획 변경 시 본 문서에서 반드시 함께 확인한다.

특히 교차영향이 큰 조합:

```text
경제 ↔ 대출 ↔ 다주택
장기 명목경제 ↔ Market Hard Cap 없음 ↔ career salary index
이사 ↔ Grid ↔ 가구 위치
시장 ↔ 모든 보유주택 평가
이벤트 ↔ Property Maintenance
Household ↔ current residence
앨범 ↔ Live Property ↔ 주거 역사
```

기획과 어드민이 서로 다른 상태로 배포되지 않도록 한다.
