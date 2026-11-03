class_name BossRush
## Desfile de jefes (hito 16.22): los jefes de la campaña seguidos (los intermedios del 16.19 y
## los finales de cada parte), cada uno en el escenario de su nivel. Cada jefe es un nivel
## («desfile:1» a «desfile:6»: así viaja en red con START y se reintenta) que se monta sobre el de
## la campaña (`make_level`): el jefe sale a los `boss_at` s, con pocos acompañantes. Se empieza
## con `start_levels` subidas y el progreso pasa de uno a otro como en una parte
## (`GameSession.carry`); sin pactos, buhonero ni locura. El tiempo de cada jefe se suma
## (`GameSession.rush_time`) y el total, al vencer al último, es el récord por personaje
## (`SaveData.records["boss_rush"]`). Números en `data/boss_rush.json`.

const DATA := "res://data/boss_rush.json"
const PREFIX := "desfile:"
static var _cfg := {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_cfg = d if d is Dictionary else {}
	return _cfg

static func stages() -> Array:
	return cfg().get("stages", [])

static func is_rush(id: String) -> bool:
	return id.begins_with(PREFIX)

static func id_for(n: int) -> String:
	return PREFIX + str(n)

## Número del jefe (1..); 0 si no es del desfile.
static func number_of(id: String) -> int:
	return int(id.substr(PREFIX.length())) if is_rush(id) else 0

static func stage(id: String) -> Dictionary:
	var n := number_of(id)
	return stages()[n - 1] if n >= 1 and n <= stages().size() else {}

## El nivel de la campaña del que sale su escenario.
static func base_of(id: String) -> String:
	return String(stage(id).get("level", "p1_n1"))

## El siguiente del desfile ("" tras el último).
static func next(id: String) -> String:
	var n := number_of(id)
	return id_for(n + 1) if n >= 1 and n < stages().size() else ""

## ¿Abierto? Al vencer a Cthulhu (o con todo desbloqueado).
static func unlocked(save: SaveData) -> bool:
	return save != null and (save.unlock_all or save.levels_won.has(String(cfg().get("unlock", "p3_n5"))))

## El jefe del paso (el final de su nivel si no se da otro).
static func boss_of(id: String) -> EnemyData:
	var b := String(stage(id).get("boss", ""))
	if b != "": return load("res://data/enemies/%s.tres" % b)
	var src: LevelData = load("res://data/levels/%s.tres" % base_of(id))
	return src.final_enemy

static func make_level(id: String) -> LevelData:
	var c := cfg()
	var st := stage(id)
	var src: LevelData = load("res://data/levels/%s.tres" % base_of(id))
	var lv: LevelData = src.duplicate()
	lv.id = StringName(id)
	var boss := boss_of(id)
	lv.display_name = "Desfile de jefes · %s" % (boss.display_name if boss != null else src.display_name)
	lv.final_time = float(c.get("boss_at", 6.0))
	lv.final_survive = 0.0
	lv.final_wave = int(c.get("final_wave", 6))
	if st.has("boss"):
		lv.final_enemy = boss
		lv.final_next = null
		lv.final_text = src.mid_texts[0] if not src.mid_texts.is_empty() and boss in src.mid_enemies else lv.final_text
	lv.mid_enemies = []
	lv.mid_times = []
	lv.mid_texts = []
	var rates: Array[Vector2] = [Vector2(0.0, float(c.get("spawn_rate", 0.5)))]
	lv.spawn_rate = rates
	lv.max_alive = int(c.get("max_alive", 24))
	lv.money_bonus = 0
	lv.health_mult *= float(st.get("health", 1.0))   # los intermedios, más duros: llegan contra un nivel 23
	return lv

## Récord del personaje (tiempo total, s; 0 si no hay).
static func best(save: SaveData, character: String) -> float:
	if save == null: return 0.0
	return float((save.records.get("boss_rush", {}) as Dictionary).get(character, 0.0))

## El mejor de todos los personajes (0 si no hay).
static func best_any(save: SaveData) -> float:
	if save == null: return 0.0
	var out := 0.0
	for v in (save.records.get("boss_rush", {}) as Dictionary).values():
		if out <= 0.0 or float(v) < out: out = float(v)
	return out

## Apunta el total; true si es récord (menos tiempo, o el primero).
static func record(save: SaveData, character: String, t: float) -> bool:
	if save == null: return false
	if not save.records.has("boss_rush"): save.records["boss_rush"] = {}
	var prev := best(save, character)
	if prev > 0.0 and t >= prev: return false
	save.records.boss_rush[character] = roundf(t * 10.0) / 10.0
	return true
