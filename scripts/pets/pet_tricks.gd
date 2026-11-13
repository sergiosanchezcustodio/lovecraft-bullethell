class_name PetTricks
extends RefCounted
## Trucos de los compañeros (hito 21.5): al llegar su jugador al nivel `level()`, cada compañero
## elige entre dos trucos (data/pet_tricks.json), con dos cartas en la ventana de la subida como las
## ramas de las armas (PlayerProgress.Option.Kind.TRICK). Unos cambian sus datos (`mods`) y otros
## añaden un efecto que lleva Pet (`efecto`: al golpear, `Pet.on_hit`, o cada poco, `Pet._trick_step`).

const PATH := "res://data/pet_tricks.json"
const EFFECTS := ["", "twin", "sleep", "howl", "sanity", "regen", "gold", "vulnerable", "slow", "heal"]

static var _data := {}

static func data() -> Dictionary:
	if _data.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = d if d is Dictionary else {"trucos": {}}
	return _data

## Nivel del jugador al que su compañero aprende el truco.
static func level() -> int:
	return int(data().get("nivel", 5))

## Los dos trucos de un compañero (por su id).
static func for_pet(pet_id: String) -> Array:
	return (data().get("trucos", {}) as Dictionary).get(pet_id, [])

static func find(pet_id: String, id: String) -> Dictionary:
	for t: Dictionary in for_pet(pet_id):
		if String(t.id) == id: return t
	return {}

## Aplica los `mods` de un truco a unos datos (una copia): "campo*" multiplica y "campo+" suma.
static func apply_mods(d: PetData, mods: Dictionary) -> void:
	for k: String in mods:
		var f := k.trim_suffix("*").trim_suffix("+")
		if not f in d: continue
		if k.ends_with("+"): d.set(f, float(d.get(f)) + float(mods[k]))
		else: d.set(f, float(d.get(f)) * float(mods[k]))
