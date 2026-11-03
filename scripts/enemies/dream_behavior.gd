class_name DreamBehavior
extends EnemyBehavior
## Sonámbulo de Providence (hito 16.18): anda despacio hacia los jugadores con los ojos cerrados y
## un aura que quita cordura (`aura_radius`, `aura_drain`). Cada `blink_every` s, si su objetivo
## está a más de `blink_min` m, se desvanece en una bruma violeta y reaparece a `blink_dist` m de
## él, con un aviso de `blink_warn` s en el suelo donde va a salir. Desvanecido no se ve, no toca
## y no se le puede dar (`Enemy.buried`).
var _blink := 0.0
var _away := -1.0                     ## > 0: desvanecido, s que faltan para reaparecer
var _to := Vector3.ZERO

const MIST := Color(0.62, 0.42, 0.85)

func start(e: Enemy) -> void:
	_blink = float(e.data.param("blink_every", 5.0)) * randf_range(0.4, 1.0)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	if _away > 0.0:
		_away -= delta
		if _away <= 0.0: _appear(e)
		return Vector3.ZERO
	_blink -= delta
	if _blink <= 0.0 and target != null:
		_blink = float(e.data.param("blink_every", 5.0))
		var off := target.global_position - e.global_position
		off.y = 0.0
		if off.length() > float(e.data.param("blink_min", 4.0)):
			_vanish(e, target)
			return Vector3.ZERO
	return super.update(e, target, delta)

func _vanish(e: Enemy, target: Player) -> void:
	var d := float(e.data.param("blink_dist", 1.8))
	var c := target.global_position
	_to = Vector3(c.x, 0.0, c.z)
	for i in 12:                                     # un sitio libre a su lado
		var a := randf() * TAU
		var p := Vector3(c.x + cos(a) * d, 0.0, c.z + sin(a) * d)
		if e.obstacles == null or not e.obstacles.is_blocked(Vector2(p.x, p.z), e.data.body_radius):
			_to = p
			break
	var warn := float(e.data.param("blink_warn", 0.7))
	_away = warn
	e.world.ground_hit(e.global_position, 0.9, MIST)
	e.world.sfx("magic", e.global_position)
	var tg := Telegraph.enemy(0.9, warn, Color(MIST, 0.8))
	tg.position = _to
	e.world.fx.add_child(tg)
	e.buried = true
	e.visual.visible = false

func _appear(e: Enemy) -> void:
	e.position = Vector3(_to.x, e.position.y, _to.z)
	e.reset_physics_interpolation()
	e.buried = false
	e.visual.visible = true
	e.world.ground_hit(_to, 0.9, MIST)
	e.world.sfx("rise_fog", _to)

func touches(e: Enemy) -> bool:
	return not e.buried
