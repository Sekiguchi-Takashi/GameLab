extends Node2D

enum S { TITLE, PREP, TALK_IN, BATTLE, TALK_OUT, CHECK, END }

var state: int = S.TITLE
var title_n = null
var prep_n = null
var talk_n = null
var battle_n = null
var check_n = null

func _ready() -> void:
	if Save.roster.is_empty():
		Save.new_game()
	title_n = preload("res://scripts/Title.gd").new()
	title_n.pick.connect(_on_title)
	add_child(title_n)
	prep_n = preload("res://scripts/Prep.gd").new()
	prep_n.start_battle.connect(_on_deploy)
	prep_n.visible = false
	add_child(prep_n)
	talk_n = preload("res://scripts/Talk.gd").new()
	talk_n.done.connect(_on_talk_done)
	talk_n.visible = false
	add_child(talk_n)
	check_n = preload("res://scripts/Check.gd").new()
	check_n.visible = false
	add_child(check_n)
	Sound.bgm("title")

func _show(s: int) -> void:
	state = s
	title_n.visible = s == S.TITLE
	prep_n.visible = s == S.PREP
	talk_n.visible = s == S.TALK_IN or s == S.TALK_OUT
	check_n.visible = s == S.CHECK
	if battle_n != null:
		battle_n.visible = s == S.BATTLE

func _on_title(what: String) -> void:
	if what == "NEW":
		Save.new_game()
		_go_prep()
	elif what == "CONTINUE":
		if Save.load_game():
			_go_prep()
		else:
			Save.new_game()
			_go_prep()
	else:
		_show(S.CHECK)

func _go_prep() -> void:
	if Save.map_index >= Maps.count():
		_show(S.END)
		return
	Save.rest()
	prep_n.setup(Save.map_index)
	_show(S.PREP)

func _on_deploy() -> void:
	var m: Dictionary = Maps.get_map(Save.map_index)
	talk_n.setup("%s %d  %s" % [Gfx.L("第", "BATTLE"), Save.map_index + 1, Maps.name_of(m)], Maps.intro_of(m))
	_show(S.TALK_IN)

func _on_talk_done() -> void:
	if state == S.TALK_IN:
		_start_battle()
	else:
		Save.map_index += 1
		Save.save_game()
		_go_prep()

func _start_battle() -> void:
	Sound.bgm("battle")
	if battle_n != null:
		battle_n.queue_free()
	battle_n = preload("res://scripts/Battle.gd").new()
	battle_n.finished.connect(_on_battle_done)
	add_child(battle_n)
	move_child(battle_n, 0)
	battle_n.start(Save.map_index)
	_show(S.BATTLE)

func _on_battle_done(win: bool) -> void:
	if not win:
		Sound.bgm("title")
		_show(S.TITLE)
		return
	for u in battle_n.units:
		var uu: Dictionary = u
		if int(uu["team"]) == 0:
			Save.store(uu)
	Save.resupply()
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
	elif state == S.CHECK:
		if check_n.tap(p):
			_show(S.TITLE)
	elif state == S.END:
		Sound.bgm("title")
		_show(S.TITLE)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if state == S.END:
		draw_rect(Rect2(0.0, 0.0, 640.0, 360.0), Color(0.05, 0.06, 0.09, 1.0))
		var t := Gfx.L("すべての戦いを終えた", "ALL BATTLES CLEARED")
		Gfx.jtext(self, t, Vector2(320.0 - Gfx.jwidth(t, 18) * 0.5, 146.0), Pal.c("yellow"), 18)
		var t2 := Gfx.L("画面をタップでタイトルへ", "TAP TO RETURN TO TITLE")
		Gfx.jtext(self, t2, Vector2(320.0 - Gfx.jwidth(t2, 13) * 0.5, 182.0), Pal.c("gray"), 13)
