class_name Fishing
extends RefCounted
## Pesca en el muelle de Innsmouth (hito 16.24): un minijuego tranquilo entre nivel y nivel de la
## parte 2. Datos en data/fishing.json; la escena es FishingScene (scenes/fishing.tscn). Aquí, lo
## que no se dibuja: qué pica (`roll`), el sedal al recoger (`Line`), lo pescado en el hueco
## (`SaveData.records["fishing"]`: {id: {caught, kept}}) y la maldición de lo que no debería haber
## salido del agua (`GameSession.fish_curse`, que la partida aplica al empezar el siguiente nivel).

const PATH := "res://data/fishing.json"
const SCENE := "res://scenes/fishing.tscn"
const RARITY_NAMES := {"comun": "Común", "raro": "Rara", "maldito": "No debería haber salido del agua"}

static var _cfg := {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_cfg = d if d is Dictionary else {}
	return _cfg

static func catches() -> Array:
	return cfg().get("catches", [])

static func find(id: String) -> Dictionary:
	for c: Dictionary in catches():
		if String(c.id) == id: return c
	return {}

## ¿Se puede ir a pescar al superar este nivel? Los de la parte del muelle (Innsmouth), de la
## campaña y con otro detrás; sin red.
static func offered(level_id: String, next_id: String, online: bool) -> bool:
	if online or next_id == "" or Campaign.next_in_part(level_id) != next_id: return false
	for l in Campaign.levels():
		if String(l.id) == level_id: return int(l.part) == int(cfg().get("part", 1))
	return false

## Lo que pica, por los pesos.
static func roll(rng: RandomNumberGenerator) -> Dictionary:
	var all := catches()
	var total := 0.0
	for c: Dictionary in all: total += float(c.weight)
	var r := rng.randf() * total
	for c: Dictionary in all:
		r -= float(c.weight)
		if r <= 0.0: return c
	return all[-1]

## Lo pescado, al hueco. `kept`: llevada a la Biblioteca (las raras y las malditas: su ficha entera).
static func record(save: SaveData, id: String, kept: bool) -> void:
	if save == null: return
	var all: Dictionary = save.records.get("fishing", {})
	var r: Dictionary = all.get(id, {"caught": 0, "kept": 0})
	r["caught"] = int(r.get("caught", 0)) + 1
	if kept: r["kept"] = int(r.get("kept", 0)) + 1
	all[id] = r
	save.records["fishing"] = all

static func caught(save: SaveData, id: String) -> int:
	if save == null: return 0
	return int(((save.records.get("fishing", {}) as Dictionary).get(id, {}) as Dictionary).get("caught", 0))

static func kept(save: SaveData, id: String) -> int:
	if save == null: return 0
	return int(((save.records.get("fishing", {}) as Dictionary).get(id, {}) as Dictionary).get("kept", 0))

## ¿Se lee su ficha entera en el bestiario? Las comunes, al pescarlas; las demás, al llevarlas.
static func full_entry(save: SaveData, c: Dictionary) -> bool:
	if save != null and save.unlock_all: return true
	return kept(save, String(c.id)) > 0 if String(c.rarity) != "comun" else caught(save, String(c.id)) > 0

## El sedal mientras se recoge (sin dibujo, con tests). Con A mantenido se gana hilo y sube la
## tensión; soltando, baja la tensión y se pierde algo de hilo. El pez da tirones: mientras dura
## uno, recoger sube mucho la tensión. Tensión 1: se parte. Progreso 1: fuera del agua.
class Line:
	enum { REELING, CAUGHT, BROKE }
	var progress := 0.15
	var tension := 0.0
	var state := REELING
	var bursting := false
	var _next_burst := 0.0
	var _burst_left := 0.0
	var _pull := 0.3
	var _r: Dictionary
	var _rng: RandomNumberGenerator

	func _init(fish: Dictionary, rng: RandomNumberGenerator) -> void:
		_pull = float(fish.get("pull", 0.3))
		_r = Fishing.cfg().get("reel", {})
		_rng = rng
		_next_burst = _every()

	func _every() -> float:
		var e: Array = _r.get("burst_every", [1.0, 2.0])
		return _rng.randf_range(float(e[0]), float(e[1])) * lerpf(1.2, 0.7, _pull)   # los fuertes, más a menudo

	func step(delta: float, reeling: bool) -> int:
		if state != REELING: return state
		_next_burst -= delta
		if _next_burst <= 0.0 and not bursting:
			bursting = true
			_burst_left = float(_r.get("burst_time", 0.6))
		if bursting:
			_burst_left -= delta
			progress -= float(_r.get("burst_back", 0.12)) * _pull * delta
			if _burst_left <= 0.0:
				bursting = false
				_next_burst = _every()
		if reeling:
			progress += float(_r.get("rate", 0.2)) * delta
			tension += (float(_r.get("tension_up", 0.32)) + (float(_r.get("burst_tension", 1.6)) * _pull if bursting else 0.0)) * delta
		else:
			progress -= float(_r.get("slack", 0.05)) * delta
			tension -= float(_r.get("tension_down", 0.75)) * delta
		tension = clampf(tension, 0.0, 1.0)
		progress = clampf(progress, 0.0, 1.0)
		if tension >= 1.0: state = BROKE
		elif progress >= 1.0: state = CAUGHT
		return state
