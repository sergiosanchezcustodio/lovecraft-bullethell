class_name Secrets
extends RefCounted
## Investigadores secretos (hito 16.25): no se compran, se abren con una condición
## (`CharacterData.secret`). Al cumplirla pasan a la partida como uno comprado
## (`SaveData.characters`); lo mira la pantalla final de cada nivel (`Game._end_screen`) y la
## selección de personaje al abrirse.
##   fragmentos  Randolph Carter: todas las páginas sueltas de los relatos (Fragments)
##   desafios    Wilbur Whateley: los quince desafíos superados (Challenge)

const HINTS := {"fragmentos": "Reúne las páginas sueltas", "desafios": "Supera los desafíos"}

static func all() -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	for r in DebugOptions.list_resources("res://data/characters"):
		var c := r as CharacterData
		if c != null and c.secret != "": out.append(c)
	out.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.order < b.order)
	return out

## Cuánto lleva y cuánto hace falta.
static func progress(save: SaveData, c: CharacterData) -> Vector2i:
	match c.secret:
		"fragmentos": return Vector2i(Fragments.found(save).size(), Fragments.total())
		"desafios": return Vector2i(Challenge.won_count(save) if save != null else 0, Challenge.all().size())
	return Vector2i(0, 1)

static func met(save: SaveData, c: CharacterData) -> bool:
	var p := progress(save, c)
	return p.y > 0 and p.x >= p.y

## Lo que dice la selección mientras está cerrado.
static func hint(save: SaveData, c: CharacterData) -> String:
	var p := progress(save, c)
	return "%s (%d de %d)" % [String(HINTS.get(c.secret, "Secreto")), p.x, p.y]

## Armas de los secretos aún cerrados: no salen en la subida de nivel hasta abrir a su dueño
## (que no se descubra antes de tiempo). Sin partida (pruebas), ninguna.
static func locked_weapons(save: SaveData) -> Array[StringName]:
	var out: Array[StringName] = []
	if save == null: return out
	for c in all():
		if not save.has_character(String(c.id)): out.append_array(c.starting_weapons)
	return out

## Abre los que ya cumplen su condición; devuelve los recién abiertos.
static func check(save: SaveData) -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	if save == null: return out
	for c in all():
		if not save.characters.has(String(c.id)) and met(save, c):
			save.characters.append(String(c.id))
			out.append(c)
	return out
