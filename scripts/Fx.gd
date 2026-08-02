extends Node2D

var flash := 0.0
var shake := 0.0
var shake_len := 0.2
var hitstop := 0.0
var pops: Array = []

func _ready() -> void:
	z_index = 90

func hit(world_pos: Vector2, n: int, crit: bool) -> void:
	flash = 0.07
	shake = 0.22
	hitstop = 0.10
	pops.append({"p": world_pos, "t": 0.0, "n": n, "c": crit})

func offset() -> Vector2:
	if shake <= 0.0:
		return Vector2.ZERO
	var k: float = shake / shake_len
	return Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 5.0 * k

func tick(d: float) -> float:
	flash = maxf(flash - d, 0.0)
	shake = maxf(shake - d, 0.0)
	var keep: Array = []
	for p in pops:
		var pp: Dictionary = p
		pp["t"] = float(pp["t"]) + d
		if float(pp["t"]) < 0.9:
			keep.append(pp)
	pops = keep
	if hitstop > 0.0:
		hitstop = maxf(hitstop - d, 0.0)
		return 0.0
	return d

func draw_pops(ci: CanvasItem, cam: Vector2, view: Rect2) -> void:
	for p in pops:
		var pp: Dictionary = p
		var k: float = float(pp["t"])
		var off: float = -sin(minf(k * 3.2, PI)) * 20.0
		var wp: Vector2 = pp["p"]
		var sp := wp - cam + view.position + Vector2(6.0, off)
		var col: Color = Pal.c("white")
		if bool(pp["c"]):
			col = Pal.c("yellow")
		if int(k * 20.0) % 2 == 0:
			col = Pal.c("red")
		Gfx.text(ci, str(pp["n"]), sp, col)

func draw_flash(ci: CanvasItem, view: Rect2) -> void:
	if flash > 0.0:
		ci.draw_rect(view, Color(1, 1, 1, flash / 0.07 * 0.55))
