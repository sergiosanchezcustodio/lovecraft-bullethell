class_name NightCycle
extends Node
## La noche avanza durante el nivel (hito 16.33): en las arenas de noche al aire libre, el nivel
## empieza en el crepúsculo (la luna más baja, cálida y fuerte, el fondo morado y casi sin
## estrellas) y llega a la luz aprobada de la arena (noche cerrada) antes del evento final; si cae
## el jefe, amanece. Va con el reloj del director, así que en red todos los PC lo ven igual. La
## curva acaba en la luz de siempre: la mediana de brillo de las noches (0,16-0,22) se mide ahí y
## el crepúsculo, algo más claro, no pasa de 0,22. Datos en `data/night.json`.

const CONFIG := "res://data/night.json"
const KEYS := ["sun", "warm", "ambient", "ambient_mix", "bg_mix", "pitch", "stars"]

static var _cfg: Dictionary = {}

static func config() -> Dictionary:
	if _cfg.is_empty():
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		_cfg = j if j is Dictionary else {"arenas": {}}
	return _cfg

## Cuánto cambia la luz en esta arena (0: nada).
static func amount(arena_id: String) -> float:
	return float((config().get("arenas", {}) as Dictionary).get(arena_id, 0.0))

## Cuánto crepúsculo queda (1 al empezar, 0 en la noche cerrada) a los `t` s de `final_time`.
static func dusk_k(t: float, final_time: float) -> float:
	if final_time <= 0.0: final_time = 240.0
	return 1.0 - smoothstep(0.0, float(config().get("to", 0.85)), t / final_time)

## La luz con `w` de crepúsculo y `a` de alba sobre la de la arena (`base`: sun_energy, sun_color,
## ambient_energy, ambient_color, background, pitch y stars).
static func blend(base: Dictionary, w: float, a: float) -> Dictionary:
	var out := base.duplicate()
	for p: Array in [[config().get("dusk", {}), w], [config().get("dawn", {}), a]]:
		var c: Dictionary = p[0]
		var k: float = p[1]
		if k <= 0.0 or c.is_empty(): continue
		out.sun_energy = float(out.sun_energy) * lerpf(1.0, float(c.get("sun", 1.0)), k)
		out.ambient_energy = float(out.ambient_energy) * lerpf(1.0, float(c.get("ambient", 1.0)), k)
		out.sun_color = (out.sun_color as Color).lerp(_col(c, "color", out.sun_color), float(c.get("warm", 0.0)) * k)
		out.ambient_color = (out.ambient_color as Color).lerp(_col(c, "ambient_color", out.ambient_color), float(c.get("ambient_mix", 0.0)) * k)
		out.background = (out.background as Color).lerp(_col(c, "background", out.background), float(c.get("bg_mix", 0.0)) * k)
		out.pitch = float(out.pitch) + float(c.get("pitch", 0.0)) * k
		out.stars = lerpf(float(out.stars), float(base.stars) * float(c.get("stars", 1.0)), k)
	return out

static func _col(c: Dictionary, key: String, def: Color) -> Color:
	var a: Array = c.get(key, [])
	return Color(a[0], a[1], a[2]) if a.size() >= 3 else def

var moon: DirectionalLight3D
var env: Environment
var director: WaveDirector
var ambient: Ambient
var _amt := 1.0
var _base := {}
var _dawn_t := -1.0                              ## s desde que cayó el jefe (<0: aún no)
var _fixed := -1.0                               ## night=0..1 la fija (pruebas)
var _dawn_time := 12.0

func setup(p_moon: DirectionalLight3D, p_env: Environment, p_director: WaveDirector, p_ambient: Ambient, arena_id: String) -> NightCycle:
	name = "NightCycle"
	moon = p_moon
	env = p_env
	director = p_director
	ambient = p_ambient
	_amt = amount(arena_id)
	return self

func _ready() -> void:
	_base = {"sun_energy": moon.light_energy, "sun_color": moon.light_color,
		"ambient_energy": env.ambient_light_energy, "ambient_color": env.ambient_light_color,
		"background": env.background_color, "pitch": moon.rotation_degrees.x,
		"stars": ambient.night if ambient != null else 0.0}
	_dawn_time = float((config().get("dawn", {}) as Dictionary).get("time", 12.0))
	var args := LaunchArgs.from_cmdline()
	if args.get_str("night", "").is_valid_float(): _fixed = clampf(args.get_float("night", 1.0), 0.0, 1.0)
	if args.get_bool("dawn"): _dawn_t = 0.0
	if director != null: director.level_completed.connect(func() -> void: if _dawn_t < 0.0: _dawn_t = 0.0)
	_apply()

func _process(delta: float) -> void:
	if _dawn_t >= 0.0: _dawn_t += delta
	_apply()

func _apply() -> void:
	var w: float
	if _fixed >= 0.0: w = 1.0 - _fixed
	else:
		var t := director.time if director != null else 0.0
		var ft := director.level.final_time if director != null and director.level != null else 240.0
		w = dusk_k(t, ft)
	var a := smoothstep(0.0, _dawn_time, _dawn_t) if _dawn_t >= 0.0 else 0.0
	var l := blend(_base, w * _amt * (1.0 - a), a * _amt)
	moon.light_energy = l.sun_energy
	moon.light_color = l.sun_color
	moon.rotation_degrees.x = minf(float(l.pitch), -8.0)
	env.ambient_light_color = l.ambient_color
	env.background_color = l.background
	# la tormenta reescribe el ambiente en cada fotograma (relámpagos) desde su base: se le cambia esa
	var weather: Variant = get_parent().get("weather") if get_parent() != null else null
	if weather is Weather: (weather as Weather)._base_ambient = l.ambient_energy
	env.ambient_light_energy = l.ambient_energy
	if ambient != null: ambient.set_stars(l.stars)
