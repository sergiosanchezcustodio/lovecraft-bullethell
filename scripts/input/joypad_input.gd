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
	if disabled():                                   # pruebas de Claude Code: un mando que no hace nada
		axis = func(_dev: int, _a: JoyAxis) -> float: return 0.0
		button = func(_dev: int, _b: JoyButton) -> bool: return false

## Pruebas lanzadas desde Claude Code (CLAUDECODE=1, con ventana): la partida no hace caso a los
## mandos, para que el autor pueda jugar con el suyo a otra cosa en el mismo PC mientras (y sus
## pulsaciones no muevan la prueba). mando=true los deja. Sin ventana (tests), nada cambia.
## La ventana tampoco se lleva el foco: tools/godot_sin_foco.sh.
static var _disabled: Variant = null
static func disabled() -> bool:
	if _disabled == null:
		_disabled = OS.get_environment("CLAUDECODE") == "1" and DisplayServer.get_name() != "headless" \
			and not LaunchArgs.from_cmdline().get_bool("mando")
	return _disabled

## Los mandos conectados (ninguno con los mandos desactivados).
static func pads() -> Array[int]:
	return [] if disabled() else Input.get_connected_joypads()

## Se traga los eventos de los mandos antes que nadie: va el último en la raíz, y _input se
## reparte de atrás adelante (Devices la pone ahí con los mandos desactivados).
class PadFilter extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(e: InputEvent) -> void:
		if e is InputEventJoypadButton or e is InputEventJoypadMotion:
			get_viewport().set_input_as_handled()

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

func joy_device() -> int:
	return device
