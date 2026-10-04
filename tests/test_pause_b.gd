extends GutTest
## Con el mando, B en la pausa vuelve al juego.

func _b() -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_B
	ev.pressed = true
	return ev

func test_b_vuelve_al_juego() -> void:
	var p := Menus.PauseMenu.new()
	add_child_autofree(p)
	watch_signals(p)
	p._unhandled_input(_b())
	assert_signal_emitted(p, "resume")

func test_oculta_no_responde() -> void:
	var p := Menus.PauseMenu.new()
	add_child_autofree(p)
	p.visible = false
	watch_signals(p)
	p._unhandled_input(_b())
	assert_signal_not_emitted(p, "resume")
