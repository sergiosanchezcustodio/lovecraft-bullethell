class_name SpatialGrid
extends RefCounted
## Rejilla espacial 2D (plano XZ) para consultas de proximidad: balas contra enemigos,
## búsqueda del enemigo más cercano o de la zona más densa. Se vacía y se rellena
## cada fotograma; las entradas son índices enteros que interpreta quien la usa.

var cell := 2.0
var _cells := {}                          # Vector2i -> PackedInt32Array
var _pos := PackedVector2Array()          # posición por índice
var _rad := PackedFloat32Array()          # radio por índice

func _init(p_cell: float = 2.0) -> void:
	cell = p_cell

func clear() -> void:
	_cells.clear()
	_pos.clear()
	_rad.clear()

func size() -> int:
	return _pos.size()

## Añade una entrada y devuelve su índice.
func insert(pos: Vector2, radius: float) -> int:
	var id := _pos.size()
	_pos.append(pos)
	_rad.append(radius)
	var c0 := _key(pos - Vector2(radius, radius))
	var c1 := _key(pos + Vector2(radius, radius))
	for x in range(c0.x, c1.x + 1):
		for y in range(c0.y, c1.y + 1):
			var k := Vector2i(x, y)
			# Los Packed*Array se copian al sacarlos del diccionario: hay que volver a guardarlo
			var list: PackedInt32Array = _cells.get(k, PackedInt32Array())
			list.append(id)
			_cells[k] = list
	return id

func position_of(id: int) -> Vector2:
	return _pos[id]

func radius_of(id: int) -> float:
	return _rad[id]

## Índices cuyos círculos tocan el círculo (pos, r), sin repetidos.
func query_circle(pos: Vector2, r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var seen := {}
	var c0 := _key(pos - Vector2(r, r))
	var c1 := _key(pos + Vector2(r, r))
	for x in range(c0.x, c1.x + 1):
		for y in range(c0.y, c1.y + 1):
			var list: PackedInt32Array = _cells.get(Vector2i(x, y), PackedInt32Array())
			for id in list:
				if seen.has(id): continue
				seen[id] = true
				var rr := r + _rad[id]
				if _pos[id].distance_squared_to(pos) <= rr * rr: out.append(id)
	return out

## Índice más cercano a pos dentro de max_r (o -1). Busca por anillos de celdas.
func nearest(pos: Vector2, max_r: float) -> int:
	var best := -1
	var best_d := max_r * max_r
	var ring := 0
	var max_ring := int(ceil(max_r / cell)) + 1
	var c := _key(pos)
	while ring <= max_ring:
		for x in range(c.x - ring, c.x + ring + 1):
			for y in range(c.y - ring, c.y + ring + 1):
				if abs(x - c.x) != ring and abs(y - c.y) != ring: continue   # solo el borde del anillo
				for id: int in _cells.get(Vector2i(x, y), PackedInt32Array()):
					var d := _pos[id].distance_squared_to(pos)
					if d < best_d:
						best_d = d
						best = id
		# si ya hay candidato y el anillo siguiente está más lejos que él, se puede parar
		if best >= 0 and float(ring) * cell > sqrt(best_d): break
		ring += 1
	return best

## Centro de la zona más poblada: la entrada, a menos de max_r de pos, que tiene más
## vecinos en un radio r (para la dinamita). Devuelve -1 si no hay ninguna.
func densest(pos: Vector2, max_r: float, r: float) -> int:
	var best := -1
	var best_n := 0
	for id in query_circle(pos, max_r):
		var n := query_circle(_pos[id], r).size()
		if n > best_n:
			best_n = n
			best = id
	return best

func _key(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / cell)), int(floor(p.y / cell)))
