class_name Signs
extends RefCounted
## Signos Mayores (hito 16.9): lo contrario de los pactos (que castigan): cada uno cambia una
## regla a favor de quien lo lleva (las explosiones dejan fuego, las gemas devuelven cordura…).
## Cada jugador elige uno al empezar una parte y otro al empezar su tercer nivel (`per_part`),
## entre tres de los que tenga abiertos, en la ventana de la subida (como la rama de una
## evolución: `PlayerProgress.signs_pending`). Se abren con logros (`unlock`); con la partida de
## pruebas (`unlock_all`), todos. Los lleva `PlayerProgress.signs` y pasan de nivel con el resto
## del progreso (`GameSession.snapshot`). Datos en `data/signs.json`; `signs=cthugha,yog` los da
## al J1 para esta ejecución.

const DATA := "res://data/signs.json"
const OFFER := 3                               ## cuántos se ofrecen

static var _data := {}

static func _load() -> void:
	if not _data.is_empty(): return
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	_data = d if d is Dictionary else {"signs": [], "per_part": [1, 3]}

static func all() -> Array:
	_load()
	return _data.get("signs", [])

static func find(id: String) -> Dictionary:
	for s: Dictionary in all():
		if String(s.id) == id: return s
	return {}

static func value(id: String) -> float:
	return float(find(id).get("value", 0.0))

## Niveles de la parte (1..5) en que se gana un signo (por defecto, el 1 y el 3).
static func levels() -> Array:
	_load()
	return _data.get("per_part", [1, 3])

## Signos que debería llevar al empezar el nivel `number` de la parte.
static func due(number: int) -> int:
	var n := 0
	for l: Variant in levels():
		if number >= int(l): n += 1
	return n

## Abiertos en esta partida guardada: los de sus logros (todos con `unlock_all`).
static func unlocked(save: SaveData) -> Array[String]:
	var out: Array[String] = []
	if save == null: return out
	for s: Dictionary in all():
		var a := String(s.get("unlock", ""))
		if save.unlock_all or a == "" or save.achievements.has(a): out.append(String(s.id))
	return out

## Hasta OFFER signos al azar de los abiertos que aún no lleva.
static func roll(save: SaveData, owned: Array, rng: RandomNumberGenerator) -> Array[String]:
	var pool := unlocked(save).filter(func(id: String) -> bool: return not owned.has(StringName(id)) and not owned.has(id))
	var out: Array[String] = []
	while out.size() < OFFER and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return out

## Icono de un signo (resources/signs/<id>.png) o null.
static func icon(id: String) -> Texture2D:
	var path := "res://resources/signs/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null

## ¿Lo lleva alguno de estos jugadores? (Efectos de todo el equipo: los baúles de Dagón.)
static func any(players: Array, id: StringName) -> bool:
	for q: Variant in players:
		if q is Player and (q as Player).has_sign(id): return true
	return false
