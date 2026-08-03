extends Node2D

const TITLE := "V5.0 CHECK LIST"

const ITEMS := [
	{"t": "SAVE SLOTS", "d": "PLAY OPENS THREE FILES. EACH KEEPS ITS OWN PROGRESS."},
	{"t": "DIFFICULTY", "d": "A NEW FILE ASKS EASY NORMAL HARD. FOE STATS SCALE."},
	{"t": "ERASE", "d": "ERASE BUTTON THEN A FILE ROW DELETES THAT FILE."},
	{"t": "RECORDS SCREEN", "d": "TITLE RECORDS SHOWS CLEARS, ROUNDS, KILLS AND TOP LEVEL."},
	{"t": "CHARACTER NAMES", "d": "ALLIES HAVE NAMES. THEY APPEAR IN PREP, DETAIL AND BATTLE."},
	{"t": "SPEAKER IN TALK", "d": "DIALOGUE SHOWS A NAME PLATE ABOVE THE WINDOW."},
	{"t": "STORY CONNECTS", "d": "TWELVE BATTLES FORM ONE STORY ENDING WITH VELD."},
	{"t": "MID BATTLE LINES", "d": "BOSS MAPS, REACH MAPS AND THE FIRST ALLY DOWN TRIGGER A LINE."},
	{"t": "NEW GAME PLUS", "d": "AFTER MAP 12, CARRY OVER AND RESTART. FOES GAIN TWO LEVELS PER CYCLE."},
	{"t": "CYCLE SHOWN", "d": "FILE LIST AND ENDING SHOW THE CYCLE NUMBER."},
	{"t": "BALANCE EARLY", "d": "MAPS 1 TO 3 SHOULD BE COMFORTABLE."},
	{"t": "BALANCE LATE", "d": "MAPS 10 TO 12 SHOULD DEMAND PROMOTION AND GOOD WEAPONS."},
	{"t": "ITEM RESUPPLY", "d": "A WIN ADDS TWO POTIONS, TWO STONES AND ONE NUT."},
	{"t": "NO CRASH", "d": "PLAY A FULL CAMPAIGN WITHOUT THE APP CLOSING."},
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
