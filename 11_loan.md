# 11_loan.md
기준일: 2026-08-25
상태: V0.3 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 전세대출, 주택담보대출, 금리, 대출한도, 월 상환, 일부·전액 상환, 집 매도·갈아타기, 다주택 보유 시 대출 lifecycle과 현금 안전장치를 상세 정의한다.

대출의 핵심 역할:

> 대출은 미래의 가처분소득을 당겨 쓰는 수단이다.

대출 자체가 금융게임이 되지 않게 하되, 더 좋은 집에 조금 더 일찍 진입하고 이후 월 생활비와 자유소득의 trade-off를 체감하게 한다.

---

# 2. 핵심 원칙

- 기본 대출상품은 `JEONSE_LOAN`, `HOME_LOAN` 2종.
- 신용대출, 가구대출은 V0.1에 넣지 않음.
- 다주택 활성화 후에도 **플레이어 전체 활성 주거대출은 최대 1개**를 V0.1 원칙으로 사용.
- 전세대출은 계약 중 월 이자만 납부하고 계약 종료 시 보증금 반환액에서 원금 자동정산.
- 전세대출 원금 일부상환 없음.
- 주담대는 원리금균등상환.
- 주담대 기본 만기 30년 = 360개월.
- 기존대출 금리는 실행 시점에 고정.
- 신규대출 첫 자동상환은 실행 다음 게임월부터, 일할계산 없음.
- 대출 가능액은 주택가격 비율 + 상환능력 중 작은 값.
- `cash_balance`와 `spendable_cash`를 분리해 필수지출을 먼저 보호.
- 일반 소비/수동 대출상환은 `spendable_cash` 범위 안에서만 가능.
- 연체·파산·강제경매가 일반 플레이에서 생기지 않도록 사전검증.
- 실직은 기존 대출 즉시회수/강제매도로 이어지지 않음.
- HOME_LOAN 일부/전액상환 허용.
- 최소 일부상환액 기본값 1,000,000원.
- 일부상환 시 잔여만기 유지 + 월상환액 재계산.
- 중도상환수수료 V0.1 없음.
- 집 매도 시 해당 HOME_LOAN은 매도대금에서 자동정산.
- 대출 승계 없음.
- 다주택 V0.1의 추가주택은 현금구매이므로 복수 HOME_LOAN 없음.

---

# 3. 대출상품

## 3.1 JEONSE_LOAN

- 계약 중 월 이자만 납부
- 원금 일부상환 불가
- 계약 종료 시 반환보증금에서 원금 자동상환
- 잔여 보증금만 플레이어 현금 반환

## 3.2 HOME_LOAN

- 원리금균등상환
- 매월 원금 + 이자
- 일부/전액상환 가능
- 담보주택 매도 시 남은 원금 자동정산

---

# 4. JEONSE_LOAN 상세

예:

```text
전세보증금 200,000,000
내 현금      80,000,000
전세대출    120,000,000
```

계약 중:

```text
월 이자만 자동지출
```

계약 종료:

```text
전세보증금 반환      200,000,000
- 전세대출 원금      120,000,000
-------------------------------
플레이어 반환          80,000,000
```

실행 시점의 금리를 해당 loan instance에 고정한다.

```text
partial_repayment_enabled = false
```

전세대출은 계약 lifecycle과 한 세트로 움직인다.

---

# 5. HOME_LOAN 상세

## 5.1 상환방식

```text
repayment_type = EQUAL_TOTAL_PAYMENT
```

대출 실행 당시:

- 원금
- 금리
- 잔여만기

를 기준으로 월상환액을 계산한다.

초기에는 이자 비중이 높고 후기에는 원금 비중이 높다.

## 5.2 기본 만기

```text
default_term_months = 360
```

기존 60~120개월 단축안은 폐기한다.

30년 만기는 실제로 30년을 끝까지 버티게 하려는 목적이 아니라 월 부담을 현실적으로 만들어 자가 구매 후에도 가구/인테리어/생활 소비를 유지하기 위한 금융조건이다.

향후 20/30/40년 선택은 별도 검토.

## 5.3 금리

기존대출은 실행금리 고정.

시장금리 변화는 신규대출에만 적용 가능.

---

# 6. 활성 주거대출 개수

V0.3 핵심 정리:

```text
active_housing_loan_count <= 1 per player
```

즉 `현재 거주주택 기준 1개`가 아니라 **플레이어 전체 기준**이다.

가능 상태:

```text
월세 current residence
→ 활성 주거대출 0

전세 current residence
→ JEONSE_LOAN 최대 1

자가 1채 또는 다주택
→ HOME_LOAN 최대 1
```

다주택 예:

```text
서대문 집
HOME_LOAN ACTIVE

성동 집
현금구매

한남 집
현금구매
```

가능.

반대로 기존 HOME_LOAN이 ACTIVE인데 새 주택에 또 HOME_LOAN을 실행하는 것은 불가.

새 HOME_LOAN이 필요하면:

- 기존 HOME_LOAN 전액상환
- 또는 해당 담보주택 매도 후 자동정산

으로 기존 활성대출을 먼저 종료한다.

복수 HOME_LOAN은 `16_multi_property.md`의 후속 확장이다.

---

# 7. 담보주택과 Current Residence는 동일하지 않을 수 있음

다주택 이후 HOME_LOAN이 연결된 집이 current residence가 아닐 수 있다.

예:

```text
서대문 첫 자가
- HOME_LOAN ACTIVE
- OWNED_PROPERTY
- current residence = false

성동 집
- 현금구매
- current residence = true
```

이 경우:

- 기존 HOME_LOAN은 계속 정상상환
- current residence 변경만으로 대출 종료/이전 안 됨
- 담보주택 매도 시에만 해당 대출 자동정산

즉 `linked_house_id`가 대출 lifecycle의 기준이며 current residence 여부와 분리한다.

---

# 8. 총 현금 / 사용 가능 현금

```text
cash_balance
= 실제 보유현금
```

```text
reserved_mandatory_expenses
= 다음 월세 + 관리비 + 기본 생활비 + Household 추가생활비 + 보험/고정비 + 기존 대출상환 + 확정 필수지출
```

```text
spendable_cash
= max(0, cash_balance - reserved_mandatory_expenses)
```

가구, 인테리어, 투자, 추가주택 현금구매, 수동 HOME_LOAN 상환 등은 `spendable_cash` 안에서만 가능하다.

다주택 Maintenance 수리비도 플레이어가 선택하는 수동지출이면 동일 안전정책을 사용한다.

---

# 9. 필수지출 예약 갱신

주요 시점:

- 게임월 시작
- 계약/이사 확정
- 대출 실행
- HOME_LOAN 일부/전액상환
- Household State 변경
- 월세/관리비 변경
- 이직/소득조건 변경
- 확정 필수지출 이벤트

HOME_LOAN이 비거주 보유집에 연결되어 있어도 월상환은 mandatory expense에 포함한다.

---

# 10. 대출한도

```text
maximum_loan
= min(property_based_limit, affordability_based_limit)
```

## 10.1 주택가격 기반

대상주택 가격/계약유형/상품에 따라 계산.

## 10.2 상환능력 기반

```text
정기소득
- 기본 생활비
- current residence 주거비
- Household 생활비
- 기존 활성 대출상환
- 신규 예상 대출상환
= 대출 후 자유소득
```

이 값이 minimum free income/safety buffer를 만족해야 한다.

PARTNER household contribution은 13에서 정의한 인정비율만 반영한다.

---

# 11. 대출액 선택 UX

최대대출 자동실행 없음.

플레이어가 허용범위 내에서 대출액 선택.

즉시 갱신:

- 계약 후 현금
- 월상환/월이자
- 예상 월 자유소득

대출을 더 받으면 현금은 남지만 월부담이 커지는 trade-off를 보여준다.

---

# 12. 계약 후 잔여현금

절대 최소현금 보유액을 강제하지 않는다.

이미:

- mandatory expense reservation
- affordability limit
- minimum free income

안전장치가 있기 때문이다.

낮은 잔여현금은 경고만 한다.

---

# 13. 이직과 기존 대출

이직 실행 전 기존 활성 대출을 포함해 affordability 재검사.

연봉 감소만으로 금지하지 않는다.

상환 후 생활안전선을 만족하면 허용.

불가능하면:

```text
대출 일부상환 또는 주거비 조정이 필요해요.
```

등 안내.

다주택의 비거주 담보주택 대출도 이직 검사에서 반드시 포함한다.

---

# 14. 연체/파산 사전방지

V0.1 미사용:

- 연체
- 신용등급
- 압류
- 강제경매
- 파산

사전방지 지점:

```text
대출 실행
→ affordability

소비/추가주택 구매
→ spendable_cash

이직
→ 기존대출 포함 affordability
```

---

# 15. 실직과 기존 대출

- 기존 대출 유지
- 월상환 계속
- 신규대출 제한 가능
- 즉시 강제매도/압류 없음

다주택 보유중이라도 실직만으로 보유주택 강제처분을 하지 않는다.

---

# 16. HOME_LOAN 일부상환/전액상환

## 일부상환

```text
minimum_partial_repayment_amount = 1,000,000
```

흐름:

```text
상환액 입력
→ spendable_cash 검사
→ 현금 감소
→ remaining_principal 감소
→ 잔여만기 유지
→ monthly_payment 재계산
→ reserved_mandatory_expenses 갱신
```

## 전액상환

남은 원금 전액 상환 후:

- `PAID_OFF`
- 다음 월상환 예약 제거

중도상환수수료 V0.1 = 0.

---

# 17. 부업수입과 대출

부업수입은 일반 현금.

따라서 HOME_LOAN 일부/전액상환에 사용 가능.

금지:

```text
광고 시청
→ 대출잔액 직접 감소
```

JEONSE_LOAN 중간 원금상환은 여전히 불가.

---

# 18. 전세 → 자가

예상 순보증금:

```text
반환 예정 전세보증금
- 남은 JEONSE_LOAN 원금
- 확정 종료비용
= 예상 순보증금
```

신규 자가 자금계획에 선반영 가능.

실행순서:

```text
새 자가 선택
→ 순보증금 계산
→ 신규 HOME_LOAN 필요액/affordability
→ 최종확정
→ 기존 전세계약 종료
→ JEONSE_LOAN 정산/종료
→ HOME_LOAN 실행
→ 입주
```

---

# 19. 자가 매도와 HOME_LOAN

담보주택을 매도하면:

```text
매도가
- 남은 HOME_LOAN 원금
- 매도비용
= 실제 회수현금
```

순서:

1. 매도가 확정
2. linked HOME_LOAN 확인
3. 비용 차감
4. 원금 자동상환
5. 대출 `SETTLED_ON_SALE`
6. 잔여현금 반영

current residence인지 여부와 무관하게 **담보주택 매도**가 정산 trigger다.

---

# 20. 일반 자가→자가 갈아타기

기존집을 매도하는 경우:

```text
기존집 예상 순자산
= 예상 매도가 - HOME_LOAN 잔액 - 매도비용
```

을 새집 구매계획에 선반영한다.

실제 실행 시 기존집 매도 → 기존대출 정산 → 새 HOME_LOAN 실행.

---

# 21. 다주택: 기존집 보유 + 새집 구매

`16_multi_property.md` 기준:

기존집을 보유하면:

```text
기존집 예상 순자산
→ 신규 구매자금에 선반영 금지
```

추가주택 V0.1은 현금구매다.

예:

```text
기존 HOME_LOAN 담보집 보유
+ 새집 현금구매
```

가능.

반대로 새집에도 HOME_LOAN이 필요하면 기존 활성 HOME_LOAN을 먼저 종료해야 한다.

---

# 22. 다주택: current residence 변경

대출이 걸린 집에서 다른 보유집으로 current residence를 바꾼다고 기존 HOME_LOAN을 자동상환하지 않는다.

대출은 `linked_house_id`에 남는다.

이후 해당 담보집을 매도하거나 전액상환할 때 종료한다.

---

# 23. 순주택자산

개별 담보집:

```text
property_net_equity
= current_market_value - linked_HOME_LOAN_remaining_principal
```

대출 없는 집:

```text
property_net_equity = current_market_value
```

다주택 총 주택순자산:

```text
total_home_equity
= Σ 각 OWNED_PROPERTY의 property_net_equity
```

단 신규주택 구매자금으로 사용할 수 있는 현금과 총 주택순자산은 다르다.

미매도 주택 순자산을 `spendable_cash`처럼 사용하지 않는다.

---

# 24. 월 정산 / 첫 상환

신규대출 실행월에는 신규대출 자동상환 없음.

```text
first_payment_game_month
= started_game_month + 1
```

JEONSE_LOAN: 다음월부터 이자.

HOME_LOAN: 다음월부터 원리금.

오프라인 월경계에서도 기존 활성대출 상환 정상처리.

새 대출 실행은 자동하지 않는다.

---

# 25. 대출 UI

핵심 표시:

- 집값
- 보유현금
- 사용 가능 현금
- 전세 예상 순보증금
- `매도하는` 기존집의 예상 순자산
- 플레이어 소득
- 인정 Household contribution
- 기존 활성대출 월부담
- 신규 대출액
- 계약 후 현금
- 월상환/월이자
- 예상 자유소득
- 기간/금리
- 첫 상환월

다주택 보유 선택에서는 `기존집 순자산은 현재 자산이지만 이번 구매자금으로 사용할 수 없음`을 명확히 표시한다.

---

# 26. 신규대출 실행조건

- 상품 활성
- 대상 계약유형
- 플레이어 전체 활성 주거대출 수
- 기존대출 종료/정산 가능 여부
- property limit
- affordability limit
- minimum free income
- 재직/소득 상태
- 신규대출 제한상태
- 필요한 자기자본

자동실행 금지.

---

# 27. Lifecycle

## JEONSE_LOAN

```text
전세 선택
→ 자격/한도
→ 대출액 선택
→ 계약
→ 다음월부터 이자
→ 계약 중 일부상환 없음
→ 계약종료 보증금에서 원금정산
→ 종료
```

## HOME_LOAN

```text
자가 선택
→ 플레이어 전체 활성대출 확인
→ 자격/한도
→ 대출액 선택
→ 실행
→ 다음월부터 원리금
→ 일부/전액상환 가능
→ 담보집 매도 또는 전액상환
→ 종료
```

---

# 28. 대출 상태

```text
ACTIVE
PAID_OFF
SETTLED_ON_CONTRACT_END
SETTLED_ON_SALE
```

미사용:

```text
OVERDUE
DEFAULT
FORECLOSURE
BANKRUPTCY
```

---

# 29. player_loan 데이터

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

종료된 대출도 기록 삭제하지 않는다.

---

# 30. 코드/엔진 영역

- 원리금균등 월상환 계산
- 전세대출 월이자
- 첫 상환월
- `spendable_cash`
- mandatory expense reservation
- property limit
- affordability limit
- 최종 min 한도
- 플레이어 전체 활성 주거대출 최대 1개 상태관리
- 전세종료 정산
- 전세→자가 순보증금 처리
- 담보집 매도 시 HOME_LOAN 정산
- 일반 갈아타기 예상 순자산/정산
- 다주택 보유선택에서 미실현 순자산 제외
- 일부/전액상환
- 이직 affordability
- 개별 property net equity / total home equity
- 대출상태 lifecycle

---

# 31. 어드민 관리대상

`15_admin.md`가 Source of Truth.

- 상품
- 신규금리
- 주담대 기간
- 한도비율
- affordability threshold
- minimum free income/safety buffer
- Household contribution 인정률
- mandatory expense 설정
- 낮은 잔여현금 경고
- 재직/소득조건
- 일부/전액상환 활성
- 최소 일부상환액
- 수수료
- 첫 상환 오프셋

`active_housing_loan_count <= 1 per player`와 다주택 V0.1 추가주택 현금구매는 구조정책으로 둔다.

---

# 32. QA

1. 원리금균등 계산이 정확한가.
2. 실행 다음월부터 첫 상환인가.
3. JEONSE_LOAN 일부상환이 없는가.
4. 전세종료 자동정산이 정확한가.
5. HOME_LOAN 일부상환 후 잔여만기 유지/월상환 감소인가.
6. 예약 필수지출이 즉시 갱신되는가.
7. 플레이어 전체에 활성 주거대출 2개가 생성되지 않는가.
8. HOME_LOAN 담보집이 비거주집이 되어도 상환이 유지되는가.
9. 담보집 매도 시 current residence 여부와 무관하게 대출이 정산되는가.
10. 대출 있는 과거집을 보유하고 새집 현금구매가 가능한가.
11. 기존 HOME_LOAN이 있는데 신규 HOME_LOAN을 추가로 실행할 수 없는가.
12. 기존대출 전액상환/매도 후 신규 HOME_LOAN 실행 가능한가.
13. 기존집 보유선택에서 예상 순자산을 새집 자금으로 잘못 사용하지 않는가.
14. 다주택 total home equity와 spendable_cash가 명확히 분리되는가.
15. 이직 affordability에 비거주 담보집 대출도 포함되는가.
16. 실직 시 강제매도/즉시회수가 없는가.
17. 오프라인 상환결과가 온라인과 동일한가.
18. 부업수입으로 HOME_LOAN 수동상환 가능하되 광고가 직접 잔액을 줄이지 않는가.

---

# 33. V0.3 확정 정책

- 대출은 미래의 가처분소득을 당겨 쓰는 수단이다.
- 기본 상품은 JEONSE_LOAN / HOME_LOAN 2종이다.
- **플레이어 전체 활성 주거대출은 V0.1 최대 1개다.**
- 다주택의 비거주 담보집에도 기존 HOME_LOAN을 유지할 수 있다.
- current residence 변경만으로 대출을 종료/이전하지 않는다.
- 담보주택 매도 또는 전액상환이 HOME_LOAN 종료 trigger다.
- 추가주택 V0.1은 현금구매이며 복수 HOME_LOAN은 후속확장이다.
- 전세대출은 월이자 + 계약종료 원금정산이며 일부상환하지 않는다.
- HOME_LOAN은 원리금균등, 기본 360개월이다.
- 신규대출 첫 상환은 실행 다음 게임월이다.
- 기존금리는 실행시점에 고정한다.
- cash_balance / spendable_cash를 분리한다.
- 필수지출을 소비 전에 예약한다.
- 대출한도는 property + affordability 모두 충족해야 한다.
- 이직은 기존 활성대출까지 포함해 상환가능성을 검사한다.
- 연체/파산/강제경매를 일반 플레이에 만들지 않는다.
- 실직 시 기존대출 즉시회수/강제매도 없다.
- HOME_LOAN 일부/전액상환 허용, 최소 일부상환 기본 100만원, 중도상환수수료 없음.
- 기존집을 매도하는 갈아타기에서는 예상 순자산을 선반영할 수 있다.
- 기존집을 보유하는 다주택 구매에서는 미실현 예상 순자산을 새집 구매자금으로 사용할 수 없다.
- 개별 property net equity와 total home equity를 계산하되 현금구매력과 분리한다.
- 부업수입은 일반현금이므로 HOME_LOAN 상환에 사용 가능하지만 광고가 잔액을 직접 줄이지 않는다.
