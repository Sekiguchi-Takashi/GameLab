extends Node2D

const TITLE := "V4.1 CHECK LIST"

const ITEMS := [
	{"t": "TWELVE MAPS", "d": "THE CAMPAIGN RUNS FROM PLAINS TO KEEP. TWELVE BATTLES."},
	{"t": "DIFFICULTY CURVE", "d": "FOE COUNT AND LEVEL RISE. LATE MAPS HAVE NINE OR TEN FOES."},
	{"t": "ENEMY LEVELS", "d": "LATER FOES HAVE MORE HP AND ATTACK. CHECK THE HP BAR LENGTH."},
	{"t": "OBJECTIVE MIX", "d": "ROUT, BOSS, REACH AND SURVIVE ALL APPEAR. NO TWO SAME IN A ROW EARLY."},
	{"t": "MAP 5 MARSH", "d": "POISON TILES EVERYWHERE. STANDING STILL COSTS HP."},
	{"t": "MAP 6 HILLS", "d": "MANY HILL TILES. RANGED UNITS GAIN RANGE UP THERE."},
	{"t": "MAP 7 RUINS", "d": "RUBBLE SLOWS MOVEMENT BUT GIVES HEAVY COVER."},
	{"t": "MAP 8 FOREST", "d": "DENSE TREES. MOVEMENT IS SLOW AND SIGHT LINES ARE SHORT."},
	{"t": "MAP 9 LAKE", "d": "WATER BLOCKS AND SPRINGS HEAL. SURVIVE EIGHT ROUNDS."},
	{"t": "MAP 11 CITADEL", "d": "RUBBLE GATE. REACH THE MARKED TILE INSIDE."},
	{"t": "MAP 12 KEEP", "d": "ALL TERRAIN AND ALL FOE TYPES. FINAL BATTLE."},
	{"t": "NO MAP WARNING", "d": "NO MAP WARNING TEXT ON ANY OF THE TWELVE MAPS."},
	{"t": "STORY FLOWS", "d": "INTRO AND OUTRO TEXT CONNECT FROM MAP TO MAP."},
	{"t": "ENDING AFTER 12", "d": "CLEARING MAP 12 SHOWS THE ALL CLEARED SCREEN."},
	{"t": "GEAR MATTERS LATE", "d": "BY MAP 8 OR SO, PROMOTION AND BETTER WEAPONS FEEL NECESSARY."},
	{"t": "NO CRASH", "d": "PLAY SEVERAL MAPS IN ONE SESSION WITHOUT THE APP CLOSING."},
]

var state: Array = []
var top := 0
var msg := ""
var msg_t := 0.0

func _ready() -> void:
	z_index = 150
	for i in ITEMS.size():
		state.append(0)

func rows() -> int:
	return 8

func _row_rect(i: int) -> Rect2:
	return Rect2(8.0, 44.0 + float(i) * 32.0, 624.0, 30.0)

func _btn(i: int) -> Rect2:
	var w := 152.0
	return Rect2(8.0 + float(i) * (w + 8.0), 322.0, w, 30.0)

func tap(p: Vector2) -> bool:
	if _btn(0).has_point(p):
		top = maxi(top - rows(), 0)
		return false
	if _btn(1).has_point(p):
		if top + rows() < ITEMS.size():
			top += rows()
		return false
	if _btn(2).has_point(p):
		_copy()
		return false
	if _btn(3).has_point(p):
		return true
	for i in rows():
		var idx := top + i
		if idx >= ITEMS.size():
			break
		if _row_rect(i).has_point(p):
			state[idx] = (int(state[idx]) + 1) % 3
			return false
	return false

func _copy() -> void:
	var lines: Array = [TITLE]
	for i in ITEMS.size():
		var it: Dictionary = ITEMS[i]
		var mark := "[  ]"
		if int(state[i]) == 1:
			mark = "[OK]"
		elif int(state[i]) == 2:
			mark = "[NG]"
		lines.append("%s %s" % [mark, String(it["t"])])
	DisplayServer.clipboard_set("\n".join(lines))
	msg = "COPIED TO CLIPBOARD"
	msg_t = 2.2

func _process(d: float) -> void:
	if msg_t > 0.0:
		msg_t -= d
		if msg_t <= 0.0:
			msg = ""
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.04, 0.05, 0.07, 0.97))
	Gfx.text(self, TITLE, Vector2(8.0, 10.0), Pal.c("white"))
	var ok := 0
	var ng := 0
	for s in state:
		if int(s) == 1:
			ok += 1
		elif int(s) == 2:
			ng += 1
	Gfx.text(self, "OK %d  NG %d  OF %d" % [ok, ng, ITEMS.size()], Vector2(430.0, 10.0), Pal.c("gray"))
	Gfx.text(self, "TAP A ROW TO CYCLE  BLANK OK NG", Vector2(8.0, 24.0), Pal.c("dgray"))
	for i in rows():
		var idx := top + i
		if idx >= ITEMS.size():
			break
		var it: Dictionary = ITEMS[idx]
		var r := _row_rect(i)
		draw_rect(r, Color(0.10, 0.13, 0.17, 1.0))
		draw_rect(r, Pal.c("line"), false, 1.0)
		var st: int = int(state[idx])
		var mark := "[  ]"
		var col: Color = Pal.c("gray")
		if st == 1:
			mark = "[OK]"
			col = Pal.c("lgreen")
		elif st == 2:
			mark = "[NG]"
			col = Pal.c("red")
		Gfx.text(self, mark, Vector2(r.position.x + 4.0, r.position.y + 4.0), col)
		Gfx.text(self, "%d %s" % [idx + 1, String(it["t"])], Vector2(r.position.x + 34.0, r.position.y + 4.0), Pal.c("white"))
		Gfx.text(self, String(it["d"]), Vector2(r.position.x + 34.0, r.position.y + 17.0), Pal.c("dgray"))
	if msg != "":
		Gfx.text(self, msg, Vector2(8.0, 306.0), Pal.c("lgreen"))
	var labels: Array = ["UP", "DOWN", "COPY RESULT", "CLOSE"]
	for i in labels.size():
		var b := _btn(i)
		draw_rect(b, Pal.c("panel"))
		draw_rect(b, Pal.c("line"), false, 1.0)
		var s2: String = labels[i]
		Gfx.text(self, s2, Vector2(b.position.x + (b.size.x - float(Gfx.text_width(s2))) * 0.5, b.position.y + 11.0), Pal.c("white"))
