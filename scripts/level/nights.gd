class_name Nights
extends RefCounted
## Noches sueltas (fase 21, bloque D): niveles aparte de la campaña (`data/nights.json`), cada uno
## con su escenario, dos criaturas, un jefe y su relato. Se eligen desde el mapa de niveles
## (`NightsMenu`) y se abren al superar un nivel de la campaña (`abre`). El nivel es un
## `data/levels/<id>.tres` corriente: se empieza de cero, como el primer nivel de una parte, y al
## superarlo no hay siguiente. Las superadas van en `SaveData.records["nights"]` ({id: veces}).

const PATH := "res://data/nights.json"
const KEY := "nights"

static var _data := {}

static func all() -> Array:
	if _data.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = d if d is Dictionary else {"noches": []}
	return _data.get("noches", [])

static func find(id: String) -> Dictionary:
	for n: Dictionary in all():
		if String(n.id) == id: return n
	return {}

static func is_night(id: String) -> bool:
	return not find(id).is_empty()

## «Noche suelta · El color que cayó del cielo» (para el HUD, la tarjeta y la red).
static func label(id: String) -> String:
	return "Noche suelta · " + String(find(id).get("titulo", ""))

## ¿Abierta? Al superar su nivel de la campaña (o con todo desbloqueado).
static func unlocked(save: SaveData, id: String) -> bool:
	var n := find(id)
	if n.is_empty() or save == null: return false
	return save.unlock_all or String(n.get("abre", "")) == "" or save.levels_won.has(String(n.abre))

static func any_unlocked(save: SaveData) -> bool:
	return all().any(func(n: Dictionary) -> bool: return unlocked(save, String(n.id)))

## Veces que se ha superado (0: ninguna).
static func wins(save: SaveData, id: String) -> int:
	if save == null: return 0
	return int((save.records.get(KEY, {}) as Dictionary).get(id, 0))

static func won_count(save: SaveData) -> int:
	if save == null: return 0
	return (save.records.get(KEY, {}) as Dictionary).size()

static func record_win(save: SaveData, id: String) -> void:
	if save == null or not is_night(id): return
	var r: Dictionary = save.records.get(KEY, {})
	r[id] = int(r.get(id, 0)) + 1
	save.records[KEY] = r
