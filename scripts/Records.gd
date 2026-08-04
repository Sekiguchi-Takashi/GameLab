extends Node2D

signal back

func _btn() -> Rect2:
	return Rect2(480.0, 600.0, 320.0, 80.0)

func tap(p: Vector2) -> void:
	if _btn().has_point(p):
		Sound.play("cancel")
		back.emit()

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.05, 0.06, 0.09, 1.0))
	var t := Gfx.L("戦績", "RECORDS")
	Gfx.jtext(self, t, Vector2(120.0, 52.0), Pal.c("white"), 36)
	var y := 76.0
	var rows: Array = [
		[Gfx.L("難易度", "DIFFICULTY"), Save.diff_label()],
		[Gfx.L("周回", "CYCLE"), str(Save.cycle)],
		[Gfx.L("制覇回数", "CAMPAIGNS CLEARED"), str(int(Save.stats["clears"]))],
		[Gfx.L("総ラウンド", "TOTAL ROUNDS"), str(int(Save.stats["turns"]))],
		[Gfx.L("撃破数", "FOES DEFEATED"), str(int(Save.stats["kills"]))],
		[Gfx.L("最高レベル", "HIGHEST LEVEL"), str(int(Save.stats["maxlv"]))],
	]
	for r in rows:
		var rr: Array = r
		draw_rect(Rect2(60.0, y - 4.0, 520.0, 30.0), Pal.c("panel"))
		draw_rect(Rect2(60.0, y - 4.0, 520.0, 30.0), Pal.c("line"), false, 1.0)
		Gfx.jtext(self, String(rr[0]), Vector2(74.0, y), Pal.c("gray"), 27)
		Gfx.jtext(self, String(rr[1]), Vector2(400.0, y), Pal.c("white"), 27)
		y += 72.0
	var b := _btn()
	draw_rect(b, Pal.c("panel"))
	draw_rect(b, Pal.c("line"), false, 2.0)
	var s := Gfx.L("戻る", "BACK")
	Gfx.jtext(self, s, Vector2(b.position.x + (b.size.x - Gfx.jwidth(s, 28)) * 0.5, b.position.y + 9.0), Pal.c("white"), 28)
