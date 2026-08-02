extends Node

const W := 20
const H := 14

const CH_TO_TILE := {".": 0, "-": 1, "~": 2, "#": 3, "T": 4, "f": 5}

const MAPS := [
	{
		"name": "PLAINS",
		"win": "ROUT",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[2, 5], [2, 7], [3, 6], [1, 6], [3, 8]],
		"enemies": [["ORC", 14, 5, 0], ["ORC", 14, 8, 0], ["WOLF", 16, 6, 0], ["WOLF", 13, 10, 0], ["ORC", 17, 7, 0]],
		"intro": ["A BAND OF RAIDERS BLOCKS THE ROAD.", "CLEAR THEM OUT."],
		"outro": ["THE ROAD IS OPEN.", "BUT SMOKE RISES TO THE EAST."],
		"rows": [
		"....T..........T....",
		"..T.......--........",
		"..........--...T....",
		"...##.....--........",
		"....#.....--.....T..",
		"..........--........",
		"--------------------",
		"..........--........",
		"..T.......--...##...",
		"..........--....#...",
		"....f.....--........",
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
		"enemies": [["WOLF", 15, 5, 0], ["WOLF", 16, 9, 0], ["ORC", 17, 7, 0], ["ORC", 14, 11, 0], ["ORC", 18, 6, 1]],
		"intro": ["THEIR CAPTAIN WAITS ACROSS THE RIVER.", "CUT HIM DOWN AND THE REST WILL SCATTER."],
		"outro": ["THE CAPTAIN FALLS.", "A SIGNAL FIRE BURNS ON THE HILL."],
		"rows": [
		"TT...~~.......TT....",
		"T....~~....TT..T....",
		".....---....T.......",
		"..T...~~~...........",
		"......~~~~..T...TT..",
		".TT....~~~~.........",
		"--------------------",
		"........~~~~....T...",
		"..T......~~~~.......",
		".....TT...~~~~......",
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
		"enemies": [["ORC", 10, 4, 0], ["ORC", 10, 8, 0], ["WOLF", 12, 6, 0], ["WOLF", 8, 2, 0], ["ORC", 15, 6, 0]],
		"intro": ["THE INNER YARD HOLDS THE GATE KEY.", "REACH THE FLOWER TILE. DO NOT STOP TO FIGHT."],
		"outro": ["THE KEY IS OURS.", "THE PASS LIES AHEAD."],
		"rows": [
		"....................",
		"..T..........#####..",
		".............#...#..",
		"....TT.......#.f.#..",
		".............#...#..",
		"..........----...#..",
		"----------.......#..",
		"..........----...#..",
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
		"enemies": [["WOLF", 4, 2, 0], ["WOLF", 16, 2, 0], ["ORC", 4, 11, 0], ["ORC", 16, 11, 0], ["ORC", 10, 1, 0], ["WOLF", 10, 12, 0]],
		"intro": ["HOLD THE PASS UNTIL THE COLUMN PASSES.", "SIX ROUNDS. THAT IS ALL."],
		"outro": ["THE COLUMN IS THROUGH.", "IT IS OVER."],
		"rows": [
		"####............####",
		"###..............###",
		"##.....TT.......--##",
		"#.....T..T......--.#",
		"......#..#......--..",
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

func count() -> int:
	return MAPS.size()

func get_map(i: int) -> Dictionary:
	return MAPS[clampi(i, 0, MAPS.size() - 1)]

func win_text(m: Dictionary) -> String:
	var w: String = m["win"]
	if w == "ROUT":
		return "DEFEAT ALL"
	if w == "BOSS":
		return "DEFEAT THE CAPTAIN"
	if w == "REACH":
		return "REACH THE MARKED TILE"
	return "SURVIVE %d ROUNDS" % int(m["rounds"])
