extends Node2D

enum Phase { PLAYER, ENEMY, OVER }
enum Mode { IDLE, MOVE, TARGET }

const VIEW := Rect2(0.0, 20.0, 640.0, 296.0)
const TS := 32.0
const WALK := 0.13
const LUNGE := 0.46

var board = null
var fx = null

var units: Array = []
var phase: int = Phase.PLAYER
var mode: int = Mode.IDLE
var sel := -1
var reach: Dictionary = {}
var parent: Dictionary = {}
var targets: Array = []
var turn := 1
var msg := "TAP A UNIT"

var cursor := Vector2i(-1, -1)
var path_preview: Array = []
var pending_target := -1

var cam := Vector2.ZERO
var touch_start := Vector2.ZERO
var touch_pos := Vector2.ZERO
var dragging := false
var down := false

var anim: Dictionary = {}
var queue: Array = []
var ai_i := 0
var ai_t := 0.0

var banner := ""
var banner_t := 0.0

func _ready() -> void:
	board = preload("res://scripts/Board.gd").new()
	add_child(board)
	fx = preload("res://scripts/Fx.gd").new()
	add_child(fx)
	_setup()

func _setup() -> void:
	units = []
	_add("KNIGHT", 0, 3, 10)
	_add("LANCER", 0, 2, 12)
	_add("ARCHER", 0, 4, 13)
	_add("MAGE", 0, 2, 14)
	_add("ORC", 1, 18, 4)
	_add("ORC", 1, 20, 7)
	_add("ORC", 1, 15, 5)
	_add("WOLF", 1, 17, 8)
	_add("WOLF", 1, 21, 3)
	queue.clear()
	anim = {}
	_center_on(units[0])
	_banner("YOUR TURN")

func _add(kind: String, team: int, x: int, y: int) -> void:
	var u: Dictionary = Units.make(kind, team, x, y)
	u["px"] = Vector2(float(x) * TS, float(y) * TS)
	u["face"] = 1
	if team == 1:
		u["face"] = -1
	u["flash"] = 0.0
	u["fade"] = 1.0
	u["nudge"] = Vector2.ZERO
	units.append(u)

func _banner(t: String) -> void:
	banner = t
	banner_t = 1.1

func _center_on(u: Dictionary) -> void:
	_cam_to(Vector2(u["px"]) - VIEW.size * 0.5 + Vector2(TS, TS) * 0.5)

func _cam_to(p: Vector2) -> void:
	cam = p
	_clamp_cam()

func _clamp_cam() -> void:
	var ws: Vector2 = board.world_size()
	cam.x = clampf(cam.x, 0.0, maxf(ws.x - VIEW.size.x, 0.0))
	cam.y = clampf(cam.y, 0.0, maxf(ws.y - VIEW.size.y, 0.0))

func busy() -> bool:
	return anim.size() > 0 or queue.size() > 0

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

func calc_reach(i: int) -> void:
	var u: Dictionary = units[i]
	var start := Vector2i(int(u["x"]), int(u["y"]))
	reach = {start: 0}
	parent = {}
	var open: Array = [start]
	var mov: int = int(u["mov"])
	while open.size() > 0:
		var p: Vector2i = open.pop_front()
		var c: int = int(reach[p])
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
			if reach.has(np) and int(reach[np]) <= nc:
				continue
			reach[np] = nc
			parent[np] = p
			open.append(np)

func path_to(goal: Vector2i) -> Array:
	var out: Array = [goal]
	var cur := goal
	var guard := 0
	while parent.has(cur) and guard < 400:
		cur = parent[cur]
		out.push_front(cur)
		guard += 1
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

func forecast(a: int, b: int) -> int:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	var terr: int = board.defense(int(ub["x"]), int(ub["y"]))
	return maxi(int(ua["atk"]) - int(ub["def"]) - terr, 1)

# ---------------- animation queue ----------------

func q_move(i: int, path: Array) -> void:
	queue.append({"k": "move", "u": i, "path": path, "step": 0, "t": 0.0})

func q_attack(a: int, b: int) -> void:
	queue.append({"k": "attack", "a": a, "b": b, "t": 0.0, "done": false})

func q_wait(sec: float) -> void:
	queue.append({"k": "wait", "t": 0.0, "len": sec})

func q_cam(to: Vector2) -> void:
	queue.append({"k": "cam", "from": cam, "to": to, "t": 0.0})

func _resolve(a: int, b: int) -> void:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	var terr: int = board.defense(int(ub["x"]), int(ub["y"]))
	var roll := randi_range(-1, 2)
	var crit := roll >= 2
	var dmg: int = maxi(int(ua["atk"]) - int(ub["def"]) - terr + roll, 1)
	if crit:
		dmg = int(float(dmg) * 1.5)
	ub["hp"] = maxi(int(ub["hp"]) - dmg, 0)
	ub["flash"] = 0.22
	var dir: Vector2 = (Vector2(ub["px"]) - Vector2(ua["px"])).normalized()
	ub["nudge"] = dir * 7.0
	fx.hit(Vector2(ub["px"]), dmg, crit)
	msg = "%d DAMAGE" % dmg
	if crit:
		msg = "CRITICAL %d" % dmg
	if int(ub["hp"]) <= 0:
		msg = "%s DOWN" % ub["kind"]
		queue.append({"k": "death", "u": b, "t": 0.0})

func _counter_ok(a: int, b: int) -> bool:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	if int(ub["hp"]) <= 0:
		return false
	var dd: int = absi(int(ua["x"]) - int(ub["x"])) + absi(int(ua["y"]) - int(ub["y"]))
	return dd <= int(ub["rng"])

func _step_anim(dt: float) -> void:
	if anim.is_empty():
		if queue.is_empty():
			return
		anim = queue.pop_front()
	var k: String = anim["k"]
	anim["t"] = float(anim["t"]) + dt
	var t: float = float(anim["t"])

	if k == "wait":
		if t >= float(anim["len"]):
			anim = {}
		return

	if k == "cam":
		var f: Vector2 = anim["from"]
		var to: Vector2 = anim["to"]
		var p: float = clampf(t / 0.32, 0.0, 1.0)
		_cam_to(f.lerp(to, p * p * (3.0 - 2.0 * p)))
		if p >= 1.0:
			anim = {}
		return

	if k == "move":
		var i: int = anim["u"]
		var u: Dictionary = units[i]
		var path: Array = anim["path"]
		var step: int = anim["step"]
		if step >= path.size() - 1:
			u["px"] = Vector2(float(u["x"]) * TS, float(u["y"]) * TS)
			anim = {}
			return
		var a: Vector2i = path[step]
		var b: Vector2i = path[step + 1]
		var p2: float = clampf(t / WALK, 0.0, 1.0)
		var pa := Vector2(float(a.x) * TS, float(a.y) * TS)
		var pb := Vector2(float(b.x) * TS, float(b.y) * TS)
		u["px"] = pa.lerp(pb, p2)
		if b.x > a.x:
			u["face"] = 1
		elif b.x < a.x:
			u["face"] = -1
		_follow(Vector2(u["px"]))
		if p2 >= 1.0:
			anim["step"] = step + 1
			anim["t"] = 0.0
		return

	if k == "attack":
		var ai: int = anim["a"]
		var bi: int = anim["b"]
		var ua: Dictionary = units[ai]
		var ub: Dictionary = units[bi]
		var home := Vector2(float(ua["x"]) * TS, float(ua["y"]) * TS)
		var tgt := Vector2(float(ub["x"]) * TS, float(ub["y"]) * TS)
		var dir: Vector2 = (tgt - home).normalized()
		if dir.x > 0.0:
			ua["face"] = 1
		elif dir.x < 0.0:
			ua["face"] = -1
		var p3: float = clampf(t / LUNGE, 0.0, 1.0)
		ua["px"] = home + dir * sin(p3 * PI) * 11.0
		if t >= LUNGE * 0.32 and not bool(anim["done"]):
			anim["done"] = true
			_resolve(ai, bi)
			if int(ub["hp"]) > 0 and _counter_ok(ai, bi):
				q_attack(bi, ai)
		if p3 >= 1.0:
			ua["px"] = home
			anim = {}
		return

	if k == "death":
		var di: int = anim["u"]
		var ud: Dictionary = units[di]
		ud["fade"] = clampf(1.0 - t / 0.45, 0.0, 1.0)
		if t >= 0.45:
			ud["fade"] = 0.0
			anim = {}
		return

	anim = {}

func _follow(p: Vector2) -> void:
	var s := p - cam + VIEW.position
	var m := 74.0
	if s.x < VIEW.position.x + m:
		cam.x -= (VIEW.position.x + m - s.x)
	if s.x > VIEW.end.x - m:
		cam.x += (s.x - (VIEW.end.x - m))
	if s.y < VIEW.position.y + m:
		cam.y -= (VIEW.position.y + m - s.y)
	if s.y > VIEW.end.y - m:
		cam.y += (s.y - (VIEW.end.y - m))
	_clamp_cam()

# ---------------- turn flow ----------------

func clear_sel() -> void:
	sel = -1
	mode = Mode.IDLE
	reach.clear()
	parent.clear()
	targets.clear()
	path_preview.clear()
	cursor = Vector2i(-1, -1)
	pending_target = -1

func end_unit(i: int) -> void:
	units[i]["done"] = true
	clear_sel()

func _check_end() -> void:
	if phase == Phase.OVER:
		return
	if alive(1) == 0:
		phase = Phase.OVER
		_banner("VICTORY")
		msg = "VICTORY"
		return
	if alive(0) == 0:
		phase = Phase.OVER
		_banner("DEFEAT")
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
	clear_sel()
	phase = Phase.ENEMY
	_banner("ENEMY TURN")
	msg = "ENEMY TURN"
	ai_i = 0
	ai_t = 0.7

func _ai_step() -> void:
	while ai_i < units.size():
		var idx := ai_i
		var e: Dictionary = units[idx]
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
		ai_i += 1
		q_cam(Vector2(e["px"]) - VIEW.size * 0.5)
		q_wait(0.22)
		if bd <= int(e["rng"]):
			q_attack(idx, best)
			return
		calc_reach(idx)
		var tgt := Vector2i(int(units[best]["x"]), int(units[best]["y"]))
		var bp := Vector2i(int(e["x"]), int(e["y"]))
		var bdist := 9999
		for kk in reach.keys():
			var c: Vector2i = kk
			if unit_at(c.x, c.y) >= 0:
				continue
			var dd2: int = absi(c.x - tgt.x) + absi(c.y - tgt.y)
			if dd2 < bdist:
				bdist = dd2
				bp = c
		var pth := path_to(bp)
		e["x"] = bp.x
		e["y"] = bp.y
		q_move(idx, pth)
		reach.clear()
		parent.clear()
		if bdist <= int(e["rng"]):
			q_attack(idx, best)
		return
	phase = Phase.PLAYER
	turn += 1
	for u in units:
		var uu: Dictionary = u
		uu["done"] = false
	_banner("YOUR TURN")
	msg = "TAP A UNIT"
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
	return Rect2(528.0, 322.0, 106.0, 30.0)

func _btn_wait() -> Rect2:
	return Rect2(414.0, 322.0, 106.0, 30.0)

func _tap(p: Vector2) -> void:
	if busy():
		return
	if phase == Phase.OVER:
		if _btn_end().has_point(p):
			phase = Phase.PLAYER
			turn = 1
			_setup()
			msg = "TAP A UNIT"
		return
	if phase != Phase.PLAYER:
		return
	if _btn_end().has_point(p):
		end_turn()
		return
	if mode == Mode.TARGET and _btn_wait().has_point(p):
		end_unit(sel)
		_check_end()
		return
	var c := _cell(p)
	if not board.inside(c.x, c.y):
		return
	var hit := unit_at(c.x, c.y)

	if mode == Mode.TARGET:
		if hit >= 0 and targets.has(hit):
			if pending_target == hit:
				var a := sel
				q_attack(a, hit)
				end_unit(a)
			else:
				pending_target = hit
				cursor = c
				msg = "TAP AGAIN TO ATTACK"
		return

	if mode == Mode.IDLE:
		cursor = c
		if hit >= 0:
			var u: Dictionary = units[hit]
			if int(u["team"]) == 0 and not bool(u["done"]):
				sel = hit
				calc_reach(hit)
				mode = Mode.MOVE
				path_preview.clear()
				msg = "TAP A TILE"
			else:
				sel = hit
				msg = "UNIT INFO"
		else:
			sel = -1
			msg = "TAP A UNIT"
		return

	if hit == sel:
		_after_move()
		return
	var key := Vector2i(c.x, c.y)
	if reach.has(key) and hit < 0:
		if cursor == key and path_preview.size() > 0:
			var mover := sel
			q_move(mover, path_preview)
			units[mover]["x"] = c.x
			units[mover]["y"] = c.y
			reach.clear()
			parent.clear()
			path_preview.clear()
			cursor = Vector2i(-1, -1)
			_after_move()
		else:
			cursor = key
			path_preview = path_to(key)
			msg = "TAP AGAIN TO MOVE"
	else:
		clear_sel()
		msg = "TAP A UNIT"

func _after_move() -> void:
	reach.clear()
	parent.clear()
	targets = targets_for(sel)
	pending_target = -1
	if targets.is_empty():
		end_unit(sel)
		msg = "TAP A UNIT"
		_check_end()
	else:
		mode = Mode.TARGET
		msg = "PICK A TARGET"

# ---------------- loop ----------------

func _process(d: float) -> void:
	var dt: float = fx.tick(d)
	if banner_t > 0.0:
		banner_t = maxf(banner_t - d, 0.0)
	for u in units:
		var uu: Dictionary = u
		uu["flash"] = maxf(float(uu["flash"]) - d, 0.0)
		uu["nudge"] = Vector2(uu["nudge"]).move_toward(Vector2.ZERO, 60.0 * d)
	if dt > 0.0:
		_step_anim(dt)
		if not busy():
			if phase == Phase.ENEMY:
				ai_t -= dt
				if ai_t <= 0.0:
					ai_t = 0.28
					_ai_step()
					_check_end()
			elif phase == Phase.PLAYER:
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
	_draw_banner()

func _tile_rect(x: int, y: int) -> Rect2:
	var p := Vector2(float(x) * TS, float(y) * TS) - cam + VIEW.position
	return Rect2(p.x, p.y, TS, TS)

func _draw_overlay() -> void:
	for k in reach.keys():
		var kk: Vector2i = k
		var r := _tile_rect(kk.x, kk.y)
		if not VIEW.intersects(r):
			continue
		draw_rect(r, Color(0.28, 0.56, 1.0, 0.30))
		draw_rect(r, Color(0.55, 0.78, 1.0, 0.42), false, 1.0)
	if path_preview.size() > 1:
		for i in range(path_preview.size() - 1):
			var a: Vector2i = path_preview[i]
			var b: Vector2i = path_preview[i + 1]
			draw_line(_tile_rect(a.x, a.y).get_center(), _tile_rect(b.x, b.y).get_center(), Pal.c("yellow"), 3.0)
		var last: Vector2i = path_preview[path_preview.size() - 1]
		draw_rect(_tile_rect(last.x, last.y), Pal.c("yellow"), false, 2.0)
	for j in targets:
		var o: Dictionary = units[int(j)]
		var r2 := _tile_rect(int(o["x"]), int(o["y"]))
		draw_rect(r2, Color(1.0, 0.25, 0.2, 0.32))
		var lc: Color = Pal.c("red")
		if int(j) == pending_target:
			lc = Pal.c("yellow")
		draw_rect(r2, lc, false, 2.0)
	if cursor.x >= 0 and mode == Mode.IDLE:
		draw_rect(_tile_rect(cursor.x, cursor.y), Pal.c("white"), false, 1.0)

func _by_depth(a, b) -> bool:
	var ua: Dictionary = units[int(a)]
	var ub: Dictionary = units[int(b)]
	return Vector2(ua["px"]).y < Vector2(ub["px"]).y

func _draw_units() -> void:
	var order: Array = []
	for i in units.size():
		order.append(i)
	order.sort_custom(_by_depth)
	for i in order:
		var u: Dictionary = units[int(i)]
		if float(u["fade"]) <= 0.0:
			continue
		var sp: Vector2 = Vector2(u["px"]) + Vector2(u["nudge"]) - cam + VIEW.position
		if sp.x < VIEW.position.x - 64.0 or sp.x > VIEW.end.x + 64.0:
			continue
		if sp.y < VIEW.position.y - 64.0 or sp.y > VIEW.end.y + 64.0:
			continue
		var frame := 0
		var moving := false
		if not anim.is_empty():
			if String(anim["k"]) == "move" and int(anim["u"]) == int(i):
				moving = true
		if moving:
			if int(float(anim["t"]) / (WALK * 0.5)) % 2 == 1:
				frame = 1
		elif int(Time.get_ticks_msec() / 520) % 2 == 1:
			frame = 1
		var nm := "%s%d" % [u["kind"], frame]
		var flip: bool = int(u["face"]) < 0
		var tex: Texture2D = Gfx.art_v(nm, false, flip)
		var dst := Rect2(sp.x - 8.0, sp.y - 16.0, 48.0, 48.0)
		var src := Rect2(0.0, 0.0, 48.0, 48.0)
		var tint := Color(1, 1, 1, float(u["fade"]))
		if bool(u["done"]) and int(u["hp"]) > 0:
			tint = Color(0.56, 0.62, 0.72, float(u["fade"]))
		draw_texture_rect_region(tex, dst, src, tint)
		if float(u["flash"]) > 0.0:
			var wt: Texture2D = Gfx.art_v(nm, true, flip)
			draw_texture_rect_region(wt, dst, src, Color(1, 1, 1, float(u["flash"]) / 0.22 * 0.85))
		if int(u["hp"]) > 0:
			var ratio: float = float(u["hp"]) / float(u["mhp"])
			draw_rect(Rect2(sp.x + 3.0, sp.y + 27.0, 26.0, 4.0), Color(0, 0, 0, 0.7))
			draw_rect(Rect2(sp.x + 4.0, sp.y + 28.0, 24.0 * ratio, 2.0), Pal.team(int(u["team"])))
	if sel >= 0 and int(units[sel]["hp"]) > 0:
		var s: Dictionary = units[sel]
		var rs := _tile_rect(int(s["x"]), int(s["y"]))
		var blink: Color = Pal.c("yellow")
		if int(Time.get_ticks_msec() / 220) % 2 == 0:
			blink = Pal.c("white")
		draw_rect(rs, blink, false, 2.0)

func _panel(r: Rect2) -> void:
	draw_rect(r, Pal.c("panel"))
	draw_rect(r, Pal.c("line"), false, 1.0)

func _draw_hud() -> void:
	_panel(Rect2(0.0, 0.0, 640.0, 20.0))
	Gfx.text(self, "TURN %d" % turn, Vector2(6.0, 6.0), Pal.c("white"))
	Gfx.text(self, msg, Vector2(100.0, 6.0), Pal.c("yellow"))
	Gfx.text(self, "ALLY %d  FOE %d" % [alive(0), alive(1)], Vector2(452.0, 6.0), Pal.c("gray"))

	_panel(Rect2(0.0, 316.0, 640.0, 44.0))
	if sel >= 0:
		var u: Dictionary = units[sel]
		var st: Dictionary = Units.STATS[u["kind"]]
		Gfx.text(self, String(st["label"]), Vector2(8.0, 322.0), Pal.c("white"))
		Gfx.text(self, "HP %d/%d" % [int(u["hp"]), int(u["mhp"])], Vector2(8.0, 338.0), Pal.c("lgreen"))
		Gfx.text(self, "ATK %d" % int(u["atk"]), Vector2(112.0, 322.0), Pal.c("gray"))
		Gfx.text(self, "DEF %d" % int(u["def"]), Vector2(112.0, 338.0), Pal.c("gray"))
		Gfx.text(self, "MOV %d" % int(u["mov"]), Vector2(190.0, 322.0), Pal.c("gray"))
		Gfx.text(self, "RNG %d" % int(u["rng"]), Vector2(190.0, 338.0), Pal.c("gray"))
		Gfx.text(self, "TERRAIN +%d" % int(board.defense(int(u["x"]), int(u["y"]))), Vector2(268.0, 322.0), Pal.c("cyan"))
		if pending_target >= 0:
			Gfx.text(self, "FORECAST %d DMG" % forecast(sel, pending_target), Vector2(268.0, 338.0), Pal.c("orange"))
	elif cursor.x >= 0:
		var kk: int = board.at(cursor.x, cursor.y)
		Gfx.text(self, "TERRAIN %s" % String(Art.TILE_KINDS[kk]), Vector2(8.0, 322.0), Pal.c("white"))
		Gfx.text(self, "COST %d   DEF +%d" % [int(board.cost(cursor.x, cursor.y)), int(board.defense(cursor.x, cursor.y))], Vector2(8.0, 338.0), Pal.c("gray"))
	else:
		Gfx.text(self, "TAP A UNIT TO MOVE.   DRAG TO SCROLL.", Vector2(8.0, 330.0), Pal.c("gray"))

	if mode == Mode.TARGET:
		var bw := _btn_wait()
		_panel(bw)
		Gfx.text(self, "WAIT", Vector2(bw.position.x + 34.0, bw.position.y + 11.0), Pal.c("white"))
	var be := _btn_end()
	_panel(be)
	var lbl := "END TURN"
	if phase == Phase.OVER:
		lbl = "RESTART"
	Gfx.text(self, lbl, Vector2(be.position.x + 28.0, be.position.y + 11.0), Pal.c("white"))

func _draw_banner() -> void:
	if banner_t <= 0.0:
		return
	var a: float = clampf(banner_t / 0.35, 0.0, 1.0)
	var w := float(Gfx.text_width(banner)) + 40.0
	var r := Rect2(320.0 - w * 0.5, 148.0, w, 34.0)
	draw_rect(r, Color(0.05, 0.07, 0.10, 0.86 * a))
	var y: Color = Pal.c("yellow")
	draw_rect(r, Color(y.r, y.g, y.b, a), false, 2.0)
	Gfx.text(self, banner, Vector2(320.0 - float(Gfx.text_width(banner)) * 0.5, 160.0), Color(1, 1, 1, a))
