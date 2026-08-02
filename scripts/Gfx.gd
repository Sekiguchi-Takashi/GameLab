extends Node

const FONT := {
	"A": [96, 144, 144, 240, 144, 144, 144, 0],
	"B": [224, 144, 144, 224, 144, 144, 224, 0],
	"C": [112, 136, 128, 128, 128, 136, 112, 0],
	"D": [224, 144, 136, 136, 136, 144, 224, 0],
	"E": [248, 128, 128, 240, 128, 128, 248, 0],
	"F": [248, 128, 128, 240, 128, 128, 128, 0],
	"G": [112, 136, 128, 184, 136, 136, 120, 0],
	"H": [136, 136, 136, 248, 136, 136, 136, 0],
	"I": [112, 32, 32, 32, 32, 32, 112, 0],
	"J": [56, 16, 16, 16, 16, 144, 96, 0],
	"K": [136, 144, 160, 192, 160, 144, 136, 0],
	"L": [128, 128, 128, 128, 128, 128, 248, 0],
	"M": [136, 216, 168, 168, 136, 136, 136, 0],
	"N": [136, 200, 168, 152, 136, 136, 136, 0],
	"O": [112, 136, 136, 136, 136, 136, 112, 0],
	"P": [240, 136, 136, 240, 128, 128, 128, 0],
	"Q": [112, 136, 136, 136, 168, 144, 104, 0],
	"R": [240, 136, 136, 240, 160, 144, 136, 0],
	"S": [120, 128, 128, 112, 8, 8, 240, 0],
	"T": [248, 32, 32, 32, 32, 32, 32, 0],
	"U": [136, 136, 136, 136, 136, 136, 112, 0],
	"V": [136, 136, 136, 136, 136, 80, 32, 0],
	"W": [136, 136, 136, 168, 168, 216, 136, 0],
	"X": [136, 136, 80, 32, 80, 136, 136, 0],
	"Y": [136, 136, 80, 32, 32, 32, 32, 0],
	"Z": [248, 8, 16, 32, 64, 128, 248, 0],
	"0": [112, 136, 152, 168, 200, 136, 112, 0],
	"1": [32, 96, 32, 32, 32, 32, 112, 0],
	"2": [112, 136, 8, 16, 32, 64, 248, 0],
	"3": [248, 16, 32, 16, 8, 136, 112, 0],
	"4": [16, 48, 80, 144, 248, 16, 16, 0],
	"5": [248, 128, 240, 8, 8, 136, 112, 0],
	"6": [48, 64, 128, 240, 136, 136, 112, 0],
	"7": [248, 8, 16, 32, 64, 64, 64, 0],
	"8": [112, 136, 136, 112, 136, 136, 112, 0],
	"9": [112, 136, 136, 120, 8, 16, 96, 0],
	".": [0, 0, 0, 0, 0, 96, 96, 0],
	",": [0, 0, 0, 0, 96, 96, 64, 0],
	"!": [32, 32, 32, 32, 32, 0, 32, 0],
	"?": [112, 136, 8, 16, 32, 0, 32, 0],
	":": [0, 96, 96, 0, 96, 96, 0, 0],
	"-": [0, 0, 0, 248, 0, 0, 0, 0],
	"+": [0, 32, 32, 248, 32, 32, 0, 0],
	"/": [8, 16, 16, 32, 64, 64, 128, 0],
	"*": [0, 168, 112, 248, 112, 168, 0, 0],
	"'": [32, 32, 0, 0, 0, 0, 0, 0],
	"(": [16, 32, 64, 64, 64, 32, 16, 0],
	")": [64, 32, 16, 16, 16, 32, 64, 0],
	"[": [112, 64, 64, 64, 64, 64, 112, 0],
	"]": [112, 16, 16, 16, 16, 16, 112, 0],
	"<": [16, 32, 64, 128, 64, 32, 16, 0],
	">": [64, 32, 16, 8, 16, 32, 64, 0],
	"%": [200, 208, 16, 32, 64, 88, 152, 0],
	"#": [80, 80, 248, 80, 248, 80, 80, 0],
	"=": [0, 0, 248, 0, 248, 0, 0, 0],
	"_": [0, 0, 0, 0, 0, 0, 248, 0],
	"$": [32, 120, 160, 112, 40, 240, 32, 0],
	" ": [0, 0, 0, 0, 0, 0, 0, 0],
}

var _atlas: ImageTexture
var _order := {}
var _cache := {}

func _ready() -> void:
	_build_atlas()

func _build_atlas() -> void:
	var keys: Array = FONT.keys()
	var cols := 16
	var rows := int(ceil(float(keys.size()) / float(cols)))
	var img := Image.create(cols * 8, rows * 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in keys.size():
		var ch: String = keys[i]
		_order[ch] = i
		var bx := (i % cols) * 8
		var by := int(i / cols) * 8
		var g: Array = FONT[ch]
		for y in 8:
			var bits: int = g[y]
			for x in 8:
				if bits & (1 << (7 - x)):
					img.set_pixel(bx + x, by + y, Color(1, 1, 1, 1))
	_atlas = ImageTexture.create_from_image(img)

func text_width(s: String) -> int:
	return s.length() * 6

func text(ci: CanvasItem, s: String, pos: Vector2, col: Color) -> void:
	var up := s.to_upper()
	var x := pos.x
	for i in up.length():
		var ch := up[i]
		if not _order.has(ch):
			ch = " "
		var idx: int = _order[ch]
		var src := Rect2(float((idx % 16) * 8), float(int(idx / 16) * 8), 8.0, 8.0)
		ci.draw_texture_rect_region(_atlas, Rect2(x, pos.y, 8.0, 8.0), src, col)
		x += 6.0

func tex(key: String, rows: Array, cols: Array) -> ImageTexture:
	var ck := key + "|" + str(cols)
	if _cache.has(ck):
		return _cache[ck]
	var h := rows.size()
	var w := String(rows[0]).length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var line: String = rows[y]
		for x in w:
			var c := line[x]
			if c == ".":
				continue
			var ci := int(c) - 1
			if ci >= 0 and ci < cols.size():
				img.set_pixel(x, y, cols[ci])
	var t := ImageTexture.create_from_image(img)
	_cache[ck] = t
	return t

func blit(ci: CanvasItem, t: Texture2D, pos: Vector2, flip_h: bool = false) -> void:
	var w := float(t.get_width())
	var h := float(t.get_height())
	var src := Rect2(0.0, 0.0, w, h)
	if flip_h:
		src = Rect2(w, 0.0, -w, h)
	ci.draw_texture_rect_region(t, Rect2(pos.x, pos.y, w, h), src)

func tex_i(key: String, rows: Array, pal: Array) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var h: int = rows.size()
	var w: int = String(rows[0]).length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var line: String = rows[y]
		for x in w:
			var c: String = line[x]
			if c == ".":
				continue
			var i: int = Art.CHARS.find(c)
			if i >= 0 and i < pal.size():
				img.set_pixel(x, y, pal[i])
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

func drop(key: String) -> void:
	if _cache.has(key):
		_cache.erase(key)

func art(name: String) -> ImageTexture:
	var key := "art:" + name
	if _cache.has(key):
		return _cache[key]
	var e: Dictionary = Art.A[name]
	var hexes: Array = e["p"]
	var cols: Array = []
	for h in hexes:
		cols.append(Color.html(String(h)))
	var rows: Array = e["a"]
	var h2: int = rows.size()
	var w: int = String(rows[0]).length()
	var img := Image.create(w, h2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h2:
		var line: String = rows[y]
		for x in w:
			var c: String = line[x]
			if c == ".":
				continue
			var i: int = Art.CHARS.find(c)
			if i >= 0 and i < cols.size():
				img.set_pixel(x, y, cols[i])
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t
