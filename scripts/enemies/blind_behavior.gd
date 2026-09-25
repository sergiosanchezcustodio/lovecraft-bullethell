class_name BlindBehavior
extends EnemyBehavior
## Pingüino albino ciego: va hacia donde oyó al jugador por última vez y corrige cada
## poco (esquivar de lado funciona); de cerca, se echa atrás y embiste.
enum State { LISTEN, WINDUP, CHARGE, RECOVER }
var state := State.LISTEN
var heard := Vector3.ZERO
var _hear_t := 0.0
var _t := 0.0
var _charge_cd := 0.0
var _charge_dir := Vector3.ZERO

func start(e: Enemy) -> void:
	heard = e.global_position
	_hear_t = randf() * float(e.data.param("hear_interval", 1.0))
	_charge_cd = float(e.data.param("charge_cooldown", 3.0)) * randf_range(0.3, 1.0)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	_charge_cd -= delta
	_hear_t -= delta
	if target != null and _hear_t <= 0.0:
		var noise := float(e.data.param("hear_noise", 0.8))
		heard = target.global_position + Vector3(randf_range(-noise, noise), 0, randf_range(-noise, noise))
		_hear_t = float(e.data.param("hear_interval", 1.0)) * randf_range(0.8, 1.2)
	var windup := 0.35
	var charge_time := float(e.data.param("charge_time", 0.35))
	match state:
		State.WINDUP:
			e.anim = "charge"; e.anim_hold = true
			e.anim_t = clampf(_t / windup, 0.0, 1.0) * 0.35
			if _t >= windup: _enter(State.CHARGE)
			return Vector3.ZERO
		State.CHARGE:
			e.anim_t = 0.35 + clampf(_t / charge_time, 0.0, 1.0) * 0.25
			if _t >= charge_time: _enter(State.RECOVER)
			return _charge_dir * float(e.data.param("charge_speed", 9.0))
		State.RECOVER:
			e.anim_t = 0.6 + clampf(_t / 0.35, 0.0, 1.0) * 0.4
			if _t >= 0.35:
				_enter(State.LISTEN)
				e.anim_hold = false
				e.anim = "walk"
			return Vector3.ZERO
	# LISTEN: caminar hacia lo oído
	var to := heard - e.global_position
	to.y = 0.0
	if target != null and _charge_cd <= 0.0:
		var d := target.global_position.distance_to(e.global_position)
		if d < float(e.data.param("charge_range", 3.5)):
			_charge_dir = (heard - e.global_position).normalized()
			_charge_dir.y = 0.0
			_charge_cd = float(e.data.param("charge_cooldown", 3.0))
			_enter(State.WINDUP)
			return Vector3.ZERO
	if to.length() < 0.4:
		e.anim = "idle"                                   # escucha
		return Vector3.ZERO
	e.anim = "walk"
	return to.normalized() * e.data.move_speed

func _enter(s: State) -> void:
	state = s
	_t = 0.0

func contact_damage(e: Enemy) -> Damage:
	var d := super.contact_damage(e)
	if state == State.CHARGE: d = d.scaled(1.6)          # el picotazo en carga duele más
	return d

func can_shoot(_e: Enemy) -> bool:
	return state == State.LISTEN
