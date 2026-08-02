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
		Sound.play("confirm")
		start_battle.emit()

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.05, 0.06, 0.09, 1.0))
	var m: Dictionary = Maps.get_map(map_i)
	Gfx.jtext(self, "%s%d  %s" % [Gfx.L("第", "BATTLE "), map_i + 1, Maps.name_of(m)], Vector2(16.0, 14.0), Pal.c("white"), 18)
	Gfx.jtext(self, "%s  %s" % [Gfx.L("目的", "OBJECTIVE"), Maps.win_text(m)], Vector2(16.0, 40.0), Pal.c("cyan"), 14)
	Gfx.jtext(self, Gfx.L("出撃する隊", "YOUR COMPANY"), Vector2(16.0, 66.0), Pal.c("gray"), 13)
	for i in Save.roster.size():
		var r: Dictionary = Save.roster[i]
		var rr := _row(i)
		draw_rect(rr, Pal.c("panel"))
		draw_rect(rr, Pal.c("line"), false, 1.0)
		var tex: Texture2D = Gfx.art("%s0" % String(r["kind"]))
		draw_texture_rect_region(tex, Rect2(rr.position.x + 2.0, rr.position.y - 4.0, 44.0, 44.0), Rect2(0.0, 0.0, 48.0, 48.0))
		Gfx.jtext(self, "%s  LV%d" % [Units.label(String(r["kind"])), int(r["lv"])], Vector2(rr.position.x + 52.0, rr.position.y + 2.0), Pal.c("white"), 15)
		Gfx.text(self, "HP %d/%d  MP %d  ATK %d  DEF %d" % [int(r["hp"]), int(r["mhp"]), int(r["mp"]), int(r["atk"]), int(r["def"])], Vector2(rr.position.x + 52.0, rr.position.y + 20.0), Pal.c("gray"))
	Gfx.jtext(self, Gfx.L("全員が出撃する。", "ALL UNITS DEPLOY."), Vector2(440.0, 96.0), Pal.c("gray"), 13)
	Gfx.jtext(self, Gfx.L("戦闘前にHPとMPは", "HP AND MP ARE"), Vector2(440.0, 116.0), Pal.c("gray"), 13)
	Gfx.jtext(self, Gfx.L("全回復する。", "RESTORED BEFORE EACH BATTLE."), Vector2(440.0, 136.0), Pal.c("gray"), 13)
	var b := _btn_go()
	draw_rect(b, Pal.c("panel"))
	draw_rect(b, Pal.c("yellow"), false, 2.0)
	var dep := Gfx.L("出撃", "DEPLOY")
	Gfx.jtext(self, dep, Vector2(b.position.x + (b.size.x - Gfx.jwidth(dep, 18)) * 0.5, b.position.y + 10.0), Pal.c("white"), 18)
