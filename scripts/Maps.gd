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
		"intro": ["ROLAND|RAIDERS ON THE ROAD.", "ROLAND|OUR FIRST WORK. CLEAR THEM OUT."],
		"outro": ["ROLAND|THE ROAD IS OPEN.", "MIRA|SMOKE RISES IN THE EAST."],
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
		"intro": ["MIRA|A CAPTAIN WAITS ACROSS THE RIVER.", "ROLAND|THREE BRIDGES. CUT HIM DOWN."],
		"outro": ["SELVA|HIS SWORD WAS ARMY ISSUE.", "ROLAND|THIS IS MORE THAN BANDITRY."],
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
		"intro": ["NOELA|THE GATE KEY IS IN THE OLD FORT.", "ROLAND|RUN FOR THE FLOWER MARK."],
		"outro": ["NOELA|WE HAVE THE KEY.", "ROLAND|THE CREST IS FRESH."],
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
		"intro": ["ROLAND|REFUGEES CROSS THE PASS.", "ROLAND|SIX ROUNDS. HOLD."],
		"outro": ["ROLAND|THE COLUMN IS THROUGH.", "MIRA|THE CHASE CONTINUES."],
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
		"intro": ["SELVA|THEIR NEST IS IN THE MARSH.", "SELVA|THESE ARE NOT RAIDERS. MERCENARIES."],
		"outro": ["GEESE|THE NEST IS BURNED.", "SELVA|WHO PAID FOR MERCENARIES."],
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
		"intro": ["MIRA|THE SIGNAL IS A MESSENGER.", "ROLAND|TAKE THE HIGH GROUND."],
		"outro": ["MIRA|THE SIGNAL IS OUT.", "ROLAND|A NAME. VELD."],
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
		"intro": ["NOELA|THE MESSENGER HIDES IN THE RUINS.", "ROLAND|TAKE HIM ALIVE."],
		"outro": ["SELVA|AN OLD COMRADE, THEN.", "ROLAND|NOW HE IS THE ENEMY."],
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
		"intro": ["ROLAND|SO IT IS VELD.", "ROLAND|A MAN FROM MY OLD COMPANY."],
		"outro": ["NOELA|WE ARE THROUGH THE WOOD.", "NOELA|DO YOU STILL SHIELD HIM."],
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
		"intro": ["MIRA|THEY CAUGHT US AT THE LAKE.", "ROLAND|EIGHT ROUNDS UNTIL RELIEF."],
		"outro": ["ROLAND|RELIEF HAS ARRIVED.", "GEESE|NOW WE DO THE HUNTING."],
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
		"intro": ["SELVA|HIS LIEUTENANT HOLDS THE CANYON.", "ROLAND|GO AROUND THE ROCKS."],
		"outro": ["MIRA|THE LIEUTENANT IS SILENT.", "ROLAND|THE CITADEL IS CLOSE."],
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
		"intro": ["ROLAND|PUSH INTO THE CITADEL YARD.", "MIRA|THE GAP IS WIDE ENOUGH."],
		"outro": ["ROLAND|THE YARD IS OURS.", "SELVA|THE KEEP AWAITS."],
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
		"intro": ["ROLAND|THIS IS THE LAST OF IT.", "ROLAND|VELD. GIVE ME AN ANSWER."],
		"outro": ["ROLAND|IT IS OVER.", "NOELA|EVERYONE LIVES."],
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
		"intro": ["ロラン|街道に野盗が出た。", "ロラン|この隊の初仕事だ。残らず片づける。", "ギース|たかが野盗だろ。すぐ終わる。"],
		"outro": ["ロラン|道が開けた。", "ミラ|東の空に煙が上がっています。"],
	},
	"RIVER": {
		"name": "渡河",
		"win": "敵将を討つ",
		"intro": ["ミラ|川向こうに隊長格がいます。", "セルヴァ|野盗が隊長を置くかね。妙だな。", "ロラン|橋は三つ。討てば残りは散る。"],
		"outro": ["セルヴァ|隊長の剣、軍の支給品だ。", "ロラン|野盗の話では済まなくなったな。"],
	},
	"FORT": {
		"name": "砦",
		"win": "指定地点へ到達",
		"intro": ["ノエラ|廃砦に門の鍵があるそうです。", "ロラン|花の印まで走れ。戦う必要はない。", "ギース|逃げ回るのは性に合わんな。"],
		"outro": ["ノエラ|鍵は手に入れました。", "ロラン|砦の紋章がまだ新しい。誰かが使っている。"],
	},
	"PASS": {
		"name": "峠",
		"win": "6 ラウンド生存",
		"intro": ["ロラン|避難民の列が峠を越える。", "ロラン|六ラウンド。持ちこたえろ。", "ミラ|敵の装備、正規軍のものです。"],
		"outro": ["ロラン|列は抜けた。", "ミラ|追撃はまだ続きます。"],
	},
	"MARSH": {
		"name": "湿地",
		"win": "敵の全滅",
		"intro": ["セルヴァ|湿地に塒がある。", "セルヴァ|ただし彼らは野盗ではない。傭兵だ。", "ロラン|誰が金を出している。"],
		"outro": ["ギース|塒を焼いた。", "セルヴァ|傭兵を雇う金がどこから出たか、だな。"],
	},
	"HILLS": {
		"name": "丘陵",
		"win": "敵将を討つ",
		"intro": ["ミラ|丘の狼煙は伝令です。", "ロラン|高所を取れ。矢が届く。", "ギース|伝令を潰せば相手は目を失う。"],
		"outro": ["ミラ|狼煙は消えました。", "ロラン|伝令の口から名が出た。ヴェルド。"],
	},
	"RUINS": {
		"name": "廃街",
		"win": "指定地点へ到達",
		"intro": ["ノエラ|廃街の奥に伝令が隠れています。", "ロラン|生かして捕らえろ。", "セルヴァ|瓦礫は重いが、盾にはなる。"],
		"outro": ["セルヴァ|元同僚が相手か。", "ロラン|昔の話だ。今は敵だ。"],
	},
	"FOREST": {
		"name": "深森",
		"win": "敵の全滅",
		"intro": ["ロラン|ヴェルド、か。", "ギース|誰だそれは。", "ロラン|昔、同じ隊にいた男だ。"],
		"outro": ["ノエラ|森を抜けました。", "ノエラ|隊長。あの人をまだ庇うおつもりですか。"],
	},
	"LAKE": {
		"name": "湖畔",
		"win": "8 ラウンド生存",
		"intro": ["ミラ|湖畔で追いつかれました。", "ロラン|八ラウンド。援軍が来るまで持たせる。", "ノエラ|下がらないで。私が繋ぎます。"],
		"outro": ["ロラン|援軍が来た。", "ギース|ここからは追う側だ。"],
	},
	"CANYON": {
		"name": "渓谷",
		"win": "敵将を討つ",
		"intro": ["セルヴァ|渓谷に副官が構えている。", "ロラン|岩が視界を切る。回り込め。", "ギース|真っ直ぐ行けないのは面倒だな。"],
		"outro": ["ミラ|副官は沈黙しました。", "ロラン|城塞まであとわずかだ。"],
	},
	"CITADEL": {
		"name": "城塞",
		"win": "指定地点へ到達",
		"intro": ["ロラン|城塞の中庭まで押し込む。", "ノエラ|門は瓦礫で塞がれています。", "ミラ|通れる幅はあります。行けます。"],
		"outro": ["ロラン|中庭を制圧した。", "セルヴァ|本丸が目の前だよ、隊長。"],
	},
	"KEEP": {
		"name": "本丸",
		"win": "敵の全滅",
		"intro": ["ロラン|ここが最後だ。", "ロラン|ヴェルド。答えを聞かせてもらう。", "ギース|長い道だったな、隊長。"],
		"outro": ["ロラン|終わったな。", "ノエラ|お疲れさまでした。皆、生きています。"],
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
