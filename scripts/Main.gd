extends Node2D

enum Phase { PLAYER, ENEMY, OVER }
enum Mode { IDLE, MOVE, TARGET }

const VIEW := Rect2(0.0, 20.0, 640.0, 296.0)
const TS := 32.0

var board = null
var fx = null

var units: Array = []
var phase: int = Phase.PLAYER
var mode: int = Mode.IDLE
var sel := -1
var reach: Dictionary = {}
var targets: Array = []
var turn := 1
var msg := "YOUR TURN"

var cam := Vector2.ZERO
var touch_start := Vector2.ZERO
var touch_pos := Vector2.ZERO
var dragging := false
var down := false

var ai_i := 0
var ai_t := 0.0

func _ready() -> void:
	board = preload("res://scripts/Board.gd").new()
	add_child(board)
	fx = preload("res://scripts/Fx.gd").new()
	add_child(fx)
	_setup()

func _setup() -> void:
	units = []
	units.append(Units.make("KNIGHT", 0, 3, 10))
	units.append(Units.make("LANCER", 0, 2, 12))
	units.append(Units.make("ARCHER", 0, 4, 13))
	units.append(Units.make("MAGE", 0, 2, 14))
	units.append(Units.make("ORC", 1, 18, 4))
	units.append(Units.make("ORC", 1, 20, 7))
	units.append(Units.make("WOLF", 1, 17, 8))
	units.append(Units.make("WOLF", 1, 21, 3))
	units.append(Units.make("ORC", 1, 15, 5))
	_center_on(units[0])

func _center_on(u: Dictionary) -> void:
	cam = Vector2(float(u["x"]) * TS, float(u["y"]) * TS) - VIEW.size * 0.5 + Vector2(TS, TS) * 0.5
	_clamp_cam()

func _clamp_cam() -> void:
	var ws: Vector2 = board.world_size()
	cam.x = clampf(cam.x, 0.0, maxf(ws.x - VIEW.size.x, 0.0))
	cam.y = clampf(cam.y, 0.0, maxf(ws.y - VIEW.size.y, 0.0))

# ---------------- queries ----------------

func unit_at(x: int, y: int) -> int:
	for i in units.size():
		var u: Dictionary = units[i]
		if int(u["hp"]) > 0 and int(u["x"]) == x and int(u["y"]) == y:
			return i
	return -1

func alive(team: int) -> int:
	var n := 0
	for u in units:
		var uu: Dictionary = u
		if int(uu["hp"]) > 0 and int(uu["team"]) == team:
			n += 1
	return n

func calc_reach(i: int) -> Dictionary:
	var u: Dictionary = units[i]
	var start := Vector2i(int(u["x"]), int(u["y"]))
	var out: Dictionary = {start: 0}
	var open: Array = [start]
	var mov: int = int(u["mov"])
	while open.size() > 0:
		var p: Vector2i = open.pop_front()
		var c: int = int(out[p])
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var np: Vector2i = p + d
			if not board.inside(np.x, np.y):
				continue
			var nc: int = c + board.cost(np.x, np.y)
			if nc > mov:
				continue
			var oi := unit_at(np.x, np.y)
			if oi >= 0 and int(units[oi]["team"]) != int(u["team"]):
				continue
			if out.has(np) and int(out[np]) <= nc:
				continue
			out[np] = nc
			open.append(np)
	return out

func targets_for(i: int) -> Array:
	var u: Dictionary = units[i]
	var rng: int = int(u["rng"])
	var out: Array = []
	for j in units.size():
		var o: Dictionary = units[j]
		if int(o["hp"]) <= 0 or int(o["team"]) == int(u["team"]):
			continue
		var dd: int = absi(int(u["x"]) - int(o["x"])) + absi(int(u["y"]) - int(o["y"]))
		if dd <= rng:
			out.append(j)
	return out

# ---------------- actions ----------------

func attack(a: int, b: int) -> void:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	var terr: int = board.defense(int(ub["x"]), int(ub["y"]))
	var roll := randi_range(-1, 2)
	var crit := roll >= 2
	var dmg: int = maxi(int(ua["atk"]) - int(ub["def"]) - terr + roll, 1)
	if crit:
		dmg = int(float(dmg) * 1.5)
	ub["hp"] = maxi(int(ub["hp"]) - dmg, 0)
	fx.hit(Vector2(float(ub["x"]) * TS, float(ub["y"]) * TS), dmg, crit)
	msg = "%d DAMAGE" % dmg
	if int(ub["hp"]) <= 0:
		msg = "%s DOWN" % ub["kind"]
	elif int(ub["rng"]) >= absi(int(ua["x"]) - int(ub["x"])) + absi(int(ua["y"]) - int(ub["y"])):
		var back: int = maxi(int(ub["atk"]) - int(ua["def"]) - board.defense(int(ua["x"]), int(ua["y"])), 1)
		ua["hp"] = maxi(int(ua["hp"]) - back, 0)
		fx.hit(Vector2(float(ua["x"]) * TS, float(ua["y"]) * TS), back, false)

func end_unit(i: int) -> void:
	units[i]["done"] = true
	sel = -1
	mode = Mode.IDLE
	reach.clear()
	targets.clear()
	_check_end()

func _check_end() -> void:
	if alive(1) == 0:
		phase = Phase.OVER
		msg = "VICTORY"
		return
	if alive(0) == 0:
		phase = Phase.OVER
		msg = "DEFEAT"
		return
	if phase == Phase.PLAYER:
		for u in units:
			var uu: Dictionary = u
			if int(uu["team"]) == 0 and int(uu["hp"]) > 0 and not bool(uu["done"]):
				return
		end_turn()

func end_turn() -> void:
	if phase != Phase.PLAYER:
		return
	sel = -1
	mode = Mode.IDLE
	reach.clear()
	targets.clear()
	phase = Phase.ENEMY
	msg = "ENEMY TURN"
	ai_i = 0
	ai_t = 0.45

func _ai_step() -> void:
	while ai_i < units.size():
		var e: Dictionary = units[ai_i]
		if int(e["team"]) != 1 or int(e["hp"]) <= 0:
			ai_i += 1
			continue
		var best := -1
		var bd := 9999
		for j in units.size():
			var p: Dictionary = units[j]
			if int(p["team"]) != 0 or int(p["hp"]) <= 0:
				continue
			var dd: int = absi(int(e["x"]) - int(p["x"])) + absi(int(e["y"]) - int(p["y"]))
			if dd < bd:
				bd = dd
				best = j
		if best < 0:
			ai_i += 1
			continue
		if bd <= int(e["rng"]):
			attack(ai_i, best)
			_center_on(e)
			ai_i += 1
			return
		var rc: Dictionary = calc_reach(ai_i)
		var tgt := Vector2i(int(units[best]["x"]), int(units[best]["y"]))
		var bp := Vector2i(int(e["x"]), int(e["y"]))
		var bdist := 9999
		for k in rc.keys():
			var kk: Vector2i = k
			if unit_at(kk.x, kk.y) >= 0:
				continue
			var dd2: int = absi(kk.x - tgt.x) + absi(kk.y - tgt.y)
			if dd2 < bdist:
				bdist = dd2
				bp = kk
		e["x"] = bp.x
		e["y"] = bp.y
		_center_on(e)
		if bdist <= int(e["rng"]):
			attack(ai_i, best)
		ai_i += 1
		return
	phase = Phase.PLAYER
	turn += 1
	for u in units:
		var uu: Dictionary = u
		uu["done"] = false
	msg = "YOUR TURN"
	_check_end()

# ---------------- input ----------------

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			down = true
			dragging = false
			touch_start = e.position
			touch_pos = e.position
		else:
			down = false
			if not dragging:
				_tap(e.position)
	elif e is InputEventScreenDrag and down:
		var dv: Vector2 = e.position - touch_pos
		touch_pos = e.position
		if touch_pos.distance_to(touch_start) > 8.0:
			dragging = true
		if dragging and VIEW.has_point(e.position):
			cam -= dv
			_clamp_cam()

func _cell(p: Vector2) -> Vector2i:
	if not VIEW.has_point(p):
		return Vector2i(-1, -1)
	var w: Vector2 = p - VIEW.position + cam
	return Vector2i(int(w.x / TS), int(w.y / TS))

func _btn_end() -> Rect2:
	return Rect2(534.0, 324.0, 100.0, 28.0)

func _btn_wait() -> Rect2:
	return Rect2(424.0, 324.0, 100.0, 28.0)

func _tap(p: Vector2) -> void:
	if phase == Phase.OVER:
		if _btn_end().has_point(p):
			_setup()
			phase = Phase.PLAYER
			turn = 1
			msg = "YOUR TURN"
		return
	if phase != Phase.PLAYER:
		return
	if _btn_end().has_point(p):
		end_turn()
		return
	if mode == Mode.TARGET and _btn_wait().has_point(p):
		end_unit(sel)
		return
	var c := _cell(p)
	if not board.inside(c.x, c.y):
		return
	var hit := unit_at(c.x, c.y)

	if mode == Mode.TARGET:
		if hit >= 0 and targets.has(hit):
			attack(sel, hit)
			end_unit(sel)
		return

	if mode == Mode.IDLE:
		if hit >= 0:
			var u: Dictionary = units[hit]
			if int(u["team"]) == 0 and not bool(u["done"]):
				sel = hit
				reach = calc_reach(hit)
				mode = Mode.MOVE
				msg = "MOVE"
		return

	# Mode.MOVE
	if hit == sel:
		_after_move()
		return
	var key := Vector2i(c.x, c.y)
	if reach.has(key) and hit < 0:
		units[sel]["x"] = c.x
		units[sel]["y"] = c.y
		_after_move()
	else:
		sel = -1
		mode = Mode.IDLE
		reach.clear()
		msg = "YOUR TURN"

func _after_move() -> void:
	reach.clear()
	targets = targets_for(sel)
	if targets.is_empty():
		end_unit(sel)
		msg = "YOUR TURN"
	else:
		mode = Mode.TARGET
		msg = "PICK TARGET"

# ---------------- loop ----------------

func _process(d: float) -> void:
	var dt: float = fx.tick(d)
	if phase == Phase.ENEMY and dt > 0.0:
		ai_t -= dt
		if ai_t <= 0.0:
			ai_t = 0.5
			_ai_step()
			_check_end()
	queue_redraw()

# ---------------- draw ----------------

func _draw() -> void:
	var off: Vector2 = fx.offset()
	draw_set_transform(off, 0.0, Vector2.ONE)
	board.draw_map(self, cam, VIEW)
	_draw_overlay()
	_draw_units()
	fx.draw_pops(self, cam, VIEW)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	fx.draw_flash(self, VIEW)
	_draw_hud()

func _tile_rect(x: int, y: int) -> Rect2:
	var p := Vector2(float(x) * TS, float(y) * TS) - cam + VIEW.position
	return Rect2(p.x, p.y, TS, TS)

func _draw_overlay() -> void:
	for k in reach.keys():
		var kk: Vector2i = k
		var r := _tile_rect(kk.x, kk.y)
		if not VIEW.intersects(r):
			continue
		draw_rect(r, Color(0.30, 0.58, 1.0, 0.35))
		draw_rect(r, Color(0.55, 0.78, 1.0, 0.5), false, 1.0)
	for j in targets:
		var o: Dictionary = units[int(j)]
		var r2 := _tile_rect(int(o["x"]), int(o["y"]))
		draw_rect(r2, Color(1.0, 0.25, 0.2, 0.38))
		draw_rect(r2, Color(1.0, 0.5, 0.4, 0.8), false, 1.0)

func _draw_units() -> void:
	var order: Array = []
	for i in units.size():
		order.append(i)
	order.sort_custom(func(a, b): return int(units[int(a)]["y"]) < int(units[int(b)]["y"]))
	for i in order:
		var u: Dictionary = units[int(i)]
		if int(u["hp"]) <= 0:
			continue
		var r := _tile_rect(int(u["x"]), int(u["y"]))
		if r.end.x < VIEW.position.x - 48.0 or r.position.x > VIEW.end.x + 48.0:
			continue
		if r.end.y < VIEW.position.y - 48.0 or r.position.y > VIEW.end.y + 48.0:
			continue
		var frame := 0
		if int(Time.get_ticks_msec() / 420) % 2 == 1:
			frame = 1
		var tex := Gfx.art("%s%d" % [u["kind"], frame])
		var dst := Rect2(r.position.x - 8.0, r.position.y - 16.0, 48.0, 48.0)
		if bool(u["done"]):
			draw_texture_rect_region(tex, dst, Rect2(0.0, 0.0, 48.0, 48.0), Color(0.55, 0.6, 0.7, 1.0))
		else:
			draw_texture_rect_region(tex, dst, Rect2(0.0, 0.0, 48.0, 48.0))
		var ratio: float = float(u["hp"]) / float(u["mhp"])
		draw_rect(Rect2(r.position.x + 3.0, r.position.y + 27.0, 26.0, 4.0), Pal.c("black"))
		draw_rect(Rect2(r.position.x + 4.0, r.position.y + 28.0, 24.0 * ratio, 2.0), Pal.team(int(u["team"])))
	if sel >= 0:
		var s: Dictionary = units[sel]
		var rs := _tile_rect(int(s["x"]), int(s["y"]))
		var blink: Color = Pal.c("yellow")
		if int(Time.get_ticks_msec() / 200) % 2 == 0:
			blink = Pal.c("white")
		draw_rect(rs, blink, false, 2.0)

func _panel(r: Rect2) -> void:
	draw_rect(r, Pal.c("panel"))
	draw_rect(r, Pal.c("line"), false, 1.0)

func _draw_hud() -> void:
	_panel(Rect2(0.0, 0.0, 640.0, 20.0))
	Gfx.text(self, "TURN %d" % turn, Vector2(6.0, 6.0), Pal.c("white"))
	Gfx.text(self, msg, Vector2(96.0, 6.0), Pal.c("yellow"))
	Gfx.text(self, "ALLY %d   FOE %d" % [alive(0), alive(1)], Vector2(430.0, 6.0), Pal.c("gray"))

	_panel(Rect2(0.0, 316.0, 640.0, 44.0))
	if sel >= 0:
		var u: Dictionary = units[sel]
		var st: Dictionary = Units.STATS[u["kind"]]
		Gfx.text(self, String(st["label"]), Vector2(8.0, 322.0), Pal.c("white"))
		Gfx.text(self, "HP %d/%d" % [int(u["hp"]), int(u["mhp"])], Vector2(8.0, 338.0), Pal.c("lgreen"))
		Gfx.text(self, "ATK %d" % int(u["atk"]), Vector2(120.0, 322.0), Pal.c("gray"))
		Gfx.text(self, "DEF %d" % int(u["def"]), Vector2(120.0, 338.0), Pal.c("gray"))
		Gfx.text(self, "MOV %d" % int(u["mov"]), Vector2(206.0, 322.0), Pal.c("gray"))
		Gfx.text(self, "RNG %d" % int(u["rng"]), Vector2(206.0, 338.0), Pal.c("gray"))
		var tr: int = board.defense(int(u["x"]), int(u["y"]))
		Gfx.text(self, "TERRAIN +%d" % tr, Vector2(292.0, 322.0), Pal.c("cyan"))
	else:
		Gfx.text(self, "TAP A UNIT TO MOVE.  DRAG TO SCROLL.", Vector2(8.0, 330.0), Pal.c("gray"))

	if mode == Mode.TARGET:
		var bw := _btn_wait()
		_panel(bw)
		Gfx.text(self, "WAIT", Vector2(bw.position.x + 32.0, bw.position.y + 10.0), Pal.c("white"))
	var be := _btn_end()
	_panel(be)
	var lbl := "END TURN"
	if phase == Phase.OVER:
		lbl = "RESTART"
	Gfx.text(self, lbl, Vector2(be.position.x + 26.0, be.position.y + 10.0), Pal.c("white"))
