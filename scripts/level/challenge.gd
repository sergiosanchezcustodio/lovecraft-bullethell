class_name Challenge
extends RefCounted
## Modo desafío (hito 15.2, fase 15): cada nivel tiene un desafío con reglas fijas
## (`data/challenges.json`), que se abre al superar ese nivel y se elige desde el mapa
## (`ChallengeMenu`). El nivel se monta sobre el de la campaña (`make_level`, id «desafio:p1_n3»:
## así viaja igual en red, con START, y se reintenta). Sus efectos usan las palancas de los pactos
## (`Pacts.value`/`has` los multiplican) más las propias (`no_dodge`, `one_weapon`, `arcane_only`,
## `max_health`, `spawn_rate`). Sin pactos. Los superados van en `SaveData.records["challenges"]`.

const PREFIX := "desafio:"
const DATA := "res://data/challenges.json"

static var _data := {}
static var _fx := {}                           ## efectos del desafío en juego (vacío fuera de uno)

static func _load() -> void:
	if not _data.is_empty(): return
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	_data = d if d is Dictionary else {"challenges": []}

static func all() -> Array:
	_load()
	return _data.challenges

static func is_challenge(id: String) -> bool:
	return id.begins_with(PREFIX)

static func base_of(id: String) -> String:
	return id.substr(PREFIX.length()) if is_challenge(id) else id

static func id_for(base: String) -> String:
	return PREFIX + base

## El desafío del nivel `base` (o de un id «desafio:…»); vacío si no tiene.
static func find(id: String) -> Dictionary:
	var base := base_of(id)
	for c: Dictionary in all():
		if String(c.level) == base: return c
	return {}

## ¿Abierto? Al superar su nivel (o con todo desbloqueado).
static func unlocked(save: SaveData, base: String) -> bool:
	return save != null and (save.unlock_all or save.levels_won.has(base))

static func any_unlocked(save: SaveData) -> bool:
	return all().any(func(c: Dictionary) -> bool: return unlocked(save, String(c.level)))

static func won(save: SaveData, base: String) -> bool:
	return save != null and (save.records.get("challenges", {}) as Dictionary).has(base)

## Mejor tiempo en superarlo (s; 0 si no hay: superado antes de guardarse los tiempos, o nunca).
static func best(save: SaveData, base: String) -> float:
	if save == null: return 0.0
	var v: Variant = (save.records.get("challenges", {}) as Dictionary).get(base_of(base), 0.0)
	return float(v) if v is float or v is int else 0.0

static func won_count(save: SaveData) -> int:
	return (save.records.get("challenges", {}) as Dictionary).size() if save != null else 0

## Apunta el desafío superado en `t` s y se queda con el mejor tiempo; true si es récord (o la
## primera vez).
static func record_win(save: SaveData, id: String, t: float) -> bool:
	if save == null: return false
	var base := base_of(id)
	var rec: Dictionary = save.records.get("challenges", {})
	var prev := best(save, base)
	var better := not rec.has(base) or prev <= 0.0 or t < prev
	if better: rec[base] = t
	save.records["challenges"] = rec
	return better

## El nivel del desafío: el de la campaña, con su nombre.
static func make_level(id: String) -> LevelData:
	var src: LevelData = load("res://data/levels/%s.tres" % base_of(id))
	var lv: LevelData = src.duplicate()
	lv.id = StringName(id)
	lv.display_name = "Desafío · %s" % String(find(id).get("name", src.display_name))
	return lv

## Activa los efectos del nivel que empieza (vacío si no es un desafío).
static func begin(level_id: String) -> void:
	_fx = (find(level_id).get("effects", {}) as Dictionary).duplicate() if is_challenge(level_id) else {}

static func active() -> bool:
	return not _fx.is_empty()

static func value(key: String) -> float:
	return float(_fx.get(key, 1.0))

static func has(key: String) -> bool:
	return _fx.has(key)

## ¿Se puede ofrecer (o dar) esta arma nueva con las reglas del desafío?
static func new_weapon_ok(w: WeaponData) -> bool:
	if has("one_weapon"): return false
	return not has("arcane_only") or w.category == WeaponData.Category.MAGIC
