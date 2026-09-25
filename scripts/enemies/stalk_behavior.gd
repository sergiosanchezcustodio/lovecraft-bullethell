class_name StalkBehavior
extends EnemyBehavior
## Acechador: ronda al jugador a distancia; salta sobre él con aviso previo (marca en el
## suelo) y al aterrizar daña y suelta un anillo de balas; además croa (onda mental con
## huecos). Élite de prueba del evento final de la fase 1.
enum State { STALK, CROUCH, JUMP, RECOVER }
var state := State.STALK
var _t := 0.0
var _pounce_cd := 0.0
var _croak_cd := 0.0
var _orbit_dir := 1.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _mark: Telegraph

func start(e: Enemy) -> void:
	_pounce_cd = float(e.data.param("pounce_cooldown", 4.5)) * 0.6
	_croak_cd = float(e.data.param("croak_cooldown", 6.5)) * 0.5
	_orbit_dir = 1.0 if randf() < 0.5 else -1.0

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var crouch_t := float(e.data.param("telegraph", 0.9))
	match state:
		State.CROUCH:
			e.anim = "pounce"; e.anim_hold = true
			e.anim_t = clampf(_t / crouch_t, 0.0, 1.0) * 0.35
			if target != null: e.facing = (_to - e.global_position).normalized()
			if _t >= crouch_t:
				_from = e.global_position
				_enter(State.JUMP)
			return Vector3.ZERO
		State.JUMP:
			var jump_t := 0.45
			var u := clampf(_t / jump_t, 0.0, 1.0)
			e.anim_t = 0.35 + u * 0.27
			var p := _from.lerp(_to, u)
			e.position = Vector3(p.x, sin(u * PI) * 1.2, p.z)
			if u >= 1.0:
				e.position.y = 0.0
				_land(e)
				_enter(State.RECOVER)
			return Vector3.ZERO
		State.RECOVER:
			e.anim_t = 0.62 + clampf(_t / 0.5, 0.0, 1.0) * 0.38
			if _t >= 0.5:
				e.anim_hold = false
				_enter(State.STALK)
			return Vector3.ZERO
	# STALK: rondar a la distancia preferida
	e.anim = "walk"
	if target == null: return Vector3.ZERO
	_pounce_cd -= delta
	_croak_cd -= delta
	var to_p := target.global_position - e.global_position
	to_p.y = 0.0
	var d := to_p.length()
	if _pounce_cd <= 0.0 and d < float(e.data.param("pounce_range", 10.0)):
		_begin_pounce(e, target)
		return Vector3.ZERO
	if _croak_cd <= 0.0 and e.data.param("croak_pattern", null) != null and not e.runner.busy:
		e.runner.fire(e.data.param("croak_pattern", null), func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)
		_croak_cd = float(e.data.param("croak_cooldown", 6.5))
	var orbit := float(e.data.param("orbit", 6.0))
	var radial := to_p.normalized() * (d - orbit) * 0.8
	var tangent := Vector3(-to_p.z, 0, to_p.x).normalized() * _orbit_dir * 0.7
	var v := (radial + tangent * e.data.move_speed)
	if v.length() < 0.6: e.anim = "idle"
	return v.limit_length(e.data.move_speed)

func _begin_pounce(e: Enemy, target: Player) -> void:
	_to = target.global_position
	_to.y = 0.0
	var r := float(e.data.param("land_radius", 1.7))
	_mark = Telegraph.new().setup(r, float(e.data.param("telegraph", 0.9)) + 0.45,
		Color(Damage.COLOR_PHYSICAL, 0.8))
	_mark.position = _to
	e.world.fx.add_child(_mark)
	_pounce_cd = float(e.data.param("pounce_cooldown", 4.5))
	_enter(State.CROUCH)

func _land(e: Enemy) -> void:
	var r := float(e.data.param("land_radius", 1.7))
	for p in e.world.players:
		if p.global_position.distance_to(e.global_position) < r + p.data.hurt_radius:
			var d := Damage.new(float(e.data.param("land_damage", 18.0)), 0.0)
			d.knockback = (p.global_position - e.global_position).normalized()
			p.take_damage(d)
	var pat: BulletPattern = e.data.param("land_pattern", null)
	if pat != null:
		e.runner.busy = false
		e.runner.fire(pat, func() -> Vector3: return e.global_position + e.facing)
	_orbit_dir = -_orbit_dir

func _enter(s: State) -> void:
	state = s
	_t = 0.0

func can_shoot(_e: Enemy) -> bool:
	return false            # sus ataques los gestiona el propio comportamiento
