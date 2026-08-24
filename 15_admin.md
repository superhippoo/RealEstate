# 15_admin.md
기준일: 2026-08-24
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

따라서 이후 상세기획과 `15_admin.md`는 함께 업데이트한다.

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
- 이벤트 후보추출/조건매칭/예약실행 알고리즘 자체

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

출처: `00_master_policy.md`, `01_economy_balance.md`, `10_events.md`, `11_loan.md`

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

필수지출 예약 대상과 안전 임계값은 아래 `# 35. 대출 상세 관리`와 연결한다.

## 5.4 월 이벤트 발생률

`10_events.md` 확정 기준:

- RANDOM 월 이벤트 발생률: 초기 약 40~60%
- 중요한 CHOICE 이벤트: 한 게임월 0~1개를 기본 목표
- SCHEDULED/FOLLOWUP 이벤트는 RANDOM 월 발생률과 별도로 처리

관리 후보:

```text
monthly_random_event_probability
no_random_event_weight
category_event_weights
max_important_choice_per_month
```

세부 이벤트 조건/관계/후속체인은 아래 `# 34. 이벤트 상세 관리`를 따른다.

---

# 6. 광고/부업 경제 관리

출처: `00_master_policy.md`, `01_economy_balance.md`, `03_career.md`, `04_time_contract.md`, `05_furniture.md`, `08_ads_sidejob.md`, `11_loan.md`

현재 정책상 부업 수입은 일반 게임머니이며 사용처 제한은 없다.

`08_ads_sidejob.md` 확정에 따라 아래 값을 최신 기준으로 사용한다.

## 6.1 부업 1회 보상

현재 테스트 기준:

- 예상 월 가처분소득의 약 15~20%
- V0.1 우선 테스트값: 20%

예시:

| 예상 월 가처분소득 | 부업 1회 보상 예시 | 월 5회 최대 |
|---:|---:|---:|
| 80만 | 16만 | 80만 |
| 100만 | 20만 | 100만 |
| 160만 | 32만 | 160만 |
| 220만 | 44만 | 220만 |
| 300만 | 60만 | 300만 |

어드민 관리 대상:

- 보상 산식 타입
- 보상 비율
- 최소 보상
- 최대 보상
- 진행단계별 보정
- 게임월 시작 시 보상 고정 여부

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
- 이벤트 추가횟수

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

## 6.5 부업 이용 정책

부업은 부족액이 있을 때만 사용하는 기능이 아니다.

- 해당 게임월에 잔여 횟수가 있으면 언제든 부업 가능
- 상시 부업 메뉴 제공
- 구매/계약 부족 상황에서는 맥락형 CTA 추가 노출
- 이번 달 남은 부업으로 부족액 전체를 해결할 수 없어도 CTA 노출 가능
- 여러 게임월 동안 부업 수입을 저축해 전세/자가 자기자본을 만드는 플레이 허용
- 부업수입은 일반 현금이지만 수동소비 가능 여부는 `spendable_cash`를 따름
- 부업수입으로 플레이어가 대출을 상환할 수 있으나 광고가 대출잔액을 직접 감소시키지는 않음

## 6.6 광고 노출 진입점

주요 진입점:

- 가구 부족액
- 인테리어 시공 부족액
- 이사비 부족액
- 보증금/전세금 부족액
- 매매 자기자본 부족액
- 대출 관련 비용 부족액
- 이벤트 비용 부족액
- 플레이어가 직접 여는 상시 부업 메뉴

각 진입점의 노출 여부/우선순위/문구는 어드민 관리 대상으로 둔다.

---

# 7. 직장/커리어 관리

출처: `00_master_policy.md`, `01_economy_balance.md`, `03_career.md`, `10_events.md`, `11_loan.md`

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

현재 V0.1 이벤트 기간 시작값:

- 첫 승진 자격검토: 최소 재직 12개월
- 다음 승진 자격검토: 현재 career_level 최소 12개월 유지
- PROMOTION → PROMOTION: 12개월 hard block
- JOB_CHANGE → PROMOTION: 6개월 hard block

어드민 관리 대상:

- 최소 재직기간
- 현재 career_level 최소 유지기간
- 필요 career XP
- 이벤트 가중치
- 자기계발 가중치
- 승진 시 급여표
- 승진 시 업무강도 변화
- 승진 시 부업 가능량 변화
- 승진 제안 노출조건
- 승진 거절/유지 허용 여부
- PROMOTION 그룹 cooldown
- 다른 커리어 이벤트 그룹과의 block/weight 관계

## 7.6 이직 제안

현재 첫 이직 테스트 범위:

- 사회생활 약 12~24개월 이후

현재 관계 시작값:

- JOB_CHANGE → JOB_CHANGE: 12개월 hard block
- PROMOTION → JOB_CHANGE: 3개월간 weight × 0.5 테스트

어드민 관리 대상:

- 첫 제안 가능 최소/최대 사회생활개월
- 회사별 이직 제안 가중치
- 플레이어 커리어레벨 조건
- 현재 직장 재직기간 조건
- 제안 급여
- 제안 업무강도/안정성/성장성
- 제안 유지기간/만료정책
- JOB_CHANGE 그룹 cooldown
- PROMOTION 등 다른 event_group 이후 block/weight
- 기존 대출 포함 이직 상환가능성 threshold

세부 상환능력 threshold는 `# 35. 대출 상세 관리`를 따른다.

## 7.7 구조조정/퇴직 관련

`10_events.md` 확정 기준을 따른다.

현재 V0.1 관계 시작값:

- JOB_CHANGE → RESTRUCTURING_MAJOR: 3개월 hard block
- RESTRUCTURING_MAJOR → RESTRUCTURING_MAJOR: 12개월 hard block

어드민 대상:

- 회사 안정성별 구조조정 발생확률
- 구조조정 event_group cooldown
- 다른 커리어 이벤트와의 block/weight 관계
- 퇴직금 산정값
- 구직기간 보정
- 재취업 회사풀
- 후속 이벤트 체인 조건

실직 상태에서 신규대출 제한 가능 여부는 대출 관리설정을 따르며 기존 대출 즉시회수/강제매도는 코드 정책상 사용하지 않는다.

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

정확한 스트레스/체력 값은 `07_character_life.md` 확정값을 사용한다.

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

출처: `02_real_estate.md`, `04_time_contract.md`, `06_house_grid.md`, `08_ads_sidejob.md`

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
- 특별 매물: 기본 1~2개월 유지

어드민 관리 대상:

- 매물종류별 최소/최대 유지기간
- 특별매물 생성확률
- 추천 매물 갱신주기
- 일반 매물 교체주기

## 13.4 특별 매물 판정/표시

사용자 문구는 `희귀 매물`보다 `특별 매물`을 우선한다.

특별매물은 단순히 가격이 싸거나 스펙이 높은 집이 아니라 평소 보기 어려운 삶과 공간을 가능하게 하는 집으로 정의한다.

관리 가능한 특성 예:

- 코너 통창
- 한강뷰
- 남산뷰
- 테라스
- 대형 욕실
- 옥상
- 대형 창
- 복층
- 다락
- 드레스룸
- 팬트리
- 희귀 평면

각 Feature별 관리 후보:

```text
feature_id
name
rarity_score
standalone_special_enabled
rarity_weight
price_modifier
allowed_housing_types
allowed_regions
required_floorplan_features
listing_duration_profile
special_reason_copy
unlockable_scene_ids
is_active
```

특별매물 판정 관리값:

```text
special_listing_threshold
price_merit_weight
special_badge_copy
```

가격 메리트는 보조가중치로 사용할 수 있지만 `싸다 = 특별매물`로 판정하지 않는다.

## 13.5 특별 매물 상세 노출

관리 대상:

- `✨ 특별 매물` 배지 문구
- `이 집이 특별한 이유` 설명문구
- Feature 태그
- `이 집에서 가능한 생활` 연결 생활씬
- 노출 유지기간

예:

```text
이 집에서 가능한 생활
✓ 테라스 모닝커피
✓ 코너창 독서
✓ 3인 소파 배치
```

## 13.6 오프라인 특별 매물 보호

정책 로직 자체는 코드지만 다음 값은 관리 가능하다.

- 특별매물 최초 노출 후 유지기간
- 보호대상 특별도 기준

플레이어가 한 번도 보지 못한 특별매물이 오프라인 중 생성·소멸하지 않는 정책은 유지한다.

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

대출이 있는 자가의 예상 순자산/매도정산은 `11_loan.md`와 아래 `# 35`를 따른다.

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

출처: `00_master_policy.md`, `05_furniture.md`, `07_character_life.md`

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

정확한 보상수치와 캐릭터 스탯 연결은 아래 #31 캐릭터 생활 관리 기준을 사용한다.

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

출처: `02_real_estate.md`, `06_house_grid.md`, `08_ads_sidejob.md`

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
rarity_score
standalone_special_enabled
price_modifier
unlockable_furniture_tags
unlockable_scene_ids
special_reason_copy
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

현재 00~12 기준으로 다음은 코드/기획 규칙으로 유지한다.

- 광고 수입은 일반 게임머니와 동일하게 취급
- 광고로 월급/승진 직접 구매 불가
- 광고로 생활스탯 직접 회복 불가
- 부업은 부족액이 없어도 잔여횟수 내에서 언제든 실행 가능
- 오프라인 부업수입 발생/횟수 자동소비 없음
- 광고 실패/중단 시 보상 및 횟수 차감 없음
- 온라인 활성 상태에서만 온라인 플레이시간 진행
- 온라인과 오프라인은 하나의 게임 달력을 사용
- 중요 의사결정 화면에서는 시간 정지
- 오프라인에서 중요 선택 자동 확정 금지
- PENDING 이벤트는 플레이어 확인 전 임의 소멸 금지
- SCHEDULED/FOLLOWUP 이벤트는 RANDOM 월 발생확률과 별도로 도래 처리
- 같은 중요 이벤트 체인의 중복 생성 제한
- 이벤트 조건매칭/후속예약/악화판정 알고리즘 자체는 코드로 관리
- 랜덤 이벤트로 집/가구/보증금 등 기존 성장의 영구손실 금지
- 계약 만료 오프라인 발생 시 자동 재계약/강제퇴거 금지
- TEMPORARY_STAY 만료 후 주거결정 전 시간 정지
- 현재 거주 중인 유일한 자가는 다음 거주지 없이 단독 매도 불가
- 매매/전세/월세 주택유형 계수는 동일 값을 공유하지 않음
- 실거래 시장유형과 게임 레이아웃유형 분리
- 개별 가구가 월급/승진확률을 직접 올리는 RPG식 효과 금지
- 중고 가구 판매 없음
- 보관함은 게임적으로 무제한
- 이동가구는 영구 소유하고 이사 시 자동 회수
- 이사 중 가구 분실/파손 없음
- 새 집은 완전 빈집으로 시작하고 자동배치하지 않음
- 이전 집 최종 스냅샷은 이사 직전 자동 저장
- 집 귀속 인테리어 시공비는 주택 매매가격에 직접 가산하지 않음
- 일반 방의 용도는 가구배치를 기반으로 자동 인식
- 전월세와 자가의 인테리어 권한 차등
- 현재 주거단계보다 다음 단계 가구 일부를 미리 보여주는 progression 구조
- 주담대 원리금균등 월상환 계산 방식 자체
- 전세대출 월이자 계산 방식 자체
- 신규대출 실행월에는 자동상환하지 않고 다음 게임월부터 첫 상환
- 현재 거주주택/계약 기준 활성 주거대출 최대 1개
- 전세대출 원금 일부상환 금지
- HOME_LOAN 일부상환 시 잔여만기 유지 + 월상환액 재계산
- `spendable_cash` 계산 엔진
- 필수지출 예약 처리 엔진
- 주택가격 기반/상환능력 기반 대출한도 계산 엔진
- 전세 종료 시 보증금 반환 및 대출원금 정산 엔진
- 전세→자가 전환 시 순보증금 선반영 후 기존 대출 정산
- 자가 매도 시 기존 주담대 정산 엔진
- 자가→자가 갈아타기 시 기존집 순자산 선반영 후 기존 대출 정산
- 이직 시 기존대출 포함 상환가능성 검사 엔진
- 순주택자산 계산 엔진
- 광고가 대출잔액을 직접 감소시키는 구조 금지
- 일반 플레이에서 연체/압류/강제경매/파산 상태를 생성하지 않도록 사전방지
- 실직 시 기존대출 즉시회수/강제매도 금지
- 시장은 플레이어 게임월 기준으로만 갱신
- STABLE / RISING / FALLING 시장 Cycle 순서와 반복은 코드/기획 규칙
- 시장 Cycle 종료 시 누적시세 초기화 금지
- 시장 Cycle 전체 누적변화는 양수이며 장기적으로 완만한 우상향
- 시장 랜덤/Seed/유저별 Regime 추첨 없음
- 지역별 독립 시장/영구 성장률 차등 없음(V0.1)
- REGION 이벤트의 시세 직접효과 없음(V0.1)
- 생성된 매물의 제시가격은 소멸까지 LOCK
- 기존 임대계약 가격은 계약기간 동안 고정
- 자가 현재시세는 게임월마다 갱신
- 신규 Starting Market Snapshot으로 기존 플레이어 시세를 덮어쓰지 않음
- 장기 부동산 가격 Hard Cap 없음

단, 위 정책의 `수치/대상/조건 범위`가 바뀔 필요가 있을 경우 상세기획과 코드 버전업으로 변경한다. 12의 고정 시장 Cycle 기간/변동률은 일반 라이브 어드민 조작값으로 두지 않는다.

---

# 28. 향후 상세기획 추가 예정 영역

아래 문서는 아직 상세기획 전이므로 어드민 관리항목은 상세 확정과 동시에 본 문서에 추가한다.

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
- 커리어 최소기간/cooldown/이벤트 관계
- 통근시간 테이블
- 지역/부동산 가격지수
- 신규게임 Starting Market Snapshot/지역×계약유형×시장유형 기준단가
- 주택유형/매물 생성값
- 가구 카탈로그/가격/해금
- 평면도 템플릿
- 인테리어 시공 가격/조건
- 광고 부업 보상/횟수/노출 진입점
- 주거단계별 이사비
- 가구 이동/보관 정책
- 핵심 이벤트 마스터/발생조건/후속체인
- 대출상품/신규금리/기간/한도/상환능력/필수지출 예약/상환정책 설정

## P1 — 라이브 운영에 중요

- 시즌가구
- 특별매물
- 추천룰
- 이사 직후 새집 추천룰
- 생활씬 조합
- 이벤트 신규 콘텐츠/밸런스
- 밸런스 계수
- 신규 회사/지역/가구/평면도 활성화
- 재계약 가격 상하한 및 Starting Market Snapshot 분기 운영

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

이 문서는 앞으로 상세기획을 진행할 때 계속 확장한다.

---

# 31. 캐릭터 생활 관리

출처: `07_character_life.md`

`07_character_life.md` 상세기획이 확정되었으므로 본 섹션을 캐릭터 생활 어드민 관리 기준으로 사용한다.

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

---

# 32. 광고/부업 상세 관리

출처: `08_ads_sidejob.md`, `11_loan.md`

`08_ads_sidejob.md` 상세기획 확정내용을 본 섹션의 기준으로 사용한다.

## 32.1 부업 보상 프로필

관리 필드 후보:

```text
profile_id
reward_formula_type
reward_ratio
minimum_reward
maximum_reward
freeze_for_game_month
is_active
```

현재 V0.1:

- 기준: 예상 월 가처분소득
- 보상비율 테스트범위: 15~20%
- 기본 테스트값: 20%
- 게임월 시작 시 그 달 1회 보상액을 고정하는 것을 기본안으로 함

## 32.2 월 부업 횟수

관리 대상:

- 회사별 기본횟수
- 통근구간별 보정
- 생활환경 보정
- 최소/최대 횟수
- 이벤트 추가횟수
- 게임월 시작 시 확정 여부

현재 일반 테스트 기준은 약 5회/게임월이다.

## 32.3 상시 부업 메뉴

부업은 구매 부족액이 없어도 잔여횟수 내에서 언제든 실행 가능하다.

관리 대상:

- 상시 메뉴 노출 여부
- 메뉴 위치/표시명
- 잔여횟수 표시 여부
- 기본 CTA 문구

## 32.4 부족액 문맥 CTA

관리 필드 후보:

```text
entry_id
purchase_context
cta_enabled
priority
copy
show_possible_monthly_earning
is_active
```

문맥 예:

```text
FURNITURE_PURCHASE
INTERIOR_PURCHASE
MOVE_CONTRACT
JEONSE_CONTRACT
HOME_PURCHASE
EVENT_COST
```

이번 달 잔여 부업으로 부족액 전체를 해결할 수 없는 경우에도 CTA를 허용한다.

부족액 판정의 기준 현금은 총 `cash_balance`가 아니라 `spendable_cash`다.

## 32.5 부업 콘텐츠

관리 필드 후보:

```text
sidejob_id
name
description
type
job_theme_tags
required_condition
reward_profile_id
visual_profile_key
is_active
```

예:

- 문서 정리
- 데이터 입력
- 디자인 외주
- 번역
- 온라인 설문
- 행사 스태프
- 배달
- 과외

직업별 테마는 연출 차별화에 사용하고 시스템적 격차는 최소화한다.

## 32.6 첫 부업 튜토리얼

관리 대상:

- 최초 노출조건
- 튜토리얼 문구
- 재노출 여부
- CTA 문구
- 노출 우선순위

현재 권장 첫 노출은 첫 욕망가구 부족 상황 등 자연스러운 구매욕망 이후다.

## 32.7 장기 저축 KPI/밸런스

부업수입을 여러 게임월 저축해 전세/자가 자기자본을 만드는 플레이를 정상 경로로 본다.

운영/분석 관리 대상:

- 무광고 대비 적극광고 성장속도 목표: 1.7~2.2배
- 게임월 평균 광고시청수
- 부업수입 저축 비율
- 부업 후 즉시구매 비율
- 부업 후 장기자산 증가 기여도

## 32.8 특별 매물 판정

관리 필드 후보:

```text
feature_id
rarity_score
standalone_special_enabled
special_listing_threshold
price_merit_weight
special_badge_copy
special_reason_copy
is_active
```

특별매물 후보 Feature 예:

- TERRACE
- RIVER_VIEW
- CORNER_WINDOW
- LARGE_BATHROOM
- DRESSROOM
- ROOFTOP_SPACE
- DUPLEX
- ATTIC
- PANTRY
- LARGE_WINDOW

특정 Feature는 단독으로 특별매물 판정이 가능하다.

가격메리트는 보조값이며 가격이 싸다는 이유만으로 특별매물이 되지는 않는다.

## 32.9 특별 매물 노출 콘텐츠

관리 대상:

- `특별 매물` 배지 문구
- `이 집이 특별한 이유` 설명문구
- 표시할 Feature 태그
- `이 집에서 가능한 생활` 생활씬 매핑
- 특별매물 유지기간
- Feature별 생성가중치

특별매물은 상위 스펙 순위가 아니라 취향적 희소성을 표현한다.

## 32.10 광고/부업 로그 및 KPI

추적 대상:

- 게임월/세션별 부업 실행률
- 광고 시작/완료율
- 부족액 CTA → 부업 전환율
- 가구/인테리어/이사/계약별 부업 사용률
- 광고 후 실제 구매완료율
- 플레이어당 게임월 광고시청수
- 무광고/평균광고/적극광고 progression 비교
- 장기목표 저축형 부업 사용률
- 광고 이후 이탈률

## 32.11 08에서 코드로 유지할 항목

다음은 코드/서버 영역이다.

- 광고 SDK 호출
- 완료 callback 처리
- reward_session_id 발급
- 보상 중복지급 방지
- 광고 fill/실패 처리
- 월 경계 부업 데이터 생성
- 잔여횟수 차감
- 특별매물 점수 계산 엔진

단, 엔진이 참조하는 수치·조건·문구·Feature 연결은 어드민에서 관리한다.

---

# 33. 이사/보관함 상세 관리

출처: `09_moving_inventory.md`, `11_loan.md`

`09_moving_inventory.md` 상세기획 확정내용을 본 섹션의 기준으로 사용한다.

## 33.1 주거단계별 이사비

가구 개수에 따라 이사비를 올리지 않고 주거단계별 고정비를 사용한다.

관리 필드 후보:

```text
move_cost_profile_id
housing_progression_tier
base_move_cost
is_active
```

단계 예:

- 원룸급
- 투룸급
- 쓰리룸급
- 소형 아파트
- 중형 아파트
- 프리미엄 주거

조기이사 추가비용은 04 계약 시스템의 별도 값과 합산한다.

이사비 부족액은 `spendable_cash`를 기준으로 판정한다.

## 33.2 가구 이동/보관 정책

가구별 다음 값은 어드민에서 관리한다.

```text
furniture_id
movable
storage_enabled
discard_enabled
discard_protection_type
```

정책:

- 이동 가능 가구는 영구 소유
- 보관함은 게임적으로 무제한
- 이사 시 모든 `PLACED` 이동가구 자동 회수
- 새 집에 배치 불가능해도 보관함에 유지
- 중고판매 없음

## 33.3 삭제 보호정책

추가 확인 대상으로 둘 수 있는 분류:

- 즐겨찾기
- PREMIUM/DESIGNER
- 시즌 한정
- 특별 획득
- 향후 유료성 재화 연계 가구

관리 필드 후보:

```text
discard_protection_type
confirmation_copy
second_confirmation_required
is_active
```

## 33.4 보관함 UI/필터

보관함 필터와 노출 여부를 관리한다.

기본 후보:

- 전체
- 침실
- 거실
- 주방/식사
- 작업/서재
- 욕실
- 취미
- 장식
- 현재 집 배치 가능
- 미배치
- 즐겨찾기
- 최근 사용

관리 구조 후보:

```text
inventory_filter_id
name
filter_type
sort_order
is_active
```

검색, 즐겨찾기 기능 자체는 코드/UX지만 노출옵션과 문구는 관리 가능하다.

## 33.5 새 집 추천룰

이사 직후 추천은 취향 AI가 아니라 새 집에서 새롭게 가능해진 콘텐츠를 기준으로 한다.

추천 기준:

- 이전 집보다 커진 배치 가능 크기
- 새로 생긴 독립공간
- 새 주거단계에서 해금된 가구
- 새 집 Feature
- 현재 비어 있는 생활기능

관리 필드 후보:

```text
move_recommendation_rule_id
trigger_type
condition_tags
recommended_category_or_item
recommended_interior_action_id
priority
copy
item_limit
is_active
```

이 추천은 자동배치가 아니라 상점/가구탐색으로 연결한다.

## 33.6 이사/빈집 안내 문구

관리 대상:

- 이사 전 `기존 집에 남는 시공` 안내문구
- 새 집 입주 안내문구
- 보관함 가구 개수 안내문구
- 빈 방 안내문구
- 새 해금 가구 안내문구
- 새 Feature 안내문구

관리 구조 후보:

```text
move_copy_id
trigger_type
condition_profile
copy
priority
is_active
```

## 33.7 이전 집 스냅샷

확정 정책:

- 이사 직전 마지막 배치/시공 상태를 자동 저장
- 거주 중 중간 배치는 별도 자동보관하지 않음
- 이전 집 스냅샷은 기본적으로 계속 보관

어드민 관리 후보:

- 자동 스냅샷 활성 여부는 정책상 기본 ON
- 앨범 표시명 템플릿
- 대표 이미지 생성용 프레임/문구
- 표시 정보 항목

스냅샷 생성과 저장 엔진 자체는 코드다.

## 33.8 집 귀속 시공 가치정책

확정 정책:

- 집 귀속 시공은 이사 시 기존 집에 남음
- 시공 비용은 주택 매매가격에 직접 가산하지 않음
- 시공의 보상은 생활가치, 시각적 변화, 생활씬, 만족도

어드민 관리 대상:

- 시공별 생활효과 프로필
- 시공별 생활씬 연결
- 시공별 시각 결과 에셋

매매가격 반영 여부는 어드민 토글로 두지 않고 현재 기획 정책으로 고정한다.

## 33.9 이사 관련 KPI

추적 대상:

- 이사 직후 가구 재배치율
- 이사 후 첫 가구 구매까지 시간
- 이사 후 신규 해금가구 구매율
- 과거 가구 재사용률
- 보관함 사용률
- 즐겨찾기 사용률
- 가구 버리기 비율
- 이사 직후 추천 → 상점 진입률
- 새 Feature 추천 → 관련 가구/시공 구매율
- 이전 집 스냅샷 열람률

## 33.10 09에서 코드로 유지할 항목

다음은 코드/엔진 영역이다.

- `PLACED → MOVING → STORED` 상태변환
- 이사 시 이동가구 자동 회수
- 인벤토리 저장/정렬/검색 엔진
- Grid 호환성 판정
- 새 집 완전 빈집 초기화
- Surface Slot 해제/개별 회수 처리
- 이전 집 스냅샷 생성/저장
- 가구 인스턴스 상태 저장

단, 가구별 이동 가능 여부, 삭제 보호, 이사비, 추천조건, 문구 등은 어드민에서 관리한다.

---

# 34. 이벤트 상세 관리

출처: `10_events.md`

`10_events.md` 상세기획 확정내용을 본 섹션의 기준으로 사용한다.

## 34.1 이벤트 마스터

관리 필드 후보:

```text
event_id
name
category
event_type
occurrence_type
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
AUTO
RECORD
CHOICE
```

`occurrence_type`:

```text
RANDOM
SCHEDULED
FOLLOWUP
```

## 34.2 RANDOM 월 이벤트 빈도

현재 V0.1:

- 월 RANDOM 이벤트 발생률 약 40~60%
- 중요한 CHOICE는 게임월 0~1개 기본 목표
- SCHEDULED/FOLLOWUP은 RANDOM 확률과 별도

관리 대상:

```text
monthly_random_event_probability
max_random_events_per_month
max_important_choice_per_month
scheduled_event_random_suppression_weight
```

예약 이벤트가 많은 달에는 일반 RANDOM 이벤트를 줄일 수 있다.

## 34.3 이벤트 카테고리/그룹

기본 카테고리:

```text
CAREER
HOUSING
LIFE
ECONOMY
REGION
PROGRESSION
```

기본 event_group 후보:

```text
PROMOTION
JOB_CHANGE
RESTRUCTURING_MAJOR
BONUS
OVERTIME
HOUSE_BREAKDOWN_MINOR
HOUSE_BREAKDOWN_MAJOR
HEALTH_MINOR
REGION_CHANGE
```

신규 그룹은 어드민에서 추가/활성화 가능하다.

## 34.4 커리어 이벤트 기간 기본값

V0.1 시작값:

| 관계 | 값 |
|---|---:|
| 첫 승진 자격검토 최소 재직기간 | 12개월 |
| 다음 승진 자격검토 최소 career_level 유지기간 | 12개월 |
| PROMOTION → PROMOTION | 12개월 hard block |
| JOB_CHANGE → JOB_CHANGE | 12개월 hard block |
| JOB_CHANGE → PROMOTION | 6개월 hard block |
| PROMOTION → JOB_CHANGE | 3개월간 weight × 0.5 |
| JOB_CHANGE → RESTRUCTURING_MAJOR | 3개월 hard block |
| RESTRUCTURING_MAJOR → RESTRUCTURING_MAJOR | 12개월 hard block |

모두 테스트값이며 운영 중 변경 가능해야 한다.

## 34.5 이벤트 관계 테이블

관리 구조:

```text
source_event_group
target_event_group
block_months
modifier_months
weight_modifier
condition_profile
is_active
```

목적:

- 승진 직후 또 승진 방지
- 이직 직후 또 이직 방지
- 이직 직후 큰 구조조정 같은 불합리한 조합 완화
- 이벤트 종류가 늘어나도 코드수정 없이 관계 추가

## 34.6 발생조건 프로필

조건으로 사용할 수 있는 항목:

- company_id / company_type / company_tier
- workload / stability / growth_rate
- career_level
- months_in_company
- months_in_current_career_level
- career_xp
- work_district
- region_id
- housing_type
- build_age / house_condition
- feature tags
- contract_status
- ENERGY / STRESS / HAPPINESS
- commute_minutes
- environment scores
- season / weather
- cash/assets
- recent event groups
- persistent state

조건 엔진은 코드지만 값과 조합은 어드민 데이터다.

## 34.7 초반 보호기간

현재 V0.1:

- 첫 3~6개월 강한 부정 이벤트 제한
- 기본 테스트 시작값: 6개월

관리 대상:

```text
early_game_protection_months
protected_event_groups
protected_event_ids
protected_weight_modifier
```

## 34.8 부정/긍정 연속 방지

관리 대상:

- 최근 N개월 큰 부정 이벤트 집계기간
- 큰 부정 후 다음 큰 부정 weight modifier
- 회복성/중립 이벤트 보정
- 큰 긍정 이벤트 cooldown
- 큰 긍정 연속 weight modifier

예시 키:

```text
negative_streak_window_months
negative_major_weight_modifier
positive_streak_window_months
positive_major_weight_modifier
```

## 34.9 CHOICE 선택지

관리 필드:

```text
choice_id
event_id
label
description
money_delta
energy_delta
stress_delta
happiness_delta
career_delta
free_time_delta
add_state_ids
remove_state_ids
followup_rule_ids
is_active
```

큰 돈/직장/주거 장기효과는 선택 전에 방향성을 고지한다.

## 34.10 미해결 상태

`미루기`는 이벤트를 종료하지 않고 persistent state를 만들 수 있다.

관리 구조:

```text
state_id
name
monthly_money_delta
monthly_energy_delta
monthly_stress_delta
monthly_happiness_delta
environment_penalty_profile
blocked_scene_ids
followup_profile_id
is_active
```

예:

```text
HOUSE_LEAK_ACTIVE
BOILER_BROKEN
JOB_SEARCH_ACTIVE
RESTRUCTURING_PENDING
```

상태 제거 조건도 데이터로 연결한다.

## 34.11 후속 이벤트 규칙

지원 타입:

```text
GUARANTEED
PROBABILITY
CONDITION
```

관리 구조:

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
is_active
```

후속 이벤트는 RANDOM 월 이벤트 발생률과 별도로 도래 처리한다.

## 34.12 악화 프로필

주거문제를 미뤘을 때 악화확률 등은 데이터로 관리한다.

관리 구조:

```text
escalation_profile_id
base_probability
probability_per_month
max_probability
cost_multiplier
stress_per_month
environment_penalty
max_defer_months
escalated_event_id
is_active
```

예시 `30% → 다음 달 60%` 같은 값은 확정값이 아니라 프로필 데이터다.

## 34.13 주거 고장 이벤트

관리 대상:

- 집 상태/연식별 발생 weight
- 신축/구축 보정
- 계절 조건
- 수리비
- 미루기 가능 여부
- 미해결 상태 ID
- followup rule
- escalation profile
- 생활환경 패널티
- 제한되는 생활씬

랜덤 가구 파손/영구손실은 사용하지 않는다.

## 34.14 커리어 이벤트

관리 대상:

- 승진 자격조건과 event_group 연결
- 이직 제안 조건/weight
- 구조조정 안정성별 weight
- 보너스/야근 이벤트 프로필
- 후속 커리어 체인
- 회사별 event_profile

커리어 자격 계산의 의미는 `03_career.md`, 이벤트 전달과 반복제한은 `10_events.md`가 기준이다.

## 34.15 이벤트 보상/손실 프로필

초기 참고범위:

- 소형: 월 가처분소득 약 5~20%
- 중형: 약 20~50%
- 큰 이벤트: 약 50~100%, 낮은 빈도

관리 대상:

```text
reward_profile_id
size_tier
reference_income_type
min_ratio
max_ratio
fixed_min
fixed_max
```

한 번의 랜덤 사건으로 여러 달 장기저축을 크게 훼손하지 않게 한다.

## 34.16 이벤트 만료/우선순위

관리 대상:

- priority
- expire_enabled
- expire_after_months
- PENDING 중요 이벤트의 만료 금지 여부
- 같은 체인 block
- 복귀 시 노출순서

권장 우선순위:

```text
시스템 필수/계약
→ 예약된 중요 FOLLOWUP
→ 중요 RANDOM CHOICE
→ 일반 이벤트
→ FLAVOR
```

## 34.17 이벤트 UI/문구

관리 대상:

- title
- body copy
- choice copy
- result copy
- priority별 UI profile
- 상태/악화 안내문구
- 복귀 요약문구
- 시각연출 asset/profile key

## 34.18 이벤트와 부업

이벤트 해결 자체에 광고를 직접 붙이지 않는다.

이벤트 비용이 부족하면 일반 게임머니 부족상황으로 `08_ads_sidejob.md`의 부업 CTA를 호출한다.

이벤트로 `이번 달 부업 +1회` 같은 추가기회를 주는 경우 해당 횟수도 어드민 데이터로 관리한다.

## 34.19 이벤트 KPI

추적 대상:

- RANDOM 발생률
- 카테고리별 발생률
- event_group별 실제 간격
- 승진/이직 반복간격
- CHOICE 선택비율
- PENDING 누적개수
- 후속 이벤트 정상도래율
- 미루기 선택률
- 미해결 상태 평균 유지개월
- 악화 발생률
- 부정 이벤트 연속발생률
- 이벤트 후 이탈률
- 이벤트 비용 후 부업 전환율

## 34.20 10에서 코드로 유지할 항목

다음은 코드/엔진 영역이다.

- RANDOM 후보 추출
- condition matching 엔진
- weight 랜덤선택
- cooldown/group cooldown 판정 엔진
- event_relation block/weight 적용 엔진
- SCHEDULED/FOLLOWUP 예약큐 실행
- PENDING 큐
- 동일 체인 잠금
- persistent state 적용/해제
- escalation probability 계산
- 결과 적용/로그 저장
- 오프라인 이벤트 처리순서

단, 엔진이 참조하는 기간, 확률, 조건, 가중치, 보상, 문구, 연결관계는 어드민에서 관리한다.

---

# 35. 대출 상세 관리

출처: `11_loan.md`

`11_loan.md` V0.2 상세기획 확정내용을 본 섹션의 기준으로 사용한다.

## 35.1 대출상품 마스터

MVP 상품:

```text
JEONSE_LOAN
HOME_LOAN
```

관리 필드 후보:

```text
loan_product_id
name
loan_type
eligible_contract_type
is_active
sort_order
```

MVP에서는 신용대출/가구대출을 사용하지 않는다.

현재 거주주택/계약 기준 활성 주거대출은 최대 1개다. 이 개수 제한 로직은 코드 정책으로 유지한다.

## 35.2 신규대출 금리

기존대출은 실행 시 금리를 고정하고 시장금리 변화는 신규대출에만 반영한다.

관리 필드 후보:

```text
loan_product_id
new_loan_interest_rate
effective_from
effective_until
is_active
```

기존대출 금리 재계산은 하지 않는다.

## 35.3 주담대 상환방식/기본기간

현재 MVP 확정:

- `HOME_LOAN` 상환방식: 원리금균등상환
- `HOME_LOAN` 기본 만기: 30년
- `default_term_months = 360`

관리 필드 후보:

```text
loan_product_id
repayment_type
default_term_months
allowed_term_months
```

현재 권장값:

```text
HOME_LOAN
repayment_type = EQUAL_TOTAL_PAYMENT
default_term_months = 360
```

기존 60~120개월 게임용 단축안은 사용하지 않는다.

향후 20년/30년/40년 선택을 도입하면 `allowed_term_months`로 관리한다.

월 원리금 계산 엔진 자체는 코드다.

## 35.4 전세대출 이자형/상환 정책

현재 확정 정책:

- 계약 중 월 이자만 납부
- 계약 중 원금 일부상환 불가
- 계약 종료 시 반환된 보증금에서 원금 자동정산

관리 필드 후보:

```text
loan_product_id
repayment_type
interest_only_during_contract
partial_repayment_enabled
principal_settlement_trigger
```

현재 권장값:

```text
JEONSE_LOAN
repayment_type = INTEREST_ONLY
interest_only_during_contract = true
partial_repayment_enabled = false
principal_settlement_trigger = JEONSE_CONTRACT_END
```

원금정산 처리 자체는 코드다.

## 35.5 주택가격 기반 한도

관리 필드 후보:

```text
property_limit_profile_id
loan_product_id
contract_type
housing_type
region_group
max_property_value_ratio
minimum_equity_ratio
is_active
```

`property_based_limit`의 계산 엔진은 코드로 유지한다.

## 35.6 상환능력 기반 한도

관리 필드 후보:

```text
affordability_profile_id
loan_product_id
income_reference_type
minimum_free_income
minimum_free_income_ratio
safety_buffer_amount
safety_buffer_ratio
is_active
```

최종 한도:

```text
maximum_loan
= min(property_based_limit, affordability_based_limit)
```

`affordability_limit` 및 최종 한도 계산 엔진은 코드로 유지한다.

## 35.7 Minimum Free Income / Safety Buffer

대출 실행 후 생활가능성의 최소 안전선을 관리한다.

관리 후보:

```text
minimum_free_income
minimum_free_income_ratio
safety_buffer_amount
safety_buffer_ratio
```

정확한 초기값은 경제 progression 시뮬레이션으로 확정한다.

## 35.8 Mandatory Expense Reservation

`reserved_mandatory_expenses`에 포함할 항목과 기준값을 관리한다.

기본 대상:

- 다음 월세
- 관리비
- 기본 생활비
- 보험/기타 고정비
- 전세대출 월이자
- 주담대 월상환액
- 이미 확정된 기타 필수 자동지출

관리 구조 후보:

```text
mandatory_expense_type
reservation_enabled
calculation_profile_id
priority
is_active
```

HOME_LOAN 일부상환 시 새 월상환액을 계산한 뒤 예약값을 즉시 갱신한다.

예약/합산 처리 엔진 자체는 코드다.

## 35.9 Spendable Cash / 잔여현금 경고

계산식:

```text
spendable_cash
= max(0, cash_balance - reserved_mandatory_expenses)
```

계산 자체는 코드다.

어드민 관리 대상:

- UI에 `보유현금`과 `사용 가능 현금`을 함께 표시할지 여부
- 부족액 CTA 노출 임계값
- 낮은 사용가능현금 경고 임계값
- 주택계약 후 낮은 잔여현금 경고 임계값
- 경고/안내 문구

관리 필드 후보:

```text
show_cash_balance
show_spendable_cash
low_spendable_cash_threshold
low_post_contract_cash_threshold
shortage_cta_threshold
warning_copy
post_contract_cash_warning_copy
```

주택 구매 후 절대 최소현금 보유액은 강제하지 않는다. 안전조건을 만족하지만 현금이 적게 남는 선택은 허용하고 경고만 노출한다.

## 35.10 신규대출 재직/소득 조건

관리 필드 후보:

```text
loan_product_id
minimum_months_in_company
minimum_monthly_income
allowed_employment_states
blocked_state_ids
is_active
```

실직/구직 상태에서 신규대출을 제한할 수 있으나 기존대출을 즉시 회수하지 않는다.

## 35.11 이직 시 상환가능성 Threshold

이직 실행 전 기존 대출상환을 포함한 affordability 검사를 한다.

관리 필드 후보:

```text
job_change_affordability_enabled
job_change_minimum_free_income
job_change_minimum_free_income_ratio
job_change_safety_buffer
```

연봉 감소 자체는 금지조건이 아니다.

## 35.12 HOME_LOAN 일부상환 / 전액상환

관리 필드 후보:

```text
loan_product_id
partial_repayment_enabled
full_repayment_enabled
minimum_partial_repayment_amount
partial_repayment_term_policy
prepayment_fee_rate
```

현재 MVP 확정값:

```text
HOME_LOAN
partial_repayment_enabled = true
full_repayment_enabled = true
minimum_partial_repayment_amount = 1000000
partial_repayment_term_policy = KEEP_REMAINING_TERM
prepayment_fee_rate = 0
```

정책:

- 최소 일부상환액 기본값: 1,000,000원
- 일부상환 가능금액 상한: `spendable_cash`
- 일부상환 후 잔여 만기 유지
- 일부상환 후 월상환액 재계산
- 새 월상환액 기준으로 `reserved_mandatory_expenses` 즉시 갱신
- 중도상환수수료 없음

`JEONSE_LOAN`은 일부상환 대상이 아니다.

## 35.13 신규대출 첫 상환 시작

현재 MVP 정책:

- 대출 실행 게임월에는 신규대출 자동상환 없음
- 실행 다음 게임월부터 첫 상환/이자 납부
- 일할계산 없음

관리 필드 후보:

```text
loan_product_id
first_payment_offset_months
proration_enabled
first_payment_copy
```

현재 권장값:

```text
first_payment_offset_months = 1
proration_enabled = false
```

상환월 계산 자체는 코드다.

## 35.14 전세→자가 / 자가→자가 자금계획

전세→자가에서 사용하는 예상 순보증금:

```text
반환 예정 전세보증금
- 남은 JEONSE_LOAN 원금
- 계약 종료 확정비용
= 예상 순보증금
```

자가→자가에서 사용하는 예상 순자산:

```text
예상 매도가
- 남은 HOME_LOAN 원금
- 예상 매도비용
= 예상 순자산
```

관리 후보:

```text
sale_cost_rate
sale_fixed_cost
estimated_sale_price_modifier
jeonse_exit_cost_profile
```

예상 자기자본 선반영, 기존대출 정산 후 신규대출 생성 순서는 코드 규칙이다.

## 35.15 대출 UI 문구/표시

관리 대상:

- 대출상품명/설명
- 금리 표시문구
- 월상환/월이자 표시문구
- 계약 후 남는 현금 문구
- 예상 월 자유소득 문구
- 첫 상환 시작월 문구
- 낮은 잔여현금 경고
- 상환능력 부족 안내
- 이직 제한 사유 안내
- HOME_LOAN 일부상환/전액상환 안내
- JEONSE_LOAN 일부상환 불가 안내가 필요한 경우 해당 문구

집 구매/대출 화면의 핵심 표시 항목:

- 집값
- 보유현금
- 사용 가능 현금
- 전세 예상 순보증금
- 기존집 매도 예상 순자산
- 대출액
- 계약 후 남는 현금
- 월상환액 또는 월이자
- 예상 월 자유소득
- 대출기간
- 적용금리
- 첫 상환 시작월

## 35.16 대출 관련 KPI

추적 후보:

- 상품별 신규대출 실행률
- 평균 대출비율
- 대출 후 예상 자유소득 분포
- 첫 자가 구매 시 평균 자기자본/대출 비율
- HOME_LOAN 일부상환 이용률
- HOME_LOAN 전액상환 이용률
- 평균 일부상환액
- 일부상환 후 월상환액 감소폭
- 갈아타기 시 기존대출 정산규모
- 전세→자가 전환 시 순보증금 기여비율
- 이직 affordability 제한 발생률
- 사용 가능 현금 부족으로 인한 구매 보류율
- 낮은 계약 후 잔여현금 경고 노출/진행률
- 부족액 CTA → 부업 전환율

## 35.17 player_loan / 대출 상태 구조

실제 DB 스키마 자체는 코드/개발영역이지만 운영·로그에서 참조할 최소 의미값은 다음과 같다.

```text
loan_id
player_id
loan_product_id
linked_house_id
linked_contract_id
original_principal
remaining_principal
interest_rate
repayment_type
term_months
remaining_term_months
monthly_payment
monthly_principal
monthly_interest
started_game_month
first_payment_game_month
last_payment_game_month
status
closed_game_month
settlement_reason
```

MVP 상태값:

```text
ACTIVE
PAID_OFF
SETTLED_ON_CONTRACT_END
SETTLED_ON_SALE
```

`OVERDUE`, `DEFAULT`, `FORECLOSURE`, `BANKRUPTCY`는 사용하지 않는다.

## 35.18 11에서 코드로 유지할 항목

다음은 코드/엔진 영역이다.

- 원리금균등 주담대 월상환 계산
- 전세대출 월이자 계산
- 신규대출 첫 상환월 계산
- 활성 주거대출 최대 1개 상태관리
- `spendable_cash` 계산
- 필수지출 예약 처리
- 주택가격 기반 대출한도 계산
- 상환능력 기반 대출한도 계산
- 최종 대출한도 계산
- 전세종료 시 보증금 반환/원금정산
- 전세→자가 순보증금 선반영/정산
- 집 매도 시 기존 주담대 정산
- 자가→자가 예상 순자산 선반영/정산
- HOME_LOAN 일부/전액상환 처리
- HOME_LOAN 일부상환 후 잔여만기 유지 + 월상환액 재계산
- 이직 시 기존대출 포함 상환가능성 검사
- 순주택자산 계산
- 대출상태 생성/종료

단, 엔진이 참조하는 금리, 기간, 비율, threshold, 안전선, 활성여부, 최소 일부상환액과 UI 문구는 본 섹션의 어드민 데이터로 관리한다.

---

# 36. 부동산 시세 상세 관리

출처: `12_market_price.md`

`12_market_price.md` V0.1 상세기획 확정내용을 본 섹션의 기준으로 사용한다.

핵심 운영원칙:

> 어드민은 시장의 상승/보합/하락 흐름을 조작하지 않고, 현실시간 기준으로 새 게임을 시작하는 플레이어의 `Starting Market Snapshot`만 관리한다.

## 36.1 Starting Market Snapshot 마스터

관리 필드 후보:

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

상태 후보:

```text
DRAFT
PUBLISHED
RETIRED
```

기본 운영주기는 분기 1회 검토/발행을 추천한다.

시장변동이 작으면 기존 Snapshot의 적용기간을 연장할 수 있다.

## 36.2 Snapshot Price

신규게임 시작가격은 개별 매물마다 직접 입력하지 않고 다음 조합별 게임용 기준단가로 관리한다.

```text
snapshot_id
region_id
contract_type
market_type
base_unit_price
```

계약유형:

```text
RENT
JEONSE
SALE
```

시장유형:

```text
MULTIFAMILY
OFFICETEL
APARTMENT
```

원룸/투룸/옥탑 등은 `02_real_estate.md`의 market_type / layout_type 분리정책을 따른다.

## 36.3 Snapshot 적용 정책

신규 플레이어가 게임을 시작하면 현실시점에 활성화된 Snapshot을:

```text
start_market_snapshot_id
```

로 저장한다.

새 Snapshot이 Publish되어도 기존 플레이어의 시작가격 기준이나 현재시세를 변경하지 않는다.

기존 플레이어는 자신의 게임시간 시장 Cycle을 계속 따른다.

이 적용정책은 코드 규칙이다.

## 36.4 Snapshot 생성 근거

실거래/현실시장 자료는 Snapshot 작성의 참고근거다.

관리/기록 후보:

- data_reference_period
- 데이터 출처 메모
- 이전 Snapshot 대비 지역/유형별 변화율
- 현실 변화율
- 게임 적용 변화율
- 운영자 조정사유

실거래 API를 게임가격에 자동 실시간 연동하지 않는다.

현실가격 변화가 크더라도 신규유저 progression을 위해 게임용 변화폭을 압축할 수 있다.

## 36.5 Snapshot Publish 검증

Publish 전 운영검증 후보:

- 적용기간 중복 여부
- 적용기간 공백 여부
- 필수 region 누락 여부
- RENT / JEONSE / SALE 누락 여부
- MULTIFAMILY / OFFICETEL / APARTMENT 필수조합 누락 여부
- base_unit_price 0/음수 여부
- 이전 Snapshot 대비 변화율 경고
- 첫 직장별 첫 매물 4~6개 생성 가능 여부
- 시작자금에서 첫 월세 선택 가능 여부
- 첫 전세/첫 자가 progression 예상시간 변화

변화율 경고 threshold는 운영 편의상 둘 수 있으나 실제 Publish 허용여부는 운영자 판단으로 남길 수 있다.

## 36.6 Snapshot 운영 편의

권장 기능:

- 이전 Snapshot 복사해서 새 Draft 생성
- 지역/계약/시장유형 Matrix 편집
- 이전 Snapshot 가격/변화율 함께 표시
- 일괄 % 보정 후 개별 수정
- Preview에서 대표 매물가격 확인
- Publish 예약
- Retire

실제 게임가격은 Published Snapshot만 참조한다.

## 36.7 재계약 가격 상하한

임대계약 갱신 시 현재 게임시세를 참조한다.

운영 밸런스값 후보:

```text
contract_type
renewal_increase_cap
renewal_decrease_cap
```

정확한 초기값은 통합 경제 시뮬레이션으로 확정한다.

기존 계약가격을 계약기간 중 매월 변경하는 기능은 두지 않는다.

## 36.8 시장 UI/문구

운영 가능한 문구 후보:

- STABLE 표시문구
- RISING 표시문구
- FALLING 표시문구
- 자가 현재시세 안내
- 구입가 대비 변화 안내
- 계약갱신 시 현재시세 안내
- 장기 시세기록/공유카드 문구

시장국면 판정 자체는 코드고정 Cycle을 따른다.

## 36.9 시세 KPI / QA 운영지표

추적 후보:

- Snapshot별 신규유저 수
- Snapshot별 첫 집 선택 분포
- Snapshot별 첫 전세 도달시간
- Snapshot별 첫 자가 도달시간
- 신규 Snapshot 전후 progression 변화
- 게임연차별 평균 SALE/JEONSE/RENT index
- 자가 구입가 대비 현재시세 분포
- 순주택자산 분포
- 계약갱신 가격변화 분포
- 장기 게임연차별 최대/중앙 주택가격
- 50년/100년/300년 이상 장기 플레이 가격표시 오류

## 36.10 12에서 코드로 유지할 항목

다음은 일반 라이브 어드민에서 변경하지 않는 코드/기획 규칙이다.

- 현실시간과 플레이어 게임시간의 시장축 분리
- 현실시간은 신규게임 Snapshot 선택에만 사용
- 시장 갱신은 플레이어 게임월 경계에서만 수행
- V0.1 `STABLE → RISING → STABLE → FALLING → STABLE → RISING` Cycle
- V0.1 36개월 Cycle 구조
- Cycle 반복
- Cycle 종료 시 누적 market index 초기화 금지
- 각 Cycle 최종 누적변화 양수
- 장기 완만한 우상향
- 장기 집값 Hard Cap 없음
- 랜덤 Noise 없음
- market Seed 없음
- 유저별 Regime 추첨 없음
- 지역별 독립 시장/고정 성장률 차등 없음
- REGION 이벤트 시세 직접효과 없음(V0.1)
- SALE / JEONSE / RENT 계약유형별 별도 시장지수 사용
- 생성된 매물가격 LOCK
- 기존 임대계약 가격 고정
- 보유 자가 current_market_value 월별 갱신
- 구입가와 현재시세 분리보존
- 신규 Snapshot으로 기존 플레이어 시세 덮어쓰기 금지
- 오프라인 시장 진행 시 월별 순차계산
- 서버 전체 플레이어 대상 현실시간 시세 배치갱신 없음

현재 Cycle 구간 길이와 월변동률은 V0.1 통합 시뮬레이션 결과 필요시 상세기획/코드 버전업으로 수정한다. 일반 운영 어드민에서 즉석 변경하는 값으로 두지 않는다.
