extends Node

const PATH := "user://save.json"

var map_index := 0
var roster: Array = []
var items: Dictionary = {"POTION": 3, "NUT": 2, "STONE": 3}

func has_save() -> bool:
	return FileAccess.file_exists(PATH)

func new_game() -> void:
	map_index = 0
	items = {"POTION": 3, "NUT": 2, "STONE": 3}
	roster = []
	for k in ["KNIGHT", "LANCER", "ARCHER", "MAGE", "CLERIC"]:
		var u: Dictionary = Units.make(String(k), 0, 0, 0)
		roster.append(_strip(u))

func _strip(u: Dictionary) -> Dictionary:
	return {
		"kind": String(u["kind"]),
		"lv": int(u["lv"]), "exp": int(u["exp"]),
		"hp": int(u["hp"]), "mhp": int(u["mhp"]),
		"atk": int(u["atk"]), "def": int(u["def"]),
		"mov": int(u["mov"]), "rng": int(u["rng"]), "spd": int(u["spd"]),
		"mp": int(u["mp"]), "mmp": int(u["mmp"]),
	}

func store(u: Dictionary) -> void:
	var s := _strip(u)
	for i in roster.size():
		var r: Dictionary = roster[i]
		if String(r["kind"]) == String(s["kind"]):
			roster[i] = s
			return
	roster.append(s)

func resupply() -> void:
	items["POTION"] = int(items["POTION"]) + 1
	items["STONE"] = int(items["STONE"]) + 1

func rest() -> void:
	for i in roster.size():
		var r: Dictionary = roster[i]
		r["hp"] = int(r["mhp"])
		r["mp"] = int(r["mmp"])

func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"map": map_index, "roster": roster, "items": items}))
	f.close()

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var txt: String = f.get_as_text()
	f.close()
	var j = JSON.parse_string(txt)
	if typeof(j) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = j
	map_index = 0
	if d.has("map"):
		map_index = int(d["map"])
	roster = []
	var arr: Array = []
	if d.has("roster"):
		arr = d["roster"]
	for e in arr:
		var ed: Dictionary = e
		var out: Dictionary = {}
		for k in ed.keys():
			var key: String = String(k)
			if key == "kind":
				out[key] = String(ed[k])
			else:
				out[key] = int(ed[k])
		roster.append(out)
	items = {"POTION": 3, "NUT": 2, "STONE": 3}
	if d.has("items"):
		var it: Dictionary = d["items"]
		for k in Units.ITEMS:
			var key: String = k
			if it.has(key):
				items[key] = int(it[key])
	if roster.is_empty():
		new_game()
	return true

func make_unit(entry: Dictionary, x: int, y: int) -> Dictionary:
	var u: Dictionary = Units.make(String(entry["kind"]), 0, x, y)
	for k in ["lv", "exp", "hp", "mhp", "atk", "def", "mov", "rng", "spd", "mp", "mmp"]:
		if entry.has(k):
			u[k] = int(entry[k])
	return u
