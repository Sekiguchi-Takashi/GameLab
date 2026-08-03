extends Node

const PATH := "user://save.json"
const SLOTS := 3
const TRACE := "user://trace.txt"

var last_trace := ""

var map_index := 0
var roster: Array = []
var items: Dictionary = {"POTION": 3, "NUT": 2, "STONE": 3}
var stash: Dictionary = {}
var slot := 0
var difficulty := 1
var cycle := 1
var stats: Dictionary = {"clears": 0, "turns": 0, "kills": 0, "maxlv": 1}

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
	for i in range(maxi(n - 5, 0), n):
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

func path_of(i: int) -> String:
	return "user://save%d.json" % i

func has_slot(i: int) -> bool:
	return FileAccess.file_exists(path_of(i))

func slot_info(i: int) -> Dictionary:
	if not has_slot(i):
		return {}
	var f := FileAccess.open(path_of(i), FileAccess.READ)
	if f == null:
		return {}
	var t: String = f.get_as_text()
	f.close()
	var j = JSON.parse_string(t)
	if typeof(j) != TYPE_DICTIONARY:
		return {}
	return j

func wipe(i: int) -> void:
	if has_slot(i):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path_of(i)))
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("save%d.json" % i)

func has_save() -> bool:
	for i in SLOTS:
		if has_slot(i):
			return true
	return false

func new_game() -> void:
	map_index = 0
	cycle = 1
	stats = {"clears": 0, "turns": 0, "kills": 0, "maxlv": 1}
	items = {"POTION": 3, "NUT": 2, "STONE": 3}
	stash = {}
	roster = []
	for k in ["KNIGHT", "LANCER", "ARCHER", "MAGE", "CLERIC"]:
		var u: Dictionary = Units.make(String(k), 0, 0, 0)
		var e := _strip(u)
		e["weapon"] = Units.starter(String(k))
		e["name"] = Gfx.L(String(Units.HERO_JA[String(k)]), String(Units.HERO_EN[String(k)]))
		roster.append(e)

func _nm(u: Dictionary) -> String:
	if u.has("name"):
		return String(u["name"])
	return ""

func _wep(u: Dictionary) -> String:
	if u.has("weapon"):
		return String(u["weapon"])
	return ""

func add_stash(k: String) -> void:
	if not stash.has(k):
		stash[k] = 0
	stash[k] = int(stash[k]) + 1

func take_stash(k: String) -> bool:
	if not stash.has(k) or int(stash[k]) <= 0:
		return false
	stash[k] = int(stash[k]) - 1
	if int(stash[k]) <= 0:
		stash.erase(k)
	return true

func _num(u: Dictionary, k: String, d: int) -> int:
	if u.has(k):
		return int(u[k])
	return d

func _strip(u: Dictionary) -> Dictionary:
	return {
		"kind": String(u["kind"]),
		"weapon": _wep(u),
		"name": _nm(u),
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
	items["POTION"] = int(items["POTION"]) + 2
	items["STONE"] = int(items["STONE"]) + 2
	items["NUT"] = int(items["NUT"]) + 1

func rest() -> void:
	for i in roster.size():
		var r: Dictionary = roster[i]
		r["hp"] = int(r["mhp"])
		r["mp"] = int(r["mmp"])

func save_game() -> void:
	var f := FileAccess.open(path_of(slot), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"map": map_index, "roster": roster, "items": items, "stash": stash,
		"diff": difficulty, "cycle": cycle, "stats": stats,
	}))
	f.close()

func load_game() -> bool:
	if not has_slot(slot):
		return false
	var f := FileAccess.open(path_of(slot), FileAccess.READ)
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
			if key == "kind" or key == "weapon":
				out[key] = String(ed[k])
			else:
				out[key] = int(ed[k])
		if not out.has("weapon"):
			out["weapon"] = Units.starter(String(out["kind"]))
		roster.append(out)
	stash = {}
	if d.has("stash"):
		var sd: Dictionary = d["stash"]
		for k in sd.keys():
			stash[String(k)] = int(sd[k])
	items = {"POTION": 3, "NUT": 2, "STONE": 3}
	if d.has("items"):
		var it: Dictionary = d["items"]
		for k in Units.ITEMS:
			var key: String = k
			if it.has(key):
				items[key] = int(it[key])
	difficulty = 1
	if d.has("diff"):
		difficulty = int(d["diff"])
	cycle = 1
	if d.has("cycle"):
		cycle = maxi(int(d["cycle"]), 1)
	stats = {"clears": 0, "turns": 0, "kills": 0, "maxlv": 1}
	if d.has("stats"):
		var st: Dictionary = d["stats"]
		for k in stats.keys():
			var key: String = k
			if st.has(key):
				stats[key] = int(st[key])
	for e2 in roster:
		var ee: Dictionary = e2
		if not ee.has("name") or String(ee["name"]) == "":
			var kk: String = String(ee["kind"])
			if Units.HERO_JA.has(kk):
				ee["name"] = Gfx.L(String(Units.HERO_JA[kk]), String(Units.HERO_EN[kk]))
			else:
				ee["name"] = ""
	if roster.is_empty():
		new_game()
	return true

func diff_mul() -> float:
	if difficulty == 0:
		return 0.82
	if difficulty == 2:
		return 1.22
	return 1.0

func diff_label() -> String:
	if difficulty == 0:
		return Gfx.L("易しい", "EASY")
	if difficulty == 2:
		return Gfx.L("難しい", "HARD")
	return Gfx.L("普通", "NORMAL")

func bump(k: String, n: int) -> void:
	if not stats.has(k):
		stats[k] = 0
	stats[k] = int(stats[k]) + n

func raise_max(k: String, n: int) -> void:
	if not stats.has(k) or int(stats[k]) < n:
		stats[k] = n

func new_plus() -> void:
	map_index = 0
	cycle += 1
	for i in roster.size():
		var r: Dictionary = roster[i]
		r["hp"] = int(r["mhp"])
		r["mp"] = int(r["mmp"])

func make_unit(entry: Dictionary, x: int, y: int) -> Dictionary:
	var u: Dictionary = Units.make(String(entry["kind"]), 0, x, y)
	for k in ["lv", "exp", "hp", "mhp", "atk", "def", "mov", "rng", "spd", "mp", "mmp"]:
		if entry.has(k):
			u[k] = int(entry[k])
	var w := _wep(entry)
	u["weapon"] = w
	u["atk"] = int(u["atk"]) + Units.weapon_atk(w)
	u["rng"] = int(u["rng"]) + Units.weapon_rng(w)
	return u
