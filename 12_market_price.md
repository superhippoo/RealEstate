# 12_market_price.md
기준일: 2026-08-25
상태: V0.2 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 부동산 시작 시세, 게임시간 내 장기 시장변동, 매물 가격 고정, 모든 보유주택 평가, 계약 갱신, 장기 시세 기록 정책을 상세 정의한다.

정적 가격구조의 기준은 `02_real_estate.md`를 따른다.

핵심 질문:

1. 현실의 특정 시점에 새로 게임을 시작한 플레이어에게 어느 가격 수준의 서울을 보여줄 것인가?
2. 게임 시작 뒤 수십·수백 게임년 동안 그 가격은 어떻게 변화하는가?
3. 다주택 이후 여러 보유주택의 현재가치와 장기기록을 어떻게 일관되게 평가하는가?

핵심 원칙:

> 현실의 서울 가격에서 시작하되, 게임 시작 이후에는 플레이어의 게임시간을 따라 하나의 장기 서울 부동산 역사가 만들어진다.

---

# 2. 시장 시스템 목적

- 시간이 흐르며 서울 집값이 변한다는 감각
- 무주택자의 목표주택 긴장감
- 첫 자가 이후 `내 집 + 다음 집`이 함께 움직이는 감각
- 주담대 원금감소 + 시세변화를 순주택자산으로 연결
- 다주택 이후 모든 보유주택의 장기 자산기록
- 수십·수백 게임년의 높은 명목가격 자체를 개인역사/공유콘텐츠로 활용

부동산 투자게임이 아니라 주거 성장과 개인 서울역사를 만드는 시스템이다.

---

# 3. 두 개의 시간축

## 현실시간

신규게임의 시작시세만 결정.

> 지금 새로 시작하는 플레이어에게 어느 가격 수준의 서울을 보여줄 것인가?

기존 유저 시세를 현실날짜로 일괄변경하지 않는다.

## 플레이어 게임시간

게임 시작 이후:

```text
elapsed_game_month
```

기준으로 시장이 진행한다.

`04_time_contract.md` 공통 게임시계 사용.

---

# 4. Starting Market Snapshot

예:

```text
START_MARKET_2026_Q3
START_MARKET_2026_Q4
START_MARKET_2027_Q1
```

게임 시작 시 활성 Snapshot을:

```text
start_market_snapshot_id
```

로 저장.

새 Snapshot이 Publish되어도 기존 플레이어 세계는 재기준화하지 않는다.

---

# 5. Snapshot 가격관리 단위

```text
region_id
× contract_type
× market_type
→ base_unit_price
```

계약:

```text
RENT / JEONSE / SALE
```

시장유형:

```text
MULTIFAMILY / OFFICETEL / APARTMENT
```

원룸/투룸/옥탑 등 layout은 02의 market_type/layout_type 분리를 따른다.

---

# 6. 02와 Snapshot 역할분리

02:
- 지역 상대가격
- 시장유형 상대가격
- 면적
- 연식
- Feature
- 기타 정적구조

12 Snapshot:
- 현실 현재시점을 참고한 신규게임 절대 시작가격

개념:

```text
Snapshot 기준단가
× 02 면적/연식/Feature/기타 보정
× 게임 시작 후 누적 시장변동
```

동일 보정을 중복적용하지 않는다.

---

# 7. Snapshot 운영

기본 추천: 분기 1회 검토/발행.

```text
현실자료 검토
→ 게임용 기준단가 산출
→ progression 압축
→ 이전 Snapshot 비교
→ 운영자 승인
→ Publish
```

자동 실시간 API 반영 없음.

현실가격 변동이 커도 게임경제를 위해 압축 가능.

---

# 8. 신규 Snapshot은 신규게임에만 적용

예:

```text
2026 Q3 시작 A
→ START_MARKET_2026_Q3 유지

2027 Q3 시작 B
→ START_MARKET_2027_Q3
```

A 세계는 이후 자신의 게임시간 시장곡선을 계속 따른다.

---

# 9. 게임 내부 시장은 고정 Cycle

MVP/V0.1:

```text
STABLE
RISING
FALLING
```

없음:

- 유저별 Seed
- Regime 랜덤추첨
- 서버 현실시간 Regime
- 어드민 즉시 시장방향 조작

같은 elapsed_game_month면 같은 시장국면.

시작 Snapshot이 다르면 절대가격은 다를 수 있다.

---

# 10. 36개월 Market Cycle

| Cycle Month | 국면 |
|---|---|
| 0~5 | STABLE |
| 6~13 | RISING |
| 14~19 | STABLE |
| 20~25 | FALLING |
| 26~29 | STABLE |
| 30~35 | RISING |

```text
market_cycle_month = elapsed_game_month % 36
```

36개월 이후 패턴만 반복한다.

---

# 11. 누적시세는 초기화하지 않음

금지:

```text
100 → Cycle → 100
```

실제:

```text
100
→ 1 Cycle 104
→ 2 Cycle 108.x
→ 3 Cycle 112.x
→ ...
```

현재가격 위에 계속 복리 누적.

---

# 12. 각 Cycle 최종변화는 양수

FALLING 구간에서는 실제 하락.

하지만:

```text
cycle_end_market_index > cycle_start_market_index
```

초기 시뮬레이션 목표:

```text
36개월 순 누적 +3~5%
```

정확한 값은 통합 경제시뮬레이션.

---

# 13. 장기 완만한 우상향

단기:
- 상승
- 정체
- 하락

장기:
- 완만한 복리 우상향

하락장은 있지만 원점복귀 시장은 사용하지 않는다.

---

# 14. 장기 집값 Hard Cap 없음

생물학적 사망/강제엔딩 없음.

50/100/300/500년 플레이 가능.

수십억·수백억·그 이상의 명목가격은 정상적인 장기 플레이 결과다.

---

# 15. 월간 급등락 없음

SALE 초기 테스트 예:

```text
STABLE  +0.05% / 월
RISING  +0.30% / 월
FALLING -0.25% / 월
```

확정 최종값은 아님.

한 달 +10~20%, -30% 같은 급변은 사용하지 않는다.

---

# 16. 랜덤 Noise 없음

같은 국면 안에서 월별 랜덤변동을 추가하지 않는다.

목적:
- QA 재현
- 경제 시뮬레이션 안정
- 유저별 시장운 제거
- 투자타이밍게임화 방지

---

# 17. SALE / JEONSE / RENT 분리

국면은 공통, 월변동률은 계약유형별 별도.

예:

```text
RISING
SALE    +0.30%
JEONSE  +0.18%
RENT    +0.08%
```

정확값은 통합 시뮬레이션.

---

# 18. 지역별 독립시장 없음 V0.1

금지:

```text
강남 RISING
마포 FALLING
```

또한 고가지역의 영구 성장률 우위도 두지 않는다.

지역가격 차이는 02 정적구조에서 만든다.

다주택 이후에도 특정 지역 수익률 때문에 반복매수하는 전략을 만들지 않는다.

---

# 19. REGION 이벤트 시세 직접효과 없음

`10_events.md`의 공원/교통/상권/공사 등 REGION 이벤트는 V0.1에서 시세를 직접 바꾸지 않는다.

생활환경/행복/스트레스/생활씬 등에 영향 가능.

시장가격 Source of Truth는 고정 Cycle.

---

# 20. 신규 매물 가격

```text
listing_price
= property_base_price_from_02_and_snapshot
× cumulative_game_market_index
```

SALE / JEONSE / RENT 각각 해당 index 사용.

---

# 21. 생성된 매물 가격 LOCK

매물 생존기간 동안 제시가격 고정.

```text
Month 10: 4억 생성
Month 11: 시장 상승
→ 기존 매물 4억 유지
→ 신규 매물 새 시세 적용
```

일반/추천/특별 모두 동일.

---

# 22. 임대계약 가격은 계약중 고정

월세/전세는 계약체결 당시 가격 유지.

시장변화는:
- 신규 매물
- 갱신계약

에 적용.

---

# 23. 계약 갱신

24개월 종료 시 현재 RENT/JEONSE 시세를 기준으로 새 조건 산출.

필요시:

```text
renewal_increase_cap
renewal_decrease_cap
```

사용.

---

# 24. 모든 보유주택 시세를 매 게임월 갱신

다주택 이후 모든:

```text
OWNED_PROPERTY
```

의:

```text
current_market_value
```

를 게임월 경계마다 갱신한다.

매물처럼 LOCK하지 않는다.

각 property 최소 보존:

```text
purchase_price
purchase_game_month
current_market_value
```

구입가는 영구 보존.

보유주택 수가 많아도 동일 플레이어의 SALE market index를 사용한다.

---

# 25. 다주택의 시장평가 원칙

예:

```text
서대문 첫 자가
성동 한강뷰
마포 테라스집
한남 current residence
```

모두 같은 플레이어의 개인 서울시장 Cycle을 공유한다.

각 집의 절대가 차이는 02 정적 가격구조로 결정된다.

다주택을 샀다고 개인 시장상승률이 커지지 않는다.

---

# 26. 개별 Property Net Equity

`11_loan.md`와 연결.

대출 있는 집:

```text
property_net_equity
= current_market_value - linked_HOME_LOAN_remaining_principal
```

대출 없는 집:

```text
property_net_equity = current_market_value
```

---

# 27. Total Home Equity

다주택:

```text
total_home_equity
= Σ owned properties' property_net_equity
```

중요:

> total_home_equity는 보유자산 가치이지 즉시 구매에 쓸 수 있는 현금이 아니다.

미매도 주택의 순자산을 `spendable_cash`처럼 사용하지 않는다.

`16_multi_property.md`의 기존집 보유 선택에서는 예상 매도순자산을 신규집 구매자금에 선반영하지 않는다.

---

# 28. 무주택 / 1주택 / 다주택 시장체감

## 무주택

목표집 가격이 움직임.

## 1주택

```text
다음 집 가격
+ 현재 내 집 가격
```

동시 변동.

## 다주택

모든 보유집 현재가치가 같이 시장을 따라 움직이지만, 이는 투자수익 극대화를 메인루프로 만들기 위함이 아니라 장기 주거역사를 반영하기 위함이다.

---

# 29. 기존집 매도 갈아타기

```text
현재시세
- 남은 HOME_LOAN
- 예상 매도비용
= 예상 순자산
```

매도하기로 한 집의 예상 순자산만 새집 자금계획에 선반영 가능.

---

# 30. 기존집 보유 구매

다주택 선택:

```text
기존집 current_market_value / net_equity
→ 자산 UI에는 표시
→ 신규집 구매자금에는 미반영
```

새집 V0.1 추가주택 구매는 spendable_cash 현금구매를 따른다.

---

# 31. 인테리어는 시세 직접가산 없음

```text
리모델링 4천만원
→ 집값 자동 +4천만원
```

금지.

보상:
- 생활
- 비주얼
- 공간
- 생활씬
- 만족도

보유집을 오래 꾸며도 시장평가는 시장/정적 가격구조와 분리.

---

# 32. 시장 갱신 시점

게임월 경계에서만.

실시간 초/분 가격갱신 없음.

`04_time_contract.md`의 월경계 순차처리 사용.

---

# 33. 오프라인 시장 진행

최대 3게임개월.

```text
Month N → N+1
시장 + 모든 보유주택 평가
→ 다음월
```

월별 순차계산.

온라인/오프라인 동일 결과.

---

# 34. 서버 전체 현실시간 배치갱신 없음

현실 30분마다 모든 플레이어 집값을 업데이트하지 않는다.

플레이어가 자신의 게임월 경계를 넘을 때 개인 market index와 owned property 평가를 갱신한다.

---

# 35. 플레이어 시장상태

```text
player_id
start_market_snapshot_id
elapsed_game_month
sale_market_index
jeonse_market_index
rent_market_index
last_market_updated_game_month
```

Cycle 위치는 elapsed_game_month로 재현 가능.

---

# 36. Snapshot 데이터

```text
market_snapshot
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

```text
market_snapshot_price
snapshot_id
region_id
contract_type
market_type
base_unit_price
```

---

# 37. 가격 집계권역과 게임 노출지역 분리

통계집계용 행정구역과 게임 생활권을 분리 가능.

예:

```text
게임: GANGNAM
조사: GANGNAM_SEOCHO
```

YONGSAN / HANNAM_PREMIUM도 02 정책 유지.

---

# 38. 장기 경제규모

집값 Hard Cap이 없으므로 소득/경제규모가 영구고정되면 극장기 progression이 깨진다.

따라서 장기 원칙:

> 주택가격과 함께 게임 내 명목 소득·경제규모도 장기적으로 성장 가능해야 한다.

구체 방식은 01/03 통합밸런싱 과제.

---

# 39. 장기 주택 기록

보존 후보:

- 시작 Snapshot
- 현재 시장지수
- 각 자가 purchase_price
- purchase_game_month
- sale_price
- current_market_value
- ownership_duration
- property_net_equity
- 장기 보유 여부

16의 주거역사/도감과 연결.

---

# 40. 공유 콘텐츠

14와 연결.

예:

```text
사회생활 196년 차
첫 자가
구입가 4.2억
현재시세 37.8억
```

또는:

```text
현재 보유주택 12채
총 주택순자산 xxx
```

단 자산숫자를 랭킹게임의 중심으로 만들지 않는다.

---

# 41. UI 원칙

일반:

```text
서울 주거시장
완만한 상승세
```

자가/다주택:

- 구입가
- 현재 예상시세
- 남은 연결대출
- 개별 순주택자산
- 총 주택순자산

을 확인 가능.

`총 주택순자산`과 `사용 가능 현금`은 명확히 구분한다.

---

# 42. 어드민 관리

핵심은 Starting Market Snapshot.

- snapshot metadata
- region × contract × market base_unit_price
- 이전 Snapshot 비교
- Publish 검증
- renewal cap
- 시장 UI copy

다주택 관련 별도 시장 growth 설정은 만들지 않는다.

---

# 43. 어드민에서 관리하지 않는 시장구조

- STABLE/RISING/FALLING Cycle
- Cycle 순서/반복
- 누적지수 초기화 금지
- Cycle 전체 양수
- 장기 완만한 우상향
- Hard Cap 없음
- random/Seed 없음
- 지역별 독립시장 없음
- REGION 시세 직접효과 없음 V0.1
- 생성매물 price LOCK
- 임대계약 가격고정
- 모든 OWNED_PROPERTY 월별 평가
- 신규 Snapshot으로 기존세계 덮어쓰기 금지

Cycle 수치 변경은 라이브 즉석 어드민이 아니라 기획/코드 버전업.

---

# 44. 시뮬레이션 시작값

```text
Cycle = 36개월
0~5   STABLE
6~13  RISING
14~19 STABLE
20~25 FALLING
26~29 STABLE
30~35 RISING
```

SALE 예시:

```text
STABLE  +0.05%
RISING  +0.30%
FALLING -0.25%
```

목표:
- 1 Cycle +3~5%
- 실제 FALLING 체감
- 장기 우상향
- 자가 progression 훼손 방지

---

# 45. QA

1. Snapshot별 신규유저 시작가격이 정상인가.
2. 새 Snapshot이 기존유저 세계를 덮지 않는가.
3. 같은 Snapshot + same elapsed month에서 동일 market index인가.
4. Cycle 반복 시 지수가 초기화되지 않는가.
5. FALLING에서 실제 하락하는가.
6. Cycle 전체가 양수인가.
7. 100/300/500년 overflow 없는가.
8. SALE/JEONSE/RENT 별도률이 정상인가.
9. 지역별 동적 성장률 차등이 없는가.
10. REGION 이벤트가 시세를 직접 바꾸지 않는가.
11. 생성매물 가격이 LOCK되는가.
12. 계약중 임대가격이 고정되는가.
13. 갱신은 현재시장+cap을 따르는가.
14. 모든 보유주택 current_market_value가 월별 갱신되는가.
15. 같은 플레이어의 모든 보유집이 같은 개인 market index를 사용하는가.
16. 개별 property net equity가 연결 HOME_LOAN을 정확히 차감하는가.
17. total_home_equity가 모든 owned property를 합산하는가.
18. total_home_equity가 spendable_cash처럼 구매에 사용되지 않는가.
19. 기존집 보유선택에서 미실현 순자산을 새집 자금으로 잘못 선반영하지 않는가.
20. 온라인/오프라인 3개월 평가결과가 동일한가.
21. 100채 이상 보유에서도 월평가가 성능상 가능한가.
22. 장기 구입가/현재가/보유기간/공유값이 재현 가능한가.

---

# 46. V0.2 확정 정책

- 현실시간은 신규게임 Starting Market Snapshot에만 사용한다.
- 새 Snapshot은 신규유저에만 적용하고 기존유저 세계를 재기준화하지 않는다.
- 게임 내부 시장은 랜덤 없는 36개월 고정 Cycle을 기본안으로 사용한다.
- `STABLE → RISING → STABLE → FALLING → STABLE → RISING`을 반복한다.
- Cycle 패턴만 반복하고 누적시세는 초기화하지 않는다.
- 각 Cycle 전체 누적변화는 양수이며 장기적으로 완만한 우상향이다.
- 장기 집값 Hard Cap은 없다.
- SALE/JEONSE/RENT 변동률은 별도다.
- 지역별 독립 Regime/영구 성장률 차등은 사용하지 않는다.
- REGION 이벤트는 V0.1에서 시세를 직접 변경하지 않는다.
- 신규 매물은 현재시세로 생성하고 생성 후 가격 LOCK.
- 기존 임대계약 가격은 계약중 고정.
- 갱신은 현재시세+필요시 renewal cap.
- **모든 OWNED_PROPERTY의 current_market_value를 매 게임월 갱신한다.**
- 모든 보유주택은 동일 플레이어의 개인 SALE market index를 공유한다.
- 구입가와 현재시세를 분리보존한다.
- 개별 property net equity와 total home equity를 계산한다.
- 미매도 주택의 순자산을 즉시 사용 가능한 현금으로 취급하지 않는다.
- 기존집 매도 시에만 예상 순자산을 갈아타기 구매자금에 선반영할 수 있다.
- 인테리어 비용은 시세에 직접 가산하지 않는다.
- 시장갱신은 게임월 경계에서만 한다.
- 오프라인도 월별 순차계산한다.
- 극장기 가격/보유기록은 주거역사·컬렉션·공유에 활용한다.
