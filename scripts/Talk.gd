extends Node2D

signal done

var lines: Array = []
var page := 0
var shown := 0.0
var title := ""

var traced := false

func setup(t: String, l: Array) -> void:
	title = t
	lines = []
	for x in l:
		lines.append(String(x))
	if lines.is_empty():
		lines.append("...")
	traced = false
	Save.trace("TSET%d" % lines.size())
	page = 0
	shown = 0.0

func _full() -> bool:
	if page >= lines.size():
		return true
	return shown >= float(String(lines[page]).length())

func tap(_p: Vector2) -> void:
	Save.trace("TTAP%d" % page)
	Sound.play("select")
	if not _full():
		shown = 9999.0
		return
	page += 1
	shown = 0.0
	if page >= lines.size():
		done.emit()

func _process(d: float) -> void:
	shown += d * 30.0
	queue_redraw()

func _draw() -> void:
	if not traced:
		traced = true
		Save.trace("TDRAW")
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.04, 0.05, 0.07, 1.0))
	Gfx.jtext(self, title, Vector2(20.0, 20.0), Pal.c("cyan"), 17)
	var wx := 20.0
	var wy := 220.0
	var ww := 600.0
	var wh := 100.0
	draw_rect(Rect2(wx, wy, ww, wh), Pal.c("panel"))
	draw_rect(Rect2(wx, wy, ww, wh), Pal.c("white"), false, 2.0)
	draw_rect(Rect2(wx + 5.0, wy + 5.0, ww - 10.0, wh - 10.0), Pal.c("line"), false, 1.0)
	var y := wy + 22.0
	for i in range(page, mini(page + 2, lines.size())):
		var s: String = lines[i]
		var n: int = s.length()
		if i == page:
			n = clampi(int(shown), 0, s.length())
		elif not _full():
			n = 0
		Gfx.jtext(self, s.substr(0, n), Vector2(wx + 20.0, y), Pal.c("white"), 16)
		y += 26.0
	if _full() and int(Time.get_ticks_msec() / 380) % 2 == 0:
		var px := wx + ww - 24.0
		var py := wy + wh - 18.0
		draw_colored_polygon(PackedVector2Array([Vector2(px, py), Vector2(px + 10.0, py), Vector2(px + 5.0, py + 8.0)]), Pal.c("yellow"))
	Gfx.jtext(self, Gfx.L("タップで進む", "TAP TO CONTINUE"), Vector2(20.0, 330.0), Pal.c("dgray"), 13)
