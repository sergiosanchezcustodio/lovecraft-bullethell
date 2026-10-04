class_name FlowField
extends RefCounted
## Mapa de flujo para que los enemigos rodeen el decorado (04-10-2026): una rejilla de CELL m
## sobre la arena con la distancia andando desde la celda de cada jugador (BFS con 4
## vecinos sobre lo transitable del ObstacleMap). Un enemigo baja por la pendiente: va a la
## celda vecina con menos distancia. Se rehace cada REBUILD s; cuesta lo mismo con 1 que con
## 150 enemigos. Con la vista despejada hasta el jugador, el enemigo va en línea recta.

const CELL := 1.0
const REBUILD := 0.8
const INF_D := 1e9
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var obstacles: ObstacleMap
var origin := Vector2.ZERO
var w := 0
var h := 0
var _free := PackedByteArray()
var _dist := PackedFloat32Array()
var _t := 999.0

func setup(p_obstacles: ObstacleMap, bounds: Rect2) -> FlowField:
	obstacles = p_obstacles
	origin = bounds.position
	w = int(ceil(bounds.size.x / CELL))
	h = int(ceil(bounds.size.y / CELL))
	_free.resize(w * h)
	_dist.resize(w * h)
	for j in h:
		for i in w:
			_free[j * w + i] = 0 if obstacles.is_blocked(center(i, j), 0.35) else 1
	return self

func center(i: int, j: int) -> Vector2:
	return origin + Vector2(i + 0.5, j + 0.5) * CELL

func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor((p.x - origin.x) / CELL)), int(floor((p.y - origin.y) / CELL)))

func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h

func tick(delta: float, targets: Array[Vector2]) -> void:
	_t += delta
	if _t < REBUILD: return
	_t = 0.0
	rebuild(targets)

## Distancias desde los objetivos (cada celda, al más cercano). BFS de 4 vecinos con una
## cola de tamaño fijo (sin crecer arrays en GDScript): unas 4.000 celdas libres por pasada.
var _queue := PackedInt32Array()
func rebuild(targets: Array[Vector2]) -> void:
	_dist.fill(INF_D)
	if _queue.size() != w * h: _queue.resize(w * h)
	var tail := 0
	for t in targets:
		var c := cell_of(t)
		if not _inside(c): continue
		var k0 := c.y * w + c.x
		if _dist[k0] == 0.0: continue
		_dist[k0] = 0.0
		_queue[tail] = k0
		tail += 1
	var head := 0
	while head < tail:
		var k := _queue[head]
		head += 1
		var nd := _dist[k] + 1.0
		var ci := k % w
		# cuatro vecinos, a mano (más rápido que recorrer una lista)
		if ci + 1 < w and _free[k + 1] == 1 and _dist[k + 1] > nd:
			_dist[k + 1] = nd; _queue[tail] = k + 1; tail += 1
		if ci > 0 and _free[k - 1] == 1 and _dist[k - 1] > nd:
			_dist[k - 1] = nd; _queue[tail] = k - 1; tail += 1
		if k + w < w * h and _free[k + w] == 1 and _dist[k + w] > nd:
			_dist[k + w] = nd; _queue[tail] = k + w; tail += 1
		if k - w >= 0 and _free[k - w] == 1 and _dist[k - w] > nd:
			_dist[k - w] = nd; _queue[tail] = k - w; tail += 1

## Dirección (en el plano) hacia el jugador por el camino libre; ZERO si no hay camino.
func direction(from: Vector2) -> Vector2:
	var c := cell_of(from)
	if not _inside(c): return Vector2.ZERO
	var best := _dist[c.y * w + c.x] if _free[c.y * w + c.x] == 1 else INF_D
	var best_c := c
	for dv: Vector2i in DIRS:
		var n := c + dv
		if not _inside(n): continue
		var nk := n.y * w + n.x
		if _free[nk] == 0: continue
		var cost := _dist[nk] + (0.414 if dv.x != 0 and dv.y != 0 else 0.0)
		if cost < best:
			best = cost
			best_c = n
	if best_c == c: return Vector2.ZERO
	return (center(best_c.x, best_c.y) - from).normalized()

## ¿Línea recta libre entre dos puntos? (muestreo cada media celda)
func clear_line(a: Vector2, b: Vector2) -> bool:
	var d := a.distance_to(b)
	var steps := int(d / (CELL * 0.5))
	for s in range(1, steps):
		var c := cell_of(a.lerp(b, float(s) / steps))
		if not _inside(c) or _free[c.y * w + c.x] == 0: return false
	return true
