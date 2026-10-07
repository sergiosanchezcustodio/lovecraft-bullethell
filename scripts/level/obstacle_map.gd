class_name ObstacleMap
extends RefCounted
## Lo que no se puede atravesar en la arena, en el plano XZ.
## - Con mapa de lo transitable (`load_mask`, generado por tools/gen_mapa_transitable.py con
##   los voxels reales de las piezas): una rejilla de 25 cm con lo bloqueado al andar, lo
##   bloqueado a las balas y la distancia de cada celda a lo bloqueado. Sigue los límites
##   dibujados (frente de los acantilados, costa) y la huella real de cada pieza.
## - Sin él: los límites son un rectángulo y los obstáculos, círculos.
## Lo usan jugadores, mascotas, enemigos (sin cuerpo físico) y balas.

var bounds := Rect2(-32, -32, 64, 64)
var _grid := SpatialGrid.new(3.0)
var _circles: Array[Vector3] = []        ## (x, z, radio): también para dibujarlos en el mapa
var _mask := PackedByteArray()           ## N × N × 3: andar, balas, distancia
var _n := 0
var _cell := 0.25
var _origin := Vector2.ZERO
var _dist_step := 1.0 / 32.0
var _water := PackedByteArray()          ## N × N: agua somera (0..255), si la arena la tiene (hito 6.4)

func add_circle(center: Vector2, radius: float) -> void:
	_circles.append(Vector3(center.x, center.y, radius))
	_grid.insert(center, radius)

## Carga el mapa de lo transitable ({file, size, cell, origin, dist_step} del JSON de la
## arena). Los límites pasan a ser la caja de lo transitable.
func load_mask(def: Dictionary) -> bool:
	var bytes := FileAccess.get_file_as_bytes(String(def.file))
	var n := int(def.size)
	if bytes.size() != n * n * 3: return false
	_mask = bytes
	_n = n
	_cell = float(def.cell)
	_origin = Vector2(def.origin[0], def.origin[1])
	_dist_step = float(def.dist_step)
	_water = PackedByteArray()
	if def.has("water"):                     # agua somera que frena (pantano, hito 6.4)
		var w := FileAccess.get_file_as_bytes(String(def.water))
		if w.size() == n * n: _water = w
	var lo := Vector2(INF, INF)
	var hi := -lo
	for j in n:
		for i in n:
			if _mask[(j * n + i) * 3] == 0:
				lo = lo.min(Vector2(i, j))
				hi = hi.max(Vector2(i + 1, j + 1))
	bounds = Rect2(_origin + lo * _cell, (hi - lo) * _cell)
	return true

## ¿Hay agua somera en ese punto? (0: seco, 1: agua). Por celda, sin interpolar.
func water_at(pos: Vector2) -> float:
	if _water.is_empty(): return 0.0
	var i := int(floor((pos.x - _origin.x) / _cell)); var j := int(floor((pos.y - _origin.y) / _cell))
	if i < 0 or j < 0 or i >= _n or j >= _n: return 0.0
	return _water[j * _n + i] / 255.0

## Punto de agua somera al azar entre rmin y rmax de center, libre para un cuerpo de radio r
## (Vector2.INF si no hay). Para los que salen del agua (hito 6.4).
func random_water(rng: RandomNumberGenerator, center: Vector2, rmin: float, rmax: float, r := 0.6) -> Vector2:
	if _water.is_empty(): return Vector2.INF
	for attempt in 40:
		var a := rng.randf() * TAU
		var p := center + Vector2(cos(a), sin(a)) * rng.randf_range(rmin, rmax)
		if water_at(p) > 0.5 and not is_blocked(p, r): return p
	return Vector2.INF

func has_water() -> bool:
	return not _water.is_empty()

## El agua como textura (L8, N × N) para el shader del suelo, o null.
func water_texture() -> ImageTexture:
	if _water.is_empty(): return null
	return ImageTexture.create_from_image(Image.create_from_data(_n, _n, false, Image.FORMAT_L8, _water))

func has_mask() -> bool:
	return _n > 0

## Los obstáculos como (x, z, radio), para dibujarlos en el mapa del nivel.
func circles() -> Array[Vector3]:
	return _circles

func count() -> int:
	return _circles.size()

## Distancia (m) de un punto a lo bloqueado; 0 si está dentro. Interpolada entre celdas.
func distance(pos: Vector2) -> float:
	var f := (pos - _origin) / _cell - Vector2(0.5, 0.5)
	var i := int(floor(f.x)); var j := int(floor(f.y))
	var t := f - Vector2(i, j)
	var a := _dist(i, j); var b := _dist(i + 1, j)
	var c := _dist(i, j + 1); var d := _dist(i + 1, j + 1)
	# la rejilla mide de centro a centro de celda: lo bloqueado empieza media celda antes
	return maxf(lerpf(lerpf(a, b, t.x), lerpf(c, d, t.x), t.y) - _cell * 0.5, 0.0)

func _dist(i: int, j: int) -> float:
	if i < 0 or j < 0 or i >= _n or j >= _n: return 0.0
	return _mask[(j * _n + i) * 3 + 2] * _dist_step

func _cell_at(pos: Vector2, channel: int) -> bool:
	var i := int(floor((pos.x - _origin.x) / _cell)); var j := int(floor((pos.y - _origin.y) / _cell))
	if i < 0 or j < 0 or i >= _n or j >= _n: return true
	return _mask[(j * _n + i) * 3 + channel] != 0

## ¿Para una bala en ese punto? (lo que hay a la altura de las balas: muros, casetas…)
func stops_bullet(pos: Vector2) -> bool:
	return _n > 0 and _cell_at(pos, 1)

## ¿Se solapa un círculo (pos, r) con algún obstáculo o se sale de la arena?
func is_blocked(pos: Vector2, r: float) -> bool:
	if _n > 0: return distance(pos) < r
	if not bounds.grow(-r).has_point(pos): return true
	return not _grid.query_circle(pos, r).is_empty()

## Desplaza un círculo (pos, r) fuera de los obstáculos y dentro de la arena.
func push_out(pos: Vector2, r: float) -> Vector2:
	if _n > 0: return _push_mask(pos, r)
	for id in _grid.query_circle(pos, r):
		var c := _circles[id]
		var d := pos - Vector2(c.x, c.y)
		var min_d := c.z + r
		var len := d.length()
		if len < min_d:
			pos = Vector2(c.x, c.y) + (d / len if len > 0.001 else Vector2.RIGHT) * min_d
	var b := bounds.grow(-r)
	return Vector2(clampf(pos.x, b.position.x, b.end.x), clampf(pos.y, b.position.y, b.end.y))

## Con el mapa: sube por la pendiente de la distancia hasta estar a r de lo bloqueado.
func _push_mask(pos: Vector2, r: float) -> Vector2:
	if distance(pos) <= 0.0: pos = _nearest_free(pos, r)     # dentro de algo: no hay pendiente, se busca
	for k in 4:
		var d := distance(pos)
		if d >= r: return pos
		var e := _cell * 0.5
		var g := Vector2(distance(pos + Vector2(e, 0)) - distance(pos - Vector2(e, 0)),
			distance(pos + Vector2(0, e)) - distance(pos - Vector2(0, e)))
		if g.length() < 0.0001: return pos
		pos += g.normalized() * (r - d + 0.01)
	return pos

## Centro de la celda libre (a más de r de lo bloqueado) más cercana, en anillos de hasta 6 m.
func _nearest_free(pos: Vector2, r: float) -> Vector2:
	var ci := int(floor((pos.x - _origin.x) / _cell)); var cj := int(floor((pos.y - _origin.y) / _cell))
	var need := r + _cell * 0.5
	for ring in range(1, int(6.0 / _cell)):
		var best := Vector2.INF
		var best_d := INF
		for di in range(-ring, ring + 1):
			for dj in [-ring, ring]:
				for q in [Vector2i(ci + di, cj + dj), Vector2i(ci + dj, cj + di)]:
					if _dist(q.x, q.y) < need: continue
					var c := _origin + (Vector2(q) + Vector2(0.5, 0.5)) * _cell
					var dd := c.distance_squared_to(pos)
					if dd < best_d:
						best_d = dd
						best = c
		if best_d < INF: return best
	return pos
