class_name KeyboardInput
extends PlayerInput
## Teclado. Solo un jugador puede usarlo en local.

var bindings: InputBindings
## Consulta de teclas inyectable (los tests la sustituyen por una falsa).
var key_down: Callable = func(k: Key) -> bool: return Input.is_physical_key_pressed(k)

func _init(p_bindings: InputBindings = null) -> void:
	bindings = p_bindings if p_bindings != null else InputBindings.new()

func _any(list: Array) -> bool:
	for k: Key in list:
		if key_down.call(k): return true
	return false

func _read_move(_delta: float) -> Vector2:
	var v := Vector2.ZERO
	if _any(bindings.key_right): v.x += 1.0
	if _any(bindings.key_left): v.x -= 1.0
	if _any(bindings.key_up): v.y += 1.0
	if _any(bindings.key_down): v.y -= 1.0
	return v.normalized()

func _read_action(action: StringName) -> bool:
	return _any(bindings.keys.get(action, []))

func device_name() -> String:
	return "teclado"
