extends Node
## Atento a la tecla o el botón de pausa para abrirla y cerrarla, también con la partida en pausa.

var game: Node

func _unhandled_input(event: InputEvent) -> void:
	# La pausa reasignada en la configuración, y siempre también Esc y Start (vía de escape)
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		pressed = k == KEY_ESCAPE or k == Settings.key_for(InputBindings.PAUSE)
	elif event is InputEventJoypadButton and event.pressed:
		var b := (event as InputEventJoypadButton).button_index
		pressed = b == JOY_BUTTON_START or b == Settings.joy_for(InputBindings.PAUSE)
	if pressed:
		if OS.is_debug_build() and game.args.get_bool("log"): print("pausa pedida por: ", event.as_text(), " dispositivo ", event.device)
		game.toggle_pause()
		get_viewport().set_input_as_handled()
