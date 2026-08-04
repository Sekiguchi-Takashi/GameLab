extends Node2D

signal start_battle
signal open_detail(i: int)

var map_i := 0

var step := 0

func _lv(e: Dictionary) -> int:
	if e.has("lv"):
		return int(e["lv"])
	return 0

func setup(i: int) -> void:
	map_i = i
	step = 0
	Save.trace("PSET%d" % i)
	Save.trace("PR%d" % Save.roster.size())
	for k in Save.roster.size():
		var e: Dictionary = Save.roster[k]
		var kind := "?"
		if e.has("kind"):
			kind = String(e["kind"])
		Save.trace("PU%d_%s_L%d" % [k, kind.substr(0, 3), _lv(e)])

func _row(i: int) -> Rect2:
	return Rect2(32.0, 184.0 + float(i) * 86.0, 800.0, 78.0)

func _btn_go() -> Rect2:
	return Rect2(880.0, 592.0, 368.0, 80.0)

var note := ""
var note_t := 0.0

func tap(p: Vector2) -> void:
	if _btn_go().has_point(p):
		Sound.play("confirm")
		Save.trace("DEPLOY")
		start_battle.emit()
		return
	for i in Save.roster.size():
		if _row(i).has_point(p):
			Sound.play("select")
			open_detail.emit(i)
			return

func _process(d: float) -> void:
	if note_t > 0.0:
		note_t -= d
		if note_t <= 0.0:
			note = ""
	queue_redraw()

func _mark(t: String) -> void:
	if step < 40:
		step += 1
		Save.trace(t)

func _draw() -> void:
	_mark("D0")
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.05, 0.06, 0.09, 1.0))
	_mark("D1")
	var m: Dictionary = Maps.get_map(map_i)
	Gfx.jtext(self, "%s%d  %s" % [Gfx.L("第", "BATTLE "), map_i + 1, Maps.name_of(m)], Vector2(32.0, 24.0), Pal.c("white"), 32)
	Gfx.jtext(self, "%s  %s" % [Gfx.L("目的", "OBJECTIVE"), Maps.win_text(m)], Vector2(32.0, 78.0), Pal.c("cyan"), 26)
	Gfx.jtext(self, Gfx.L("出撃する隊", "YOUR COMPANY"), Vector2(32.0, 140.0), Pal.c("gray"), 24)
	_mark("D2")
	for i in Save.roster.size():
		_mark("DR%d" % i)
		var r: Dictionary = Save.roster[i]
		var rr := _row(i)
		draw_rect(rr, Pal.c("panel"))
		draw_rect(rr, Pal.c("line"), false, 1.0)
		_mark("DA%d" % i)
		Gfx.draw_unit(self, Gfx.unit_key(String(r["kind"]), 0, 0), false, Rect2(rr.position.x + 6.0, rr.position.y - 6.0, 88.0, 88.0), Color(1, 1, 1, 1))
		Gfx.jtext(self, "%s  LV%d" % [Units.display(r), int(r["lv"])], Vector2(rr.position.x + 104.0, rr.position.y + 6.0), Pal.c("white"), 26)
		Gfx.text(self, "HP %d/%d  MP %d  ATK %d  DEF %d" % [int(r["hp"]), int(r["mhp"]), int(r["mp"]), int(r["atk"]), int(r["def"])], Vector2(rr.position.x + 104.0, rr.position.y + 46.0), Pal.c("gray"))
		_mark("DP%d" % i)
		var wl: String = Units.weapon_label(String(r["weapon"]))
		Gfx.jtext(self, wl, Vector2(rr.position.x + 520.0, rr.position.y + 8.0), Pal.c("cyan"), 24)
		if Units.can_promote(r):
			Gfx.jtext(self, Gfx.L("昇格可", "PROMOTE"), Vector2(rr.position.x + 520.0, rr.position.y + 46.0), Pal.c("yellow"), 24)
	Gfx.jtext(self, Gfx.L("全員が出撃する。", "ALL UNITS DEPLOY."), Vector2(880.0, 192.0), Pal.c("gray"), 24)
	Gfx.jtext(self, Gfx.L("HPとMPは戦闘前に", "HP AND MP REFILL"), Vector2(880.0, 232.0), Pal.c("gray"), 24)
	Gfx.jtext(self, Gfx.L("全回復する。", "BEFORE EACH BATTLE."), Vector2(880.0, 272.0), Pal.c("gray"), 24)
	Gfx.jtext(self, Gfx.L("行をタップで", "TAP A ROW FOR"), Vector2(880.0, 352.0), Pal.c("cyan"), 24)
	Gfx.jtext(self, Gfx.L("装備と昇格。", "GEAR AND PROMOTION."), Vector2(880.0, 392.0), Pal.c("cyan"), 24)
	_mark("D3")
	var it := "%s %d  %s %d  %s %d" % [Units.item_label("POTION"), int(Save.items["POTION"]), Units.item_label("NUT"), int(Save.items["NUT"]), Units.item_label("STONE"), int(Save.items["STONE"])]
	Gfx.jtext(self, it, Vector2(32.0, 592.0), Pal.c("lgreen"), 26)
	if note != "":
		Gfx.jtext(self, note, Vector2(32.0, 636.0), Pal.c("yellow"), 26)
	Gfx.jtext(self, Gfx.L("戦闘前にHPとMPは", "HP AND MP ARE"), Vector2(880.0, 232.0), Pal.c("gray"), 24)
	Gfx.jtext(self, Gfx.L("全回復する。", "RESTORED BEFORE EACH BATTLE."), Vector2(880.0, 272.0), Pal.c("gray"), 24)
	_mark("D4")
	var b := _btn_go()
	draw_rect(b, Pal.c("panel"))
	draw_rect(b, Pal.c("yellow"), false, 2.0)
	var dep := Gfx.L("出撃", "DEPLOY")
	Gfx.jtext(self, dep, Vector2(b.position.x + (b.size.x - Gfx.jwidth(dep, 32)) * 0.5, b.position.y + 10.0), Pal.c("white"), 32)
	_mark("D5")
