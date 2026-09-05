class_name FurnitureDB
## data/mvp/furniture.json 로더 — 정적 정의는 id로만 참조 (05_furniture.md 구조의 MVP 축소판)

var defs := {}  # id -> Dictionary


static func load_default() -> FurnitureDB:
	var db := FurnitureDB.new()
	var f := FileAccess.open("res://data/mvp/furniture.json", FileAccess.READ)
	assert(f != null, "furniture.json 로드 실패")
	var parsed = JSON.parse_string(f.get_as_text())
	for d in parsed["furniture"]:
		db.defs[d["id"]] = d
	return db


func get_def(id: String) -> Dictionary:
	return defs[id]


func all_ids() -> Array:
	return defs.keys()
