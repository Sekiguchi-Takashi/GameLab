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
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["ORC", 19, 0, 0, 1], ["WOLF", 19, 1, 0, 1], ["ORC", 19, 2, 0, 1], ["WOLF", 19, 3, 0, 1], ["ORC", 19, 4, 0, 1]],
		"intro": ["RAIDERS BLOCK THE ROAD.", "CLEAR THEM OUT."],
		"outro": ["THE ROAD IS OPEN.", "SMOKE RISES EAST."],
		"rows": [
		"..#...T.............",
		"..........-T.....f..",
		"..........-...TT....",
		"....T.....-T...T....",
		"...T.#f.#.-.........",
		".......T..-.f.......",
		"--------------------",
		"..........-......T..",
		"......T...-.........",
		"..........-.........",
		"#T........-..T......",
		".....T....-..TT.....",
		"..........-.....f...",
		"..........#........."],
	},
	{
		"name": "RIVER",
		"win": "BOSS",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["ORC", 19, 0, 0, 1], ["WOLF", 19, 1, 0, 1], ["ORC", 19, 2, 0, 1], ["WOLF", 19, 3, 0, 1], ["ORC", 19, 4, 1, 1]],
		"intro": ["THE CAPTAIN WAITS ACROSS THE RIVER.", "THREE BRIDGES. CUT HIM DOWN."],
		"outro": ["THE CAPTAIN FALLS.", "A SIGNAL BURNS ON THE HILL."],
		"rows": [
		"....~~~............T",
		"....~~~.....T.....T.",
		"--------------------",
		"......~~~.h...h...T.",
		".......~~~..........",
		"........~~~.........",
		"--------------------",
		"..........~~~.......",
		"..T.h.T....~~~...T..",
		"T..T.......T~~~.....",
		"...T.........~~~....",
		"--------------------",
		".T..........T.~~~...",
		"......T........~~~.."],
	},
	{
		"name": "FORT",
		"win": "REACH",
		"goal": Vector2i(15, 3),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["ORC", 19, 0, 0, 2], ["WOLF", 19, 1, 0, 2], ["ORC", 19, 2, 0, 2], ["WOLF", 19, 3, 0, 2], ["ORC", 19, 4, 0, 2], ["WOLF", 19, 5, 0, 2]],
		"intro": ["THE GATE KEY LIES IN THE INNER YARD.", "REACH THE FLOWER TILE."],
		"outro": ["THE KEY IS OURS.", "THE PASS LIES AHEAD."],
		"rows": [
		"....................",
		"..h.....T....######.",
		"....T........#....#.",
		".T...........#.f..#.",
		".............#....#.",
		"..................#.",
		"-------------r....#.",
		"........TT........#.",
		".............#....#.",
		"T............#h.T.#.",
		"....T........#...T#.",
		"..T......h...######.",
		"....T..T............",
		"...................."],
	},
	{
		"name": "PASS",
		"win": "SURVIVE",
		"goal": Vector2i(0, 0),
		"rounds": 6,
		"spawn": [[7, 5], [7, 6], [7, 7], [7, 8], [8, 5]],
		"enemies": [["ORC", 4, 0, 0, 2], ["WOLF", 4, 1, 0, 2], ["BOWMAN", 0, 2, 0, 2], ["ORC", 1, 2, 0, 2], ["WOLF", 2, 2, 0, 2], ["BOWMAN", 3, 2, 0, 2]],
		"intro": ["HOLD THE PASS UNTIL THE COLUMN PASSES.", "SIX ROUNDS."],
		"outro": ["THE COLUMN IS THROUGH.", "THE CHASE GOES ON."],
		"rows": [
		"####........h...####",
		"####......h.....####",
		"T...................",
		"...........h.T......",
		"..h.................",
		"--------..-.--------",
		"........T.-.........",
		"........T.-...h..h..",
		"--------..-.--------",
		"....T.....h.........",
		".T.....T............",
		".......T........h...",
		"####..T.........####",
		"####T...........####"],
	},
	{
		"name": "MARSH",
		"win": "ROUT",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["ORC", 19, 0, 0, 3], ["BOWMAN", 19, 1, 0, 3], ["SHAMAN", 19, 2, 0, 3], ["ORC", 19, 3, 0, 3], ["BOWMAN", 19, 4, 0, 3], ["SHAMAN", 19, 5, 0, 3], ["ORC", 19, 6, 0, 3]],
		"intro": ["THEIR NEST SITS IN THE MARSH.", "MIND THE POISON."],
		"outro": ["THE NEST IS BURNED.", "THE WATER CLEARS."],
		"rows": [
		".....p....p....p....",
		"....s..p....pT......",
		"s...p....p....p.....",
		"......p....p....p...",
		"........p....p......",
		".....pTpppppp..p...T",
		"--------------------",
		"....p..pppppp.p.....",
		"..s...ppppppp...p..T",
		"........p....p......",
		".....p....p....pT...",
		".T.....p....p.......",
		"....p.T..p....p.....",
		"....T.p....p....p..."],
	},
	{
		"name": "HILLS",
		"win": "BOSS",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["WOLF", 19, 0, 0, 3], ["BOWMAN", 19, 1, 0, 3], ["SHAMAN", 19, 2, 0, 3], ["WOLF", 19, 3, 0, 3], ["BOWMAN", 19, 4, 0, 3], ["SHAMAN", 19, 5, 0, 3], ["ORC", 19, 6, 1, 3]],
		"intro": ["SOMEONE LIT A SIGNAL ON THE HILL.", "TAKE THE HIGH GROUND."],
		"outro": ["THE SIGNAL IS OUT.", "RUINS LIE BEYOND."],
		"rows": [
		".................#..",
		"...............T....",
		".........hhh........",
		"........Thhhhhh.....",
		".TT....hhh..hhh.....",
		".T.....hhh..hhh.....",
		"........#..hhhh....T",
		"--------------------",
		".........hhhh.......",
		".......hhh..........",
		".T.....hhh......hhh.",
		"................hhh.",
		"........#.........T.",
		"......T..#.T........"],
	},
	{
		"name": "RUINS",
		"win": "REACH",
		"goal": Vector2i(17, 2),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["ORC", 19, 0, 0, 4], ["BOWMAN", 19, 1, 0, 4], ["HEAVY", 19, 2, 0, 4], ["ORC", 19, 3, 0, 4], ["BOWMAN", 19, 4, 0, 4], ["HEAVY", 19, 5, 0, 4], ["ORC", 19, 7, 0, 4], ["BOWMAN", 19, 8, 0, 4]],
		"intro": ["A MESSENGER HIDES IN THE RUINS.", "RUBBLE IS SLOW BUT SAFE."],
		"outro": ["THE MESSENGER IS TAKEN.", "A LAKE WAITS PAST THE WOOD."],
		"rows": [
		".........-..........",
		".rr......-..rr......",
		".rrrr....-..rr...f..",
		"...rr....-..........",
		"--------------------",
		".rrr.....-r....#.rr.",
		".rrr.....-r...#..rr#",
		"...rr....-..........",
		"...rr...r-..........",
		"--------------------",
		".....rr..-...#....#.",
		".....rr..-.rr.......",
		"#........-.rr.......",
		".........-.........."],
	},
	{
		"name": "FOREST",
		"win": "ROUT",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["WOLF", 19, 0, 0, 5], ["SHAMAN", 19, 1, 0, 5], ["HEAVY", 19, 2, 0, 5], ["WOLF", 19, 3, 0, 5], ["SHAMAN", 19, 4, 0, 5], ["HEAVY", 19, 5, 0, 5], ["WOLF", 19, 6, 0, 5], ["SHAMAN", 19, 7, 0, 5]],
		"intro": ["THE WOOD IS THICK.", "DO NOT GET SPLIT UP."],
		"outro": ["WE ARE THROUGH THE WOOD.", "WATER GLEAMS AHEAD."],
		"rows": [
		"T.....T.Th......T..T",
		"..T...........T.....",
		"T....h-T.....T..T..T",
		"..TT.T-..T....TT....",
		".TT...-......T...TT.",
		"T.T...-Th.T.T.....T.",
		".T....-.......T....T",
		"--------------------",
		".T....-.............",
		"......-...T...T...T.",
		"......-.............",
		"......-.TT..........",
		".T...T.h.T....T.....",
		"T..T..T.T.........T."],
	},
	{
		"name": "LAKE",
		"win": "SURVIVE",
		"goal": Vector2i(0, 0),
		"rounds": 8,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["ORC", 19, 0, 0, 5], ["BOWMAN", 19, 1, 0, 5], ["SHAMAN", 19, 2, 0, 5], ["HEAVY", 19, 3, 0, 5], ["ORC", 19, 4, 0, 5], ["BOWMAN", 19, 5, 0, 5], ["SHAMAN", 19, 6, 0, 5], ["HEAVY", 19, 7, 0, 5], ["ORC", 19, 8, 0, 5]],
		"intro": ["THEY CAUGHT US AT THE LAKE.", "HOLD EIGHT ROUNDS."],
		"outro": ["RELIEF HAS ARRIVED.", "WE ARE NO LONGER THE HUNTED."],
		"rows": [
		"...s................",
		"........~~~~......s.",
		"..~~~~~.~~~~........",
		".T~~~~~T~~-~........",
		"..~~~~~...-.........",
		"..~~~~~T..-.T.....s.",
		"--------------------",
		"...T...T..-.....s...",
		"T...T.....-..~~~~~..",
		"..........-..~~~~~..",
		"..........-..~~~~~..",
		"....T.....-..~~~~~..",
		"....................",
		"...Ts..............."],
	},
	{
		"name": "CANYON",
		"win": "BOSS",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[0, 2], [0, 3], [0, 4], [0, 5], [0, 6]],
		"enemies": [["ORC", 19, 2, 0, 6], ["WOLF", 19, 3, 0, 6], ["BOWMAN", 19, 4, 0, 6], ["SHAMAN", 19, 5, 0, 6], ["HEAVY", 19, 6, 0, 6], ["ORC", 19, 7, 0, 6], ["WOLF", 19, 8, 0, 6], ["BOWMAN", 19, 9, 0, 6], ["HEAVY", 19, 10, 1, 6]],
		"intro": ["THE LORD OF THE CANYON WAITS.", "ROCKS BLOCK THE VIEW."],
		"outro": ["THE CANYON IS SILENT.", "THE CITADEL IS CLOSE."],
		"rows": [
		"####################",
		"####################",
		"....h...........h...",
		".......##T......##..",
		"........####..h..##.",
		"........T..h.....##h",
		"--------------------",
		".....h.T............",
		".....##.......T.T...",
		"....................",
		"......T.............",
		"....................",
		"####################",
		"####################"],
	},
	{
		"name": "CITADEL",
		"win": "REACH",
		"goal": Vector2i(16, 6),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["BOWMAN", 19, 0, 0, 7], ["SHAMAN", 19, 1, 0, 7], ["HEAVY", 19, 2, 0, 7], ["ORC", 19, 3, 0, 7], ["BOWMAN", 19, 4, 0, 7], ["SHAMAN", 19, 5, 0, 7], ["HEAVY", 19, 6, 0, 7], ["ORC", 19, 7, 0, 7], ["BOWMAN", 19, 8, 0, 7], ["SHAMAN", 19, 9, 0, 7]],
		"intro": ["PUSH INTO THE CITADEL YARD.", "THE GATE IS CHOKED WITH RUBBLE."],
		"outro": ["THE YARD IS OURS.", "THE KEEP STANDS BEFORE US."],
		"rows": [
		"..T.................",
		"......T...#########.",
		".....T....#.......#.",
		"..........#.......#.",
		"..........#.......#.",
		"..........#r.rrrT.#.",
		"----------rr.rrrf.#.",
		"..........rr.rrr..#.",
		".......T..#r.rrrh.#.",
		"........T.#....T..#.",
		"..........#.....T.#.",
		".........h#......h#.",
		"..........#########.",
		".............T.....T"],
	},
	{
		"name": "KEEP",
		"win": "ROUT",
		"goal": Vector2i(0, 0),
		"rounds": 0,
		"spawn": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
		"enemies": [["ORC", 19, 0, 0, 8], ["WOLF", 19, 1, 0, 8], ["BOWMAN", 19, 2, 0, 8], ["SHAMAN", 19, 3, 0, 8], ["HEAVY", 19, 4, 0, 8], ["ORC", 19, 5, 0, 8], ["WOLF", 19, 6, 0, 8], ["BOWMAN", 19, 7, 0, 8], ["SHAMAN", 19, 8, 0, 8], ["HEAVY", 19, 9, 0, 8]],
		"intro": ["THIS IS THE LAST OF IT.", "THEY WILL SPEND EVERYTHING."],
		"outro": ["IT IS FINISHED.", "THE COMPANY TURNS FOR HOME."],
		"rows": [
		"....r....-.....T....",
		".....#T..-..........",
		".r#.r...T-.......T..",
		"--------------------",
		"...#..r.#-.T....s...",
		"..pppr...-.....hhhT.",
		"T.ppp....-....Thhh..",
		"..ppp....-.....hhh..",
		"..pppT..T-....Thhh..",
		".........-..T.......",
		"--------------------",
		"........s-..........",
		".........-.....#r...",
		"........#-...T.T...."],
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
		"intro": ["隊長は川の向こうだ。", "橋は三つ。討てば残りは散る。"],
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
		"win": "6 ラウンド生存",
		"intro": ["本隊が通過するまで峠を守れ。", "六ラウンド。それだけでいい。"],
		"outro": ["本隊は抜けた。", "追撃はまだ続く。"],
	},
	"MARSH": {
		"name": "湿地",
		"win": "敵の全滅",
		"intro": ["湿地に彼らの塒がある。", "毒沼に足を取られるな。"],
		"outro": ["塒を焼いた。", "湿地の水が澄んでいく。"],
	},
	"HILLS": {
		"name": "丘陵",
		"win": "敵将を討つ",
		"intro": ["丘の上に狼煙を上げた者がいる。", "高所を取れ。矢が届く。"],
		"outro": ["狼煙は消えた。", "丘の向こうに廃街が見える。"],
	},
	"RUINS": {
		"name": "廃街",
		"win": "指定地点へ到達",
		"intro": ["廃れた街の奥に伝令が隠れている。", "瓦礫は重いが、身を守る。"],
		"outro": ["伝令を捕らえた。", "森を抜ければ湖だ。"],
	},
	"FOREST": {
		"name": "深森",
		"win": "敵の全滅",
		"intro": ["森が深い。相手は地形を知っている。", "分断されるな。"],
		"outro": ["森を抜けた。", "湖面が見えてきた。"],
	},
	"LAKE": {
		"name": "湖畔",
		"win": "8 ラウンド生存",
		"intro": ["湖畔で追いつかれた。", "援軍が来るまで八ラウンド持たせろ。"],
		"outro": ["援軍が到着した。", "もう追われる側ではない。"],
	},
	"CANYON": {
		"name": "渓谷",
		"win": "敵将を討つ",
		"intro": ["渓谷の主が待ち構えている。", "岩が視界を遮る。回り込め。"],
		"outro": ["渓谷の主は沈黙した。", "城塞まであとわずかだ。"],
	},
	"CITADEL": {
		"name": "城塞",
		"win": "指定地点へ到達",
		"intro": ["城塞の中庭まで押し込む。", "門は瓦礫で塞がれている。"],
		"outro": ["中庭を制圧した。", "本丸が目の前にある。"],
	},
	"KEEP": {
		"name": "本丸",
		"win": "敵の全滅",
		"intro": ["ここが最後だ。", "相手も全てを出してくる。"],
		"outro": ["全てが終わった。", "隊は帰路につく。"],
	},
}

func count() -> int:
	return MAPS.size()

func get_map(i: int) -> Dictionary:
	return MAPS[clampi(i, 0, MAPS.size() - 1)]

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
