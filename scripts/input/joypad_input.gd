class_name JoypadInput
extends PlayerInput
## Un mando concreto, identificado por su número de dispositivo.

var device := 0
var bindings: InputBindings
## Consultas inyectables (los tests las sustituyen por unas falsas).
var axis: Callable = func(dev: int, a: JoyAxis) -> float: return Input.get_joy_axis(dev, a)
var button: Callable = func(dev: int, b: JoyButton) -> bool: return Input.is_joy_button_pressed(dev, b)

func _init(p_device: int = 0, p_bindings: InputBindings = null) -> void:
	device = p_device
	bindings = p_bindings if p_bindings != null else InputBindings.new()

func _read_move(_delta: float) -> Vector2:
	# Stick izquierdo con zona muerta radial y reescalado, o la cruceta si el stick está en reposo
	var v := Vector2(axis.call(device, JOY_AXIS_LEFT_X), -axis.call(device, JOY_AXIS_LEFT_Y))
	var dz := bindings.stick_deadzone
	if v.length() < dz:
		v = Vector2.ZERO
		if button.call(device, JOY_BUTTON_DPAD_RIGHT): v.x += 1.0
		if button.call(device, JOY_BUTTON_DPAD_LEFT): v.x -= 1.0
		if button.call(device, JOY_BUTTON_DPAD_UP): v.y += 1.0
		return v.normalized()
	return v.normalized() * inverse_lerp(dz, 1.0, minf(v.length(), 1.0))

func _read_action(action: StringName) -> bool:
	for b: JoyButton in bindings.joy_buttons.get(action, []):
		if button.call(device, b): return true
	return false

func device_name() -> String:
	return "mando %d (%s)" % [device, Input.get_joy_name(device)]
