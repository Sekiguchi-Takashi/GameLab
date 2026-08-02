extends Node2D

const TITLE := "V2.3 CHECK LIST"

const ITEMS := [
	{"t": "TURN ORDER BY SPEED", "d": "TOP BAR SHOWS NEXT UNITS. WOLF SHOULD ACT BEFORE ORC."},
	{"t": "ACTIVE UNIT AUTO SELECT", "d": "ON YOUR TURN THE UNIT IS PICKED AND CAMERA MOVES TO IT."},
	{"t": "MOVE ONCE THEN ACT", "d": "MOVE, THEN ATTACK OR SKILL OR WAIT. NO SECOND MOVE."},
	{"t": "FACING", "d": "UNIT FACES THE WAY IT MOVED OR ATTACKED."},
	{"t": "FLANK BONUS", "d": "HIT FROM SIDE = X1.2, FROM BACK = X1.5. SEE FORECAST TEXT."},
	{"t": "SKILL KNIGHT GUARD", "d": "TAP SKILL. DAMAGE TAKEN IS HALVED UNTIL NEXT TURN."},
	{"t": "SKILL LANCER PIERCE", "d": "HITS TARGET AND THE UNIT BEHIND IT."},
	{"t": "SKILL ARCHER SNIPE", "d": "RANGE 3 AND NO COUNTER ATTACK."},
	{"t": "SKILL MAGE BLAST", "d": "HITS CENTER PLUS FOUR NEIGHBOURS."},
	{"t": "SKILL CLERIC HEAL", "d": "RESTORES HP OF AN ADJACENT ALLY."},
	{"t": "MP LIMIT", "d": "SKILL USES MP. AT ZERO THE SKILL BUTTON IS GREY."},
	{"t": "EXP AND LEVEL UP", "d": "ATTACK GIVES EXP. AT 100 A LEVEL UP BANNER APPEARS."},
	{"t": "ENEMY AI", "d": "ARCHER TYPE KEEPS DISTANCE. WEAK TARGETS ARE PICKED FIRST."},
	{"t": "TERRAIN AI", "d": "ENEMY PREFERS FOREST OR ROCK WHEN IT CAN."},
	{"t": "NO CRASH", "d": "PLAY THREE ROUNDS WITHOUT FREEZE OR MISSING SPRITES."},
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
