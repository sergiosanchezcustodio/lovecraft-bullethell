class_name SaveData
extends RefCounted
## Una partida guardada (un hueco). Se guarda como JSON con número de versión: al leer una
## versión anterior se migra (`from_dict`), así que el formato puede crecer sin romper las
## partidas existentes y se podrá subir a la nube tal cual (fase 10).

const VERSION := 1

var created := ""                        ## fecha de creación (ISO)
var updated := ""                        ## última vez que se guardó
var play_time := 0.0                     ## s jugados en total (solo en partida)
var money := 0                           ## dinero de la tienda: sobrevive a la muerte
var purchases := {}                      ## id de artículo -> nivel comprado
var pets := []                           ## compañeros desbloqueados (ids)
var characters := []                     ## personajes desbloqueados además de los iniciales (ids)
var levels_won := []                     ## niveles superados (ids, p. ej. "p1_n1")
var stats := {"runs": 0, "kills": 0, "deaths": 0, "revives": 0}
var achievements := {}                   ## logros cumplidos: id -> fecha (D-32)
## Biblioteca: lo visto o tenido alguna vez (enemies, weapons, items, places) -> lista de ids.
var seen := {"enemies": [], "weapons": [], "items": [], "places": []}
## Partida de pruebas: todo lo que existe y lo que se añada (personajes, compañeros, niveles,
## artículos de la tienda) está disponible, sin tener que comprarlo ni ganarlo.
var unlock_all := false

static func create() -> SaveData:
	var d := SaveData.new()
	d.created = Time.get_datetime_string_from_system()
	d.updated = d.created
	return d

## Partida de pruebas con todo desbloqueado y dinero de sobra.
static func create_test() -> SaveData:
	var d := create()
	d.unlock_all = true
	d.money = 999999
	for r in DebugOptions.list_resources("res://data/characters"): d.characters.append(String((r as CharacterData).id))
	for r in DebugOptions.list_resources("res://data/pets"): d.pets.append(String((r as PetData).id))
	return d

func has_character(id: String) -> bool:
	return unlock_all or characters.has(id)

func has_pet(id: String) -> bool:
	return unlock_all or pets.has(id)

func has_seen(kind: String, id: String) -> bool:
	return (seen.get(kind, []) as Array).has(id)

## Apunta algo visto para la Biblioteca; true si es nuevo.
func mark_seen(kind: String, id: String) -> bool:
	if not seen.has(kind): seen[kind] = []
	var a: Array = seen[kind]
	if a.has(id): return false
	a.append(id)
	return true

func has_level(id: String) -> bool:
	return unlock_all or Campaign.is_unlocked(id, levels_won)

## Objetos comprados en la tienda (cada nivel de un potenciador cuenta como uno).
func items_bought() -> int:
	var n := 0
	for k in purchases: n += int(purchases[k])
	return n

func to_dict() -> Dictionary:
	return {"version": VERSION, "created": created, "updated": updated, "play_time": play_time,
		"money": money, "purchases": purchases, "pets": pets, "characters": characters,
		"levels_won": levels_won, "stats": stats, "unlock_all": unlock_all, "achievements": achievements,
		"seen": seen}

## Lee un diccionario de cualquier versión conocida; los campos que falten toman su valor
## por defecto.
static func from_dict(d: Dictionary) -> SaveData:
	var s := SaveData.new()
	d = migrate(d)
	s.created = str(d.get("created", ""))
	s.updated = str(d.get("updated", s.created))
	s.play_time = float(d.get("play_time", 0.0))
	s.money = int(d.get("money", 0))
	s.purchases = d.get("purchases", {})
	s.pets = d.get("pets", [])
	s.characters = d.get("characters", [])
	s.levels_won = d.get("levels_won", [])
	s.unlock_all = bool(d.get("unlock_all", false))
	var st: Dictionary = d.get("stats", {})
	for k in s.stats: s.stats[k] = int(st.get(k, 0))
	for k in st:
		if not s.stats.has(k): s.stats[k] = st[k]
	s.achievements = (d.get("achievements", {}) as Dictionary).duplicate()
	var sn: Dictionary = d.get("seen", {})
	for k in sn: s.seen[k] = (sn[k] as Array).duplicate()
	# JSON guarda los enteros como float: los niveles comprados se vuelven a enteros
	for k in s.purchases: s.purchases[k] = int(s.purchases[k])
	return s

## Migraciones entre versiones del formato. Cada cambio de formato sube VERSION y añade
## aquí su paso (versión N -> N+1).
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 0))
	if v < 1:
		# versión 0 (sin número): solo se llamaba "time" al tiempo jugado
		if d.has("time") and not d.has("play_time"): d["play_time"] = d["time"]
		v = 1
	d["version"] = v
	return d

## Tiempo jugado como texto: "3 h 05 min", "12 min" o "menos de 1 min".
static func format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	if m < 1: return "menos de 1 min"
	if m < 60: return "%d min" % m
	return "%d h %02d min" % [m / 60, m % 60]
