extends Node2D

signal finished(win: bool)

enum Sub { MOVE, TARGET, SKILL }

const VIEW := Rect2(0.0, 20.0, 640.0, 296.0)
const TS := 32.0
const WALK := 0.13
const LUNGE := 0.46

var board = null
var fx = null
var map_i := 0
var mapdef: Dictionary = {}
var goal := Vector2i(-1, -1)
var limit := 0
var result_sent := false

var units: Array = []
var order: Array = []
var oi := 0
var rnd := 1
var active := -1
var over := false

var sub: int = Sub.MOVE
var reach: Dictionary = {}
var parent: Dictionary = {}
var targets: Array = []
var cursor := Vector2i(-1, -1)
var path_preview: Array = []
var pending := -1
var msg := ""

var cam := Vector2.ZERO
var touch_start := Vector2.ZERO
var touch_pos := Vector2.ZERO
var dragging := false
var down := false

var anim: Dictionary = {}
var queue: Array = []
var ai_t := 0.0

var banner := ""
var banner_t := 0.0

func _ready() -> void:
	board = preload("res://scripts/Board.gd").new()
	add_child(board)
	fx = preload("res://scripts/Fx.gd").new()
	add_child(fx)

func start(index: int) -> void:
	map_i = index
	mapdef = Maps.get_map(index)
	board.load_rows(mapdef["rows"])
	goal = mapdef["goal"]
	limit = int(mapdef["rounds"])
	_setup()

func _setup() -> void:
	units = []
	var spawn: Array = mapdef["spawn"]
	var n: int = mini(Save.roster.size(), spawn.size())
	for i in n:
		var sp: Array = spawn[i]
		var entry: Dictionary = Save.roster[i]
		var u: Dictionary = Save.make_unit(entry, int(sp[0]), int(sp[1]))
		_push(u, 0)
	var foes: Array = mapdef["enemies"]
	for e in foes:
		var ee: Array = e
		var eu: Dictionary = Units.make(String(ee[0]), 1, int(ee[1]), int(ee[2]))
		if int(ee[3]) == 1:
			eu["boss"] = true
			eu["hp"] = int(eu["hp"]) + 14
			eu["mhp"] = int(eu["mhp"]) + 14
			eu["atk"] = int(eu["atk"]) + 3
			eu["def"] = int(eu["def"]) + 2
		_push(eu, 1)
	_validate()
	queue.clear()
	anim = {}
	over = false
	result_sent = false
	rnd = 0
	_begin_round()
	_banner(Maps.name_of(mapdef))

func _push(u: Dictionary, team: int) -> void:
	u["px"] = Vector2(float(u["x"]) * TS, float(u["y"]) * TS)
	u["face"] = 1
	u["dir"] = Vector2i(0, 1)
	if team == 1:
		u["face"] = -1
		u["dir"] = Vector2i(-1, 0)
	u["flash"] = 0.0
	u["fade"] = 1.0
	u["nudge"] = Vector2.ZERO
	if not u.has("boss"):
		u["boss"] = false
	units.append(u)

func _free_tile(x: int, y: int, self_i: int) -> bool:
	if not board.inside(x, y):
		return false
	if board.cost(x, y) >= 99:
		return false
	for i in units.size():
		if i == self_i:
			continue
		var o: Dictionary = units[i]
		if int(o["x"]) == x and int(o["y"]) == y:
			return false
	return true

func _validate() -> void:
	for i in units.size():
		var u: Dictionary = units[i]
		if _free_tile(int(u["x"]), int(u["y"]), i):
			continue
		var found := false
		for r in range(1, 8):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if absi(dx) != r and absi(dy) != r:
						continue
					var nx: int = int(u["x"]) + dx
					var ny: int = int(u["y"]) + dy
					if _free_tile(nx, ny, i):
						u["x"] = nx
						u["y"] = ny
						u["px"] = Vector2(float(nx) * TS, float(ny) * TS)
						found = true
						break
				if found:
					break
			if found:
				break
	var start := Vector2i(-1, -1)
	for u2 in units:
		var uu: Dictionary = u2
		if int(uu["team"]) == 0:
			start = Vector2i(int(uu["x"]), int(uu["y"]))
			break
	if start.x < 0:
		return
	var seen: Dictionary = {start: true}
	var open: Array = [start]
	while open.size() > 0:
		var p: Vector2i = open.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var np: Vector2i = p + d
			if seen.has(np):
				continue
			if not board.inside(np.x, np.y):
				continue
			if board.cost(np.x, np.y) >= 99:
				continue
			seen[np] = true
			open.append(np)
	var lost := 0
	for u3 in units:
		var uu3: Dictionary = u3
		if int(uu3["team"]) != 1:
			continue
		if not seen.has(Vector2i(int(uu3["x"]), int(uu3["y"]))):
			lost += 1
	if lost > 0:
		msg = "MAP WARNING %d FOES CUT OFF" % lost

func _banner(t: String) -> void:
	banner = t
	banner_t = 1.05

func _cam_to(p: Vector2) -> void:
	cam = p
	_clamp_cam()

func _clamp_cam() -> void:
	var ws: Vector2 = board.world_size()
	cam.x = clampf(cam.x, 0.0, maxf(ws.x - VIEW.size.x, 0.0))
	cam.y = clampf(cam.y, 0.0, maxf(ws.y - VIEW.size.y, 0.0))

func busy() -> bool:
	return anim.size() > 0 or queue.size() > 0

# ------------- order -------------

func _begin_round() -> void:
	rnd += 1
	if String(mapdef["win"]) == "SURVIVE" and rnd > limit:
		_finish(true)
		return
	order = []
	for i in units.size():
		var u: Dictionary = units[i]
		if int(u["hp"]) > 0:
			order.append(i)
	order.sort_custom(_by_speed)
	for i in units.size():
		var uu: Dictionary = units[i]
		uu["moved"] = false
		uu["acted"] = false
	oi = -1
	_banner("ROUND %d" % rnd)
	_next_unit()

func _by_speed(a, b) -> bool:
	var ua: Dictionary = units[int(a)]
	var ub: Dictionary = units[int(b)]
	if int(ua["spd"]) != int(ub["spd"]):
		return int(ua["spd"]) > int(ub["spd"])
	if int(ua["team"]) != int(ub["team"]):
		return int(ua["team"]) < int(ub["team"])
	return int(a) < int(b)

func _next_unit() -> void:
	_clear_sel()
	oi += 1
	while oi < order.size():
		var i: int = int(order[oi])
		if int(units[i]["hp"]) > 0:
			break
		oi += 1
	if oi >= order.size():
		_begin_round()
		return
	active = int(order[oi])
	var u: Dictionary = units[active]
	u["guard"] = false
	q_cam(Vector2(u["px"]) - VIEW.size * 0.5)
	if int(u["team"]) == 0:
		sub = Sub.MOVE
		_calc_reach(active)
		msg = Gfx.L("移動か行動", "MOVE OR ACT")
	else:
		msg = Gfx.L("敵の手番", "ENEMY TURN")
		ai_t = 0.35

func _end_unit() -> void:
	if active >= 0:
		units[active]["acted"] = true
	_clear_sel()
	_check_over()
	if over:
		return
	_next_unit()

func _clear_sel() -> void:
	reach.clear()
	parent.clear()
	targets.clear()
	path_preview.clear()
	cursor = Vector2i(-1, -1)
	pending = -1

func _boss_alive() -> bool:
	for u in units:
		var uu: Dictionary = u
		if int(uu["team"]) == 1 and bool(uu["boss"]) and int(uu["hp"]) > 0:
			return true
	return false

func _on_goal() -> bool:
	if goal.x < 0:
		return false
	for u in units:
		var uu: Dictionary = u
		if int(uu["team"]) == 0 and int(uu["hp"]) > 0:
			if int(uu["x"]) == goal.x and int(uu["y"]) == goal.y:
				return true
	return false

func _check_over() -> void:
	if over:
		return
	if alive(0) == 0:
		_finish(false)
		return
	var w: String = String(mapdef["win"])
	if w == "ROUT":
		if alive(1) == 0:
			_finish(true)
	elif w == "BOSS":
		if not _boss_alive():
			_finish(true)
	elif w == "REACH":
		if _on_goal():
			_finish(true)
	elif w == "SURVIVE":
		if rnd > limit:
			_finish(true)

func _finish(win: bool) -> void:
	over = true
	if win:
		Sound.bgm("win")
		_banner(Gfx.L("任務達成", "MISSION CLEAR"))
		msg = "CLEAR"
	else:
		Sound.bgm("lose")
		_banner(Gfx.L("敗北", "DEFEAT"))
		msg = "DEFEAT"

# ------------- queries -------------

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

func _calc_reach(i: int) -> void:
	var u: Dictionary = units[i]
	reach = {}
	parent = {}
	if bool(u["moved"]):
		return
	var start := Vector2i(int(u["x"]), int(u["y"]))
	reach = {start: 0}
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
			var oi2 := unit_at(np.x, np.y)
			if oi2 >= 0 and int(units[oi2]["team"]) != int(u["team"]):
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

func dist(a: int, b: int) -> int:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	return absi(int(ua["x"]) - int(ub["x"])) + absi(int(ua["y"]) - int(ub["y"]))

func in_range(i: int, r: int, hostile: bool) -> Array:
	var u: Dictionary = units[i]
	var out: Array = []
	for j in units.size():
		var o: Dictionary = units[j]
		if int(o["hp"]) <= 0:
			continue
		if hostile and int(o["team"]) == int(u["team"]):
			continue
		if not hostile and int(o["team"]) != int(u["team"]):
			continue
		if not hostile and j == i:
			continue
		if dist(i, j) <= r:
			out.append(j)
	return out

func flank(a: int, b: int) -> float:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	var v := Vector2i(int(ua["x"]) - int(ub["x"]), int(ua["y"]) - int(ub["y"]))
	var f: Vector2i = ub["dir"]
	var dot: int = v.x * f.x + v.y * f.y
	if dot > 0:
		return 1.0
	if dot < 0:
		return 1.5
	return 1.2

func flank_name(a: int, b: int) -> String:
	var m := flank(a, b)
	if m >= 1.5:
		return "BACK X1.5"
	if m >= 1.2:
		return "SIDE X1.2"
	return "FRONT"

func base_damage(a: int, b: int, mult: float) -> int:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	var terr: int = board.defense(int(ub["x"]), int(ub["y"]))
	var raw: float = float(int(ua["atk"]) - int(ub["def"]) - terr) * flank(a, b) * mult
	if bool(ub["guard"]):
		raw *= 0.5
	return maxi(int(raw), 1)

func forecast(a: int, b: int, mult: float) -> int:
	return base_damage(a, b, mult)

# ------------- animation -------------

func q_move(i: int, path: Array) -> void:
	queue.append({"k": "move", "u": i, "path": path, "step": 0, "t": 0.0})

func q_attack(a: int, b: int, mult: float, counter: bool) -> void:
	queue.append({"k": "attack", "a": a, "b": b, "m": mult, "c": counter, "t": 0.0, "done": false})

func q_burst(a: int, list: Array, mult: float) -> void:
	queue.append({"k": "burst", "a": a, "list": list, "m": mult, "t": 0.0, "done": false})

func q_heal(a: int, b: int) -> void:
	queue.append({"k": "heal", "a": a, "b": b, "t": 0.0, "done": false})

func q_wait(sec: float) -> void:
	queue.append({"k": "wait", "t": 0.0, "len": sec})

func q_cam(to: Vector2) -> void:
	queue.append({"k": "cam", "from": cam, "to": to, "t": 0.0})

func _face_to(a: int, b: int) -> void:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	var dx: int = int(ub["x"]) - int(ua["x"])
	var dy: int = int(ub["y"]) - int(ua["y"])
	if absi(dx) >= absi(dy):
		ua["dir"] = Vector2i(signi(dx), 0)
		if dx != 0:
			ua["face"] = signi(dx)
	else:
		ua["dir"] = Vector2i(0, signi(dy))

func _gain_exp(i: int, n: int) -> void:
	var u: Dictionary = units[i]
	if int(u["team"]) != 0:
		return
	u["exp"] = int(u["exp"]) + n
	while int(u["exp"]) >= 100:
		u["exp"] = int(u["exp"]) - 100
		u["lv"] = int(u["lv"]) + 1
		u["mhp"] = int(u["mhp"]) + 4
		u["atk"] = int(u["atk"]) + 1
		u["def"] = int(u["def"]) + 1
		u["hp"] = mini(int(u["hp"]) + 6, int(u["mhp"]))
		Sound.play("level")
		_banner("%s LV%d" % [Units.label(String(u["kind"])), int(u["lv"])])

func _damage(a: int, b: int, mult: float) -> void:
	var ua: Dictionary = units[a]
	var ub: Dictionary = units[b]
	var roll := randi_range(-1, 2)
	var crit := roll >= 2
	var dmg: int = maxi(base_damage(a, b, mult) + roll, 1)
	if crit:
		dmg = int(float(dmg) * 1.5)
	ub["hp"] = maxi(int(ub["hp"]) - dmg, 0)
	ub["flash"] = 0.22
	var dv: Vector2 = (Vector2(ub["px"]) - Vector2(ua["px"])).normalized()
	ub["nudge"] = dv * 7.0
	fx.hit(Vector2(ub["px"]), dmg, crit)
	Sound.play("hit")
	msg = "%d %s" % [dmg, Gfx.L("ダメージ", "DAMAGE")]
	if crit:
		msg = "%s %d" % [Gfx.L("会心", "CRITICAL"), dmg]
	_gain_exp(a, 12)
	if int(ub["hp"]) <= 0:
		msg = "%s %s" % [Units.label(String(ub["kind"])), Gfx.L("撃破", "DOWN")]
		Sound.play("down")
		_gain_exp(a, 30)
		queue.append({"k": "death", "u": b, "t": 0.0})

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
		var p: float = clampf(t / 0.30, 0.0, 1.0)
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
		var a1: Vector2i = path[step]
		var b1: Vector2i = path[step + 1]
		var p2: float = clampf(t / WALK, 0.0, 1.0)
		u["px"] = Vector2(float(a1.x) * TS, float(a1.y) * TS).lerp(Vector2(float(b1.x) * TS, float(b1.y) * TS), p2)
		u["dir"] = Vector2i(b1.x - a1.x, b1.y - a1.y)
		if b1.x > a1.x:
			u["face"] = 1
		elif b1.x < a1.x:
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
		var dv2: Vector2 = (tgt - home).normalized()
		var p3: float = clampf(t / LUNGE, 0.0, 1.0)
		if t < dt * 1.5:
			Sound.play("slash")
		ua["px"] = home + dv2 * sin(p3 * PI) * 11.0
		if t >= LUNGE * 0.32 and not bool(anim["done"]):
			anim["done"] = true
			_face_to(ai, bi)
			_damage(ai, bi, float(anim["m"]))
			if bool(anim["c"]) and int(ub["hp"]) > 0 and dist(ai, bi) <= int(ub["rng"]):
				q_attack(bi, ai, 1.0, false)
		if p3 >= 1.0:
			ua["px"] = home
			anim = {}
		return

	if k == "burst":
		var a2: int = anim["a"]
		var p4: float = clampf(t / 0.5, 0.0, 1.0)
		if t >= 0.16 and not bool(anim["done"]):
			anim["done"] = true
			var list: Array = anim["list"]
			for j in list:
				var jj: int = int(j)
				if int(units[jj]["hp"]) > 0:
					_face_to(a2, jj)
					_damage(a2, jj, float(anim["m"]))
		if p4 >= 1.0:
			anim = {}
		return

	if k == "heal":
		var ha: int = anim["a"]
		var hb: int = anim["b"]
		if t >= 0.18 and not bool(anim["done"]):
			anim["done"] = true
			var uh: Dictionary = units[hb]
			var amt: int = 12 + int(units[ha]["lv"]) * 2
			var before: int = int(uh["hp"])
			uh["hp"] = mini(before + amt, int(uh["mhp"]))
			uh["flash"] = 0.22
			fx.hit(Vector2(uh["px"]), int(uh["hp"]) - before, false)
			msg = "%s %d" % [Gfx.L("回復", "HEAL"), int(uh["hp"]) - before]
			Sound.play("heal")
			_gain_exp(ha, 14)
		if t >= 0.5:
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

# ------------- enemy ai -------------

func _ai_act() -> void:
	var i := active
	var e: Dictionary = units[i]
	var best_t := -1
	var best_p := Vector2i(int(e["x"]), int(e["y"]))
	var best_s := -1.0e9
	_calc_reach(i)
	var spots: Array = reach.keys()
	if spots.is_empty():
		spots = [Vector2i(int(e["x"]), int(e["y"]))]
	var ox: int = int(e["x"])
	var oy: int = int(e["y"])
	for k in spots:
		var c: Vector2i = k
		if unit_at(c.x, c.y) >= 0 and not (c.x == ox and c.y == oy):
			continue
		e["x"] = c.x
		e["y"] = c.y
		var terr: float = float(board.defense(c.x, c.y))
		var hostiles: Array = in_range(i, int(e["rng"]), true)
		if hostiles.is_empty():
			var near := 999
			for j in units.size():
				var o: Dictionary = units[j]
				if int(o["team"]) != 0 or int(o["hp"]) <= 0:
					continue
				near = mini(near, dist(i, j))
			var s0: float = -float(near) * 10.0 + terr * 2.0
			if s0 > best_s:
				best_s = s0
				best_p = c
				best_t = -1
		else:
			for j in hostiles:
				var jj: int = int(j)
				var d: int = base_damage(i, jj, 1.0)
				var s1: float = float(d) * 8.0 + terr * 4.0
				if d >= int(units[jj]["hp"]):
					s1 += 400.0
				s1 -= float(int(units[jj]["hp"])) * 0.5
				if int(e["rng"]) >= 2:
					s1 += float(dist(i, jj)) * 6.0
				if s1 > best_s:
					best_s = s1
					best_p = c
					best_t = jj
	e["x"] = ox
	e["y"] = oy
	_calc_reach(i)
	if not (best_p.x == ox and best_p.y == oy):
		var pth := path_to(best_p)
		e["x"] = best_p.x
		e["y"] = best_p.y
		e["moved"] = true
		q_move(i, pth)
	_clear_sel()
	if best_t >= 0:
		q_attack(i, best_t, 1.0, true)
	q_wait(0.2)

# ------------- input -------------

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			down = true
			dragging = false
			touch_start = ev.position
			touch_pos = ev.position
		else:
			down = false
			if not dragging:
				_tap(ev.position)
	elif ev is InputEventScreenDrag and down:
		var dv: Vector2 = ev.position - touch_pos
		touch_pos = ev.position
		if touch_pos.distance_to(touch_start) > 8.0:
			dragging = true
		if dragging and VIEW.has_point(ev.position):
			cam -= dv
			_clamp_cam()

func _cell(p: Vector2) -> Vector2i:
	if not VIEW.has_point(p):
		return Vector2i(-1, -1)
	var w: Vector2 = p - VIEW.position + cam
	return Vector2i(int(w.x / TS), int(w.y / TS))

func _btn(i: int) -> Rect2:
	return Rect2(340.0 + float(i) * 100.0, 322.0, 94.0, 30.0)

func _my_turn() -> bool:
	return not over and active >= 0 and int(units[active]["team"]) == 0 and not busy()

func _tap(p: Vector2) -> void:
	if over:
		if _btn(2).has_point(p) and not result_sent:
			result_sent = true
			finished.emit(String(msg) == "CLEAR")
		return
	if busy() or active < 0:
		return
	if int(units[active]["team"]) != 0:
		return
	var u: Dictionary = units[active]

	if _btn(0).has_point(p):
		Sound.play("select")
		if sub == Sub.TARGET:
			sub = Sub.MOVE
			_calc_reach(active)
			targets.clear()
			pending = -1
			msg = Gfx.L("移動か行動", "MOVE OR ACT")
		else:
			sub = Sub.TARGET
			reach.clear()
			path_preview.clear()
			targets = in_range(active, int(u["rng"]), true)
			pending = -1
			msg = Gfx.L("対象を選ぶ", "PICK A TARGET")
		return
	if _btn(1).has_point(p):
		Sound.play("select")
		_open_skill()
		return
	if _btn(2).has_point(p):
		Sound.play("cancel")
		_end_unit()
		return

	var c := _cell(p)
	if not board.inside(c.x, c.y):
		return
	var hit := unit_at(c.x, c.y)

	if sub == Sub.TARGET or sub == Sub.SKILL:
		if hit >= 0 and targets.has(hit):
			if pending == hit:
				_do_action(hit)
			else:
				pending = hit
				cursor = c
				msg = Gfx.L("もう一度で決定", "TAP AGAIN")
		return

	if hit >= 0:
		cursor = c
		return
	var key := Vector2i(c.x, c.y)
	if reach.has(key):
		if cursor == key and path_preview.size() > 0:
			var pth := path_preview
			units[active]["x"] = c.x
			units[active]["y"] = c.y
			units[active]["moved"] = true
			q_move(active, pth)
			reach.clear()
			parent.clear()
			path_preview.clear()
			cursor = Vector2i(-1, -1)
			msg = Gfx.L("行動か待機", "ACT OR WAIT")
		else:
			Sound.play("select")
			cursor = key
			path_preview = path_to(key)
			msg = Gfx.L("もう一度で移動", "TAP AGAIN TO MOVE")
	else:
		cursor = c

func _skill_of(i: int) -> String:
	return String(units[i]["skill"])

func _open_skill() -> void:
	var u: Dictionary = units[active]
	var sk := _skill_of(active)
	if sk == "" or int(u["mp"]) <= 0:
		msg = Gfx.L("技が使えない", "NO SKILL")
		return
	var info: Dictionary = Units.SKILL[sk]
	reach.clear()
	path_preview.clear()
	pending = -1
	if sk == "GUARD":
		u["guard"] = true
		u["mp"] = int(u["mp"]) - 1
		_banner(Gfx.L("防御態勢", "GUARD UP"))
		_end_unit()
		return
	if sk == "HEAL":
		targets = in_range(active, int(info["rng"]), false)
	else:
		targets = in_range(active, int(info["rng"]), true)
	if targets.is_empty():
		msg = Gfx.L("射程内に対象なし", "NO TARGET IN RANGE")
		sub = Sub.MOVE
		_calc_reach(active)
		return
	sub = Sub.SKILL
	msg = "%s : %s" % [Units.skill_label(sk), Gfx.L("対象を選ぶ", "PICK TARGET")]

func _do_action(tgt: int) -> void:
	var u: Dictionary = units[active]
	if sub == Sub.TARGET:
		q_attack(active, tgt, 1.0, true)
		_end_unit()
		return
	var sk := _skill_of(active)
	u["mp"] = int(u["mp"]) - 1
	if sk == "PIERCE":
		var list: Array = [tgt]
		var d := Vector2i(int(units[tgt]["x"]) - int(u["x"]), int(units[tgt]["y"]) - int(u["y"]))
		var bx: int = int(units[tgt]["x"]) + d.x
		var by: int = int(units[tgt]["y"]) + d.y
		var b2 := unit_at(bx, by)
		if b2 >= 0 and int(units[b2]["team"]) != int(u["team"]):
			list.append(b2)
		q_burst(active, list, 1.0)
	elif sk == "SNIPE":
		q_attack(active, tgt, 1.3, false)
	elif sk == "BLAST":
		var cx: int = int(units[tgt]["x"])
		var cy: int = int(units[tgt]["y"])
		var list2: Array = []
		for d2 in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var h := unit_at(cx + d2.x, cy + d2.y)
			if h >= 0 and int(units[h]["team"]) != int(u["team"]):
				list2.append(h)
		q_burst(active, list2, 0.9)
	elif sk == "HEAL":
		q_heal(active, tgt)
	_end_unit()

# ------------- loop -------------

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
		if not busy() and not over and active >= 0:
			if int(units[active]["team"]) == 1:
				ai_t -= dt
				if ai_t <= 0.0:
					if bool(units[active]["acted"]):
						_end_unit()
					else:
						units[active]["acted"] = true
						_ai_act()
						ai_t = 0.15
			elif int(units[active]["hp"]) <= 0:
				_end_unit()
		if not busy():
			_check_over()
	queue_redraw()

# ------------- draw -------------

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
		var fill := Color(1.0, 0.25, 0.2, 0.32)
		var lc: Color = Pal.c("red")
		if sub == Sub.SKILL and _skill_of(active) == "HEAL":
			fill = Color(0.3, 1.0, 0.4, 0.28)
			lc = Pal.c("lgreen")
		draw_rect(r2, fill)
		if int(j) == pending:
			lc = Pal.c("yellow")
		draw_rect(r2, lc, false, 2.0)
	if goal.x >= 0:
		var gr := _tile_rect(goal.x, goal.y)
		var pulse: float = 0.4 + 0.3 * sin(float(Time.get_ticks_msec()) * 0.005)
		draw_rect(gr, Color(1.0, 0.85, 0.2, pulse * 0.5))
		draw_rect(gr, Pal.c("yellow"), false, 2.0)
	if cursor.x >= 0:
		draw_rect(_tile_rect(cursor.x, cursor.y), Pal.c("white"), false, 1.0)

func _by_depth(a, b) -> bool:
	var ua: Dictionary = units[int(a)]
	var ub: Dictionary = units[int(b)]
	return Vector2(ua["px"]).y < Vector2(ub["px"]).y

func _draw_units() -> void:
	var ord2: Array = []
	for i in units.size():
		ord2.append(i)
	ord2.sort_custom(_by_depth)
	for i in ord2:
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
		if bool(u["acted"]) and int(u["hp"]) > 0:
			tint = Color(0.56, 0.62, 0.72, float(u["fade"]))
		draw_texture_rect_region(tex, dst, src, tint)
		if float(u["flash"]) > 0.0:
			var wt: Texture2D = Gfx.art_v(nm, true, flip)
			draw_texture_rect_region(wt, dst, src, Color(1, 1, 1, float(u["flash"]) / 0.22 * 0.85))
		if int(u["hp"]) > 0:
			var ratio: float = float(u["hp"]) / float(u["mhp"])
			draw_rect(Rect2(sp.x + 3.0, sp.y + 27.0, 26.0, 4.0), Color(0, 0, 0, 0.7))
			draw_rect(Rect2(sp.x + 4.0, sp.y + 28.0, 24.0 * ratio, 2.0), Pal.team(int(u["team"])))
			if bool(u["guard"]):
				draw_rect(Rect2(sp.x + 2.0, sp.y - 2.0, 6.0, 6.0), Pal.c("cyan"))
			if bool(u["boss"]):
				draw_rect(Rect2(sp.x + 12.0, sp.y - 20.0, 8.0, 4.0), Pal.c("yellow"))
			var fd: Vector2i = u["dir"]
			var ctr := Vector2(sp.x + 16.0, sp.y + 34.0)
			draw_line(ctr, ctr + Vector2(float(fd.x), float(fd.y)) * 9.0, Pal.c("white"), 1.0)
	if active >= 0 and int(units[active]["hp"]) > 0:
		var s: Dictionary = units[active]
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
	Gfx.text(self, "R%d" % rnd, Vector2(4.0, 6.0), Pal.c("white"))
	var x := 36.0
	var shown := 0
	var idx := oi
	while idx < order.size() and shown < 6:
		var ui: int = int(order[idx])
		if int(units[ui]["hp"]) > 0:
			var lab: String = String(units[ui]["kind"]).substr(0, 3)
			var col: Color = Pal.team(int(units[ui]["team"]))
			if shown == 0:
				Gfx.text(self, ">", Vector2(x - 6.0, 6.0), Pal.c("yellow"))
			Gfx.text(self, lab, Vector2(x, 6.0), col)
			x += 26.0
			shown += 1
		idx += 1
	Gfx.jtext(self, msg, Vector2(228.0, 3.0), Pal.c("yellow"), 14)
	Gfx.jtext(self, Maps.win_text(mapdef), Vector2(448.0, 3.0), Pal.c("cyan"), 14)

	_panel(Rect2(0.0, 316.0, 640.0, 44.0))
	var show := active
	if show >= 0:
		var u: Dictionary = units[show]
		var st: Dictionary = Units.STATS[u["kind"]]
		Gfx.jtext(self, "%s LV%d" % [Units.label(String(u["kind"])), int(u["lv"])], Vector2(6.0, 320.0), Pal.c("white"), 15)
		Gfx.text(self, "HP %d/%d  MP %d" % [int(u["hp"]), int(u["mhp"]), int(u["mp"])], Vector2(6.0, 338.0), Pal.c("lgreen"))
		Gfx.text(self, "ATK %d" % int(u["atk"]), Vector2(126.0, 322.0), Pal.c("gray"))
		Gfx.text(self, "DEF %d" % int(u["def"]), Vector2(126.0, 338.0), Pal.c("gray"))
		Gfx.text(self, "MOV %d" % int(u["mov"]), Vector2(196.0, 322.0), Pal.c("gray"))
		Gfx.text(self, "SPD %d" % int(u["spd"]), Vector2(196.0, 338.0), Pal.c("gray"))
		Gfx.text(self, "EXP %d" % int(u["exp"]), Vector2(266.0, 322.0), Pal.c("cyan"))
		if pending >= 0:
			if sub == Sub.SKILL and _skill_of(active) == "HEAL":
				Gfx.text(self, "HEAL", Vector2(266.0, 338.0), Pal.c("lgreen"))
			else:
				var mult := 1.0
				if sub == Sub.SKILL:
					var sk := _skill_of(active)
					if sk == "SNIPE":
						mult = 1.3
					elif sk == "BLAST":
						mult = 0.9
				Gfx.text(self, "%d DMG %s" % [forecast(active, pending, mult), flank_name(active, pending)], Vector2(266.0, 338.0), Pal.c("orange"))
	if not over and active >= 0 and int(units[active]["team"]) == 0:
		var lbls: Array = [Gfx.L("攻撃", "ATTACK"), Units.skill_label(_skill_of(active)), Gfx.L("待機", "WAIT")]
		if String(lbls[1]) == "":
			lbls[1] = Gfx.L("技", "SKILL")
		for i in 3:
			var b := _btn(i)
			_panel(b)
			var lc: Color = Pal.c("white")
			if i == 1 and (int(units[active]["mp"]) <= 0 or _skill_of(active) == ""):
				lc = Pal.c("dgray")
			var s2: String = lbls[i]
			Gfx.jtext(self, s2, Vector2(b.position.x + (b.size.x - Gfx.jwidth(s2, 16)) * 0.5, b.position.y + 6.0), lc, 16)
	elif over:
		var b2 := _btn(2)
		_panel(b2)
		var nx := Gfx.L("次へ", "NEXT")
		Gfx.jtext(self, nx, Vector2(b2.position.x + (b2.size.x - Gfx.jwidth(nx, 16)) * 0.5, b2.position.y + 6.0), Pal.c("white"), 16)

func _draw_banner() -> void:
	if banner_t <= 0.0:
		return
	var a: float = clampf(banner_t / 0.35, 0.0, 1.0)
	var w := Gfx.jwidth(banner, 18) + 40.0
	var r := Rect2(320.0 - w * 0.5, 146.0, w, 34.0)
	draw_rect(r, Color(0.05, 0.07, 0.10, 0.86 * a))
	var y: Color = Pal.c("yellow")
	draw_rect(r, Color(y.r, y.g, y.b, a), false, 2.0)
	Gfx.jtext(self, banner, Vector2(320.0 - Gfx.jwidth(banner, 18) * 0.5, 152.0), Color(1, 1, 1, a), 18)
