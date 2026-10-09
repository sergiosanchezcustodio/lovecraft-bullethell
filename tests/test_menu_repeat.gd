extends GutTest
## Navegación de los menús al mantener pulsado (MenuRepeat): el foco avanza solo y la lista
## se desliza hasta la opción enfocada.

var sc: ScrollContainer
var rows: Array[Button] = []

func before_each() -> void:
	sc = ScrollContainer.new()
	sc.size = Vector2(300, 200)
	sc.follow_focus = true
	add_child_autofree(sc)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	rows.clear()
	for i in 30:
		var b := Button.new()
		b.text = "Opción %d" % i
		b.custom_minimum_size.y = 40
		box.add_child(b)
		rows.append(b)
	await get_tree().process_frame
	rows[0].grab_focus()

func after_each() -> void:
	Input.action_release("ui_down")

func _focused() -> int:
	return rows.find(get_viewport().gui_get_focus_owner())

func test_quita_el_salto_de_las_listas() -> void:
	assert_false(sc.follow_focus, "lo desliza MenuRepeat")
	assert_true(sc.has_meta(&"smooth_focus"))

func test_mantener_abajo_avanza_solo_y_desliza() -> void:
	Input.action_press("ui_down")
	var t := 0.0
	while t < 1.5:
		await get_tree().process_frame
		t += get_process_delta_time()
	Input.action_release("ui_down")
	await get_tree().create_timer(0.3).timeout
	assert_gt(_focused(), 5, "manteniendo 1,5 s avanza varias opciones")
	assert_gt(sc.scroll_vertical, 0, "y la lista se ha desplazado")
	var r := rows[_focused()].get_global_rect()
	var view := sc.get_global_rect()
	assert_true(r.position.y >= view.position.y - 1 and r.end.y <= view.end.y + 1, "la opción enfocada se ve entera")

func test_sin_mantener_no_repite() -> void:
	Input.action_press("ui_down")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("ui_down")
	await get_tree().create_timer(0.3).timeout
	assert_lt(_focused(), 2, "una pulsación corta no repite")

## Cruceta del mando como eventos de verdad (lo que hizo el autor: el menú se bloqueaba).
func _dpad(button: JoyButton, pressed: bool) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = 0
	ev.button_index = button
	ev.pressed = pressed
	Input.parse_input_event(ev)

func test_cruceta_mantenida_no_bloquea() -> void:
	_dpad(JOY_BUTTON_DPAD_DOWN, true)
	await get_tree().create_timer(1.2).timeout
	_dpad(JOY_BUTTON_DPAD_DOWN, false)
	await get_tree().process_frame
	assert_gt(_focused(), 3, "manteniendo la cruceta avanza")
	assert_false(Input.is_action_pressed("ui_down"), "al soltarla, abajo deja de estar pulsado")
	var at := _focused()
	await get_tree().create_timer(0.5).timeout
	assert_eq(_focused(), at, "y el foco se queda quieto")
	_dpad(JOY_BUTTON_DPAD_UP, true)
	await get_tree().create_timer(0.8).timeout
	_dpad(JOY_BUTTON_DPAD_UP, false)
	assert_lt(_focused(), at, "y se puede volver a subir")
