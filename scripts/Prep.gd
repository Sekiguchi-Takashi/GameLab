extends Node2D

signal start_battle

var map_i := 0

func setup(i: int) -> void:
	map_i = i

func _row(i: int) -> Rect2:
	return Rect2(16.0, 92.0 + float(i) * 40.0, 400.0, 36.0)

func _btn_go() -> Rect2:
	return Rect2(440.0, 296.0, 184.0, 40.0)

func tap(p: Vector2) -> void:
	if _btn_go().has_point(p):
		start_battle.emit()

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.05, 0.06, 0.09, 1.0))
	var m: Dictionary = Maps.get_map(map_i)
	Gfx.text(self, "BATTLE %d   %s" % [map_i + 1, String(m["name"])], Vector2(16.0, 20.0), Pal.c("white"))
	Gfx.text(self, "OBJECTIVE  %s" % Maps.win_text(m), Vector2(16.0, 40.0), Pal.c("cyan"))
	Gfx.text(self, "YOUR COMPANY", Vector2(16.0, 70.0), Pal.c("gray"))
	for i in Save.roster.size():
		var r: Dictionary = Save.roster[i]
		var rr := _row(i)
		draw_rect(rr, Pal.c("panel"))
		draw_rect(rr, Pal.c("line"), false, 1.0)
		var tex: Texture2D = Gfx.art("%s0" % String(r["kind"]))
		draw_texture_rect_region(tex, Rect2(rr.position.x + 2.0, rr.position.y - 4.0, 44.0, 44.0), Rect2(0.0, 0.0, 48.0, 48.0))
		Gfx.text(self, "%s LV%d" % [String(r["kind"]), int(r["lv"])], Vector2(rr.position.x + 52.0, rr.position.y + 6.0), Pal.c("white"))
		Gfx.text(self, "HP %d/%d  MP %d  ATK %d  DEF %d" % [int(r["hp"]), int(r["mhp"]), int(r["mp"]), int(r["atk"]), int(r["def"])], Vector2(rr.position.x + 52.0, rr.position.y + 20.0), Pal.c("gray"))
	Gfx.text(self, "ALL UNITS DEPLOY.", Vector2(440.0, 96.0), Pal.c("gray"))
	Gfx.text(self, "HP AND MP ARE", Vector2(440.0, 112.0), Pal.c("gray"))
	Gfx.text(self, "RESTORED BEFORE", Vector2(440.0, 128.0), Pal.c("gray"))
	Gfx.text(self, "EACH BATTLE.", Vector2(440.0, 144.0), Pal.c("gray"))
	var b := _btn_go()
	draw_rect(b, Pal.c("panel"))
	draw_rect(b, Pal.c("yellow"), false, 2.0)
	Gfx.text(self, "DEPLOY", Vector2(b.position.x + 60.0, b.position.y + 16.0), Pal.c("white"))
