class_name PolypBehavior
extends EnemyBehavior
## Pólipo volador (hito 21.15, «La sombra fuera del tiempo»): flota a `fly` m, a medias material
## (etéreo: atraviesa el decorado; casi no se ve, PolypWinds le baja el alfa). Se acerca a su presa
## a vaivenes y cada `rush_every` s, si la tiene a menos de `rush_range` m, silba más fuerte, se para
## `rush_tell` s (el aviso) y se lanza `rush_mult` veces más deprisa durante `rush_time` s en línea
## recta: solo así toca, y al tocar se acaba la embestida. Silba de vez en cuando (`polyp_whistle`):
## por el oído se sabe que hay uno cerca.

var _bob := 0.0
var _phase := 0.0
var _rush_cd := 3.0
var _tell := 0.0
var _rushing := 0.0
var _dir := Vector3.FORWARD
var _whistle := 3.0

func start(e: Enemy) -> void:
	_bob = randf() * TAU
	_phase = randf() * TAU
	_rush_cd = _next_rush(e) * randf_range(0.5, 1.0)
	_whistle = randf_range(1.5, 6.0)
	e.position.y = float(e.data.param("fly", 0.9))

func _next_rush(e: Enemy) -> float:
	var r: Vector2 = e.data.param("rush_every", Vector2(3.5, 6.0))
	return randf_range(r.x, r.y)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_bob += delta
	var fly := float(e.data.param("fly", 0.9))
	e.position.y = lerpf(e.position.y, fly + sin(_bob * 2.2) * 0.18, minf(1.0, delta * 4.0))
	if target == null: return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	_whistle -= delta
	if _whistle <= 0.0:
		_whistle = randf_range(4.0, 8.0)
		e.world.sfx("polyp_whistle", e.global_position)
	if _tell > 0.0:                                    # el aviso: quieto, hinchándose
		_tell -= delta
		e.anim = "idle"
		if _tell <= 0.0:
			_rushing = float(e.data.param("rush_time", 0.7))
			_dir = to / maxf(d, 0.01)
		return Vector3.ZERO
	if _rushing > 0.0:
		_rushing -= delta
		e.anim = "burst"
		return _dir * e.data.move_speed * float(e.data.param("rush_mult", 2.6))
	_rush_cd -= delta
	if _rush_cd <= 0.0 and d < float(e.data.param("rush_range", 7.0)):
		_rush_cd = _next_rush(e)
		_tell = float(e.data.param("rush_tell", 0.6))
		e.windup(_tell)
		e.world.sfx("polyp_rush", e.global_position)
		return Vector3.ZERO
	e.anim = "walk"
	if d < 0.05: return Vector3.ZERO
	var fwd := to / d
	var side := Vector3(-fwd.z, 0.0, fwd.x)
	var v := (fwd + side * sin(_bob * 1.3 + _phase) * 0.75).normalized() * e.data.move_speed
	if d < 1.6: v *= 0.35                             # de cerca no empuja: espera a embestir
	return v

## Solo toca embistiendo.
func touches(_e: Enemy) -> bool:
	return _rushing > 0.0

func contact_damage(e: Enemy) -> Damage:
	_rushing = 0.0
	return super(e)

func is_rushing() -> bool:
	return _rushing > 0.0

func is_telling() -> bool:
	return _tell > 0.0
