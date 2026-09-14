# 13_life_stage.md
기준일: 2026-08-24
상태: V0.1 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 라이프스테이지를 생물학적 나이 증가가 아니라 `가구 구성(Household State)`과 `삶의 형태 변화`로 정의하고, 파트너·자녀·가족상태가 주거선택, 생활비, 생활씬, 가구/인테리어 욕망, 교육환경 Utility, 대출·이사 추천에 어떻게 연결되는지 상세 정의한다.

핵심 원칙:

> 라이프스테이지는 상위 티어가 아니라 같은 집과 같은 서울을 다른 방식으로 살아보게 만드는 선택이다.

> SOLO도 완전한 장기 플레이이며 PARTNER/FAMILY는 필수 progression이 아니다.

> 게임의 시간은 생물학적 나이가 아니라 경제·주거·커리어의 압축시간이므로 노화·사망·자녀 실제 연령 progression을 직접 연결하지 않는다.

---

# 2. 시스템 목적

초반 게임의 핵심 질문은 다음과 같다.

> 다음에는 어떤 집에서 살아볼까?

라이프스테이지가 열리면 다음 질문이 추가된다.

> 다음에는 누구와, 어떤 생활을 해볼까?

라이프스테이지의 역할은 다음과 같다.

- 더 큰 집을 원하는 새로운 이유를 만든다.
- 같은 집에서도 가구원 구성에 따라 필요한 공간과 생활씬을 달라지게 한다.
- 파트너/가족 전용 가구와 생활씬을 후반 콘텐츠로 연다.
- 통근, 공간, 생활환경, 교육환경의 trade-off를 확장한다.
- 가족을 단순 행복 버프나 비용 패널티로 만들지 않는다.
- 최고급 1주택 도달 이후에도 장기 주거 progression이 계속될 수 있도록 `16_multi_property.md`의 다주택/주거 컬렉션 확장과 연결한다.

---

# 3. 게임시간과 생물학적 시간 분리

`00_master_policy.md`의 시간정책을 따른다.

게임시간은 다음을 표현한다.

- 사회생활 경과
- 경제 성장
- 커리어 성장
- 주거 계약
- 부동산 시장
- 생활 변화의 누적

게임시간이 흘렀다고 캐릭터가 실제로 노화하지 않는다.

따라서 다음과 같은 장기 플레이도 정상이다.

```text
사회생활 50년 차
사회생활 100년 차
사회생활 300년 차
```

PARTNER/FAMILY 상태도 게임월이 오래 지났다는 이유로 자동 종료되지 않는다.

V0.1에서는 다음을 사용하지 않는다.

- 플레이어 생물학적 나이
- 파트너 노화
- 자녀 0세→1세→초등학생→성인 식 실제 연령 progression
- 노화에 따른 사망
- 시간 경과만으로 발생하는 가족 소멸

---

# 4. Household State

V0.1 기본 Household State는 세 가지다.

```text
SOLO
PARTNER
FAMILY_WITH_CHILD
```

## 4.1 SOLO

1인 가구다.

SOLO는 초반 임시상태가 아니라 독립적인 완성형 플레이 방식이다.

SOLO 상태에서도:

- 전세
- 첫 자가
- 중형 아파트
- 프리미엄 주거
- 한남 프리미엄
- 향후 다주택/주거 컬렉션

까지 모두 진행할 수 있다.

## 4.2 PARTNER

파트너와 함께 사는 2인 가구다.

법적 결혼 여부를 별도 시뮬레이션하는 대신 게임에서는 `함께 살기`라는 생활변화를 중심으로 표현한다.

PARTNER가 되면:

- 파트너 자율 캐릭터 등장
- 2인 생활씬 해금
- 2인 가구/수납/식사공간 욕망 증가
- 생활비 증가
- household contribution 발생
- 추천주택 기준 변화

가 발생한다.

## 4.3 FAMILY_WITH_CHILD

파트너와 자녀가 함께 사는 가족상태다.

V0.1에서는 자녀 수를 여러 명으로 확장하지 않고 `CHILD` 생활역할 1개를 기본으로 한다.

FAMILY가 되면:

- 가족 생활씬 해금
- 아이 공간/수납/식사/욕실 욕망 증가
- 가족용 가구 콘텐츠 해금
- 생활비 증가
- 교육환경 Utility 활성화
- 가족형 주택추천 가중치 활성화

가 발생한다.

---

# 5. 라이프스테이지는 상위 티어가 아니다

다음과 같은 선형 progression을 강제하지 않는다.

```text
SOLO
→ PARTNER
→ FAMILY_WITH_CHILD
→ 성공
```

다음 경로는 모두 정상이다.

```text
SOLO 유지
SOLO → PARTNER
SOLO → PARTNER → FAMILY_WITH_CHILD
```

결혼/파트너/자녀 여부로 게임의 성공과 실패를 판정하지 않는다.

특히 최고급 프리미엄 주거에서 혼자 살면서:

- 서재
- 드레스룸
- 홈짐
- 취미방
- 홈바
- 홈카페
- 테라스

를 확장하는 SOLO 플레이도 완성형 장기 플레이로 본다.

---

# 6. Household State 전환 방식

Household State 변화는 `10_events.md`의 LIFE / PROGRESSION 계열 `CHOICE` 이벤트를 통해 발생한다.

중요 전환은 자동 실행하지 않는다.

예:

```text
관계 생활이벤트 누적
→ 함께 살아볼까? CHOICE
→ 함께 살기 / 지금 생활 유지
```

PARTNER 이후:

```text
일정 생활기간 경과
→ 가족에 대한 대화 CHOICE
→ 가족을 늘려볼까 / 지금 둘의 삶 유지
```

CHOICE 중에는 `04_time_contract.md`의 중요 의사결정 시간정지 정책을 적용한다.

오프라인에서 PARTNER/FAMILY 상태를 자동 확정하지 않는다.

---

# 7. 제안 거절과 재제안

`지금은 아니야` 선택은 실패가 아니다.

기본 정책:

- 거절 패널티 없음
- 일정 cooldown 이후 다시 제안 가능
- 플레이어가 원할 경우 해당 유형 제안을 다시 받지 않는 옵션을 향후 제공 가능

예:

```text
proposal_cooldown_until_game_month
proposal_disabled
```

정확한 최소기간과 cooldown은 어드민에서 관리한다.

---

# 8. 자가/전세/월세와 Household State는 독립

다음 조건은 사용하지 않는다.

```text
자가가 있어야 PARTNER 가능
자가가 있어야 FAMILY 가능
```

가능한 플레이 예:

- 월세 원룸에서 PARTNER
- 전세 투룸에서 FAMILY
- 자가 아파트에서 SOLO
- 프리미엄 주거에서 SOLO

가구구성과 주거계약 유형은 독립적인 선택축이다.

---

# 9. 작은 집에서도 모든 Household State 허용

PARTNER/FAMILY가 되었다고 현재 집에서 강제퇴거시키지 않는다.

예:

```text
원룸 + PARTNER
원룸 + FAMILY_WITH_CHILD
```

도 시스템적으로 가능하다.

대신 큰 집을 원하는 soft pressure를 만든다.

예:

- 공간부족
- 수납부족
- 프라이버시 부족
- 사용할 수 있는 가족 생활씬 제한
- 큰 침대/식탁/소파 배치 곤란
- 아이 공간 부족

핵심:

> 가족이 생겨서 강제로 이사하는 것이 아니라, 같이 살다 보니 더 좋은 집이 갖고 싶어진다.

---

# 10. Recommended Household Size

각 주택/평면에 hard limit 대신 추천 가구원 수를 둘 수 있다.

예:

```text
원룸        추천 1명
투룸        추천 1~2명
쓰리룸      추천 2~3명
중형 아파트 추천 2~4명
```

추천 인원을 초과해도 거주할 수 있다.

추천 가구원 수는 다음의 계산/안내에 사용한다.

- 공간여유
- 프라이버시
- 수납
- 가족 생활씬 가능성
- 주택추천 가중치
- 자연어 안내문구

강제 입주제한에는 사용하지 않는다.

---

# 11. 공간부족은 실제 집꾸미기에서 느끼게 한다

Household State를 단순 스탯 패널티로 만들지 않는다.

예를 들어 PARTNER가 되면 다음을 원하게 한다.

- 2인 침대
- 2인 식탁
- 더 큰 소파
- 추가 수납

FAMILY에서는:

- 아이 침대/공간
- 아이 책상
- 장난감 수납
- 가족 식탁
- 큰 냉장고
- 가족 소파
- 욕실/수납 개선

등을 원하게 한다.

플레이어가 실제 Grid에 배치하면서 현재 집의 한계를 체감하게 하는 것이 우선이다.

---

# 12. 방 용도는 자동 고정하지 않는다

FAMILY가 되었다고 방 하나를 자동으로 아이방으로 바꾸지 않는다.

예:

```text
침실
서재
빈방
```

이 있는 집에서 플레이어가 직접:

- 서재 유지
- 아이방으로 전환
- 취미방 유지

를 결정한다.

`06_house_grid.md`의 기본 원칙대로 일반 방의 용도는 가구배치를 기반으로 인식한다.

예:

```text
아이침대
+ 아이책상
+ 장난감 수납
→ CHILD_ROOM 성격 강화
```

---

# 13. PARTNER 생활씬

PARTNER가 되면 같은 가구에서도 새로운 생활씬이 열린다.

예:

- 같이 TV 보기
- 소파에서 이야기하기
- 같이 저녁 먹기
- 커피 마시기
- 같이 요리하기
- 테라스에서 커피
- 각자 책 읽기
- 한 사람은 책상, 한 사람은 소파
- 비 오는 날 같이 영화 보기

핵심 보상:

> 같은 소파와 같은 집도 혼자 살 때와 둘이 살 때 다른 생활콘텐츠를 제공한다.

---

# 14. FAMILY 생활씬

예:

- 같이 아침 먹기
- 아이가 거실에서 놀기
- 소파에서 책 읽어주기
- 장난감 정리
- 아이 공간에서 재우기
- 가족 영화 보기
- 욕조 목욕
- 주말 가족 식사
- 테라스 가족생활

큰 현금보상보다 `07_character_life.md`의 자율생활/힐링 연출을 확장하는 것이 목적이다.

---

# 15. 복수 캐릭터 자율생활

PARTNER/FAMILY에서는 플레이어 캐릭터 외 가구원이 집 안에서 자율행동한다.

파트너/자녀는 직접 조작 대상이 아니라 자율생활 캐릭터다.

생활 예:

```text
플레이어: 책상에서 작업
파트너: 소파에서 TV
```

```text
플레이어: 요리
파트너: 식탁
아이: 거실 놀이
```

한 공간에서 여러 캐릭터가 동시에 생활하는 장면을 핵심 연출로 본다.

---

# 16. Interaction Point와 복수 캐릭터

`06_house_grid.md`, `07_character_life.md`의 interaction point 구조를 확장 사용한다.

예:

```text
3인 소파
seat_left
seat_center
seat_right
```

복수 캐릭터가 동일 가구를 사용할 때 각 interaction point의 사용 여부를 판정해야 한다.

동일 interaction point 중복 점유는 허용하지 않는다.

---

# 17. 파트너 경제기여

PARTNER에게 별도의 회사·직급·승진·이직 시스템 전체를 만들지 않는다.

V0.1에서는:

```text
partner_household_contribution
```

이라는 가구단위 기여금으로 단순화한다.

이는 플레이어 월급과 구분해 표시한다.

예:

```text
플레이어 월급
+ 파트너 생활비 기여
+ 부업/기타수입
- 주거비
- 가구원 생활비
= 월 household cashflow
```

파트너가 생겼다고 플레이어의 `salary` 자체가 증가하지 않는다.

---

# 18. 파트너 기여의 밸런스 원칙

파트너 월급을 플레이어 월급과 1:1로 합산해 총소득을 갑자기 두 배로 만들지 않는다.

반대로 PARTNER를 비용만 증가시키는 경제 패널티로 만들지도 않는다.

목표:

> 파트너는 생활규모를 키우고 비용도 늘리지만 경제에 일부 기여한다.

정확한 contribution 금액/비율은 통합 경제 시뮬레이션에서 확정한다.

---

# 19. Household Living Cost

가구원이 늘어나면 기본 생활비가 증가한다.

개념:

```text
SOLO              base living cost × solo modifier
PARTNER           base living cost × partner modifier
FAMILY_WITH_CHILD base living cost × family modifier
```

단순 인원수 선형배수는 사용하지 않는다.

주거·가전·통신 등 공유비용이 있으므로 완만한 증가곡선을 사용한다.

FAMILY가 되어도 파트너 기여금이 자동 0이 되지 않는다.

육아휴직·퇴사 등 파트너의 세부 커리어 변화는 V0.1에서 시뮬레이션하지 않는다.

---

# 20. 가처분소득과 필수지출 예약

Household State 변화로 생활비가 변하면 `01_economy_balance.md`, `11_loan.md`의:

```text
reserved_mandatory_expenses
spendable_cash
```

계산에 반영한다.

PARTNER/FAMILY 전환이 확정되는 순간 다음 월 예산을 재산정한다.

---

# 21. 대출에서 파트너 기여 인정

파트너 contribution을 신규대출 상환능력에 100% 인정하지 않는 것을 기본 방향으로 한다.

후보 설정:

```text
recognized_household_contribution_ratio
```

목적:

- PARTNER 선택만으로 대출한도가 폭증하는 문제 방지
- PARTNER가 주택 progression의 사실상 필수 선택이 되는 문제 방지

정확한 인정비율은 `11_loan.md`와 통합 시뮬레이션에서 확정한다.

기존 플레이어 커리어 월급과 파트너 contribution은 대출 UI에서도 구분한다.

---

# 22. 부업과 Household State

가구원이 늘었다고 부업 기본횟수를 직접 추가하지 않는다.

부업기회는 기존대로:

- 직장
- 통근
- 생활환경
- 자유시간

을 중심으로 결정한다.

가족생활이 자유시간에 간접 영향을 주는 구조는 향후 밸런스에서 연결 가능하나 V0.1 핵심규칙으로 강제하지 않는다.

---

# 23. 라이프스테이지 전용 가구 콘텐츠

PARTNER 이후 후보:

- 2인 침대
- 큰 식탁
- 큰 소파
- 추가 수납
- 2인 생활 장식

FAMILY 이후 후보:

- 아이 침대
- 아이 책상
- 장난감
- 아이 수납
- 패밀리 식탁
- 큰 냉장고
- 가족용 소파
- 아이방 가구
- 욕실 관련 가구

라이프스테이지 자체가 후반 가구 소비와 공간욕망을 여는 progression 역할을 한다.

---

# 24. 자가와 가족 인테리어

FAMILY가 자가를 요구하지는 않는다.

다만 `자가 + FAMILY` 조합에서는 다음과 같은 자가 전용 인테리어 욕망을 확장할 수 있다.

- 아이방 벽지/마감
- 붙박이 수납
- 가족형 주방
- 욕실 개선
- 고정 조명
- 가족수납 빌트인

자가의 추가 인테리어 권한은 `06_house_grid.md`의 ownership 정책을 따른다.

---

# 25. FAMILY에서 교육환경 Utility 활성화

SOLO/PARTNER에서는 교육환경을 핵심 주거 Utility로 사용하지 않는다.

`FAMILY_WITH_CHILD` 상태가 되면:

```text
education_environment
```

이 주거평가 요소로 활성화된다.

개념:

```text
FAMILY 주거 효용
= 집 자체 가치
+ 통근
+ 생활환경
+ 교육환경
+ 가구원 공간적합도
```

---

# 26. 학군/교육환경은 가격과 분리

교육환경이 좋다고 13에서 주택가격을 다시 곱하지 않는다.

금지:

```text
학군 좋음
→ house price × 1.2
```

주택가격에는 이미 `02_real_estate.md`, `12_market_price.md`의 지역/시장 가격구조가 반영되어 있다.

13의 교육환경은:

> 현재 FAMILY 플레이어에게 이 지역/집이 얼마나 매력적인가

라는 Utility에만 사용한다.

가격과 효용을 이중계산하지 않는다.

---

# 27. 교육환경이 한 지역을 정답으로 만들지 않게 한다

강남 등 특정 지역이 교육환경에서 높은 평가를 가질 수 있으나 다음과 trade-off를 유지한다.

- 높은 주거비
- 직장과의 통근
- 집 크기
- 생활환경
- 현재 자산

따라서 FAMILY에서도 `강남 = 무조건 최적해`가 되지 않게 한다.

---

# 28. Household별 주택추천

PARTNER 추천 요소 후보:

- 독립 침실
- 2인 생활공간
- 식사공간
- 수납

FAMILY 추천 요소 후보:

- 방 개수
- 수납
- 욕실
- 아이 공간 확보가능성
- 교육환경
- 공원/생활환경

추천은 가중치일 뿐 계약 제한이 아니다.

작은 집이나 낮은 추천점수 집도 플레이어가 선택할 수 있다.

---

# 29. 직장-주거 Trade-off 확장

라이프스테이지가 생기면 기존의 직장·통근·집 크기 trade-off가 더 복잡해진다.

예:

```text
직장 = 강남
```

선택 A:
- 강남 작은 아파트
- 비쌈
- 통근 좋음
- 교육환경 좋음
- 공간 좁음

선택 B:
- 성동/송파 더 큰 집
- 공간 좋음
- 생활환경 좋음
- 통근 증가

선택 C:
- 외곽 더 넓은 집
- 저렴
- 공간 매우 좋음
- 장거리 통근

지역을 단순 상하 티어가 아니라 현재 Household에 맞는 효용으로 평가한다.

---

# 30. Household Environment 내부평가

기존 생활환경에 다음 내부평가를 추가할 수 있다.

```text
household_space
privacy
family_storage
education_environment
```

사용자에게 반드시 숫자로 노출할 필요는 없다.

자연어 예:

```text
둘이 살기엔 조금 좁아요.
아이 공간이 부족해요.
수납은 넉넉해요.
교육환경이 좋아요.
```

---

# 31. 라이프스테이지와 Happiness

PARTNER/FAMILY 상태 자체가 영구 행복 버프를 주지 않는다.

금지:

```text
PARTNER → HAPPINESS +20 영구
FAMILY → HAPPINESS +30 영구
```

대신:

- 새로운 생활씬
- 좋은 가족공간
- 함께 쓰는 가구
- 공간부족/생활불편

을 통해 `ENERGY / STRESS / HAPPINESS`에 간접 영향을 준다.

가족을 스탯 아이템으로 만들지 않는다.

---

# 32. 랜덤 이별/사망/가족 영구손실 없음

V0.1에서는 다음을 사용하지 않는다.

- 랜덤 이별
- 파트너 사망
- 자녀 사망
- 가족 강제이탈
- 가족상태의 랜덤 영구손실

힐링형 성장게임의 기존 성장을 랜덤으로 제거하지 않는 `10_events.md`의 원칙과 일치시킨다.

향후 플레이어가 직접 관계상태를 바꾸는 콘텐츠는 별도 기획에서 검토할 수 있다.

---

# 33. 자녀 성장단계는 V0.1에서 사용하지 않음

자녀를:

```text
BABY
CHILD
TEEN
ADULT
```

처럼 게임월에 따라 자동 성장시키지 않는다.

V0.1에서는 `CHILD` 하나의 생활역할로 충분하다.

자녀 성장 콘텐츠가 필요해질 경우 게임월 = 실제 연령으로 연결하지 않고 `narrative progression`으로 별도 설계한다.

---

# 34. 가족 생활앨범 연결

`14_healing_social.md`에서 다음 기록을 활용할 수 있다.

- 처음 함께 산 집
- 처음 둘이 꾸민 거실
- 아이 공간을 만든 집
- 첫 가족 식탁
- 가족의 첫 자가
- 오래 살았던 집

`09_moving_inventory.md`의 이사 직전 집 스냅샷과 결합해 플레이어의 주거사/생활사를 남긴다.

---

# 35. 최고급 1주택 이후의 장기 progression

한남 프리미엄 등 현재 게임에서 가장 좋은 거주주택을 구매했다고 게임이 끝나지 않는다.

최상위 거주주택 이후의 장기 질문은 다음처럼 확장한다.

```text
다음에는 어떤 집에서 살아볼까?
↓
다음에는 어떤 삶을 살아볼까?
↓
다음에는 어떤 집을 하나 더 가져볼까?
↓
서울에서 어떤 집들을 내 컬렉션으로 만들어볼까?
```

이 장기 확장은 `16_multi_property.md`에서 상세기획한다.

13에서 확정하는 연결원칙:

- 최고급 1주택은 강제 엔딩이 아니다.
- 현재 거주지는 장기적으로도 1개를 유지한다.
- 향후 여러 주택 보유를 허용할 수 있다.
- 다주택의 1차 목적은 투자수익 극대화보다 주거 컬렉션과 여러 집 꾸미기다.
- 예전에 살던 집을 매도하지 않고 보유하는 선택을 향후 지원한다.
- 각 보유주택은 구입가, 현재시세, 보유기간, 인테리어/배치상태를 보존할 수 있어야 한다.
- 지역/주거유형/희귀 Feature별 컬렉션 progression을 검토한다.
- 초기 다주택 확장에서는 추가주택 현금구매 우선안을 검토한다.
- 임대수익, 투자대출, 공실, 세금 등은 후속 확장으로 둔다.

---

# 36. 다주택과 Household State의 관계

향후 다주택이 열려도 Household의 실제 생활은 `current_residence_id` 한 곳을 기준으로 처리한다.

즉 여러 집을 보유해도:

- 통근
- 생활스탯
- 파트너/가족 자율행동
- 교육환경
- 현재 생활씬

은 현재 거주지 기준이다.

나머지 보유주택은 컬렉션/방문/꾸미기/시세기록 대상이 된다.

세부 보유·방문·가구배치·대출정책은 `16_multi_property.md`에서 확정한다.

---

# 37. 데이터 구조 가안

## 37.1 player_household

```text
player_id
household_state
partner_enabled
child_enabled
state_started_game_month
proposal_cooldown_until_game_month
proposal_disabled
```

## 37.2 household_economy

```text
household_state
partner_contribution
living_cost_modifier
recognized_loan_income_ratio
```

## 37.3 household_housing_preference

```text
household_state
recommended_household_size
space_weight
storage_weight
privacy_weight
education_weight
bathroom_weight
living_environment_weight
```

실제 DB 스키마는 개발단계에서 최종 결정한다.

---

# 38. 어드민 관리 대상

`15_admin.md`에 다음 운영항목을 동기화한다.

## 38.1 Household State Profile

```text
household_state
name
living_cost_modifier
partner_contribution
recognized_loan_income_ratio
recommended_household_size
is_active
```

## 38.2 라이프스테이지 제안 이벤트

관리 대상:

- PARTNER 제안 최소 사회생활개월
- PARTNER 제안 조건
- FAMILY 제안 최소 PARTNER 유지개월
- 제안 cooldown
- 이벤트 문구
- 선택지 문구
- 재제안 여부

## 38.3 Household Housing Preference

관리 대상:

- 공간
- 수납
- 프라이버시
- 교육환경
- 욕실
- 생활환경
- 추천 가중치
- 자연어 안내문구

## 38.4 Household Content Unlock

관리 대상:

- 가구
- 생활씬
- 인테리어 콘텐츠
- 상점 추천카테고리
- 라이프스테이지별 노출/해금

---

# 39. 코드/기획 고정영역

다음은 일반 어드민 조작대상이 아니다.

- 라이프스테이지를 생물학적 나이가 아닌 Household State로 처리하는 구조
- V0.1 `SOLO / PARTNER / FAMILY_WITH_CHILD` 상태구조
- SOLO 완전 장기플레이 허용
- PARTNER/FAMILY를 필수 progression으로 만들지 않는 정책
- 중요 Household 전환의 CHOICE 방식
- 오프라인 자동 Household 전환 금지
- 자가 여부와 Household State 독립
- 작은 집에서도 모든 Household State 거주 가능
- 추천 가구원수 초과를 soft pressure로 처리
- 자녀 실제 연령 progression 없음(V0.1)
- 교육환경을 Utility로만 사용하고 집값에 중복 가산하지 않음
- 랜덤 이별/사망/가족 영구손실 없음
- 게임시간 경과만으로 Household State 자동소멸 금지
- 현재 거주지의 생활효과와 향후 보유주택 컬렉션을 분리하는 방향

---

# 40. QA / 테스트

1. SOLO 상태로 프리미엄 주거까지 정상 progression 가능한가.
2. PARTNER 선택이 경제적으로 필수 선택이 되지 않는가.
3. FAMILY 선택이 순수 패널티가 되지 않는가.
4. PARTNER/FAMILY 상태에서도 작은 집 거주가 가능한가.
5. 작은 집의 불편이 강제퇴거가 아니라 이사욕망으로 연결되는가.
6. Household State 변화 후 `reserved_mandatory_expenses`가 정상 갱신되는가.
7. 파트너 contribution 때문에 첫 자가 progression이 과도하게 빨라지지 않는가.
8. FAMILY 생활비 때문에 progression이 멈추지 않는가.
9. 파트너 contribution 대출 인정으로 대출한도가 폭증하지 않는가.
10. FAMILY에서 교육환경이 의미 있게 느껴지는가.
11. 교육환경이 특정 지역 하나를 무조건 정답으로 만들지 않는가.
12. 가족 전용 가구/생활씬이 실제 주거욕망을 만드는가.
13. 오프라인에서 PARTNER/FAMILY 전환이 자동 실행되지 않는가.
14. 게임 100년/300년 이후에도 생물학적 나이 모순을 생성하지 않는가.
15. 자녀가 게임월에 따라 자동 성장하지 않는가.
16. 복수 자율 캐릭터가 interaction point를 충돌 없이 사용하는가.
17. 이사 직전 가족 주거 스냅샷이 정상 보존되는가.
18. 최고급 1주택 도달 이후에도 16의 장기 주거 컬렉션으로 확장 가능한 데이터구조인가.

---

# 41. V0.1 확정 정책

- 라이프스테이지는 생물학적 나이가 아니라 Household State다.
- V0.1 상태는 `SOLO / PARTNER / FAMILY_WITH_CHILD`다.
- SOLO도 끝까지 정상적인 완성형 플레이다.
- PARTNER/FAMILY는 상위티어나 필수 progression이 아니다.
- PARTNER/FAMILY 전환은 반드시 CHOICE 이벤트로 처리한다.
- 오프라인에서 중요 Household 전환을 자동확정하지 않는다.
- 게임시간은 실제 생물학적 나이와 연결하지 않는다.
- 노화/사망을 사용하지 않는다.
- 자녀 실제 연령 progression은 V0.1에서 사용하지 않는다.
- 작은 집에서도 PARTNER/FAMILY 거주를 허용한다.
- 큰 집은 hard gate가 아니라 soft desire다.
- recommended household size는 추천/불편 계산에 사용하고 강제 입주제한에는 사용하지 않는다.
- 파트너는 별도 커리어 시뮬레이션 대신 household contribution을 제공한다.
- 파트너 contribution은 플레이어 salary와 구분한다.
- Household State에 따라 생활비가 증가한다.
- PARTNER/FAMILY가 새로운 가구, 생활씬, 인테리어 욕망을 연다.
- FAMILY에서 교육환경 Utility를 활성화한다.
- 교육환경은 주택가격에 다시 가산하지 않는다.
- 자가 여부와 Household State를 독립시킨다.
- 랜덤 이별/사망/가족 영구손실을 사용하지 않는다.
- PARTNER/FAMILY 자체가 영구 행복 버프를 주지 않는다.
- 가족의 가치는 생활씬과 공간사용 변화로 표현한다.
- 수백 게임년이 지나도 Household State는 시간 때문에 자동소멸하지 않는다.
- 최고급 1주택은 게임의 강제 엔딩이 아니다.
- 최고급 1주택 이후 장기 progression은 `16_multi_property.md`의 다주택/주거 컬렉션으로 확장한다.
