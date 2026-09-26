extends Node
## Dispositivos de entrada (autoload `Devices`). Un dispositivo es el teclado (KEYBOARD) o
## un mando (su número). Recuerda el último que se ha usado en los menús (el J1 entra con
## él en la selección de personaje) y avisa cuando un mando se conecta o se desconecta.
## Los mandos se reconocen por su GUID: al reconectarse, Godot puede darles otro número.

signal joy_connected(device: int)
signal joy_disconnected(device: int)

const KEYBOARD := -1
## Colores de los jugadores 1 a 4: los del anillo, el HUD y los marcos de selección.
const COLORS: Array[Color] = [Color(1.0, 0.82, 0.3), Color(0.35, 0.75, 1.0), Color(0.55, 1.0, 0.45), Color(1.0, 0.45, 0.8)]
const MAX_PLAYERS := 4

var last_device := KEYBOARD              ## el último que pulsó algo (menús)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(func(device: int, connected: bool) -> void:
		if connected: joy_connected.emit(device)
		else: joy_disconnected.emit(device))

func _input(event: InputEvent) -> void:
	var d: Variant = device_of(event)
	if d != null: last_device = d

## Dispositivo de un evento: KEYBOARD, el número del mando o null si no es de un jugador
## (ratón, movimientos mínimos del stick).
static func device_of(event: InputEvent) -> Variant:
	if event is InputEventKey: return KEYBOARD
	if event is InputEventJoypadButton: return event.device
	if event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5: return event.device
	return null

func is_connected_joy(device: int) -> bool:
	return device == KEYBOARD or device in Input.get_connected_joypads()

func guid(device: int) -> String:
	return "teclado" if device == KEYBOARD else Input.get_joy_guid(device)

## Busca un mando conectado por su GUID (tras reconectarse). -2 si no está.
func find_by_guid(g: String) -> int:
	if g == "teclado": return KEYBOARD
	for d in Input.get_connected_joypads():
		if Input.get_joy_guid(d) == g: return d
	return -2

func device_name(device: int) -> String:
	return "Teclado" if device == KEYBOARD else "Mando %d" % (device + 1)

## Entrada de partida para un dispositivo, con los controles de la configuración.
func make_input(device: int) -> PlayerInput:
	var b := Settings.bindings()
	if device == KEYBOARD: return KeyboardInput.new(b)
	return JoypadInput.new(device, b)
