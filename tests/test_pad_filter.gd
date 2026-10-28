extends GutTest
## Pruebas de Claude Code sin mandos (JoypadInput.disabled): el filtro, último en la raíz, se
## traga los eventos de mando antes que los demás nodos; el teclado pasa.

class Probe extends Node:
	var got := 0
	func _input(_e: InputEvent) -> void:
		got += 1

func test_el_filtro_se_traga_los_mandos() -> void:
	var probe := Probe.new()
	get_tree().root.add_child(probe)
	get_tree().root.move_child(probe, 0)
	var f := JoypadInput.PadFilter.new()
	get_tree().root.add_child(f)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	get_tree().root.push_input(pad)
	assert_eq(probe.got, 0, "el mando no llega")
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	get_tree().root.push_input(key)
	assert_eq(probe.got, 1, "el teclado sí")
	probe.free()
	f.free()

func test_sin_ventana_los_mandos_siguen() -> void:
	assert_false(JoypadInput.disabled(), "los tests van sin ventana: nada cambia")
