extends Node

const RATE := 22050
var enabled := true
var _sfx: Dictionary = {}
var _bgm_cache: Dictionary = {}
var _players: Array = []
var _bgm: AudioStreamPlayer = null
var _cur := ""

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_bgm = AudioStreamPlayer.new()
	_bgm.volume_db = -8.0
	add_child(_bgm)
	_bgm.finished.connect(_on_bgm_finished)

func _on_bgm_finished() -> void:
	if enabled and _cur != "" and _bgm.stream != null:
		_bgm.play()

func _wav(buf: PackedFloat32Array, _loop: bool) -> AudioStreamWAV:
	var n := buf.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var v: float = clampf(buf[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return w

func _hz(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)

func _square(t: float, hz: float, duty: float) -> float:
	var ph: float = fmod(t * hz, 1.0)
	if ph < duty:
		return 1.0
	return -1.0

func _tri(t: float, hz: float) -> float:
	var ph: float = fmod(t * hz, 1.0)
	return 4.0 * absf(ph - 0.5) - 1.0

func _build_sfx(name: String) -> AudioStreamWAV:
	var dur := 0.18
	if name == "down" or name == "level":
		dur = 0.55
	if name == "hit" or name == "slash":
		dur = 0.22
	var n: int = int(float(RATE) * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t: float = float(i) / float(RATE)
		var k: float = 1.0 - t / dur
		var v := 0.0
		if name == "select":
			v = _square(t, 880.0, 0.5) * k * 0.28
		elif name == "confirm":
			var f1 := 660.0
			if t > 0.06:
				f1 = 990.0
			v = _square(t, f1, 0.5) * k * 0.3
		elif name == "cancel":
			var f2 := 520.0
			if t > 0.06:
				f2 = 330.0
			v = _square(t, f2, 0.5) * k * 0.3
		elif name == "slash":
			v = (randf() * 2.0 - 1.0) * k * k * 0.35 + _square(t, 300.0 - t * 400.0, 0.25) * k * 0.15
		elif name == "hit":
			v = (randf() * 2.0 - 1.0) * k * k * 0.42 + _tri(t, 120.0) * k * 0.3
		elif name == "heal":
			var step: int = mini(int(t / 0.05), 3)
			var notes := [72, 76, 79, 84]
			v = _tri(t, _hz(int(notes[step]))) * k * 0.34
		elif name == "down":
			v = _square(t, 220.0 * (1.0 - t * 1.2), 0.5) * k * 0.3 + (randf() * 2.0 - 1.0) * k * k * 0.2
		elif name == "level":
			var st2: int = mini(int(t / 0.09), 5)
			var ns := [60, 64, 67, 72, 76, 79]
			v = _square(t, _hz(int(ns[st2])), 0.5) * k * 0.3
		else:
			v = _square(t, 440.0, 0.5) * k * 0.25
		buf[i] = v
	return _wav(buf, false)

func play(name: String) -> void:
	if not enabled:
		return
	if not _sfx.has(name):
		_sfx[name] = _build_sfx(name)
	var st: AudioStreamWAV = _sfx[name]
	for p in _players:
		var pp: AudioStreamPlayer = p
		if not pp.playing:
			pp.stop()
			pp.stream = st
			pp.play()
			return
	return

const SONGS := {
	"title": {
		"bpm": 104,
		"lead": [69, -1, 72, -1, 76, -1, 74, 72, 69, -1, 67, -1, 69, -1, -1, -1,
			71, -1, 74, -1, 77, -1, 76, 74, 71, -1, 69, -1, 71, -1, -1, -1],
		"bass": [45, 45, 52, 52, 48, 48, 55, 55, 45, 45, 52, 52, 43, 43, 50, 50,
			47, 47, 54, 54, 50, 50, 57, 57, 47, 47, 54, 54, 45, 45, 52, 52],
		"drum": [1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 1, 0,
			1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 2, 0],
	},
	"battle": {
		"bpm": 138,
		"lead": [64, 64, 67, 71, 72, -1, 71, 67, 64, -1, 62, 64, 67, -1, -1, -1,
			65, 65, 69, 72, 74, -1, 72, 69, 65, -1, 64, 62, 64, -1, -1, -1],
		"bass": [40, 40, 47, 40, 43, 43, 50, 43, 40, 40, 47, 40, 38, 38, 45, 45,
			41, 41, 48, 41, 45, 45, 52, 45, 41, 41, 48, 41, 40, 40, 47, 47],
		"drum": [1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 2, 2, 0,
			1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 2, 1, 2],
	},
	"win": {
		"bpm": 120,
		"lead": [72, 72, 72, 76, -1, 79, -1, 84, -1, -1, 81, 79, 81, -1, -1, -1],
		"bass": [48, 48, 48, 52, 52, 55, 55, 60, 60, 60, 57, 55, 57, 57, 57, 57],
		"drum": [1, 0, 1, 0, 2, 0, 2, 0, 1, 0, 1, 0, 2, 2, 2, 0],
	},
	"lose": {
		"bpm": 88,
		"lead": [69, -1, 68, -1, 67, -1, 65, -1, 64, -1, -1, -1, 62, -1, -1, -1],
		"bass": [45, 45, 44, 44, 43, 43, 41, 41, 40, 40, 40, 40, 38, 38, 38, 38],
		"drum": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
	},
}

func _build_song(name: String) -> AudioStreamWAV:
	var song: Dictionary = SONGS[name]
	var lead: Array = song["lead"]
	var bass: Array = song["bass"]
	var drum: Array = song["drum"]
	var bpm: float = float(song["bpm"])
	var step: float = 60.0 / bpm / 2.0
	var steps: int = lead.size()
	var total: int = int(float(RATE) * step * float(steps))
	var buf := PackedFloat32Array()
	buf.resize(total)
	for i in total:
		var t: float = float(i) / float(RATE)
		var si: int = mini(int(t / step), steps - 1)
		var lt: float = t - float(si) * step
		var env: float = clampf(1.0 - lt / step, 0.0, 1.0)
		var v := 0.0
		var ln: int = int(lead[si])
		if ln >= 0:
			v += _square(t, _hz(ln), 0.25) * env * 0.20
		var bn: int = int(bass[si])
		if bn >= 0:
			v += _tri(t, _hz(bn)) * 0.22
		var dn: int = int(drum[si])
		if dn == 1:
			v += _tri(t, 70.0) * clampf(1.0 - lt / 0.10, 0.0, 1.0) * 0.35
		elif dn == 2:
			v += (randf() * 2.0 - 1.0) * clampf(1.0 - lt / 0.07, 0.0, 1.0) * 0.16
		buf[i] = clampf(v, -1.0, 1.0)
	return _wav(buf, true)

func bgm(name: String) -> void:
	if _cur == name:
		return
	_cur = name
	if not enabled or name == "":
		_bgm.stop()
		return
	if not _bgm_cache.has(name):
		_bgm_cache[name] = _build_song(name)
	_bgm.stop()
	_bgm.stream = _bgm_cache[name]
	_bgm.play()

func toggle() -> void:
	enabled = not enabled
	if not enabled:
		_cur = ""
		_bgm.stop()
	else:
		var c := _cur
		_cur = ""
		bgm(c)
