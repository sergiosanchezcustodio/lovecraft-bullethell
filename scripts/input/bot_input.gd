class_name BotInput
extends PlayerInput
## Jugador automático con guion, para capturas y pruebas de carga reproducibles.
## Patrones: "idle" (quieto), "circle" (círculos) y "zigzag" (ida y vuelta en diagonal).
## Esquiva cada `dodge_every` segundos (0 = nunca).

var pattern := "circle"
var period := 6.0
var dodge_every := 0.0
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
	return Vector2.ZERO

func _read_action(action: StringName) -> bool:
	if action == InputBindings.DODGE and dodge_every > 0.0:
		return _t > dodge_every * 0.5 and fmod(_t, dodge_every) < 0.05   # no esquiva nada más empezar
	return false

func device_name() -> String:
	return "bot (%s)" % pattern
