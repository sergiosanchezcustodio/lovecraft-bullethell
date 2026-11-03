class_name Expedition
## Expedición (hito 16.21, a la manera de *Slay the Spire*): una tirada por una parte de la
## campaña con un mapa de caminos que se bifurcan (`ExpeditionMap`, `scenes/expedition_map.tscn`).
## Cada fila tiene dos o tres nodos y cada nodo lleva a uno o dos de la siguiente:
##   combate     un nivel de la parte, más corto (`combat_time`), con su evento final;
##   elite       igual, con el triple de élites (todas con rasgos, 16.20) y una subida de premio;
##   buhonero    una parada corta con el buhonero (16.12) desde el principio;
##   curiosidad  un suceso con dos o tres opciones, en el mapa (`curiosities`);
##   descanso    el campamento: dos subidas al empezar el siguiente nivel, en el mapa;
##   jefe        el último nivel de la parte, con su jefe enseguida (`boss_time`).
## El progreso pasa de un nivel a otro (`GameSession.carry`) y los dólares se guardan en la bolsa
## de la expedición (`state.money`), que solo vale aquí: ni llegan al hueco ni salen de él. Al caer
## se acaba la expedición. Solo sin red. Los niveles son «expedicion:<tipo>:<nivel>:<fila>»; el
## mapa, «expedicion:mapa». Estado en `GameSession.expedition`; números en `data/expedition.json`.

const DATA := "res://data/expedition.json"
const PREFIX := "expedicion:"
const MAP_ID := "expedicion:mapa"
const SCENE := "res://scenes/expedition_map.tscn"
const KINDS := ["combate", "elite", "buhonero", "curiosidad", "descanso", "jefe"]
const NAMES := {"combate": "Combate", "elite": "Élites", "buhonero": "El buhonero", "curiosidad": "Curiosidad",
	"descanso": "Descanso", "jefe": "Jefe"}
const INFO := {"combate": "Un nivel de la parte, más corto.", "elite": "Más élites, todas con rasgos. Una subida de premio.",
	"buhonero": "Una parada corta con el buhonero: gasta la bolsa de la expedición.",
	"curiosidad": "Algo os sale al paso. Elegís qué hacer.", "descanso": "El campamento: dos subidas al empezar el siguiente nivel.",
	"jefe": "El horror de la parte. Si cae, la expedición está hecha."}
static var _cfg := {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_cfg = d if d is Dictionary else {}
	return _cfg

static func is_expedition(id: String) -> bool:
	return id.begins_with(PREFIX)

static func is_map(id: String) -> bool:
	return id == MAP_ID

## Tipo del nodo de un id de nivel ("" si no es de la expedición).
static func kind_of(id: String) -> String:
	return id.get_slice(":", 1) if is_expedition(id) and not is_map(id) else ""

static func base_of(id: String) -> String:
	return id.get_slice(":", 2) if is_expedition(id) and not is_map(id) else "p1_n1"

static func level_id(kind: String, base: String, row: int) -> String:
	return "%s%s:%s:%d" % [PREFIX, kind, base, row]

## ¿Abierta la expedición de la parte `part` (0..)? Al superar su último nivel.
static func unlocked(save: SaveData, part: int) -> bool:
	if save == null: return false
	if save.unlock_all: return true
	var last := ""
	for l: Dictionary in Campaign.levels(): if int(l.part) == part: last = String(l.id)
	return last != "" and save.levels_won.has(last)

# ---------------------------------------------------------------- el mapa

## Mapa nuevo de la parte `part`: filas de nodos {kind, base, links} (links: índices en la fila
## siguiente) y, al final, el jefe. Determinista con la semilla.
static func generate(part: int, seed: int) -> Array:
	var c := cfg()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var levels: Array = Campaign.levels().filter(func(l: Dictionary) -> bool: return int(l.part) == part)
	var n_rows := int(c.get("rows", 6))
	var w: Array = c.get("width", [2, 3])
	var weights: Dictionary = c.get("weights", {})
	var rows: Array = []
	for r in n_rows:
		var row: Array = []
		var width := 2 if r == n_rows - 1 else rng.randi_range(int(w[0]), int(w[1]))   # antes del jefe: descanso o buhonero
		var lvl_n := clampi(1 + int(float(r) / float(n_rows) * 4.0), 1, 4)       # del nivel 1 al 4 de la parte
		for i in width:
			var kind: String = "combate" if r == 0 else (String(["descanso", "buhonero"][mini(i, 1)]) if r == n_rows - 1 else _pick(weights, rng))
			if r == 1 and kind == "descanso": kind = "combate"
			var lv: Dictionary = levels[mini(lvl_n - 1 + (rng.randi() % 2 if r > 0 else 0), levels.size() - 2)]
			row.append({"kind": kind, "base": String(lv.id), "links": []})
		rows.append(row)
	rows.append([{"kind": "jefe", "base": String(levels[-1].id), "links": []}])
	for r in rows.size() - 1:                         # cada nodo, a uno o dos de la fila siguiente; ninguno sin entrada
		var a: Array = rows[r]
		var b: Array = rows[r + 1]
		for i in a.size():
			var j := roundi(float(i) / maxf(a.size() - 1, 1) * (b.size() - 1))
			a[i].links = [j]
			if b.size() > 1 and rng.randf() < 0.5:
				var k := clampi(j + (1 if rng.randf() < 0.5 else -1), 0, b.size() - 1)
				if k != j: a[i].links.append(k)
		for j in b.size():
			if not a.any(func(n: Dictionary) -> bool: return j in n.links):
				var best := 0
				for i in a.size(): if absf(float(i) / maxf(a.size() - 1, 1) - float(j) / maxf(b.size() - 1, 1)) < absf(float(best) / maxf(a.size() - 1, 1) - float(j) / maxf(b.size() - 1, 1)): best = i
				a[best].links.append(j)
		for n: Dictionary in a: n.links.sort()
	return rows

static func _pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k in weights: total += float(weights[k])
	var x := rng.randf() * total
	for k in weights:
		x -= float(weights[k])
		if x <= 0.0: return String(k)
	return "combate"

## Empieza una expedición nueva por la parte `part`.
static func start(part: int, seed := -1) -> void:
	if seed < 0: seed = randi()
	GameSession.expedition = {"part": part, "seed": seed, "rows": generate(part, seed), "row": -1, "col": -1,
		"money": 0, "bonus": 0, "hurt": 1.0, "time": 0.0, "done": [], "signs": 0}
	GameSession.carry.clear()
	GameSession.level = StringName(MAP_ID)

static func state() -> Dictionary:
	return GameSession.expedition

static func active() -> bool:
	return not GameSession.expedition.is_empty()

## Los nodos a los que se puede ir ahora: [fila, columna].
static func choices() -> Array:
	var st := state()
	if st.is_empty(): return []
	var rows: Array = st.rows
	var r := int(st.row)
	if r < 0: return range((rows[0] as Array).size()).map(func(i: int) -> Array: return [0, i])
	if r >= rows.size() - 1: return []
	var out := []
	for j: int in rows[r][int(st.col)].links: out.append([r + 1, j])
	return out

## Va al nodo [fila, columna]: devuelve el id del nivel que hay que jugar, o "" si se resuelve
## en el mapa (curiosidad y descanso, que se aplican con `rest` o `choose`).
static func enter(r: int, c: int) -> String:
	var st := state()
	st.row = r
	st.col = c
	(st.done as Array).append([r, c])
	var n: Dictionary = st.rows[r][c]
	match String(n.kind):
		"curiosidad", "descanso": return ""
	return level_id(String(n.kind), String(n.base), r)

static func node_at(r: int, c: int) -> Dictionary:
	return state().rows[r][c]

## Descanso: subidas al empezar el siguiente nivel.
static func rest() -> void:
	state().bonus = int(state().bonus) + int(cfg().get("rest_bonus", 2))

## Suceso de esta fila (siempre el mismo para la misma expedición y fila).
static func curiosity(r: int) -> Dictionary:
	var list: Array = cfg().get("curiosities", [])
	if list.is_empty(): return {}
	return list[(int(state().get("seed", 0)) + r * 7) % list.size()]

## ¿Se puede elegir la opción? (si cuesta dólares, que los haya en la bolsa)
static func can_choose(o: Dictionary) -> bool:
	return int(o.get("money", 0)) >= 0 or int(state().money) + int(o.money) >= 0

## Aplica la opción de un suceso a la bolsa y al progreso de cada jugador (`GameSession.carry`).
static func choose(o: Dictionary, rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var st := state()
	st.money = maxi(int(st.money) + int(o.get("money", 0)), 0)
	st.bonus = int(st.bonus) + int(o.get("bonus", 0))
	st.hurt = float(st.hurt) * float(o.get("hurt", 1.0))
	st.signs = int(st.signs) + int(o.get("sign", 0))   # Signos Mayores de más (los da la partida al empezar)
	for snap: Dictionary in GameSession.carry:
		for i in int(o.get("weapon", 0)):
			var ws: Array = (snap.weapons as Array).filter(func(e: Array) -> bool: return int(e[1]) < _max_level(String(e[0])))
			if not ws.is_empty():
				var e: Array = ws[rng.randi() % ws.size()]
				e[1] = int(e[1]) + 1
		for i in int(o.get("passive", 0)):
			var ups: Array = []
			for f in DirAccess.get_files_at("res://data/upgrades"):
				var id := f.trim_suffix(".remap").trim_suffix(".tres")
				if f.ends_with(".tres") or f.ends_with(".tres.remap"):
					if not (snap.passives as Dictionary).has(StringName(id)) and not (snap.passives as Dictionary).has(id): ups.append(id)
			if not ups.is_empty(): snap.passives[StringName(ups[rng.randi() % ups.size()])] = 1

static func _max_level(weapon: String) -> int:
	var path := "res://data/weapons/%s.tres" % weapon
	return (load(path) as WeaponData).max_level if ResourceLoader.exists(path) else 5

# ---------------------------------------------------------------- los niveles

static func make_level(id: String) -> LevelData:
	var c := cfg()
	var kind := kind_of(id)
	var src: LevelData = load("res://data/levels/%s.tres" % base_of(id))
	var lv: LevelData = src.duplicate()
	lv.id = StringName(id)
	lv.display_name = "Expedición · %s · %s" % [String(NAMES.get(kind, kind)), src.display_name]
	lv.money_bonus = 0
	lv.mid_enemies = []
	lv.mid_times = []
	lv.mid_texts = []
	match kind:
		"combate":
			lv.final_time = float(c.get("combat_time", 120.0))
		"elite":
			lv.final_time = float(c.get("elite_time", 100.0))
			lv.elite_cap = maxi(roundi(lv.elite_cap * float(c.get("elite_cap", 3.0))), 3)
			lv.health_mult *= float(c.get("elite_health", 1.15))
		"buhonero":
			lv.final_time = float(c.get("peddler_time", 70.0))
			lv.final_enemy = null
			lv.final_next = null
			lv.final_survive = 12.0                       # al final, una horda corta y se acaba
			lv.final_rate = 2.0
			lv.final_name = "los que siguen al buhonero"
			var rates: Array[Vector2] = []
			for v: Vector2 in lv.spawn_rate: rates.append(Vector2(v.x, v.y * 0.4))
			lv.spawn_rate = rates
		"jefe":
			lv.final_time = float(c.get("boss_time", 45.0))
			lv.final_survive = 0.0
	if lv.final_survive > 0.0 and kind != "buhonero": lv.final_survive = minf(lv.final_survive, 30.0)   # la horda del Arrecife, más corta
	return lv

## ¿El buhonero sale en este nivel? (enseguida)
static func peddler_now(id: String) -> bool:
	return kind_of(id) == "buhonero"

## Nivel superado: la bolsa y el tiempo. Devuelve el id que sigue (el mapa, o "" tras el jefe).
static func won(id: String, money_left: int, t: float) -> String:
	var st := state()
	st.money = money_left
	st.time = float(st.time) + t
	if kind_of(id) == "elite": st.bonus = int(st.bonus) + int(cfg().get("elite_bonus", 1))
	return "" if kind_of(id) == "jefe" else MAP_ID

## Récords: expediciones completadas por parte (y la más rápida).
static func record(save: SaveData, part: int, t: float) -> bool:
	if save == null: return false
	if not save.records.has("expeditions"): save.records["expeditions"] = {}
	var key := "p%d" % (part + 1)
	var rec: Dictionary = save.records.expeditions.get(key, {"won": 0, "best": 0.0})
	rec.won = int(rec.won) + 1
	var better := float(rec.best) <= 0.0 or t < float(rec.best)
	if better: rec.best = roundf(t * 10.0) / 10.0
	save.records.expeditions[key] = rec
	return better

static func wins(save: SaveData, part: int) -> int:
	if save == null: return 0
	return int(((save.records.get("expeditions", {}) as Dictionary).get("p%d" % (part + 1), {}) as Dictionary).get("won", 0))
