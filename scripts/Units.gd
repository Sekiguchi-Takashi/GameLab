extends Node

const STATS := {
	"KNIGHT": {"hp": 30, "atk": 9, "def": 6, "mov": 4, "rng": 1, "spd": 4, "mp": 3, "skill": "GUARD", "label": "KNIGHT"},
	"LANCER": {"hp": 26, "atk": 11, "def": 4, "mov": 4, "rng": 1, "spd": 6, "mp": 3, "skill": "PIERCE", "label": "LANCER"},
	"ARCHER": {"hp": 21, "atk": 8, "def": 3, "mov": 4, "rng": 2, "spd": 7, "mp": 3, "skill": "SNIPE", "label": "ARCHER"},
	"MAGE": {"hp": 19, "atk": 12, "def": 2, "mov": 3, "rng": 2, "spd": 5, "mp": 3, "skill": "BLAST", "label": "MAGE"},
	"CLERIC": {"hp": 22, "atk": 6, "def": 3, "mov": 4, "rng": 1, "spd": 6, "mp": 4, "skill": "HEAL", "label": "CLERIC"},
	"ORC": {"hp": 26, "atk": 9, "def": 4, "mov": 3, "rng": 1, "spd": 3, "mp": 0, "skill": "", "label": "ORC"},
	"WOLF": {"hp": 19, "atk": 8, "def": 2, "mov": 5, "rng": 1, "spd": 9, "mp": 0, "skill": "", "label": "WOLF"},
	"BOWMAN": {"hp": 18, "atk": 8, "def": 2, "mov": 4, "rng": 2, "spd": 7, "mp": 0, "skill": "", "label": "BOWMAN"},
	"SHAMAN": {"hp": 17, "atk": 11, "def": 2, "mov": 3, "rng": 2, "spd": 5, "mp": 0, "skill": "", "label": "SHAMAN"},
	"PALADIN": {"hp": 40, "atk": 13, "def": 9, "mov": 4, "rng": 1, "spd": 5, "mp": 4, "skill": "GUARD", "label": "PALADIN"},
	"DRAGOON": {"hp": 34, "atk": 16, "def": 6, "mov": 5, "rng": 1, "spd": 7, "mp": 4, "skill": "PIERCE", "label": "DRAGOON"},
	"SNIPER": {"hp": 28, "atk": 12, "def": 5, "mov": 4, "rng": 3, "spd": 8, "mp": 4, "skill": "SNIPE", "label": "SNIPER"},
	"ARCHMAGE": {"hp": 26, "atk": 17, "def": 4, "mov": 3, "rng": 2, "spd": 6, "mp": 5, "skill": "BLAST", "label": "ARCHMAGE"},
	"BISHOP": {"hp": 30, "atk": 9, "def": 5, "mov": 4, "rng": 2, "spd": 7, "mp": 6, "skill": "HEAL", "label": "BISHOP"},
	"HEAVY": {"hp": 34, "atk": 9, "def": 8, "mov": 2, "rng": 1, "spd": 2, "mp": 0, "skill": "", "label": "HEAVY"},
}

const SKILL := {
	"GUARD": {"cost": 1, "rng": 0, "text": "HALVE DAMAGE UNTIL NEXT TURN"},
	"PIERCE": {"cost": 1, "rng": 1, "text": "HIT TARGET AND THE ONE BEHIND"},
	"SNIPE": {"cost": 1, "rng": 3, "text": "LONG SHOT, X1.3, NO COUNTER"},
	"BLAST": {"cost": 1, "rng": 2, "text": "CROSS AREA, X0.9, NO COUNTER"},
	"HEAL": {"cost": 1, "rng": 1, "text": "RESTORE HP OF AN ALLY"},
}

const JA_NAME := {
	"KNIGHT": "騎士", "LANCER": "槍兵", "ARCHER": "弓兵", "MAGE": "魔道士",
	"CLERIC": "僧侶", "ORC": "野盗", "WOLF": "狼",
	"BOWMAN": "射手", "SHAMAN": "呪術師", "HEAVY": "重装",
	"PALADIN": "聖騎士", "DRAGOON": "竜騎士", "SNIPER": "狙撃手",
	"ARCHMAGE": "大魔道士", "BISHOP": "司祭",
}

const PROMOTE := {
	"KNIGHT": "PALADIN", "LANCER": "DRAGOON", "ARCHER": "SNIPER",
	"MAGE": "ARCHMAGE", "CLERIC": "BISHOP",
}

const PROMO_LV := 10

func can_promote(entry: Dictionary) -> bool:
	if not PROMOTE.has(String(entry["kind"])):
		return false
	return int(entry["lv"]) >= PROMO_LV

func promote(entry: Dictionary) -> Dictionary:
	var from: String = String(entry["kind"])
	var to: String = String(PROMOTE[from])
	var a: Dictionary = STATS[from]
	var b: Dictionary = STATS[to]
	var out: Dictionary = entry.duplicate()
	out["kind"] = to
	out["mhp"] = int(entry["mhp"]) + int(b["hp"]) - int(a["hp"])
	out["hp"] = int(out["mhp"])
	out["atk"] = int(entry["atk"]) + int(b["atk"]) - int(a["atk"])
	out["def"] = int(entry["def"]) + int(b["def"]) - int(a["def"])
	out["mov"] = int(b["mov"])
	out["rng"] = int(b["rng"])
	out["spd"] = int(b["spd"])
	out["mmp"] = int(b["mp"])
	out["mp"] = int(b["mp"])
	return out

const JA_SKILL := {
	"GUARD": "防御", "PIERCE": "貫き", "SNIPE": "狙撃", "BLAST": "爆炎", "HEAL": "治癒",
}

const ITEMS := ["POTION", "NUT", "STONE"]
const ITEM_JA := {"POTION": "傷薬", "NUT": "活力の実", "STONE": "投げ石"}
const ITEM_INFO := {
	"POTION": {"rng": 1, "ally": true, "power": 15},
	"NUT": {"rng": 0, "ally": true, "power": 2},
	"STONE": {"rng": 3, "ally": false, "power": 7},
}

func item_label(k: String) -> String:
	return Gfx.L(String(ITEM_JA[k]), k)

func label(kind: String) -> String:
	var st: Dictionary = STATS[kind]
	return Gfx.L(String(JA_NAME[kind]), String(st["label"]))

func skill_label(sk: String) -> String:
	if sk == "":
		return ""
	return Gfx.L(String(JA_SKILL[sk]), sk)

func make(kind: String, team: int, x: int, y: int) -> Dictionary:
	var s: Dictionary = STATS[kind]
	return {
		"kind": kind, "team": team, "x": x, "y": y,
		"hp": int(s["hp"]), "mhp": int(s["hp"]),
		"atk": int(s["atk"]), "def": int(s["def"]),
		"mov": int(s["mov"]), "rng": int(s["rng"]), "spd": int(s["spd"]),
		"mp": int(s["mp"]), "mmp": int(s["mp"]),
		"skill": String(s["skill"]),
		"lv": 1, "exp": 0,
		"guard": false, "moved": false, "acted": false,
		"dir": Vector2i(0, 1),
	}
