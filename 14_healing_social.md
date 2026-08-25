# 14_healing_social.md
기준일: 2026-08-25
상태: V0.2 상세기획 확정

# 1. 문서 목적

이 문서는 `방 한 칸에서 한남동까지`의 계절·날씨·시간대 감성연출, 특별 생활씬 발견, 생활앨범, 주거역사, Photo Mode, 외부 공유카드와 향후 게임 내 집구경 소셜을 정의한다.

핵심 원칙:

> 생활씬은 보상을 얻기 위해 보는 것이 아니라, 내가 만든 집에서 살아가는 모습을 보기 위해 존재한다.

> 공유는 자산순위를 자랑하는 기능보다 `내가 만든 집과 내가 살아온 집들`을 보여주는 기능이어야 한다.

> 14는 생활씬을 발생시키는 엔진이 아니라, 07에서 발생한 생활을 더 보고 싶게 만들고 발견·기록·공유하는 시스템이다.

---

# 2. 07과 14의 역할 분리

`07_character_life.md`:

- ENERGY / STRESS / HAPPINESS
- 자율행동 선정
- 생활씬 조건매칭
- 가구 Interaction
- 반복방지
- 생활씬 회복효과

`14_healing_social.md`:

- 계절/날씨/시간대 연출 정책
- 특별 생활씬 최초발견
- 생활앨범
- 주거 성장기록
- 집 사진/스냅샷 표시
- 외부 공유카드
- 다주택 주거도감/대표집 공유
- 향후 다른 플레이어 집구경/큐레이션

---

# 3. 계절은 플레이어 게임시간 기준

현실 계절과 연동하지 않는다.

V0.1 기본:

```text
SPRING
SUMMER
AUTUMN
WINTER
```

- 게임 3개월 = 계절 1개
- 게임 12개월 = 사계절 1회
- 이후 반복

```text
season_index = floor(game_month / 3) % 4
```

24개월 임대계약 동안 사계절을 대략 두 번 경험한다.

---

# 4. 계절의 역할

경제최적화보다 감성콘텐츠 우선.

영향:

- 창밖 풍경
- 자연광/색감
- 집 내부 조명
- 캐릭터 의상 연출
- 생활씬 조건
- 계절 소품/가구
- 배경음/환경음

계절 때문에 난방비/냉방비를 크게 흔드는 것은 V0.1 핵심이 아니다.

---

# 5. 날씨

```text
CLEAR
CLOUDY
RAIN
SNOW
```

현실 서울 날씨와 연동하지 않는다.

계절별 weight를 다르게 관리한다.

예:

- SPRING: CLEAR/CLOUDY/RAIN
- SUMMER: CLEAR/CLOUDY/RAIN
- AUTUMN: CLEAR/CLOUDY/RAIN
- WINTER: CLEAR/CLOUDY/SNOW + 낮은 RAIN

정확 weight는 어드민.

---

# 6. 날씨 변경주기

`07_character_life.md`의 생활주기 하나 동안 하나의 날씨를 유지한다.

실시간 몇 분마다 무작위로 뒤집지 않는다.

---

# 7. 시간대

```text
MORNING
DAY
EVENING
NIGHT
```

현실 현지시각이 아니라:

- 조명
- 행동 가중치
- 생활씬 조건
- 환경음

을 위한 연출축이다.

---

# 8. 현실시간 연동 금지

V0.1에서는:

- 현실계절 → 게임계절
- 현실날씨 → 게임날씨
- 현실시각 → 게임 시간대

강제연동 없음.

---

# 9. 생활씬 타입

```text
DAILY
COMBINATION
SEASONAL
MILESTONE
HOUSEHOLD
```

DAILY 반복행동은 대부분 앨범 대상이 아니다.

COMBINATION/SEASONAL/MILESTONE/HOUSEHOLD의 대표씬을 발견/기록에 활용한다.

---

# 10. 모든 행동을 앨범화하지 않음

자동등록 후보:

- 특별 생활씬 최초발견
- 주요 MILESTONE
- Household milestone
- 매도/퇴거 전 최종 주거 스냅샷
- 첫 자가
- 희귀 Feature 대표씬

비등록 기본:

- 반복 DAILY
- 동일씬 반복
- 단순 이동/청소/샤워

---

# 11. 최초발견 연출

생활씬을 방해하지 않는 작은 알림.

```text
✨ 새로운 생활 장면
비 오는 밤의 영화
[앨범 보기]
```

전체화면 강제팝업/시간정지는 하지 않는다.

---

# 12. 최초발견 보상

- HAPPINESS 소량
- 앨범 등록
- 발견수 증가
- 프로필/공유 배경 등 비경제 보상 가능

큰 현금보상 없음.

생활씬을 돈 파밍으로 만들지 않는다.

---

# 13. 생활앨범 기본 구조

V0.2 기본 탭:

```text
[현재 거주지]
[생활 장면]
[내 집]
[서울 주거 도감]
[주거 역사]
```

다주택 기능이 비활성인 초기 단계에서는 `내 집/주거 도감`을 숨기거나 단순화할 수 있다.

---

# 14. 현재 거주지

current residence의:

- 수동 Photo
- 대표 생활씬
- 입주 당시/현재 Before-After
- Household 생활기록

을 본다.

`16_multi_property.md`에 따라 실제 생활효과는 current residence 1곳 기준이다.

---

# 15. 생활 장면

발견한 특별씬을 카테고리별로 본다.

후보:

- 계절
- 주거단계
- Feature
- SOLO
- PARTNER
- FAMILY

---

# 16. `내 집` — 현재 보유주택

`16_multi_property.md`의 현재 `OWNED_PROPERTY`를 보여준다.

각 집 후보정보:

- 대표 이미지
- 지역/주거유형
- current residence 여부
- FEATURED_PROPERTY 여부
- purchase_price
- current_market_value
- ownership_duration
- Maintenance 상태

보유집은 과거 스냅샷이 아니라 실제 방문/꾸미기가 가능한 Live Property다.

---

# 17. 서울 주거 도감

`16_multi_property.md`에서 한번이라도 소유해 획득한 대표 컬렉션을 영구 기록한다.

카테고리:

- 지역
- 주거유형
- 희귀 Feature
- 대표 floorplan

예:

```text
지역          9 / 10
주거유형      7 / 7
희귀 Feature  6 / 10
대표 평면    24 / 35
```

이 도감은 다주택의 의도적인 completion 콘텐츠이므로 카테고리별 완성률을 표시할 수 있다.

PARTNER/FAMILY 선택형 앨범과는 다른 성격이다.

---

# 18. 주거 역사

`09_moving_inventory.md`의 매도/퇴거 직전 최종 스냅샷을 사용한다.

예:

```text
첫 원룸
서대문 · 7평
사회생활 0년 0개월 ~ 2년 0개월
당시 직장: 광화문 안정기업
[마지막 모습]
```

집을 보유한 채 current residence만 옮긴 경우에는 과거집으로 닫지 않고 `내 집`에 계속 유지한다.

해당 집을 매도하는 순간 최종 스냅샷을 만들고 주거역사에 종료기록을 남긴다.

---

# 19. 주거역사에 그때의 삶 저장

후보:

```text
region_id
housing_type
size_pyeong
contract_type
move_in_game_month
move_out_game_month
career_state
household_state
representative_scene_id
purchase_price
sale_price
ownership_duration
```

보유중이면 current_market_value는 `내 집`에서 실시간 표시.

---

# 20. 장기 시세/보유기록

12/16과 연결.

예:

```text
첫 자가
구입가 4억 2천
현재시세 37억 8천
보유 196년
```

또는 매도완료:

```text
구입 4억 2천
매도 7억 1천
총 보유 41년
```

극장기 기록을 오류가 아니라 개인 세계의 역사로 취급한다.

---

# 21. Photo Mode

실제 현재 편집중인 집의 Grid/가구상태를 기반으로 한다.

최소:

- UI 숨기기
- 줌
- 카메라 이동
- 프레임 조절
- 내부 앨범 저장
- 공유카드 연결

다주택에서는 current residence뿐 아니라 방문 중인 OWNED_PROPERTY에서도 Photo Mode 사용 가능.

---

# 22. 수동 Photo 저장 제한

V0.1 테스트값:

```text
manual_photo_save_limit_per_game_month = 3
manual_photo_save_limit_per_house = 20
```

정책:

- 게임월당 수동 저장 기본 3장
- 집별 동시보관 수동사진 기본 20장
- 삭제 후 새 저장 가능
- 자동 생활씬/최종 주거스냅샷은 수동한도 미차감
- OS 스크린샷 통제 안 함
- Photo Mode 진입/구도조절은 무제한, 내부저장만 제한

다주택에서도 `per_house` 한도는 property별 독립 적용하고 게임월 전체 수동저장 한도는 플레이어 단위로 적용한다.

---

# 23. 공유카드 유형

V0.2:

```text
HOME_CARD
MOVE_CARD
MILESTONE_CARD
LIFE_SCENE_CARD
HISTORY_CARD
MARKET_HISTORY_CARD
PROPERTY_COLLECTION_CARD
```

16 확정으로 `PROPERTY_COLLECTION_CARD`는 더 이상 단순 미래 후보가 아니라 다주택 활성화 시 사용하는 카드유형으로 본다.

---

# 24. HOME_CARD / FEATURED_PROPERTY

HOME_CARD 기본은 current residence.

다주택에서는 `FEATURED_PROPERTY`를 별도로 지정해 프로필/집자랑 카드의 대표집으로 사용할 수 있다.

FEATURED_PROPERTY는 소셜 표시용이며:

- 통근
- 생활스탯
- Household Utility

에 영향 없음.

---

# 25. MOVE / MILESTONE CARD

후보:

- 새집 이사
- 첫 전세
- 첫 자가
- 한남 입성
- 첫 다주택
- 10번째 보유주택
- 첫 지역컬렉션 완성
- Household 첫 동거집/가족 첫 자가

큰 현금보상과 연결하지 않는다.

---

# 26. LIFE_SCENE_CARD

특별씬 대표컷 공유.

경제보상 없음.

---

# 27. HISTORY / Before-After

핵심 공유콘텐츠.

- 첫 입주 vs 현재
- 첫 원룸 vs 현재집
- 첫 자가 구입 당시 vs 현재 보유상태
- 매도한 집 첫 입주 vs 최종 모습

09의 스냅샷 + 현재 Live Property를 사용한다.

---

# 28. PROPERTY_COLLECTION_CARD

다주택/도감 공유카드.

예:

```text
나의 서울 주거 컬렉션
사회생활 127년 차
현재 보유 12채
지역 8/10
주거유형 7/7
Feature 9/12
```

또는:

```text
내가 가장 오래 가진 집
서대문 첫 자가
196년 보유중
```

집 수/자산을 경쟁 랭킹으로 연결하지 않는다.

---

# 29. MARKET_HISTORY_CARD

예:

```text
사회생활 327년 차
게임 시작 당시 서대문 아파트 4.2억
현재 동일급 48.7억
```

또는 보유집:

```text
첫 자가 4.2억 → 현재 37.8억
```

수백년의 숫자 자체도 공유거리로 허용.

---

# 30. 자산숫자 우선순위

공유 기본 우선:

```text
집 이미지
→ 주거 변화
→ 생활 장면
→ 기록
→ 자산 숫자
```

총 주택순자산/보유주택 수를 소셜 점수로 사용하지 않는다.

---

# 31. 게임 내 소셜은 MVP 후순위

MVP에서 친구/팔로우/댓글/DM/실시간피드/자산랭킹을 한꺼번에 만들지 않는다.

우선:

> 개인 기록 + 외부 공유

후속 첫 소셜:

> 다른 플레이어 집 구경

---

# 32. 집구경과 대표집

후속 게임 내 소셜에서는 current residence와 FEATURED_PROPERTY 중 플레이어가 공개 대상으로 선택한 집을 노출할 수 있다.

다주택 전체를 자동 공개하지 않는다.

플레이어가 대표집을 바꿀 수 있다.

---

# 33. Reaction

후보:

```text
포근해요
살아보고 싶어요
아이디어 얻었어요
```

Reaction은 현금/월급/행복/집값에 직접 보너스 없음.

---

# 34. 자산랭킹 없음

금지 기본:

- 자산 TOP 100
- 가장 비싼 집
- 순자산 순위
- 보유주택 수 순위

---

# 35. 인기집은 테마 큐레이션

예:

- 이번 주 작은 집
- 최고의 구축
- 포근한 거실
- 예쁜 테라스
- 겨울집
- 원룸 잘 꾸미기
- 오래 보유한 추억의 집

집값/자산/보유수는 추천점수 직접신호로 쓰지 않는다.

---

# 36. 다양성 보정

- 동일 플레이어 연속노출 감소
- 동일 집 반복노출 감소
- 한남/고가집 독식 방지
- 주거단계 다양성
- 지역 다양성
- 작은집 슬롯

---

# 37. 타인의 집에서 가구 발견

다른 집 가구 선택 → 상품정보/상점 이동.

전체 인테리어 자동복사는 후순위.

---

# 38. 미발견 생활씬 / 힌트

실루엣/빈 슬롯 가능.

힌트 예:

```text
욕조가 있는 집에서 겨울밤을 보내보세요.
```

```text
테라스가 있는 집에서 여름 아침을 보내보세요.
```

목적은 공략이 아니라 새 집/가구/Feature 욕망 생성.

---

# 39. 생활앨범 → 주거욕망 루프

```text
미발견 장면
→ 필요한 Feature/집/가구 인지
→ 새 주거욕망
→ 경제/매물/꾸미기 루프로 복귀
```

다주택 이후에는:

```text
이미 좋은 집에 거주
→ 다른 Feature 생활씬을 위해 추가집 탐색
```

도 가능.

---

# 40. Household 카테고리 완성률

SOLO/PARTNER/FAMILY는 별도 카테고리.

PARTNER/FAMILY를 선택하지 않았다는 이유로 전체 게임완성률을 낮게 표시하지 않는다.

반대로 `서울 주거 도감`은 의도적인 수집 progression이므로 완성률 표시 가능.

---

# 41. 주거단계 생활앨범

- 옥탑
- 원룸
- 투룸
- 아파트
- 자가
- 테라스
- 프리미엄

과거단계 생활씬을 다시 보고 싶게 할 수 있다.

다주택 Live Property가 있으면 예전집을 재방문해 꾸미기/Photo/후속 확장 생활씬에 사용할 수 있다.

---

# 42. 다주택과 생활씬

V0.1 기본:

> 자율 Household 생활씬은 current residence에서만.

비거주 보유집 방문은 꾸미기/Photo/관리 확인 중심.

`16_multi_property.md` 후속의 `SECOND_HOME_STAY`가 도입될 경우에만 별장형 임시 생활씬을 확장한다.

즉 현재 문서의 예전 `겨울에는 서촌집/여름에는 테라스집`은 자동 동시생활이 아니라 후속 SECOND_HOME_STAY 방향으로 해석한다.

---

# 43. 생활/주거 타임라인

예:

```text
0년 0개월  첫 직장
0년 1개월  첫 원룸
18년 7개월 첫 자가
31년 2개월 PARTNER
52년 8개월 한남 입성
70년 3개월 첫 추가주택
127년 0개월 보유 12채
```

생물학적 연령이 아니라 사회생활/주거 역사.

---

# 44. 개인정보/Moderation

초기 게임 내 소셜에서는:

- 실명
- 연락처
- DM
- 과도한 자유텍스트

를 우선하지 않는다.

닉네임 + 집 + preset Reaction 중심.

공개 UGC가 생기면 신고/차단/moderation 필수.

---

# 45. 소셜 BM 원칙

사용하지 않음:

- 유료 Reaction 부스트
- 광고로 인기집 상단노출
- 유료 랭킹
- 유료 방문권

자연스러운 연결:

```text
다른 집에서 가구 발견
→ 상점에서 보기
```

---

# 46. 최소 데이터 구조

## life_album_entry

```text
album_entry_id
player_id
scene_id
first_discovered_game_month
house_id
household_state
season
weather
time_band
snapshot_asset
```

## housing_history_entry

```text
history_id
player_id
house_id
move_in_game_month
move_out_game_month
contract_type
region_id
snapshot_id
career_state
household_state
purchase_price
sale_price
ownership_duration
```

## photo

```text
photo_id
player_id
house_id
game_month
camera_state
snapshot_asset
source_type
```

```text
MANUAL
AUTO_LIFE_SCENE
AUTO_MOVE_HISTORY
```

## share_card

```text
share_card_id
card_type
source_id
template_id
generated_asset
generated_game_month
```

다주택 컬렉션 원본 데이터는 16의 property/collection 구조를 참조한다.

---

# 47. 어드민

`15_admin.md #38`과 다주택 `#39`를 함께 사용한다.

14 관리:

- 계절/날씨
- 앨범 scene/category
- 힌트
- 수동 Photo 한도
- 공유카드 템플릿
- 큐레이션/Reaction

16/39 관리:

- 주거 도감 카테고리/slot
- collection reward
- FEATURED_PROPERTY 관련 copy
- 다주택 공유카드 표시항목

---

# 48. 코드/기획 고정

- 현실 계절/날씨 연동 없음
- 계절은 게임시간 기준
- 생활씬 발생은 07, 발견/기록/공유는 14
- 반복 DAILY 전부 앨범화 안 함
- 매도/퇴거 최종 스냅샷은 09
- 보유중 property는 Live House로 유지
- PARTNER/FAMILY 미선택을 전체 앨범 미완성 취급 안 함
- 주거 도감은 의도적 completion이므로 완성률 허용
- 자산순위 랭킹 없음
- Reaction/인기집 경제보너스 없음
- Photo 내부저장만 제한, OS 스크린샷 통제 안 함
- current residence와 FEATURED_PROPERTY 역할 분리

---

# 49. MVP 범위

우선:

- 게임 계절/날씨/시간대
- 특별씬 발견
- 생활앨범
- 주거역사
- 제한형 Photo
- 외부 공유

다주택이 출시범위에 들어가면 추가:

- 내 집
- 서울 주거 도감
- PROPERTY_COLLECTION_CARD
- FEATURED_PROPERTY 공유

게임 내 SNS는 후순위.

---

# 50. QA

1. 사계절/날씨가 정상 반복되는가.
2. 현실 계절/날씨가 개입하지 않는가.
3. 최초발견만 정상 앨범화되는가.
4. DAILY 반복이 앨범을 오염시키지 않는가.
5. 매도/퇴거 최종 스냅샷이 주거역사에 들어가는가.
6. 기존집 보유이사 시 해당 집이 주거역사 종료집으로 잘못 닫히지 않는가.
7. 보유중 모든 property가 `내 집`에 표시되는가.
8. 매도하면 `내 집`에서 빠지고 `주거 역사/도감`은 유지되는가.
9. 서울 주거 도감이 지역/유형/Feature/대표평면 기준으로 누적되는가.
10. PARTNER/FAMILY 미선택이 전체 미완성으로 보이지 않는가.
11. 수동Photo 게임월 3장/집별20장 기본한도가 정상인가.
12. 다주택에서 집별 Photo 한도가 독립인가.
13. 플레이어 전체 월 수동Photo 한도는 여러 집 합계에 적용되는가.
14. current residence와 FEATURED_PROPERTY가 독립적으로 동작하는가.
15. 대표집 변경이 생활효과를 바꾸지 않는가.
16. PROPERTY_COLLECTION_CARD가 실제 도감/보유값을 사용하는가.
17. 장기 보유기간/시세 공유가 정상인가.
18. 자산랭킹이 생기지 않는가.
19. 큐레이션에서 고가집 독식이 방지되는가.
20. 비거주집에서 Household 자율생활이 동시에 돌지 않는가.

---

# 51. V0.2 확정 정책

- 14는 생활씬 발생엔진이 아니라 발견·기록·공유 시스템이다.
- 계절은 게임시간 기준 3개월씩, 12개월 사계절 반복을 기본으로 한다.
- 현실 계절/날씨/시각과 강제연동하지 않는다.
- 날씨는 계절별 weight로 결정하고 생활주기 동안 유지한다.
- 특별씬 최초발견과 milestone 중심으로 앨범화한다.
- 기본 UI는 현재 거주지 / 생활 장면 / 내 집 / 서울 주거 도감 / 주거 역사로 확장한다.
- 기존집을 보유한 채 이사하면 그 집은 과거 스냅샷이 아니라 Live Property로 `내 집`에 남는다.
- 집을 매도/퇴거하면 최종 스냅샷을 주거역사에 보존한다.
- Photo Mode는 current residence와 모든 보유주택에서 사용 가능하다.
- 수동 Photo 저장은 게임월 3장, 집별 20장을 기본 테스트값으로 둔다.
- 외부 공유카드에 PROPERTY_COLLECTION_CARD / MARKET_HISTORY_CARD를 포함한다.
- FEATURED_PROPERTY를 current residence와 분리해 대표집 공유에 사용할 수 있다.
- 주거 도감은 지역/주거유형/Feature/대표평면의 의도적 completion 콘텐츠다.
- PARTNER/FAMILY 미선택은 전체 앨범 미완성으로 취급하지 않는다.
- 자산/보유주택 수 랭킹은 만들지 않는다.
- 게임 내 소셜은 후순위이며 집구경/테마 큐레이션을 우선한다.
- 다주택의 기본 Household 자율생활은 current residence에서만 진행하고, 별장형 생활은 SECOND_HOME_STAY 후속확장으로 둔다.
