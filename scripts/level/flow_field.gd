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
var built := false                       ## ya hay distancias (antes de la primera pasada, todo vale)

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
	built = true
	_gen += 1                                   # las direcciones guardadas ya no valen
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
## La celda vecina a la que bajar solo cambia al rehacer las distancias: se guarda por celda
## hasta la pasada siguiente (hito 23.6: era la mitad de lo que costaba ir hacia el jugador).
var _gen := 1                            ## pasada de las distancias (sube en cada `rebuild`)
var _best := PackedInt32Array()          ## celda vecina a la que bajar (-1: ninguna)
var _best_gen := PackedInt32Array()      ## en qué pasada se calculó
func direction(from: Vector2) -> Vector2:
	var ci := int(floor((from.x - origin.x) / CELL))
	var cj := int(floor((from.y - origin.y) / CELL))
	if ci < 0 or cj < 0 or ci >= w or cj >= h: return Vector2.ZERO
	var k := cj * w + ci
	if _best.size() != w * h:
		_best.resize(w * h)
		_best_gen.resize(w * h)
		_best_gen.fill(0)
	if _best_gen[k] != _gen:
		_best_gen[k] = _gen
		_best[k] = _best_from(Vector2i(ci, cj))
	var b := _best[k]
	if b < 0: return Vector2.ZERO
	return (center(b % w, b / w) - from).normalized()

## La celda vecina con menos distancia (en diagonal, +0,414), o -1 si ninguna mejora la propia.
func _best_from(c: Vector2i) -> int:
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
	return -1 if best_c == c else best_c.y * w + best_c.x

## Distancia andando hasta el jugador más cercano (INF_D si desde ahí no se llega).
func distance_at(p: Vector2) -> float:
	var c := cell_of(p)
	if not _inside(c): return INF_D
	var k := c.y * w + c.x
	if _free[k] == 0: return INF_D
	return _dist[k] if built else 0.0

## ¿Se llega andando desde ahí hasta algún jugador?
func reachable(p: Vector2) -> bool:
	return distance_at(p) < INF_D

## ¿Pasillo recto libre entre dos puntos, del ancho del cuerpo (radio r)? Se mira la línea
## del centro y las dos de los costados: midiendo solo el centro, el enemigo iba recto y se
## enganchaba en las esquinas con el hombro.
func clear_line(a: Vector2, b: Vector2, r := 0.0) -> bool:
	var d := a.distance_to(b)
	if d < 0.01: return true
	var side := Vector2(b.y - a.y, a.x - b.x) / d * r
	var steps := maxi(2, int(d / CELL) + 1)          # una muestra por celda, sin arrays en el bucle
	var lanes := 3 if r > 0.0 else 1
	for s in range(1, steps):
		var m := a.lerp(b, float(s) / steps)
		for k in lanes:
			var c := cell_of(m + (side if k == 1 else (-side if k == 2 else Vector2.ZERO)))
			if not _inside(c) or _free[c.y * w + c.x] == 0: return false
	return true
