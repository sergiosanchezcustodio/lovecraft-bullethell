extends GutTest

func before_all() -> void:
	UiInput.configure()

func _options() -> Array[PlayerProgress.Option]:
	var out: Array[PlayerProgress.Option] = []
	for f in ["vida", "cordura", "iman"]:
		var o := PlayerProgress.Option.new()
		o.kind = PlayerProgress.Option.Kind.PASSIVE
		o.upgrade = load("res://data/upgrades/%s.tres" % f)
		o.to_level = 1
		out.append(o)
	return out

func _joy(button: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.device = 0
	e.pressed = pressed
	Input.parse_input_event(e)

func _key(k: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = pressed
		Input.parse_input_event(e)

func test_aceptar_incluye_el_boton_a_y_no_el_espacio() -> void:
	var has_a := false
	var has_space := false
	for e in InputMap.action_get_events("ui_accept"):
		if e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A: has_a = true
		if e is InputEventKey and e.keycode == KEY_SPACE: has_space = true
	assert_true(has_a)
	assert_false(has_space, "Espacio es esquivar: no debe confirmar menús")

func test_el_boton_a_elige_la_mejora_con_el_foco() -> void:
	var menu := Menus.LevelUpMenu.new(_options(), "Nivel 2")
	var picked: Array = []                     # el menú se libera al elegir: se guarda aquí
	menu.chosen.connect(func(o: PlayerProgress.Option) -> void: picked.append(o))
	add_child(menu)
	await wait_seconds(0.7)
	_joy(JOY_BUTTON_A, true)
	await wait_physics_frames(2)
	_joy(JOY_BUTTON_A, false)
	await wait_physics_frames(2)
	assert_eq(picked.size(), 1, "el botón A confirma")
	if picked.size() == 1:
		assert_eq((picked[0] as PlayerProgress.Option).upgrade.id, &"vida", "elige la primera, que tiene el foco")

func test_no_elige_nada_durante_el_primer_medio_segundo() -> void:
	var menu := Menus.LevelUpMenu.new(_options(), "Nivel 2")
	watch_signals(menu)
	add_child_autofree(menu)
	await wait_physics_frames(3)
	_joy(JOY_BUTTON_A, true)
	await wait_physics_frames(2)
	_joy(JOY_BUTTON_A, false)
	_key(KEY_1)
	await wait_physics_frames(2)
	assert_signal_not_emitted(menu, "chosen")
