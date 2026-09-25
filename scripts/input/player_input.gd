class_name PlayerInput
extends RefCounted
## Entrada de un jugador. Los personajes nunca leen Input directamente: reciben
## un PlayerInput (teclado, mando, bot o una combinación) y le preguntan por el
## movimiento y las acciones. Imprescindible para el cooperativo local y el online.
##
## Cada fotograma se llama a update(delta); después, move (vector de pantalla:
## x a la derecha, y hacia arriba, longitud <= 1), is_down() y just_pressed().

var move := Vector2.ZERO
var _down := {}
var _prev := {}

func update(delta: float) -> void:
	_prev = _down.duplicate()
	_down.clear()
	move = _read_move(delta).limit_length(1.0)
	for a: StringName in InputBindings.ACTIONS:
		_down[a] = _read_action(a)

func is_down(action: StringName) -> bool:
	return _down.get(action, false)

func just_pressed(action: StringName) -> bool:
	return _down.get(action, false) and not _prev.get(action, false)

## Para que las subclases lo implementen.
func _read_move(_delta: float) -> Vector2:
	return Vector2.ZERO

func _read_action(_action: StringName) -> bool:
	return false

## Nombre del dispositivo, para depuración y la pantalla de unirse (fase 2).
func device_name() -> String:
	return "ninguno"
