class_name ModelPool
extends RefCounted
## Reserva de modelos de enemigos (hito 16.1). Montar un modelo (un nodo por pivote y una malla
## por parte: unos 15 nodos) costaba ~0,3 ms en el fotograma en que aparecía el enemigo, y con
## varios a la vez era un pico. Aquí se montan de antemano, como mucho `PER_FRAME` por fotograma
## y dentro de `BUDGET_USEC`, y el enemigo que aparece se lleva uno hecho (`take`). Los modelos
## no se devuelven: el que muere se deshace (`Crumble`) o se borra como siempre.
## `model_pool=false` la quita (para comparar).

const SPARE := 3                           ## modelos de reserva por tipo
const PER_FRAME := 1
const BUDGET_USEC := 400

static var enabled := true
static var _spare := {}                    ## ruta -> Array de modelos fuera del árbol
static var _want := {}                     ## ruta -> cuántos de reserva
static var hits := 0                       ## modelos servidos de la reserva (tests y registro)
static var misses := 0

## Que haya `n` modelos de reserva de esta ruta.
static func stock(path: String, n := SPARE) -> void:
	if not enabled: return
	_want[path] = maxi(int(_want.get(path, 0)), n)

## Un modelo listo: de la reserva si hay, si no se monta ahora.
static func take(path: String) -> Node3D:
	var list: Array = _spare.get(path, [])
	while not list.is_empty():
		var m: Node3D = list.pop_back()
		if is_instance_valid(m):
			hits += 1
			return m
	misses += 1
	return VoxelBuilder.load_model(path)

## Cada fotograma: repone la reserva poco a poco.
static func refill() -> void:
	if not enabled or _want.is_empty(): return
	var t0 := Time.get_ticks_usec()
	var made := 0
	for path: String in _want:
		var list: Array = _spare.get(path, [])
		if list.size() >= int(_want[path]): continue
		list.append(VoxelBuilder.load_model(path))
		_spare[path] = list
		made += 1
		if made >= PER_FRAME or Time.get_ticks_usec() - t0 > BUDGET_USEC: return

## Monta ya toda la reserva (mientras la partida sale de negro).
static func fill_now() -> void:
	for path: String in _want:
		var list: Array = _spare.get(path, [])
		while list.size() < int(_want[path]): list.append(VoxelBuilder.load_model(path))
		_spare[path] = list

## Al salir del nivel: los modelos de reserva no están en el árbol y hay que borrarlos a mano.
static func clear() -> void:
	for path: String in _spare:
		for m in _spare[path]:
			if is_instance_valid(m): (m as Node).free()
	_spare.clear()
	_want.clear()

static func spare_count() -> int:
	var n := 0
	for path: String in _spare: n += (_spare[path] as Array).size()
	return n
