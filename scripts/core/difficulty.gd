class_name Difficulty
extends RefCounted
## Dificultad del 1 al 10 por características (29-10-2026, D-42, temporal: para que el autor
## calibre el juego desde la pausa). El 3 de cada característica es la dificultad "Normal" de
## antes (10-10 a 29-10-2026); el 1 es casi "Investigador" (la de antes de esa fecha) y el 5,
## "Pesadilla". Cada una se mueve sola (`set_cat`) o todas a la vez (`set_all`); se guarda en
## Settings ("dif_levels") y vale para los tres huecos. En red, la del anfitrión (`net`).
## Se lee en vivo: cambiarla en la pausa se nota al seguir (la vida, en los que salgan después).
##
## Historia: "Normal" se endureció el 12-10-2026 ("muy muy fácil") y se rebajó el 15-10-2026 con
## simulaciones (tools/simular.py): con ritmo ×8,5 el bot no pasaba el nivel 1 con ningún
## personaje de inicio. Pruebas: cfg_difficulty=N (todas a N), dif_<característica>=N (una, p. ej.
## dif_vida=6) y dif_<valor>=x (un multiplicador suelto, p. ej. dif_rate=4).

const LEVELS := 10
const BASE := 3                          ## la de siempre ("Normal")
const NEUTRAL := 0                       ## `forced = 0`: todos los multiplicadores a 1 (tests)

## Características, en el orden del menú: nombre, qué cambia y sus valores del 1 al 10.
const CATS := {
	"numero": {"name": "Número de enemigos", "help": "Ritmo de aparición y enemigos vivos a la vez",
		"rate": [1.0, 1.8, 2.6, 3.3, 4.0, 4.8, 5.6, 6.5, 7.5, 8.5],
		"cap": [1.0, 1.25, 1.5, 1.65, 1.8, 1.95, 2.1, 2.3, 2.5, 2.7],
		"ramp": [1.0, 0.7, 0.4, 0.45, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]},       ## del ritmo al empezar (ver ramp)
	"vida": {"name": "Vida de los enemigos", "help": "Hordas y élites (los jefes, aparte)",
		"health": [0.8, 0.9, 1.0, 1.1, 1.2, 1.35, 1.5, 1.7, 1.95, 2.25]},
	"jefes": {"name": "Vida de los jefes", "help": "Jefes del final y minijefes",
		"boss": [0.7, 0.85, 1.0, 1.1, 1.2, 1.35, 1.5, 1.7, 1.95, 2.25]},
	"dano": {"name": "Daño de los enemigos", "help": "La vida que quitan",
		"damage": [1.0, 1.2, 1.4, 1.6, 1.8, 2.05, 2.3, 2.6, 2.95, 3.3]},
	"cordura": {"name": "Daño a la cordura", "help": "Ataques mentales y la cordura que roban de cerca",
		"mental": [1.0, 1.35, 1.7, 1.95, 2.2, 2.5, 2.8, 3.1, 3.5, 3.9],
		"horror": [0.4, 0.7, 1.0, 1.25, 1.5, 1.75, 2.0, 2.3, 2.6, 3.0]},
	"velocidad": {"name": "Velocidad de los enemigos", "help": "Los de cuerpo a cuerpo y, desde el 4, los que disparan",
		"melee": [1.0, 1.09, 1.18, 1.25, 1.32, 1.39, 1.46, 1.53, 1.6, 1.68],
		"shooter": [1.0, 1.0, 1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.2]},
	"balas": {"name": "Balas enemigas", "help": "Velocidad de sus balas",
		"bullet": [0.85, 0.92, 1.0, 1.06, 1.12, 1.18, 1.25, 1.32, 1.4, 1.5]},
	"agresividad": {"name": "Agresividad", "help": "Cada cuánto disparan y cuánto avisan en el suelo",
		"attack": [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.75],
		"warn": [1.2, 1.1, 1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65]},
	"elites": {"name": "Élites", "help": "Cuántas puede haber a la vez",
		"elites": [0.5, 0.75, 1.0, 1.0, 1.5, 1.5, 2.0, 2.0, 2.5, 3.0]},
}

static var forced := -1:                ## los tests la fijan: 0 neutra, 1..10 todas a ese nivel
	set(v):
		forced = v
		_cache.clear()
static var net = null:                  ## en red, invitado: los niveles del anfitrión (la pone NetGame; la partida la borra)
	set(v):
		net = v
		_cache.clear()
static var _cache := {}                 ## valor -> multiplicador (se borra al cambiar algo: `refresh`)

## Nivel de cada característica (1..10), de la configuración, la red o los tests.
static func levels() -> Dictionary:
	var out := {}
	var saved = {}
	if net is Dictionary: saved = net
	elif forced < 0 and Engine.get_main_loop() != null and (Engine.get_main_loop() as SceneTree).root.has_node("Settings"):
		saved = Auto.setting("dif_levels", {})
		var all = Auto.setting("difficulty", 0)                  # cfg_difficulty=N: todas a N (simulaciones)
		if all != null and int(all) > 0:
			saved = {}
			for c in CATS: saved[c] = int(all)
	for c in CATS:
		var v := BASE
		if forced > 0: v = forced
		elif saved is Dictionary and saved.has(c): v = int(saved[c])
		out[c] = clampi(_arg_level(c, v), 1, LEVELS)
	return out

## La dificultad general: el nivel si todas coinciden; -1 si es personalizada.
static func general() -> int:
	var lv := levels()
	var first := int(lv.values()[0])
	for c in lv:
		if int(lv[c]) != first: return -1
	return first

static func set_cat(cat: String, lv: int) -> void:
	var got = Auto.setting("dif_levels", {})
	var cur: Dictionary = (got as Dictionary).duplicate() if got is Dictionary else {}
	for c in CATS: if not cur.has(c): cur[c] = BASE
	cur[cat] = clampi(lv, 1, LEVELS)
	_save(cur)

## Todas a la vez (el historial de la pausa, hito 13.2): las que falten, al 3.
static func set_levels(d: Dictionary) -> void:
	var cur := {}
	for c in CATS: cur[c] = clampi(int(d.get(c, BASE)), 1, LEVELS)
	_save(cur)

static func set_all(lv: int) -> void:
	var cur := {}
	for c in CATS: cur[c] = clampi(lv, 1, LEVELS)
	_save(cur)

static func _save(d: Dictionary) -> void:
	var s := Auto.node("Settings")
	if s != null: s.set_value("dif_levels", d)
	refresh()

## Invitado: los niveles del anfitrión (al empezar y al seguir tras cada pausa).
static func set_net(d: Dictionary) -> void:
	var out := {}
	for c in CATS: out[c] = clampi(int(d.get(c, BASE)), 1, LEVELS)
	net = out
	refresh()

static func refresh() -> void:
	_cache.clear()

## Multiplicador `key` de la característica `cat` a su nivel actual (cacheado: se lee por enemigo).
static func value(cat: String, key: String) -> float:
	var ck := cat + "/" + key
	if _cache.has(ck): return _cache[ck]
	var v := 1.0
	if forced != NEUTRAL:
		v = float((CATS[cat][key] as Array)[int(levels()[cat]) - 1])
	v = _o(key, v)
	_cache[ck] = v
	return v

static func rate(t := INF) -> float: return value("numero", "rate") * ramp(t)
static func cap(t := INF) -> float: return value("numero", "cap") * lerpf(ramp(t), 1.0, 0.5)

## Rampa al empezar cada nivel (15-10-2026, simulaciones con tools/simular.py): el ritmo empieza en
## "ramp" de su valor y llega al completo a los RAMP_TIME s. Sin ella, en Normal salían 2,5
## enemigos por segundo desde el segundo 0 y el bot caía a los 30-60 s con un arma a nivel 1.
const RAMP_TIME := 120.0
## Solo al empezar desde cero (game._apply_carry): llegando con el progreso del nivel anterior, la
## rampa hacía fáciles los niveles 2 a 5 (el bot que pasaba el 1 pasaba la parte entera).
static var ramp_on := true
static func ramp(t: float) -> float:
	if not ramp_on: return 1.0
	return lerpf(value("numero", "ramp"), 1.0, clampf(t / RAMP_TIME, 0.0, 1.0))
static func health() -> float: return value("vida", "health")
static func boss_health() -> float: return value("jefes", "boss")
static func damage() -> float: return value("dano", "damage")
static func mental() -> float: return value("cordura", "mental")
static func horror() -> float: return value("cordura", "horror")
static func melee_speed() -> float: return value("velocidad", "melee")
static func shooter_speed() -> float: return value("velocidad", "shooter")
static func bullet_speed() -> float: return value("balas", "bullet")
static func attack() -> float: return value("agresividad", "attack")
static func warn() -> float: return value("agresividad", "warn")
## Élites a la vez para un nivel que permite `base` (al menos una si el nivel tiene).
static func elites(base: int) -> int:
	if base <= 0: return base
	return maxi(1, int(round(base * value("elites", "elites"))))

## Pruebas: dif_rate=4 cambia un valor suelto; dif_vida=6, el nivel de una característica.
static var _over = null
static func _args() -> Dictionary:
	if _over == null:
		_over = {}
		for a in OS.get_cmdline_user_args():
			if a.begins_with("dif_") and "=" in a: _over[a.substr(4, a.find("=") - 4)] = float(a.substr(a.find("=") + 1))
	return _over
static func _o(key: String, v: float) -> float:
	return float(_args().get(key, v))
static func _arg_level(cat: String, v: int) -> int:
	return int(_args().get(cat, v))

## Para el registro: "numero 3, vida 4, …" (de la actual o de `lv`).
static func describe(lv: Dictionary = {}) -> String:
	if lv.is_empty(): lv = levels()
	var parts: Array[String] = []
	for c in CATS: parts.append("%s %d" % [c, int(lv.get(c, BASE))])
	return ", ".join(parts)
