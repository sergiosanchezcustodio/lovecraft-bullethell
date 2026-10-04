class_name Campaign
extends RefCounted
## Mapa de niveles (data/campaign.json): 3 partes × 5 niveles. Un nivel está abierto si es
## el primero o si se ha superado el anterior (en orden, pasando de una parte a la
## siguiente), y se puede jugar si además existen sus datos en data/levels/.

const PATH := "res://data/campaign.json"

static var _parts: Array = []

static func parts() -> Array:
	if _parts.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_parts = (d as Dictionary).get("parts", []) if d is Dictionary else []
	return _parts

## Todos los niveles en orden, como diccionarios {id, name, creatures, part, number}.
static func levels() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pi := 0
	for p: Dictionary in parts():
		var n := 1
		for l: Dictionary in p.levels:
			var e := l.duplicate()
			e["part"] = pi
			e["number"] = n
			out.append(e)
			n += 1
		pi += 1
	return out

static func is_unlocked(id: String, won: Array) -> bool:
	var all := levels()
	for i in all.size():
		if all[i].id == id: return i == 0 or won.has(all[i - 1].id)
	return false

static func exists(id: String) -> bool:
	return ResourceLoader.exists("res://data/levels/%s.tres" % id)

## Siguiente nivel de la misma parte que ya existe ("" si es el último o no hay datos).
static func next_in_part(id: String) -> String:
	var all := levels()
	for i in all.size() - 1:
		if all[i].id == id and all[i + 1].part == all[i].part:
			return String(all[i + 1].id) if exists(String(all[i + 1].id)) else ""
	return ""

## Número de nivel dentro de su parte (1..5).
static func number_of(id: String) -> int:
	for l in levels():
		if l.id == id: return int(l.number)
	return 1

## Primer nivel de una parte (0..2).
static func first_of(part: int) -> String:
	for l in levels():
		if l.part == part: return String(l.id)
	return ""

## Una parte se abre al superar el último nivel de la anterior (la primera, siempre).
static func part_unlocked(part: int, won: Array) -> bool:
	if part == 0: return true
	var last := ""
	for l in levels():
		if l.part == part - 1: last = String(l.id)
	return won.has(last)

static func is_playable(id: String, won: Array) -> bool:
	return is_unlocked(id, won) and exists(id)
