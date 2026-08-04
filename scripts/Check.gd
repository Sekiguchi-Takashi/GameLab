extends Node2D

const TITLE := "V5.4 CHECK LIST"

const ITEMS := [
	{"t": "EXTERNAL ART LOADED", "d": "TITLE BOTTOM LEFT SHOULD SHOW ART 40 EXTERNAL OR MORE."},
	{"t": "RESOLUTION 1280x720", "d": "UNITS ARE LARGE AND FACES ARE READABLE ON THE MAP."},
	{"t": "FACING DOWN", "d": "MOVE A UNIT DOWNWARD. IT SHOWS THE FRONT VIEW."},
	{"t": "FACING UP", "d": "MOVE A UNIT UPWARD. IT SHOWS THE BACK VIEW."},
	{"t": "FACING SIDE", "d": "MOVE LEFT OR RIGHT. IT SHOWS THE SIDE VIEW, MIRRORED FOR LEFT."},
	{"t": "FACING PHASE", "d": "AFTER ACTING, FOUR DIRECTION BUTTONS APPEAR BEFORE THE TURN ENDS."},
	{"t": "FACING BY MAP TAP", "d": "DURING THAT PHASE, TAPPING THE MAP ALSO SETS THE FACING."},
	{"t": "FACING AFFECTS DAMAGE", "d": "SET A UNIT TO FACE AWAY, THEN LET A FOE HIT ITS BACK. DAMAGE SHOULD RISE."},
	{"t": "ENEMY FACING", "d": "ENEMY SPRITES ALSO TURN WHEN THEY MOVE AND ATTACK."},
	{"t": "LAYOUT INTACT", "d": "TITLE, PREP, DETAIL, TALK, SLOTS AND RECORDS ALL FIT THE NEW SIZE."},
	{"t": "TEXT READABLE", "d": "NO TEXT IS CUT OFF OR OVERLAPPING AT THE NEW RESOLUTION."},
	{"t": "BUTTONS TAPPABLE", "d": "ALL BUTTONS RESPOND AND ARE LARGE ENOUGH FOR A FINGER."},
	{"t": "NO CRASH", "d": "PLAY SEVERAL MAPS WITHOUT THE APP CLOSING."},
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
	return Rect2(16.0, 96.0 + float(i) * 66.0, 1248.0, 62.0)

func _btn(i: int) -> Rect2:
	var w := 300.0
	return Rect2(16.0 + float(i) * (w + 16.0), 636.0, w, 62.0)

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
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.04, 0.05, 0.07, 0.97))
	Gfx.text(self, TITLE, Vector2(16.0, 20.0), Pal.c("white"))
	var ok := 0
	var ng := 0
	for s in state:
		if int(s) == 1:
			ok += 1
		elif int(s) == 2:
			ng += 1
	Gfx.text(self, "OK %d  NG %d  OF %d" % [ok, ng, ITEMS.size()], Vector2(860.0, 20.0), Pal.c("gray"))
	Gfx.text(self, "TAP A ROW TO CYCLE  BLANK OK NG", Vector2(16.0, 48.0), Pal.c("dgray"))
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
		Gfx.text(self, msg, Vector2(16.0, 612.0), Pal.c("lgreen"))
	var labels: Array = ["UP", "DOWN", "COPY RESULT", "CLOSE"]
	for i in labels.size():
		var b := _btn(i)
		draw_rect(b, Pal.c("panel"))
		draw_rect(b, Pal.c("line"), false, 1.0)
		var s2: String = labels[i]
		Gfx.text(self, s2, Vector2(b.position.x + (b.size.x - float(Gfx.text_width(s2))) * 0.5, b.position.y + 11.0), Pal.c("white"))
