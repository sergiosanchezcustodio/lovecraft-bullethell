class_name Ambient
extends Node3D
## Ambiente de los escenarios (16-10-2026, encargo del autor): lo que se mueve sin ser parte
## del combate. Los datos están en data/ambient.json:
## - por pieza ("models"), en cualquier arena: balanceo con el viento (sway.gdshader: árboles,
##   juncos), brillo animado de su capa de luz (glow_anim.gdshader: llamas que tiemblan, cristales
##   que laten, bombillas que fallan; la luz real va a la par), flotar en el mar y partículas en
##   un pivote (brasas de las hogueras, polillas de las lámparas). Lo aplica `dress()` al montar
##   la arena (ArenaBuilder).
## - por arena ("arenas"): noche (estrellas que titilan en el agua y los charcos y alguna fugaz),
##   bandadas de aves o murciélagos que cruzan o dan vueltas, luciérnagas, motas de luz, polvo en
##   la luz de luna, burbujas que suben en el mar, remolinos de ceniza o nieve y sin sombras de
##   nubes (interiores y grutas).
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
var _mats_sky: Array[ShaderMaterial] = []       ## suelo y mar: estrellas y fugaces
var _shoot_t := -1.0
var _next_shoot := 8.0
var _flocks: Array[Dictionary] = []
var _next_flock := 3.0
var _next_bubble := 4.0
var _next_whirl := 5.0
var _whirls: Array = []                         ## [emisor, dirección, vida]
var _clouds_done := false
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
	if not _clouds_done:
		_clouds_done = true
		var g := get_parent()
		if not bool(cfg.get("clouds", true)) and g != null and "weather" in g and g.weather != null: g.weather.hide_clouds()
	if night > 0.0: _shooting(delta)
	if cfg.has("birds"): _birds(delta, t)
	if cfg.has("bubbles"): _bubbles(delta)
	if cfg.has("whirls"): _whirl_step(delta)

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
		var gone: bool = Vector2(center.x - f.x, center.z - f.z).length() > 34.0 and fl.t > fl.circle_time
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
		"circle_time": 0.0, "radius": 1.0, "a0": 0.0, "turn": 1.0, "c": f, "p": f - dir * 30.0 + side * _rng.randf_range(-8, 8), "dir": dir}
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
