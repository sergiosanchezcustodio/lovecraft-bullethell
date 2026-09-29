class_name BotInput
extends PlayerInput
## Jugador automático con guion, para capturas y pruebas de carga reproducibles.
## Patrones: "idle" (quieto), "circle" (círculos), "zigzag" (ida y vuelta en diagonal),
## y en línea recta para medir: "right", "up" y "diag" (arriba a la derecha).
## "follow": jugador de compañía en el cooperativo (hito 2.9): va hacia `leader` si se aleja
## y, cerca, da vueltas a su alrededor a su aire (necesita `body` y `leader`).
## Esquiva cada `dodge_every` segundos (0 = nunca).

var pattern := "circle"
var period := 6.0
var dodge_every := 0.0
var body: Node3D                            ## el personaje que maneja (patrón "follow")
var leader: Node3D                          ## a quién acompaña
var phase := 0.0                            ## desfase de su vuelta (cada bot la suya)
var _t := 0.0

func _init(p_pattern: String = "circle", p_dodge_every: float = 0.0) -> void:
	pattern = p_pattern
	dodge_every = p_dodge_every

func update(delta: float) -> void:
	_t += delta
	super.update(delta)

func _read_move(_delta: float) -> Vector2:
	match pattern:
		"circle":
			var a := _t / period * TAU
			return Vector2(cos(a), sin(a))
		"zigzag":
			return Vector2(1, 1).normalized() * (1.0 if fmod(_t, period) < period * 0.5 else -1.0)
		"follow": return _follow()
		"right": return Vector2(1, 0)
		"up": return Vector2(0, 1)
		"diag": return Vector2(1, 1).normalized()
	return Vector2.ZERO

## El compañero derribado más cercano (cooperativo), o null.
func _downed_mate() -> Node3D:
	if not ("world" in body) or body.world == null: return null
	var best: Node3D = null
	var best_d := INF
	for q in body.world.players:
		if q == body or not q.is_downed(): continue
		var d: float = q.global_position.distance_to(body.global_position)
		if d < best_d:
			best_d = d
			best = q
	return best

## Hacia el líder si está a más de 4 m; si no, rodeándolo a unos 3 m. Si hay un compañero
## derribado, va a su lado para reanimarlo.
func _follow() -> Vector2:
	if body == null or leader == null or not is_instance_valid(body) or not is_instance_valid(leader): return Vector2.ZERO
	var a := _t / period * TAU + phase
	var spot := leader.global_position + Vector3(cos(a), 0, sin(a)) * 3.0
	var down := _downed_mate()                              # un compañero derribado: a reanimarlo
	if down != null: spot = down.global_position
	var to := spot - body.global_position
	to.y = 0.0
	if to.length() < 0.4 or (down != null and to.length() < 0.8): return Vector2.ZERO
	var d := to.normalized() * clampf(to.length() / 2.0, 0.4, 1.0)
	# del suelo al espacio de la pantalla (inverso de PlayerMotor.screen_to_world)
	var right := PlayerMotor.screen_to_world(Vector2(1, 0))
	var fwd := PlayerMotor.screen_to_world(Vector2(0, 1))
	return Vector2(d.dot(right), d.dot(fwd))

func _read_action(action: StringName) -> bool:
	if action == InputBindings.DODGE and dodge_every > 0.0:
		return _t > dodge_every * 0.5 and fmod(_t, dodge_every) < 0.05   # no esquiva nada más empezar
	return false

func device_name() -> String:
	return "bot (%s)" % pattern
