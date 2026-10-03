class_name ChargeBehavior
extends EnemyBehavior
## Shoggoth esclavo (hito 4.3): se arrastra hacia el jugador; a `charge_range` m se encoge
## (`windup` s, con un aviso alargado en el suelo) y embiste en línea recta a `charge_speed`
## durante `charge_time` s; después descansa `rest` s. Durante la embestida empuja fuerte.
## Animaciones: anim_windup, anim_move y anim_rest (para otros modelos: el Antiguo guerrero).
enum State { CRAWL, WINDUP, CHARGE, REST }
var state := State.CRAWL
var _t := 0.0
var _cd := 0.0
var _dir := Vector3.FORWARD

func start(e: Enemy) -> void:
	_cd = float(e.data.param("charge_cooldown", 3.5)) * randf_range(0.4, 1.0)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	match state:
		State.WINDUP:
			e.anim = String(e.data.param("anim_windup", "burst")); e.anim_hold = true
			e.anim_t = clampf(_t / float(e.data.param("windup", 0.8)), 0.0, 1.0) * 0.5
			if _t >= float(e.data.param("windup", 0.8)): _enter(State.CHARGE)
			return Vector3.ZERO
		State.CHARGE:
			e.anim = String(e.data.param("anim_move", "crawl")); e.anim_hold = false
			e.facing = _dir
			if _t >= float(e.data.param("charge_time", 0.7)): _enter(State.REST)
			return _dir * float(e.data.param("charge_speed", 11.0))
		State.REST:
			e.anim = String(e.data.param("anim_rest", "idle"))
			if _t >= float(e.data.param("rest", 1.2)): _enter(State.CRAWL)
			return Vector3.ZERO
	e.anim = String(e.data.param("anim_move", "crawl"))
	if target == null: return Vector3.ZERO
	_cd -= delta
	var to := target.global_position - e.global_position
	to.y = 0.0
	if _cd <= 0.0 and to.length() < float(e.data.param("charge_range", 8.0)):
		_dir = to.normalized()
		var length := float(e.data.param("charge_speed", 11.0)) * float(e.data.param("charge_time", 0.7))
		var mark := Telegraph.new().setup(1.0, float(e.data.param("windup", 0.8)) + 0.2, Color(Damage.COLOR_PHYSICAL, 0.7))
		mark.position = e.global_position + _dir * length * 0.5
		mark.position.y = 0.0
		mark.rotation.y = atan2(_dir.x, _dir.z)
		mark.scale = Vector3(e.data.body_radius * 1.6, 1.0, length * 0.5)
		e.world.fx.add_child(mark)
		_cd = float(e.data.param("charge_cooldown", 3.5))
		_enter(State.WINDUP)
		return Vector3.ZERO
	return to.normalized() * e.data.move_speed

func contact_damage(e: Enemy) -> Damage:
	var d := super.contact_damage(e)
	if state == State.CHARGE:
		d.physical *= float(e.data.param("charge_mult", 1.6))
		d.knockback = _dir * 2.0
	return d

func _enter(s: State) -> void:
	state = s
	_t = 0.0

func can_shoot(_e: Enemy) -> bool:
	return state == State.CRAWL
