class_name PolypWinds
extends Node
## Las trampillas de la Gran Raza y los pólipos voladores (hito 21.15, «La sombra fuera del tiempo»):
## - Trampillas: las de la arena (`trapdoors` en su JSON). Cada `LevelData.trap_every` s (más a menudo
##   con el jefe suelto, `trap_final_every`) una cerrada empieza a silbar: su tapa tiembla `trap_warn` s
##   y se abre. Abierta, sopla un viento que aparta a los que se acercan (en medio, calma) y suelta un
##   `trap_enemy` cada `trap_spawn_every` s, hasta `trap_spawn_cap`. Se sella de pie en medio
##   `trap_seal` s (con varios, antes; Peaslee, que las vio en sueños, ×1,6); si se sale, lo hecho se
##   pierde despacio. También se puede sellar mientras silba, y entonces no llega a abrirse. Sellada,
##   suelta unas gemas.
## - La gran trampilla del archivo (`great_door`): de ahí sube el jefe, y sopla mientras vive.
## - Los pólipos (`polyp` en sus parámetros) casi no se ven: más cuanto más cerca de alguien de este
##   PC, y del todo un momento al recibir un golpe. Los delata su remolino de arena (un MultiMesh de
##   granos que giran alrededor) y su silbido (PolypBehavior). El jefe, sin cuerpo, levanta uno enorme.
## - El aliento del jefe (`pull`): durante unos segundos tira de todos hacia él.
## En red, lo que se abre y se sella y el aliento los decide el anfitrión (suceso "trap"); el viento y
## lo que se ve, cada PC con sus jugadores.

enum State { CLOSED, WARN, OPEN }

const SEAL_R := 1.7                    ## m: en medio, para sellarla
const PEASLEE := 1.6
const DECAY := 0.3                     ## lo sellado que se pierde por segundo si no hay nadie
const CALM := 0.9                      ## m: en medio, sin viento
const LID_SLIDE := 1.5                 ## m que se aparta la tapa
const GREAT_SCALE := 2.0
const SAND := Color(0.80, 0.62, 0.42)
const SEAL_COLOR := Color(0.95, 0.80, 0.42)
const DUST := Color(0.86, 0.68, 0.48)    ## la arena que sopla (receta "steam", blanca, teñida)
const GRAINS := 12                     ## granos del remolino de cada pólipo
const BOSS_GRAINS := 48
const MAX_GRAINS := 720
const SEE_NEAR := 2.6                  ## m: a esta distancia se ve del todo
const SEE_FAR := 7.0                   ## m: desde aquí, casi nada
const MIN_ALPHA := 0.06
const MAX_ALPHA := 0.72
const HIT_SHOW := 1.1                  ## s que se ve tras un golpe
const SWIRL_PUSH := 0.9                ## m/s que empuja de lado el remolino de un pólipo, de cerca
const SWIRL_R := 2.0

static var current: PolypWinds

var world: CombatWorld
var level: LevelData
var host := true
var game: Node
var doors: Array[Dictionary] = []      ## {i, pos: Vector2, state, t, seal, spawned, spawn_t, lid, ring, fill, fx_t, wh_t, big}
var great := Vector2.INF               ## la gran trampilla
var great_door: Dictionary = {}        ## la gran trampilla, como las demás (no se sella)
var opened := 0                        ## veces que se ha abierto una (tests)
var sealed := 0                        ## veces que se ha sellado una (tests)
var released := 0                      ## pólipos que han salido (tests)
var pull_at := Vector3.INF             ## el aliento del jefe: hacia dónde
var pull_t := 0.0
var pull_force := 0.0
var _next := 0.0
var _seen := {}                        ## Enemy -> [vida la última vez, s que le quedan a la vista, alfa puesto]
var _mm: MultiMeshInstance3D
var _spin := 0.0
var _rng := RandomNumberGenerator.new()

func setup(p_world: CombatWorld, p_level: LevelData, p_host: bool, p_game: Node = null) -> PolypWinds:
	name = "PolypWinds"
	world = p_world; level = p_level; host = p_host; game = p_game
	_next = (level.trap_every if level != null else 0.0) * 0.5
	_rng.randomize()
	current = self
	var layout := {}
	if level != null and FileAccess.file_exists(level.arena):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(level.arena))
		if j is Dictionary: layout = j
	for p in layout.get("trapdoors", []):
		add_door(Vector2(float(p[0]), float(p[1])))
	var g: Array = layout.get("great_door", [])
	if g.size() == 2: great = Vector2(float(g[0]), float(g[1]))
	return self

func _exit_tree() -> void:
	if current == self: current = null

func _ready() -> void:
	for d in doors: _dress(d)
	if great != Vector2.INF:
		great_door = _door(-1, great, true)
		_dress(great_door)

## Una trampilla más (las de la arena; también para las pruebas).
func add_door(at: Vector2) -> Dictionary:
	var d := _door(doors.size(), at, false)
	doors.append(d)
	if is_inside_tree(): _dress(d)
	return d

func _door(i: int, at: Vector2, big: bool) -> Dictionary:
	return {"i": i, "pos": at, "state": State.CLOSED, "t": 0.0, "seal": 0.0, "spawned": 0, "spawn_t": 1.5,
		"lid": null, "ring": null, "fill": null, "fx_t": 0.0, "wh_t": 0.0, "big": big}

## s hasta la próxima: más a menudo con el jefe suelto.
func every() -> float:
	if level == null: return 0.0
	if level.trap_final_every > 0.0 and boss_alive(): return level.trap_final_every
	return level.trap_every

func boss_alive() -> bool:
	for e in world.enemies:
		if e is Enemy and is_instance_valid(e) and e.is_alive() and (e as Enemy).behavior is PolypBossBehavior: return true
	return false

## ¿Hay un pólipo a menos de `r` m de alguien de este PC? (el consejo)
func polyp_near(r: float) -> bool:
	for e in world.enemies:
		if not (e is Enemy) or not is_instance_valid(e) or not e.is_alive(): continue
		if not bool((e as Enemy).data.param("polyp", false)) or (e as Enemy).data.unique: continue
		for q in world.players:
			if not q.remote and q.global_position.distance_to(e.global_position) < r: return true
	return false

func open_count() -> int:
	return doors.filter(func(d: Dictionary) -> bool: return d.state != State.CLOSED).size()

# ------------------------------------------------------------------ lógica

func _physics_process(delta: float) -> void:
	if host:
		var ev := every()
		if ev > 0.0 and not doors.is_empty():
			_next -= delta
			if _next <= 0.0:
				_next = ev * _rng.randf_range(0.8, 1.2)
				if open_count() < (level.trap_max if level != null else 3): warn_random()
	for d in doors: _step_door(d, delta)
	if pull_t > 0.0: pull_t -= delta
	_winds(delta)

func _step_door(d: Dictionary, delta: float) -> void:
	if d.state == State.CLOSED:
		d.seal = 0.0
		return
	d.t = float(d.t) - delta
	if d.state == State.WARN and host and float(d.t) <= 0.0: open_door(int(d.i))
	# sellar: quien está de pie en medio (vivo y sin caer)
	var rate := 0.0
	for q in world.players:
		if q.health <= 0.0 or q.is_downed(): continue
		if Vector2(q.global_position.x, q.global_position.z).distance_to(d.pos) > SEAL_R: continue
		rate += PEASLEE if q.data != null and q.data.id == &"peaslee" else 1.0
	var need := level.trap_seal if level != null else 2.5
	if rate > 0.0: d.seal = minf(1.0, float(d.seal) + rate * delta / maxf(need, 0.1))
	else: d.seal = maxf(0.0, float(d.seal) - DECAY * delta)
	if host and float(d.seal) >= 1.0:
		seal_door(int(d.i))
		return
	if d.state == State.OPEN and host and level != null and level.trap_enemy != null:
		d.spawn_t = float(d.spawn_t) - delta
		if float(d.spawn_t) <= 0.0 and int(d.spawned) < level.trap_spawn_cap:
			d.spawn_t = level.trap_spawn_every * _rng.randf_range(0.8, 1.2)
			d.spawned = int(d.spawned) + 1
			_release(d)

## Una cerrada al azar empieza a silbar (anfitrión).
func warn_random() -> void:
	var shut := doors.filter(func(d: Dictionary) -> bool: return d.state == State.CLOSED)
	if shut.is_empty(): return
	warn_door(int(shut[_rng.randi() % shut.size()].i))

func warn_door(i: int) -> void:
	if i < 0 or i >= doors.size() or doors[i].state != State.CLOSED: return
	var d := doors[i]
	d.state = State.WARN
	d.t = level.trap_warn if level != null else 3.0
	d.seal = 0.0
	if host: _net({"a": "warn", "i": i})
	Auto.sfx_at("trap_rumble", Vector3(d.pos.x, 0.0, d.pos.y))

func open_door(i: int) -> void:
	if i < 0 or i >= doors.size() or doors[i].state == State.OPEN: return
	var d := doors[i]
	d.state = State.OPEN
	d.spawned = 0
	d.spawn_t = 0.8
	opened += 1
	if host: _net({"a": "open", "i": i})
	_open_fx(d, true)

## La sella: se cierra, suena la losa y suelta unas gemas (las gemas, el anfitrión).
func seal_door(i: int) -> void:
	if i < 0 or i >= doors.size() or doors[i].state == State.CLOSED: return
	var d := doors[i]
	var was_open: bool = d.state == State.OPEN
	d.state = State.CLOSED
	d.seal = 0.0
	sealed += 1
	if host:
		_net({"a": "seal", "i": i})
		var gm: Variant = game.get("gems") if game != null else null
		if gm is GemManager:
			for k in 3:
				var a := _rng.randf() * TAU
				(gm as GemManager).drop(Vector3(d.pos.x + cos(a) * 1.2, 0.0, d.pos.y + sin(a) * 1.2), 2.0, 2)
	if was_open: _open_fx(d, false)
	var at := Vector3(d.pos.x, 0.0, d.pos.y)
	Auto.sfx_at("trap_seal", at)
	VoxelFx.puff(world.fx, at + Vector3(0, 0.3, 0), "steam", 0.9, DUST, 1.2)
	world._shout("Trampilla sellada", at + Vector3(0, 2.2, 0), SEAL_COLOR, 56, 1.0, 1.5)

## Todas las cerradas, a la vez (el jefe, en su segunda fase).
func open_all() -> void:
	if not host: return
	for d in doors:
		if d.state == State.CLOSED: warn_door(int(d.i))

## La gran trampilla: se abre al subir el jefe y se cierra al morir.
func open_great(open: bool) -> void:
	if great_door.is_empty(): return
	var want: int = State.OPEN if open else State.CLOSED
	if great_door.state == want: return
	great_door.state = want
	if host: _net({"a": "great", "o": 1 if open else 0})
	_open_fx(great_door, open)
	if not open: Auto.sfx_at("trap_seal", Vector3(great.x, 0.0, great.y))

## El aliento del jefe: tira de todos hacia `at` durante `t` s con `force` m/s (anfitrión y su suceso).
func pull(at: Vector3, t: float, force: float) -> void:
	pull_at = at
	pull_t = t
	pull_force = force
	if host: _net({"a": "pull", "x": snappedf(at.x, 0.01), "z": snappedf(at.z, 0.01), "t": t, "f": force})

func _release(d: Dictionary) -> void:
	var dir: Variant = game.get("director") if game != null else null
	if dir == null: return
	released += 1
	var a := _rng.randf() * TAU
	dir.spawn(level.trap_enemy, Vector3(d.pos.x + cos(a) * 0.6, 0.0, d.pos.y + sin(a) * 0.6))
	Auto.sfx_at("polyp_whistle", Vector3(d.pos.x, 0.0, d.pos.y))

## El viento de las abiertas, el de los pólipos y el aliento, en los jugadores de este PC.
func _winds(_delta: float) -> void:
	var wind := level.trap_wind if level != null else 3.0
	var wr := level.trap_wind_radius if level != null else 6.0
	var open: Array[Dictionary] = []
	for d in doors:
		if d.state == State.OPEN: open.append(d)
	if not great_door.is_empty() and great_door.state == State.OPEN: open.append(great_door)
	for q in world.players:
		if q.remote or q.health <= 0.0: continue
		var p := Vector2(q.global_position.x, q.global_position.z)
		var v := Vector2.ZERO
		for d in open:
			var r: float = wr * (1.5 if d.big else 1.0)
			var to: Vector2 = p - d.pos
			var dist := to.length()
			if dist >= r or dist < 0.01: continue
			var k := smoothstep(CALM, CALM + 1.4, dist) * (1.0 - dist / r)
			v += to / dist * wind * k * (1.4 if d.big else 1.0)
		for e in world.enemies:                          # los remolinos de los pólipos: de lado
			if not (e is Enemy) or not is_instance_valid(e) or not e.is_alive(): continue
			if not bool((e as Enemy).data.param("polyp", false)): continue
			var to2 := p - Vector2(e.global_position.x, e.global_position.z)
			var dd := to2.length()
			if dd < SWIRL_R and dd > 0.05: v += Vector2(-to2.y, to2.x) / dd * SWIRL_PUSH * (1.0 - dd / SWIRL_R)
		if pull_t > 0.0 and pull_at != Vector3.INF:
			var to3 := Vector2(pull_at.x, pull_at.z) - p
			var d3 := to3.length()
			if d3 > 0.8: v += to3 / d3 * pull_force * clampf(1.2 - d3 / 18.0, 0.25, 1.0)
		if v != Vector2.ZERO: q.push += Vector3(v.x, 0.0, v.y)

## Invitado: lo que decidió el anfitrión.
func remote(d: Dictionary) -> void:
	var i := int(d.get("i", -1))
	match String(d.get("a", "")):
		"warn": warn_door(i)
		"open": open_door(i)
		"seal": seal_door(i)
		"great": open_great(int(d.get("o", 0)) == 1)
		"pull": pull(Vector3(float(d.get("x", 0.0)), 0.0, float(d.get("z", 0.0))), float(d.get("t", 2.0)), float(d.get("f", 2.0)))

func _net(d: Dictionary) -> void:
	var net: Variant = game.get("net_game") if game != null else null
	if net is NetGame:
		d["k"] = "trap"
		(net as NetGame)._event(d)

# ------------------------------------------------------------------ lo que se ve

## La tapa, el corro donde hay que ponerse y lo sellado.
func _dress(d: Dictionary) -> void:
	if world == null or world.fx == null: return
	var k: float = GREAT_SCALE if d.big else 1.0
	var lid := Node3D.new()
	lid.name = "Tapa"
	lid.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	lid.position = Vector3(d.pos.x, 0.12 * k, d.pos.y)
	lid.scale = Vector3.ONE * k
	lid.add_child(VoxelBuilder.load_model("res://models/pna_tapa.json"))
	world.fx.add_child(lid)
	d.lid = lid
	if d.big: return
	var ring := MeshInstance3D.new()                    # dónde ponerse para sellarla
	var tm := TorusMesh.new()
	tm.inner_radius = SEAL_R - 0.08; tm.outer_radius = SEAL_R
	ring.mesh = tm
	var m := VoxelFx.std()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = SEAL_COLOR
	ring.material_override = m
	ring.position = Vector3(d.pos.x, 0.18, d.pos.y)
	ring.scale = Vector3(1, 0.15, 1)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false
	ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	world.fx.add_child(ring)
	d.ring = ring
	var fill := MeshInstance3D.new()                    # lo sellado: un disco que crece
	fill.mesh = VoxelFx.plane2()
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://scripts/fx/telegraph.gdshader")
	fm.set_shader_parameter("fill", true)
	fm.set_shader_parameter("soft", true)
	fm.set_shader_parameter("color", Color(SEAL_COLOR, 0.4))
	fill.material_override = fm
	fill.position = Vector3(d.pos.x, 0.2, d.pos.y)
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fill.visible = false
	fill.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	world.fx.add_child(fill)
	d.fill = fill

## Al abrirse, la tapa se aparta y se inclina; al cerrarse, vuelve a su sitio de un golpe.
func _open_fx(d: Dictionary, open: bool) -> void:
	var lid: Node3D = d.get("lid")
	var k: float = GREAT_SCALE if d.big else 1.0
	var at := Vector3(d.pos.x, 0.0, d.pos.y)
	if open:
		Auto.sfx_at("trap_open", at)
		VoxelFx.puff(world.fx, at + Vector3(0, 0.5, 0), "steam", 1.0 * k, DUST, 1.4)
		world.shake(0.25 if not d.big else 0.6)
	if lid == null or not is_instance_valid(lid): return
	var a := float(int(d.i) * 2.399 + 0.7)
	var rest := Vector3(d.pos.x, 0.12 * k, d.pos.y)
	var aside := rest + Vector3(cos(a), 0.0, sin(a)) * LID_SLIDE * k + Vector3(0, 0.05 * k, 0)
	var tw := lid.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lid, "position", aside if open else rest, 0.35 if open else 0.25).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(lid, "rotation", Vector3(0.0, a, 0.18) if open else Vector3.ZERO, 0.35 if open else 0.25)

func _process(delta: float) -> void:
	_spin += delta
	for d in doors: _door_fx(d, delta)
	if not great_door.is_empty(): _door_fx(great_door, delta)
	_fade(delta)
	_grains()

func _door_fx(d: Dictionary, delta: float) -> void:
	var at := Vector3(d.pos.x, 0.0, d.pos.y)
	var lid: Node3D = d.get("lid")
	var k: float = GREAT_SCALE if d.big else 1.0
	var ring: Node3D = d.get("ring")
	var fill: Node3D = d.get("fill")
	var active: bool = d.state != State.CLOSED
	if ring != null:
		ring.visible = active
		if active: ring.scale = Vector3(1.0 + 0.04 * sin(_spin * 5.0), 0.15, 1.0 + 0.04 * sin(_spin * 5.0))
		if active and not ring.is_in_group(&"pickups"): ring.add_to_group(&"pickups")   # los bots van a sellarla (SmartBot)
		elif not active and ring.is_in_group(&"pickups"): ring.remove_from_group(&"pickups")
	if fill != null:
		fill.visible = active and float(d.seal) > 0.01
		if fill.visible: fill.scale = Vector3.ONE * maxf(float(d.seal) * SEAL_R, 0.05)
	d.fx_t = float(d.fx_t) - delta
	d.wh_t = float(d.wh_t) - delta
	match int(d.state):
		State.WARN:                                    # la tapa tiembla y se escapa arena
			if lid != null and is_instance_valid(lid):
				lid.rotation = Vector3(_rng.randf_range(-0.03, 0.03), lid.rotation.y, _rng.randf_range(-0.03, 0.03))
				lid.position.y = 0.12 * k + absf(sin(_spin * 31.0)) * 0.03
			if float(d.fx_t) <= 0.0:
				d.fx_t = 0.4
				VoxelFx.puff(world.fx, at + Vector3(0, 0.2, 0), "steam", 0.4 * k, DUST, 0.9)
			if float(d.wh_t) <= 0.0:
				d.wh_t = 1.4
				Auto.sfx_at("polyp_whistle", at)
		State.OPEN:                                    # el viento: polvo que sube y lo de alrededor se mece
			if float(d.fx_t) <= 0.0:
				d.fx_t = 0.35
				VoxelFx.puff(world.fx, at + Vector3(_rng.randf_range(-0.4, 0.4), 0.4, _rng.randf_range(-0.4, 0.4)) * Vector3(k, 1.0, k), "steam", 0.5 * k, DUST, 1.1)
				Gusts.push(world.fx, at, 0.3 * k, (level.trap_wind_radius if level != null else 6.0) * k)
			if float(d.wh_t) <= 0.0:
				d.wh_t = _rng.randf_range(2.2, 3.6)
				Auto.sfx_at("trap_wind", at)

## Lo que casi no se ve: el alfa de cada pólipo según lo cerca que esté de alguien de este PC y de
## si acaba de recibir un golpe.
func _fade(delta: float) -> void:
	var local: Array[Vector3] = []
	for q in world.players:
		if not q.remote and q.health > 0.0: local.append(q.global_position)
	for e in world.enemies:
		if not (e is Enemy) or not is_instance_valid(e) or not e.is_alive(): continue
		var en := e as Enemy
		if not bool(en.data.param("polyp", false)) or en.model == null: continue
		var s: Array = _seen.get(en, [en.health, 0.0, -1.0])
		if en.health < float(s[0]) - 0.01: s[1] = HIT_SHOW
		s[0] = en.health
		s[1] = maxf(0.0, float(s[1]) - delta)
		var near := INF
		for p in local: near = minf(near, Vector2(p.x - en.global_position.x, p.z - en.global_position.z).length())
		var top := float(en.data.param("polyp_alpha", MAX_ALPHA))
		var a := lerpf(top, float(en.data.param("polyp_min_alpha", MIN_ALPHA)), clampf((near - SEE_NEAR) / (SEE_FAR - SEE_NEAR), 0.0, 1.0))
		if float(s[1]) > 0.0: a = maxf(a, top * clampf(float(s[1]) / HIT_SHOW * 1.5, 0.0, 1.0))
		if en.is_revealed(): a = maxf(a, top)
		if absf(a - float(s[2])) > 0.02:
			s[2] = a
			set_alpha(en, a)
		_seen[en] = s
	if _seen.size() > world.enemies.size() + 16:          # los muertos, fuera
		for k in _seen.keys():
			if not is_instance_valid(k): _seen.erase(k)

## Pone el alfa a los materiales del modelo (los de un etéreo, que son suyos: Enemy._make_ethereal).
static func set_alpha(en: Enemy, a: float) -> void:
	if en.model == null or not en.model.has_meta("meshes"): return
	for mi: MeshInstance3D in en.model.get_meta("meshes"):
		var m := mi.material_override as BaseMaterial3D
		if m == null: continue
		if m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = a

## alfa que lleva puesto (tests).
func alpha_of(en: Enemy) -> float:
	var s: Array = _seen.get(en, [])
	return float(s[2]) if s.size() > 2 else -1.0

## Los remolinos de arena: granos que giran alrededor de cada pólipo (y uno enorme alrededor del
## jefe, mayor aún sin cuerpo).
func _grains() -> void:
	if _mm == null: _make_grains()
	var mm := _mm.multimesh
	var n := 0
	for e in world.enemies:
		if n >= MAX_GRAINS: break
		if not (e is Enemy) or not is_instance_valid(e) or not e.is_alive(): continue
		var en := e as Enemy
		if not bool(en.data.param("polyp", false)): continue
		var boss := en.behavior is PolypBossBehavior or en.data.unique
		var count := BOSS_GRAINS * (2 if en.buried else 1) if boss else GRAINS
		var wu := en.windup_amount().x                    # al prepararse para embestir, se abre y gira más deprisa
		var r0 := float(en.data.param("swirl_r", 0.9)) * (1.6 if en.buried else 1.0) * (1.0 + 0.6 * wu)
		var h := float(en.data.param("swirl_h", 1.3))
		var seed := float(en.get_instance_id() % 997)
		var c := en.global_position
		for g in count:
			if n >= MAX_GRAINS: break
			var u := float(g) / count
			var sp := 2.4 + fmod(u * 7.3 + seed, 1.0) * 1.8
			var a := _spin * sp * (1.0 + 1.5 * wu) + u * TAU * 3.0 + seed
			var rr := r0 * (0.55 + 0.45 * fmod(u * 13.7 + seed * 0.3, 1.0))
			var y := fmod(u * 5.1 + _spin * 0.35 + seed * 0.01, 1.0) * h
			var pos := Vector3(c.x + cos(a) * rr, 0.06 + y, c.z + sin(a) * rr)
			var sz := 0.06 if not boss else 0.1
			mm.set_instance_transform(n, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * sz), pos))
			mm.set_instance_color(n, Color(SAND.lerp(Color(0.95, 0.85, 0.65), fmod(u * 3.1, 1.0) * 0.6), 0.85))
			n += 1
	mm.visible_instance_count = n

func _make_grains() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = VoxelFx.box1()
	mm.instance_count = MAX_GRAINS
	mm.visible_instance_count = 0
	var m := VoxelFx.std()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	_mm = MultiMeshInstance3D.new()
	_mm.name = "Remolinos"
	_mm.multimesh = mm
	_mm.material_override = m
	_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mm.custom_aabb = AABB(Vector3(-200, -2, -200), Vector3(400, 12, 400))
	_mm.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_mm)
