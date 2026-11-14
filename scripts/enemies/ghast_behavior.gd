class_name GhastBehavior
extends EnemyBehavior
## Ghasts de las bóvedas de Zin (hito 21.10, nivel 4 de la parte 4). Saltan como canguros, todos a la vez
## (el salto lleva un reloj común, así que la manada avanza a golpes) y odian la luz: no entran en la del
## farol de un jugador (`light_k` × el alcance de su `CarryLight`, así que la linterna de la tienda la
## agranda) ni en la de los hongos que brillan (`DreamLands.glows`). Rondan al borde de la luz y, cada
## `leap_every` s, uno salta sobre su jugador con aviso (`leap_warn`): golpea al caer (`leap_damage` en
## `leap_radius`) y la luz lo quema (`burn` × su vida por segundo) hasta que sale huyendo. Dentro de una luz
## se queman siempre, y huyen de ella.
## Parámetros (opcionales): light_k (0.65), edge (0.9 m fuera de la luz), hop (0.55 s por salto), leap_every
## (5), leap_range (7), leap_warn (0.55), leap_time (0.45), leap_damage (12), leap_radius (1.1), burn (0.35),
## flee_time (1.3).

enum State { PROWL, AIM, LEAP, FLEE }

const BURN_TICK := 0.25
const LEAP_H := 1.4
const EMBER := Color(1.0, 0.62, 0.3)

var state := State.PROWL
var burned := 0.0                      ## daño de luz recibido (tests)
var _t := 0.0
var _cd := 0.0
var _burn := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _away := Vector3.ZERO
var _side := 1.0

func start(e: Enemy) -> void:
	_cd = float(e.data.param("leap_every", 5.0)) * randf_range(0.4, 1.0)
	_side = 1.0 if e.get_instance_id() % 2 == 0 else -1.0

## La luz que alcanza `at` (con `margin` m de más): su centro, o INF si está a oscuras.
static func light_at(world: CombatWorld, at: Vector3, k: float, margin := 0.0) -> Vector3:
	for q in world.players:
		if q.health <= 0.0: continue
		var r := lantern(q, k) + margin
		var c: Vector3 = q.global_position
		if Vector2(at.x - c.x, at.z - c.z).length() < r: return Vector3(c.x, 0.0, c.z)
	var dl := DreamLands.current
	if dl != null:
		for g in dl.glows:
			if Vector2(at.x, at.z).distance_to(g) < dl.glow_radius() + margin: return Vector3(g.x, 0.0, g.y)
	return Vector3.INF

## Radio de la luz del farol de `q` que los ghasts no pisan.
static func lantern(q: Node3D, k: float) -> float:
	var lamp := q.get_node_or_null("CarryLight") as OmniLight3D
	return (lamp.omni_range if lamp != null else 4.5) * k

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var k := float(e.data.param("light_k", 0.65))
	var lit := light_at(e.world, e.global_position, k)
	if lit != Vector3.INF and state != State.LEAP: _scorch(e, lit, delta)
	match state:
		State.AIM:
			e.anim = "idle"
			if _t >= float(e.data.param("leap_warn", 0.55)):
				_from = e.global_position
				_enter(State.LEAP)
			return Vector3.ZERO
		State.LEAP:
			e.anim = "run"
			var u := clampf(_t / float(e.data.param("leap_time", 0.45)), 0.0, 1.0)
			var p := _from.lerp(_to, u)
			e.position = Vector3(p.x, sin(u * PI) * LEAP_H, p.z)
			if u >= 1.0:
				e.position.y = 0.0
				_strike(e)
				_away = (_from - _to) * Vector3(1, 0, 1)
				_enter(State.FLEE)
			return Vector3.ZERO
		State.FLEE:
			e.anim = "run"
			if _t >= float(e.data.param("flee_time", 1.3)) and lit == Vector3.INF: _enter(State.PROWL)
			var away := (e.global_position - lit) * Vector3(1, 0, 1) if lit != Vector3.INF else _away
			return away.normalized() * e.data.move_speed * 1.4 * _hop(e) if away.length() > 0.01 else Vector3.ZERO
	# PROWL
	e.anim = "walk"
	if lit != Vector3.INF:                                      # dentro de una luz: fuera
		var out := (e.global_position - lit) * Vector3(1, 0, 1)
		return out.normalized() * e.data.move_speed * 1.3 if out.length() > 0.01 else Vector3(_side, 0, 0) * e.data.move_speed
	if target == null: return Vector3.ZERO
	var to := (target.global_position - e.global_position) * Vector3(1, 0, 1)
	var d := to.length()
	var ring := lantern(target, k) + float(e.data.param("edge", 0.9))
	_cd -= delta
	if _cd <= 0.0 and d < float(e.data.param("leap_range", 7.0)):
		_aim(e, target)
		return Vector3.ZERO
	var dir := toward(e, target)
	var v := Vector3.ZERO
	if d > ring + 0.6: v = shape_path(e, dir, e.data.move_speed)
	else:                                                       # al borde de la luz: de lado
		var side := Vector3(-dir.z, 0, dir.x) * _side
		v = (side + dir * clampf((d - ring) * 0.8, -1.0, 1.0)).normalized() * e.data.move_speed * 0.8
		if randf() < delta * 0.2: _side = -_side
	# no da el paso que le meta en una luz
	var nxt := e.global_position + v.normalized() * 0.5
	if v.length() > 0.01 and light_at(e.world, nxt, k) != Vector3.INF and state == State.PROWL:
		v = Vector3(-v.z, 0, v.x) * _side
	return v * _hop(e)

## La manada salta a la vez: velocidad a golpes con un reloj común.
func _hop(e: Enemy) -> float:
	var per := float(e.data.param("hop", 0.55))
	var ph := fmod(Time.get_ticks_msec() * 0.001 / per, 1.0)
	return 0.25 + 1.75 * maxf(0.0, sin(ph * TAU))

func _aim(e: Enemy, target: Player) -> void:
	_to = target.global_position + target.velocity * Vector3(1, 0, 1) * 0.3
	_to.y = 0.0
	var warn := float(e.data.param("leap_warn", 0.55))
	var tg := Telegraph.enemy(float(e.data.param("leap_radius", 1.1)), warn + float(e.data.param("leap_time", 0.45)),
		Color(Damage.COLOR_PHYSICAL, 0.8))
	tg.position = _to
	e.world.fx.add_child(tg)
	e.world.sfx("screech", e.global_position)
	_cd = float(e.data.param("leap_every", 5.0)) * randf_range(0.85, 1.2)
	_enter(State.AIM)

func _strike(e: Enemy) -> void:
	var d := Damage.new(float(e.data.param("leap_damage", 12.0)), 0.0)
	d.source = e
	e.world.strike(e.global_position * Vector3(1, 0, 1), float(e.data.param("leap_radius", 1.1)), d)

## La luz lo quema (a tics, para no llenar la pantalla de cifras).
func _scorch(e: Enemy, lit: Vector3, delta: float) -> void:
	_burn -= delta
	if _burn > 0.0: return
	_burn = BURN_TICK
	var dmg := e.data.max_health * e.health_scale * float(e.data.param("burn", 0.35)) * BURN_TICK
	burned += dmg
	e.take_damage(Damage.new(dmg, 0.0))
	if FxShade.on(): HitSparks.burst("glint_ember", e.global_position + Vector3(0, 0.7, 0))
	if state == State.PROWL:
		_away = (e.global_position - lit) * Vector3(1, 0, 1)
		state = State.FLEE
		_t = 0.0

func _enter(s: State) -> void:
	state = s
	_t = 0.0

## En el aire no toca.
func touches(e: Enemy) -> bool:
	return state != State.LEAP and state != State.AIM
