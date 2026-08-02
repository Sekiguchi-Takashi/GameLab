extends Node

const STATS := {
	"KNIGHT": {"hp": 30, "atk": 9, "def": 6, "mov": 4, "rng": 1, "label": "KNIGHT"},
	"LANCER": {"hp": 26, "atk": 11, "def": 4, "mov": 4, "rng": 1, "label": "LANCER"},
	"ARCHER": {"hp": 21, "atk": 8, "def": 3, "mov": 4, "rng": 2, "label": "ARCHER"},
	"MAGE": {"hp": 19, "atk": 12, "def": 2, "mov": 3, "rng": 2, "label": "MAGE"},
	"ORC": {"hp": 26, "atk": 9, "def": 4, "mov": 3, "rng": 1, "label": "ORC"},
	"WOLF": {"hp": 19, "atk": 8, "def": 2, "mov": 5, "rng": 1, "label": "WOLF"},
}

func make(kind: String, team: int, x: int, y: int) -> Dictionary:
	var s: Dictionary = STATS[kind]
	return {
		"kind": kind,
		"team": team,
		"x": x,
		"y": y,
		"hp": int(s["hp"]),
		"mhp": int(s["hp"]),
		"atk": int(s["atk"]),
		"def": int(s["def"]),
		"mov": int(s["mov"]),
		"rng": int(s["rng"]),
		"done": false,
	}
