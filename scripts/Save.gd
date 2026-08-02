extends Node

const PATH := "user://save.json"
const TRACE := "user://trace.txt"

var last_trace := ""

var map_index := 0
var roster: Array = []
var items: Dictionary = {"POTION": 3, "NUT": 2, "STONE": 3}

func read_trace() -> void:
	if not FileAccess.file_exists(TRACE):
		last_trace = "NO TRACE"
		return
	var f := FileAccess.open(TRACE, FileAccess.READ)
	if f == null:
		last_trace = "NO TRACE"
		return
	var t: String = f.get_as_text()
	f.close()
	var parts: PackedStringArray = t.strip_edges().split("\n")
	var out: Array = []
	var n: int = parts.size()
	for i in range(maxi(n - 4, 0), n):
		out.append(String(parts[i]))
	last_trace = " > ".join(out)

func trace(tag: String) -> void:
	var f := FileAccess.open(TRACE, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(TRACE, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_string(tag + "\n")
	f.close()

func clear_trace() -> void:
	var f := FileAccess.open(TRACE, FileAccess.WRITE)
	if f != null:
		f.store_string("")
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(PATH)

func new_game() -> void:
	map_index = 0
	items = {"POTION": 3, "NUT": 2, "STONE": 3}
	roster = []
	for k in ["KNIGHT", "LANCER", "ARCHER", "MAGE", "CLERIC"]:
		var u: Dictionary = Units.make(String(k), 0, 0, 0)
		roster.append(_strip(u))

func _num(u: Dictionary, k: String, d: int) -> int:
	if u.has(k):
		return int(u[k])
	return d

func _strip(u: Dictionary) -> Dictionary:
	return {
		"kind": String(u["kind"]),
		"lv": _num(u, "lv", 1), "exp": _num(u, "exp", 0),
		"hp": _num(u, "hp", 10), "mhp": _num(u, "mhp", 10),
		"atk": _num(u, "atk", 5), "def": _num(u, "def", 3),
		"mov": _num(u, "mov", 4), "rng": _num(u, "rng", 1), "spd": _num(u, "spd", 5),
		"mp": _num(u, "mp", 0), "mmp": _num(u, "mmp", 0),
	}

func store(u: Dictionary) -> void:
	if not u.has("kind"):
		return
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
