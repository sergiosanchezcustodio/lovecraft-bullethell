extends GutTest
## Navegación con el mando en los menús: en una ventana de confirmación, izquierda y derecha
## pasan de un botón al otro sin escaparse a lo de detrás; en una lista, bajar desde la última
## fila no sale de ella; al cerrar la ventana, lo de detrás recupera el foco.

func _press(button: JoyButton) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		ev.pressed = pressed
		get_viewport().push_input(ev)
	await get_tree().process_frame

func _behind() -> Array[Button]:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(box)
	var out: Array[Button] = []
	for i in 4:
		var b := Button.new()
		b.text = "fila %d" % i
		b.custom_minimum_size = Vector2(1800, 120)
		box.add_child(b)
		out.append(b)
	return out

func test_la_confirmacion_cambia_de_boton_con_la_cruceta() -> void:
	var rows := _behind()
	var c := MenuKit.Confirm.new("¿Seguro?", "Sí")
	add_child_autofree(c)
	await get_tree().process_frame
	await get_tree().process_frame
	var no := get_viewport().gui_get_focus_owner()
	assert_eq((no as Button).text, "Cancelar")
	await _press(JOY_BUTTON_DPAD_RIGHT)
	assert_eq((get_viewport().gui_get_focus_owner() as Button).text, "Sí")
	await _press(JOY_BUTTON_DPAD_DOWN)
	assert_eq((get_viewport().gui_get_focus_owner() as Button).text, "Sí", "no se escapa hacia abajo")
	await _press(JOY_BUTTON_DPAD_LEFT)
	assert_eq((get_viewport().gui_get_focus_owner() as Button).text, "Cancelar")
	for r in rows: assert_eq(r.focus_mode, Control.FOCUS_NONE, "lo de detrás no puede tener el foco")
	c.queue_free()
	await get_tree().process_frame
	for r in rows: assert_eq(r.focus_mode, Control.FOCUS_ALL, "al cerrar lo recupera")

func test_bajar_desde_la_ultima_fila_no_sale_de_la_lista() -> void:
	var rows := _behind()
	MenuKit.chain_focus(rows)
	rows[3].grab_focus()
	await _press(JOY_BUTTON_DPAD_DOWN)
	assert_eq(get_viewport().gui_get_focus_owner(), rows[3])
	await _press(JOY_BUTTON_DPAD_UP)
	assert_eq(get_viewport().gui_get_focus_owner(), rows[2])
	rows[0].grab_focus()
	await _press(JOY_BUTTON_DPAD_UP)
	assert_eq(get_viewport().gui_get_focus_owner(), rows[0])
