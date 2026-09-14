# 01_economy_balance.md
기준일: 2026-08-25
상태: V0.2 상세기획 확정

## 0. 목적

이 문서는 `방 한 칸에서 한남동까지`의 경제 밸런스 원칙을 정의한다.

핵심 목표:

1. 월급을 받아도 많이 남지 않는 현실감
2. 사고 싶은 가구/집에 항상 조금 부족한 상태
3. 기다리기와 부업 사이 선택
4. 광고사용자가 더 빠르지만 무광고도 정상 진행
5. 첫 전세/자가/프리미엄까지 장기 목표 유지
6. 수백 게임년 이후에도 집값과 소득 규모가 완전히 분리되지 않는 장기 경제

---

# 1. 핵심 경제 루프

```text
월급/정기수입
→ 필수지출 예약/자동지출
→ 사용 가능 현금
→ 가구/인테리어/주거 욕망
→ 부족액
→ 기다리기 또는 부업
→ 구매/저축
→ 다음 월
```

다주택 이후:

```text
기존 성장
→ 추가주택 현금구매
→ 집꾸미기/컬렉션
→ Property Maintenance 수리비
→ 다시 경제루프
```

다주택 V0.1은 임대수익 자기증식 루프를 만들지 않는다.

---

# 2. 통화

별도 광고재화 없음.

```text
월급
부업
보너스
기타수입
→ cash_balance
```

모두 같은 일반 게임머니.

---

# 3. 보유현금 / 사용 가능 현금

```text
cash_balance
= 실제 보유현금
```

```text
reserved_mandatory_expenses
= 다음 필수 자동지출 예약
```

```text
spendable_cash
= max(0, cash_balance - reserved_mandatory_expenses)
```

수동지출:

- 가구
- 인테리어
- 투자
- 추가주택 현금구매
- HOME_LOAN 수동상환
- Property 수리비 선택지

등은 `spendable_cash` 범위 안에서만 가능.

---

# 4. 필수지출 예약

후보:

- 월세
- 관리비
- 기본 생활비
- Household State 추가생활비
- 보험/기타 고정비
- 전세대출 이자
- HOME_LOAN 월상환
- 이미 확정된 필수 자동지출

다주택 비거주 담보집의 HOME_LOAN도 포함한다.

V0.1 다주택 추가주택에는 고정 보유세/정기관리비를 별도 곱하지 않는다.

Maintenance는 변동형 관리비용 역할.

---

# 5. 월 정산 목표

초기:

- 정기지출: 월급 약 65~80%
- 가처분소득: 약 20~35%

예:

```text
월급 300만
월세 80
관리비 15
생활비 110
기타 20
→ 잔여 75
```

정확값은 직장/집/Household 조합 시뮬레이션으로 결정.

---

# 6. 생활비

실제 식사/교통/통신을 매번 결제시키지 않는다.

월 정산으로 압축한다.

소득/주거단계가 오르면 생활비도 완만히 증가하는 라이프스타일 인플레이션을 사용한다.

PARTNER/FAMILY는 13의 living_cost_modifier를 사용.

---

# 7. 가처분소득이 핵심 밸런스 단위

월급 자체보다:

```text
월 정기수입
- 필수지출
= 월 자유소득
```

을 본다.

가구가격, 부업보상, 이벤트 비용, 대출 affordability를 이 값과 비교한다.

---

# 8. 가구 가격밴드

- 소품: 월 가처분소득 약 5~20%
- 일반가구: 약 30~100%
- 욕망가구: 약 1~3개월 가처분소득
- 프리미엄: 여러 달 저축/부업

핵심:

> 조금 기다리면 살 수 있지만 지금 갖고 싶다.

---

# 9. 인테리어 / 주거 비용

가구보다 큰 Sink:

- 부분시공
- 욕실/주방
- 전체 인테리어
- 이사
- 보증금/전세
- 첫 자가
- 주담대
- 추가주택
- Property Maintenance

시공비를 집값에 직접 가산하지 않는다.

---

# 10. 부업 경제

`08_ads_sidejob.md` 기준.

- 1회 = 예상 월 가처분소득 약 15~20%
- 기본 테스트 20%
- 일반 약 5회/게임월
- 적극 부업 사용자 성장속도 목표 무광고 대비 약 1.7~2.2배

부족액이 없어도 잔여횟수 내 상시 가능.

오프라인 자동실행 없음.

---

# 11. 무광고 / 적극부업 비교

무광고도:

- 가구
- 전세
- 첫 자가
- 프리미엄

까지 도달 가능해야 한다.

부업은 시간을 줄이는 선택.

`광고 없이는 진행불가` 구조 금지.

---

# 12. 이벤트 비용

글로벌 RANDOM 참고범위:

- 소형: 가처분소득 5~20%
- 중형: 20~50%
- 큰 이벤트: 50~100%, 낮은 빈도

Property Maintenance는 `한 건 크기`뿐 아니라 보유주택 수에 따른 월 총 기대수리비를 별도 검증한다.

1/3/10/30/100/300채 기준 QA.

---

# 13. 대출

대출은 미래 가처분소득을 당겨 쓰는 수단.

한도:

```text
min(property_based_limit, affordability_based_limit)
```

V0.1 플레이어 전체 활성 주거대출 최대 1개.

대출 후 최소 자유소득 안전선을 유지.

연체/경매/파산을 일반 플레이에 만들지 않는다.

---

# 14. 첫 자가 이후 자산

1주택:

```text
cash
+ current home net equity
```

다주택:

```text
cash
+ Σ property_net_equity
= 전체 자산의 주요부분
```

하지만:

```text
total_home_equity != spendable_cash
```

미매도 집의 자산가치를 신규구매 현금처럼 쓰지 않는다.

---

# 15. 다주택 V0.1 경제

`16_multi_property.md` 기준:

- 추가주택 현금구매
- 임대수익 없음
- 복수 HOME_LOAN 없음
- 정기 다주택 보유세/고정관리비 없음
- Maintenance가 변동형 관리비용

목적:

> 충분히 성장한 플레이어가 돈을 쓸 장기 주거/컬렉션 Sink를 만든다.

집→임대료→집의 자기증식 루프는 후속으로 미룬다.

---

# 16. 장기 부동산 우상향과 명목경제

`12_market_price.md`는 수백 게임년 동안 주택가격에 Hard Cap을 두지 않는다.

따라서 초기 월급표/생활비/가구가격이 영구 고정이면 극장기 경제가 깨진다.

장기 원칙:

> 게임의 주요 명목금액은 장기적으로 동일한 경제규모 안에서 조정될 수 있어야 한다.

최소 연결:

- 회사 base salary × `long_term_nominal_income_index`
- 이직 offer salary도 같은 시점 index 사용
- 필요시 기본 생활비/이벤트 비용/가구·시공 신규콘텐츠 가격 기준도 장기 경제규모와 정합성을 맞춤
- PARTNER contribution도 장기 경제와 괴리되지 않게 조정

중요:

- 모든 가격을 똑같은 index로 기계적으로 올릴 필요는 없다.
- 주택 Market Cycle과 salary index를 동일비율로 만들 필요도 없다.
- 플레이어가 인플레이션 트레이딩을 하는 경제게임이 목적이 아니다.
- 기존에 이미 구매한 가구가격을 매달 재평가할 필요는 없다.

---

# 17. Long-term Nominal Economy Index

개념 후보:

```text
long_term_nominal_income_index
long_term_living_cost_index
```

가장 먼저 필요한 것은 income index다.

정확히 확정하지 않은 것:

- 시작 game month
- update interval
- growth rate
- 생활비/콘텐츠 가격 연동비율

이 값은 다음 시뮬레이션에서 결정한다.

```text
50년
100년
300년
500년
```

검증해야 할 것:

- 주택 가격 대비 소득
- 가처분소득
- 추가주택 구매속도
- Maintenance 감당가능성
- 가구/시공 비용의 체감

---

# 18. 장기 Index와 커리어 레벨 분리

`03_career.md` 기준:

```text
career_level = 1~5
```

유지.

Lv5 이후 숫자 직급을 무한히 추가하지 않는다.

장기 명목소득 조정은:

- 승진 아님
- career XP 보상 아님
- 업무강도 자동변경 아님

단순 장기 경제규모 보정.

---

# 19. 시작자금

현재 가안:

```text
25,000,000원
```

첫 직장과 무관하게 동일 시작.

Starting Market Snapshot이 바뀌면 첫 월세 선택가능성도 함께 QA해야 한다.

---

# 20. 목표시간

가안:

- 첫 욕망가구 20~40분
- 첫 방 만족 1~2시간
- 첫 이사 4~8시간
- 첫 전세 10~20시간
- 첫 자가 20~40시간
- 중형 아파트 50~100시간
- 프리미엄 장기
- 다주택/서울 주거도감 극장기

---

# 21. 필수 시뮬레이션

플레이 유형:

```text
NO_AD
AVERAGE_SIDEJOB
ACTIVE_SIDEJOB
```

기간:

- 첫 24개월
- 5년
- 첫 자가
- 프리미엄 도달
- 50년
- 100년
- 300년

각각:

- cash
- spendable_cash
- income
- living cost
- debt
- home equity
- total home equity
- property count
- Maintenance cost
- collection progress

추적.

---

# 22. 밸런스 실패 기준

- 필수지출 후 수개월 아무것도 못 삼
- 부업 없이는 정상 progression 불가
- 부업 몇 번으로 집을 즉시 구매
- PARTNER가 경제적 필수선택
- 첫 자가 후 가구/시공 소비 중단
- 다주택 임대수익 때문에 커리어 무의미
- Maintenance가 집을 더 사지 말라는 벌칙으로 느낌
- 수백년 뒤 집값만 성장하고 소득은 고정
- 반대로 장기소득이 집값보다 너무 빨리 올라 모든 집을 즉시 구매

---

# 23. 어드민

주요:

```text
starting_cash
living_cost_profiles
lifestyle_inflation
mandatory_expense_profiles
price_tier_ratios
sidejob_reward_ratio
sidejob_count_profiles
property_repair_cost_profiles
long_term_nominal_income_enabled
long_term_nominal_income_start_month
long_term_nominal_income_update_interval_months
long_term_nominal_income_growth_rate
```

장기 수치는 통합시뮬레이션 후 확정.

---

# 24. V0.2 확정 정책

- 경제의 핵심은 월급→필수지출→가처분→소비/저축이다.
- cash_balance와 spendable_cash를 분리한다.
- 모든 수동구매는 spendable_cash 기준이다.
- 정기지출 목표는 초기 월급의 약65~80%, 가처분20~35%다.
- 가구가격은 가처분소득 대비 욕망단계로 설계한다.
- 부업은 일반게임머니이며 상시 선택 가능하다.
- 무광고도 정상진행 가능하고 부업은 속도 가속수단이다.
- 생활수준이 오르면 비용도 증가한다.
- 대출은 미래 가처분소득을 당겨 쓰며 affordability 안전선을 사용한다.
- total_home_equity와 spendable_cash를 분리한다.
- 다주택 V0.1 추가주택은 현금구매이며 임대수익/복수주담대/고정보유세는 없다.
- 다주택 Maintenance는 보유수에 따라 증가하는 변동형 경제 Sink다.
- **수백 게임년 장기 플레이를 위해 명목소득을 영구고정하지 않는다.**
- long_term_nominal_income_index를 사용해 career salary/offer의 장기규모를 조정하는 원칙을 사용한다.
- exact 장기 index 값은 50/100/300/500년 통합시뮬레이션 후 확정한다.
