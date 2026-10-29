class_name Endless
extends Node
## Modo sin fin «La noche eterna» (hito 13.8, fase 13): se abre al vencer a Cthulhu. Se elige
## uno de los 15 escenarios y se aguanta sin final: oleadas con enemigos de las tres partes,
## un jefe cada 5 minutos y una dificultad que sube sola. El nivel se monta a partir del de ese
## escenario (`make_level`, id «sin_fin:p2_n3»: así viaja igual en red, con START, y se
## reintenta); este nodo, en el anfitrión, lo endurece con el tiempo (`step`). Récord de tiempo
## por personaje y escenario en el hueco (`SaveData.records`, `record`). Números en
## `data/endless.json`.

const PREFIX := "sin_fin:"
const DATA := "res://data/endless.json"

var level: LevelData
var _base_health := 1.0
var _base_max := 90

static func is_endless(id: String) -> bool:
	return id.begins_with(PREFIX)

static func base_of(id: String) -> String:
	return id.substr(PREFIX.length()) if is_endless(id) else id

static func id_for(base: String) -> String:
	return PREFIX + base

static func cfg() -> Dictionary:
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	return d if d is Dictionary else {}

## ¿Está abierto? Al vencer a Cthulhu (o con todo desbloqueado).
static func unlocked(save: SaveData) -> bool:
	return save != null and (save.unlock_all or save.levels_won.has(String(cfg().get("unlock", "p3_n5"))))

## El nivel sin fin sobre el escenario del nivel `base` (p. ej. "p2_n3").
static func make_level(id: String) -> LevelData:
	var c := cfg()
	var base := base_of(id)
	var src: LevelData = load("res://data/levels/%s.tres" % base)
	var lv: LevelData = src.duplicate()
	lv.id = StringName(id)
	lv.display_name = "La noche eterna · %s" % src.display_name
	lv.endless = true
	lv.number = 1
	var skip: Array = c.get("skip_enemies", [])
	var pool: Array[EnemyData] = []
	var seen := {}
	for p in 3:
		for n in 5:
			var l: LevelData = load("res://data/levels/p%d_n%d.tres" % [p + 1, n + 1])
			for d in l.pool:
				if d.unique or seen.has(d.id) or skip.has(String(d.id)) or String(d.id).ends_with("_muelle"): continue
				seen[d.id] = true
				pool.append(d)
	lv.pool = pool
	var rates: Array[Vector2] = []
	for r: Array in c.get("spawn_rate", [[0, 0.6], [300, 3.0], [900, 5.0], [1800, 7.0], [3600, 9.0]]):
		rates.append(Vector2(float(r[0]), float(r[1])))
	lv.spawn_rate = rates
	lv.final_enemy = null
	lv.final_next = null
	lv.final_survive = 0.0
	lv.final_time = 1e9
	lv.money_bonus = 0
	# un jefe cada `boss_every` s, en el orden de la campaña y vuelta a empezar
	var bosses: Array[EnemyData] = []
	for b: String in c.get("bosses", []):
		var path := "res://data/enemies/%s.tres" % b
		if ResourceLoader.exists(path): bosses.append(load(path))
	var every := float(c.get("boss_every", 300.0))
	var mids: Array[EnemyData] = []
	var times: Array[float] = []
	var texts: Array[String] = []
	if not bosses.is_empty():
		for k in int(c.get("bosses_max", 24)):
			mids.append(bosses[k % bosses.size()])
			times.append(every * (k + 1))
			texts.append("La noche trae %s" % bosses[k % bosses.size()].display_name)
	lv.mid_enemies = mids
	lv.mid_times = times
	lv.mid_texts = texts
	return lv

func setup(p_level: LevelData) -> Endless:
	level = p_level
	_base_health = level.health_mult
	_base_max = level.max_alive
	name = "Endless"
	return self

func _physics_process(_delta: float) -> void:
	var dir := get_parent().get("director") as WaveDirector
	if dir == null or dir.mirror: return
	step(level, dir.time, _base_health, _base_max)

## La dificultad que sube sola: más escalones de enemigos, más vida, más a la vez y más élites.
static func step(lv: LevelData, t: float, base_health := 1.0, base_max := 90) -> void:
	var c := cfg_cached()
	lv.number = clampi(1 + int(t / float(c.get("tier_every", 120.0))), 1, 5)
	lv.health_mult = base_health * (1.0 + float(c.get("health_per_5min", 0.25)) * t / 300.0)
	lv.max_alive = mini(base_max + int(t / 60.0 * float(c.get("alive_per_min", 3.0))), int(c.get("alive_max", 160)))
	lv.elite_cap = 2 + int(t / float(c.get("elite_every", 600.0)))

static var _cfg_cache := {}
static func cfg_cached() -> Dictionary:
	if _cfg_cache.is_empty(): _cfg_cache = cfg()
	return _cfg_cache

## Récord del escenario `base` con ese personaje (s; 0 si no hay).
static func best(save: SaveData, character: String, base: String) -> float:
	if save == null: return 0.0
	return float((save.records.get("endless", {}) as Dictionary).get("%s|%s" % [character, base], 0.0))

## Apunta el tiempo; true si es récord nuevo. También el mejor de todos (`stats.endless_best`,
## para el logro).
static func record(save: SaveData, character: String, base: String, t: float) -> bool:
	if save == null: return false
	if not save.records.has("endless"): save.records["endless"] = {}
	var key := "%s|%s" % [character, base]
	var prev := float(save.records.endless.get(key, 0.0))
	save.stats["endless_best"] = maxi(int(save.stats.get("endless_best", 0)), int(t))
	if t <= prev: return false
	save.records.endless[key] = roundf(t * 10.0) / 10.0
	return true

static func clock(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]
