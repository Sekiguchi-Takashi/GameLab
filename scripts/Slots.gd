extends Node2D

signal chosen(slot: int, is_new: bool)
signal back

var erase_mode := false
var pick_diff := -1
var note := ""
var note_t := 0.0

func _row(i: int) -> Rect2:
	return Rect2(120.0, 176.0 + float(i) * 132.0, 1040.0, 112.0)

func _dbtn(i: int) -> Rect2:
	return Rect2(240.0 + float(i) * 280.0, 320.0, 256.0, 88.0)

func _btn(i: int) -> Rect2:
	return Rect2(120.0 + float(i) * 540.0, 604.0, 500.0, 80.0)

func setup() -> void:
	erase_mode = false
	pick_diff = -1
	note = ""

func tap(p: Vector2) -> void:
	if pick_diff >= 0:
		for i in 3:
			if _dbtn(i).has_point(p):
				Save.slot = pick_diff
				Save.difficulty = i
				Sound.play("confirm")
				var sl := pick_diff
				pick_diff = -1
				chosen.emit(sl, true)
				return
		if _btn(1).has_point(p):
			pick_diff = -1
		return
	if _btn(0).has_point(p):
		erase_mode = not erase_mode
		Sound.play("select")
		return
	if _btn(1).has_point(p):
		Sound.play("cancel")
		back.emit()
		return
	for i in Save.SLOTS:
		if not _row(i).has_point(p):
			continue
		if erase_mode:
			if Save.has_slot(i):
				Save.wipe(i)
				Sound.play("cancel")
				note = Gfx.L("消去しました", "ERASED")
				note_t = 2.0
			erase_mode = false
			return
		if Save.has_slot(i):
			Save.slot = i
			Sound.play("confirm")
			chosen.emit(i, false)
		else:
			pick_diff = i
			Sound.play("select")
		return

func _process(d: float) -> void:
	if note_t > 0.0:
		note_t -= d
		if note_t <= 0.0:
			note = ""
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.05, 0.06, 0.09, 1.0))
	if pick_diff >= 0:
		var t := Gfx.L("難易度を選ぶ", "CHOOSE DIFFICULTY")
		Gfx.jtext(self, t, Vector2(640.0 - Gfx.jwidth(t, 36) * 0.5, 220.0), Pal.c("white"), 36)
		var labels: Array = [Gfx.L("易しい", "EASY"), Gfx.L("普通", "NORMAL"), Gfx.L("難しい", "HARD")]
		var notes: Array = [Gfx.L("敵が弱い", "FOES WEAKER"), Gfx.L("標準", "STANDARD"), Gfx.L("敵が強い", "FOES STRONGER")]
		for i in 3:
			var b := _dbtn(i)
			draw_rect(b, Pal.c("panel"))
			draw_rect(b, Pal.c("line"), false, 2.0)
			var s: String = labels[i]
			Gfx.jtext(self, s, Vector2(b.position.x + (b.size.x - Gfx.jwidth(s, 30)) * 0.5, b.position.y + 4.0), Pal.c("white"), 30)
			var s2: String = notes[i]
			Gfx.jtext(self, s2, Vector2(b.position.x + (b.size.x - Gfx.jwidth(s2, 40)) * 0.5, b.position.y + 26.0), Pal.c("gray"), 40)
		var bb := _btn(1)
		draw_rect(bb, Pal.c("panel"))
		draw_rect(bb, Pal.c("line"), false, 2.0)
		Gfx.jtext(self, Gfx.L("戻る", "BACK"), Vector2(bb.position.x + 100.0, bb.position.y + 10.0), Pal.c("white"), 28)
		return
	var ttl := Gfx.L("記録の選択", "SELECT A FILE")
	Gfx.jtext(self, ttl, Vector2(120.0, 96.0), Pal.c("white"), 36)
	for i in Save.SLOTS:
		var r := _row(i)
		draw_rect(r, Pal.c("panel"))
		var edge: Color = Pal.c("line")
		if erase_mode and Save.has_slot(i):
			edge = Pal.c("red")
		draw_rect(r, edge, false, 2.0)
		Gfx.jtext(self, "%s %d" % [Gfx.L("記録", "FILE"), i + 1], Vector2(r.position.x + 24.0, r.position.y + 12.0), Pal.c("cyan"), 28)
		if not Save.has_slot(i):
			Gfx.jtext(self, Gfx.L("空き", "EMPTY"), Vector2(r.position.x + 240.0, r.position.y + 38.0), Pal.c("dgray"), 28)
			continue
		var info: Dictionary = Save.slot_info(i)
		var mi := 0
		if info.has("map"):
			mi = int(info["map"])
		var cyc := 1
		if info.has("cycle"):
			cyc = maxi(int(info["cycle"]), 1)
		var lvs := ""
		if info.has("roster"):
			var rr: Array = info["roster"]
			for e in rr:
				var ee: Dictionary = e
				lvs += "%d " % int(ee["lv"])
		Gfx.jtext(self, "%s %d / 12" % [Gfx.L("戦い", "BATTLE"), mini(mi + 1, 40)], Vector2(r.position.x + 120.0, r.position.y + 6.0), Pal.c("white"), 27)
		Gfx.text(self, "LV " + lvs, Vector2(r.position.x + 240.0, r.position.y + 62.0), Pal.c("gray"))
		if cyc > 1:
			Gfx.jtext(self, "%d %s" % [cyc, Gfx.L("周目", "CYCLE")], Vector2(r.position.x + 840.0, r.position.y + 12.0), Pal.c("yellow"), 28)
	if note != "":
		Gfx.jtext(self, note, Vector2(120.0, 560.0), Pal.c("lgreen"), 26)
	var lb: Array = [Gfx.L("消去", "ERASE"), Gfx.L("戻る", "BACK")]
	for i in 2:
		var b2 := _btn(i)
		draw_rect(b2, Pal.c("panel"))
		var e2: Color = Pal.c("line")
		if i == 0 and erase_mode:
			e2 = Pal.c("red")
		draw_rect(b2, e2, false, 2.0)
		var s3: String = lb[i]
		Gfx.jtext(self, s3, Vector2(b2.position.x + (b2.size.x - Gfx.jwidth(s3, 28)) * 0.5, b2.position.y + 9.0), Pal.c("white"), 28)
