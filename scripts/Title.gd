extends Node2D

signal pick(what: String)

func _btn(i: int) -> Rect2:
	return Rect2(200.0, 150.0 + float(i) * 42.0, 240.0, 32.0)

func _labels() -> Array:
	return [Gfx.L("はじめる", "PLAY"), Gfx.L("戦績", "RECORDS"), Gfx.L("確認リスト", "CHECK LIST"), Gfx.L("音 " + _snd(), "SOUND " + _snd())]

func _snd() -> String:
	if Sound.enabled:
		return "ON"
	return "OFF"

func tap(p: Vector2) -> void:
	var l := _labels()
	for i in l.size():
		if _btn(i).has_point(p):
			Sound.play("confirm")
			if i == 0:
				pick.emit("PLAY")
			elif i == 1:
				pick.emit("RECORDS")
			elif i == 2:
				pick.emit("CHECK")
			else:
				Sound.toggle()
				if Sound.enabled:
					Sound.bgm("title")
			return

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.05, 0.06, 0.09, 1.0))
	for i in 12:
		var y := 40.0 + float(i) * 4.0
		draw_rect(Rect2(0.0, y, 640.0, 2.0), Color(0.10, 0.14, 0.22, 1.0 - float(i) * 0.07))
	var t := Gfx.L("四つの戦い", "GAMELAB TACTICS")
	Gfx.jtext(self, t, Vector2(320.0 - Gfx.jwidth(t, 22) * 0.5, 62.0), Pal.c("white"), 22)
	var sub := Gfx.L("小さな戦記", "A SMALL WAR IN FOUR BATTLES")
	Gfx.jtext(self, sub, Vector2(320.0 - Gfx.jwidth(sub, 13) * 0.5, 92.0), Pal.c("gray"), 13)
	Gfx.text(self, "FONT " + Gfx.jfont_path, Vector2(6.0, 332.0), Pal.c("dgray"))
	Gfx.text(self, "LAST " + Save.last_trace, Vector2(6.0, 346.0), Pal.c("dgray"))
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
		Gfx.jtext(self, s, Vector2(b.position.x + (b.size.x - Gfx.jwidth(s, 15)) * 0.5, b.position.y + 8.0), Pal.c("white"), 15)
