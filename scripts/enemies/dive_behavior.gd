class_name DiveBehavior
extends EnemyBehavior
## Antiguo alado (hito 4.2): vuela en círculo alrededor del jugador a `height` m; cada
## `dive_cooldown` s marca el suelo bajo él (aviso de `telegraph` s), cae en picado, daña lo
## que hay en `dive_radius` y vuelve a subir. En el aire no hace daño por contacto.
enum State { FLY, AIM, DIVE, RISE }
var state := State.FLY
var _t := 0.0
var _cd := 0.0
var _dir := 1.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO

func start(e: Enemy) -> void:
	_cd = float(e.data.param("dive_cooldown", 4.0)) * randf_range(0.5, 1.0)
	_dir = 1.0 if randf() < 0.5 else -1.0
	e.position.y = float(e.data.param("height", 2.6))

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var h := float(e.data.param("height", 2.6))
	match state:
		State.AIM:
			e.anim = "fly"
			if _t >= float(e.data.param("telegraph", 0.7)):
				_from = e.global_position
				_enter(State.DIVE)
			return Vector3.ZERO
		State.DIVE:
			e.anim = "dive"
			var u := clampf(_t / float(e.data.param("dive_time", 0.4)), 0.0, 1.0)
			var p := _from.lerp(_to, u * u)
			e.position = Vector3(p.x, lerpf(_from.y, 0.1, u * u), p.z)
			if u >= 1.0:
				_strike(e)
				_enter(State.RISE)
			return Vector3.ZERO
		State.RISE:
			e.anim = "fly"
			e.position.y = lerpf(0.1, h, clampf(_t / 0.6, 0.0, 1.0))
			if _t >= 0.6: _enter(State.FLY)
			return Vector3.ZERO
	# FLY: en círculo alrededor del objetivo
	e.anim = "fly"
	e.position.y = lerpf(e.position.y, h, 1.0 - exp(-3.0 * delta))
	if target == null: return Vector3.ZERO
	_cd -= delta
	var to_p := target.global_position - e.global_position
	to_p.y = 0.0
	var d := to_p.length()
	if _cd <= 0.0 and d < float(e.data.param("dive_range", 9.0)):
		_to = target.global_position
		_to.y = 0.0
		var mark := Telegraph.new().setup(float(e.data.param("dive_radius", 1.3)),
			float(e.data.param("telegraph", 0.7)) + float(e.data.param("dive_time", 0.4)), Color(Damage.COLOR_PHYSICAL, 0.8))
		mark.position = _to
		e.world.fx.add_child(mark)
		_cd = float(e.data.param("dive_cooldown", 4.0))
		Sfx.play("screech")
		_enter(State.AIM)
		return Vector3.ZERO
	var orbit := float(e.data.param("orbit", 5.0))
	var radial := to_p.normalized() * (d - orbit) * 0.8
	var tangent := Vector3(-to_p.z, 0, to_p.x).normalized() * _dir * e.data.move_speed
	return (radial + tangent).limit_length(e.data.move_speed)

func _strike(e: Enemy) -> void:
	var r := float(e.data.param("dive_radius", 1.3))
	for p in e.world.players:
		var off := p.global_position - e.global_position
		off.y = 0.0
		if off.length() < r + p.data.hurt_radius:
			var dmg := Damage.new(float(e.data.param("dive_damage", 12.0)), 0.0)
			dmg.source = e
			dmg.knockback = off.normalized()
			p.take_damage(dmg)
	_dir = -_dir

func _enter(s: State) -> void:
	state = s
	_t = 0.0

## Solo toca a los jugadores cuando está abajo.
func touches(e: Enemy) -> bool:
	return e.position.y < 0.6

func can_shoot(_e: Enemy) -> bool:
	return false
