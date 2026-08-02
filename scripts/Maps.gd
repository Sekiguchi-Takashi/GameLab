extends Node

const W := 20
const H := 14

const CH_TO_TILE := {".": 0, "-": 1, "~": 2, "#": 3, "T": 4, "f": 5, "p": 6, "s": 7, "h": 8, "r": 9}

const MAPS := [
	{
		"name": "PLAINS",
		"win": "ROUT",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[2, 5], [2, 7], [3, 6], [1, 6], [3, 8]],
		"enemies": [["ORC", 14, 5, 0], ["ORC", 14, 8, 0], ["WOLF", 16, 6, 0], ["WOLF", 13, 10, 0], ["BOWMAN", 17, 7, 0]],
		"intro": ["A BAND OF RAIDERS BLOCKS THE ROAD.", "CLEAR THEM OUT."],
		"outro": ["THE ROAD IS OPEN.", "BUT SMOKE RISES TO THE EAST."],
		"rows": [
		"....T..........T....",
		"..T.......--........",
		"..........--...T....",
		"...##.....--...hh...",
		"....#.....--...hh...",
		"..........--........",
		"--------------------",
		"..........--........",
		"..T.......--.hh##...",
		"..........--....#...",
		"....f.....--..s.....",
		"..T.......--.....T..",
		"..........--........",
		"....T..........T...."],
	},
	{
		"name": "RIVER",
		"win": "BOSS",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[2, 7], [1, 8], [3, 9], [2, 10], [1, 6]],
		"enemies": [["WOLF", 15, 5, 0], ["SHAMAN", 16, 9, 0], ["ORC", 17, 7, 0], ["BOWMAN", 14, 11, 0], ["ORC", 18, 6, 1]],
		"intro": ["THEIR CAPTAIN WAITS ACROSS THE RIVER.", "CUT HIM DOWN AND THE REST WILL SCATTER."],
		"outro": ["THE CAPTAIN FALLS.", "A SIGNAL FIRE BURNS ON THE HILL."],
		"rows": [
		"TT...~~....h..TT....",
		"T....~~....TT..T....",
		".....---....T.......",
		"..T...~~~..pp.......",
		"......~~~~.pp...TT..",
		".TT....~~~~.........",
		"--------------------",
		"........~~~~....T...",
		"..T......~~~~.......",
		".....TT...~~~~.pp...",
		"..........~~~~..TT..",
		"...TT......----.....",
		"............~~~~....",
		"..T....TT....~~~~..."],
	},
	{
		"name": "FORT",
		"win": "REACH",
		"goal": Vector2i(15, 3),
		"rounds": 0,
		"spawn": [[1, 6], [1, 5], [1, 7], [2, 6], [2, 8]],
		"enemies": [["BOWMAN", 10, 4, 0], ["ORC", 10, 8, 0], ["WOLF", 12, 6, 0], ["WOLF", 8, 2, 0], ["HEAVY", 15, 6, 0]],
		"intro": ["THE INNER YARD HOLDS THE GATE KEY.", "REACH THE FLOWER TILE. DO NOT STOP TO FIGHT."],
		"outro": ["THE KEY IS OURS.", "THE PASS LIES AHEAD."],
		"rows": [
		"....................",
		"..T..........#####..",
		".............#.s.#..",
		"....TT.......r.f.#..",
		".............#...#..",
		"..........----.h.#..",
		"----------.......#..",
		"..........----.h.#..",
		".............#...#..",
		"....TT.......#...#..",
		".............#####..",
		"..T.................",
		"....................",
		"...TT...........TT.."],
	},
	{
		"name": "PASS",
		"win": "SURVIVE",
		"goal": Vector2i(0, 0),
		"rounds": 6,
		"spawn": [[9, 6], [10, 6], [9, 7], [10, 7], [8, 6]],
		"enemies": [["BOWMAN", 4, 2, 0], ["SHAMAN", 16, 2, 0], ["ORC", 4, 11, 0], ["ORC", 16, 11, 0], ["HEAVY", 10, 1, 0], ["WOLF", 10, 12, 0]],
		"intro": ["HOLD THE PASS UNTIL THE COLUMN PASSES.", "SIX ROUNDS. THAT IS ALL."],
		"outro": ["THE COLUMN IS THROUGH.", "IT IS OVER."],
		"rows": [
		"####............####",
		"###..............###",
		"##.....TT.......--##",
		"#.....T..T......--.#",
		"....hh#..#..hh..--..",
		"--------..--------..",
		"..........--........",
		"..........--........",
		"--------..--------..",
		"......#..#......--..",
		"#.....T..T......--.#",
		"##.....TT.......--##",
		"###..............###",
		"####............####"],
	},
]


const JA := {
	"PLAINS": {
		"name": "平原",
		"win": "敵の全滅",
		"intro": ["野盗の一団が街道をふさいでいる。", "残らず片づけろ。"],
		"outro": ["道が開けた。", "だが東の空に煙が上がっている。"],
	},
	"RIVER": {
		"name": "渡河",
		"win": "敵将を討つ",
		"intro": ["敵の隊長は川の向こうで待っている。", "橋は三つ。隊長を討てば残りは散る。"],
		"outro": ["隊長が倒れた。", "丘の上で狼煙が上がる。"],
	},
	"FORT": {
		"name": "砦",
		"win": "指定地点へ到達",
		"intro": ["内庭に門の鍵がある。", "花のマスへ到達せよ。戦う必要はない。"],
		"outro": ["鍵は手に入れた。", "この先は峠だ。"],
	},
	"PASS": {
		"name": "峠",
		"win": "六ラウンド生存",
		"intro": ["本隊が通過するまで峠を守れ。", "六ラウンド。それだけでいい。"],
		"outro": ["本隊は抜けた。", "これで終わりだ。"],
	},
}

func name_of(m: Dictionary) -> String:
	var k: String = m["name"]
	var j: Dictionary = JA[k]
	return Gfx.L(String(j["name"]), k)

func intro_of(m: Dictionary) -> Array:
	var k: String = m["name"]
	var j: Dictionary = JA[k]
	if Gfx.has_jp():
		return j["intro"]
	return m["intro"]

func outro_of(m: Dictionary) -> Array:
	var k: String = m["name"]
	var j: Dictionary = JA[k]
	if Gfx.has_jp():
		return j["outro"]
	return m["outro"]

func count() -> int:
	return MAPS.size()

func get_map(i: int) -> Dictionary:
	return MAPS[clampi(i, 0, MAPS.size() - 1)]

func win_text(m: Dictionary) -> String:
	if Gfx.has_jp():
		var j: Dictionary = JA[String(m["name"])]
		return String(j["win"])
	var w: String = m["win"]
	if w == "ROUT":
		return "DEFEAT ALL"
	if w == "BOSS":
		return "DEFEAT THE CAPTAIN"
	if w == "REACH":
		return "REACH THE MARKED TILE"
	return "SURVIVE %d ROUNDS" % int(m["rounds"])
