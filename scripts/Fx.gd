extends Node2D

var flash := 0.0
var flash_col := Color(1, 1, 1)
var shake := 0.0
var hitstop := 0.0
var pops: Array = []
var efx: Array = []

const SHAKE_LEN := 0.24
const FLASH_LEN := 0.07

func _ready() -> void:
	z_index = 90

func hit(world_pos: Vector2, n: int, crit: bool) -> void:
	flash = FLASH_LEN
	flash_col = Color(1, 1, 1)
	shake = SHAKE_LEN
	hitstop = 0.09
	if crit:
		shake = 0.38
		hitstop = 0.17
	pops.append({"p": world_pos, "t": 0.0, "n": n, "c": crit, "h": false})

func heal_pop(world_pos: Vector2, n: int) -> void:
	pops.append({"p": world_pos, "t": 0.0, "n": n, "c": false, "h": true})

func spawn(kind: String, a: Vector2, b: Vector2, col: Color) -> void:
	var life := 0.34
	if kind == "arrow":
		life = 0.30
	elif kind == "magic":
		life = 0.52
	elif kind == "holy":
		life = 0.50
	elif kind == "heal":
		life = 0.62
	elif kind == "guard":
		life = 0.55
	efx.append({"k": kind, "a": a, "b": b, "t": 0.0, "life": life, "c": col})

func offset() -> Vector2:
	if shake <= 0.0:
		return Vector2.ZERO
	var k: float = shake / SHAKE_LEN
	return Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 5.5 * minf(k, 1.4)

func tick(d: float) -> float:
	flash = maxf(flash - d, 0.0)
	shake = maxf(shake - d, 0.0)
	var keep: Array = []
	for p in pops:
		var pp: Dictionary = p
		pp["t"] = float(pp["t"]) + d
		if float(pp["t"]) < 1.0:
			keep.append(pp)
	pops = keep
	var ke: Array = []
	for e in efx:
		var ee: Dictionary = e
		ee["t"] = float(ee["t"]) + d
		if float(ee["t"]) < float(ee["life"]):
			ke.append(ee)
	efx = ke
	if hitstop > 0.0:
		hitstop = maxf(hitstop - d, 0.0)
		return 0.0
	return d

func _s(p: Vector2, cam: Vector2, view: Rect2) -> Vector2:
	return p - cam + view.position + Vector2(32.0, 32.0)

func draw_efx(ci: CanvasItem, cam: Vector2, view: Rect2) -> void:
	for e in efx:
		var ee: Dictionary = e
		var k: String = ee["k"]
		var t: float = float(ee["t"])
		var life: float = float(ee["life"])
		var u: float = clampf(t / life, 0.0, 1.0)
		var a := _s(Vector2(ee["a"]), cam, view)
		var b := _s(Vector2(ee["b"]), cam, view)
		var col: Color = ee["c"]
		if k == "slash":
			var ang0: float = -2.4
			var sweep: float = 3.0
			var ctr := b
			for i in 3:
				var f: float = clampf(u * 1.6 - float(i) * 0.12, 0.0, 1.0)
				if f <= 0.0 or f >= 1.0:
					continue
				var r: float = 22.0 - float(i) * 5.0
				var aa: float = ang0 + sweep * f
				var p1 := ctr + Vector2(cos(aa), sin(aa)) * r
				var p2 := ctr + Vector2(cos(aa - 0.5), sin(aa - 0.5)) * r
				ci.draw_line(p1, p2, Color(col.r, col.g, col.b, 1.0 - f), 3.0 - float(i))
		elif k == "thrust":
			var d2: Vector2 = (b - a).normalized()
			var reach: float = sin(u * PI) * 30.0
			var tip := a + d2 * (20.0 + reach)
			ci.draw_line(a + d2 * 8.0, tip, Color(col.r, col.g, col.b, 1.0 - u), 4.0)
			ci.draw_circle(tip, 3.0 * (1.0 - u), Color(1, 1, 1, 1.0 - u))
		elif k == "arrow":
			var p := a.lerp(b, u)
			var d3: Vector2 = (b - a).normalized()
			ci.draw_line(p - d3 * 9.0, p + d3 * 5.0, Color(0.95, 0.92, 0.8, 1.0), 2.0)
			ci.draw_line(p - d3 * 9.0, p - d3 * 13.0, Color(0.8, 0.4, 0.3, 0.9), 3.0)
		elif k == "magic":
			if u < 0.55:
				var g: float = u / 0.55
				var rr: float = 26.0 * (1.0 - g) + 10.0
				for ri in 3:
					ci.draw_arc(b, rr - float(ri) * 4.0, 0.0, TAU, 18, Color(col.r, col.g, col.b, g), 1.5)
			else:
				var g2: float = (u - 0.55) / 0.45
				for bi in 9:
					var ang: float = TAU * float(bi) / 9.0
					var d4: float = g2 * 30.0
					ci.draw_circle(b + Vector2(cos(ang), sin(ang)) * d4, 6.0 * (1.0 - g2), Color(col.r, col.g, col.b, 1.0 - g2))
		elif k == "holy":
			var w: float = 16.0 * sin(u * PI)
			var top: float = b.y - 140.0 * (1.0 - clampf(u * 1.6, 0.0, 1.0))
			ci.draw_rect(Rect2(b.x - w * 0.5, top, w, b.y - top), Color(1.0, 0.98, 0.78, 0.55 * sin(u * PI)))
			ci.draw_rect(Rect2(b.x - w * 0.2, top, w * 0.4, b.y - top), Color(1, 1, 1, 0.8 * sin(u * PI)))
		elif k == "heal":
			for hi in 7:
				var ph: float = fmod(u + float(hi) * 0.14, 1.0)
				var xo: float = sin((float(hi) * 1.7) + ph * 6.0) * 11.0
				ci.draw_circle(b + Vector2(xo, 18.0 - ph * 46.0), 3.0 * (1.0 - ph), Color(0.55, 1.0, 0.6, 1.0 - ph))
		elif k == "guard":
			var g3: float = sin(u * PI)
			ci.draw_arc(b, 20.0 + 8.0 * (1.0 - g3), 0.0, TAU, 24, Color(0.55, 0.85, 1.0, g3), 2.5)
			ci.draw_arc(b, 13.0, 0.0, TAU, 20, Color(1, 1, 1, g3 * 0.7), 1.5)

func draw_pops(ci: CanvasItem, cam: Vector2, view: Rect2) -> void:
	for p in pops:
		var pp: Dictionary = p
		var k: float = float(pp["t"])
		var off: float = -sin(minf(k * 2.7, PI)) * 24.0
		var wp: Vector2 = pp["p"]
		var sp := wp - cam + view.position + Vector2(9.0, off)
		var crit: bool = bool(pp["c"])
		var heal: bool = bool(pp["h"])
		var col: Color = Pal.c("white")
		if heal:
			col = Pal.c("lgreen")
		elif crit:
			col = Pal.c("yellow")
		elif int(k * 22.0) % 2 == 0:
			col = Pal.c("red")
		var fade: float = clampf(1.0 - (k - 0.6) / 0.4, 0.0, 1.0)
		col.a = fade
		var txt := str(int(pp["n"]))
		if heal:
			txt = "+" + txt
		if crit:
			Gfx.jtext(ci, txt, sp + Vector2(-8.0, -12.0), col, 40)
			Gfx.text(ci, "!", sp + Vector2(40.0, 0.0), col)
		else:
			Gfx.text(ci, txt, sp, col)

func draw_flash(ci: CanvasItem, view: Rect2) -> void:
	if flash > 0.0:
		var a: float = flash / FLASH_LEN * 0.5
		ci.draw_rect(view, Color(flash_col.r, flash_col.g, flash_col.b, a))
