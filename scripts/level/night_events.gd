class_name NightEvents
extends Node
## Sucesos de la noche (hito 21.4): una o dos veces por nivel, con aviso, algo cambia las reglas
## durante unos 30 s: la luna de sangre (más élites y el doble de dólares), la niebla espesa (se ve
## menos, más experiencia), la lluvia de estrellas (caen gemas), el silencio (nadie aparece y luego
## una horda), la marea viva y la ventisca (data/night_events.json). Las reglas se leen en vivo con
## `value`, como los pactos (Pacts.value). Lo decide el anfitrión (o el PC en local), con la semilla
## de la partida, y llega a los invitados como suceso de la red ("night"); allí solo se ve y se oye.

const PATH := "res://data/night_events.json"
const FADE := 2.5                    ## s que tarda la luz en cambiar al empezar y al acabar
const STAR_FALL := 0.55              ## s que tarda una estrella en caer
const STAR_FROM := Vector3(2.5, 13.0, -2.5)

static var _data := {}
static var current := {}             ## el suceso en curso ({}: ninguno); sus reglas, con value()

var game: Node                       ## Game
var director: WaveDirector
var world: CombatWorld
var arena_id := ""
var host := true                     ## decide y aplica las reglas; el invitado solo lo enseña
var schedule: Array = []             ## [[segundo, id]] por lanzar, en orden
var started := 0                     ## sucesos lanzados en este nivel
var left := 0.0                      ## s que le quedan al suceso en curso
var _scheduled := false
var _k := 0.0                        ## cuánto se ve el suceso (0..1)
var _look := {}                      ## lo que se ve del último (se apaga después de acabar)
var _rain_t := 0.0
var _silence := -1.0                 ## s de silencio que quedan (<0: no)
var _weather_before: WeatherData
var _weather_changed := false
var _moon: DirectionalLight3D
var _env: Environment
var _moon_base := Color.WHITE
var _moon_wrote := Color(-1, -1, -1)
var _amb_base := Color.WHITE
var _amb_wrote := Color(-1, -1, -1)
var _fog_base := 0.0
var _fog_wrote := -1.0
var _star_mat: StandardMaterial3D

# ---------------------------------------------------------------- datos

static func data() -> Dictionary:
	if _data.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = d if d is Dictionary else {"sucesos": []}
	return _data

static func all() -> Array:
	return data().get("sucesos", [])

static func find(id: String) -> Dictionary:
	for e: Dictionary in all():
		if String(e.id) == id: return e
	return {}

## Los que pueden salir en esta arena.
static func for_arena(arena: String) -> Array:
	var out := []
	for e: Dictionary in all():
		var where: Variant = e.get("arenas", "todas")
		if where is Array and not (where as Array).has(arena): continue
		if (e.get("excluir", []) as Array).has(arena): continue
		out.append(e)
	return out

## Una regla del suceso en curso (1 si no hay ninguno o no la cambia).
static func value(key: String) -> float:
	if current.is_empty(): return 1.0
	return float((current.get("efectos", {}) as Dictionary).get(key, 1.0))

## Rapidez de un enemigo por el suceso (la ventisca a todos; la marea, a los marinos).
static func speed_of(d: EnemyData) -> float:
	if current.is_empty(): return 1.0
	var k := value("enemy_speed")
	if d.tags.has(&"marina"): k *= value("marine_speed")
	return k

## Peso al aparecer (las élites con la luna de sangre; los marinos con la marea).
static func weight_of(d: EnemyData) -> float:
	if current.is_empty(): return 1.0
	var k := value("elite_weight") if d.tier >= 4 else 1.0
	if d.tags.has(&"marina"): k *= value("marine_weight")
	return k

# ---------------------------------------------------------------- partida

func setup(p_game: Node, p_director: WaveDirector, p_world: CombatWorld, p_moon: DirectionalLight3D,
		p_env: Environment, p_arena: String, p_host: bool) -> NightEvents:
	name = "NightEvents"
	game = p_game; director = p_director; world = p_world; _moon = p_moon; _env = p_env
	arena_id = p_arena; host = p_host
	current = {}
	process_priority = 10                       # después del ciclo de la noche y del clima, que reescriben la luz
	return self

## Los sucesos del nivel: uno o dos, distintos, con la semilla de la partida (en `_physics_process`,
## cuando ya está). `forced`: ese id a los `at` s (pruebas).
func plan(seed: int, forced := "", at := 5.0) -> void:
	_scheduled = true
	schedule.clear()
	if forced != "":
		if not find(forced).is_empty(): schedule.append([at, forced])
		return
	var ft := director.level.final_time if director != null and director.level != null else 0.0
	var pool := for_arena(arena_id)
	if ft < 60.0 or pool.is_empty(): return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var d := data()
	var n := 2 if rng.randf() < float(d.get("dos", 0.5)) and pool.size() > 1 else 1
	for i in n:
		var e: Dictionary = pool[rng.randi() % pool.size()]
		pool.erase(e)
		var span: Array = d.get("primero" if i == 0 else "segundo", [0.25, 0.35])
		schedule.append([ft * rng.randf_range(float(span[0]), float(span[1])), String(e.id)])

func _physics_process(delta: float) -> void:
	if not host or director == null: return
	if not _scheduled:
		var args := LaunchArgs.from_cmdline()
		var seed := int(game.get("run_seed")) if game != null and game.get("run_seed") != null else randi()
		plan(seed * 31 + hash(arena_id), args.get_str("night_event", ""), args.get_float("night_at", 5.0))
	step(delta)

## Anfitrión: lanza lo que toca y lleva el que está en curso (tests: a mano).
func step(delta: float) -> void:
	if current.is_empty():
		if schedule.is_empty() or director.completed or director._final_done: return
		if director.time < float(schedule[0][0]): return
		start(String((schedule.pop_front() as Array)[1]))
		return
	left -= delta
	_rain_step(delta)
	_silence_step(delta)
	if left <= 0.0: stop()

## Empieza un suceso: avisa, suena y cambia las reglas (también en el invitado, desde la red).
func start(id: String) -> void:
	var e := find(id)
	if e.is_empty(): return
	current = e
	_look = e
	started += 1
	left = float(e.get("duracion", 30.0))
	_rain_t = 0.0
	var sil: Dictionary = e.get("silencio", {})
	_silence = float(sil.get("tiempo", 0.0)) if not sil.is_empty() else -1.0
	if host and _silence > 0.0: director.spawning_paused = true
	Auto.sfx("omen")
	if String(e.get("sonido", "")) != "": Auto.sfx(String(e.sonido))
	_say("%s · %s" % [String(e.get("nombre", "")), String(e.get("texto", ""))], 3.5)
	var wpath := String((e.get("visual", {}) as Dictionary).get("weather", ""))
	if wpath != "" and ResourceLoader.exists(wpath) and game != null and game.has_method("set_weather"):
		var w: Variant = game.get("weather")
		_weather_before = (w as Weather).data if w is Weather else null
		_weather_changed = true
		game.set_weather(load(wpath))
	_rules_changed()
	if host and game != null and game.get("net_game") != null:
		(game.get("net_game") as NetGame)._event({"k": "night", "text": id})
	if LaunchArgs.from_cmdline().get_bool("log"): print("SUCESO %s t=%.0f" % [id, director.time if director else 0.0])

## Acaba el suceso en curso: todo vuelve a como estaba (la luz, poco a poco).
func stop() -> void:
	if current.is_empty(): return
	var e := current
	current = {}
	left = 0.0
	if host and _silence >= 0.0: director.spawning_paused = false
	_silence = -1.0
	if String(e.get("fin", "")) != "": _say(String(e.fin), 2.0)
	if _weather_changed and game != null:
		game.set_weather(_weather_before)
		_weather_changed = false
	_rules_changed()
	if host and game != null and game.get("net_game") != null:
		(game.get("net_game") as NetGame)._event({"k": "night", "text": ""})

## Invitado: lo que manda el anfitrión ("" acaba el que hay).
func remote(id: String) -> void:
	if id == "": stop()
	else: start(id)

func _say(text: String, seconds: float) -> void:
	if game != null and game.has_method("announce"): game.announce(text, seconds)

## La rapidez de los investigadores va en sus estadísticas: se rehacen al empezar y al acabar.
func _rules_changed() -> void:
	if world == null: return
	for q: Player in world.players:
		if is_instance_valid(q): q.rebuild_stats()

func _exit_tree() -> void:
	current = {}                                # que no siga en el siguiente nivel ni en los menús

# ---------------------------------------------------------------- lluvia de estrellas y silencio

func _rain_step(delta: float) -> void:
	var r: Dictionary = current.get("lluvia", {})
	if r.is_empty() or world == null or world.players.is_empty(): return
	_rain_t -= delta
	if _rain_t > 0.0: return
	_rain_t = float(r.get("cada", 0.5))
	var alive := world.players.filter(func(q: Player) -> bool: return q.health > 0.0)
	if alive.is_empty(): return
	var q: Player = alive[randi() % alive.size()]
	var rad := float(r.get("radio", 8.0))
	for tries in 6:
		var a := randf() * TAU
		var d := lerpf(2.0, rad, sqrt(randf()))
		var at := Vector3(q.global_position.x + cos(a) * d, 0.0, q.global_position.z + sin(a) * d)
		if world.obstacles != null and world.obstacles.is_blocked(Vector2(at.x, at.z), 0.3): continue
		star(at, float(r.get("valor", 4.0)))
		return

## Una estrella cae del cielo en `at` y deja sus gemas al tocar el suelo.
func star(at: Vector3, value: float) -> void:
	if world == null or world.fx == null: return
	if _star_mat == null:
		_star_mat = VoxelFx.std()
		_star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_star_mat.albedo_color = Color(1.0, 0.95, 0.75)
	var c := MeshInstance3D.new()
	c.mesh = VoxelFx.box1()
	c.material_override = _star_mat
	c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.fx.add_child(c)
	c.global_position = at + STAR_FROM
	c.look_at_from_position(c.global_position, at, Vector3.FORWARD if absf(STAR_FROM.normalized().y) > 0.99 else Vector3.UP)
	c.scale = Vector3(0.07, 0.07, 0.9)                     # alargada a lo largo de la caída
	var tw := c.create_tween()
	tw.tween_property(c, "global_position", at + Vector3(0, 0.3, 0), STAR_FALL).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		VoxelFx.puff(world.fx, at + Vector3(0, 0.2, 0), "rise", 0.3, Color(1.0, 0.92, 0.6), 0.6)
		Auto.sfx_at("star_fall", at)
		var gems: Variant = game.get("gems") if game != null else null
		if gems is GemManager: (gems as GemManager).drop(at, value, 2)
		c.queue_free())

func _silence_step(delta: float) -> void:
	if _silence < 0.0: return
	_silence -= delta
	if _silence > 0.0: return
	_silence = -1.0
	director.spawning_paused = false
	var s: Dictionary = current.get("silencio", {})
	var n := roundi(float(s.get("horda", 16)) * LevelData.coop(director.level.coop_spawn, director.players))
	n = mini(n, WaveDirector.HARD_CAP - director.alive.size())
	for i in n:
		var d := director.pick()
		if d == null: break
		director.spawn(d, director.spawn_point(d.body_radius))
	_say(String(s.get("texto", "")), 2.0)
	if String(s.get("sonido", "")) != "": Auto.sfx(String(s.sonido))
	if game != null and game.get("net_game") != null:
		(game.get("net_game") as NetGame)._event({"k": "say", "text": String(s.get("texto", ""))})

# ---------------------------------------------------------------- lo que se ve

func _process(delta: float) -> void:
	var want := 0.0 if current.is_empty() else 1.0
	var was := _k
	_k = move_toward(_k, want, delta / FADE)
	if _k <= 0.0 and was <= 0.0: return
	var v: Dictionary = _look.get("visual", {})
	if _moon != null and v.has("moon"):                       # el color de la luna
		if _moon.light_color != _moon_wrote: _moon_base = _moon.light_color   # lo ha reescrito el ciclo de la noche
		_moon_wrote = _moon_base.lerp(_col(v.moon), float(v.get("moon_mix", 0.5)) * _k)
		_moon.light_color = _moon_wrote
	if _env != null and v.has("ambient"):                     # y el del ambiente
		if _env.ambient_light_color != _amb_wrote: _amb_base = _env.ambient_light_color
		_amb_wrote = _amb_base.lerp(_col(v.ambient), float(v.get("ambient_mix", 0.3)) * _k)
		_env.ambient_light_color = _amb_wrote
	if _env != null and v.has("fog"):                         # la niebla que se suma (el clima la reescribe)
		if not is_equal_approx(_env.fog_density, _fog_wrote): _fog_base = _env.fog_density
		_fog_wrote = _fog_base + float(v.fog) * _k
		_env.fog_density = _fog_wrote

static func _col(a: Variant) -> Color:
	var c: Array = a
	return Color(float(c[0]), float(c[1]), float(c[2]))
