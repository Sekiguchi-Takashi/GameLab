extends Node2D

enum S { TITLE, PREP, TALK_IN, BATTLE, TALK_OUT, CHECK, END, DETAIL, SLOTS, RECORDS }

var state: int = S.TITLE
var title_n = null
var prep_n = null
var talk_n = null
var battle_n = null
var check_n = null
var detail_n = null
var slots_n = null
var records_n = null

func _ready() -> void:
	Save.read_trace()
	Save.clear_trace()
	Save.trace("BOOT")
	if Save.roster.is_empty():
		Save.new_game()
	title_n = preload("res://scripts/Title.gd").new()
	title_n.pick.connect(_on_title, CONNECT_DEFERRED)
	add_child(title_n)
	prep_n = preload("res://scripts/Prep.gd").new()
	prep_n.start_battle.connect(_on_deploy, CONNECT_DEFERRED)
	prep_n.visible = false
	add_child(prep_n)
	talk_n = preload("res://scripts/Talk.gd").new()
	talk_n.done.connect(_on_talk_done, CONNECT_DEFERRED)
	talk_n.visible = false
	add_child(talk_n)
	check_n = preload("res://scripts/Check.gd").new()
	check_n.visible = false
	add_child(check_n)
	detail_n = preload("res://scripts/Detail.gd").new()
	detail_n.visible = false
	detail_n.closed.connect(_on_detail_closed, CONNECT_DEFERRED)
	add_child(detail_n)
	prep_n.open_detail.connect(_on_open_detail, CONNECT_DEFERRED)
	slots_n = preload("res://scripts/Slots.gd").new()
	slots_n.visible = false
	slots_n.chosen.connect(_on_slot, CONNECT_DEFERRED)
	slots_n.back.connect(_to_title, CONNECT_DEFERRED)
	add_child(slots_n)
	records_n = preload("res://scripts/Records.gd").new()
	records_n.visible = false
	records_n.back.connect(_to_title, CONNECT_DEFERRED)
	add_child(records_n)
	Sound.bgm("title")

func _show(s: int) -> void:
	state = s
	Save.trace("SHOW%d/M%d" % [s, Save.map_index])
	title_n.visible = s == S.TITLE
	prep_n.visible = s == S.PREP
	talk_n.visible = s == S.TALK_IN or s == S.TALK_OUT
	check_n.visible = s == S.CHECK
	detail_n.visible = s == S.DETAIL
	slots_n.visible = s == S.SLOTS
	records_n.visible = s == S.RECORDS
	if battle_n != null:
		battle_n.visible = s == S.BATTLE

func _to_title() -> void:
	Sound.bgm("title")
	_show(S.TITLE)

func _on_title(what: String) -> void:
	if what == "PLAY":
		slots_n.setup()
		_show(S.SLOTS)
	elif what == "RECORDS":
		_show(S.RECORDS)
	else:
		_show(S.CHECK)

func _on_slot(sl: int, is_new: bool) -> void:
	Save.slot = sl
	if is_new:
		var d := Save.difficulty
		Save.new_game()
		Save.difficulty = d
		Save.save_game()
	else:
		if not Save.load_game():
			Save.new_game()
	_go_prep()

func _on_open_detail(i: int) -> void:
	detail_n.setup(i)
	_show(S.DETAIL)

func _on_detail_closed() -> void:
	prep_n.setup(Save.map_index)
	_show(S.PREP)

func _go_prep() -> void:
	Save.trace("PREP%d" % Save.map_index)
	if Save.map_index >= Maps.count():
		Save.bump("clears", 1)
		Save.save_game()
		Sound.bgm("win")
		_show(S.END)
		return
	Save.rest()
	Save.trace("REST")
	prep_n.setup(Save.map_index)
	Sound.bgm("title")
	_show(S.PREP)

func _on_deploy() -> void:
	var m: Dictionary = Maps.get_map(Save.map_index)
	talk_n.setup("%s %d  %s" % [Gfx.L("第", "BATTLE"), Save.map_index + 1, Maps.name_of(m)], Maps.intro_of(m))
	_show(S.TALK_IN)

func _on_talk_done() -> void:
	Save.trace("TDONE%d" % state)
	if state == S.TALK_IN:
		_start_battle()
	else:
		Save.map_index += 1
		Save.trace("ADV%d" % Save.map_index)
		Save.save_game()
		Save.trace("SAVED")
		_go_prep()

func _start_battle() -> void:
	Save.trace("BATTLE%d" % Save.map_index)
	if state == S.BATTLE:
		return
	Sound.bgm("battle")
	if battle_n != null:
		battle_n.finished.disconnect(_on_battle_done)
		remove_child(battle_n)
		battle_n.queue_free()
		battle_n = null
	battle_n = preload("res://scripts/Battle.gd").new()
	battle_n.finished.connect(_on_battle_done, CONNECT_DEFERRED)
	add_child(battle_n)
	move_child(battle_n, 0)
	battle_n.start(Save.map_index)
	_show(S.BATTLE)

func _on_battle_done(win: bool) -> void:
	Save.trace("DONE" + str(win))
	if not win:
		Sound.bgm("title")
		if battle_n != null:
			battle_n.finished.disconnect(_on_battle_done)
			remove_child(battle_n)
			battle_n.queue_free()
			battle_n = null
		_show(S.TITLE)
		return
	var bu: Array = []
	if battle_n != null:
		bu = battle_n.units
	for u in bu:
		var uu: Dictionary = u
		if int(uu["team"]) == 0:
			Save.store(uu)
	Save.trace("HARVEST")
	if battle_n != null:
		battle_n.finished.disconnect(_on_battle_done)
		remove_child(battle_n)
		battle_n.queue_free()
		battle_n = null
	Save.trace("FREED")
	Save.resupply()
	if battle_n != null:
		var dr: Array = battle_n.drops
		for k in dr:
			Save.add_stash(String(k))
	Save.trace("STORE")
	var m: Dictionary = Maps.get_map(Save.map_index)
	talk_n.setup(Gfx.L("勝利", "VICTORY"), Maps.outro_of(m))
	_show(S.TALK_OUT)

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch) or not e.pressed:
		return
	var p: Vector2 = e.position
	if state == S.TITLE:
		title_n.tap(p)
	elif state == S.PREP:
		prep_n.tap(p)
	elif state == S.TALK_IN or state == S.TALK_OUT:
		talk_n.tap(p)
	elif state == S.DETAIL:
		detail_n.tap(p)
	elif state == S.SLOTS:
		slots_n.tap(p)
	elif state == S.RECORDS:
		records_n.tap(p)
	elif state == S.CHECK:
		if check_n.tap(p):
			_show(S.TITLE)
	elif state == S.END:
		if _end_btn().has_point(p):
			Save.new_plus()
			Save.save_game()
			_go_prep()
		else:
			Sound.bgm("title")
			_show(S.TITLE)

func _end_btn() -> Rect2:
	return Rect2(200.0, 300.0, 240.0, 34.0)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if state == S.END:
		draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.05, 0.06, 0.09, 1.0))
		var n := 0
		for e in Save.roster:
			var ee: Dictionary = e
			Gfx.draw_unit(self, "%s0" % String(ee["kind"]), false, Rect2(70.0 + float(n) * 100.0, 210.0, 72.0, 72.0), Color(1, 1, 1, 1))
			n += 1
		var b := _end_btn()
		draw_rect(b, Pal.c("panel"))
		draw_rect(b, Pal.c("yellow"), false, 2.0)
		var bs := Gfx.L("引き継いで最初から", "NEW GAME PLUS")
		Gfx.jtext(self, bs, Vector2(b.position.x + (b.size.x - Gfx.jwidth(bs, 15)) * 0.5, b.position.y + 8.0), Pal.c("white"), 15)
		var t := Gfx.L("すべての戦いを終えた", "ALL BATTLES CLEARED")
		Gfx.jtext(self, t, Vector2(320.0 - Gfx.jwidth(t, 18) * 0.5, 146.0), Pal.c("yellow"), 18)
		var t2 := Gfx.L("画面をタップでタイトルへ", "TAP TO RETURN TO TITLE")
		Gfx.jtext(self, t2, Vector2(320.0 - Gfx.jwidth(t2, 13) * 0.5, 182.0), Pal.c("gray"), 13)
		Gfx.jtext(self, "%s %d" % [Gfx.L("周回", "CYCLE"), Save.cycle], Vector2(20.0, 20.0), Pal.c("yellow"), 14)
