extends GutTest

func _keyboard(pressed: Array) -> KeyboardInput:
	var k := KeyboardInput.new(InputBindings.new())
	k.key_down = func(key: Key) -> bool: return key in pressed
	return k

func _joypad(axes: Dictionary, buttons: Array) -> JoypadInput:
	var j := JoypadInput.new(0, InputBindings.new())
	j.axis = func(_dev: int, a: JoyAxis) -> float: return axes.get(a, 0.0)
	j.button = func(_dev: int, b: JoyButton) -> bool: return b in buttons
	return j

func test_teclado_wasd_y_flechas() -> void:
	var k := _keyboard([KEY_W, KEY_D])
	k.update(0.016)
	assert_almost_eq(k.move, Vector2(1, 1).normalized(), Vector2.ONE * 0.001)
	k = _keyboard([KEY_LEFT])
	k.update(0.016)
	assert_eq(k.move, Vector2(-1, 0))

func test_teclado_pulsacion_unica() -> void:
	var pressed := [KEY_SPACE]
	var k := _keyboard(pressed)
	k.update(0.016)
	assert_true(k.just_pressed(InputBindings.DODGE))
	k.update(0.016)
	assert_true(k.is_down(InputBindings.DODGE))
	assert_false(k.just_pressed(InputBindings.DODGE), "mantener pulsado no repite")

func test_mando_zona_muerta_y_reescalado() -> void:
	var j := _joypad({JOY_AXIS_LEFT_X: 0.15}, [])
	j.update(0.016)
	assert_eq(j.move, Vector2.ZERO, "dentro de la zona muerta")
	j = _joypad({JOY_AXIS_LEFT_X: 1.0}, [])
	j.update(0.016)
	assert_almost_eq(j.move, Vector2(1, 0), Vector2.ONE * 0.001)
	j = _joypad({JOY_AXIS_LEFT_Y: -1.0}, [])           # stick arriba = eje Y negativo
	j.update(0.016)
	assert_almost_eq(j.move, Vector2(0, 1), Vector2.ONE * 0.001)

func test_mando_cruceta_y_boton_de_esquive() -> void:
	var j := _joypad({}, [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_A])
	j.update(0.016)
	assert_eq(j.move, Vector2(-1, 0))
	assert_true(j.just_pressed(InputBindings.DODGE))

func test_combinada_toma_el_mayor_movimiento_y_cualquier_accion() -> void:
	var sources: Array[PlayerInput] = [_keyboard([KEY_SPACE]), _joypad({JOY_AXIS_LEFT_X: 1.0}, [])]
	var c := CombinedInput.new(sources)
	c.update(0.016)
	assert_almost_eq(c.move, Vector2(1, 0), Vector2.ONE * 0.001)
	assert_true(c.just_pressed(InputBindings.DODGE))

func test_bot_circula_y_no_esquiva_al_empezar() -> void:
	var b := BotInput.new("circle", 1.0)
	b.update(0.016)
	assert_almost_eq(b.move.length(), 1.0, 0.001)
	assert_false(b.is_down(InputBindings.DODGE))
	var dodges := 0
	for i in 200:
		b.update(1.0 / 60.0)
		if b.just_pressed(InputBindings.DODGE): dodges += 1
	assert_between(dodges, 2, 4, "unos 3 esquives en 3,3 s con dodge_every=1")
