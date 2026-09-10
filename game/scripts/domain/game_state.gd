class_name GameState
## 진짜 MVP 게임 상태 — 00/01/07/08/10 규칙 구현.
## 순수 로직(노드 아님): 욕구 체인, 부업, 월 정산, 이벤트, 스탯, 만족도, 세이브.
##
## 경제(01 §5): 월급 300만 − (월세80+관리비15+생활비110+기타20=225만) = 가처분 75만
## 부업(08): 20만/회 × 최대 5회/게임월
## 스탯(07): ENERGY/STRESS/HAPPINESS 0~100 + 지금 집 만족도 보조표시
## 이벤트(10 V0.1): RANDOM 월 40~60%, 소규모 위주

signal desire_progressed(desire_index: int)

const SALARY := 3_000_000
const MONTHLY_EXPENSES := 2_250_000          # 월세80 + 관리비15 + 생활비110 + 기타20
const START_CASH := 4_500_000                # 00 §9 가안 기준 첫 돈
const SIDEJOB_REWARD := 200_000              # 08 §2
const SIDEJOB_MAX_PER_MONTH := 5

# 욕구 체인 (00 §9: 최소가구 → 욕망가구 → …). items: 완료에 필요한 가구 id 복수 가능
const DESIRES := [
	{
		"id": "bed", "name": "잠자리", "items": ["bed_single"],
		"line": "하루 종일 서 있었네… 제대로 잘 수 있는 침대가 필요해.",
		"happiness": 15,
	},
	{
		"id": "sofa", "name": "쉼터", "items": ["sofa_two"],
		"line": "벽에 기대 앉는 것도 지쳤어. 소파에 앉아 쉬고 싶다.",
		"happiness": 15,
	},
	{
		"id": "workspot", "name": "일터", "items": ["desk_small", "chair_basic"],
		"line": "재택근무 때마다 침대에 누워 일하니 자꾸 졸려… 책상이 필요해.",
		"happiness": 12,
	},
	{
		"id": "cozy", "name": "온기", "items": ["plant_monstera", "floor_lamp"],
		"line": "방이 너무 삭막하고 어두워. 식물이랑 따뜻한 조명이면 좀 나을까?",
		"happiness": 12,
	},
	{
		"id": "entertain", "name": "여유", "items": ["tv_43"],
		"line": "퇴근하고 아무것도 안 하는 밤이 외로워… TV가 있다면!",
		"happiness": 18,
	},
]

# 이벤트 풀 (10 V0.1: 소규모 AUTO/RECORD 위주)
const EVENTS := [
	{"text": "급식 맛집을 발견했다. 점심이 행복하다.", "cash": 0, "energy": 5, "stress": -3, "happiness": 3},
	{"text": "친구와 맛집 탐방. 좋은 밤이었다.", "cash": -30_000, "energy": -3, "stress": -5, "happiness": 6},
	{"text": "마트 적립 포인트가 쌓여 있었다.", "cash": 50_000, "happiness": 1},
	{"text": "지하철이 계속 지연됐다. 피곤한 아침.", "energy": -5, "stress": 6},
	{"text": "감기에 걸렸다. 약국 비용과 뻐근한 하루.", "cash": -20_000, "energy": -8, "stress": 3},
	{"text": "옷 수선비를 지불했다. 생각보다 비쌌다.", "cash": -30_000, "stress": 2},
	{"text": "회사에서 좋은 평가를 받았다. 뿌듯한 하루.", "stress": -4, "happiness": 5},
	{"text": "퇴근길 노을이 예뻤다. 잠깐 걸었다.", "stress": -5, "happiness": 2},
]

# 부업 이름 풀 (08 §17: 짧은 플레이버)
const SIDEJOBS := ["문서 정리", "카페 서빙", "데이터 라벨링", "홍보물 배포", "행사 서포트"]

var month: int = 1
var cash_balance: int = START_CASH
var energy := 70
var stress := 40
var happiness := 55
var desire_index := 0
var purchased := {}          # furniture id -> true (구매+배치 완료)
var sidejobs_used := 0
var month_sidejob_income := 0
var last_event: Dictionary = {}
var goal_done := false


func spendable_cash() -> int:
	return maxi(0, cash_balance - MONTHLY_EXPENSES)


func shortfall(amount: int) -> int:
	return maxi(0, amount - spendable_cash())


## 현재 욕구가 완료되었는가 (필요 가구 전부 구매)
func desire_done(di: int = -1) -> bool:
	var i := di if di >= 0 else desire_index
	if i >= DESIRES.size():
		return true
	for fid in DESIRES[i]["items"]:
		if not purchased.has(fid):
			return false
	return true


## 현재 욕구의 남은 가구 id 목록
func desire_remaining() -> Array:
	var out: Array = []
	if desire_index < DESIRES.size():
		for fid in DESIRES[desire_index]["items"]:
			if not purchased.has(fid):
				out.append(fid)
	return out


## 가구 구매 확정 시: 욕구 진행/완료 처리. 반환: 완료된 욕구(없으면 빈 dict)
func on_furniture_owned(fid: String) -> Dictionary:
	purchased[fid] = true
	happiness = mini(100, happiness + 2)   # 일반 가구 구매도 소폭 행복(07 §3.3)
	if desire_done() and desire_index < DESIRES.size():
		var d: Dictionary = DESIRES[desire_index]
		happiness = mini(100, happiness + int(d["happiness"]))
		stress = maxi(0, stress - 8)         # 좋은 집은 회복공간(07)
		desire_index += 1
		if desire_index >= DESIRES.size():
			goal_done = true
		desire_progressed.emit(desire_index)
		return d
	return {}


## 배치 취소(환불) 시 소유 철회 — on_furniture_owned의 역연산
func undo_furniture_owned(fid: String, completed_desire: Dictionary) -> void:
	purchased.erase(fid)
	happiness = maxi(0, happiness - 2)
	if not completed_desire.is_empty():
		happiness = maxi(0, happiness - int(completed_desire["happiness"]))
		stress = mini(100, stress + 8)
		desire_index = maxi(0, desire_index - 1)
		goal_done = false


## 부업 (08): 성공 시 true
func do_sidejob() -> bool:
	if sidejobs_used >= SIDEJOB_MAX_PER_MONTH:
		return false
	sidejobs_used += 1
	month_sidejob_income += SIDEJOB_REWARD
	cash_balance += SIDEJOB_REWARD
	energy = maxi(0, energy - 3)            # 부업은 체력 소모(07 §3.1)
	return true


## 지금 집 만족도 (07 §8: 보조 표시) — 완료 욕구 비중 + 배치 가구 수
func room_satisfaction() -> float:
	var fulfilled := float(desire_index)
	var placed_extra := 0
	for fid in purchased:
		var is_desire := false
		for d in DESIRES:
			if fid in d["items"]:
				is_desire = true
				break
		if not is_desire:
			placed_extra += 1
	return clampf((fulfilled + placed_extra * 0.3) / DESIRES.size(), 0.0, 1.0)


func satisfaction_label() -> String:
	var s := room_satisfaction()
	if s >= 0.99:
		return "매우 좋음"
	if s >= 0.6:
		return "좋음"
	if s >= 0.3:
		return "보통"
	return "삭막함"


## 월 정산 (01/04/10): 이번 달 현금흐름+스탯+이벤트 종합. 반환: 정산 리포트
func settle_month() -> Dictionary:
	# 이벤트 판정 (RANDOM 40~60% → 50% 채택)
	last_event = {}
	if randf() < 0.5:
		last_event = EVENTS[randi() % EVENTS.size()]
		cash_balance += int(last_event.get("cash", 0))
		energy = clampi(energy + int(last_event.get("energy", 0)), 0, 100)
		stress = clampi(stress + int(last_event.get("stress", 0)), 0, 100)
		happiness = clampi(happiness + int(last_event.get("happiness", 0)), 0, 100)

	# 월급/지출
	cash_balance += SALARY - MONTHLY_EXPENSES

	# 스탯 월 정산: 기본 소모 + 방 회복력(07: 가구↑ → 스트레스 회복↑)
	energy = clampi(energy - 5, 0, 100)
	stress = clampi(stress + 8, 0, 100)
	var relax := mini(purchased.size(), 8)   # 배치 가구 수만큼 회복
	stress = maxi(0, stress - relax)
	if room_satisfaction() >= 0.6:
		happiness = mini(100, happiness + 5)

	month += 1
	sidejobs_used = 0
	var report := {
		"month": month,
		"income": SALARY,
		"expenses": MONTHLY_EXPENSES,
		"sidejob": month_sidejob_income,
		"event": last_event,
		"energy": energy, "stress": stress, "happiness": happiness,
	}
	month_sidejob_income = 0
	return report


## 구매 가능 여부 (배치 비용 검사는 spendable 기준)
func can_afford(amount: int) -> bool:
	return amount <= spendable_cash()


func try_spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	cash_balance -= amount
	return true


# ---------------------------------------------------------------- 세이브/로드
const SAVE_PATH := "user://mvp_save.json"

func to_dict() -> Dictionary:
	return {
		"month": month, "cash_balance": cash_balance,
		"energy": energy, "stress": stress, "happiness": happiness,
		"desire_index": desire_index, "purchased": purchased.keys(),
		"goal_done": goal_done,
	}


func from_dict(d: Dictionary) -> void:
	month = int(d.get("month", 1))
	cash_balance = int(d.get("cash_balance", START_CASH))
	energy = int(d.get("energy", 70))
	stress = int(d.get("stress", 40))
	happiness = int(d.get("happiness", 55))
	desire_index = int(d.get("desire_index", 0))
	purchased.clear()
	for fid in d.get("purchased", []):
		purchased[fid] = true
	goal_done = bool(d.get("goal_done", false))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(to_dict()))


## 배치 목록을 포함한 전체 저장 (UI가 placements를 넘김)
func save_game_with(placements: Array) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"game": to_dict(), "placements": placements}))


static func load_game() -> GameState:
	var gs := GameState.new()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			if parsed.has("game"):
				gs.from_dict(parsed["game"])
			else:
				gs.from_dict(parsed)
	return gs
