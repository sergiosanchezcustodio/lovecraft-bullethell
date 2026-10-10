class_name GiantMoves
extends RefCounted
## Movimientos de los enemigos grandes (10-10-2026). Un cuerpo de 1,5 m de radio no cabe por
## los pasillos del decorado y se quedaba empujando contra una cabaña mientras le disparaban:
## - Salto: si no tiene un pasillo recto de su anchura hasta el jugador (o se ha atascado),
##   marca dónde va a caer, salta por encima de lo que haya y al caer golpea alrededor.
## - Erupción (solo los seres únicos): una hilera de avisos que avanza por el suelo desde él
##   hasta el jugador; al cumplirse, sale disparado del suelo lo que haya debajo.
## Sus balas, además, pasan por encima del decorado (PatternRunner.over_walls).
## Los anclados (Dagon, Cthulhu) y los etéreos no lo usan.

const MIN_RADIUS := 0.9                 ## a partir de este radio de cuerpo, "grande"
const LEAP_WARN := 0.6                  ## s de aviso donde va a caer
const LEAP_TIME := 0.7                  ## s en el aire
const LEAP_HEIGHT := 2.6
const LEAP_COOLDOWN := 3.5
const LEAP_MAX := 10.0                  ## m como mucho por salto
const ERUPT_EVERY := 6.5
const ERUPT_STEP := 1.5                 ## m entre avisos de la hilera
const ERUPT_RADIUS := 1.1
const ERUPT_WARN := 0.75
const ERUPT_DELAY := 0.1                ## s entre un aviso y el siguiente: la hilera avanza
const EARTH := Color(0.42, 0.36, 0.3, 0.9)

var _leap_cd := 2.0
var _erupt_t := 4.0
var _warn_t := -1.0                     ## >= 0: agachado, esperando a saltar
var _air_t := -1.0                      ## >= 0: en el aire
var _from := Vector3.ZERO
var _to := Vector3.ZERO

static func applies(d: EnemyData) -> bool:
	return not d.ethereal and (d.unique or d.body_radius >= MIN_RADIUS)

## Devuelve true mientras el salto controla al enemigo (no anda, no lo empujan).
func step(e: Enemy, target: Player, delta: float) -> bool:
	if e.anchored: return false
	if _air_t >= 0.0: return _fly(e, delta)
	if _warn_t >= 0.0:
		_warn_t += delta
		if _warn_t >= LEAP_WARN:
			_warn_t = -1.0
			_air_t = 0.0
			_from = e.position
		return true
	if target == null or not is_instance_valid(target): return false
	if e.data.unique:
		_erupt_t -= delta
		if _erupt_t <= 0.0:
			_erupt_t = float(e.data.param("erupt_every", ERUPT_EVERY)) * randf_range(0.85, 1.15)
			_erupt(e, target)
	_leap_cd -= delta
	if _leap_cd > 0.0 or e._stun > 0.0 or e._root_t > 0.0: return false
	var f: FlowField = e.world.flow
	var a := Vector2(e.position.x, e.position.z)
	var b := Vector2(target.global_position.x, target.global_position.z)
	var far := a.distance_to(b) > 4.0
	var blocked := f != null and not f.clear_line(a, b, e.data.body_radius)
	if not far or not (blocked or e._detour_t > 0.0):
		return false
	_leap_cd = LEAP_COOLDOWN
	var land := _landing(e, a, b)
	if land == Vector2.INF: return false
	_to = Vector3(land.x, 0, land.y)
	_warn_t = 0.0
	if OS.get_cmdline_user_args().has("log=true"): print("SALTO %s %.1f m" % [e.data.id, a.distance_to(land)])
	var tg := Telegraph.new().setup(_radius(e), LEAP_WARN + LEAP_TIME, Color(Damage.COLOR_PHYSICAL, 0.8))
	tg.position = _to
	e.world.fx.add_child(tg)
	return true

func _radius(e: Enemy) -> float:
	return e.data.body_radius + 1.2

func _fly(e: Enemy, delta: float) -> bool:
	_air_t += delta
	var k := clampf(_air_t / LEAP_TIME, 0.0, 1.0)
	var p := _from.lerp(_to, k)
	p.y = sin(k * PI) * LEAP_HEIGHT
	e.position = p
	var dir := _to - _from
	dir.y = 0.0
	if dir.length() > 0.1: e.facing = dir.normalized()
	if k >= 1.0:
		_air_t = -1.0
		e.position.y = 0.0
		_impact(e, _to, _radius(e), maxf(12.0, e.data.contact_physical * 1.5), 6.0)
	return true

## Dónde caer: hacia el jugador, lo más cerca de él que se pueda (sin pasarse), en un sitio con
## hueco para el cuerpo y desde el que se llega andando.
func _landing(e: Enemy, a: Vector2, b: Vector2) -> Vector2:
	var to := b - a
	var dist := minf(to.length() - 1.5, LEAP_MAX)
	var obs: ObstacleMap = e.world.obstacles
	var f: FlowField = e.world.flow
	var d := dist
	while d >= 3.0:
		for ang in [0.0, 0.35, -0.35, 0.7, -0.7]:
			var p := a + to.normalized().rotated(ang) * d
			if obs != null and (not obs.bounds.grow(-e.data.body_radius).has_point(p) or obs.is_blocked(p, e.data.body_radius)): continue
			if f != null and not f.reachable(p): continue
			return p
		d -= 1.0
	return Vector2.INF

func _erupt(e: Enemy, target: Player) -> void:
	var from := Vector3(e.position.x, 0, e.position.z)
	var to := Vector3(target.global_position.x, 0, target.global_position.z)
	var dir := (to - from)
	var dist := dir.length()
	if dist < 2.0: return
	dir /= dist
	var n := mini(int((dist + 3.0) / ERUPT_STEP), 14)    # llega hasta el jugador y un poco más allá
	var dmg := float(e.data.param("erupt_damage", 14.0))
	var eid := e.get_instance_id()
	for i in n:
		var at := from + dir * (e.data.body_radius + 0.8 + i * ERUPT_STEP)
		var tg := Telegraph.new().setup(ERUPT_RADIUS, ERUPT_WARN + i * ERUPT_DELAY, Color(Damage.COLOR_PHYSICAL, 0.7))
		tg.position = at
		e.world.fx.add_child(tg)
		tg.finished.connect(func() -> void:
			var e2 := instance_from_id(eid) as Enemy
			if e2 == null or not e2.is_alive(): return
			_impact(e2, at, ERUPT_RADIUS, dmg, 1.5, i % 3 == 0))

## Golpe en el suelo: daño y empuje a los jugadores de dentro, polvo y temblor.
static func _impact(e: Enemy, at: Vector3, r: float, dmg: float, shake: float, sound := true) -> void:
	if sound: Sfx.play("slam")
	WadeSplash.burst(e.world.fx, at, r * 0.7, EARTH, "")
	var cam := e.get_viewport().get_camera_3d() as GameCamera
	if cam != null and shake > 0.0: cam.shake(shake * 0.05)
	for p in e.world.players:
		if p.health > 0.0 and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < r + p.data.hurt_radius:
			var d := Damage.new(dmg, 0.0)
			d.source = e
			d.knockback = (p.global_position - at).normalized()
			p.take_damage(d)
