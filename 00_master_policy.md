# RealEstate 게임 기획 정리
기준일: 2026-08-25
상태: 00~16 핵심 상세기획 정합성 반영 완료

## 0. 문서 목적

이 문서는 현재까지 확정된 `방 한 칸에서 한남동까지` 게임의 핵심 기획 원칙과 시스템 방향을 정리한 마스터 문서다.

세부 규칙과 데이터 테이블은 각 번호별 상세 MD를 Source of Truth로 사용한다.

---

# 1. 게임 한 문장 정의

서울에서 첫 직장을 얻은 사회초년생이 작은 집에서 시작해 월급을 받고, 집을 꾸미고, 이직하고, 이사하며 더 좋은 삶과 집을 만들어가고, 극장기에는 서울의 여러 집을 소유·꾸미고 관리하며 자신의 주거 역사를 수집하는 힐링형 주거 성장 시뮬레이션.

---

# 2. 핵심 판타지

## 2.1 중심은 부동산 투자게임이 아니다

핵심 감정루프:

```text
갖고 싶은 집/가구 발견
→ 돈이 조금 부족
→ 기다리거나 부업
→ 구매
→ 집이 좋아짐
→ 캐릭터 생활장면 변화
→ 더 좋은 집/삶 욕망
```

초반 질문:

> 다음에는 어떤 집에서 살아볼까?

라이프스테이지 이후:

> 다음에는 어떤 삶을 살아볼까?

다주택 이후:

> 다음에는 어떤 집을 하나 더 가져볼까?

극장기:

> 서울에서 어떤 집들을 내 컬렉션으로 만들어볼까?

## 2.2 현실의 주거욕망을 게임에서 충족

플레이어가 부러워하는 것은 단순 자산숫자가 아니라:

- 비 오는 밤 소파
- 창가 독서
- 욕조
- 테라스 커피
- 예쁜 조명
- 취미방
- 큰 거실
- 첫 자가
- 오래 보유한 첫 집
- 서로 다른 컨셉의 여러 집

같은 장면이다.

좋은 가구/집은 `새로운 삶의 장면`을 산다는 의미를 가진다.

---

# 3. 시간 시스템

## 3.1 기본

- 현실 활성 30분 = 게임 1개월
- 임대 기본계약 24개월
- 오프라인 최대 인정 3게임개월 = 현실 90분
- 온라인/오프라인은 하나의 게임달력

## 3.2 생물학적 나이/죽음 없음

게임시간은 경제·주거·커리어 시간이다.

- 사회생활 N년 N개월
- 게임 연월
- 계약잔여기간
- 월급 countdown

을 사용한다.

플레이어/파트너/자녀가 게임월만큼 생물학적으로 노화하지 않는다.

죽음/강제 엔딩 없음.

## 3.3 중요한 선택

자동확정하지 않음:

- 계약갱신/이사
- 매매/대출
- 이직/승진 중요결정
- 투자
- Household State 전환
- current residence 변경
- 중요한 Property 수리/미루기

실제 중요선택 화면에서 시간정지 가능.

## 3.4 오프라인

자동 가능:

- 월급/정기지출
- 기존 대출상환
- 커리어 기본진행
- 시장 Cycle
- 모든 OWNED_PROPERTY 현재가치 갱신
- AUTO/RECORD 이벤트
- 모든 보유주택 Maintenance 후보판정
- 기존 Property Issue 악화

자동 금지:

- 부업
- 신규대출
- 구매/매도
- 이사
- 글로벌 CHOICE
- Property 수리/미루기 CHOICE

복귀 시 월별 팝업폭격 대신 통합정산 + 주택관리 리포트.

---

# 4. 경제 구조

## 4.1 월급

가장 안정적인 장기 성장수단.

승진/이직은 영구 경제성장.

광고/결제로 월급·승진 직접구매 없음.

## 4.2 생활비

초기 목표:

- 정기지출 월급 약 65~80%
- 가처분소득 약 20~35%

소득/주거/Household가 커지면 라이프스타일 비용도 증가.

## 4.3 Household

PARTNER/FAMILY는 생활비가 늘지만 PARTNER의 `household contribution`이 일부 기여.

파트너 contribution은 플레이어 salary와 분리.

## 4.4 사용 가능 현금

```text
cash_balance
reserved_mandatory_expenses
spendable_cash = max(0, cash_balance - reserved_mandatory_expenses)
```

가구/인테리어/투자/일반소비/수동 대출상환/추가주택 현금구매/수리비 등은 `spendable_cash` 기준.

## 4.5 장기 명목경제

12의 주택가격은 Hard Cap 없이 수백 게임년 우상향할 수 있다.

따라서 극장기에는 소득·경제규모도 장기 명목성장 가능해야 한다.

구체 장기 소득곡선은 01/03 통합 경제 시뮬레이션에서 조정할 밸런스 과제로 남긴다. 현재 임의 숫자를 확정하지 않는다.

---

# 5. 광고 = 부업

- 일반 게임머니
- 부족액 없어도 잔여횟수 내 상시 가능
- 1회 보상 예상 월 가처분소득 약 15~20%, 기본 테스트 20%
- 일반 약 5회/게임월
- 적극사용 성장속도 목표 무광고 대비 약 1.7~2.2배
- 오프라인 자동실행 없음

사용처 제한 없음.

부업은 경제 가속수단이지 생활스탯/승진/대출잔액 직접 보상이 아니다.

---

# 6. 직장 / 커리어

회사 주요속성:

- 월급
- 근무지역
- 업무강도
- 성장성
- 안정성
- 부업기회

업무지구:

- 광화문
- 여의도
- 구로
- 강남
- 판교

첫 직장 테스트:

| 직장 | 초봉 | 근무지 | 업무강도 | 안정성 | 성장성 | 부업 |
|---|---:|---|---:|---:|---:|---:|
| 광화문 안정기업 | 300만 | 광화문 | 2 | 4 | 2 | 6 |
| 구로 IT | 330만 | 구로 | 3 | 3 | 4 | 5 |
| 강남 스타트업 | 370만 | 강남 | 4 | 2 | 5 | 3 |

승진/이직은 재직기간 + 성장 + 이벤트 관계를 사용.

대표 cooldown:

- PROMOTION→PROMOTION 12개월
- JOB_CHANGE→JOB_CHANGE 12개월
- JOB_CHANGE→PROMOTION 6개월
- PROMOTION→JOB_CHANGE 3개월 weight 감소
- JOB_CHANGE→RESTRUCTURING_MAJOR 3개월 block

실직/구조조정은 게임오버 아님.

---

# 7. 통근과 주거 Utility

지역을 단순 상하티어로 보지 않는다.

```text
집 자체 가치
+ current residence ↔ 현재 직장 통근
+ 생활환경
+ FAMILY일 때 교육환경/공간적합도
```

통근은:

- 스트레스
- 체력
- 자유시간
- 부업
- 자기계발

에 영향을 준다.

다주택이 있어도 통근/Household Utility는 current residence 1곳만 사용한다.

---

# 8. 부동산 / 시장

## 8.1 거래형태

- 월세
- 전세
- 매매

## 8.2 정적 가격

`02_real_estate.md`:

```text
지역
× 시장유형
× 계약유형
× 면적
× 연식
× Feature
× 기타 보정
```

가상 매물 중심.

## 8.3 신규게임 시작가격

현실시장 자료는 `Starting Market Snapshot`의 참고근거.

현실시간은 신규게임 출발가격을 정할 때만 사용.

기본 관리단위:

```text
region × contract_type × market_type → base_unit_price
```

분기검토/Publish 추천.

기존 플레이어 세계를 신규 Snapshot으로 덮어쓰지 않는다.

## 8.4 게임 내부 Market Cycle

36개월 고정패턴:

```text
STABLE
→ RISING
→ STABLE
→ FALLING
→ STABLE
→ RISING
→ 반복
```

- 랜덤/Seed 없음
- Cycle 종료 후 누적지수 초기화 없음
- FALLING은 실제 하락
- 전체 Cycle 순변화 양수
- 장기 완만한 복리 우상향
- 장기 가격 Hard Cap 없음
- 지역별 독립 Regime/영구 성장률 우위 없음
- REGION 이벤트 시세 직접효과 없음 V0.1

수백년 뒤 수십·수백억원 이상 가격은 정상 결과.

## 8.5 매물/계약/보유집

- 신규 매물은 현재시세로 생성
- 생성 매물가격은 소멸까지 LOCK
- 기존 임대계약 가격은 계약기간 고정
- 갱신은 현재시세 + 필요시 cap
- 모든 OWNED_PROPERTY current_market_value는 매 게임월 갱신
- 모든 보유집은 같은 플레이어 개인 SALE market index 사용

---

# 9. 첫 시작

가안:

> 서울에서 첫 직장을 얻었습니다.
> 가진 돈은 2,500만 원.
> 살 집을 찾아야 합니다.

첫 세션 핵심:

1. 첫 직장
2. 첫 집
3. 빈집
4. 최소 가구
5. 욕망 가구
6. 부족액
7. 기다리기/부업
8. 구매
9. 생활변화
10. 첫 월급정산

---

# 10. 신축 / 구축

신축:
- 비쌈
- 기본 상태 좋음
- Maintenance 낮음

구축:
- 저렴/넓음 가능
- 기본 상태 낮음
- Maintenance weight 높음 가능
- 리모델링 욕망 큼

구축의 관리리스크는 current residence뿐 아니라 다주택 보유 후에도 해당 property의 개성으로 유지된다.

---

# 11. 인테리어 / 가구

가구는 장비가 아니라 생활기능.

```text
가구 → 생활행동
가구조합 → 공간환경
Feature/시공 → 새로운 생활씬
```

전월세:
- 이동/원상복구 꾸미기 중심

자가:
- 벽/바닥/욕실/주방/붙박이/고정조명/전체 인테리어 해금

시공비는 주택 매매가에 직접 가산하지 않는다.

가구 구매 부족액은 `spendable_cash` 기준.

중고판매 없음.

---

# 12. 캐릭터 생활

핵심 스탯:

```text
ENERGY
STRESS
HAPPINESS
```

0~100 + 자연어 상태.

캐릭터가 current residence에서 자율생활.

좋은 집은 회복공간이며 직장/통근의 소모를 보완.

가구가 늘수록 행동/조합씬이 늘어남.

PARTNER/FAMILY가 있으면 current residence에서 복수 캐릭터 생활씬 가능.

비거주 보유집에서는 Household 자율생활을 동시에 돌리지 않는다.

---

# 13. Grid / 평면도

- House → Floor → Space → Grid → Furniture
- 대부분 단층
- 1 Grid ≈25cm
- 4방향 회전
- interaction point
- Surface Slot
- 일반방 용도는 가구배치 기반 자동인식
- 같은 평수에도 여러 floorplan

MVP 전체 자동배치/추천배치는 사용하지 않는다.

Grid snap/회전제안/가능위치 하이라이트 같은 보조기능은 허용.

다주택에서는 각 property의 Grid/인테리어/가구상태를 동시에 독립 저장.

---

# 14. 이사 / 인벤토리

이동가구는 영구소유.

보관함은 전역 공용, 게임적으로 무제한.

한 가구 인스턴스는 한 위치에만 존재.

### 매도/임대퇴거

```text
해당 집 이동가구 전량회수
→ GLOBAL STORAGE
```

### 기존집을 보유한 다주택 이사

```text
가구 기본적으로 기존집 유지
→ 가져갈 가구만 선택 이동
```

새집 자동배치 없음.

보유중 property는 과거 스냅샷이 아니라 Live House.

매도/퇴거할 때만 최종 스냅샷을 주거역사에 남긴다.

---

# 15. 대출

기본 상품:

```text
JEONSE_LOAN
HOME_LOAN
```

V0.1:

```text
active_housing_loan_count <= 1 per player
```

즉 플레이어 전체 기준 최대 1개.

전세:
- 이자만
- 일부상환 없음
- 계약종료 보증금에서 원금정산

HOME:
- 원리금균등
- 기본 360개월
- 실행 다음월 첫상환
- 일부/전액상환
- 최소 일부상환 100만원 기본
- 중도상환수수료 없음
- 일부상환 후 잔여만기 유지/월상환 재계산

대출한도:

```text
min(property_based_limit, affordability_based_limit)
```

다주택에서 HOME_LOAN이 걸린 과거집을 보유하고 다른 집을 현금구매할 수 있다.

current residence 변경만으로 기존 HOME_LOAN이 종료되지 않는다.

담보집 매도 또는 전액상환이 종료 trigger.

---

# 16. 이벤트

시간타입:

```text
AUTO / RECORD / CHOICE
```

발생:

```text
RANDOM / SCHEDULED / FOLLOWUP
```

Scope:

```text
PLAYER
CAREER
CURRENT_RESIDENCE
OWNED_PROPERTY
REGION
```

글로벌 RANDOM 약40~60% 테스트.

글로벌 중요 CHOICE 월 0~1개 목표.

## 16.1 Property Maintenance

다주택 이후 모든 OWNED_PROPERTY를 독립적으로 판정.

예:

- 누수
- 보일러
- 수도/전기
- 창호

보유주택 수가 늘면 Maintenance 기대발생량도 실제 증가.

Property 사건은 글로벌 중요 CHOICE cap과 별도.

같은 달 여러 사건은 관리 리포트로 묶는다.

## 16.2 Residence Life

층간소음/이웃/수면방해 등 실제 생활문제는 CURRENT_RESIDENCE에서만.

## 16.3 Property Issue

미루면 `linked_property_id` 단위로 독립 issue가 남아 비용/상태/사용제한이 악화될 수 있다.

비거주집 issue는 플레이어 stress보다 해당 주택 상태에 주로 영향.

랜덤으로 집/가구 영구손실 없음.

---

# 17. 투자 / 확률

월급 = 안정 기본.

부업 = 선택형 노력.

투자 = 별도 위험/보상 이벤트.

행운 = 작은 양념.

`광고 → 복권 → 랜덤보상`은 사용하지 않는다.

다주택은 투자시스템 확장이 아니라 주거 컬렉션/복수 집꾸미기 시스템이 우선이다.

---

# 18. 라이프스테이지

생물학적 나이가 아니라 Household State.

```text
SOLO
PARTNER
FAMILY_WITH_CHILD
```

- SOLO도 완전 장기플레이
- PARTNER/FAMILY 비필수
- 전환은 CHOICE
- 오프라인 자동확정 없음
- 자가 여부와 독립
- 작은집에서도 가능, 공간부족은 soft pressure
- 파트너는 별도 커리어 시뮬레이션 대신 household contribution
- FAMILY 교육환경 Utility
- 자녀 실제 연령 progression 없음 V0.1
- 랜덤 이별/사망/가족 영구손실 없음

실제 Household 생활은 current residence 기준.

---

# 19. 힐링 / 생활앨범

계절:

```text
SPRING 3개월
SUMMER 3개월
AUTUMN 3개월
WINTER 3개월
```

현실 계절/날씨/시간과 강제연동 없음.

생활씬 발생은 07.

발견/앨범/Photo/공유는 14.

기본 기록영역:

- 현재 거주지
- 생활 장면
- 내 집
- 서울 주거 도감
- 주거 역사

수동 Photo 테스트:

```text
게임월당 3장
집별 20장
```

OS 스크린샷 통제 없음.

PARTNER/FAMILY 미선택을 전체 앨범 미완성으로 보지 않는다.

주거 도감은 의도적 completion이므로 완성률 허용.

---

# 20. 공유 / 소셜

외부 공유 우선.

카드:

- HOME
- MOVE
- MILESTONE
- LIFE_SCENE
- HISTORY
- MARKET_HISTORY
- PROPERTY_COLLECTION

`FEATURED_PROPERTY`를 current residence와 별도로 대표집으로 설정 가능.

대표집은 소셜표시만 바꾸며 gameplay effect 없음.

자산/보유주택 수 랭킹 없음.

게임 내 소셜 첫 확장은 다른 플레이어 집구경 + 테마 큐레이션 중심.

---

# 21. 다주택 / 주거 컬렉션

`16_multi_property.md`가 Source of Truth.

## 21.1 진입

첫 자가 이후 구조적으로 가능.

한남 도달을 hard gate로 사용하지 않는다.

경제적으로는 기존집을 보유하면 매도 예상 순자산을 신규집 구매자금에 쓸 수 없으므로 자연스럽게 후기 콘텐츠가 된다.

## 21.2 구매/거주

주택 구매와 current residence 변경을 분리.

- 사서 이사
- 사서 보유
- 새집 이사 + 기존집 보유

current residence는 항상 1개.

단순 방문은 residence 변경 아님.

보유집 간 residence 변경은 정식 이사.

## 21.3 V0.1 경제

- 추가주택 현금구매
- 플레이어 전체 활성 주거대출 최대1
- 임대수익 없음
- 정기 다주택 고정보유세/고정관리비 없음
- 보유주택 gameplay hard cap 없음

Maintenance가 변동형 관리부담/경제 Sink 역할.

## 21.4 집 상태

모든 보유집:

- 방문
- 꾸미기
- Photo
- 시세기록
- Maintenance

가능.

집별 가구/시공/Grid 상태 동시보존.

## 21.5 주거 도감

`한 번이라도 소유`한 대표콘텐츠 영구발견:

- 지역
- 주거유형
- Feature
- 대표 floorplan

현재 내 집 목록과 영구 도감을 분리.

컬렉션 보상은 큰 현금보다 배지/오브제/공유프레임.

## 21.6 다주택 Maintenance

모든 OWNED_PROPERTY마다 독립판정.

보유수 증가 → 사건 기대량 실제 증가.

사건을 없애지 않고 UI만 관리 리포트/일괄수리로 묶어 조작부담 감소.

반드시 다음 규모 QA:

```text
1 / 3 / 10 / 30 / 100 / 300채
```

영구 주택/가구 손실 없음.

후속 확장:

```text
SECOND_HOME_STAY
RENT_OUT
PROPERTY_MANAGER
MULTI_HOME_LOAN
HOLDING_COST
```

---

# 22. 엔드게임

한남동급 최고집은 게임 종료가 아니라 1주택 progression의 대형 milestone.

그 이후:

```text
첫 자가
→ 상급 자가
→ 프리미엄 current residence
→ 기존집 보유/추가집 구매
→ 지역 수집
→ 주거유형 수집
→ Feature/floorplan 수집
→ 수십·수백채의 개인 서울 주거역사
```

으로 확장.

목표는 부동산 레버리지 최대화가 아니라:

> 여러 집을 소유하고, 각각 꾸미고, 오래 보유하고, 관리하고, 기록하는 것.

---

# 23. MVP 핵심 검증

초기 MVP:

1. 첫 직장/첫 집 선택
2. 월급/생활비 정산
3. 가구 구매욕망
4. 생활장면 변화
5. 계약 후 이사욕망
6. 부업 즉시소비/장기저축
7. 이벤트가 생활감을 더하는지
8. 계절/날씨/앨범이 집을 다시 보게 하는지
9. 이전집 기록/Before-After 성장감

PARTNER/FAMILY, 게임 내 소셜, 다주택은 출시범위에서 단계적으로 제외할 수 있다.

단 데이터/엔진 구조는 확장을 막지 않아야 한다.

---

# 24. 상세문서 구조 / 상태

핵심 번호형 상세기획:

```text
00_master_policy.md
01_economy_balance.md
02_real_estate.md
03_career.md
04_time_contract.md
05_furniture.md
06_house_grid.md
07_character_life.md
08_ads_sidejob.md
09_moving_inventory.md
10_events.md
11_loan.md
12_market_price.md
13_life_stage.md
14_healing_social.md
15_admin.md
16_multi_property.md
```

**현재 00~16 핵심 시스템 상세기획은 모두 한 차례 확정 완료된 상태다.**

`99_full_game_design.md`가 존재할 경우 이후 통합본/제품기획서 역할로 갱신할 수 있다.

---

# 25. 남은 작업의 성격

이제 다음 단계는 새로운 번호별 시스템 상세기획보다:

- 전체 경제 시뮬레이션
- 수치 확정
- 콘텐츠 제작량/에셋 정의
- MVP 범위 컷
- 데이터/DB 스키마
- UI Flow
- 프로토타입
- QA 시나리오

가 중심이다.

특히 아직 숫자로 최종 확정하지 않은 주요 항목:

- 시작/주거 절대가격
- 장기 소득 명목성장
- Market Cycle 계약유형별 최종 월변동률
- 대출 affordability threshold
- Household contribution/생활비
- 다주택 Maintenance 확률/수리비
- residence 변경 cooldown 최종값

이 값은 통합 경제/극장기 시뮬레이션 후 확정한다.

---

# 26. 플레이 목표 시간 가안

- 첫 욕망가구: 20~40분
- 첫 방 만족: 1~2시간
- 첫 이사: 4~8시간
- 첫 전세: 10~20시간
- 첫 자가: 20~40시간
- 중형 아파트: 50~100시간
- 한남급 프리미엄: 장기 목표이자 다주택/컬렉션 milestone

아직 밸런스 QA용 목표값.

---

# 27. 최종 제품 원칙

> 돈을 많이 버는 게임보다 좋은 삶을 조금씩 완성하는 게임을 만든다.

플레이어가 다음 집을 꿈꾸고,
그 집을 갖기 위해 조금 더 일하고,
조금 기다리고,
조금 더 꾸미고,
그 안에서 캐릭터가 더 잘 사는 모습을 본다.

그리고 아주 오래 플레이한 뒤에는 지나온 집, 아직 가진 집, 관리해온 집, 그 안의 생활장면들이 하나의 개인 서울 주거역사가 된다.

---

# 28. 어드민 운영 원칙

운영값 Source of Truth는 `15_admin.md`.

대표 어드민 대상:

- 경제/시간
- 회사/급여/커리어
- 지역/통근
- Starting Market Snapshot
- 매물/특별매물/floorplan
- 가구/시공/해금
- 광고/부업
- 대출금리/한도/threshold
- 생활행동/생활씬
- 이벤트/cooldown/followup
- Household profile
- 계절/날씨/앨범/Photo/공유
- 다주택 해금/컬렉션 slot
- Property Maintenance 확률/수리/악화 profile
- 관리 리포트

코드영역:

- Grid/pathfinding
- 상태머신
- 저장/로드
- 시간엔진
- 고정 Market Cycle
- 대출 계산엔진
- 이벤트 조건매칭/예약/Property 순회
- current residence 1개 구조
- 가구 instance 한 위치
- 영구손실 금지 등 핵심 정책

상세 MD 수정 시 15를 동시에 갱신한다.
