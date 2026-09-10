class_name GameState
## "방 한 칸에서 한남동까지" MVP 게임 상태 v2 — 기획 00/01/02/03/04/07/08/10 기반.
## 순수 로직: 시간/직장/매물/계약/욕구/부업/월정산/이벤트/스탯/보관함/세이브(오프라인).
##
## 경제(01§5): 월급 − (월세+관리비+생활비110+기타20) = 가처분
## 시간(04§2): 활성 시간으로 게임월 진행. 중요 결정 중 정지. 오프라인 최대 3개월(04§4)
## 부업(08§7/9): 1회 보상 = 월 가처분 20%, 횟수 = 회사 기본값(광화문6/구로5/강남3) + 통근보정
## 계약(04§12): 24개월. 만료 3개월 전 안내 → 재계약/이사 선택

signal month_advanced(report: Dictionary)
signal contract_warning(months_left: int)

## 1 게임월 = 현실 활성 180초 (문서 기준값 1800초=30분, 테스트 가속. live 밸런스 시 1800으로)
const MONTH_SECONDS := 180.0
const OFFLINE_MONTH_CAP := 3          # 04§4
const CONTRACT_LENGTH := 24           # 04§12

# 첫 직장 3종 (03§3)
const COMPANIES := [
	{"id": "gwanghwamun", "name": "광화문 안정기업", "salary": 3_000_000,
		"district": "광화문", "workload": 2, "stability": 4, "growth": 2,
		"sidejobs": 6, "desc": "시간형 · 월급 300만 · 부업 기회 많음"},
	{"id": "guro", "name": "구로 IT기업", "salary": 3_300_000,
		"district": "구로", "workload": 3, "stability": 3, "growth": 4,
		"sidejobs": 5, "desc": "균형형 · 월급 330만 · 성장 좋음"},
	{"id": "gangnam", "name": "강남 스타트업", "salary": 3_700_000,
		"district": "강남", "workload": 4, "stability": 2, "growth": 5,
		"sidejobs": 3, "desc": "성장형 · 월급 370만 · 강도 높음"},
]

# 첫 매물 후보 (02§9: 같은 trade-off를 보여주는 4~6개)
const LISTINGS := [
	{"id": "gwanak_small", "name": "관악 신림 원룸", "region": "관악구", "size": "9평",
		"rent": 550_000, "maintenance": 70_000, "commute": 55, "desc": "저렴하지만 통근 김"},
	{"id": "gwanak_new", "name": "관악 신축 원룸", "region": "관악구", "size": "8평",
		"rent": 700_000, "maintenance": 100_000, "commute": 50, "desc": "깔끔한 신축, 조금 비쌈"},
	{"id": "guro_close", "name": "구로 직주근접 원룸", "region": "구로구", "size": "7평",
		"rent": 650_000, "maintenance": 80_000, "commute": 15, "desc": "회사까지 15분, 작은 집"},
	{"id": "mapo_nice", "name": "마포 한뷰 옥탑", "region": "마포구", "size": "10평",
		"rent": 850_000, "maintenance": 60_000, "commute": 40, "desc": "넓고 감성적, 월세 높음"},
]

## const 템플릿은 수정 불가 → 인스턴스는 복제해서 사용
static func company_by_id(id: String) -> Dictionary:
	for c in COMPANIES:
		if c["id"] == id:
			return c.duplicate()
	return COMPANIES[0].duplicate()


static func listing_by_id(id: String) -> Dictionary:
	for l in LISTINGS:
		if l["id"] == id:
			return l.duplicate()
	return LISTINGS[0].duplicate()


# 통근 보정 (08§9 V0.1)
static func commute_sidejob_adj(commute_min: int) -> int:
	if commute_min <= 20: return 1
	if commute_min <= 40: return 0
	if commute_min <= 60: return -1
	if commute_min <= 80: return -2
	return -3

const LIVING_COST := 1_100_000   # 생활비 110 (01§5)
const MISC_COST := 200_000       # 기타 20 (01§5)
const START_CASH := 4_500_000

# 욕구 체인 (00§9 첫 세션 흐름 — 콘텐츠 가이드)
const DESIRES := [
	{"id": "bed", "name": "잠자리", "items": ["bed_single"],
		"line": "하루 종일 서 있었네… 제대로 잘 침대가 필요해.", "happiness": 15},
	{"id": "sofa", "name": "쉼터", "items": ["sofa_two"],
		"line": "벽에 기대 앉는 것도 지쳤어. 소파가 있으면 좋겠다.", "happiness": 15},
	{"id": "workspot", "name": "일터", "items": ["desk_small", "chair_basic"],
		"line": "재택근무 때마다 침대에서 일하니 자꾸 졸려…", "happiness": 12},
	{"id": "cozy", "name": "온기", "items": ["plant_monstera", "floor_lamp"],
		"line": "방이 삭막하고 어두워. 식물이랑 따뜻한 조명이면 나을까?", "happiness": 12},
	{"id": "entertain", "name": "여유", "items": ["tv_43"],
		"line": "퇴근하고 아무것도 안 하는 밤이 외로워… TV가 있다면!", "happiness": 18},
]

const EVENTS := [
	{"text": "급식 맛집을 발견했다. 점심이 행복하다.", "cash": 0, "energy": 5, "stress": -3, "happiness": 3},
	{"text": "친구와 맛집 탐방. 좋은 밤이었다.", "cash": -30_000, "energy": -3, "stress": -5, "happiness": 6},
	{"text": "마트 적립 포인트가 쌓여 있었다.", "cash": 50_000, "happiness": 1},
	{"text": "지하철이 계속 지연됐다. 피곤한 아침.", "energy": -5, "stress": 6},
	{"text": "감기에 걸렸다. 약국 비용과 뻐근한 하루.", "cash": -20_000, "energy": -8, "stress": 3},
	{"text": "회사에서 좋은 평가를 받았다. 뿌듯한 하루.", "stress": -4, "happiness": 5},
	{"text": "퇴근길 노을이 예뻤다. 잠깐 걸었다.", "stress": -5, "happiness": 2},
]

const SIDEJOB_NAMES := ["문서 정리", "카페 서빙", "데이터 라벨링", "홍보물 배포", "행사 서포트", "번역 외주"]

var month := 1
var month_seconds := 0.0            # 현재 게임월 경과 (활성 시간만 누적)
var cash_balance: int = START_CASH
var energy := 70
var stress := 40
var happiness := 55
var company: Dictionary = {}
var listing: Dictionary = {}
var contract_remaining := CONTRACT_LENGTH
var contract_renew_count := 0
var desire_index := 0
var purchased := {}                  # furniture id -> true (구매. 배치 여부는 별도)
var storage := []                    # 구매했으나 미배치 가구 id
var sidejobs_used := 0
var month_sidejob_income := 0
var goal_done := false
var last_save_unix := 0


# ---------------------------------------------------------------- 경제 파생값
func salary() -> int:
	return int(company.get("salary", 3_000_000))


func rent_total() -> int:
	return int(listing.get("rent", 600_000)) + int(listing.get("maintenance", 80_000))


func monthly_expenses() -> int:
	return rent_total() + LIVING_COST + MISC_COST


func monthly_free_income() -> int:
	return salary() - monthly_expenses()


func spendable_cash() -> int:
	return maxi(0, cash_balance - monthly_expenses())


func shortfall(amount: int) -> int:
	return maxi(0, amount - spendable_cash())


# ---------------------------------------------------------------- 부업 (08)
func sidejob_reward() -> int:
	# 08§7: 1회 보상 = 월 가처분소득의 20%
	return int(abs(monthly_free_income()) * 0.2) if monthly_free_income() > 0 else 150_000


func sidejob_max() -> int:
	# 08§9: 회사 기본값 + 통근 보정
	return maxi(1, int(company.get("sidejobs", 5)) + commute_sidejob_adj(int(listing.get("commute", 40))))


func do_sidejob() -> bool:
	if sidejobs_used >= sidejob_max():
		return false
	sidejobs_used += 1
	month_sidejob_income += sidejob_reward()
	cash_balance += sidejob_reward()
	energy = maxi(0, energy - 3)
	return true


# ---------------------------------------------------------------- 스탯 (07§4 자연어)
static func energy_label(v: int) -> String:
	if v >= 80: return "생기 있음"
	if v >= 60: return "여유 있음"
	if v >= 40: return "조금 피곤함"
	if v >= 20: return "지침"
	return "기절 직전"


static func stress_label(v: int) -> String:
	if v >= 80: return "번아웃 직전"
	if v >= 60: return "많이 지침"
	if v >= 40: return "조금 지침"
	if v >= 20: return "여유"
	return "평온"


static func happiness_label(v: int) -> String:
	if v >= 80: return "행복함"
	if v >= 60: return "만족스러움"
	if v >= 40: return "보통"
	if v >= 20: return "쓸쓸함"
	return "외로움"


# ---------------------------------------------------------------- 욕구
func desire_done(di: int = -1) -> bool:
	var i := di if di >= 0 else desire_index
	if i >= DESIRES.size():
		return true
	for fid in DESIRES[i]["items"]:
		if not purchased.has(fid):
			return false
	return true


func on_furniture_owned(fid: String) -> Dictionary:
	purchased[fid] = true
	storage.erase(fid)
	happiness = mini(100, happiness + 2)
	if desire_done() and desire_index < DESIRES.size():
		var d: Dictionary = DESIRES[desire_index]
		happiness = mini(100, happiness + int(d["happiness"]))
		stress = maxi(0, stress - 8)
		desire_index += 1
		if desire_index >= DESIRES.size():
			goal_done = true
		return d
	return {}


# ---------------------------------------------------------------- 만족도 (07§8)
func room_satisfaction() -> float:
	var placed_count := purchased.size() - storage.size()
	return clampf(float(desire_index) * 0.18 + float(placed_count) * 0.035, 0.0, 1.0)


func satisfaction_label() -> String:
	var s := room_satisfaction()
	if s >= 0.99: return "매우 좋음"
	if s >= 0.6: return "좋음"
	if s >= 0.3: return "보통"
	return "삭막함"


# ---------------------------------------------------------------- 시간/월 정산
## 활성 시간 누적. 게임월이 넘으면 true 반환 (호출측에서 정산 팝업)
func tick(delta: float) -> bool:
	month_seconds += delta
	if month_seconds >= MONTH_SECONDS:
		month_seconds -= MONTH_SECONDS
		return true
	return false


func settle_month() -> Dictionary:
	# 이벤트 (10 V0.1: RANDOM 50%)
	var ev := {}
	if randf() < 0.5:
		ev = EVENTS[randi() % EVENTS.size()]
		cash_balance += int(ev.get("cash", 0))
		energy = clampi(energy + int(ev.get("energy", 0)), 0, 100)
		stress = clampi(stress + int(ev.get("stress", 0)), 0, 100)
		happiness = clampi(happiness + int(ev.get("happiness", 0)), 0, 100)

	cash_balance += salary() - monthly_expenses()

	# 스탯 월 정산 (07§5/§7: 업무/통근 부담 + 방 회복력)
	var workload := int(company.get("workload", 3))
	energy = clampi(energy - 4 - workload, 0, 100)
	stress = clampi(stress + 5 + workload, 0, 100)
	var relax := mini(purchased.size() - storage.size(), 8)
	stress = maxi(0, stress - relax)
	if room_satisfaction() >= 0.6:
		happiness = mini(100, happiness + 5)

	month += 1
	sidejobs_used = 0
	contract_remaining -= 1

	var report := {
		"month": month, "income": salary(), "expenses": monthly_expenses(),
		"sidejob": month_sidejob_income, "event": ev,
		"energy": energy, "stress": stress, "happiness": happiness,
		"contract_left": contract_remaining,
	}
	month_sidejob_income = 0
	month_advanced.emit(report)
	return report


## 오프라인 경과 게임월 수 (04§4: 최대 3)
func offline_months(now_unix: int) -> int:
	if last_save_unix <= 0:
		return 0
	var elapsed: float = float(now_unix - last_save_unix)
	return mini(int(elapsed / MONTH_SECONDS), OFFLINE_MONTH_CAP)


# ---------------------------------------------------------------- 계약 (04§12-14)
func contract_state() -> String:
	if contract_remaining > 3: return ""
	if contract_remaining > 0: return "%d개월 후 계약 만료" % contract_remaining
	return "계약 만료! 결정이 필요해요"


func renew_contract() -> void:
	# 재계약: 현재 시세 +5% 갱신 (04§14 간소화)
	listing["rent"] = roundi(float(listing["rent"]) * 1.05)
	contract_remaining = CONTRACT_LENGTH
	contract_renew_count += 1


func move_to(new_listing: Dictionary) -> void:
	# 09§9: 이사 = 해당 집 이동가구 전량회수 → 보관함
	listing = new_listing.duplicate()
	contract_remaining = CONTRACT_LENGTH
	storage = purchased.keys().duplicate()


# ---------------------------------------------------------------- 구매
func try_spend(amount: int) -> bool:
	if amount > spendable_cash():
		return false
	cash_balance -= amount
	return true


# ---------------------------------------------------------------- 세이브
const SAVE_PATH := "user://mvp_save.json"

func to_dict() -> Dictionary:
	return {
		"month": month, "month_seconds": month_seconds, "cash_balance": cash_balance,
		"energy": energy, "stress": stress, "happiness": happiness,
		"company_id": company.get("id", ""), "listing_id": listing.get("id", ""),
		"contract_remaining": contract_remaining, "contract_renew_count": contract_renew_count,
		"desire_index": desire_index, "purchased": purchased.keys(),
		"storage": storage, "goal_done": goal_done,
		"last_save_unix": int(Time.get_unix_time_from_system()),
	}


func from_dict(d: Dictionary) -> void:
	month = int(d.get("month", 1))
	month_seconds = float(d.get("month_seconds", 0.0))
	cash_balance = int(d.get("cash_balance", START_CASH))
	energy = int(d.get("energy", 70))
	stress = int(d.get("stress", 40))
	happiness = int(d.get("happiness", 55))
	company = company_by_id(str(d.get("company_id", "")))
	listing = listing_by_id(str(d.get("listing_id", "")))
	contract_remaining = int(d.get("contract_remaining", CONTRACT_LENGTH))
	contract_renew_count = int(d.get("contract_renew_count", 0))
	desire_index = int(d.get("desire_index", 0))
	purchased.clear()
	for fid in d.get("purchased", []):
		purchased[fid] = true
	storage = Array(d.get("storage", []))
	goal_done = bool(d.get("goal_done", false))
	last_save_unix = int(d.get("last_save_unix", 0))


func save_game_with(placements: Array) -> void:
	last_save_unix = int(Time.get_unix_time_from_system())
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"game": to_dict(), "placements": placements}))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


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


static func load_placements() -> Array:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary and parsed.has("placements"):
			return parsed["placements"]
	return []
