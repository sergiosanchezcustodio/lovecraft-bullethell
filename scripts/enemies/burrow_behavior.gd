class_name BurrowBehavior
extends EnemyBehavior
## Shoggoth excavador (hito 16.16): persigue un rato en la superficie y se mete bajo el hielo.
## Enterrado no se ve, no toca y no se le puede dar (`Enemy.buried`: fuera de la rejilla); avanza
## deprisa hacia su objetivo dejando grietas en el suelo y, al llegar (o al acabarse el tiempo),
## marca con un aviso dónde va a salir y sale debajo del jugador: daña lo que haya en el círculo,
## con un temblor y esquirlas de hielo. Después se queda arriba, aturdido un momento.
## Parámetros (todos opcionales):
##   surface (4.0 s arriba antes de enterrarse), under (2.2 s como mucho bajo tierra),
##   under_speed (×2,4 su velocidad), warn (0,9 s de aviso), burst_radius (1,6 m),
##   burst_damage (16), dazed (0,9 s quieto al salir)
enum State { SURFACE, DIG, UNDER, WARN, DAZED }
var state := State.SURFACE
var _t := 0.0
var _crack := 0.0
var _to := Vector3.ZERO

const DIG_TIME := 0.45
const ICE := Color(0.55, 0.70, 0.82)

func start(e: Enemy) -> void:
	_t = -randf() * 1.5                                     # no se entierran todos a la vez

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var p := e.data.params
	match state:
		State.SURFACE:
			if _t >= float(p.get("surface", 4.0)) and target != null:
				_enter(State.DIG)
				e.world.ground_hit(e.global_position, e.data.body_radius * e.model_scale * 1.4, ICE)
				e.world.sfx("rise_snow", e.global_position)
				play_attack_anim(e, "burst")
				return Vector3.ZERO
			return super.update(e, target, delta)
		State.DIG:                                          # se hunde: encoge y se va
			if _t >= DIG_TIME:
				_bury(e, true)
				_enter(State.UNDER)
			return Vector3.ZERO
		State.UNDER:
			if target == null:
				_surface(e)
				return Vector3.ZERO
			var to := target.global_position - e.global_position
			to.y = 0.0
			_crack -= delta
			if _crack <= 0.0:                                # grietas por donde pasa (se ven en todos los PC)
				_crack = 0.28
				e.world.ground_hit(e.global_position, 0.55, ICE)
			if to.length() < 1.2 or _t >= float(p.get("under", 2.2)):
				_to = target.global_position
				_to.y = 0.0
				var r := float(p.get("burst_radius", 1.6))
				var tg := Telegraph.enemy(r, float(p.get("warn", 0.9)), Color(ICE, 0.85))
				tg.position = _to
				e.world.fx.add_child(tg)
				e.world.sfx("ice_crack", _to)
				_enter(State.WARN)
				return Vector3.ZERO
			return to.normalized() * e.data.move_speed * float(p.get("under_speed", 2.4))
		State.WARN:                                         # bajo el aviso, esperando
			var off := _to - e.global_position
			off.y = 0.0
			if _t >= float(p.get("warn", 0.9)):
				_burst(e)
				_enter(State.DAZED)
				return Vector3.ZERO
			return off / maxf(float(p.get("warn", 0.9)) - _t, 0.05) if off.length() > 0.05 else Vector3.ZERO
		State.DAZED:
			e.anim = "idle"
			if _t >= float(p.get("dazed", 0.9)): _enter(State.SURFACE)
			return Vector3.ZERO
	return Vector3.ZERO

func _burst(e: Enemy) -> void:
	e.position = Vector3(_to.x, e.position.y, _to.z)
	_bury(e, false)
	var r := float(e.data.param("burst_radius", 1.6))
	var dmg := Damage.new(float(e.data.param("burst_damage", 16.0)), 0.0)
	dmg.source = e
	e.world.strike(_to, r, dmg)
	e.world.ground_hit(_to, r, ICE)
	e.world.shake(0.25)
	e.world.sfx("slam", _to)
	e.world.sfx("tekeli", _to)
	play_attack_anim(e, "burst")

## Sale a la superficie donde está (sin objetivo).
func _surface(e: Enemy) -> void:
	_bury(e, false)
	e.world.ground_hit(e.global_position, 1.0, ICE)
	_enter(State.DAZED)

func _bury(e: Enemy, on: bool) -> void:
	e.buried = on
	e.visual.visible = not on
	if not on: e.reset_physics_interpolation()

func _enter(s: State) -> void:
	state = s
	_t = 0.0

## La Máquina del más allá lo saca (hito 20.20): bajo tierra o a punto de salir, sale aturdido
## donde está, sin el golpe de la salida.
func reveal(e: Enemy) -> void:
	if e.buried and state in [State.UNDER, State.WARN]: _surface(e)

func touches(e: Enemy) -> bool:
	return not e.buried and state != State.DIG

func can_shoot(_e: Enemy) -> bool:
	return false
