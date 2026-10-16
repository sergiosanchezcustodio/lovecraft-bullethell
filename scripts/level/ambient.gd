class_name Ambient
extends Node3D
## Ambiente de los escenarios (16-10-2026, encargo del autor): lo que se mueve sin ser parte
## del combate. Los datos están en data/ambient.json:
## - por pieza ("models"), en cualquier arena: balanceo con el viento (sway.gdshader: árboles,
##   juncos), brillo animado de su capa de luz (glow_anim.gdshader: llamas que tiemblan, cristales
##   que laten, bombillas que fallan; la luz real va a la par), flotar en el mar y partículas en
##   un pivote (brasas de las hogueras, polillas de las lámparas), y faroles colgados que se mecen
##   con el viento del clima y sus rachas (swing: la parte que cuelga, con su luz). Lo aplica `dress()` al montar
##   la arena (ArenaBuilder).
## - por arena ("arenas"): noche (estrellas que titilan en el agua y los charcos y alguna fugaz),
##   bandadas de aves o murciélagos que cruzan o dan vueltas, luciérnagas, motas de luz, polvo en
##   la luz de luna, burbujas que suben en el mar, remolinos de ceniza o nieve, sin sombras de
##   nubes (interiores y grutas), gotas que caen de la bóveda (ondas en el mar, salpicaduras en la
##   roca), nieve que se desprende de las cornisas (pivotes "spill" de las rocas y del acantilado)
##   y olas que rompen contra la borda con rocío y espuma por la cubierta (que brillan con los
##   relámpagos).
## Sonido (16-10-2026): gotas, golpes de ola, crujidos de los faroles y graznidos de las
## bandadas a la vista (Sfx: drip, wave_hit, creak, bird_<ave>, en el bus Ambiente) y un bucle de
## viento por arena ("loop") que sube con las rachas del clima. La lluvia la pone Weather.
## Las ventanas que se encienden y el cristal con cielo son capas del modelo (VoxelBuilder,
## glow 2 y 3) y no necesitan nada de aquí. Las banderas, igual (parte "flag").
## Nada de esto tiene colisión ni afecta a la partida. `ambient=false` lo quita (comparar).

const PATH := "res://data/ambient.json"
const MODES := {"pulse": 1, "flame": 2, "electric": 3}
static var _cfg = null
static var _mats := {}                          ## material compartido por modelo y capa

static func config() -> Dictionary:
	if _cfg == null:
		_cfg = {}
		if FileAccess.file_exists(PATH): _cfg = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _cfg

static func enabled() -> bool:
	return not OS.get_cmdline_user_args().has("ambient=false")

static func model_cfg(model: String) -> Dictionary:
	return (config().get("models", {}) as Dictionary).get(model, {})

## Viste una pieza recién montada (ArenaBuilder): materiales con balanceo o brillo animado y
## partículas en sus pivotes. Devuelve lo que hay que animar después ({} si nada).
static func dress(holder: Node3D, m: Node3D, model: String, in_sea: bool, wind: Vector2) -> Dictionary:
	var c := model_cfg(model)
	if c.is_empty() or not enabled(): return {}
	for mi: MeshInstance3D in m.get_meta("meshes"):
		var kind := int(mi.get_meta("kind", 0))
		if c.has("sway") and kind == 0:
			mi.material_override = _sway_material(model, c, mi.material_override, wind)
		elif c.has("glow") and kind == 1:
			mi.material_override = _glow_material(model, c)
	var pivots: Dictionary = m.get_meta("pivots")
	var vs := float(m.get_meta("voxel_size"))
	for e: Dictionary in c.get("emit", []):
		var at := String(e.get("at", ""))
		if not pivots.has(at): continue
		var pv: Array = pivots[at]
		var fx := VoxelFx.emitter(String(e.recipe), float(e.get("r", 0.4)))
		fx.position = Vector3(pv[0], pv[1], pv[2]) * vs + Vector3(0, float(e.get("dy", 0.0)), 0)
		holder.add_child(fx)
	var out := {}
	if c.has("bob") and in_sea: out["bob"] = float(c.bob)
	if c.has("swing") and (m.get_meta("part_nodes") as Dictionary).has(String(c.swing.get("part", ""))): out["swing"] = c.swing
	if c.has("glow"): out["glow"] = c
	return out

static func _sway_material(model: String, c: Dictionary, base: Material, wind: Vector2) -> ShaderMaterial:
	var key := "sway|%s|%s" % [model, var_to_str(wind)]
	if _mats.has(key): return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/sway.gdshader")
	m.set_shader_parameter("colors_srgb", VoxelBuilder.colors_are_srgb())
	if base is StandardMaterial3D:
		m.set_shader_parameter("roughness_v", (base as StandardMaterial3D).roughness)
		m.set_shader_parameter("specular_v", (base as StandardMaterial3D).metallic_specular)
	m.set_shader_parameter("amplitude", float(c.sway))
	m.set_shader_parameter("height", float(c.get("height", 4.0)))
	m.set_shader_parameter("speed", float(c.get("speed", 1.0)))
	m.set_shader_parameter("wind", wind.normalized())
	_mats[key] = m
	return m

static func _glow_material(model: String, c: Dictionary) -> ShaderMaterial:
	var key := "glow|" + model
	if _mats.has(key): return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/glow_anim.gdshader")
	m.set_shader_parameter("colors_srgb", VoxelBuilder.colors_are_srgb())
	m.set_shader_parameter("mode", int(MODES.get(String(c.glow), 1)))
	m.set_shader_parameter("amount", float(c.get("amount", 0.2)))
	m.set_shader_parameter("speed", float(c.get("speed", 1.0)))
	_mats[key] = m
	return m

## La misma cuenta que glow_anim.gdshader (para que la luz real tiemble con su llama).
static func anim_k(mode: int, amount: float, speed: float, t: float, s: float) -> float:
	if mode == 1: return 1.0 + amount * sin(t * speed * 1.3 + s)
	if mode == 2: return 1.0 + amount * (0.55 * sin(t * 7.3 * speed + s) * sin(t * 3.1 * speed + s * 1.7) + 0.45 * sin(t * 13.7 * speed + s * 2.3))
	var u := t / 6.5 + s * 0.13
	var slot := floorf(u)
	if _h1(slot + s) > 0.8:
		var w := (u - slot) * 6.5
		if w < 0.7: return lerpf(0.12, 1.0, float(_h1(floorf(w * 18.0) + slot * 3.0 + s) >= 0.45))
	return 1.0 - amount * 0.1 * sin(t * 50.0)

static func _h1(x: float) -> float:
	var v := sin(x * 12.9898) * 43758.5453
	return v - floorf(v)

## Semilla de una pieza (la misma que el shader: su posición en el mundo)
static func seed_of(pos: Vector3) -> float:
	var v := pos.x * 0.173 + pos.z * 0.311
	return (v - floorf(v)) * 100.0

# ------------------------------------------------------------------ nodo

var arena: Node3D
var camera: GameCamera
var cfg := {}                                   ## el de esta arena
var night := 0.0
var _rng := RandomNumberGenerator.new()
var _bobs: Array = []                           ## [holder, y0, amplitud, semilla]
var _lights: Array = []                         ## [OmniLight3D, energía, modo, amount, speed, semilla]
var _swings: Array[Dictionary] = []             ## faroles que cuelgan: parte, ángulo y velocidad
var _mats_sky: Array[ShaderMaterial] = []       ## suelo y mar: estrellas y fugaces
var _shoot_t := -1.0
var _next_shoot := 8.0
var _flocks: Array[Dictionary] = []
var _next_flock := 3.0
var _next_bubble := 4.0
var _next_whirl := 5.0
var _whirls: Array = []                         ## [emisor, dirección, vida]
var _clouds_done := false
var _next_drip := 2.0
var _drops: Array = []                          ## [gota, velocidad, y del suelo o del agua, en el mar]
var _ripples: Array = []                        ## [malla, material, vida]
var _spills: Array = []                         ## [punto del borde (mundo), hacia dónde cae]
var _next_spill := 4.0
var _sprays: Array = []                         ## [punto en la borda, base con -Z hacia la cubierta, largo]
var _next_spray := 1.5
var _lit: Array = []                            ## [emisor, tinte]: rocío y espuma que aclara el rayo
var _loop: AudioStreamPlayer
var _loop_db := -80.0
var _flash_was := 0.0
var demo := false

func setup(p_arena: Node3D, p_camera: GameCamera, arena_id: String) -> Ambient:
	arena = p_arena
	camera = p_camera
	name = "Ambient"
	cfg = (config().get("arenas", {}) as Dictionary).get(arena_id, {})
	night = float(cfg.get("night", 0.0))
	_rng.seed = hash(arena_id)
	demo = OS.get_cmdline_user_args().has("amb_demo=true")       # clips: todo enseguida
	if demo:
		_next_shoot = 1.0; _next_flock = 0.3; _next_bubble = 0.8; _next_whirl = 0.5
		_next_spill = 1.0; _next_spray = 0.5; _next_drip = 0.3
	return self

func _ready() -> void:
	if not enabled(): return
	for it: Dictionary in arena.get_meta("ambient", []):
		var h: Node3D = it.holder
		if it.has("bob"): _bobs.append([h, h.position.y, float(it.bob), seed_of(h.global_position)])
		if it.has("glow") and it.has("light"):
			var g: Dictionary = it.glow
			var l: OmniLight3D = it.light
			_lights.append([l, l.light_energy, int(MODES.get(String(g.glow), 1)), float(g.get("amount", 0.2)), float(g.get("speed", 1.0)), seed_of(h.global_position)])
		if it.has("swing"): _add_swing(h, it.swing)
	for n in ["Ground", "Sea"]:
		var mi := arena.get_node_or_null(n) as MeshInstance3D
		if mi != null and mi.material_override is ShaderMaterial:
			var sm := mi.material_override as ShaderMaterial
			sm.set_shader_parameter("night", night)
			_mats_sky.append(sm)
	var size: Vector2 = arena.get_meta("size")
	if cfg.has("fireflies"): _scatter("fireflies", cfg.fireflies, size, 1.2, Color(1, 1, 1))
	if cfg.has("motes"): _scatter("glow_motes", cfg.motes, size, 1.0, Color(1, 1, 1))
	if cfg.get("dust", false): _dust_beams()
	if cfg.has("spills"): _find_spills(cfg.spills)
	if cfg.has("spray"): _find_sprays(cfg.spray)
	if cfg.has("loop"): _start_loop(cfg.loop)

## Farol que cuelga: su parte gira sobre el gancho y se lleva la luz y el halo de niebla.
func _add_swing(h: Node3D, c: Dictionary) -> void:
	var m := h.get_child(0) as Node3D
	var part: Node3D = (m.get_meta("part_nodes") as Dictionary)[String(c.part)]
	for n in h.get_children():
		if n is OmniLight3D or n is FogVolume: n.reparent(part, true)
	var p := float(c.get("period", 1.9))
	_swings.append({"part": part, "d": Vector2.ZERO, "v": Vector2.ZERO, "seed": seed_of(h.global_position),
		"k": pow(TAU / p, 2.0), "deg": float(c.get("deg", 0.65)), "max": deg_to_rad(float(c.get("max", 28.0))),
		"turb": float(c.get("turb", 0.8)), "inv": h.global_basis.orthonormalized().inverse()})

## Péndulo amortiguado empujado por el viento: se inclina a sotavento tanto más cuanto más
## sopla, y la turbulencia (cerca de su frecuencia propia) lo mece; las rachas lo agitan más.
func _swing_step(delta: float, t: float) -> void:
	var g := get_parent()
	var wv := Vector3.ZERO
	if g != null and "weather" in g and g.weather != null: wv = (g.weather as Weather).wind_now()
	var w := Vector2(wv.x, wv.z)
	var along := w.normalized() if w.length() > 0.01 else Vector2.RIGHT
	var side := Vector2(-along.y, along.x)
	var dt := minf(delta, 0.05)
	for s: Dictionary in _swings:
		var sd: float = s.seed
		var a: float = deg_to_rad(s.deg) * w.length()
		var turb: float = s.turb
		var target: Vector2 = along * a * (1.0 + turb * (0.7 * sin(t * 3.1 + sd) + 0.3 * sin(t * 1.9 + sd * 1.7))) 			+ side * a * turb * 0.45 * sin(t * 2.6 + sd * 2.3)
		var acc: Vector2 = -(s.k as float) * ((s.d as Vector2) - target) - 0.7 * (s.v as Vector2)
		s.v += acc * dt
		s.d = (s.d as Vector2) + (s.v as Vector2) * dt
		s.d = (s.d as Vector2).limit_length(s.max)
		var d: Vector2 = s.d
		var part: Node3D = s.part
		var out_now := (s.v as Vector2).dot(d) > 0.0                    # se aleja del centro
		if s.get("out", false) and not out_now and d.length() > deg_to_rad(9.0) and _rng.randf() < 0.25:
			var gp := part.global_position
			var f := _focus()
			if Vector2(gp.x - f.x, gp.z - f.z).length() < 12.0: Sfx.play("creak")
		s["out"] = out_now
		if d.length() < 0.0005:
			part.basis = Basis.IDENTITY
			continue
		var axis: Vector3 = (s.inv as Basis) * Vector3(d.x, 0, d.y).cross(Vector3.UP)   # la punta va hacia d
		part.basis = Basis(axis.normalized(), d.length())

## N emisores repartidos por la arena (luciérnagas sobre el agua, motas de luz)
func _scatter(recipe: String, c: Dictionary, size: Vector2, y: float, tint: Color) -> void:
	var obstacles: ObstacleMap = arena.get_meta("obstacles")
	for k in int(c.get("n", 6)):
		var p := Vector2.ZERO
		for attempt in 20:
			p = Vector2(_rng.randf_range(-0.45, 0.45) * size.x, _rng.randf_range(-0.45, 0.45) * size.y)
			if recipe != "fireflies" or obstacles.water_at(p) > 0.0 or attempt > 12: break
		var e := VoxelFx.emitter(recipe, float(c.get("r", 4.0)), false, false, tint)
		e.position = Vector3(p.x, y, p.y)
		e.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 6, 16))
		add_child(e)

## Polvo en la luz de luna delante de los ventanales del estudio
func _dust_beams() -> void:
	for h: Node in arena.get_node("Props").get_children():
		var m := h.get_child(0) as Node3D
		if m == null or not String(m.name).begins_with("prv_muro") or String(m.name) == "prv_muro_bajo": continue
		for x in [-4.0, 0.0, 4.0]:
			var e := VoxelFx.emitter("dust_beam", 2.0)
			e.position = (h as Node3D).transform * Vector3(x, 1.6, 2.2)
			add_child(e)

func _process(delta: float) -> void:
	if not enabled(): return
	var t := fmod(Time.get_ticks_msec() / 1000.0, 3600.0)       # el TIME de los shaders
	for b: Array in _bobs:
		var h: Node3D = b[0]
		var s: float = b[3]
		h.position.y = b[1] + sin(t * 0.9 + s) * b[2]
		h.rotation.x = sin(t * 0.7 + s * 1.3) * b[2] * 0.5
		h.rotation.z = sin(t * 0.8 + s * 0.7) * b[2] * 0.5
	for l: Array in _lights:
		(l[0] as OmniLight3D).light_energy = l[1] * anim_k(l[2], l[3], l[4], t, l[5])
	if not _swings.is_empty(): _swing_step(delta, t)
	if not _clouds_done:
		_clouds_done = true
		var g := get_parent()
		if not bool(cfg.get("clouds", true)) and g != null and "weather" in g and g.weather != null: g.weather.hide_clouds()
	if night > 0.0: _shooting(delta)
	if cfg.has("birds"): _birds(delta, t)
	if cfg.has("bubbles"): _bubbles(delta)
	if cfg.has("whirls"): _whirl_step(delta)
	if cfg.has("drips"): _drip_step(delta)
	if not _spills.is_empty(): _spill_step(delta)
	if not _sprays.is_empty(): _spray_step(delta)
	if _loop != null: _loop_step(delta)
	if not _lit.is_empty() or _flash_was > 0.0: _flash_step()

func _focus() -> Vector3:
	return camera.center() if camera != null else Vector3.ZERO

# ------------------------------------------------------------------ estrellas fugaces

func _shooting(delta: float) -> void:
	if _shoot_t >= 0.0:
		_shoot_t += delta
		if _shoot_t > 1.3: _shoot_t = -1.0
	else:
		_next_shoot -= delta
		if _next_shoot <= 0.0:
			_next_shoot = _rng.randf_range(12.0, 30.0) if not demo else 3.0
			var f := _focus()
			var a := _rng.randf() * TAU
			var start := Vector2(f.x, f.z) + Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-6, 6))
			var d := Vector2(cos(a), sin(a)) * _rng.randf_range(6.0, 10.0)
			for sm in _mats_sky: sm.set_shader_parameter("shoot", Vector4(start.x - d.x * 0.5, start.y - d.y * 0.5, d.x, d.y))
			_shoot_t = 0.0
	for sm in _mats_sky: sm.set_shader_parameter("shoot_t", _shoot_t)

# ------------------------------------------------------------------ burbujas y remolinos

## Algo respira bajo el agua: burbujas en un punto del mar a la vista
func _bubbles(delta: float) -> void:
	_next_bubble -= delta
	if _next_bubble > 0.0: return
	_next_bubble = float(cfg.bubbles) * _rng.randf_range(0.6, 1.4) * (0.3 if demo else 1.0)
	var size: Vector2 = arena.get_meta("size")
	var f := _focus()
	for attempt in 12:
		var p := Vector2(f.x + _rng.randf_range(-12, 12), f.z + _rng.randf_range(-9, 9))
		var obstacles: ObstacleMap = arena.get_meta("obstacles")
		var sea: bool = arena.get_node_or_null("Sea") != null and (p.x > size.x * 0.5 + 1.5 or p.y > size.y * 0.5 + 1.5)
		if sea or obstacles.water_at(p) > 0.5:
			var y: float = (arena.get_node("Sea") as Node3D).position.y + 0.05 if sea else 0.04
			var e := VoxelFx.emitter("sea_bubbles", _rng.randf_range(0.2, 0.45), true)
			e.position = Vector3(p.x, y, p.y)
			add_child(e)
			get_tree().create_timer(2.5).timeout.connect(e.queue_free)
			return

## Remolino de ceniza o nieve que cruza un trozo de suelo y se deshace
func _whirl_step(delta: float) -> void:
	_next_whirl -= delta
	if _next_whirl <= 0.0 and _whirls.size() < 2:
		_next_whirl = float(cfg.whirls) * _rng.randf_range(0.6, 1.4)
		var f := _focus()
		var tc: Array = cfg.get("whirl_tint", [0.5, 0.5, 0.5])
		var e := VoxelFx.emitter("whirl", 1.2, false, false, Color(tc[0] * 2.0, tc[1] * 2.0, tc[2] * 2.0))
		e.position = Vector3(f.x + _rng.randf_range(-9, 9), 0.05, f.z + _rng.randf_range(-7, 7))
		add_child(e)
		var a := _rng.randf() * TAU
		_whirls.append([e, Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.8, 1.6), _rng.randf_range(6.0, 10.0)])
	for w: Array in _whirls.duplicate():
		var e: GPUParticles3D = w[0]
		e.position += (w[1] as Vector3) * delta
		w[2] -= delta
		if w[2] <= 0.0 and e.emitting:
			e.emitting = false
			get_tree().create_timer(2.0).timeout.connect(e.queue_free)
			_whirls.erase(w)

# ------------------------------------------------------------------ sonido de fondo y rayos

func _weather() -> Weather:
	var g := get_parent()
	return g.weather as Weather if g != null and "weather" in g and g.weather != null else null

## Bucle de viento de la arena (sin costura: tools/gen_sfx.py --ambiente), con fundido de entrada.
func _start_loop(c: Dictionary) -> void:
	if Sfx.muted: return
	var path := "res://resources/sfx/%s" % String(c.get("file", "wind_loop.wav"))
	if not ResourceLoader.exists(path): return
	var st := (load(path) as AudioStreamWAV).duplicate() as AudioStreamWAV
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = int(st.get_length() * st.mix_rate)
	_loop = AudioStreamPlayer.new()
	_loop.stream = st
	_loop.bus = "Ambiente" if AudioServer.get_bus_index("Ambiente") >= 0 else "Master"
	_loop.volume_db = -60.0
	_loop.pitch_scale = float(c.get("pitch", 1.0))
	add_child(_loop)
	_loop.play(_rng.randf() * st.get_length())

## Las rachas del clima lo suben (hasta unos 8 dB) y lo afinan un poco.
func _loop_step(delta: float) -> void:
	var c: Dictionary = cfg.loop
	var target := float(c.get("db", -20.0))
	var pitch := float(c.get("pitch", 1.0))
	var w := _weather()
	if w != null and w.data != null and float(c.get("gusts", 1.0)) > 0.0:
		var ratio := w.wind_now().length() / maxf(w.data.wind, 0.1)
		target += 6.0 * log(maxf(ratio, 0.5)) / log(2.0) * float(c.get("gusts", 1.0))
		pitch *= 1.0 + 0.05 * (ratio - 1.0)
	_loop_db = lerpf(_loop_db, target, minf(delta * (0.6 if _loop_db < target - 20.0 else 2.0), 1.0))
	_loop.volume_db = _loop_db
	_loop.pitch_scale = lerpf(_loop.pitch_scale, pitch, minf(delta * 2.0, 1.0))

## El rayo aclara un instante el rocío y la espuma (sin luz propia, no los alcanza la del rayo).
func _flash_step() -> void:
	var w := _weather()
	var k: float = w.flash if w != null else 0.0
	_lit = _lit.filter(func(e: Array) -> bool: return is_instance_valid(e[0]))
	if k <= 0.001 and _flash_was <= 0.001: return
	_flash_was = k
	for e: Array in _lit:
		var t: Color = e[1]
		var f := 1.0 + 2.2 * k
		((e[0] as GPUParticles3D).process_material as ParticleProcessMaterial).color = Color(t.r * f, t.g * f, t.b * f, t.a)

func _lit_emitter(recipe: String, r: float, tint := Color.WHITE) -> GPUParticles3D:
	var e := VoxelFx.emitter(recipe, r, true, true, tint)
	_lit.append([e, tint])
	return e

# ------------------------------------------------------------------ gotas de la bóveda

## Una gota cae de la bóveda (fuera de la vista) y, al llegar, salpica y deja ondas en el mar o,
## más pequeñas, en la roca mojada.
func _drip_step(delta: float) -> void:
	var c: Dictionary = cfg.drips
	_next_drip -= delta
	if _next_drip <= 0.0:
		var ev: Array = c.get("every", [0.6, 1.5])
		_next_drip = _rng.randf_range(ev[0], ev[1]) * (0.4 if demo else 1.0)
		var size: Vector2 = arena.get_meta("size")
		var obstacles: ObstacleMap = arena.get_meta("obstacles")
		var sea_node := arena.get_node_or_null("Sea") as Node3D
		var f := _focus()
		var want_sea := _rng.randf() < float(c.get("sea", 0.5))
		for attempt in 12:
			var p := Vector2(f.x + _rng.randf_range(-12, 12), f.z + _rng.randf_range(-9, 9))
			var sea: bool = sea_node != null and (p.x > size.x * 0.5 + 1.0 or p.y > size.y * 0.5 + 1.0)
			if want_sea != sea and attempt < 10: continue
			if not sea and obstacles.is_blocked(p, 0.1): continue
			var y: float = sea_node.position.y + 0.06 if sea else 0.02
			var d := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.025, 0.12, 0.025)
			bm.material = _drop_material()
			d.mesh = bm
			d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			d.position = Vector3(p.x, y + float(c.get("h", 6.0)), p.y)
			add_child(d)
			_drops.append([d, 0.0, y, sea])
			break
	for dr: Array in _drops.duplicate():
		var d: MeshInstance3D = dr[0]
		dr[1] += 9.8 * delta
		d.position.y -= float(dr[1]) * delta
		if d.position.y > float(dr[2]): continue
		var at := Vector3(d.position.x, dr[2], d.position.z)
		d.queue_free()
		_drops.erase(dr)
		var sp := VoxelFx.emitter("drip_splash", 0.1, true)
		sp.position = at + Vector3(0, 0.02, 0)
		add_child(sp)
		get_tree().create_timer(0.8).timeout.connect(sp.queue_free)
		_ripple(at, 0.55 if dr[3] else 0.3, 0.8 if dr[3] else 0.45)          # en la roca, la película de agua del suelo
		var near := Vector2(at.x - _focus().x, at.z - _focus().z).length()
		Sfx.play("drip", -clampf((near - 4.0) * 0.8, 0.0, 10.0))       # las lejanas, más bajas
	for r: Array in _ripples.duplicate():
		r[2] += delta / 1.6
		(r[1] as ShaderMaterial).set_shader_parameter("life", r[2])
		if r[2] >= 1.0:
			(r[0] as Node).queue_free()
			_ripples.erase(r)

static func _drop_material() -> StandardMaterial3D:
	if not _mats.has("drop"):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.5, 0.58, 0.66, 0.75)
		_mats["drop"] = m
	return _mats["drop"]

func _ripple(at: Vector3, radius: float, alpha: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * radius * 2.2
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/ripple.gdshader")
	m.set_shader_parameter("radius", radius)
	m.set_shader_parameter("tint", Color(0.42, 0.5, 0.58, alpha))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at
	add_child(mi)
	_ripples.append([mi, m, 0.0])

# ------------------------------------------------------------------ nieve de las cornisas

## Bordes con nieve (pivotes "spill" de las piezas y del acantilado) que miran a la cámara.
func _find_spills(c: Dictionary) -> void:
	var models: Array = c.get("models", [])
	var holders: Array = []
	for h: Node in arena.get_node("Props").get_children():
		var m := h.get_child(0) as Node3D
		if m != null and String(m.name) in models: holders.append(h)
	var barrier := arena.get_node_or_null("Barrier")
	if barrier != null and c.get("barrier", false): holders.append_array(barrier.get_children())
	var cam_dir := Vector3(1, 0, 1).normalized()
	for h: Node in holders:
		var m := h.get_child(0) as Node3D if h.get_child_count() > 0 else null
		if m == null or not m.has_meta("pivots"): continue                  # la meseta de detrás no es una pieza
		var vs := float(m.get_meta("voxel_size"))
		var piv: Dictionary = m.get_meta("pivots")
		for k: String in piv:
			if not k.begins_with("spill"): continue
			var pv: Array = piv[k]
			var p := m.global_transform * (Vector3(pv[0], pv[1], pv[2]) * vs)
			var out := (m.global_basis * Vector3(pv[3], 0, pv[4]))
			out = Vector3(out.x, 0, out.z).normalized()
			if out.dot(cam_dir) > 0.25: _spills.append([p, out])

func _spill_step(delta: float) -> void:
	_next_spill -= delta
	if _next_spill > 0.0: return
	var ev: Array = cfg.spills.get("every", [5, 12])
	_next_spill = _rng.randf_range(ev[0], ev[1]) * (0.3 if demo else 1.0)
	var f := _focus()
	var seen: Array = []
	for s: Array in _spills:                                       # a la vista: lo alto sube en pantalla
		var p: Vector3 = s[0]
		var d := Vector2(p.x - f.x, p.z - f.z) - Vector2(1, 1).normalized() * p.y * 1.73
		var across := absf(d.dot(Vector2(1, -1).normalized()))           # de lado en la pantalla
		var depth := absf(d.dot(Vector2(1, 1).normalized()))             # arriba y abajo (el doble de suelo)
		if across < 11.0 and depth < 12.0 and p.y > 0.6: seen.append(s)
	if seen.is_empty(): return
	var s: Array = seen[_rng.randi() % seen.size()]
	var top: Vector3 = s[0]
	var out: Vector3 = s[1]
	var r := _rng.randf_range(0.7, 1.4)
	var e := VoxelFx.emitter("snow_spill", r, true)
	e.position = top
	e.basis = Basis.looking_at(-out, Vector3.UP)                   # +Z de la receta hacia fuera
	add_child(e)
	get_tree().create_timer(2.5).timeout.connect(e.queue_free)
	var fall := sqrt(2.0 * maxf(top.y, 0.2) / 4.0)
	get_tree().create_timer(fall * 0.8).timeout.connect(_snow_puff.bind(Vector3(top.x, 0.15, top.z) + out * 0.35, r))

func _snow_puff(at: Vector3, r: float) -> void:
	var pf := VoxelFx.emitter("snow_puff", r * 0.7, true, false, Color(1.15, 1.2, 1.3, 0.7))
	pf.position = at
	add_child(pf)
	get_tree().create_timer(1.8).timeout.connect(pf.queue_free)

# ------------------------------------------------------------------ olas contra la borda

## Tramos de borda: punto en lo alto y hacia dónde queda la cubierta.
func _find_sprays(c: Dictionary) -> void:
	var model := String(c.get("model", ""))
	for h: Node in arena.get_node("Props").get_children():
		var m := h.get_child(0) as Node3D
		if m == null or String(m.name) != model: continue
		var hn := h as Node3D
		var center := Vector3(-hn.global_position.x, 0, -hn.global_position.z).normalized()
		var best := Vector3.ZERO
		for ax: Vector3 in [hn.global_basis.x, -hn.global_basis.x, hn.global_basis.z, -hn.global_basis.z]:
			var a := Vector3(ax.x, 0, ax.z).normalized()
			if best == Vector3.ZERO or a.dot(center) > best.dot(center): best = a
		var aabb := _world_aabb(hn)
		# la borda queda a la altura del mar (más allá de la orilla): el rocío salta a la de la cubierta
		var top := Vector3(hn.global_position.x, maxf(aabb.end.y, 0.0) + 0.2, hn.global_position.z) - best * 0.25
		_sprays.append([top, Basis.looking_at(best, Vector3.UP), maxf(aabb.size.x, aabb.size.z)])

static func _world_aabb(h: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi: MeshInstance3D in h.find_children("*", "MeshInstance3D", true, false):
		var b := mi.global_transform * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out

func _spray_step(delta: float) -> void:
	_next_spray -= delta
	if _next_spray > 0.0: return
	var ev: Array = cfg.spray.get("every", [1.2, 3.5])
	_next_spray = _rng.randf_range(ev[0], ev[1]) * (0.5 if demo else 1.0)
	var f := _focus()
	var seen: Array = []
	for s: Array in _sprays:
		var p: Vector3 = s[0]
		if Vector2(p.x, p.z).distance_to(Vector2(f.x, f.z)) < 13.0: seen.append(s)
	if seen.is_empty(): return
	var s: Array = seen[_rng.randi() % seen.size()]
	var b: Basis = s[1]
	var at: Vector3 = (s[0] as Vector3) + b.x * _rng.randf_range(-0.35, 0.35) * float(s[2])
	var r := _rng.randf_range(1.2, 2.6)                            # unas rompen más fuerte que otras
	var sp := _lit_emitter("spray", r)
	sp.position = at
	sp.basis = b
	add_child(sp)
	get_tree().create_timer(1.8).timeout.connect(sp.queue_free)
	Sfx.play("wave_hit", (r - 2.6) * 3.0)                          # las flojas suenan menos
	var crest := _lit_emitter("snow_puff", r * 0.45, Color(1.3, 1.38, 1.45, 0.55))   # la cresta asoma por la borda
	crest.position = at
	add_child(crest)
	get_tree().create_timer(1.6).timeout.connect(crest.queue_free)
	get_tree().create_timer(0.5).timeout.connect(_foam.bind(Vector3(at.x, 0.05, at.z) - b.z * 0.4, b, r))

## Espuma por la cubierta cuando cae el rocío (-Z de la base hacia dentro).
func _foam(at: Vector3, b: Basis, r: float) -> void:
	var fo := _lit_emitter("foam", r)
	fo.position = at
	fo.basis = b
	add_child(fo)
	get_tree().create_timer(2.2).timeout.connect(fo.queue_free)

# ------------------------------------------------------------------ bandadas

const BIRD_SPEED := {"petrel": 6.5, "skua": 6.0, "gull": 5.0, "crow": 5.5, "bat": 7.0}
const BIRD_FLAP := {"petrel": 4.5, "skua": 3.6, "gull": 3.0, "crow": 4.2, "bat": 10.0}

func _birds(delta: float, t: float) -> void:
	var c: Dictionary = cfg.birds
	_next_flock -= delta
	if _next_flock <= 0.0 and _flocks.size() < 2:
		var ev: Array = c.get("every", [10, 20])
		_next_flock = _rng.randf_range(ev[0], ev[1]) if not demo else 4.0
		_spawn_flock(c)
	var f := _focus()
	for fl: Dictionary in _flocks.duplicate():
		fl.t += delta
		var kind := String(fl.kind)
		var v: float = fl.speed
		var center: Vector3
		var dir: Vector3
		if fl.t < fl.circle_time:                                   # vueltas sobre un punto
			var ang: float = fl.a0 + fl.t * v / fl.radius * fl.turn
			center = fl.c + Vector3(cos(ang), 0, sin(ang)) * fl.radius
			dir = Vector3(-sin(ang), 0, cos(ang)) * fl.turn
			fl.p = center
			fl.dir = dir
		else:
			fl.p += (fl.dir as Vector3) * v * delta
			center = fl.p
			dir = fl.dir
		if fl.storm:                                                # contra la tormenta: el viento lo zarandea
			center += Vector3(sin(fl.t * 2.1) * 1.2, sin(fl.t * 3.3) * 0.6, cos(fl.t * 1.7) * 0.8)
		var basis := Basis.looking_at(dir.normalized(), Vector3.UP)
		for i in (fl.members as Array).size():
			var b: Node3D = fl.members[i]
			var off: Vector3 = fl.offsets[i]
			var ph: float = fl.phases[i]
			var p := center + basis * off
			if kind == "bat":                                       # vuelo quebrado
				p += basis * Vector3(sin(fl.t * 5.0 + ph) * 0.6, sin(fl.t * 7.0 + ph * 2.0) * 0.4, 0)
			p.y = fl.h + off.y + sin(fl.t * 0.8 + ph) * 0.25
			b.position = p
			var bank: float = -0.35 * float(fl.turn) if fl.t < fl.circle_time else sin(fl.t * 0.9 + ph) * 0.12
			b.basis = basis * Basis(Vector3(0, 0, 1), bank)
			_flap(b, kind, t + ph, fl.t + ph)
		fl.next_call -= delta                                            # graznan de vez en cuando, si se les ve
		var dist := Vector2(center.x - f.x, center.z - f.z).length()
		if fl.next_call <= 0.0:
			fl.next_call = _rng.randf_range(2.0, 5.0) if kind == "bat" else _rng.randf_range(3.5, 9.0)
			if dist < 15.0: Sfx.play("bird_" + kind, -dist * 0.4)
		var gone: bool = dist > 34.0 and fl.t > fl.circle_time
		if gone or fl.t > 90.0:
			for b: Node3D in fl.members: b.queue_free()
			_flocks.erase(fl)

func _spawn_flock(c: Dictionary) -> void:
	var kinds: Array = c.get("kinds", ["gull"])
	var kind := String(kinds[_rng.randi() % kinds.size()])
	var sz: Array = c.get("size", [2, 5])
	var hh: Array = c.get("height", [6, 9])
	var n := _rng.randi_range(int(sz[0]), int(sz[1]))
	var f := _focus()
	var a := _rng.randf() * TAU
	var dir := Vector3(cos(a), 0, sin(a))
	var side := Vector3(-dir.z, 0, dir.x)
	var fl := {"kind": kind, "t": 0.0, "speed": float(BIRD_SPEED.get(kind, 5.0)) * _rng.randf_range(0.85, 1.15),
		"h": _rng.randf_range(hh[0], hh[1]), "members": [], "offsets": [], "phases": [], "storm": bool(c.get("storm", false)),
		"circle_time": 0.0, "radius": 1.0, "a0": 0.0, "turn": 1.0, "c": f, "p": f - dir * 30.0 + side * _rng.randf_range(-8, 8), "dir": dir,
		"next_call": _rng.randf_range(1.0, 4.0)}
	if _rng.randf() < float(c.get("circle", 0.0)):                 # dan vueltas un rato y se van
		fl.circle_time = _rng.randf_range(10.0, 20.0)
		fl.radius = _rng.randf_range(5.0, 8.0)
		fl.c = f + Vector3(_rng.randf_range(-5, 5), 0, _rng.randf_range(-4, 4))
		fl.a0 = _rng.randf() * TAU
		fl.turn = 1.0 if _rng.randf() < 0.5 else -1.0
		fl.p = fl.c + Vector3(cos(fl.a0), 0, sin(fl.a0)) * fl.radius
	for i in n:
		var b := Node3D.new()
		var m := VoxelBuilder.load_model("res://models/amb_%s.json" % kind)
		for mi: MeshInstance3D in m.get_meta("meshes"):            # sin sombra: a 8 m, la sombra nítida parecía otro pájaro
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.add_child(m)
		add_child(b)
		fl.members.append(b)
		var row := (i + 1) / 2
		var s := -1.0 if i % 2 else 1.0
		var off := Vector3(s * row * 1.1, _rng.randf_range(-0.4, 0.4), row * 1.3) if kind in ["petrel", "gull", "skua"] \
			else Vector3(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-0.8, 0.8), _rng.randf_range(-2.0, 2.0))
		if i == 0: off = Vector3.ZERO
		fl.offsets.append(off + Vector3(_rng.randf_range(-0.3, 0.3), 0, _rng.randf_range(-0.3, 0.3)))
		fl.phases.append(_rng.randf() * TAU)
	_flocks.append(fl)

## Aleteo: las alas giran sobre el hombro; gaviotas y págalos planean a ratos.
func _flap(b: Node3D, kind: String, t: float, ft: float) -> void:
	var m := b.get_child(0)
	var nodes: Dictionary = m.get_meta("part_nodes")
	var freq: float = BIRD_FLAP.get(kind, 4.0)
	var amp := 0.75 if kind == "bat" else 0.55
	if kind in ["gull", "skua", "petrel"] and fmod(ft, 4.5) > 2.2:   # planeo con las alas algo altas
		amp = 0.06
	var ang := sin(t * freq * TAU) * amp + (0.12 if amp < 0.1 else 0.0)
	if nodes.has("wing_r"): (nodes["wing_r"] as Node3D).rotation.z = ang
	if nodes.has("wing_l"): (nodes["wing_l"] as Node3D).rotation.z = -ang
