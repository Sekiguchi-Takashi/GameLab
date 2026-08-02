extends Node2D

signal pick(what: String)

func _btn(i: int) -> Rect2:
	return Rect2(200.0, 160.0 + float(i) * 46.0, 240.0, 36.0)

func _labels() -> Array:
	var out: Array = ["NEW GAME"]
	if Save.has_save():
		out.append("CONTINUE")
	out.append("CHECK LIST")
	return out

func tap(p: Vector2) -> void:
	var l := _labels()
	for i in l.size():
		if _btn(i).has_point(p):
			pick.emit(String(l[i]))
			return

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.05, 0.06, 0.09, 1.0))
	for i in 12:
		var y := 40.0 + float(i) * 4.0
		draw_rect(Rect2(0.0, y, 640.0, 2.0), Color(0.10, 0.14, 0.22, 1.0 - float(i) * 0.07))
	var t := "GAMELAB TACTICS"
	Gfx.text(self, t, Vector2(320.0 - float(Gfx.text_width(t)) * 0.5, 76.0), Pal.c("white"))
	var sub := "A SMALL WAR IN FOUR BATTLES"
	Gfx.text(self, sub, Vector2(320.0 - float(Gfx.text_width(sub)) * 0.5, 96.0), Pal.c("gray"))
	var kn: Texture2D = Gfx.art("KNIGHT0")
	draw_texture_rect_region(kn, Rect2(96.0, 150.0, 96.0, 96.0), Rect2(0.0, 0.0, 48.0, 48.0))
	var orc: Texture2D = Gfx.art_v("ORC0", false, true)
	draw_texture_rect_region(orc, Rect2(452.0, 150.0, 96.0, 96.0), Rect2(0.0, 0.0, 48.0, 48.0))
	var l := _labels()
	for i in l.size():
		var b := _btn(i)
		draw_rect(b, Pal.c("panel"))
		draw_rect(b, Pal.c("line"), false, 2.0)
		var s: String = l[i]
		Gfx.text(self, s, Vector2(b.position.x + (b.size.x - float(Gfx.text_width(s))) * 0.5, b.position.y + 14.0), Pal.c("white"))
