class_name InputBindings
extends Resource
## Asignación de teclas y botones a acciones. Es un dato para poder reasignarla
## desde el menú de opciones (fase 5) sin tocar código.

## Acciones de botón. El movimiento es aparte (vector).
const DODGE := &"dodge"
const PAUSE := &"pause"
const SHEET := &"sheet"
const MAP := &"map"
const CONFIRM := &"confirm"
const BACK := &"back"
const PAGE_PREV := &"page_prev"             ## páginas de la ficha (hito 2.12)
const PAGE_NEXT := &"page_next"
const ACTIONS: Array[StringName] = [DODGE, PAUSE, SHEET, MAP, CONFIRM, BACK, PAGE_PREV, PAGE_NEXT]

## Teclado: movimiento (varias teclas por dirección) y acciones (varias teclas por acción).
@export var key_up: Array[Key] = [KEY_W, KEY_UP]
@export var key_down: Array[Key] = [KEY_S, KEY_DOWN]
@export var key_left: Array[Key] = [KEY_A, KEY_LEFT]
@export var key_right: Array[Key] = [KEY_D, KEY_RIGHT]
@export var keys := {
	DODGE: [KEY_SPACE],
	PAUSE: [KEY_ESCAPE],
	SHEET: [KEY_TAB],
	MAP: [KEY_M],
	CONFIRM: [KEY_ENTER, KEY_KP_ENTER],
	BACK: [KEY_ESCAPE],
	PAGE_PREV: [KEY_Q],
	PAGE_NEXT: [KEY_E],
}

## Mando: stick izquierdo (más la cruceta como alternativa de movimiento) y botones.
@export var stick_deadzone := 0.2
@export var joy_buttons := {
	DODGE: [JOY_BUTTON_A],
	PAUSE: [JOY_BUTTON_START],
	SHEET: [JOY_BUTTON_BACK],
	MAP: [JOY_BUTTON_DPAD_DOWN],
	CONFIRM: [JOY_BUTTON_A],
	BACK: [JOY_BUTTON_B],
	PAGE_PREV: [JOY_BUTTON_LEFT_SHOULDER],
	PAGE_NEXT: [JOY_BUTTON_RIGHT_SHOULDER],
}
