class_name ZoogBehavior
extends EnemyBehavior
## Zoogs del bosque encantado (hito 21.10, parte 4). Furtivos y en enjambre: cada poco cuentan cuántos
## zoogs (etiqueta `zoog`) tienen a `pack_r` m. Con menos de `pack_min` no se atreven: se quedan a `shy`
## m del jugador más cercano dando vueltas y, si se les acerca, huyen. Con bastantes, atacan a saltos a
## `bold_mult` veces su paso. Un zoog al que le dan estando solo huye un momento.
## Los de las copas (`drop`): aparecen escondidos en lo alto de los robles; eligen a un jugador, marcan
## su sitio (`warn` s) y caen encima (`drop_damage` en `drop_radius` m). Después son zoogs como los demás.
## Parámetros (opcionales): pack_r (4.5), pack_min (3), shy (6.5), bold_mult (1.35), drop, warn (1.0),
## drop_radius (1.2), drop_damage (9), drop_wait (0.6-2.2 s escondido antes de caer).

enum State { HIDDEN, WARN, FALL, GROUND }

const COUNT_EVERY := 0.4
const FALL_TIME := 0.32
const FALL_H := 5.0
const SCARED := 1.4                    ## s que huye un zoog solo al que le dan
const LEAF := Color(0.40, 0.46, 0.26)

var state := State.GROUND
var bold := false
var pack := 0                          ## zoogs que ha contado cerca (incluido él)
var _count_t := 0.0
var _t := 0.0
var _wait := 0.0
var _to := Vector3.ZERO
var _scared := 0.0
var _hp := -1.0
var _side := 1.0

func start(e: Enemy) -> void:
	_count_t = randf() * COUNT_EVERY
	_side = 1.0 if e.get_instance_id() % 2 == 0 else -1.0
	_hp = e.health
	if bool(e.data.param("drop", false)):
		state = State.HIDDEN
		_wait = randf_range(0.6, 2.2)
		_hide(e, true)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var p := e.data.params
	match state:
		State.HIDDEN:
			if target == null or _t < _wait: return Vector3.ZERO
			_to = target.global_position
			_to.y = 0.0
			var r := float(p.get("drop_radius", 1.2))
			var tg := Telegraph.enemy(r, float(p.get("warn", 1.0)), Color(LEAF, 0.85))
			tg.position = _to
			e.world.fx.add_child(tg)
			e.world.sfx("brush", _to)
			e.position = Vector3(_to.x, e.position.y, _to.z)
			_enter(State.WARN)
			return Vector3.ZERO
		State.WARN:
			if _t >= float(p.get("warn", 1.0)):
				_hide(e, false)
				e.position.y = FALL_H
				_enter(State.FALL)
			return Vector3.ZERO
		State.FALL:
			var k := clampf(_t / FALL_TIME, 0.0, 1.0)
			e.position.y = FALL_H * (1.0 - k * k)
			e.anim = "run"
			if k >= 1.0:
				e.position.y = 0.0
				_land(e)
				_enter(State.GROUND)
			return Vector3.ZERO
	return _ground(e, target, delta)

func _ground(e: Enemy, target: Player, delta: float) -> Vector3:
	var p := e.data.params
	_count_t -= delta
	if _count_t <= 0.0:
		_count_t = COUNT_EVERY
		pack = count_pack(e, float(p.get("pack_r", 4.5)))
		bold = pack >= int(p.get("pack_min", 3))
	if e.health < _hp and not bold: _scared = SCARED                 # le han dado estando solo
	_hp = e.health
	_scared -= delta
	if target == null:
		e.anim = "idle"
		return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	var dir := to / maxf(d, 0.01)
	var side := Vector3(-dir.z, 0, dir.x) * _side
	if bold and _scared <= 0.0:
		e.anim = "run"
		var hop := fmod(_t * 2.4 + float(e.get_instance_id() % 7) * 0.13, 1.0)
		e.position.y = sin(hop * PI) * 0.18 if hop < 0.5 else 0.0
		return toward(e, target) * e.data.move_speed * float(p.get("bold_mult", 1.35))
	e.position.y = 0.0
	var shy := float(p.get("shy", 6.5))
	if _scared > 0.0 or d < shy - 1.5:                               # huye
		e.anim = "run"
		return (-dir + side * 0.4).normalized() * e.data.move_speed * 1.15
	e.anim = "walk"
	var radial := 0.6 if d > shy + 2.5 else 0.0                      # se acerca hasta su distancia
	return (side * 0.7 + dir * radial).normalized() * e.data.move_speed * 0.75

## Zoogs vivos a `r` m de este (con él).
static func count_pack(e: Enemy, r: float) -> int:
	var n := 0
	for o in e.world.enemies_in_circle(e.global_position, r):
		if o is Enemy and o.is_alive() and (o as Enemy).data.tags.has(&"zoog"): n += 1
	return n

func _land(e: Enemy) -> void:
	var r := float(e.data.param("drop_radius", 1.2))
	var dmg := Damage.new(float(e.data.param("drop_damage", 9.0)), 0.0)
	dmg.source = e
	e.world.strike(_to, r, dmg)
	e.world.ground_hit(_to, r, LEAF)
	e.world.sfx("slam", _to)
	e.reset_physics_interpolation()

func _hide(e: Enemy, on: bool) -> void:
	e.buried = on
	e.visual.visible = not on

func _enter(s: State) -> void:
	state = s
	_t = 0.0

## Lo que revela lo hace caer donde está, sin golpe.
func reveal(e: Enemy) -> void:
	if state in [State.HIDDEN, State.WARN]:
		_hide(e, false)
		e.position.y = 0.0
		_enter(State.GROUND)

func touches(e: Enemy) -> bool:
	return state == State.GROUND and not e.buried

func can_shoot(_e: Enemy) -> bool:
	return bold
