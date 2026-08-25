# 16_multi_property.md
기준일: 2026-08-25
상태: V0.1 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 다주택, 주거 컬렉션, 복수 집꾸미기, 보유주택 관리, 주택별 유지보수 이벤트를 상세 정의한다.

핵심 목표:

- 최고급 1주택 도달 이후에도 장기 플레이 목표가 계속될 것
- 다주택이 단순 시세차익/임대수익 게임으로 변하지 않을 것
- 여러 집을 실제로 방문하고 꾸밀 수 있을 것
- 첫 자가와 오래 보유한 집이 개인의 주거 역사로 남을 것
- 집이 많아질수록 실제로 관리할 집도 많아진다는 책임감을 만들 것
- 수십·수백 게임년 플레이에서 서울 주거 컬렉션이 장기 progression으로 기능할 것

핵심 원칙:

> 다주택의 1차 목적은 투자수익 극대화가 아니라 `서울의 여러 집을 내 것으로 만들고, 각각 꾸미고, 오래 보유하며, 내 주거 역사를 수집하는 것`이다.

> 한남 프리미엄 등 최고급 거주주택은 강제 엔딩이 아니라 1주택 progression의 첫 번째 대형 milestone이다.

> 집을 많이 소유하면 더 많은 꾸미기 공간과 컬렉션을 얻지만, 동시에 더 많은 집을 관리해야 한다.

---

# 2. 장기 플레이 질문의 확장

초반:

> 다음에는 어떤 집에서 살아볼까?

라이프스테이지 이후:

> 다음에는 어떤 삶을 살아볼까?

다주택 이후:

> 다음에는 어떤 집을 하나 더 가져볼까?

극장기:

> 서울에서 어떤 집들을 내 컬렉션으로 만들어볼까?

다주택은 기존 progression을 폐기하지 않고 그 위에 수평적 목표를 추가한다.

---

# 3. 적용 범위

MVP 출시 시점에 다주택 전체를 반드시 포함해야 하는 것은 아니다.

다만 본 문서는 다주택 확장 시 사용할 상세규칙의 Source of Truth다.

기존 문서의 다음 규칙은 `MVP/V0.1 1주택 단계`로 해석한다.

- 자가→자가 갈아타기에서 기존집 매도
- 이사 시 현재집 이동가구 전량회수
- 현재 거주주택 중심 HOME_LOAN

다주택 기능이 활성화된 플레이어부터 본 문서의 확장규칙을 적용한다.

---

# 4. 다주택 기능 해금 방향

다주택을 `한남 프리미엄 도달 후에만` 여는 hard gate로 두지 않는다.

기본 방향:

> 첫 자가를 보유한 이후부터 구조적으로 다주택 선택이 가능하다.

다만 기존집을 보유하면 기존집 예상 매도 순자산을 새집 구매자금으로 사용할 수 없으므로 경제적으로 자연스럽게 후기 콘텐츠가 된다.

정확한 해금조건/노출조건은 어드민에서 조정할 수 있다.

후보:

- 첫 자가 구매 완료
- 일정 사회생활 개월 경과
- 다주택 안내 튜토리얼 완료

특정 지역/한남 도달을 필수조건으로 사용하지 않는다.

---

# 5. 현재 거주지와 보유주택 분리

장기적으로 다음을 분리한다.

```text
CURRENT_RESIDENCE
OWNED_PROPERTY
```

플레이어가 여러 주택을 보유해도:

```text
current_residence_count = 1
owned_property_count = 0 ~ N
```

이다.

현재 거주지 기준으로 계산하는 것:

- 통근
- ENERGY / STRESS / HAPPINESS의 주거환경 영향
- housing_satisfaction
- Household 자율생활
- 교육환경 Utility
- 기본 자율행동/생활씬
- 현재 거주 관련 월 주거비

추가 보유주택은 다음 대상이 된다.

- 컬렉션
- 방문
- 꾸미기
- 시세기록
- 보유기간 기록
- 주택별 Maintenance 이벤트
- 향후 별장/임대 확장

여러 집의 생활효과를 동시에 합산하지 않는다.

---

# 6. 주택 구매와 거주지 변경을 분리

자가 매물 구매 시 구매목적을 분리한다.

## 6.1 사서 이사하기

새 주택을 구매하고 현재 거주지를 새 집으로 변경한다.

기존 자가가 있다면:

- 기존집 매도
- 기존집 보유

중 하나를 선택한다.

## 6.2 사서 보유하기

현재 거주지를 유지하고 새 주택만 추가 보유한다.

새 주택은 `OWNED_PROPERTY`가 되며 current residence는 바뀌지 않는다.

## 6.3 기존집 보유 + 새집 이사

새집을 current residence로 만들되 기존집을 팔지 않는다.

이 경우 기존집은 추가 `OWNED_PROPERTY`로 남는다.

---

# 7. 기존집 매도와 보유의 자금 차이

## 7.1 기존집 매도

새집 구매계획에 다음 예상 순자산을 반영할 수 있다.

```text
예상 매도가
- 남은 HOME_LOAN 원금
- 예상 매도비용
= 예상 순자산
```

`11_loan.md`의 기존 자가 갈아타기 규칙을 사용한다.

## 7.2 기존집 보유

기존집은 매도하지 않으므로:

```text
기존집 예상 순자산
→ 새집 구매자금으로 사용 불가
```

새집 구매는 실제 사용 가능한 현금과 허용되는 신규대출만 사용한다.

즉 자산이 많아 보여도 집에 묶인 미실현 순자산을 마음대로 현금처럼 사용하지 않는다.

---

# 8. 추가주택 V0.1 구매방식

다주택 첫 버전에서는 추가 보유주택을 `현금구매` 중심으로 연다.

```text
ADDITIONAL_PROPERTY
→ CASH ONLY
```

추가주택 구매 가능금액은:

```text
spendable_cash
```

범위 안에서만 사용한다.

목적:

- 복수 주담대 금융복잡도 방지
- 레버리지 투자게임화 방지
- 다주택을 장기 돈 Sink로 사용
- 기존 커리어/부업/저축 의미 유지

---

# 9. HOME_LOAN V0.1 다주택 규칙

다주택 활성화 이후에도 V0.1에서는:

```text
active HOME_LOAN <= 1 per player
```

를 유지한다.

즉 `현재 거주지 기준 1개`가 아니라 플레이어 전체 기준 활성 HOME_LOAN 최대 1개다.

기존 주담대가 남은 과거집을 보유한 상태에서 다른 집을 현금으로 구매하는 것은 허용한다.

예:

```text
서대문 첫 자가
HOME_LOAN 잔액 1.2억

성동 새 자가
현금구매
```

가능.

새 집에 HOME_LOAN을 사용하려면:

- 기존 HOME_LOAN 전액상환
- 또는 기존 담보주택 매도 후 자동정산

으로 활성 대출을 먼저 종료해야 한다.

복수 HOME_LOAN은 후속 확장이다.

---

# 10. 임대수익 V0.1 제외

다주택이라고 바로 월세/전세 임대수익을 제공하지 않는다.

첫 다주택 버전의 보유가치:

```text
보유
+ 시세변화
+ 방문/꾸미기
+ 컬렉션
+ 기록
```

임대수익 없음.

이유:

```text
집 구매
→ 임대수익
→ 다음 집 구매 가속
→ 임대수익 증가
```

의 자기증식 루프가 커리어·부업·저축을 압도하는 것을 막기 위해서다.

---

# 11. 정기 다주택 보유세/관리비 V0.1 제외

V0.1에서는 주택마다 매월 고정 보유세/관리비를 단순 곱해 부과하지 않는다.

예:

```text
50채 × 매월 고정 관리비
```

처럼 장기 컬렉션을 반복 정산으로 피곤하게 만들지 않는다.

대신 각 주택의 Maintenance 이벤트가 변동형 관리부담과 경제 Sink 역할을 한다.

향후 임대수익을 도입할 경우 보유비용/세금/공실과 함께 재설계한다.

---

# 12. 보유주택 수 Hard Cap

게임 progression 상:

```text
최대 10채
최대 30채
```

같은 소유 Hard Cap을 두지 않는다.

수십·수백 게임년을 플레이하면 수십/수백 채를 보유하는 것도 정상 시나리오다.

기술적 안전상한이 필요하면 플레이어가 체감하지 않을 만큼 높은 내부 제한으로 둔다.

극장기 UI/저장/이벤트 성능은 100채 이상을 전제로 QA한다.

---

# 13. 보유주택 방문

`내 집` 목록에서 모든 보유주택을 다시 방문할 수 있다.

예:

```text
[현재 거주지]
한남 아파트

[내가 가진 집]
서대문 첫 자가
성동 한강뷰 아파트
마포 테라스 빌라
```

보유집에서 가능한 기본 행동:

- 방문하기
- 꾸미기
- Photo Mode
- 이 집으로 이사하기
- 매도하기
- 대표집으로 설정하기

단순 방문은 current residence 변경이 아니다.

---

# 14. 방문과 실제 거주를 분리

보유집을 방문해도 다음은 변경하지 않는다.

- 통근시간
- 월 생활비
- Household Utility
- 교육환경 적용
- current residence 기반 생활스탯

`이 집으로 이사하기`를 명시적으로 실행해야 current residence가 변경된다.

방문은 집구경/꾸미기/사진/관리 목적의 편집 컨텍스트다.

---

# 15. 보유주택 간 Current Residence 변경

내가 이미 보유한 다른 집으로 거주지를 바꾸는 것도 정식 이사다.

```text
MOVE_RESIDENCE
```

처리 후보:

- 이사비 발생
- current residence 변경
- 통근 재계산
- Household Utility 재계산
- 기존 current residence는 보유주택으로 유지

거주지 스위칭 최적화를 막기 위해 `residence_change_cooldown_months`를 둘 수 있다.

초기 테스트 후보:

```text
3 game months
```

정확한 값은 어드민/QA에서 조정한다.

---

# 16. 집별 배치상태 동시보존

각 보유주택은 독립적인 집꾸미기 상태를 계속 가진다.

예:

```text
한남 집
- 브라운 모듈 소파
- 홈바

성동 집
- 크림 소파
- 원목 식탁

서대문 첫 자가
- 오래된 책장
- 초창기 침대
```

보존 대상:

- floorplan state
- wall/floor state
- 집 귀속 시공
- 붙박이/주방/욕실
- placed furniture
- furniture color variant
- surface slot
- interaction point 배치정보

다주택의 핵심 가치는 `여러 개의 저장 가능한 집꾸미기 공간`을 갖는 것이다.

---

# 17. 가구 인스턴스는 한 장소에만 존재

이동가구 한 인스턴스가 동시에 여러 집에 복제되지 않는다.

가구 상태:

```text
PLACED
STORED
MOVING
```

추가 위치값:

```text
placed_house_id
```

예:

```text
cream_sofa_instance_123
status = PLACED
placed_house_id = SEONGDONG_HOME_01
```

한 집에서 다른 집으로 이동하면 원래 집에서는 제거된다.

---

# 18. 보관함은 전역 공용

보관함은 집별로 분리하지 않고 플레이어 전체 공용으로 유지한다.

```text
GLOBAL STORAGE
```

보관함 UI에서는 가구 위치를 보여준다.

예:

```text
크림 모듈 소파
현재 위치: 성동 집

원목 식탁
현재 위치: 한남 집

플로어램프
보관함
```

다른 집에 배치 중인 가구를 가져오면 기존 집에서 제거한 뒤 현재 편집집으로 이동한다.

---

# 19. 기존집 매도 시 가구처리

기존집을 매도하는 경우 `09_moving_inventory.md`의 전량회수 정책을 유지한다.

```text
매도 대상 집의 모든 이동가구
→ MOVING
→ GLOBAL STORAGE
```

집 귀속 시공은 매도집에 남는다.

매도 직전 최종 집 스냅샷을 생성한다.

---

# 20. 기존집 보유 이사 시 가구처리

기존집을 보유한 채 새집으로 이사하면 이동가구를 전량회수하지 않는다.

기본:

```text
기존집의 가구
→ 기존집에 그대로 유지
```

플레이어가 `새집으로 가져갈 가구`만 선택한다.

예:

```text
✓ 침대
✓ 커피머신
□ 기존 소파
□ 원목 식탁
```

선택한 가구만 기존집에서 제거되어 이동한다.

이 선택은 자동배치가 아니며 새집 도착 후 보관함/배치 단계에서 직접 배치한다.

---

# 21. 새집 구매 후 기본 상태

새로 구입한 집은 기존 정책대로 구매 시점의 기본/시공 상태로 시작한다.

`사서 보유하기`를 선택한 경우에도 자동으로 가구를 채워주지 않는다.

플레이어가 보관함/다른 보유주택의 가구를 옮기거나 새 가구를 구매해 꾸민다.

---

# 22. 주거 컬렉션의 핵심

보유 이유를 시세차익 외에 다양하게 만든다.

- 첫 자가라서
- 특정 지역의 집이라서
- 희귀 평면이라서
- 테라스/한강뷰/복층 등 Feature가 있어서
- 특정 주거유형을 모으기 위해
- 특정 생활씬을 위한 공간이라서
- 오래 보유한 개인 기록이라서

다주택은 `집이라는 콘텐츠를 수집하는 시스템`이다.

---

# 23. `주거 도감`과 `현재 내 집 컬렉션` 분리

두 개를 구분한다.

## 23.1 주거 도감

한 번이라도 소유해 본 콘텐츠의 영구 기록.

집을 매도해도 유지된다.

## 23.2 현재 내 집 컬렉션

지금 실제로 보유 중인 주택 목록.

매도하면 목록에서 빠진다.

예:

```text
서울 주거 도감 82%
현재 보유 17채
```

---

# 24. 모든 집 수집의 기준

랜덤 생성되는 모든 개별 `house_id`를 수집대상으로 두지 않는다.

무한 매물 생성 구조에서는 100% 달성이 불가능하기 때문이다.

도감 슬롯은 대표 콘텐츠 단위로 정의한다.

기본 축:

- 지역
- 주거유형
- 희귀 Feature
- 대표 floorplan template

---

# 25. 지역 컬렉션

초기 생활권 예:

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

한 번이라도 해당 지역 자가를 소유하면 지역 도감 기록을 획득할 수 있다.

---

# 26. 주거유형 컬렉션

예:

- 옥탑
- 원룸
- 투룸
- 오피스텔
- 빌라
- 아파트
- 프리미엄 주거

실제 게임 housing_type 구조와 매핑한다.

---

# 27. Feature 컬렉션

예:

- TERRACE
- RIVER_VIEW
- CORNER_WINDOW
- DUPLEX
- ATTIC
- LARGE_BATHROOM
- ROOFTOP_SPACE
- LARGE_WINDOW
- DRESSROOM
- PANTRY

Feature를 가진 집을 소유하면 해당 도감 슬롯을 획득한다.

특정 Feature가 희귀할수록 특별매물과 컬렉션 욕망이 강해진다.

---

# 28. Floorplan 컬렉션

대표 floorplan template를 장기 컬렉션 축으로 사용할 수 있다.

예:

```text
대표 평면 24 / 35
```

단 모든 생성형 매물의 세부 배치변형까지 별도 슬롯으로 만들지 않는다.

---

# 29. 컬렉션 UI

예:

```text
서울 주거 도감

지역          9 / 10
주거유형      7 / 7
희귀 Feature  6 / 10
대표 평면    24 / 35

전체           73%
```

다주택은 의도적인 수집콘텐츠이므로 완성률 표시를 허용한다.

단 집 이미지/취향/생활가치보다 효율 숫자를 더 크게 강조하지 않는다.

---

# 30. 컬렉션 보상

큰 현금보상을 사용하지 않는다.

금지 예:

```text
도감 50% 달성
→ 현금 5억원
```

추천 보상:

- 프로필 배지
- 공유카드 프레임
- 기념 오브제
- 비경제 장식품
- Photo Mode 프레임
- 앨범 꾸미기 요소

컬렉션은 경제 파밍보다 자랑/기록 보상을 제공한다.

---

# 31. 특별매물과 다주택

다주택 이후 특별매물의 역할이 확장된다.

이전:

> 지금 이 집으로 이사하고 싶은가?

이후:

> 지금 살지는 않아도 소유하고 싶은가?

예:

```text
서촌 다락집 특별매물
현재 한남 거주
→ 컬렉션용 구매
```

최고급 집에 도달한 뒤에도 매물 탐색을 계속할 이유가 생긴다.

---

# 32. 매물 UI의 컬렉션 정보

보조정보로 해당 매물이 새 도감 슬롯을 채우는지 알려줄 수 있다.

예:

```text
마포 테라스 빌라

주거 도감
✓ 마포
✓ 빌라
NEW 테라스
```

또는:

```text
이 집에서 새로운 컬렉션을 발견할 수 있어요.
```

`NEW ×3` 같은 RPG 효율 숫자는 과도하게 강조하지 않는다.

---

# 33. 보유주택 시세

`12_market_price.md`의 플레이어 개인 시장지수를 모든 보유주택에 동일하게 적용한다.

각 보유주택:

```text
purchase_price
purchase_game_month
current_market_value
ownership_duration
```

를 유지한다.

`current_market_value`는 게임월마다 갱신한다.

여러 보유주택이 있다고 지역별 독립 시장이나 다른 Regime을 만들지 않는다.

---

# 34. 보유주택 매도

현재 거주지가 아닌 보유주택은 플레이어 선택으로 매도할 수 있다.

기본 정산:

```text
current_market_value
- sale_cost
- linked_loan_remaining_principal(존재 시)
= cash inflow
```

현재 거주지 매도는 다음 거주지 확정 등 기존 안전규칙을 따른다.

---

# 35. 단기 Flipping 방지

시장 장기 우상향 때문에 거래비용이 없으면 짧은 기간의 반복매매가 유리해질 수 있다.

따라서:

- 매수/매도 관련 비용
- 시장 Cycle 변동폭

을 함께 조정해 단기 매매가 주요 돈벌이 루프가 되지 않게 한다.

정확한 비용은 통합 경제 시뮬레이션으로 확정한다.

다주택의 핵심 보상은 시세차익보다 컬렉션/꾸미기/기록이다.

---

# 36. 매도 후 주거 역사

보유주택을 매도하기 직전:

```text
FINAL_SNAPSHOT
```

을 자동 생성한다.

영구 보존 후보:

- purchase_price
- sale_price
- purchase_game_month
- sale_game_month
- ownership_duration
- 이전 current residence 여부
- final_snapshot_id
- 대표 생활씬

소유권은 사라져도 `주거 도감`과 `주거 역사`는 유지된다.

---

# 37. 대표집 FEATURED_PROPERTY

소셜/공유용으로 current residence와 별개인 대표집을 하나 지정할 수 있다.

```text
FEATURED_PROPERTY
```

예:

- 실제 거주: 강남 아파트
- 대표집: 서촌 테라스집

대표집은 공유/프로필 노출에만 사용한다.

통근, 생활스탯, Household Utility에는 영향하지 않는다.

---

# 38. 다주택 UI 구조

추천 기본 탭:

```text
[현재 거주지]
[내 집]
[서울 주거 도감]
[주거 역사]
```

### 현재 거주지
실제 생활하는 1곳.

### 내 집
현재 소유중인 모든 주택.

### 서울 주거 도감
한 번이라도 소유해 발견한 대표 컬렉션.

### 주거 역사
매도한 집까지 포함한 전체 과거기록.

---

# 39. 주택 이벤트의 Scope 확장

다주택 이후 주거 이벤트는 플레이어 전체 단위가 아니라 `주택 단위`를 지원해야 한다.

이벤트에 다음 개념을 둔다.

```text
event_scope
```

후보:

```text
PLAYER
CURRENT_RESIDENCE
OWNED_PROPERTY
REGION
CAREER
```

주거 이벤트에는 필요 시:

```text
linked_property_id
```

를 저장한다.

---

# 40. PROPERTY_MAINTENANCE와 RESIDENCE_LIFE 구분

모든 주거 이벤트가 모든 보유주택에서 발생하지 않는다.

## 40.1 PROPERTY_MAINTENANCE

거주하지 않아도 집 자체에서 발생 가능한 문제.

예:

- 누수
- 보일러 고장
- 수도 문제
- 전기 문제
- 창호 문제
- 시설 수리
- 관리사무소 관련 문제

기본 scope:

```text
OWNED_PROPERTY
```

## 40.2 RESIDENCE_LIFE

실제로 거주해야 의미가 있는 생활문제.

예:

- 층간소음
- 이웃 문제
- 주변 소음
- 수면 방해

기본 scope:

```text
CURRENT_RESIDENCE
```

비거주 보유집에서 층간소음 때문에 플레이어 스트레스를 올리는 식으로 처리하지 않는다.

---

# 41. 보유주택 수만큼 Maintenance 판정

주택별 Maintenance 이벤트는 각 `player_property`마다 독립적으로 발생판정한다.

즉:

```text
1채
→ 1개 property 후보

10채
→ 10개 property 후보

100채
→ 100개 property 후보
```

이다.

보유주택 수가 증가하면 전체 Maintenance 이벤트 기대발생량도 실제로 증가한다.

`플레이어당 월 최대 1건`처럼 발생량을 강제로 잘라 다주택 관리부담을 없애지 않는다.

---

# 42. 발생량과 UI 노출량을 분리

이벤트는 주택별로 실제 발생시키되 같은 달의 여러 건을 팝업 여러 개로 연속노출하지 않는다.

예:

```text
이번 달 내 집 관리

새로운 문제 4건
계속 관리 중 2건

[전체 보기]
```

즉:

> 이벤트 발생량은 유지하고, UI 조작부담은 관리 리포트로 줄인다.

---

# 43. 기존 중요 CHOICE 월 Cap과 분리

`10_events.md`의 글로벌 중요 CHOICE 목표:

```text
게임월 0~1개
```

는 커리어/인생/Household 같은 주요 선택에 유지한다.

PROPERTY_MAINTENANCE 이벤트는 이 Cap과 별도다.

```text
GLOBAL IMPORTANT CHOICE
→ 기존 월 Cap 적용

PROPERTY MANAGEMENT EVENT
→ 보유주택별 독립 판정
```

주택을 많이 가졌다는 이유로 승진/이직/라이프스테이지 이벤트가 밀려나지 않게 한다.

---

# 44. 주택별 이벤트 중복제한

같은 event_group의 중복제한 key는 property 단위로 적용한다.

예:

```text
LEAK + property_A
```

가 ACTIVE이면 property_A에 같은 누수를 또 생성하지 않는다.

하지만:

```text
property_A → 누수
property_B → 누수
property_C → 누수
```

는 동시에 가능하다.

중복판정 개념:

```text
event_group + linked_property_id
```

---

# 45. Property Issue

주택 Maintenance 사건을 미루면 해당 집에 독립적인 `Property Issue`가 남는다.

예:

```text
누수 발견 EVENT
↓
미루기
↓
LEAK ISSUE
↓
월별 악화판정
↓
수리
↓
RESOLVED
```

Issue 최소정보:

```text
issue_instance_id
property_id
issue_type
severity
started_game_month
deferred_months
current_repair_cost
status
```

기존 10의 persistent state 구조를 property_id 단위로 확장한다.

---

# 46. 주택별 관리상태

각 보유주택은 관리상태를 가진다.

기본 표시:

```text
NORMAL
NEEDS_ATTENTION
ISSUE_ACTIVE
```

예:

```text
내 집 23채

정상 20
관리 필요 2
수리 필요 1
```

내 집 목록에서도 바로 상태를 확인한다.

---

# 47. 현재 거주지 사건 우선표시

동일한 Maintenance 문제라도 current residence 여부에 따라 표시 우선순위를 다르게 한다.

현재 거주지:

```text
지금 살고 있는 집에 누수가 생겼어요.
```

추가 보유집:

```text
보유 중인 마포집에 누수가 생겼어요.
```

현재 거주지는 실제 생활환경/생활씬 영향까지 있을 수 있으므로 관리 리포트 상단에 배치한다.

---

# 48. 비거주집 Issue의 영향

비거주 보유집 문제는 플레이어 생활스탯에 직접 큰 패널티를 반복 부과하지 않는다.

주요 영향:

- 해당 집의 condition 악화
- repair cost 증가
- 일부 공간/생활씬 사용 제한
- 해당 집 방문 시 시각적 문제 연출
- 일부 꾸미기/시공 제한 가능

현재 거주지 문제는 기존 07/10처럼 생활환경과 스트레스에 추가 영향 가능하다.

---

# 49. 영구손실 금지

다주택 Maintenance에서도 기존 공정성 원칙을 유지한다.

랜덤 문제 방치로:

- 주택 소멸
- 강제매도
- 가구 영구파손/삭제
- 보증금/대형자산 영구손실

을 만들지 않는다.

악화는:

- 비용 증가
- 상태 악화
- 공간/생활씬 제한

수준으로 처리한다.

---

# 50. 집 특성과 Maintenance 확률

주택별 발생확률/가중치는 기존 주거속성을 활용한다.

후보:

- build_age
- house_condition
- housing_type
- Feature
- season
- 현재 미해결 Issue 수

예:

- 신축: 낮은 고장 weight
- 구축: 높은 고장 weight
- 특정 Feature: 관련 Maintenance event 후보 추가 가능

정확한 확률은 어드민에서 관리한다.

---

# 51. Feature별 Maintenance 확장

향후 희귀 Feature가 집의 관리 개성을 만들 수 있다.

예:

### TERRACE
- 배수 문제
- 방수 점검

### LARGE_WINDOW
- 창호 문제

### BATHTUB / LARGE_BATHROOM
- 욕실 배관 문제

### DUPLEX / ATTIC
- 구조/단열 관련 경미한 관리이벤트

Feature가 `예쁜 대신 계속 고장나는 패널티`로 느껴지지 않게 발생률은 낮게 관리한다.

---

# 52. 다주택 Maintenance는 변동형 경제 Sink

V0.1에는 정기 다주택 보유세를 두지 않지만 집이 많을수록 실제 Maintenance 이벤트 수와 수리비 기대값이 증가한다.

예:

```text
10채
→ 관리문제 가끔 발생

50채
→ 월별 관리리포트의 의미 증가
```

즉 관리이벤트가 변동형 유지비 역할을 한다.

목적은 다주택을 금지하는 것이 아니라 `실제 여러 집을 가지고 있다`는 감각을 만드는 것이다.

---

# 53. Maintenance 확률 설계 원칙

1주택 기준 빈도만 보고 확률을 정하면 극장기 다주택에서 사건이 폭증할 수 있다.

반드시 다음 보유규모를 기준으로 시뮬레이션한다.

```text
1채
3채
10채
30채
100채
300채
```

검증:

- 월 평균 신규 Issue 수
- 월 평균 수리비
- 관리 리포트 건수
- 처리 클릭 수
- 미해결 Issue 누적량
- 다주택 컬렉션 욕망 저해 여부

초기 확률숫자는 이 문서에서 확정하지 않는다.

---

# 54. 주택 관리 리포트

같은 게임월 여러 보유주택 문제는 하나의 관리 리포트에서 처리한다.

예:

```text
이번 달 내 집 관리

신규 3건
미해결 2건

마포 테라스빌라
누수
[수리] [미루기]

서대문 구축아파트
보일러
[수리] [미루기]

용산 오피스텔
창호 문제
[수리] [미루기]
```

개별 Issue는 실제로 독립 저장한다.

---

# 55. 일괄처리

다주택이 많을수록 반복 클릭을 줄이기 위해 경미한 문제의 일괄수리 기능을 제공하는 방향을 추천한다.

예:

```text
수리가 필요한 집 모두 처리
총 비용 18,400,000원
```

원칙:

> 발생량을 줄이지 않고 조작 노동만 줄인다.

큰/특수 CHOICE가 필요한 문제는 일괄처리 대상에서 제외할 수 있다.

---

# 56. 자동관리 후속확장

극장기 확장으로 `PROPERTY_MANAGER` 같은 자동관리 기능을 고려할 수 있다.

예:

```text
자동관리 ON
→ 경미한 Maintenance 자동수리
→ 관리대행 비용 발생
```

이는 100채 이상 플레이어의 UX와 후기 경제 Sink가 될 수 있다.

다만 첫 다주택 V0.1에서는 필수기능이 아니다.

---

# 57. 오프라인 다주택 이벤트

`04_time_contract.md`의 최대 3개월 오프라인 진행을 그대로 적용한다.

오프라인에서 각 게임월을 순차처리하며:

```text
모든 owned property
→ Maintenance 후보판정
→ 신규 Issue 생성
→ 기존 Issue 악화판정
```

을 수행한다.

복귀 시 여러 집 문제를 월별 팝업 여러 장으로 보여주지 않고 통합 관리 리포트로 보여준다.

플레이어가 직접 선택해야 하는 수리/미루기 CHOICE는 자동확정하지 않는다.

---

# 58. Property Management Queue

다주택 Maintenance가 기존 PENDING life choice 큐를 압도하지 않도록 논리/UI를 분리한다.

```text
PENDING_LIFE_CHOICE
PROPERTY_ISSUE_QUEUE
```

승진, 이직, Household State 등은 기존 주요 선택 큐.

누수/보일러/창호 등 주택관리 문제는 Property Management Queue.

필요하면 현재 거주지의 긴급한 문제만 주요 선택영역에도 강조할 수 있다.

---

# 59. 미루기와 악화

각 Property Issue는 독립적으로 미룰 수 있다.

예:

```text
마포집 누수 → 미룸
서대문집 누수 → 바로 수리
```

집별로:

- deferred_months
- escalation_probability
- current_repair_cost
- environment penalty

을 계산한다.

악화 프로필은 `10_events.md` 이벤트 규칙을 재사용한다.

---

# 60. 다주택과 생활씬

기본 V0.1 원칙:

> 자율생활/생활효과는 current residence에서만 진행한다.

추가 보유집 방문 중에는:

- 집 구경
- 꾸미기
- Photo Mode
- 관리문제 확인
- 단순 방문연출

을 제공할 수 있다.

보유집마다 동시에 Household 자율생활을 돌리지 않는다.

---

# 61. SECOND_HOME_STAY 후속확장

`14_healing_social.md`에서 여러 집의 서로 다른 계절생활을 즐길 가능성을 남긴다.

향후:

```text
SECOND_HOME_STAY
```

를 도입하면:

- 여름 테라스집
- 겨울 서촌집
- 비 오는 날 한강뷰집

등 별장형 생활씬을 제공할 수 있다.

현재 통근/경제 거주지는 그대로 유지하고 일시 생활씬만 제공하는 별도 시스템으로 검토한다.

V0.1 다주택에는 필수 아님.

---

# 62. 장기 공유 콘텐츠

`14_healing_social.md`와 연결한다.

공유 후보:

```text
나의 서울 주거 컬렉션
사회생활 127년 차
현재 보유주택 12채
살아본 지역 8/10
주거유형 7/7
Feature 9/12
```

또는:

```text
첫 자가
구입가 4.2억
현재시세 31.8억
보유기간 196년
```

집 수/자산숫자만 랭킹화하지 않는다.

---

# 63. 오래 보유한 집 기록

각 보유주택의 장기 history를 남긴다.

후보:

- 최초 구입가
- 현재시세
- 구입 게임월
- 보유기간
- current residence로 사용한 기간
- 대표 인테리어 변화
- 해당 집에서 발견한 생활씬
- 해결한 Maintenance 기록

예:

```text
서대문 첫 자가
보유 196년
누수 수리 4회
보일러 수리 2회
전체 리모델링 1회
```

모든 기록을 메인 UI에 노출할 필요는 없지만 주택 역사 데이터로 보존할 수 있다.

---

# 64. 다주택과 라이프스테이지

Household State는 현재 거주지에서만 실제 생활효과를 만든다.

예:

- FAMILY 교육환경 Utility → current residence 기준
- 공간부족/프라이버시 → current residence 기준
- PARTNER/FAMILY 자율생활 → current residence 기준

추가 보유집이 넓다고 현재 거주지의 공간부족을 자동 해결하지 않는다.

---

# 65. 다주택과 특별매물

특별매물은 다주택 이후 장기 탐색 동기가 된다.

- 희귀 Feature
- 희귀 평면
- 특정 지역 감성
- 생활씬 가능성

을 통해 `이미 최고집에 살지만 갖고 싶은 집`을 만든다.

특별매물을 단순 수익률 좋은 투자상품으로 만들지 않는다.

---

# 66. 다주택과 광고/부업

추가주택 구매 역시 일반 현금지출이다.

부업수입을 여러 달 모아 추가주택 현금구매에 사용하는 것을 허용한다.

다만 광고를 보고 즉시 투자주택을 자동 획득하거나 다주택 전용 대출을 제공하지 않는다.

수리비 부족 상황에서는 일반 `spendable_cash` 부족 CTA를 통해 부업 진입을 제공할 수 있다.

---

# 67. 핵심 데이터 구조 가안

## 67.1 player_property

```text
property_id
player_id
house_instance_id
source_listing_id
purchase_price
purchase_game_month
current_market_value
ownership_status
is_current_residence
is_featured_property
previously_used_as_residence
residence_started_game_month
last_visited_game_month
condition_grade
maintenance_status
active_issue_count
last_issue_game_month
```

상태 후보:

```text
OWNED
SOLD
```

## 67.2 property_house_state

```text
property_id
floorplan_state
interior_state
placed_furniture_state
```

실제 배치 데이터는 06/09의 Grid 및 furniture instance 구조와 연결한다.

## 67.3 furniture_instance 추가

```text
placed_house_id
```

한 인스턴스는 한 집 또는 보관함에만 존재한다.

## 67.4 property_collection_entry

```text
player_id
collection_type
collection_key
first_acquired_game_month
first_property_id
```

## 67.5 property_issue

```text
issue_instance_id
property_id
issue_type
severity
started_game_month
deferred_months
current_repair_cost
status
```

## 67.6 event instance 확장

```text
event_instance_id
event_id
event_scope
linked_property_id
started_game_month
status
persistent_state_id
```

---

# 68. 어드민 관리 대상

`15_admin.md`에 `#39. 다주택 / 주거 컬렉션 / 주택관리 상세 관리`를 추가한다.

주요 관리 대상:

### 다주택 해금/노출

```text
multi_property_enabled
minimum_owned_home_history
minimum_social_months
```

### 거주지 변경

```text
owned_residence_move_cost_profile
residence_change_cooldown_months
```

### 추가주택 구매

```text
additional_property_cash_only
additional_property_loan_enabled
sale_cost_profile
```

V0.1 권장:

```text
additional_property_cash_only = true
additional_property_loan_enabled = false
```

### 컬렉션

```text
collection_category
collection_slot
completion_reward_profile
display_order
```

### Maintenance Event

```text
event_scope
property_event_weight_profile
build_age_modifier
condition_modifier
feature_modifier
season_modifier
```

### Property Issue

```text
issue_type
severity_profile
repair_cost_profile
escalation_profile
batch_repair_enabled
```

### UI/공유

- 내 집 상태문구
- 관리 리포트 문구
- 컬렉션 획득 문구
- 대표집 설정 문구
- 주거 도감 배지/프레임

---

# 69. 코드/기획 규칙으로 고정할 것

다음은 일반 라이브 어드민에서 임의 변경하지 않는 구조다.

- current residence는 항상 1개
- 보유주택 수에 gameplay hard cap 없음
- 구매와 거주지 변경 분리
- 기존집 보유 시 미실현 예상 순자산을 새집 구매자금으로 사용하지 않음
- 이동가구 한 인스턴스는 한 위치에만 존재
- 보유주택별 Grid/인테리어/가구상태 동시보존
- 기존집 매도 시 이동가구 전량회수
- 기존집 보유 이사 시 선택한 가구만 이동
- 단순 방문은 current residence 변경 아님
- current residence에서만 통근/생활/Household Utility 적용
- V0.1 추가주택 현금구매
- V0.1 플레이어 전체 활성 HOME_LOAN 최대 1개
- V0.1 임대수익 없음
- V0.1 정기 다주택 보유세/고정관리비 없음
- 주거 도감은 한번 획득하면 영구
- 현재 내 집 컬렉션은 실제 소유기준
- 매도 시 최종 스냅샷/주거역사 보존
- 모든 보유주택은 PROPERTY_MAINTENANCE 이벤트 후보
- 보유주택 수 증가에 따라 Maintenance 기대발생량 실제 증가
- Property 이벤트 발생량을 글로벌 중요 CHOICE cap으로 제한하지 않음
- 같은 월 다수 Property 이벤트는 관리 리포트로 묶을 수 있음
- CURRENT_RESIDENCE 생활이벤트와 OWNED_PROPERTY Maintenance 이벤트 분리
- Property Issue는 linked_property_id 단위로 독립상태 유지
- 랜덤 Maintenance로 집/가구 영구손실 없음
- 오프라인에서도 모든 보유주택 Maintenance를 게임월별 순차처리

---

# 70. QA / 시뮬레이션

## 70.1 구매/거주

- 첫 자가 이후 다주택 선택이 정상 노출되는가
- 한남 도달이 다주택 필수조건으로 잘못 작동하지 않는가
- `사서 보유` 시 current residence가 바뀌지 않는가
- `사서 이사` 시 current residence가 정확히 하나만 남는가
- 기존집 보유에서 예상 매도 순자산을 신규구매 자금으로 잘못 사용하지 않는가

## 70.2 대출

- 플레이어 전체 HOME_LOAN이 2개 생성되지 않는가
- 주담대가 남은 과거집을 보유하면서 다른 집 현금구매가 가능한가
- 기존 HOME_LOAN 정산 후 새 HOME_LOAN 실행이 가능한가

## 70.3 가구/집상태

- 보유집 이사에서 선택하지 않은 가구가 기존집에 남는가
- 선택한 가구만 이동하는가
- 매도 시 이동가구가 전부 회수되는가
- 가구 한 인스턴스가 두 집에 중복배치되지 않는가
- 각 집을 재방문하면 마지막 배치/시공상태가 그대로인가

## 70.4 컬렉션

- 매도해도 주거 도감 기록이 남는가
- 현재 내 집 목록에서는 매도주택이 빠지는가
- 랜덤 개별 house_id가 100% 조건으로 잘못 들어가지 않는가
- 지역/주거유형/Feature/대표 평면 컬렉션이 정상 누적되는가
- 특별매물이 최고집 이후에도 탐색동기가 되는가

## 70.5 시장/매도

- 모든 보유주택 current_market_value가 월별 갱신되는가
- 단기매매가 지나치게 강한 수익전략이 되지 않는가
- 장기 첫 집 보유기록이 정상 유지되는가

## 70.6 Property Maintenance

보유규모:

```text
1 / 3 / 10 / 30 / 100 / 300채
```

각각 검증:

- 월 평균 신규 Maintenance 이벤트
- 월 평균 미해결 Issue
- 월 평균 수리비
- 처리 클릭 수
- 관리 리포트 가독성
- 현재 거주지 문제 우선표시
- 동일 집 동일 Issue 중복 방지
- 서로 다른 집의 동일 Issue 동시발생 허용
- 비거주집 문제가 생활스탯을 과도하게 깎지 않는지
- 방치해도 주택/가구 영구손실이 없는지
- 오프라인 3개월 순차처리와 온라인 결과가 동일한지
- 다주택 관리부담이 컬렉션 욕망을 꺾지 않는지

## 70.7 극장기

- 100채 이상 보유 UI가 사용 가능한가
- 300채 이상에서 저장/로드/월 경계 처리가 성능상 가능한가
- 관리리포트가 수십 건이어도 처리 가능한가
- 다주택이 커리어/부업/생활시스템을 무의미하게 만들지 않는가

---

# 71. 후속 확장

V0.1 다주택 이후에만 다음을 검토한다.

```text
SECOND_HOME_STAY
RENT_OUT
PROPERTY_MANAGER
MULTI_HOME_LOAN
HOLDING_COST
```

### SECOND_HOME_STAY
별장형 생활씬.

### RENT_OUT
임대수익.

### PROPERTY_MANAGER
경미한 Issue 자동관리 + 관리대행 비용.

### MULTI_HOME_LOAN
복수 투자주택 대출.

### HOLDING_COST
임대수익 도입 시 보유세/관리비/공실 등과 함께 설계.

첫 다주택 버전에는 포함하지 않는다.

---

# 72. V0.1 확정 정책

- 다주택의 1차 목적은 투자수익이 아니라 주거 컬렉션/복수 집꾸미기다.
- 한남 프리미엄은 엔딩이 아니라 1주택 progression의 milestone이다.
- 다주택 구조는 첫 자가 이후부터 가능하며 한남 도달을 hard gate로 사용하지 않는다.
- 기존집을 보유하면 예상 매도 순자산을 새집 구매자금으로 사용할 수 없다.
- 주택 구매와 current residence 변경을 분리한다.
- current residence는 항상 1개다.
- 추가 보유주택은 자유롭게 방문/꾸미기/Photo/매도할 수 있다.
- 단순 방문은 통근/생활/Household Utility를 변경하지 않는다.
- 보유한 다른 집으로 실제 거주지를 옮기는 것은 정식 이사로 처리한다.
- 보유주택 수 gameplay hard cap은 두지 않는다.
- 집별 Grid/인테리어/가구배치 상태를 동시에 보존한다.
- 이동가구 한 인스턴스는 한 위치에만 존재한다.
- 보관함은 전역 공용이다.
- 기존집 매도 시 이동가구는 전량회수한다.
- 기존집 보유 이사 시 기존집 가구는 유지하고 가져갈 가구만 선택한다.
- 추가주택 V0.1은 현금구매다.
- 플레이어 전체 활성 HOME_LOAN은 V0.1 최대 1개다.
- 기존 주담대집을 보유하면서 다른 집을 현금구매할 수 있다.
- 임대수익은 V0.1에 없다.
- 정기 다주택 보유세/고정관리비는 V0.1에 없다.
- 모든 보유주택 current_market_value는 플레이어 개인 시장지수에 따라 월별 갱신한다.
- 주거 도감과 현재 내 집 컬렉션을 분리한다.
- 주거 도감은 지역/주거유형/Feature/대표 평면 단위이며 한 번 획득하면 영구다.
- 컬렉션 보상은 큰 현금보다 배지/오브제/공유 프레임 등 비경제 보상이다.
- 매도 시 최종 스냅샷과 구매/매도/보유기록을 주거역사에 남긴다.
- FEATURED_PROPERTY는 소셜 표시용이며 생활효과는 없다.
- 모든 보유주택은 독립적인 PROPERTY_MAINTENANCE 이벤트 발생대상이다.
- 보유주택 수가 늘면 Maintenance 이벤트 기대발생량도 실제로 늘어난다.
- Property 이벤트 발생량은 글로벌 중요 CHOICE 월 cap과 별도로 처리한다.
- 같은 달 여러 Property 이벤트는 관리 리포트로 묶는다.
- OWNED_PROPERTY Maintenance와 CURRENT_RESIDENCE 생활형 주거이벤트를 구분한다.
- 동일 event_group 중복방지는 linked_property_id 단위로 적용한다.
- 비거주집 문제는 플레이어 스탯보다 해당 주택 상태/비용/사용제한에 영향을 준다.
- Property Issue는 주택별 독립적으로 미루기/악화/해결된다.
- 랜덤 Maintenance로 주택/가구를 영구손실시키지 않는다.
- 다주택 관리문제는 반복 클릭을 줄이기 위해 관리 리포트/일괄처리를 제공하는 방향을 사용한다.
- 오프라인에서도 모든 보유주택의 Maintenance를 게임월별 순차 처리하고 중요한 선택은 자동확정하지 않는다.
- 1/3/10/30/100/300채 보유규모를 기준으로 Maintenance 발생량과 비용을 반드시 시뮬레이션한다.
- 임대수익, 자동관리, 복수대출, 별장생활, 보유비용은 후속 확장이다.
