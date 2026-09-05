class_name MiniEconomy
## Micro MVP용 최소 경제 — cash / reserved / spendable 개념 검증용.
## (실제 게임은 01_economy_balance.md 기준 서비스로 대체)

var cash_balance: int = 4_500_000
var reserved_mandatory_expenses: int = 2_950_000  # 월세 80 + 관리비 15 + 생활비 200 (만원)
var month: int = 1
var salary: int = 3_000_000


func spendable_cash() -> int:
	return max(0, cash_balance - reserved_mandatory_expenses)


## 구매 시도: 성공 true, 부족 시 false (부족액은 shortfall()으로)
func try_spend(amount: int) -> bool:
	if amount <= spendable_cash():
		cash_balance -= amount
		return true
	return false


func shortfall(amount: int) -> int:
	return max(0, amount - spendable_cash())


## 월 정산: 월급 수입 → 자동지출 → 다음 달 예약 재계산 (04_time_contract.md 12단계의 MVP 축소판)
func settle_month() -> Dictionary:
	var income := salary
	var expenses := reserved_mandatory_expenses
	cash_balance += income - expenses
	month += 1
	return {
		"income": income,
		"expenses": expenses,
		"net": income - expenses,
		"month": month,
	}
