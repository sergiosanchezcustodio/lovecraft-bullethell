class_name DarkBehavior
extends EnemyBehavior
## Sombras aladas del campanario (hito 23.8, «El que acecha en la oscuridad»). Vuelan y solo avanzan a
## oscuras: no entran en la luz de una farola encendida ni en la del farol de un jugador (`light_k` × su
## alcance; Blackout.light_at), y si quedan dentro (la farola vuelve, el destello de un rayo) se queman
## (`burn` × su vida por segundo) y huyen. Rondan al borde de la luz y, cada `dive_every` s, una se lanza
## en picado sobre su jugador atravesando la luz: golpea por contacto y se quema al pasar. Con el apagón,
## los faroles alumbran menos y la ronda se cierra.
## Parámetros (opcionales): light_k (0.5), edge (0.6 m fuera de la luz), fly (1.2 m), dive_every (6),
## dive_range (6), dive_speed (2.6 × la suya), dive_time (0.9), burn (0.4), flee_time (1.0).

enum State { PROWL, DIVE, FLEE }

const BURN_TICK := 0.25
const EMBER := Color(0.75, 0.82, 1.0)

var state := State.PROWL
var burned := 0.0                      ## daño de luz recibido (tests)
var _t := 0.0
var _cd := 0.0
var _burn := 0.0
var _dir := Vector3.ZERO
var _side := 1.0

func start(e: Enemy) -> void:
	_cd = float(e.data.param("dive_every", 6.0)) * randf_range(0.4, 1.0)
	_side = 1.0 if e.get_instance_id() % 2 == 0 else -1.0

## La luz que alcanza `at` para lo de la oscuridad (INF: a oscuras). Sin apagones, solo los faroles.
static func light_for(world: CombatWorld, at: Vector3, k: float, margin := 0.0) -> Vector3:
	var b := Blackout.current
	if b != null:
		if b.flash_lit: return at - Vector3(0.01, 0, 0)              # el rayo lo alumbra todo
		return b.light_at(at, k, margin)
	return GhastBehavior.light_at(world, at, k, margin)

static func lantern_r(q: Node3D, k: float) -> float:
	var l := q.get_node_or_null("CarryLight") as OmniLight3D
	return (l.omni_range if l != null else 4.5) * k

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var fly := float(e.data.param("fly", 1.2))
	e.position.y = lerpf(e.position.y, fly + sin(e._spawn_t * 3.1) * 0.15, minf(1.0, delta * 4.0))
	var k := float(e.data.param("light_k", 0.5))
	var lit := light_for(e.world, e.global_position, k)
	if lit != Vector3.INF: _scorch(e, lit, delta)
	match state:
		State.DIVE:
			e.anim = "burst"
			if _t >= float(e.data.param("dive_time", 0.9)):
				_enter(State.FLEE)
				_dir = -_dir
			return _dir * e.data.move_speed * float(e.data.param("dive_speed", 2.6))
		State.FLEE:
			e.anim = "walk"
			if _t >= float(e.data.param("flee_time", 1.0)) and lit == Vector3.INF: _enter(State.PROWL)
			var away := (e.global_position - lit) * Vector3(1, 0, 1) if lit != Vector3.INF else _dir
			return away.normalized() * e.data.move_speed * 1.3 if away.length() > 0.01 else Vector3.ZERO
	e.anim = "walk"
	if lit != Vector3.INF:
		var out := (e.global_position - lit) * Vector3(1, 0, 1)
		return out.normalized() * e.data.move_speed * 1.3 if out.length() > 0.01 else Vector3(_side, 0, 0) * e.data.move_speed
	if target == null: return Vector3.ZERO
	var to := (target.global_position - e.global_position) * Vector3(1, 0, 1)
	var d := to.length()
	var ring := lantern_r(target, k) + float(e.data.param("edge", 0.6))
	_cd -= delta
	if _cd <= 0.0 and d < float(e.data.param("dive_range", 6.0)) and d > 0.1:
		_cd = float(e.data.param("dive_every", 6.0)) * randf_range(0.8, 1.25)
		_dir = to / d
		e.world.sfx("shadow_wing", e.global_position)
		_enter(State.DIVE)
		return Vector3.ZERO
	var dir := toward(e, target)
	var v := Vector3.ZERO
	if d > ring + 0.5: v = shape_path(e, dir, e.data.move_speed)
	else:
		var side := Vector3(-dir.z, 0, dir.x) * _side
		v = (side + dir * clampf((d - ring) * 0.8, -1.0, 1.0)).normalized() * e.data.move_speed * 0.8
		if randf() < delta * 0.25: _side = -_side
	var nxt := e.global_position + v.normalized() * 0.5
	if v.length() > 0.01 and light_for(e.world, nxt, k) != Vector3.INF:
		v = Vector3(-v.z, 0, v.x) * _side
	return v

func _enter(s: int) -> void:
	state = s
	_t = 0.0

## La luz la quema (a tics).
func _scorch(e: Enemy, lit: Vector3, delta: float) -> void:
	_burn -= delta
	if _burn > 0.0: return
	_burn = BURN_TICK
	var dmg := e.data.max_health * e.health_scale * float(e.data.param("burn", 0.4)) * BURN_TICK
	burned += dmg
	var dm := Damage.new(dmg, 0.0)
	dm.tag = Blackout.TAG
	e.take_damage(dm)
	if not e.is_alive() and not e.puppet: Achievements.add(Auto.save(), "shadows_burned")   # «Hágase la luz» (23.8)
	if FxShade.on(): HitSparks.burst("glint_ember", e.global_position + Vector3(0, 0.4, 0))
	if state == State.PROWL:
		_dir = (e.global_position - lit) * Vector3(1, 0, 1)
		_enter(State.FLEE)

func touches(_e: Enemy) -> bool:
	return state == State.DIVE or Blackout.current == null or not Blackout.current.power
