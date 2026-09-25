extends Node
## Atento a Esc o Start para abrir y cerrar la pausa, también con la partida en pausa.

var game: Node

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_ESCAPE:
		pressed = true
	elif event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
		pressed = true
	if pressed:
		if OS.is_debug_build() and game.args.get_bool("log"): print("pausa pedida por: ", event.as_text(), " dispositivo ", event.device)
		game.toggle_pause()
		get_viewport().set_input_as_handled()
