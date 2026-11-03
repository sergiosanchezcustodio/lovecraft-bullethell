class_name Madness
extends RefCounted
## Grados de locura (hito 16.14, D-49): al vencer a Cthulhu, la campaña se repite en grado 1 a 5
## (`data/madness.json`). Cada grado suma lo suyo a los anteriores: multiplicadores en las mismas
## palancas que los pactos (`Pacts.value` los incluye: velocidad, vida, balas, élites, dólares) y
## dos variantes de las criaturas corrientes: escudo de icor (`ward`, para el primer golpe,
## `Enemy.set_ward`) y partirse en dos al morir (`split`, `WaveDirector`). El grado se elige en el
## mapa (`GameSession.madness`; en red, el del anfitrión) y solo vale en los niveles de la campaña
## (`enabled`, lo pone la partida). El grado N+1 se abre al vencer a Cthulhu en el N; el mejor de
## cada nivel va en `SaveData.records["madness"]`. `madness=N` lo fija para una ejecución.

const DATA := "res://data/madness.json"
const MAX := 5

static var enabled := false                  ## la partida: ¿es un nivel de la campaña?
static var _data := {}
static var _cache := {}

static func _load() -> void:
	if not _data.is_empty(): return
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	_data = d if d is Dictionary else {"grades": []}

static func grades() -> Array:
	_load()
	return _data.get("grades", [])

static func info(g: int) -> Dictionary:
	for x: Dictionary in grades():
		if int(x.grade) == g: return x
	return {}

## Grado en juego (0: ninguno).
static func grade() -> int:
	return clampi(GameSession.madness, 0, MAX) if enabled else 0

static func set_grade(g: int) -> void:
	GameSession.madness = clampi(g, 0, MAX)
	_cache.clear()

## Producto de un multiplicador de los grados hasta `g` (por defecto, el que se juega).
static func value(key: String, g := -1) -> float:
	if g < 0: g = grade()
	if g <= 0: return 1.0
	var ck := "%s/%d" % [key, g]
	if _cache.has(ck): return _cache[ck]
	var v := 1.0
	for x: Dictionary in grades():
		if int(x.grade) <= g: v *= float((x.get("effects", {}) as Dictionary).get(key, 1.0))
	_cache[ck] = v
	return v

## Probabilidad de una variante hasta el grado `g`: la del grado más alto que la nombra.
static func chance(key: String, g := -1) -> float:
	if g < 0: g = grade()
	var c := 0.0
	for x: Dictionary in grades():
		var ch: Dictionary = x.get("chances", {})
		if int(x.grade) <= g and ch.has(key): c = float(ch[key])
	return c

## Lo que cambia cada grado, sumado hasta `g` (para el mapa y la pantalla final).
static func describe(g: int) -> String:
	var lines := PackedStringArray()
	for x: Dictionary in grades():
		if int(x.grade) <= g: lines.append(String(x.text))
	if g > 0: lines.append("Dólares ×%s." % str(snappedf(value("money", g), 0.1)).replace(".", ","))
	return " ".join(lines)

static func title(g: int) -> String:
	if g <= 0: return "Sin locura"
	var x := info(g)
	return "Grado %s · %s" % [x.get("roman", str(g)), x.get("name", "")]

## El grado más alto que se puede elegir con esta partida: 0 hasta vencer a Cthulhu; después, uno
## más que el mejor con el que se ha vencido a Cthulhu.
static func unlocked(save: SaveData) -> int:
	if save == null: return 0
	if save.unlock_all: return MAX
	_load()
	var last := String(_data.get("unlock", "p3_n5"))
	if not save.levels_won.has(last): return 0
	return mini(best(save, last) + 1, MAX)

static func best(save: SaveData, level_id: String) -> int:
	if save == null: return 0
	return int((save.records.get("madness", {}) as Dictionary).get(level_id, 0))

## Nivel superado en el grado `g`: se apunta si es el mejor.
static func record_win(save: SaveData, level_id: String, g: int) -> void:
	if save == null or g <= 0: return
	var m: Dictionary = save.records.get("madness", {})
	if int(m.get(level_id, 0)) < g: m[level_id] = g
	save.records["madness"] = m
