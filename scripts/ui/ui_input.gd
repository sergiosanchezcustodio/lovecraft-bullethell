class_name UiInput
extends RefCounted
## Controles de los menús. Por defecto, Godot confirma con Intro, Intro del teclado
## numérico y Espacio, pero con ningún botón del mando. Aquí se añade A (confirmar) y
## B (volver), y se quita Espacio, que es la tecla de esquivar: esquivar justo cuando
## se abre el menú de mejoras elegía una sin querer.

static func configure() -> void:
	for e in InputMap.action_get_events("ui_accept"):
		if e is InputEventKey and (e as InputEventKey).keycode == KEY_SPACE:
			InputMap.action_erase_event("ui_accept", e)
	_add_joy("ui_accept", JOY_BUTTON_A)
	_add_joy("ui_cancel", JOY_BUTTON_B)

static func _add_joy(action: StringName, button: JoyButton) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button: return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1                      # cualquier mando
	InputMap.action_add_event(action, ev)
