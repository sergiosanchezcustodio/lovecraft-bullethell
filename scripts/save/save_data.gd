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

static func create() -> SaveData:
	var d := SaveData.new()
	d.created = Time.get_datetime_string_from_system()
	d.updated = d.created
	return d

## Objetos comprados en la tienda (cada nivel de un potenciador cuenta como uno).
func items_bought() -> int:
	var n := 0
	for k in purchases: n += int(purchases[k])
	return n

func to_dict() -> Dictionary:
	return {"version": VERSION, "created": created, "updated": updated, "play_time": play_time,
		"money": money, "purchases": purchases, "pets": pets, "characters": characters,
		"levels_won": levels_won, "stats": stats}

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
	var st: Dictionary = d.get("stats", {})
	for k in s.stats: s.stats[k] = int(st.get(k, 0))
	for k in st:
		if not s.stats.has(k): s.stats[k] = st[k]
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
