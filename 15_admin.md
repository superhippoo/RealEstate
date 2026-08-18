# 15_admin.md
기준일: 2026-08-18
상태: V0.1 운영/어드민 관리항목 정리

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`에서 운영 중 변경 가능성이 있는 콘텐츠, 수치, 조건, 노출정책을 코드 하드코딩이 아니라 어드민에서 관리하기 위한 통합 인벤토리다.

이 문서는 상세기획 문서를 대체하지 않는다.

- 각 시스템의 의미, 규칙, 플레이 의도는 해당 상세 MD가 기준이다.
- 이 문서는 그중 `운영 중 조정하거나 추가/삭제할 가능성이 있는 값`만 모아서 어드민 관리 대상으로 정리한다.
- 코드 구조와 상태전이 로직 자체는 어드민 대상이 아니다.

핵심 원칙:

> 게임의 규칙 구조는 코드로 구현하고, 운영 중 변경 가능성이 있는 콘텐츠·수치·조건·노출값은 어드민에서 관리한다.

---

# 2. 앞으로의 문서 운영 규칙

07 이후 상세 MD를 작성할 때는 기획 확정과 동시에 해당 기능의 어드민 관리항목을 이 문서에 추가한다.

예:

```text
07_character_life.md 확정
→ 생활 스탯/행동/회복량/발생조건 중 어드민 대상 추출
→ 15_admin.md의 캐릭터 생활 관리 섹션에 동시 반영
```

따라서 이후 `07~14` 상세기획과 `15_admin.md`는 함께 업데이트한다.

---

# 3. 어드민 대상과 코드 대상의 구분

## 3.1 어드민으로 관리하는 것

원칙적으로 다음은 어드민 관리 대상으로 본다.

- 콘텐츠 추가/삭제/활성화 여부
- 이름, 설명, 표시 문구
- 가격과 보상
- 확률
- 기간
- 횟수
- 조건값
- 해금조건
- 노출조건
- 추천조건
- 가중치
- 밸런스 계수
- 카테고리/태그
- 콘텐츠 간 연결관계
- 시즌 시작/종료일
- 이벤트 발생조건과 결과값

## 3.2 코드로 관리하는 것

다음은 원칙적으로 어드민 대상이 아니다.

- Grid 충돌 알고리즘
- 4방향 회전 계산 방식 자체
- pathfinding 알고리즘
- interaction point 접근 판정 로직
- 월 경계 처리 엔진
- 온라인/오프라인 시간 계산 엔진
- 상태머신 자체
- `PENDING`, `TEMPORARY_STAY` 등의 상태전이 로직 구조
- 저장/로드 방식
- 데이터베이스 스키마 자체
- 네트워크/동기화 로직
- 기기 시간 조작 방지 로직
- 자동배치 알고리즘
- 공간 용도 자동인식 알고리즘 자체

단, 위 로직에서 사용하는 `기준값/임계값/기간/가중치`는 어드민으로 분리할 수 있다.

---

# 4. 공통 게임 설정 관리

출처: `00_master_policy.md`, `01_economy_balance.md`, `04_time_contract.md`

## 4.1 시간 설정

어드민 관리 후보:

- 게임 1개월에 해당하는 현실 활성시간
  - 현재: 30분
- 오프라인 최대 인정시간
  - 현재: 현실 90분
- 오프라인 최대 진행 게임개월
  - 현재: 3개월
- 월급 임박 UI 강조 시작시간
  - 현재 가안: 월 경계 5분 전
- 계약 기본기간
  - 현재: 24개월
- 계약 만료 1차 안내 시점
  - 현재: 3개월 전
- 계약 만료 재강조 시점
  - 현재: 1개월 전

권장 Admin Key 예:

```text
GAME_MONTH_REAL_SECONDS
OFFLINE_MAX_SECONDS
OFFLINE_MAX_GAME_MONTHS
SALARY_COUNTDOWN_ALERT_SECONDS
DEFAULT_RENTAL_CONTRACT_MONTHS
CONTRACT_NOTICE_MONTHS
CONTRACT_FINAL_NOTICE_MONTHS
```

## 4.2 진행 목표시간

밸런스 테스트를 위해 운영값으로 관리한다.

현재 가안:

- 첫 갖고 싶은 가구: 20~40분
- 첫 방 꾸미기 만족: 1~2시간
- 첫 이사 욕망: 4~8시간
- 첫 전세: 10~20시간
- 첫 자가: 20~40시간
- 중형 아파트: 50~100시간
- 프리미엄 주거: 장기 목표

이 값들은 직접 게임 로직을 움직이는 값이라기보다 밸런스 QA/운영 기준값으로 관리한다.

---

# 5. 경제 밸런스 관리

출처: `00_master_policy.md`, `01_economy_balance.md`

## 5.1 시작 자산

- 시작 현금
  - 현재 가안: 25,000,000원
- 직장별 시작자금 차등 여부
  - 현재 정책: 동일 시작자금

관리 항목:

```text
starting_cash
```

## 5.2 월 생활비/가처분소득 목표

현재 밸런스 목표:

- 정기지출 목표: 월급의 65~80%
- 가처분소득 목표: 월급의 20~35%

어드민 관리 대상:

- 소득구간별 기본 생활비
- 생활비 스케일링 계수
- 라이프스타일 인플레이션 계수
- 보험/기타 고정비
- 주거단계별 소비수준 보정
- 가족/라이프스테이지 추가비용은 13 상세기획 이후 추가

## 5.3 자동 지출 항목

관리 대상 콘텐츠/수치:

- 기본 생활비
- 보험/기타 고정비
- 관리비 기준값/계수
- 계약별 월세
- 대출 월 상환액은 대출 데이터에서 연동

자동지출 처리 순서 자체는 코드 로직이다.

## 5.4 월 이벤트 발생률

현재 초기 가안:

- 월 이벤트 발생률 40~60%

이벤트 상세는 `10_events.md` 확정 시 이 문서에 세분화한다.

관리 후보:

```text
monthly_event_probability
no_event_weight
category_event_weights
```

---

# 6. 광고/부업 경제 관리

출처: `00_master_policy.md`, `01_economy_balance.md`, `03_career.md`, `04_time_contract.md`, `05_furniture.md`

현재 정책상 부업 수입은 일반 게임머니이며 사용처 제한은 없다.

## 6.1 부업 1회 보상

현재 테스트 기준:

- 예상 월 가처분소득의 약 20~25%
- 우선 테스트값: 약 25%

예시:

| 예상 월 가처분소득 | 부업 1회 보상 예시 |
|---:|---:|
| 80만 | 20만 |
| 100만 | 25만 |
| 160만 | 40만 |
| 220만 | 55만 |
| 300만 | 75만 |

어드민 관리 대상:

- 보상 산식 타입
- 보상 비율
- 최소 보상
- 최대 보상
- 진행단계별 보정

## 6.2 월 부업 가능량

현재 기본 테스트값:

- 일반 기준 약 5회/게임월

직장 기본값 예:

- 광화문 안정기업: 6회
- 구로 IT기업: 5회
- 강남 스타트업: 3회

어드민 관리 대상:

- 회사별 기본 부업횟수
- 최소/최대 부업횟수
- 월 초기화 기준
- 생활환경 보정값

## 6.3 통근 보정

현재 V0.1 가안:

- 20분 이하: +1
- 21~40분: 0
- 41~60분: -1
- 61~80분: -2
- 81분 이상: -3

어드민에서 구간과 보정값을 관리한다.

## 6.4 광고 성장속도 목표

현재 테스트 목표:

- 적극 광고 플레이가 무광고 대비 약 1.7~2.2배 빠른 경제 성장

운영 분석/밸런스 목표값으로 관리한다.

## 6.5 광고 노출 진입점

향후 `08_ads_sidejob.md` 상세기획에서 세분화한다.

현재 확인된 주요 진입점:

- 가구 부족액
- 인테리어 시공 부족액
- 이사비 부족액
- 보증금/전세금 부족액
- 매매 자기자본 부족액
- 대출 관련 비용 부족액
- 투자금 부족액

각 진입점의 노출 여부/우선순위/조건은 어드민 관리 대상으로 두는 것이 적합하다.

---

# 7. 직장/커리어 관리

출처: `00_master_policy.md`, `01_economy_balance.md`, `03_career.md`

## 7.1 회사 마스터

회사별 관리 필드:

```text
company_id
company_name
company_type
company_tier
work_district
workload
stability
growth_rate
bonus_profile
benefit_profile
event_profile
is_active
```

회사 등급 후보:

```text
SMALL
MID
LARGE
TOP
```

## 7.2 첫 직장 설정

현재 V0.1:

| 직장 | 초봉 가안 | 근무지 | 업무강도 | 안정성 | 성장성 | 기본 부업기회 |
|---|---:|---|---:|---:|---:|---:|
| 광화문 안정기업 | 300만 | 광화문 | 2/5 | 4/5 | 2/5 | 6 |
| 구로 IT기업 | 330만 | 구로 | 3/5 | 3/5 | 4/5 | 5 |
| 강남 스타트업 | 370만 | 강남 | 4/5 | 2/5 | 5/5 | 3 |

모든 값은 어드민 관리 대상으로 둔다.

## 7.3 회사별 월급표

현재 V0.1 테스트값:

광화문 안정기업:
- Lv1 300
- Lv2 330
- Lv3 380
- Lv4 450
- Lv5 540

구로 IT기업:
- Lv1 330
- Lv2 380
- Lv3 460
- Lv4 570
- Lv5 700

강남 스타트업:
- Lv1 370
- Lv2 450
- Lv3 560
- Lv4 720
- Lv5 900

단위: 만 원/월.

관리 구조:

```text
company_id
career_level
salary
workload_override
sidejob_base_override
bonus_profile
```

## 7.4 커리어 레벨/직급 표시명

현재 내부 레벨:

- career_level 1~5

관리 대상:

- 레벨 수
- 회사유형별 표시 직급명
- 레벨별 급여
- 레벨별 업무강도
- 레벨별 성장계수

## 7.5 승진 조건

로직 구조:

```text
재직기간 + 커리어 성장점수 + 업무/이벤트 결과
```

어드민 관리 대상:

- 최소 재직기간
- 필요 career XP
- 이벤트 가중치
- 자기계발 가중치
- 승진 시 급여표
- 승진 시 업무강도 변화
- 승진 시 부업 가능량 변화
- 승진 제안 노출조건
- 승진 거절/유지 허용 여부

## 7.6 이직 제안

현재 첫 이직 테스트 범위:

- 사회생활 약 12~24개월 이후

어드민 관리 대상:

- 첫 제안 가능 최소/최대 사회생활개월
- 회사별 이직 제안 가중치
- 플레이어 커리어레벨 조건
- 현재 직장 재직기간 조건
- 제안 급여
- 제안 업무강도/안정성/성장성
- 제안 유지기간/만료정책은 이벤트 상세와 연동

## 7.7 구조조정/퇴직 관련

향후 10 이벤트 상세기획에서 세분화한다.

현재 어드민 후보:

- 회사 안정성별 구조조정 발생확률
- 퇴직금 산정값
- 구직기간 보정
- 재취업 회사풀

---

# 8. 업무지구/통근 관리

출처: `00_master_policy.md`, `02_real_estate.md`, `03_career.md`

## 8.1 업무지구 마스터

현재 후보:

- 광화문
- 여의도
- 구로
- 강남
- 판교

관리 필드:

```text
work_district_id
name
is_active
sort_order
```

## 8.2 통근시간 테이블

MVP는 실시간 길찾기가 아니라:

```text
주거지역 × 업무지구 = 통근시간
```

테이블 방식이다.

따라서 전 조합의 통근분 값을 어드민에서 관리한다.

관리 예:

```text
residential_region_id
work_district_id
commute_minutes
```

## 8.3 통근 영향 보정

통근시간이 다음에 미치는 보정값을 별도 관리한다.

- 부업 가능횟수
- 자기계발 효율
- 스트레스
- 체력
- 생활행동 기회

정확한 스트레스/체력 값은 `07_character_life.md` 확정 시 추가한다.

---

# 9. 부동산 지역 관리

출처: `02_real_estate.md`

## 9.1 주거지역 마스터

초기 생활권 후보:

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

관리 필드:

```text
region_id
name
is_active
sort_order
region_group
premium_segment
```

## 9.2 지역별 계약유형 가격지수

월세/전세/매매를 별도 관리한다.

```text
region_id
rent_index
jeonse_index
sale_index
```

현실지수와 게임용 압축지수를 분리 보관할 수 있다.

권장 필드:

```text
real_rent_index
real_jeonse_index
real_sale_index
game_rent_index
game_jeonse_index
game_sale_index
```

## 9.3 기준지역

현재 V1 조사 기준:

- 서대문 = 1.00

기준지역 역시 변경 가능 값으로 관리한다.

## 9.4 게임용 압축계수

현재 V1 테스트:

- 현실 계수의 0.65승

관리 항목:

```text
real_to_game_compression_exponent
```

현재: `0.65`

---

# 10. 주택 시장유형 계수 관리

출처: `02_real_estate.md`

실거래 시장유형:

```text
MULTIFAMILY
OFFICETEL
APARTMENT
```

계약유형별 계수를 별도 관리한다.

## 10.1 현실 계수 V1

| 계약 | MULTIFAMILY | OFFICETEL | APARTMENT |
|---|---:|---:|---:|
| 매매 | 1.00 | 0.76 | 1.79 |
| 전세 | 1.00 | 1.18 | 1.57 |
| 월세 | 1.00 | 1.22 | 1.14 |

## 10.2 게임용 압축 계수 V1

| 계약 | MULTIFAMILY | OFFICETEL | APARTMENT |
|---|---:|---:|---:|
| 매매 | 1.00 | 0.84 | 1.46 |
| 전세 | 1.00 | 1.11 | 1.34 |
| 월세 | 1.00 | 1.14 | 1.09 |

관리 키 예:

```text
contract_type
market_type
real_coefficient
game_coefficient
```

매매/전세/월세에 같은 값을 공유하지 않는다.

---

# 11. 주택 표시유형/레이아웃 관리

출처: `02_real_estate.md`, `06_house_grid.md`

## 11.1 게임 표시 주택유형

현재 기본 6종:

- 옥탑
- 원룸
- 투룸
- 오피스텔
- 빌라
- 아파트

관리 항목:

```text
housing_type_id
name
market_type
layout_type
is_active
sort_order
base_traits
```

## 11.2 Layout Type

현재 구조:

```text
ROOFTOP
ONE_ROOM
TWO_ROOM
ETC
```

향후 쓰리룸/아파트 세부 타입 등 확장 가능.

## 11.3 옥탑 보정

옥탑은 실거래 API에서 직접 추출한 계수가 아니므로 게임 디자인 값으로 별도 관리한다.

```text
rooftop_modifier
```

현재 수치는 미확정.

---

# 12. 한남 프리미엄 관리

출처: `02_real_estate.md`

내부 ID:

```text
HANNAM_PREMIUM
```

일반 용산지역과 별도 프리미엄 세그먼트로 관리한다.

어드민 관리 대상:

- 프리미엄 권역 활성화 여부
- 매매/전세/월세 게임용 가격지수
- 등장 조건
- 주거 progression tier
- 사용 가능한 평면도 템플릿
- 프리미엄 가구/인테리어 해금 연결
- 희귀 Feature 풀

V1 게임용 지수는 `02_real_estate.md` 조사값을 기준으로 하되 밸런스 테스트 후 조정 가능해야 한다.

---

# 13. 매물 마스터/생성 관리

출처: `02_real_estate.md`, `04_time_contract.md`, `06_house_grid.md`

## 13.1 매물 데이터

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
sunlight_grade
view_grade
parking
elevator
special_features
listing_duration
rarity
ownership_type
housing_progression_tier
is_active
```

실제 구현이 완전 고정 매물 DB가 아니라 템플릿 생성형이라면 위 값 중 일부는 `생성규칙`으로 관리한다.

## 13.2 첫 집 추천

첫 직장 선택 후 추천 매물 수:

- 현재 정책: 4~6개

어드민 관리 대상:

- 추천 매물 수 최소/최대
- 직장별 추천 지역 가중치
- 시작자금 대비 보증금/월세 범위
- 통근시간 범위
- 주택유형 가중치
- 신축/구축 비중

## 13.3 매물 유지기간

현재 정책:

- 일반 매물: 지속 재생성
- 추천 매물: 2~4개월 유지
- 희귀 매물: 1~2개월 유지

어드민 관리 대상:

- 매물종류별 최소/최대 유지기간
- 희귀도별 생성확률
- 추천 매물 갱신주기
- 일반 매물 교체주기

## 13.4 희귀 매물 조건

관리 가능한 특성 예:

- 코너 통창
- 한강뷰
- 남산뷰
- 테라스
- 욕조
- 옥상
- 대형 창
- 희귀 평면

각 특성별:

```text
feature_id
name
rarity_weight
price_modifier
allowed_housing_types
allowed_regions
required_floorplan_features
listing_duration_profile
is_active
```

## 13.5 오프라인 희귀 매물 보호

정책 로직 자체는 코드지만 다음 값은 관리 가능하다.

- 희귀 매물 최초 노출 후 유지기간
- 보호대상 rarity 기준

플레이어가 한 번도 보지 못한 희귀 매물이 오프라인 중 생성·소멸하지 않는 정책은 유지한다.

---

# 14. 부동산 가격공식 파라미터

출처: `02_real_estate.md`

가격구조:

```text
기준가격
× 지역가격지수
× 주택유형계수
× 면적계수
× 연식계수
× 개별특성계수
× 게임밸런스 보정
```

어드민 관리 대상:

- 계약유형별 기준 단가
- 지역지수
- 시장유형 계수
- 면적 band/계수
- 연식 band/계수
- 신축/구축 보정
- 층수 보정
- 채광 보정
- 뷰 보정
- 주차 보정
- 엘리베이터 보정
- 특수 Feature 보정
- 게임밸런스 최종 보정

가격 계산식 구조 자체는 코드로 관리한다.

---

# 15. 계약/이사 시간 관리

출처: `04_time_contract.md`

## 15.1 임대계약

현재 확정값:

- 기본 계약기간: 24개월
- 준비 안내: 만료 3개월 전
- 최종 강조: 만료 1개월 전

관리 대상:

- 계약유형별 계약기간
- 안내 시점
- 재계약 보증금/월세 산정 보정
- 중개비
- 이사비
- 조기이사 추가비용

## 15.2 TEMPORARY_STAY

현재 정책:

- 최대 3개월
- 기존 주거비 계속 발생
- 임시거주 추가비용 발생
- 신규 대형 인테리어/집 귀속 시공 제한
- 3개월 종료 후 주거 결정 전까지 시간 정지

현재 월세형 추가비용 테스트 범위:

- 기존 월세의 약 10~20%

어드민 관리 대상:

```text
temporary_stay_max_months
temporary_stay_rent_surcharge_rate
temporary_stay_jeonse_fee
temporary_stay_restricted_action_ids
```

## 15.3 조기이사

관리 대상:

- 정상 이사비
- 중개비
- 중도이사 추가비용
- 계약 잔여기간별 추가비용 보정이 필요할 경우 해당 테이블

## 15.4 자가 갈아타기

`현재 거주 중인 유일한 자가 → 다음 거주지 확정 후 매도` 정책은 코드 규칙이다.

어드민 관리 후보:

- 매도비용/중개비
- 예상 매도가 산식 보정
- 매도 관련 세금/비용을 단순화해서 넣을 경우 해당 수치

---

# 16. 가구 카탈로그 관리

출처: `05_furniture.md`, `06_house_grid.md`

가구는 주요 라이브 운영 콘텐츠이므로 거의 모든 콘텐츠 속성을 어드민에서 관리한다.

## 16.1 기본정보

```text
furniture_id
name
category
subcategory
description
thumbnail/model_asset_key
is_active
sort_order
```

## 16.2 가격/상품군

```text
price
price_tier
```

내부 상품군 후보:

- BASIC
- STANDARD
- PREMIUM
- DESIGNER

RPG식 N/R/SR/SSR 등급은 사용하지 않는다.

## 16.3 배치정보

```text
grid_width
grid_height
rotation_allowed
layer
```

회전 엔진은 코드지만 가구별 회전 가능 여부는 어드민 값이다.

## 16.4 색상/스타일

```text
color_variants
style_tags
```

현재 기본 컬러 정책:

- 한 가구당 약 3~5개의 사전 정의 Variant 우선

스타일 후보:

- 내추럴
- 모던
- 미드센추리
- 빈티지
- 미니멀
- 러블리/파스텔

## 16.5 이동/설치 조건

```text
movable
requires_room_type
requires_feature
requires_ownership_type
required_housing_progression_tier
```

## 16.6 Interaction

```text
interaction_types
interaction_direction
interaction_points
```

예:

- 소파: seat_left / seat_center / seat_right
- 침대: sleep_left / sleep_right
- 책상: chair_position

interaction 처리 엔진은 코드지만 콘텐츠별 point 정의는 데이터/어드민 관리 대상으로 둔다.

## 16.7 가구 효과

관리 필드 후보:

```text
recovery_effect
stress_effect
happiness_effect
study_effect
housing_satisfaction_effect
```

다만 직접 커리어/급여 증가 효과는 사용하지 않는다.

## 16.8 판매/노출기간

```text
sale_type
available_from
available_until
rarity
```

- 기본 기능가구는 상시 판매
- 시즌가구/특별컬렉션은 기간 관리 가능

---

# 17. 가구 가격밴드 관리

출처: `05_furniture.md`

가처분소득 대비 권장 가격범위:

- 소형 소품: 월 가처분소득 약 5~20%
- 일반 가구: 약 30~100%
- 욕망 가구: 약 1~3개월 가처분소득
- 프리미엄 가구: 여러 달 저축/부업 가속 필요

관리 대상:

- price_tier별 목표비율
- 카테고리별 최소/최대 가격
- 주거 progression별 권장 가격대
- 신규 가구 가격 자동추천 기준을 만들 경우 그 계수

---

# 18. 가구/주거 Progression 해금 관리

출처: `05_furniture.md`, `06_house_grid.md`

핵심 정책:

> 더 크고 좋은 집으로 이동하면 새로운 가구군과 인테리어 콘텐츠가 실제 해금된다.

어드민에서 `주거 progression tier ↔ 해금 콘텐츠` 매핑을 관리한다.

예:

### 원룸

구매 가능:
- 원룸 생활 가구
- 소형 침대/책상/소파
- 기본 수납/장식

미리보기:
- 투룸용 일부 가구

### 투룸

새로 해금:
- 3인 소파
- 본격 식탁
- 큰 책장
- 홈오피스 가구
- 확장 수납

### 쓰리룸

새로 해금:
- 독립 서재 가구군
- 드레스룸 가구군
- 취미방
- 홈짐
- 대형 식탁/소파

### 아파트

새로 해금:
- 대형 거실가구
- 프리미엄 주방 관련 가구
- 대형 수납

### 프리미엄 주거

새로 해금:
- 홈바
- 와인셀러
- 대형 오디오
- 프리미엄 드레스룸
- 홈카페
- 테라스 가구
- 프리미엄 취미공간

관리 구조 예:

```text
housing_progression_tier
content_type
content_id
purchase_enabled
preview_enabled
unlock_priority
```

`현재 단계 + 다음 단계 일부 미리보기` 범위도 어드민에서 관리한다.

---

# 19. 가구 추천/상점 노출 관리

출처: `05_furniture.md`

## 19.1 상점 섹션

관리 후보:

- 새로 나온 가구
- 지금 집에 추천
- 인기
- 공간별
- 스타일별
- 가격대별

각 섹션:

```text
section_id
name
sort_order
is_active
exposure_rule
item_limit
```

## 19.2 현재 집 상태 기반 추천

추천 룰 예:

- 침대 있음 + 협탁 없음 → 협탁 추천
- 책상 있음 + 작업조명 없음 → 데스크램프 추천
- 큰 거실 입주 → 3인 소파 추천

관리 구조 후보:

```text
recommendation_rule_id
condition_tags
recommended_category_or_item
priority
copy
is_active
```

## 19.3 `이 가구를 놓을 수 있는 집 보기`

연결 로직은 코드지만:

- CTA 노출 대상 가구
- 추천할 주거 progression tier
- 최소 필요 Grid/Feature 조건

등은 데이터 관리 대상으로 둘 수 있다.

---

# 20. 생활씬/조합행동 관리

출처: `00_master_policy.md`, `05_furniture.md`

07 상세기획 전 현재까지 확인된 관리항목을 우선 정의한다.

## 20.1 생활씬 마스터

```text
scene_id
name
scene_type
required_furniture_tags
required_space_usage
required_feature_tags
season_condition
time_condition
weather_condition
character_state_condition
reward_profile
collection_enabled
is_active
```

## 20.2 조합 생활씬

예:

- 소파 + TV + 사이드테이블 + 겨울 → 귤 먹으며 TV 보기
- 욕조 + 욕실조명 + 입욕 요소 → 반신욕
- 테라스 + 테이블 + 커피머신 → 테라스 커피
- 책장 + 독서의자 + 스탠드 + 밤 → 밤 독서

관리 대상:

- 필요한 가구/태그
- 공간조건
- 계절/시간/날씨
- 발생 우선순위
- 일반 행동 대비 추가 보상
- 최초발견 보상
- 생활앨범 기록 여부

정확한 보상수치와 캐릭터 스탯 연결은 `07_character_life.md` 확정과 동시에 업데이트한다.

---

# 21. 평면도 템플릿 관리

출처: `02_real_estate.md`, `06_house_grid.md`

## 21.1 Floorplan Template

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
ownership_type_rule
rarity
is_active
```

## 21.2 평면도 풀

현재 MVP 제작량 가안:

- 원룸 5~8개
- 투룸 5~8개
- 쓰리룸 4~6개
- 오피스텔 4~6개
- 소형 아파트 4~6개
- 중형 아파트 3~5개
- 총 약 25~35개

실제 템플릿 추가/삭제/활성화는 어드민에서 관리한다.

## 21.3 템플릿 배정 가중치

매물 생성 시:

- 주택유형
- 평형
- 지역
- 신축/구축
- rarity

에 따른 템플릿 선택 가중치를 관리할 수 있다.

---

# 22. Grid/공간 기준값 관리

출처: `06_house_grid.md`

## 22.1 기본 Grid 환산값

현재:

- 1 Grid Cell ≈ 25cm × 25cm
- 1평 ≈ 53 Cell은 환산참고값

Grid 알고리즘 자체는 코드지만 이 환산 기준은 시스템 설정값으로 관리 가능하다.

## 22.2 공간환경 표시등급

사용자 표시 예:

- 매우 좋음
- 좋음
- 보통
- 부족

어드민 관리 대상:

- sleep_environment_score 구간
- work_environment_score 구간
- relax_environment_score 구간
- storage_score 구간
- 각 구간 표시문구

정확한 스코어 산식은 07과 함께 확정한다.

## 22.3 공간 용도 판정 기준

자동인식 알고리즘은 코드지만 각 용도의 핵심 가구/태그와 판정 임계값은 데이터화할 수 있다.

예:

```text
space_usage_type = OFFICE
required_tags = DESK, OFFICE_CHAIR
optional_tags = PC, BOOKSHELF, DESK_LAMP
minimum_score = TBD
```

---

# 23. 주택 Feature 관리

출처: `02_real_estate.md`, `06_house_grid.md`

현재 Feature 후보:

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

관리 필드:

```text
feature_id
name
description
allowed_housing_types
allowed_floorplan_templates
rarity_weight
price_modifier
unlockable_furniture_tags
unlockable_scene_ids
is_active
```

Feature는 가격만 올리는 값이 아니라 새로운 가구와 생활씬을 여는 연결 데이터로 관리한다.

---

# 24. 전월세/자가 인테리어 권한 관리

출처: `06_house_grid.md`

핵심 정책:

- 전세/월세: 이동가구와 원상복구 가능한 꾸미기 중심
- 자가: 집 귀속 시공 본격 해금

관리 구조 후보:

```text
ownership_type
interior_action_id
is_allowed
required_housing_progression_tier
required_feature_id
```

현재 자가에서 해금하는 시공 후보:

- 벽지/도장
- 바닥
- 붙박이장
- 욕실 교체
- 욕조 설치
- 주방 시공
- 아일랜드
- 대형 빌트인
- 고정 조명
- 전체 인테리어

MVP 이후 자가 확장:

- 가벽
- 벽 철거
- 방 합치기
- 구조 변경

---

# 25. 인테리어 시공 콘텐츠 관리

출처: `00_master_policy.md`, `01_economy_balance.md`, `05_furniture.md`, `06_house_grid.md`

시공은 가구 이후의 큰 경제 싱크다.

현재 예시 가격 가안:

- 도배: 250만
- 바닥: 400만
- 욕실: 1,000만
- 주방: 1,500만
- 전체 리모델링: 4,000만

모두 확정값이 아니므로 어드민에서 관리한다.

관리 필드 후보:

```text
interior_action_id
name
category
price
required_ownership_type
required_feature_id
required_housing_progression_tier
space_type
visual_result_key
effect_profile
is_active
```

---

# 26. 가구/콘텐츠 제작량 관리 목표

출처: `05_furniture.md`, `06_house_grid.md`

현재 MVP 콘텐츠량 목표 가안:

가구:
- 침실 15~20종
- 거실 25~30종
- 주방/식사 15~20종
- 서재 10~15종
- 장식 30종 이상
- 욕실/기타 10종 이상
- 총 약 100종 전후

평면도:
- 총 약 25~35개

이는 직접 런타임 설정값보다 콘텐츠 제작/운영 관리 지표로 사용한다.

---

# 27. 어드민에서 별도로 관리하지 않을 확정 로직

현재 00~06 기준으로 다음은 코드/기획 규칙으로 유지한다.

- 광고 수입은 일반 게임머니와 동일하게 취급
- 광고로 월급/승진 직접 구매 불가
- 온라인 활성 상태에서만 온라인 플레이시간 진행
- 온라인과 오프라인은 하나의 게임 달력을 사용
- 중요 의사결정 화면에서는 시간 정지
- 오프라인에서 중요 선택 자동 확정 금지
- PENDING 이벤트는 플레이어 확인 전 임의 소멸 금지
- 계약 만료 오프라인 발생 시 자동 재계약/강제퇴거 금지
- TEMPORARY_STAY 만료 후 주거결정 전 시간 정지
- 현재 거주 중인 유일한 자가는 다음 거주지 없이 단독 매도 불가
- 매매/전세/월세 주택유형 계수는 동일 값을 공유하지 않음
- 실거래 시장유형과 게임 레이아웃유형 분리
- 개별 가구가 월급/승진확률을 직접 올리는 RPG식 효과 금지
- 중고 가구 판매 없음
- 일반 방의 용도는 가구배치를 기반으로 자동 인식
- 전월세와 자가의 인테리어 권한 차등
- 현재 주거단계보다 다음 단계 가구 일부를 미리 보여주는 progression 구조

단, 위 정책의 `수치/대상/조건 범위`가 바뀔 필요가 있을 경우 해당 부분은 어드민 설정으로 분리할 수 있다.

---

# 28. 향후 상세기획 추가 예정 영역

아래 문서는 아직 상세기획 전이므로 어드민 관리항목은 상세 확정과 동시에 본 문서에 추가한다.

- `07_character_life.md`
  - 캐릭터 스탯
  - 생활행동
  - 회복/피로/행복
  - 자율행동 조건
  - 생활씬 보상

- `08_ads_sidejob.md`
  - 광고 placement
  - 부업 콘텐츠
  - 횟수/쿨다운/보상
  - 노출조건

- `09_moving_inventory.md`
  - 이사비
  - 이동/보관 규칙
  - 인벤토리 정책

- `10_events.md`
  - 이벤트 마스터
  - 확률/가중치
  - 선택지/결과
  - 이벤트 큐

- `11_loan.md`
  - 대출상품
  - 금리
  - 한도
  - 상환조건

- `12_market_price.md`
  - 시장추세
  - 월간 변동폭
  - 지역 이벤트
  - 집값 보정계수

- `13_life_stage.md`
  - 파트너/자녀/가족상태
  - 발생조건
  - 생활비/주거조건 변화

- `14_healing_social.md`
  - 계절/날씨
  - 생활앨범
  - 공유카드
  - 추천/인기집 운영

---

# 29. 관리 우선순위

실제 어드민을 한 번에 전부 개발하지 않고 운영 필요성이 높은 순서로 구축한다.

## P0 — 출시 전 반드시 필요

- 공통 시간/기간 설정
- 경제 기본값
- 직장/급여/업무강도
- 통근시간 테이블
- 지역/부동산 가격지수
- 주택유형/매물 생성값
- 가구 카탈로그/가격/해금
- 평면도 템플릿
- 인테리어 시공 가격/조건
- 광고 부업 보상/횟수

## P1 — 라이브 운영에 중요

- 시즌가구
- 희귀매물
- 추천룰
- 생활씬 조합
- 이벤트
- 밸런스 계수
- 신규 회사/지역/가구/평면도 활성화

## P2 — 고도화 이후

- 고급 추천운영
- 소셜/공유 운영
- 라이프스테이지 운영
- 구조변경/프리미엄 인테리어
- 다주택/투자주택 콘텐츠

---

# 30. 운영상 Source of Truth

어드민 관련 기준은 다음 순서로 본다.

1. 각 시스템 상세 MD의 확정 정책
2. `15_admin.md`의 관리대상/필드 정의
3. 실제 어드민 데이터

기획 정책이 바뀌면:

```text
상세 MD 수정
→ 15_admin.md 동시 수정
→ 실제 어드민 스키마/데이터 반영
```

순서로 관리한다.

이 문서는 앞으로 07~14 기획을 진행할 때 계속 확장한다.

---

# 31. 캐릭터 생활 관리

출처: `07_character_life.md`

`07_character_life.md` 상세기획이 확정되었으므로 본 섹션을 캐릭터 생활 어드민 관리 기준으로 사용한다. 위 `# 28. 향후 상세기획 추가 예정 영역`의 `07_character_life.md` 항목은 본 섹션으로 대체한다.

## 31.1 생활 스탯 기본 설정

플레이어 핵심 생활 스탯:

```text
ENERGY
STRESS
HAPPINESS
```

현재 기본 범위:

```text
0 ~ 100
```

어드민 관리 대상:

```text
life_stat_type
min_value
max_value
status_range_min
status_range_max
status_label
sort_order
is_active
```

사용자에게는 숫자와 자연어 상태를 함께 보여준다.

예:

```text
체력 78 · 여유 있음
스트레스 62 · 조금 지침
행복 84 · 만족스러움
```

## 31.2 업무강도/통근 생활영향

관리 대상:

- 업무강도별 체력 변화
- 업무강도별 스트레스 변화
- 통근시간 구간별 체력 변화
- 통근시간 구간별 스트레스 변화
- 통근/업무강도의 자유시간 보정
- 회사/이벤트별 추가 생활부담 보정

관리 구조 후보:

```text
impact_profile_id
source_type
source_key
energy_delta
stress_delta
happiness_delta
free_time_modifier
```

## 31.3 생활행동 마스터

관리 필드 후보:

```text
life_action_id
name
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
is_active
```

기본 카테고리:

- 휴식
- 자기계발
- 건강
- 취미
- 생활

행동 처리 알고리즘은 코드지만 각 행동의 조건/수치/가중치는 어드민으로 관리한다.

## 31.4 자율행동 가중치/반복방지

자율행동은 핵심 힐링 콘텐츠이므로 운영 중 반복감 조절이 가능해야 한다.

관리 대상:

- 행동별 기본 가중치
- 스탯 구간별 가중치 보정
- 평일/휴일 가중치 보정
- 계절/날씨/시간대 가중치 보정
- 동일 행동 반복 패널티
- 동일 가구 반복 패널티
- 미사용 공간/가구 보너스 가중치
- 최근행동 기록 기준 개수
- 행동별 최소 쿨다운
- 생활씬별 최소 쿨다운

관리 키 후보:

```text
recent_action_history_count
same_action_repeat_penalty
same_furniture_repeat_penalty
unused_space_weight_bonus
```

현재 최근행동 기록 기준은 `3~5개`를 테스트 범위로 본다.

## 31.5 자유시간

자유시간은 내부 계산값으로 관리한다.

관리 대상:

- 기본 자유시간값
- 업무강도 보정
- 통근 보정
- 생활환경 보정
- 이벤트 보정
- 자연어 상태 구간/문구

사용자에게 직접 포인트값을 강조하지 않고 `넉넉함 / 보통 / 부족함` 등의 자연어 상태로 표시한다.

## 31.6 계절 관리

현재 기본 계절:

```text
SPRING
SUMMER
AUTUMN
WINTER
```

관리 필드 후보:

```text
season_id
name
sort_order
visual_profile_key
behavior_weight_profile
scene_pool_id
is_active
```

계절 진행주기는 추후 `14_healing_social.md`에서 확정하며 본 문서에 추가한다.

## 31.7 날씨 관리

현재 후보:

- 맑음
- 흐림
- 비
- 눈

관리 필드 후보:

```text
weather_id
name
weight
allowed_seasons
visual_profile_key
behavior_weight_profile
scene_pool_id
is_active
```

실제 현실 날씨가 아니라 게임 내부 날씨를 사용한다.

## 31.8 시간대 관리

현재 후보:

- 아침
- 낮
- 저녁
- 밤

관리 대상:

- 시간대 코드/명칭
- 생활씬 조건
- 행동 가중치
- 연출 프로필
- 생활리듬과의 조합조건

경제시간과 생활연출시간은 서로 다른 축으로 사용한다.

## 31.9 평일/휴일 생활리듬

현재 초기 가안:

```text
게임 1개월 = 현실 30분
약 4개 생활주기
생활주기 1개 ≈ 7.5분
평일모드 약 5분
휴일모드 약 2.5분
```

이 값은 테스트값이므로 어드민에서 조정 가능하게 한다.

관리 필드 후보:

```text
life_rhythm_mode
mode_name
duration_seconds
behavior_weight_profile
scene_weight_profile
is_active
```

현재 모드:

```text
WEEKDAY
HOLIDAY
```

평일/휴일 전환 엔진 자체는 코드로 관리한다.

## 31.10 조합 생활씬 상세 관리

기존 `# 20. 생활씬/조합행동 관리`를 07 확정내용으로 보강한다.

관리 필드 후보:

```text
life_scene_id
name
required_furniture_tags
required_space_usage
required_house_features
season
weather
time_band
life_rhythm_mode
min_energy
max_stress
reward_energy
reward_stress
reward_happiness
housing_satisfaction_reward
first_discovery_reward
repeat_reward_profile
album_enabled
cooldown
priority
is_active
```

정책:

- 조합 생활씬은 일반 행동보다 더 높은 회복/행복 보상 가능
- 첫 발견은 가장 큰 보상 + 생활앨범 등록 가능
- 반복 발생은 보상을 낮추거나 쿨다운 적용
- 직접 큰 현금보상을 지급하지 않음

## 31.11 주거단계별 생활씬 해금

새 집이 새로운 생활씬 세트를 여는 progression을 관리한다.

관리 구조 후보:

```text
housing_progression_tier
life_scene_id
preview_enabled
unlock_enabled
priority
```

현재 기본 흐름:

- 원룸: 바닥식사/작은 소파/책상 생활
- 투룸: 독립 침실/본격 홈오피스
- 쓰리룸·아파트: 취미방/드레스룸/홈짐/큰 거실
- 자가: 욕조/본격 욕실·주방 시공 기반 생활씬
- 프리미엄: 테라스/홈바/홈카페/대형 취미공간

## 31.12 번아웃 관리

관리 대상:

- 발생 스트레스 임계값
- 발생까지 필요한 지속기간
- 회복 조건
- 자기계발 효율 패널티
- 커리어 이벤트 보정
- 휴식행동 가중치
- 상태 표시문구

번아웃은 게임오버가 아니라 회복 가능한 약한 장기상태다.

## 31.13 캐릭터 반응/대사 관리

관리 콘텐츠:

- 상태별 대사
- 신규 가구 첫 사용 대사
- 이사 직후 대사
- 신규 공간 첫 반응
- 생활씬 문구
- 번아웃/회복 반응

관리 필드 후보:

```text
reaction_id
trigger_type
trigger_key
condition_profile
copy
weight
cooldown
is_first_time_only
is_active
```

## 31.14 오프라인 생활 보정

오프라인 처리 순서는 코드지만 다음 수치는 어드민 관리 가능하다.

- 기본 직장 피로 보정
- 통근 생활부담 보정
- 생활환경 기본 회복 보정
- 오프라인 생활요약 문구 풀

오프라인에서는 특수 생활씬의 실제 발견을 자동 처리하지 않는다.

## 31.15 07에서 코드로 유지할 항목

다음은 어드민 데이터가 아니라 코드/엔진 영역이다.

- 캐릭터 pathfinding
- interaction point 이동 처리
- 애니메이션 상태머신
- 행동 우선순위 계산 알고리즘 자체
- 생활씬 조건 매칭 엔진
- 스탯 clamp 처리
- 생활리듬 상태전환 엔진
- 오프라인 생활 계산 처리순서
- 저장/로드 구조

단, 알고리즘이 사용하는 조건값/가중치/기간/보상값은 본 섹션의 어드민 데이터로 관리한다.
