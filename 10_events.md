# 10_events.md
기준일: 2026-08-25
상태: V0.2 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 회사·주거·생활·경제·지역·다주택 관리 이벤트의 발생, 선택, 결과, 대기, 재발 제한, 후속 체인을 상세 정의한다.

이벤트의 목적은 단순 랜덤 보상이나 패널티가 아니다.

- 매달 생활이 똑같이 반복되지 않게 한다.
- 직장, 집, 통근, 생활상태, 자산상태가 실제 사건으로 이어지게 한다.
- 플레이어가 자신이 선택한 삶의 조건을 사건을 통해 체감하게 한다.
- 좋은 일과 나쁜 일이 적당히 섞인 생활 리듬을 만든다.
- 랜덤 사건이 장기 progression을 파괴하지 않게 한다.
- 다주택 이후에는 각 집이 실제로 독립적인 관리대상처럼 느껴지게 한다.

핵심 원칙:

> 이벤트는 플레이어를 벌주는 랜덤 함정이 아니라, 지금까지 만든 삶과 보유한 집에 작은 변화를 주는 사건이다.

---

# 2. 시간 처리 기준: AUTO / RECORD / CHOICE

`04_time_contract.md`의 시간정책을 따른다.

## 2.1 AUTO

선택이 필요 없고 자동 처리 가능한 사건.

예:

- 소액 관리비 변동
- 소액 보너스
- 기본 시장 변화
- 소액 환급
- 생활비 소폭 변동

온라인/오프라인 모두 자동 처리 가능하다.

## 2.2 RECORD

이미 일어난 결과를 기록해서 알려주는 사건.

예:

- 프로젝트 성과 보너스
- 회사 복지 지급
- 작은 지역 변화
- 자동 수리 완료

오프라인에서도 발생할 수 있고 복귀 시 통합 정산/기록에서 보여준다.

## 2.3 CHOICE

플레이어 판단이 필요한 사건.

예:

- 승진 관련 중요한 선택
- 이직 제안
- 구조조정 대응
- 큰 주거 수리 선택
- 투자 선택
- 계약 관련 선택
- 주택별 수리/미루기 선택

자동 확정하지 않고 `PENDING` 또는 다주택의 `PROPERTY_ISSUE_QUEUE`에 둔다.

플레이어가 실제 중요 선택 화면을 열면 결정이 끝날 때까지 게임 시간을 일시 정지한다.

---

# 3. 이벤트 발생 출처: RANDOM / SCHEDULED / FOLLOWUP

시간 처리 타입과 별도로 `어떻게 발생했는가`를 구분한다.

## 3.1 RANDOM

현재 상태를 기반으로 후보 풀에서 확률적으로 발생한다.

예:

- 최초 누수
- 보너스
- 몸살
- 친구 방문
- 동네 행사

## 3.2 SCHEDULED

시스템상 일정 시점에 발생하도록 예약된 사건.

예:

- 계약 만료 알림
- 이미 정해진 수리 완료
- 특정 progression 시점 안내

## 3.3 FOLLOWUP

이전 이벤트의 선택이나 미해결 상태 때문에 후속으로 발생한다.

예:

- 누수 수리를 미룸 → 다음 달 누수 재확인
- 이직 준비 시작 → 몇 개월 후 결과
- 조직개편 대응 선택 → 후속 결과

중요 원칙:

> RANDOM 이벤트의 월 발생확률과 이미 예약된 SCHEDULED/FOLLOWUP 이벤트는 별도로 처리한다.

이미 발생원인이 있는 후속 이벤트가 `이번 달 랜덤 이벤트가 안 뽑혔다`는 이유로 사라지면 안 된다.

---

# 4. Event Scope

다주택 확장을 위해 이벤트에 `어디에 귀속되는 사건인가`를 나타내는 scope를 둔다.

```text
event_scope
```

기본 후보:

```text
PLAYER
CAREER
CURRENT_RESIDENCE
OWNED_PROPERTY
REGION
```

### PLAYER

플레이어 개인 전체에 발생하는 사건.

예:
- 몸살
- 경조사
- 환급

### CAREER

현재 직장/커리어에 귀속.

예:
- 승진
- 이직
- 구조조정

### CURRENT_RESIDENCE

실제로 살고 있는 집에서만 의미가 있는 사건.

예:
- 층간소음
- 이웃 문제
- 수면 방해

### OWNED_PROPERTY

거주 여부와 상관없이 소유한 집 자체에서 발생 가능한 Maintenance 사건.

예:
- 누수
- 보일러 고장
- 수도/전기 문제
- 창호 문제

### REGION

현재 생활지역/관련 지역의 생활환경 사건.

예:
- 동네축제
- 공원/상권 변화
- 공사

주택에 귀속되는 이벤트 인스턴스는 필요 시:

```text
linked_property_id
```

를 저장한다.

---

# 5. 이벤트 카테고리

기본 카테고리:

- `CAREER` 회사/커리어
- `HOUSING` 주거
- `LIFE` 생활
- `ECONOMY` 경제
- `REGION` 지역
- `PROGRESSION` 특별 progression

예시:

## CAREER
- 성과
- 보너스
- 야근
- 승진
- 이직
- 조직개편
- 구조조정
- 복지

## HOUSING
- 누수
- 보일러
- 냉방
- 배수
- 층간소음
- 관리비
- 집주인/관리 관련
- 수리

## LIFE
- 몸살
- 휴가
- 친구 방문
- 취미
- 계절생활
- PARTNER/FAMILY 제안

## ECONOMY
- 세금/환급
- 특별수당
- 카드지출
- 경조사
- 보험/예상외 지출

## REGION
- 동네축제
- 공원/상권 변화
- 교통 개선
- 공사
- 지역 분위기 변화

## PROGRESSION
- 첫 승진
- 첫 전세
- 첫 자가
- 첫 구조조정
- 첫 프리미엄 주거
- 다주택/컬렉션 milestone

---

# 6. 플레이어 상태와 Property 상태가 후보 풀을 만든다

완전 랜덤으로 모든 이벤트를 뿌리지 않는다.

후보 조건으로 다음을 조합할 수 있다.

- 현재 회사
- 회사 유형/등급
- 업무강도
- 안정성
- 성장성
- career_level
- 재직기간
- 현재 career_level 유지기간
- 근무지역
- current residence 지역
- 주택유형
- 신축/구축/집 상태
- 주택 Feature
- 계약상태
- Household State
- 체력
- 스트레스
- 행복
- 통근시간
- 생활환경
- 보유/배치 가구
- 계절
- 날씨
- 현재 자산
- 최근 이벤트
- 현재 활성 상태값
- 보유주택별 build_age / condition / feature / active issue

핵심:

> 현재 플레이어가 어떤 삶을 살고 있고 어떤 집들을 보유하고 있는지가 어떤 사건이 일어날 수 있는지를 결정한다.

---

# 7. 글로벌 RANDOM 이벤트 빈도

플레이어 전체의 일반 RANDOM 이벤트는 매달 반드시 발생하지 않는다.

V0.1 초기 테스트 범위:

- 글로벌 RANDOM 월 이벤트 발생률: 약 40~60%
- 이벤트 없음: 약 40~60%
- 소규모 AUTO/RECORD가 일반적인 사건의 다수를 차지
- 중요한 글로벌 CHOICE는 낮은 빈도로 발생

글로벌 중요 CHOICE는 기본적으로 한 게임월 `0~1개`를 목표로 한다.

SCHEDULED/FOLLOWUP은 위 RANDOM 발생률과 별도다.

예약된 중요 사건이 많은 달에는 일반 글로벌 RANDOM 이벤트를 줄일 수 있다.

---

# 8. Property Maintenance 빈도는 글로벌 Cap과 분리

`16_multi_property.md`가 활성화되면 보유주택 Maintenance는 각 `player_property`마다 독립 판정한다.

즉:

```text
1채 → 1개 property 후보
10채 → 10개 property 후보
100채 → 100개 property 후보
```

이다.

보유주택 수가 늘면 전체 Maintenance 기대발생량도 실제로 증가한다.

다음처럼 글로벌 중요 CHOICE cap으로 잘라내지 않는다.

```text
보유 100채
→ Property 사건 최대 1건
```

금지.

대신 UI 노출은 `주택 관리 리포트`로 묶어 반복팝업을 줄인다.

---

# 9. 이벤트 중요도

이벤트에는 priority를 둔다.

```text
CRITICAL
HIGH
NORMAL
FLAVOR
```

예:

### CRITICAL
- 계약 만료
- 구조조정 이후 진로
- 현재 거주상태를 반드시 결정해야 하는 문제

### HIGH
- 승진
- 이직 제안
- 현재 거주지의 큰 주거 수리

### NORMAL
- 보너스
- 야근
- 일반 Maintenance

### FLAVOR
- 동네축제
- 계절 이야기
- 소소한 행운

글로벌 중요 이벤트가 겹치면 낮은 priority를 억제/연기할 수 있다.

Property Maintenance는 발생 자체를 글로벌 priority cap으로 없애지 않고 관리 Queue에서 정리한다.

---

# 10. 이벤트 그룹

개별 `event_id`와 별도로 `event_group`을 둔다.

기본 그룹 예:

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
PARTNER_PROPOSAL
FAMILY_PROPOSAL
```

이벤트 ID가 달라도 같은 의미의 사건이 과도하게 반복되지 않게 한다.

---

# 11. 발생 제한은 ID + 그룹 + Scope + 관계를 함께 본다

이벤트 발생 가능 여부는 최소 다음을 함께 본다.

- 동일 event_id 재발기간
- 동일 event_group 재발기간
- event_scope
- linked_property_id
- 현재 회사 재직기간
- 현재 career_level 유지기간
- 특정 이전 이벤트 이후 경과기간
- 다른 event_group과의 관계 제한
- 현재 진행 중인 이벤트 체인

Property 이벤트의 동일/유사 사건 중복은 기본적으로:

```text
event_group + linked_property_id
```

단위로 판정한다.

따라서 같은 집에 누수가 진행중인데 새 최초 누수를 또 만들지는 않지만, 서로 다른 집에서 동시에 누수가 발생할 수 있다.

---

# 12. 커리어 이벤트 기본 기간값 V0.1

커리어 시스템의 자격조건은 `03_career.md`가 기준이고 이벤트 시스템은 자격 이후 노출 타이밍과 재발 제한을 관리한다.

| 이전/현재 조건 | 대상 이벤트 | 초기 규칙 |
|---|---|---|
| 첫 직장 입사 | 첫 승진 | 최소 재직 12개월 이후 자격 검토 |
| 직전 승진 | 다음 승진 | 현재 career_level 최소 12개월 유지 |
| PROMOTION 발생 | PROMOTION | 12개월 hard block |
| JOB_CHANGE 발생 | JOB_CHANGE | 12개월 hard block |
| JOB_CHANGE 발생 | PROMOTION | 6개월 hard block |
| PROMOTION 발생 | JOB_CHANGE | 3개월간 가중치 0.5 테스트 |
| JOB_CHANGE 발생 | RESTRUCTURING_MAJOR | 3개월 hard block |
| RESTRUCTURING_MAJOR 발생 | RESTRUCTURING_MAJOR | 12개월 hard block |

기간은 V0.1 시작값이며 어드민에서 조정한다.

---

# 13. 이벤트 관계 테이블

개념 데이터:

```text
source_event_group
target_event_group
block_months
weight_modifier
modifier_months
condition_profile
```

예:

```text
PROMOTION → PROMOTION
block 12개월

JOB_CHANGE → JOB_CHANGE
block 12개월

JOB_CHANGE → PROMOTION
block 6개월

PROMOTION → JOB_CHANGE
3개월 동안 weight × 0.5
```

Property Maintenance 간 관계는 필요 시 linked_property_id 조건을 함께 사용한다.

---

# 14. 동일/유사 사건 반복 방지

각 이벤트에:

- `cooldown_months`
- `group_cooldown_months`
- `max_per_month`
- `max_lifetime`
- 최근 N개월 내 발생여부

를 둘 수 있다.

단 `누수를 미뤘기 때문에 FOLLOWUP이 다시 뜨는 것`은 랜덤 반복이 아니라 미해결 상태의 후속처리다.

다주택에서는 플레이어 전체에 같은 누수 그룹 cooldown을 걸어 다른 집의 누수까지 차단하지 않는다.

---

# 15. 부정/긍정 이벤트 연속 방지

글로벌 큰 부정 이벤트에는 `negative_streak_guard`를 둔다.

예:

- 최근 2개월 큰 부정 이벤트가 있었다면 다음 글로벌 큰 부정 weight 감소
- 회복성/중립 이벤트 weight 상승 가능

큰 긍정 이벤트도 경제를 무너뜨리지 않도록 연속 제한할 수 있다.

단 Property Maintenance의 발생량은 보유주택 수를 반영해야 하므로 글로벌 negative streak guard가 모든 집의 경미한 Maintenance를 통째로 제거하지 않게 한다.

---

# 16. 초반 보호기간

사회생활 초반에는 강한 부정 사건을 제한한다.

V0.1:

- 첫 3~6개월 큰 구조조정/큰 수리비/큰 경제손실 weight 감소 또는 비활성
- 기본 테스트 6개월 보호

작은 생활/경미한 집 문제는 발생 가능.

다주택 자체는 첫 자가 이후이므로 초반 보호와 직접 충돌하지 않는다.

---

# 17. 회사/커리어 이벤트

안정성이 높은 회사:

- 큰 구조조정 확률 낮음
- 안정적 보너스/복지 가능

성장형/불안정 회사:

- 성과급/성장 이벤트
- 야근/조직변화
- 구조조정 위험

승진/이직/구조조정의 자격 의미는 `03_career.md`가 기준이다.

---

# 18. 승진 이벤트

승진 자격 충족 후 PROMOTION cooldown/관계 제한을 통과해야 발생한다.

예:

```text
승진 제안
월급 380 → 450
업무강도 ★★★ → ★★★★
부업기회 5 → 4
```

중요한 승진 CHOICE는 글로벌 중요 CHOICE 범주다.

---

# 19. 이직 이벤트

이직 제안은:

- 월급
- 업무강도
- 안정성
- 성장성
- 근무지역
- current residence 기준 통근
- 예상 월잔액
- 예상 부업횟수

를 보여준다.

JOB_CHANGE cooldown은 기존 기준을 유지한다.

---

# 20. 구조조정 이벤트

실직은 게임오버가 아니다.

```text
조직개편 발표
→ 대응 선택
→ FOLLOWUP
→ 잔류/퇴직
→ 필요 시 구직
```

이직 직후 큰 구조조정 hard block 등 기존 관계값을 사용한다.

---

# 21. 야근/업무 이벤트

업무강도가 높을수록 weight가 증가할 수 있다.

```text
특근수당 +
체력 -
스트레스 +
```

돈과 생활리듬 trade-off를 만든다.

---

# 22. 주거 이벤트를 두 종류로 분리

## 22.1 PROPERTY_MAINTENANCE

비거주 보유집에서도 발생 가능.

예:

- 누수
- 보일러
- 냉방/배수
- 수도/전기
- 창호
- 시설수리

기본 scope:

```text
OWNED_PROPERTY
```

## 22.2 RESIDENCE_LIFE

실제로 거주해야 의미가 있는 문제.

예:

- 층간소음
- 이웃 문제
- 주변 소음
- 수면 방해

기본 scope:

```text
CURRENT_RESIDENCE
```

비거주 보유집의 생활형 불편으로 플레이어 스탯을 직접 깎지 않는다.

---

# 23. 주택 고장 후보 조건

Property Maintenance의 weight 후보:

- build_age
- house_condition
- housing_type
- Feature
- season
- active issue 수

가구를 랜덤으로 영구파괴하지 않는다.

Feature별 Maintenance는 `16_multi_property.md` 기준으로 낮은 확률의 개성 요소로 확장 가능하다.

---

# 24. 미루기는 Property Issue를 만든다

수리를 미루면 이벤트가 끝나는 것이 아니라 해당 집에 미해결 Issue가 남는다.

예:

```text
LEAK_DISCOVERED
property_id = MAPO_HOME

[바로 수리]
→ RESOLVED

[미루기]
→ LEAK ISSUE 생성/유지
→ FOLLOWUP 예약
```

Property Issue는 linked_property_id 단위로 독립적이다.

---

# 25. Persistent State / Property Issue

글로벌 상태 예:

```text
JOB_SEARCH_ACTIVE
RESTRUCTURING_PENDING
```

주택별 상태는 Property Issue로 관리한다.

```text
LEAK
BOILER_BROKEN
WINDOW_PROBLEM
```

주택별 Issue 영향 후보:

- repair cost 증가
- 해당 주택 condition 악화
- 해당 집 공간/생활씬 제한
- current residence라면 생활환경/스트레스 영향 추가

비거주집의 Issue가 매달 플레이어 스트레스를 직접 대폭 깎지 않는다.

---

# 26. 악화확률

미루기 후 악화 가능성을 둔다.

관리값:

```text
base_escalation_probability
escalation_probability_per_month
max_escalation_probability
escalated_cost_multiplier
stress_per_month
environment_penalty
max_defer_months
```

다주택에서는 각 Issue의 `deferred_months`를 독립 계산한다.

영구 주택/가구 손실은 만들지 않는다.

---

# 27. 후속 이벤트 체인

FOLLOWUP 유형:

```text
GUARANTEED
PROBABILITY
CONDITION
```

Property Issue의 followup 역시 동일 엔진을 재사용하며 linked_property_id를 유지한다.

---

# 28. 후속 이벤트 데이터

```text
followup_rule_id
source_event_id
source_choice_id
followup_type
delay_min_months
delay_max_months
followup_event_id
base_probability
required_state
required_conditions
weight
```

Property 이벤트는 원본 property_id를 후속 이벤트로 전달한다.

---

# 29. 주거 이벤트 예시: 누수

현재 거주지:

```text
지금 살고 있는 집 천장에서 물이 새기 시작했어요.
```

추가 보유집:

```text
보유 중인 마포집에서 누수가 확인됐어요.
```

선택:

```text
[바로 수리]
돈 -수리비
문제 해결

[미루기]
현재 비용 없음
Property Issue 유지
악화 가능
```

현재 거주지라면 수리 전 생활환경/일부 생활씬에 추가 영향 가능.

---

# 30. 층간소음/생활소음

`CURRENT_RESIDENCE`에서만 발생한다.

가능 영향:

- 수면환경 악화
- 스트레스 증가

일부 불편은 돈으로 즉시 해결하지 않고 다음 이사욕망을 만드는 역할을 한다.

---

# 31. 생활 이벤트

`07_character_life.md`, `13_life_stage.md`, `14_healing_social.md`와 연결한다.

예:

- 몸살
- 휴가
- 취미
- 친구 방문
- PARTNER/FAMILY 제안

생활 이벤트는 큰 경제손실보다 생활상태 변화 중심이다.

---

# 32. 친구 방문

집꾸미기 보상으로 사용할 수 있다.

조건:

- current residence의 주거환경
- 앉을 가구/식사공간 등

결과:

- 행복
- 특별 생활씬
- 생활앨범 기록

---

# 33. 경제 이벤트

긍정:

- 세금환급
- 특별수당
- 소액 경품

부정:

- 예상외 카드값
- 보험/경조사
- 수리비

한 번의 랜덤 사건으로 여러 달의 장기저축을 크게 훼손하지 않게 한다.

다주택 Maintenance 수리비는 보유주택 수 증가에 따라 총 기대값이 늘 수 있으므로 16의 보유규모 QA를 별도로 수행한다.

---

# 34. REGION 이벤트

예:

- 동네축제
- 새 공원
- 공사
- 상권 활성화
- 교통 개선
- 지역 분위기 변화

V0.1에서 REGION 이벤트는 **부동산 시세를 직접 변경하지 않는다.**

영향 후보:

- 생활환경
- 행복/스트레스
- 생활씬
- 지역 체감

시세는 `12_market_price.md`의 고정 Market Cycle이 Source of Truth다.

---

# 35. 계절 이벤트

계절 진행은 `14_healing_social.md` 확정정책을 따른다.

- 계절 1개 = 게임 3개월
- 게임 12개월 = 사계절 1회
- 현실 계절과 연동하지 않음

계절별 이벤트 풀을 달리할 수 있다.

---

# 36. 생활씬과 이벤트의 구분

- 짧은 자율행동/관찰 중심 → 생활씬
- 선택, 상태변화, 비용, 보상, 지속효과 → 이벤트

생활씬 발생은 07, 발견/앨범/공유는 14가 기준이다.

---

# 37. CHOICE 선택지

보통 2~3개.

연결 가능:

- 즉시 돈 변화
- 체력/스트레스/행복
- 자유시간
- 커리어
- Household State
- persistent state / Property Issue
- 후속 이벤트

가능하면 하나의 선택지만 명백한 정답이 되지 않게 한다.

---

# 38. 중요한 결과는 미리 알려준다

큰 돈, 직장 변화, 주거 장기상태는 선택 전에 방향성을 보여준다.

소액 FLAVOR는 일부 숨겨진 결과를 허용할 수 있다.

---

# 39. PENDING과 Property Management Queue

글로벌 중요 CHOICE:

```text
PENDING_LIFE_CHOICE
```

다주택 Maintenance:

```text
PROPERTY_ISSUE_QUEUE
```

로 논리/UI를 분리한다.

원칙:

- 중요한 CHOICE 자동결정 금지
- 오프라인 발생 시 대기
- 글로벌 PENDING 하나 때문에 전체 게임을 무조건 멈추지 않음
- 실제 중요 선택화면을 열면 시간정지 가능
- Property Issue가 많아도 승진/이직/Household CHOICE를 큐에서 밀어내지 않음

---

# 40. 주택 관리 리포트

같은 달 여러 Property Maintenance는 개별 팝업 대신 하나의 관리 리포트로 묶는다.

예:

```text
이번 달 내 집 관리

신규 문제 3건
미해결 2건

마포 테라스빌라 - 누수
서대문 구축아파트 - 보일러
용산 오피스텔 - 창호
```

발생한 Issue 자체는 각각 독립 저장한다.

---

# 41. 일괄수리

다주택이 많아지면 경미한 Issue를 한 번에 처리할 수 있는 UI를 제공하는 방향을 사용한다.

```text
수리가 필요한 집 모두 처리
총 비용 18,400,000원
```

큰/특수 선택은 일괄처리에서 제외 가능.

핵심:

> 이벤트 발생량을 줄이는 것이 아니라 조작노동을 줄인다.

---

# 42. 동일 이벤트 체인 잠금

글로벌 체인:

- 이직 PENDING → 추가 이직 제안 보류
- 구조조정 진행 중 → 동일 체인 금지

Property 체인:

- `HOUSE_BREAKDOWN + property_A` ACTIVE → property_A 동일 최초 사건 금지
- property_B의 동일 그룹은 독립 발생 가능

---

# 43. 이벤트 만료

중요 글로벌 CHOICE:

- 기본 확인/처리 전 만료 없음

FLAVOR:

- 만료 가능

Property Issue:

- 단순 시간만으로 자동 소멸하지 않음
- 해결/악화/후속 상태전이로 처리

---

# 44. 오프라인 처리

오프라인 최대 3개월 범위에서:

- AUTO → 자동 처리
- RECORD → 발생/기록
- 글로벌 CHOICE → PENDING
- SCHEDULED/FOLLOWUP → 도래 처리, CHOICE면 대기
- 모든 OWNED_PROPERTY → Maintenance 후보 판정
- 기존 Property Issue → 월별 악화/상태효과 판정

각 게임월을 순차적으로 처리한다.

복귀 시 여러 집 문제를 월별 팝업으로 반복하지 않고 통합 관리 리포트로 보여준다.

플레이어 선택은 자동확정하지 않는다.

---

# 45. 복귀 이벤트 요약

예:

```text
2개월 동안 이런 일이 있었어요.

+ 성과급 400,000원
- 일반 지출 70,000원

처리할 인생 선택 1개
관리 필요한 집 4채
```

경제 통합정산과 함께 보여줄 수 있다.

---

# 46. 예약 이벤트가 많은 달의 우선순위

글로벌 권장순서:

```text
시스템 필수/계약
→ 예약된 중요 FOLLOWUP
→ 중요한 RANDOM CHOICE
→ 일반 글로벌 이벤트
→ FLAVOR
```

Property Maintenance는 별도 property 판정/Queue로 처리한다.

---

# 47. 이벤트와 광고/부업

이벤트 해결 자체에 광고를 직접 붙이지 않는다.

금지:

```text
광고 보면 누수 해결
```

허용:

```text
수리비 부족
→ 일반 게임머니 부족
→ [부업하기]
```

다주택 수리비도 동일하다.

---

# 48. 이벤트 보상/손실 규모

글로벌 RANDOM 참고범위:

- 소형: 월 가처분소득 약 5~20%
- 중형: 약 20~50%
- 큰 이벤트: 약 50~100%, 낮은 빈도

Property Maintenance는 1채가 아니라 1/3/10/30/100/300채 보유규모에서 총 기대수리비를 별도 시뮬레이션한다.

---

# 49. 영구손실 금지

랜덤 이벤트/Property Issue로 다음을 만들지 않는다.

- 집 소멸
- 강제매도
- 가구 영구파괴
- 보증금 전체 몰수
- 장기간 모은 자산의 대규모 강제 소멸

악화는 비용/상태/사용제한 수준이다.

---

# 50. 이벤트 공정성

통제불가능 랜덤일수록 패널티는 작게 한다.

플레이어가 확인 가능한 위험:

- 낮은 회사 안정성
- 오래된 집
- 긴 통근
- 장기간 높은 스트레스
- 다수 노후주택 보유

등은 사건 weight에 반영 가능하다.

다주택 관리부담은 `집을 많이 샀으니 벌준다`가 아니라 실제 복수주택 보유감을 만드는 수준으로 유지한다.

---

# 51. Event Master 데이터

```text
event_master

- event_id
- name
- category
- event_type: AUTO / RECORD / CHOICE
- occurrence_type: RANDOM / SCHEDULED / FOLLOWUP
- event_scope
- event_group
- priority
- condition_profile
- weight
- cooldown_months
- group_cooldown_months
- available_from
- available_until
- max_per_month
- max_lifetime
- blocks_same_event_chain
- is_negative_major
- is_positive_major
- is_active
```

---

# 52. Event Instance 확장

```text
player_event_log

- event_instance_id
- event_id
- linked_property_id
- created_game_month
- resolved_game_month
- status
- selected_choice_id
- result_payload
```

Property scope가 아니면 linked_property_id는 null 가능.

---

# 53. 이벤트 관계 데이터

```text
event_relation

- source_event_group
- target_event_group
- block_months
- modifier_months
- weight_modifier
- condition_profile
- is_active
```

Property별 관계가 필요하면 condition에서 linked_property_id 동일 여부를 본다.

---

# 54. 선택지 데이터

```text
event_choice

- choice_id
- event_id
- label
- description
- money_delta
- energy_delta
- stress_delta
- happiness_delta
- career_delta
- free_time_delta
- household_state_change
- add_state_ids
- remove_state_ids
- followup_rule_ids
```

---

# 55. Property Issue 데이터

```text
property_issue

- issue_instance_id
- property_id
- issue_type
- severity
- started_game_month
- deferred_months
- current_repair_cost
- status
- escalation_profile_id
- blocked_scene_ids
```

상태 후보:

```text
ACTIVE
RESOLVED
```

---

# 56. 후속 이벤트 규칙 데이터

```text
event_followup_rule

- followup_rule_id
- source_event_id
- source_choice_id
- followup_type
- delay_min_months
- delay_max_months
- followup_event_id
- base_probability
- required_state_ids
- condition_profile
- weight
- preserve_linked_property
- is_active
```

Property followup은 기본적으로 `preserve_linked_property = true`다.

---

# 57. 악화 프로필

```text
event_escalation_profile

- escalation_profile_id
- base_probability
- probability_per_month
- max_probability
- cost_multiplier
- stress_per_month
- environment_penalty
- max_defer_months
- escalated_event_id
- is_active
```

비거주 Property Issue에서는 stress_per_month를 0 또는 매우 낮게 둘 수 있다.

---

# 58. 이벤트 발생 알고리즘

글로벌 RANDOM:

```text
현재 플레이어 상태로 후보 추출
→ 조건 불일치 제거
→ ID/group cooldown
→ event_relation
→ 진행중 체인 제거
→ 초반보호/연속보정
→ priority/weight
→ 결정
```

Property Maintenance:

```text
각 OWNED_PROPERTY 순회
→ 해당 Property 조건으로 후보 추출
→ linked_property_id 단위 중복/cooldown
→ build_age/condition/feature/season weight
→ 발생판정
→ Event/Issue 생성
```

SCHEDULED/FOLLOWUP은 예약큐에서 별도 처리한다.

---

# 59. 이벤트 UI/연출

모든 이벤트를 전용 애니메이션으로 만들 필요는 없다.

예:

- current residence 누수 → 물자국/생활환경 변화
- 비거주 보유집 누수 → 집 목록 경고 + 방문 시 연출
- 눈 → 창밖
- 친구 방문 → NPC
- 야근 → 늦은 귀가

일반 Maintenance는 관리 카드로 처리 가능하다.

---

# 60. 다른 시스템과의 연결

## 03 커리어
- 승진/이직 자격 의미

## 04 시간/계약
- AUTO/RECORD/CHOICE
- PENDING
- 오프라인 순차처리
- Property Queue 복귀요약

## 07 캐릭터 생활
- current residence의 주거문제가 생활스탯/씬에 영향

## 08 광고/부업
- 수리비 부족 시 일반 부업 CTA

## 12 시장가격
- REGION 이벤트는 V0.1 시세 직접효과 없음

## 13 라이프스테이지
- PARTNER/FAMILY 제안과 current residence 생활

## 14 힐링/소셜
- 계절/날씨
- 생활앨범
- 주거역사

## 16 다주택
- OWNED_PROPERTY Maintenance
- Property Issue
- 관리 리포트/일괄수리

---

# 61. V0.2 확정 정책

- 이벤트 시간 타입은 AUTO / RECORD / CHOICE다.
- 발생 출처는 RANDOM / SCHEDULED / FOLLOWUP이다.
- event_scope를 PLAYER / CAREER / CURRENT_RESIDENCE / OWNED_PROPERTY / REGION 등으로 구분한다.
- 주택 귀속 이벤트는 linked_property_id를 가진다.
- 글로벌 RANDOM 월 이벤트는 약 40~60%에서 테스트한다.
- 글로벌 중요한 CHOICE는 월 0~1개를 기본 목표로 한다.
- Property Maintenance는 글로벌 CHOICE cap과 별도다.
- 모든 보유주택은 독립적으로 Maintenance 후보 판정을 받는다.
- 보유주택 수가 늘면 Maintenance 기대발생량도 실제로 늘어난다.
- event_id뿐 아니라 event_group cooldown을 사용한다.
- Property 이벤트 동일 그룹 중복은 event_group + linked_property_id 단위로 제한한다.
- 서로 다른 집에서 같은 누수/고장 그룹이 동시에 발생할 수 있다.
- PROPERTY_MAINTENANCE와 CURRENT_RESIDENCE 생활형 주거이벤트를 구분한다.
- 층간소음 등 생활형 문제는 current residence에서만 발생한다.
- 미루기 선택은 Property Issue/persistent state와 FOLLOWUP을 만든다.
- Property Issue는 집별 독립적으로 악화/해결된다.
- 비거주집 문제는 플레이어 스탯보다 해당 집 상태/비용/사용제한에 주로 영향을 준다.
- 같은 달 여러 Property 이벤트는 관리 리포트로 묶는다.
- 경미한 다수 Issue는 일괄수리 UI를 지원하는 방향을 사용한다.
- Property Queue와 글로벌 PENDING CHOICE를 분리한다.
- 오프라인에서도 모든 보유주택 Maintenance를 게임월별 순차 처리한다.
- 중요한 수리/미루기 선택은 오프라인 자동확정하지 않는다.
- 승진/이직 등 커리어 이벤트의 기존 cooldown/관계값을 유지한다.
- 큰 부정/긍정 글로벌 이벤트 연속방지 장치를 둔다.
- 첫 3~6개월 강한 글로벌 부정 이벤트 보호를 사용한다.
- REGION 이벤트는 V0.1에서 부동산 시세를 직접 변경하지 않는다.
- 계절 진행은 14의 게임시간 3개월/계절 정책을 따른다.
- 랜덤으로 집/가구/보증금 등 기존 성장을 영구손실시키지 않는다.
- 이벤트 해결에 광고를 직접 붙이지 않고 일반 게임머니/부업 시스템을 사용한다.

---

# 62. 테스트 항목

1. 글로벌 RANDOM 이벤트가 너무 자주 발생하지 않는가.
2. SCHEDULED/FOLLOWUP이 랜덤확률 때문에 누락되지 않는가.
3. 승진/이직 반복이 정상 제한되는가.
4. 큰 글로벌 부정 이벤트가 연속돼 벌칙게임이 되지 않는가.
5. 미룬 주거문제가 적절한 시점에 다시 등장하는가.
6. Property Issue의 악화가 미루기를 무조건 오답으로 만들지 않는가.
7. current residence 주거문제가 생활상태와 자연스럽게 연결되는가.
8. 비거주집 문제 때문에 플레이어 생활스탯이 과도하게 악화되지 않는가.
9. 같은 집에 같은 최초 누수가 중복 생성되지 않는가.
10. 서로 다른 집에는 동일 누수가 동시에 발생 가능한가.
11. 1/3/10/30/100/300채에서 월 Maintenance 발생량이 감당 가능한가.
12. 다주택 관리 리포트가 수십 건이어도 읽고 처리할 수 있는가.
13. 일괄수리가 반복 클릭을 실제로 줄이는가.
14. Property 이벤트가 글로벌 승진/이직/Household CHOICE를 밀어내지 않는가.
15. 오프라인 1~3개월 Property Maintenance 결과가 온라인과 동일한가.
16. 관리문제 방치로 집/가구가 영구손실되지 않는가.
17. REGION 이벤트가 V0.1에서 시세를 직접 바꾸지 않는가.
18. 계절 이벤트가 14의 계절주기와 일치하는가.
19. 이벤트 비용 부족 시 일반 부업 CTA가 정상 작동하는가.
20. 다주택 Maintenance의 총 비용이 주거 컬렉션 욕망을 과도하게 꺾지 않는가.
