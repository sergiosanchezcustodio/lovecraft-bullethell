class_name Pacts
extends RefCounted
## Pactos del Necronomicón (hito 13.6, fase 13; D-44): antes de cada nivel se pueden sellar
## hasta tres, cada uno con su maldición y su premio (más experiencia, más dólares o mejores
## baúles). Duran hasta que se cambien (en el mapa, al elegir parte, y en la pantalla del nivel
## superado, antes del siguiente). Los sellados van en `GameSession.pacts`; en cooperativo los
## elige el J1 y en red el anfitrión (llegan a los invitados con GO, `NetGame`). Sus efectos
## se leen en vivo con `value` y `has`, en las mismas palancas que la dificultad. Los superados
## se apuntan en el hueco (`SaveData.seen["pacts"]`: "nivel:pacto") y cuentan para los logros
## (`stats.pact_levels` y `pact3_levels`). Datos en `data/pacts.json`; `pacts=noche,furia`
## los sella para esta ejecución.

const DATA := "res://data/pacts.json"

static var _data := {}
static var _cache := {}                     ## efectos de los sellados (se leen cada paso)

static func _load() -> void:
	if not _data.is_empty(): return
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	_data = d if d is Dictionary else {"max": 3, "pacts": []}

static func all() -> Array:
	_load()
	return _data.get("pacts", [])

static func max_count() -> int:
	_load()
	return int(_data.get("max", 3))

static func find(id: String) -> Dictionary:
	for p: Dictionary in all():
		if String(p.id) == id: return p
	return {}

## Los sellados (válidos, sin repetir y como mucho `max_count`).
static func clean(ids: Array) -> Array:
	var out: Array = []
	for id: Variant in ids:
		var s := String(id)
		if s != "" and not out.has(s) and not find(s).is_empty() and out.size() < max_count(): out.append(s)
	return out

static func active() -> Array:
	return GameSession.pacts

static func set_active(ids: Array) -> void:
	GameSession.pacts = clean(ids)
	_cache.clear()

## Los efectos sumados de los sellados (caché; se rehace si cambian).
static func _effects() -> Dictionary:
	if _cache.get("ids") != GameSession.pacts:
		var fx := {}
		for id: Variant in GameSession.pacts:
			var e: Dictionary = find(String(id)).get("effects", {})
			for k: String in e: fx[k] = float(fx.get(k, 1.0)) * float(e[k])
		_cache = {"ids": GameSession.pacts.duplicate(), "fx": fx}
	return _cache.fx

## Producto de un multiplicador entre los sellados (1 si ninguno lo toca).
static func value(key: String, ids: Variant = null) -> float:
	if ids == null: return float(_effects().get(key, 1.0))
	var v := 1.0
	for id: Variant in (ids if ids is Array else active()):
		var fx: Dictionary = find(String(id)).get("effects", {})
		if fx.has(key): v *= float(fx[key])
	return v

## ¿Algún sellado lleva esa marca?
static func has(key: String, ids: Variant = null) -> bool:
	if ids == null: return _effects().has(key)
	for id: Variant in (ids if ids is Array else active()):
		if (find(String(id)).get("effects", {}) as Dictionary).has(key): return true
	return false

static func names(ids: Array) -> String:
	var out := PackedStringArray()
	for id: Variant in ids:
		var p := find(String(id))
		if not p.is_empty(): out.append(String(p.name))
	return ", ".join(out)

## Nivel superado con pactos: los apunta en el hueco y cuenta para los logros.
static func record_win(save: SaveData, level_id: String, ids: Array) -> void:
	if save == null or ids.is_empty(): return
	for id: Variant in ids: save.mark_seen("pacts", "%s:%s" % [level_id, id])
	save.stats["pact_levels"] = int(save.stats.get("pact_levels", 0)) + 1
	if ids.size() >= 3: save.stats["pact3_levels"] = int(save.stats.get("pact3_levels", 0)) + 1

## Pactos distintos con los que se ha superado un nivel (sellos en el mapa).
static func won_on(save: SaveData, level_id: String) -> Array:
	var out: Array = []
	if save == null: return out
	for s: Variant in save.seen.get("pacts", []):
		var parts := String(s).split(":")
		if parts.size() == 2 and parts[0] == level_id: out.append(parts[1])
	return out
