class_name GauntBehavior
extends EnemyBehavior
## Descarnados nocturnos del yermo frío (hito 21.10, nivel 5 de la parte 4). Vuelan en círculo sobre su
## jugador a `height` m y no tocan. Cada `grab_every` s, si está a menos de `grab_range` m, marcan su sitio
## (`grab_warn` s) y bajan: al que siga en la marca (`grab_radius`) lo agarran y se lo llevan por el aire
## `carry_dist` m en `carry_time` s, quitándole `carry_mental` de cordura por segundo, y lo dejan caer
## (`drop_damage`). Si mientras lo llevan les hacen `free_frac` de su vida (un compañero, o él mismo), lo
## sueltan antes, y merece la pena: sueltan gemas y los que estén cerca recuperan cordura (`_reward`).
## En red, el anfitrión decide el agarre y vuela; el que va colgado lo coloca su propio PC: la marioneta,
## con la animación "carry", se lleva al jugador de ese PC que tenga debajo (`puppet_step`).

enum State { FLY, AIM, SWOOP, CARRY, RISE }

const SWOOP_TIME := 0.35
const HOLD_Y := 1.0                        ## m sobre el que lleva colgado
const RISE_TIME := 0.6
const MARK := Color(0.45, 0.3, 0.7, 0.85)
const FREE_GEMS := 4                       ## gemas que suelta al soltar a alguien
const FREE_SANITY := 12.0                  ## cordura para los que estén cerca
const FREE_NEAR := 7.0

var state := State.FLY
var victim: Player                         ## al que lleva (en su PC, o el remoto en el anfitrión)
var freed := false                         ## lo soltó por los golpes (tests)
var drops := 0                             ## veces que ha dejado caer a alguien (tests)
var _t := 0.0
var _cd := 0.0
var _dir := 1.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _carry_dir := Vector3.ZERO
var _hp0 := 0.0

func start(e: Enemy) -> void:
	_cd = float(e.data.param("grab_every", 6.0)) * randf_range(0.5, 1.0)
	_dir = 1.0 if randf() < 0.5 else -1.0
	e.position.y = float(e.data.param("height", 2.8))

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var h := float(e.data.param("height", 2.8))
	match state:
		State.AIM:
			e.anim = "fly"
			e.position = e.position.lerp(Vector3(_to.x, h, _to.z), 1.0 - exp(-4.0 * delta))
			if _t >= float(e.data.param("grab_warn", 0.9)):
				_from = e.global_position
				_enter(State.SWOOP)
			return Vector3.ZERO
		State.SWOOP:
			e.anim = "dive"
			var u := clampf(_t / SWOOP_TIME, 0.0, 1.0)
			var p := _from.lerp(Vector3(_to.x, HOLD_Y + 0.4, _to.z), u * u)
			e.position = p
			if u >= 1.0: _grab(e)
			return Vector3.ZERO
		State.CARRY:
			e.anim = "carry"
			var ct := float(e.data.param("carry_time", 2.2))
			var speed := float(e.data.param("carry_dist", 6.0)) / ct
			var lift := float(e.data.param("carry_lift", 1.4)) * clampf(_t / 0.4, 0.0, 1.0)
			e.position += _carry_dir * speed * delta
			e.position.y = lift + HOLD_Y
			if victim != null and is_instance_valid(victim) and victim.health > 0.0:
				_hold(e, victim, lift, delta)
			else:
				victim = null
			var hit := _hp0 - e.health
			if victim != null and hit >= e.data.max_health * e.health_scale * float(e.data.param("free_frac", 0.25)):
				freed = true
				e.world.shout(L.t("¡Lo suelta!"), e.global_position + Vector3(0, 1.4, 0), Color(0.8, 0.7, 1.0))
				_reward(e)
				_release(e, false)
				return Vector3.ZERO
			if _t >= ct or victim == null: _release(e, true)
			return Vector3.ZERO
		State.RISE:
			e.anim = "fly"
			e.position.y = lerpf(e.position.y, h, 1.0 - exp(-4.0 * delta))
			if _t >= RISE_TIME: _enter(State.FLY)
			return Vector3.ZERO
	# FLY: en círculo
	e.anim = "fly"
	e.position.y = lerpf(e.position.y, h, 1.0 - exp(-3.0 * delta))
	if target == null: return Vector3.ZERO
	_cd -= delta
	var to_p := (target.global_position - e.global_position) * Vector3(1, 0, 1)
	var d := to_p.length()
	if _cd <= 0.0 and d < float(e.data.param("grab_range", 8.0)) and target.carried <= 0.0:
		_aim(e, target)
		return Vector3.ZERO
	var orbit := float(e.data.param("orbit", 5.5))
	var radial := to_p.normalized() * (d - orbit) * 0.8
	var tangent := Vector3(-to_p.z, 0, to_p.x).normalized() * _dir * e.data.move_speed
	return (radial + tangent).limit_length(e.data.move_speed)

func _aim(e: Enemy, target: Player) -> void:
	_to = target.global_position * Vector3(1, 0, 1)
	var warn := float(e.data.param("grab_warn", 0.9))
	var tg := Telegraph.enemy(float(e.data.param("grab_radius", 1.1)), warn + SWOOP_TIME, MARK)
	tg.position = _to
	e.world.fx.add_child(tg)
	e.world.sfx("screech", e.global_position)
	_cd = float(e.data.param("grab_every", 6.0)) * randf_range(0.85, 1.2)
	_enter(State.AIM)

## Abajo: agarra al que siga en la marca (el más cerca de ella).
func _grab(e: Enemy) -> void:
	var r := float(e.data.param("grab_radius", 1.1))
	victim = null
	var bd := INF
	for q in e.world.players:
		if q.health <= 0.0 or q.carried > 0.0 or q.motor.is_dodging(): continue
		var d := Vector2(q.global_position.x - _to.x, q.global_position.z - _to.z).length()
		if d <= r and d < bd:
			bd = d
			victim = q
	if victim == null:
		_enter(State.RISE)
		return
	_hp0 = e.health
	_carry_dir = _escape_dir(e, victim.global_position)
	e.world.sfx("wind_gust", e.global_position)
	_enter(State.CARRY)

## Hacia dónde se lo lleva: al azar, pero sin acabar encima del decorado.
func _escape_dir(e: Enemy, from: Vector3) -> Vector3:
	var dist := float(e.data.param("carry_dist", 6.0))
	var a0 := randf() * TAU
	for i in 8:
		var a := a0 + TAU * i / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var end := from + dir * dist
		if e.obstacles == null or not e.obstacles.is_blocked(Vector2(end.x, end.z), 0.5): return dir
	return Vector3(cos(a0), 0, sin(a0))

## Lleva colgado a `q` (solo si es de este PC; el remoto lo coloca el suyo).
func _hold(e: Enemy, q: Player, lift: float, delta: float) -> void:
	if q.remote: return
	q.global_position = Vector3(e.global_position.x, 0.0, e.global_position.z)
	q.carried = 0.25
	q.lift = lift
	q.sanity = maxf(0.0, q.sanity - float(e.data.param("carry_mental", 4.0)) * delta)

func _release(e: Enemy, fall: bool) -> void:
	if victim != null and is_instance_valid(victim) and not victim.remote:
		victim.carried = 0.0
		if fall: _drop_hurt(e, victim)
	if fall: drops += 1
	victim = null
	_enter(State.RISE)

## Soltarlo merece la pena: suelta gemas y quien esté cerca (también el que iba colgado) recupera cordura.
func _reward(e: Enemy) -> void:
	var at := e.global_position * Vector3(1, 0, 1)
	var game := e.get_tree().current_scene if e.is_inside_tree() else null
	var gm: Variant = game.get("gems") if game != null else null
	if gm != null and gm.has_method("drop"):
		for i in FREE_GEMS: gm.drop(at + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)), 3.0, 2)
	for q in e.world.players:
		if q.remote or q.health <= 0.0: continue
		if q.global_position.distance_to(at) <= FREE_NEAR:
			q.sanity = minf(q.data.max_sanity, q.sanity + FREE_SANITY)

static func _drop_hurt(e: Enemy, q: Player) -> void:
	var d := Damage.new(float(e.data.param("drop_damage", 6.0)), 0.0)
	d.source = e
	q.take_damage(d)
	e.world.ground_hit(q.global_position * Vector3(1, 0, 1), 0.8, Color(0.85, 0.85, 0.95))

## En el invitado: la marioneta con "carry" se lleva al jugador de este PC que tenga debajo.
func puppet_step(e: Enemy, delta: float) -> void:
	if e.anim != "carry":
		if victim != null and is_instance_valid(victim):
			victim.carried = 0.0
			_drop_hurt(e, victim)
		victim = null
		return
	if victim == null:
		for q in e.world.players:
			if q.remote or q.health <= 0.0: continue
			if Vector2(q.global_position.x - e.global_position.x, q.global_position.z - e.global_position.z).length() < 1.6:
				victim = q
				break
	if victim != null and is_instance_valid(victim):
		_hold(e, victim, maxf(0.0, e.global_position.y - HOLD_Y), delta)

func _enter(s: State) -> void:
	state = s
	_t = 0.0

## Vuela: no toca.
func touches(_e: Enemy) -> bool:
	return false
