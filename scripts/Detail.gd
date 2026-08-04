extends Node2D

signal closed

var idx := 0
var note := ""
var note_t := 0.0

func setup(i: int) -> void:
	idx = i
	note = ""
	note_t = 0.0

func _entry() -> Dictionary:
	return Save.roster[clampi(idx, 0, Save.roster.size() - 1)]

func _list() -> Array:
	var e: Dictionary = _entry()
	var kind: String = String(e["kind"])
	var out: Array = []
	for k in Units.WEAPONS.keys():
		var key: String = k
		if not Units.can_equip(kind, key):
			continue
		if Save.stash.has(key) and int(Save.stash[key]) > 0:
			out.append(key)
	out.sort()
	return out

func _row(i: int) -> Rect2:
	return Rect2(660.0, 190.0 + float(i) * 62.0, 590.0, 56.0)

func _btn(i: int) -> Rect2:
	return Rect2(40.0 + float(i) * 300.0, 616.0, 280.0, 68.0)

func tap(p: Vector2) -> void:
	if _btn(2).has_point(p):
		Sound.play("cancel")
		closed.emit()
		return
	var e: Dictionary = _entry()
	if _btn(0).has_point(p):
		if Units.can_promote(e):
			Save.roster[idx] = Units.promote(e)
			var ne: Dictionary = Save.roster[idx]
			var w := String(ne["weapon"])
			if w != "" and not Units.can_equip(String(ne["kind"]), w):
				Save.add_stash(w)
				ne["weapon"] = ""
			Sound.play("level")
			_say("%s %s" % [Units.label(String(ne["kind"])), Gfx.L("に昇格", "PROMOTED")])
		else:
			Sound.play("cancel")
			_say(Gfx.L("昇格はLV10から", "PROMOTE AT LV10"))
		return
	if _btn(1).has_point(p):
		var cur := String(e["weapon"])
		if cur == "":
			Sound.play("cancel")
			_say(Gfx.L("外す装備がない", "NOTHING EQUIPPED"))
			return
		Save.add_stash(cur)
		e["weapon"] = ""
		Sound.play("select")
		_say(Gfx.L("装備を外した", "UNEQUIPPED"))
		return
	var l := _list()
	for i in l.size():
		if i >= 7:
			break
		if _row(i).has_point(p):
			var key: String = l[i]
			if not Save.take_stash(key):
				return
			var cur2 := String(e["weapon"])
			if cur2 != "":
				Save.add_stash(cur2)
			e["weapon"] = key
			Sound.play("confirm")
			_say("%s %s" % [Units.weapon_label(key), Gfx.L("を装備", "EQUIPPED")])
			return

func _say(t: String) -> void:
	note = t
	note_t = 2.2

func _process(d: float) -> void:
	if note_t > 0.0:
		note_t -= d
		if note_t <= 0.0:
			note = ""
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.05, 0.06, 0.09, 1.0))
	if Save.roster.is_empty():
		return
	var e: Dictionary = _entry()
	var kind: String = String(e["kind"])
	Gfx.draw_unit(self, Gfx.unit_key(kind, 0, 0), false, Rect2(40.0, 48.0, 160.0, 160.0), Color(1, 1, 1, 1))
	Gfx.jtext(self, "%s  LV%d" % [Units.display(e), int(e["lv"])], Vector2(224.0, 48.0), Pal.c("white"), 32)
	var w := String(e["weapon"])
	var wa: int = Units.weapon_atk(w)
	var wr: int = Units.weapon_rng(w)
	Gfx.text(self, "HP %d/%d   MP %d" % [int(e["hp"]), int(e["mhp"]), int(e["mp"])], Vector2(224.0, 104.0), Pal.c("lgreen"))
	Gfx.text(self, "ATK %d + %d = %d" % [int(e["atk"]), wa, int(e["atk"]) + wa], Vector2(224.0, 132.0), Pal.c("gray"))
	Gfx.text(self, "DEF %d   MOV %d   SPD %d" % [int(e["def"]), int(e["mov"]), int(e["spd"])], Vector2(224.0, 160.0), Pal.c("gray"))
	Gfx.text(self, "RNG %d + %d = %d" % [int(e["rng"]), wr, int(e["rng"]) + wr], Vector2(224.0, 188.0), Pal.c("gray"))
	Gfx.jtext(self, "%s  %s" % [Gfx.L("装備", "WEAPON"), Units.weapon_label(w)], Vector2(40.0, 244.0), Pal.c("yellow"), 28)
	Gfx.jtext(self, Gfx.L("装備できる武器", "AVAILABLE"), Vector2(640.0, 136.0), Pal.c("gray"), 24)
	var l := _list()
	if l.is_empty():
		Gfx.jtext(self, Gfx.L("倉庫に無い", "STASH EMPTY"), Vector2(660.0, 192.0), Pal.c("dgray"), 26)
	for i in l.size():
		if i >= 7:
			break
		var key: String = l[i]
		var r := _row(i)
		draw_rect(r, Pal.c("panel"))
		draw_rect(r, Pal.c("line"), false, 1.0)
		Gfx.jtext(self, "%s  x%d" % [Units.weapon_label(key), int(Save.stash[key])], Vector2(r.position.x + 8.0, r.position.y + 4.0), Pal.c("white"), 26)
		var wd: Dictionary = Units.WEAPONS[key]
		Gfx.text(self, "ATK+%d RNG+%d" % [int(wd["atk"]), int(wd["rng"])], Vector2(r.position.x + 196.0, r.position.y + 8.0), Pal.c("cyan"))
	if note != "":
		Gfx.jtext(self, note, Vector2(40.0, 552.0), Pal.c("lgreen"), 26)
	var labels: Array = [Gfx.L("昇格", "PROMOTE"), Gfx.L("外す", "UNEQUIP"), Gfx.L("戻る", "BACK")]
	for i in 3:
		var b := _btn(i)
		draw_rect(b, Pal.c("panel"))
		draw_rect(b, Pal.c("line"), false, 2.0)
		var col: Color = Pal.c("white")
		if i == 0 and not Units.can_promote(e):
			col = Pal.c("dgray")
		var s: String = labels[i]
		Gfx.jtext(self, s, Vector2(b.position.x + (b.size.x - Gfx.jwidth(s, 28)) * 0.5, b.position.y + 7.0), col, 28)
