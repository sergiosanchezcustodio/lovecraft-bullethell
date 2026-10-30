class_name SaveData
extends RefCounted
## Una partida guardada (un hueco). Se guarda como JSON con número de versión: al leer una
## versión anterior se migra (`from_dict`), así que el formato puede crecer sin romper las
## partidas existentes y se podrá subir a la nube tal cual (fase 10).

const VERSION := 2

var created := ""                        ## fecha de creación (ISO)
var updated := ""                        ## última vez que se guardó
## Versión del juego (application/config/version) al crear la partida y al guardarla por última
## vez: si cambia el formato, se sabe de dónde viene. Vacía en las partidas de antes de guardarla.
var created_with := ""
var saved_with := ""
var play_time := 0.0                     ## s jugados en total (solo en partida)
var money := 0                           ## dinero de la tienda: sobrevive a la muerte
var purchases := {}                      ## id de artículo -> nivel comprado
var toggles := {}                        ## id de artículo -> activo (lo que se puede apagar: el Pacto)
var pets := []                           ## compañeros desbloqueados (ids)
var characters := []                     ## personajes desbloqueados además de los iniciales (ids)
var levels_won := []                     ## niveles superados (ids, p. ej. "p1_n1")
var stats := {"runs": 0, "kills": 0, "deaths": 0, "revives": 0}
var achievements := {}                   ## logros cumplidos: id -> fecha (D-32)
var records := {}                        ## récords: {"endless": {"personaje|nivel": s}} (hito 13.8)
## Biblioteca: lo visto o tenido alguna vez (enemies, weapons, items, places) -> lista de ids.
## Vestuario (D-34): prendas compradas (ids) y lo que lleva puesto cada personaje
## (id de personaje -> {"head": id, "body": id, "feet": id}; sin clave, lo suyo).
var outfits := []
var worn := {}
var seen := {"enemies": [], "weapons": [], "items": [], "places": []}
## Partida de pruebas: todo lo que existe y lo que se añada (personajes, compañeros, niveles,
## artículos de la tienda) está disponible, sin tener que comprarlo ni ganarlo.
var unlock_all := false
## Copia en la nube (fase 10, versión 2 del formato): `rev` sube en cada guardado; `cloud_base` es
## la revisión de la nube con la que coincidía la última vez (−1: nunca), y `device`, el PC que la
## guardó. Así se sabe qué lado ha cambiado sin fiarse de la hora de cada PC (`CloudSync.decide`).
var rev := 0
var cloud_base := -1
var device := ""

static func create() -> SaveData:
	var d := SaveData.new()
	d.created = Time.get_datetime_string_from_system()
	d.updated = d.created
	d.created_with = game_version()
	d.saved_with = d.created_with
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

func has_outfit(id: String) -> bool:
	return unlock_all or outfits.has(id)

## Lo que lleva puesto un personaje, solo con prendas que tiene.
func worn_by(character_id: String) -> Dictionary:
	var out := {}
	var w: Dictionary = worn.get(character_id, {})
	for k in w:
		if has_outfit(String(w[k])): out[k] = String(w[k])
	return out

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
	return (unlock_all and Demo.level_ok(id)) or Campaign.is_unlocked(id, levels_won)

## Objetos comprados en la tienda (cada nivel de un potenciador cuenta como uno).
func items_bought() -> int:
	var n := 0
	for k in purchases: n += int(purchases[k])
	return n

func to_dict() -> Dictionary:
	return {"version": VERSION, "created": created, "updated": updated, "play_time": play_time,
		"created_with": created_with, "saved_with": saved_with,
		"money": money, "purchases": purchases, "pets": pets, "characters": characters,
		"levels_won": levels_won, "stats": stats, "unlock_all": unlock_all, "achievements": achievements,
		"seen": seen, "outfits": outfits, "worn": worn, "toggles": toggles, "records": records,
		"rev": rev, "cloud_base": cloud_base, "device": device}

## Lee un diccionario de cualquier versión conocida; los campos que falten toman su valor
## por defecto.
static func from_dict(d: Dictionary) -> SaveData:
	var s := SaveData.new()
	d = migrate(d)
	s.created = str(d.get("created", ""))
	s.updated = str(d.get("updated", s.created))
	s.created_with = str(d.get("created_with", ""))
	s.saved_with = str(d.get("saved_with", ""))
	s.play_time = float(d.get("play_time", 0.0))
	s.money = int(d.get("money", 0))
	s.purchases = d.get("purchases", {})
	s.toggles = (d.get("toggles", {}) as Dictionary).duplicate()
	s.pets = d.get("pets", [])
	s.characters = d.get("characters", [])
	s.levels_won = d.get("levels_won", [])
	s.unlock_all = bool(d.get("unlock_all", false))
	s.rev = int(d.get("rev", 0))
	s.cloud_base = int(d.get("cloud_base", -1))
	s.device = str(d.get("device", ""))
	var st: Dictionary = d.get("stats", {})
	for k in s.stats: s.stats[k] = int(st.get(k, 0))
	for k in st:
		if not s.stats.has(k): s.stats[k] = st[k]
	s.achievements = (d.get("achievements", {}) as Dictionary).duplicate()
	s.records = (d.get("records", {}) as Dictionary).duplicate(true)
	s.outfits = (d.get("outfits", []) as Array).duplicate()
	s.worn = (d.get("worn", {}) as Dictionary).duplicate(true)
	var sn: Dictionary = d.get("seen", {})
	for k in sn: s.seen[k] = (sn[k] as Array).duplicate()
	# JSON guarda los enteros como float: los niveles comprados se vuelven a enteros
	for k in s.purchases: s.purchases[k] = int(s.purchases[k])
	return s

static func game_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))

## Compara versiones "0.9.10" > "0.9.2" por partes numéricas: 1 si a es más nueva, −1 si b, 0 si iguales
## (o alguna vacía: no se sabe).
static func compare_versions(a: String, b: String) -> int:
	if a == "" or b == "": return 0
	var pa := a.split(".")
	var pb := b.split(".")
	for k in maxi(pa.size(), pb.size()):
		var x := int(pa[k]) if k < pa.size() else 0
		var y := int(pb[k]) if k < pb.size() else 0
		if x != y: return 1 if x > y else -1
	return 0

## Se guardó con una versión del juego más nueva que esta (el menú de huecos lo avisa).
func from_newer_game() -> bool:
	return compare_versions(saved_with, game_version()) > 0

## Migraciones entre versiones del formato. Cada cambio de formato sube VERSION y añade
## aquí su paso (versión N -> N+1).
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 0))
	if v < 1:
		# versión 0 (sin número): solo se llamaba "time" al tiempo jugado
		if d.has("time") and not d.has("play_time"): d["play_time"] = d["time"]
		v = 1
	if v < 2:
		# versión 1: sin revisiones para la nube (rev 0, nunca subida)
		v = 2
	d["version"] = v
	return d

## Tiempo jugado como texto: "3 h 05 min", "12 min" o "menos de 1 min".
static func format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	if m < 1: return "menos de 1 min"
	if m < 60: return "%d min" % m
	return "%d h %02d min" % [m / 60, m % 60]
