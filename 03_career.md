# 03_career.md
기준일: 2026-08-25
상태: V0.2 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 직장/커리어, 승진, 이직, 업무강도, 근무지역, 장기 명목소득 progression을 정의한다.

커리어는 단순 월급표가 아니라:

```text
커리어
→ 소득/근무지역/업무강도
→ 통근/자유시간
→ 부업/자기계발
→ 주거선택/자산축적
```

을 바꾸는 시스템이다.

---

# 2. 핵심 원칙

- 직장은 단순 월급순 티어가 아니다.
- 높은 월급은 업무강도/자유시간/주거비와 trade-off 가능.
- 근무지역은 current residence Utility의 핵심변수.
- 이직은 연봉뿐 아니라 통근/삶을 바꾼다.
- 연봉 감소 이직도 affordability를 만족하면 허용.
- 실직/구조조정은 게임오버 아님.
- 가구가 승진확률/월급을 직접 올리는 장비는 아님.
- 커리어레벨은 1~5로 단순화하되, 게임은 수백년 지속 가능하므로 Lv5 이후 명목소득이 영구고정되지는 않는다.

---

# 3. 첫 직장 3종 V0.1

| 항목 | 광화문 안정기업 | 구로 IT기업 | 강남 스타트업 |
|---|---|---|---|
| 초봉 가안 | 300만 | 330만 | 370만 |
| 근무지 | 광화문 | 구로 | 강남 |
| 업무강도 | ★★ | ★★★ | ★★★★ |
| 안정성 | ★★★★ | ★★★ | ★★ |
| 성장성 | ★★ | ★★★★ | ★★★★★ |
| 기본 부업기회 | 6 | 5 | 3 |
| 성격 | 시간형 | 균형형 | 성장형 |

모두 통합 경제시뮬레이션 전 테스트값.

---

# 4. 회사 속성

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
bonus_profile
benefit_profile
event_profile
```

등급 후보:

```text
SMALL / MID / LARGE / TOP
```

등급이 높다고 무조건 좋은 직장은 아니다.

---

# 5. 커리어 레벨

```text
career_level = 1 ~ 5
```

회사별 표시직급은 달라도 내부 level은 동일.

예:

전통기업:

```text
사원 → 대리 → 과장 → 차장 → 부장
```

스타트업:

```text
Junior → Senior → Lead → Head → Executive/Manager
```

Lv5 이후 Lv6, Lv7, Lv100처럼 직급을 무한히 만들지 않는다.

장기 경제성장은 별도의 명목소득 index로 처리한다.

---

# 6. 승진

기본 자격:

```text
재직기간
+ career growth / XP
+ 업무/이벤트 결과
```

획득원:

- 월 근무
- 자기계발
- 회사 이벤트
- 생활환경의 간접효과

승진 결과:

- 급여표 단계 상승
- 직급 변경
- 업무강도 변경 가능
- 부업가능량 변경 가능

기간만 채웠다고 자동승진하지 않는다.

커리어 시스템이 자격을 계산하고 `10_events.md`가 실제 PROMOTION 이벤트 노출/cooldown을 관리한다.

---

# 7. 승진 기간 시작값

- 첫 승진 자격검토: 최소 재직 12개월
- 다음 승진: 현재 level 최소 12개월 유지
- PROMOTION→PROMOTION: 12개월 hard block
- JOB_CHANGE→PROMOTION: 6개월 hard block

테스트값이며 15에서 관리.

---

# 8. 월급표 V0.1 가안

단위 만원/월.

### 광화문 안정기업

```text
Lv1 300
Lv2 330
Lv3 380
Lv4 450
Lv5 540
```

### 구로 IT

```text
Lv1 330
Lv2 380
Lv3 460
Lv4 570
Lv5 700
```

### 강남 스타트업

```text
Lv1 370
Lv2 450
Lv3 560
Lv4 720
Lv5 900
```

이 값은 `base salary table`이다.

---

# 9. 장기 명목소득 Index

`12_market_price.md`는 주택가격에 장기 Hard Cap이 없고 수백 게임년 동안 완만한 복리 우상향을 허용한다.

따라서 커리어 급여도 Lv5 도달 이후 영구고정시키지 않는다.

장기적으로:

```text
actual_salary
= company_level_base_salary
× long_term_nominal_income_index
```

를 사용할 수 있다.

`long_term_nominal_income_index`의 목적:

- 수백 게임년 뒤에도 주택/가구/시공 가격과 소득 규모가 완전히 분리되지 않게 함
- career_level 수를 무한히 늘리지 않음
- `사회생활 300년 차인데 월급만 900만원` 문제 방지

중요:

- 이 index 상승은 승진이 아니다.
- career_level, 직급명, 업무강도를 자동 변경하지 않는다.
- 동일 시점의 신규 이직 offer salary에도 같은 명목 index를 반영해야 한다.
- PARTNER contribution, 생활비, 경제상대비율 등도 통합경제에서 같은 장기 명목규모와 정합성을 맞춰야 한다.
- 정확한 시작시점/상승률/주기는 아직 확정하지 않는다.
- Market Cycle과 똑같은 비율로 올릴 필요도 없다.

정확한 장기곡선은 01/03/12/16 극장기 시뮬레이션에서 결정한다.

---

# 10. 장기 Index와 게임감

플레이어가 매달 `인플레이션 +0.1%`를 관리하는 경제게임으로 느끼지 않게 한다.

UI에서는 필요할 때:

```text
연봉 조정
생활물가 변화를 반영해 급여가 조정됐어요.
```

같은 자연스러운 기록으로 표현 가능.

명목조정 자체는 큰 CHOICE가 아니라 AUTO/RECORD 성격으로 처리할 수 있다.

장기 급여조정으로 행복/커리어성장점수를 직접 주지 않는다.

---

# 11. 업무강도 + 통근 → 자유시간

내부 기본:

```text
부업가능횟수
= 회사 기본값 + 통근보정 + 생활환경 보정
```

통근 시작값:

- <=20분 +1
- 21~40 0
- 41~60 -1
- 61~80 -2
- 81+ -3

영향:

- 부업
- 자기계발
- 체력/스트레스
- 생활행동

세부는 07/08.

---

# 12. 이직

이직은:

- 급여
- 업무강도
- 안정성
- 성장성
- 근무지역

을 바꿀 수 있다.

현재집 통근과 기존대출까지 포함해 예상 생활결과를 보여준다.

다주택에서도 통근판정은 current residence 기준.

---

# 13. 이직 카드

예:

```text
판교 IT기업 제안

월급 380 → 520
업무강도 ★★★
통근 20 → 82분
예상 월잔액 변화
부업 6 → 3회
```

장기 명목소득 index가 활성인 극장기에는 제안급여도 같은 시점 index를 적용해 서로 비교한다.

---

# 14. 이직 후 재계산

수락 즉시:

- work_district
- current residence 통근
- 생활부담
- 자유시간
- 부업횟수
- 자기계발
- 월 경제

재계산.

`새 직장 때문에 이사하고 싶다`는 주거욕망을 만든다.

---

# 15. 이직 재발 제한

- JOB_CHANGE→JOB_CHANGE 12개월 hard block
- PROMOTION→JOB_CHANGE 3개월간 weight 감소 테스트

정확값은 10/15.

---

# 16. 이직 Affordability

기존 활성대출을 포함해:

```text
새 정기소득
- 생활비
- current residence 고정주거비
- Household 필수비
- 기존 대출상환
= 이직 후 자유소득
```

11의 minimum free income을 충족해야 실행.

비거주 보유집에 연결된 HOME_LOAN도 포함한다.

---

# 17. 첫 이직 타이밍

첫 이직 후보는 사회생활 약 12~24개월 이후부터 테스트.

자격과 실제 노출은 분리:

- 03: 자격/affordability
- 10: cooldown/event relation/노출

---

# 18. 오프라인

최대 3게임개월.

자동:
- 기본 career XP
- 선택 없는 작은 회사결과
- 장기 명목급여 index 자동조정이 도래하면 적용/기록 가능

자동 금지:
- 승진 중요선택
- 이직
- 구조조정 대응

CHOICE는 PENDING.

---

# 19. 회사 안정성 / 구조조정

안정성 높음:
- 큰 구조조정 낮음
- 안정적 보너스/복지 가능

낮음:
- 고속성장/성과급
- 조직변화/구조조정 위험

실직은 게임오버 아님.

기존 대출 즉시회수/주택 강제매도 없음.

JOB_CHANGE→RESTRUCTURING_MAJOR 3개월 hard block 테스트.

---

# 20. 직장 Pool

가상회사 확장.

업무지구 예:

광화문: 언론/금융/대기업/공기업형

여의도: 금융/증권/방송

구로: IT/중견/서비스

강남: 스타트업/플랫폼/광고콘텐츠

판교: 게임/IT/플랫폼

실회사명 사용 안 함.

---

# 21. 집꾸미기와 커리어

직접:

```text
비싼 의자 → 승진확률 +10%
```

금지.

간접:

- 수면환경 → 컨디션
- 작업공간 → 자기계발
- 휴식공간 → 번아웃 완화
- 통근 개선 → 자유시간

으로 연결.

---

# 22. 집 크기 / 생활공간

원룸 → 작은 작업/휴식.

투룸 → 독립 침실/작업방.

아파트 → 거실/주방/서재/드레스룸.

프리미엄 → 테라스/홈카페/홈짐/취미방.

다주택의 비거주집 공간효과는 current career에 합산하지 않는다.

---

# 23. 데이터 구조

```text
player_career
- current_company_id
- career_level
- months_in_company
- months_in_current_career_level
- career_xp
- base_salary
- long_term_nominal_income_index
- salary
- work_district
- workload
- stability
- growth_rate
- promotion_eligible
- pending_career_event_ids
```

```text
career_offer
- offer_id
- company_id
- base_salary
- nominal_income_index
- offered_salary
- work_district
- workload
- stability
- growth_rate
- created_game_month
- affordability_checked
- expected_free_income_after_debt
- status
```

---

# 24. 어드민

기존:

- 회사/급여표
- 업무강도
- 안정성/성장성
- 부업 기본횟수
- 승진/이직조건
- cooldown

장기 경제 추가:

```text
long_term_nominal_income_enabled
long_term_nominal_income_start_month
long_term_nominal_income_update_interval_months
long_term_nominal_income_growth_rate
```

단 정확값은 통합시뮬레이션 후 확정한다.

직급/level 수 자체는 라이브 어드민으로 무한확장하는 방식이 아니다.

---

# 25. QA

1. 첫 3직장이 서로 다른 trade-off인가.
2. 승진이 자동시간경과가 아닌가.
3. 이직 근무지 변화가 주거선택을 바꾸는가.
4. 기존대출을 포함한 이직 affordability가 작동하는가.
5. 비거주 담보집 대출도 이직검사에 포함되는가.
6. 실직이 강제매도로 이어지지 않는가.
7. Lv5 도달 후에도 50/100/300년에서 명목소득이 영구고정되지 않는가.
8. 장기 income index가 career level/직급을 자동변경하지 않는가.
9. 같은 시점 이직 offer에 같은 장기 index가 적용되는가.
10. 장기 index가 집값보다 너무 빠르거나 너무 느려 progression을 깨지 않는가.
11. 장기 명목조정이 새로운 파밍/CHOICE로 변하지 않는가.

---

# 26. V0.2 확정 정책

- 첫 직장 3개 구조와 초기 월급은 기존 V0.1 가안을 사용한다.
- 회사는 급여/위치/업무강도/안정성/성장성/부업기회를 가진다.
- career level은 1~5로 유지한다.
- 승진은 재직기간+성장+업무/이벤트 결과 기반이다.
- 이벤트 시스템이 실제 승진/이직 노출과 반복제한을 관리한다.
- 첫 승진 최소12개월, PROMOTION→PROMOTION12개월, JOB_CHANGE→PROMOTION6개월 시작값을 사용한다.
- 이직은 급여와 근무지역을 바꿀 수 있다.
- 이직은 기존 활성대출을 포함해 affordability를 검사한다.
- 실직/구조조정은 게임오버/즉시강제매도 아님.
- 가구/주거환경은 커리어에 간접영향만 준다.
- **Lv5 이후에도 장기 명목소득은 영구고정하지 않는다.**
- 실제 급여/이직제안은 장기적으로 `base salary × long_term_nominal_income_index` 구조를 사용할 수 있다.
- 장기 명목소득 index는 승진/직급변경이 아니다.
- 정확한 장기 index 시작시점/주기/상승률은 01/03/12/16 통합 극장기 시뮬레이션으로 확정한다.
