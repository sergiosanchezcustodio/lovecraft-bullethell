class_name FlockBehavior
extends EnemyBehavior
## Chotacabras de Dunwich (hito 21.14): vuelan a `fly` m del suelo y rondan a su presa a `orbit` m
## (cada uno a su distancia y en su sentido), y cada `dive_every` s se lanzan contra ella en picado:
## se paran en el aire `dive_tell` s (el aviso: se ve venir y se puede esquivar) y bajan `dive_mult`
## veces más deprisa durante `dive_time` s; solo así tocan, y al tocar remontan. Huelen la muerte: su presa es
## el caído más cercano, si lo hay, y si no, quien tenga menos de un tercio de la vida, más deprisa; si
## no, el jugador más cercano. Alrededor de un caído dan vueltas muy cerca (Unseen hace que su tiempo
## corra más deprisa y, si se le acaba, se llevan su alma), cantando más a menudo.

const LOW := 0.35                      ## fracción de vida desde la que un jugador «huele a muerte»
const LOW_MULT := 1.15
const DOWN_ORBIT := 1.1
const SEEK := 25.0                     ## m: hasta dónde huelen a un caído

var _a := 0.0
var _dir := 1.0
var _orbit := 4.5
var _dive := 3.0
var _diving := 0.0
var _tell := 0.0
var _bob := 0.0
var _cry := 5.0

func start(e: Enemy) -> void:
	var orb: Vector2 = e.data.param("orbit", Vector2(3.5, 5.5))
	_orbit = randf_range(orb.x, orb.y)
	_dir = 1.0 if randf() < 0.5 else -1.0
	_dive = _next_dive(e)
	_bob = randf() * TAU
	_cry = randf_range(3.0, 10.0)
	e.position.y = float(e.data.param("fly", 1.5))

func _next_dive(e: Enemy) -> float:
	var r: Vector2 = e.data.param("dive_every", Vector2(2.5, 4.5))
	return randf_range(r.x, r.y)

## A quién van: el caído más cercano (a menos de SEEK m), el más débil o el que les dan.
func prey(e: Enemy, target: Player) -> Player:
	var best: Player = null
	var bd := SEEK
	for q in e.world.players:
		if not q.is_downed(): continue
		var d := q.global_position.distance_to(e.global_position)
		if d < bd:
			bd = d
			best = q
	if best != null: return best
	var weak: Player = null
	for q in e.world.players:
		if q.health <= 0.0 or q.health >= q.data.max_health * LOW: continue
		if weak == null or q.health / q.data.max_health < weak.health / weak.data.max_health: weak = q
	return weak if weak != null else target

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_bob += delta
	var fly := float(e.data.param("fly", 1.5))
	var p := prey(e, target)
	if p == null:
		e.position.y = fly + sin(_bob * 3.0) * 0.12
		return Vector3.ZERO
	var down := p.is_downed()
	var low := not down and p.health < p.data.max_health * LOW
	var speed := e.data.move_speed * (LOW_MULT if low else 1.0)
	var to := p.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	_cry -= delta
	if _cry <= 0.0:
		_cry = randf_range(1.5, 3.0) if down else randf_range(6.0, 14.0)
		e.world.sfx("whippoorwill", e.global_position)
	var v := Vector3.ZERO
	if down:                                            # alrededor del caído, muy cerca
		_diving = 0.0
		_a += delta * speed * 1.4 / DOWN_ORBIT * _dir
		var want := p.global_position + Vector3(cos(_a), 0.0, sin(_a)) * DOWN_ORBIT
		v = (want - e.global_position) * 3.0
		v.y = 0.0
		e.position.y = fly * 0.6 + sin(_bob * 5.0) * 0.1
		e.anim = "walk"
		return v.limit_length(speed * 1.6)
	if _tell > 0.0:                                     # el aviso: quieto en el aire, alas arriba
		_tell -= delta
		e.anim = "idle"
		e.position.y = lerpf(e.position.y, fly + 0.35, minf(1.0, delta * 8.0))
		if _tell <= 0.0: _diving = float(e.data.param("dive_time", 0.6))
		return Vector3.ZERO
	if _diving > 0.0:                                   # en picado
		_diving -= delta
		e.anim = "run"
		e.position.y = lerpf(e.position.y, fly * 0.55, minf(1.0, delta * 6.0))
		return (to / maxf(d, 0.01)) * speed * float(e.data.param("dive_mult", 2.4))
	_dive -= delta
	if _dive <= 0.0 and d < _orbit + 3.0:
		_dive = _next_dive(e)
		_tell = float(e.data.param("dive_tell", 0.4))
		e.windup(_tell)
	# ronda: hacia su punto del círculo
	_a = atan2(-to.z, -to.x) + delta * speed / maxf(_orbit, 1.0) * _dir * 1.6
	var want := p.global_position + Vector3(cos(_a), 0.0, sin(_a)) * _orbit
	v = want - e.global_position
	v.y = 0.0
	e.position.y = lerpf(e.position.y, fly + sin(_bob * 3.0) * 0.15, minf(1.0, delta * 4.0))
	e.anim = "walk"
	return v.limit_length(1.0) * speed if v.length() > 0.3 else Vector3.ZERO

## Solo tocan en picado.
func touches(_e: Enemy) -> bool:
	return _diving > 0.0

## Al tocar, remontan: un golpe por picado.
func contact_damage(e: Enemy) -> Damage:
	_diving = 0.0
	return super(e)

func is_diving() -> bool:
	return _diving > 0.0
