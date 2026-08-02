extends Node2D

const W := 24
const H := 18
const TS := 32.0

const COST := {0: 1, 1: 1, 2: 99, 3: 99, 4: 2, 5: 1}
const DEF := {0: 0, 1: 0, 2: 0, 3: 3, 4: 2, 5: 0}

var terrain: Array = []

func _ready() -> void:
	z_index = 0
	_generate()

func _generate() -> void:
	terrain = []
	for y in H:
		var row: Array = []
		for x in W:
			row.append(0)
		terrain.append(row)
	for x in W:
		terrain[9][x] = 1
	for y in range(2, 7):
		terrain[y][15] = 1
	for y in range(11, 16):
		terrain[y][6] = 1
	var rocks := [[3, 3], [4, 3], [3, 4], [19, 5], [20, 5], [20, 6], [11, 13], [12, 13], [17, 14]]
	for r in rocks:
		var rr: Array = r
		terrain[int(rr[1])][int(rr[0])] = 3
	var trees := [[7, 2], [8, 3], [6, 4], [9, 5], [13, 2], [14, 6], [2, 12], [3, 14], [9, 15],
		[15, 12], [16, 15], [21, 12], [20, 15], [5, 6], [18, 3], [11, 4], [22, 8], [1, 7]]
	for t in trees:
		var tt: Array = t
		terrain[int(tt[1])][int(tt[0])] = 4
	var water := [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [22, 16], [23, 16], [22, 17], [23, 17],
		[23, 15], [12, 8], [13, 8], [12, 7], [11, 8]]
	for w in water:
		var ww: Array = w
		terrain[int(ww[1])][int(ww[0])] = 2
	var flowers := [[5, 11], [17, 7], [10, 1], [19, 16], [2, 16]]
	for f in flowers:
		var ff: Array = f
		terrain[int(ff[1])][int(ff[0])] = 5

func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H

func at(x: int, y: int) -> int:
	if not inside(x, y):
		return 3
	var row: Array = terrain[y]
	return int(row[x])

func cost(x: int, y: int) -> int:
	return int(COST[at(x, y)])

func defense(x: int, y: int) -> int:
	return int(DEF[at(x, y)])

func world_size() -> Vector2:
	return Vector2(float(W) * TS, float(H) * TS)

func draw_map(ci: CanvasItem, cam: Vector2, view: Rect2) -> void:
	var x0: int = maxi(int((cam.x - view.position.x) / TS) - 1, 0)
	var y0: int = maxi(int((cam.y - view.position.y) / TS) - 1, 0)
	var x1: int = mini(x0 + int(view.size.x / TS) + 3, W)
	var y1: int = mini(y0 + int(view.size.y / TS) + 3, H)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var k: int = at(x, y)
			var tname: String = Art.TILE_KINDS[k]
			var t: Texture2D = Gfx.art(tname)
			var p := Vector2(float(x) * TS, float(y) * TS) - cam + view.position
			ci.draw_texture_rect_region(t, Rect2(p.x, p.y, TS, TS), Rect2(0.0, 0.0, TS, TS))
