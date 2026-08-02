extends Node2D

const TS := 32.0

const COST := {0: 1, 1: 1, 2: 99, 3: 99, 4: 2, 5: 1, 6: 2, 7: 1, 8: 2, 9: 3}
const DEF := {0: 0, 1: 0, 2: 0, 3: 3, 4: 2, 5: 0, 6: 0, 7: 0, 8: 2, 9: 4}
const TICK := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: -3, 7: 4, 8: 0, 9: 0}
const BONUS_RNG := {8: 1}

var W := 20
var H := 14
var terrain: Array = []

func load_rows(rows: Array) -> void:
	H = rows.size()
	W = String(rows[0]).length()
	terrain = []
	for y in H:
		var line: String = rows[y]
		var row: Array = []
		for x in W:
			var c: String = line[x]
			var v := 0
			if Maps.CH_TO_TILE.has(c):
				v = int(Maps.CH_TO_TILE[c])
			row.append(v)
		terrain.append(row)

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

func tick(x: int, y: int) -> int:
	return int(TICK[at(x, y)])

func range_bonus(x: int, y: int) -> int:
	var k: int = at(x, y)
	if BONUS_RNG.has(k):
		return int(BONUS_RNG[k])
	return 0

func world_size() -> Vector2:
	return Vector2(float(W) * TS, float(H) * TS)

func draw_map(ci: CanvasItem, cam: Vector2, view: Rect2) -> void:
	var x0: int = maxi(int(cam.x / TS) - 1, 0)
	var y0: int = maxi(int(cam.y / TS) - 1, 0)
	var x1: int = mini(x0 + int(view.size.x / TS) + 3, W)
	var y1: int = mini(y0 + int(view.size.y / TS) + 3, H)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var tname: String = Art.TILE_KINDS[at(x, y)]
			var t: Texture2D = Gfx.art(tname)
			var p := Vector2(float(x) * TS, float(y) * TS) - cam + view.position
			ci.draw_texture_rect_region(t, Rect2(p.x, p.y, TS, TS), Rect2(0.0, 0.0, TS, TS))
