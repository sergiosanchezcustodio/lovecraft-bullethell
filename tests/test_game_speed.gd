extends GutTest
## Hito 16.23: velocidad del juego y pausa automática.

func after_each() -> void:
	HitStop.stop()
	HitStop.normal = 1.0
	Engine.time_scale = 1.0

func test_las_velocidades_van_del_70_al_130_y_la_normal_es_la_de_siempre() -> void:
	assert_eq(Settings.GAME_SPEEDS[0], 0.7)
	assert_eq(Settings.GAME_SPEEDS[-1], 1.3)
	assert_eq(float(Settings.defaults["game_speed"]), 1.0)
	assert_true(Settings.defaults["auto_pause"])

func test_la_micro_pausa_respeta_la_velocidad_elegida() -> void:
	HitStop.enabled = true
	HitStop.normal = 0.8
	Engine.time_scale = 0.8
	var n := HitStop.count
	HitStop.hit(40, true)
	assert_eq(HitStop.count, n + 1, "a la velocidad elegida, sí")
	assert_eq(Engine.time_scale, HitStop.SCALE)
	HitStop.stop()
	assert_almost_eq(Engine.time_scale, 0.8, 0.001, "y la devuelve")
	HitStop.enabled = true
	Engine.time_scale = 2.0
	HitStop.hit(40, true)
	assert_eq(HitStop.count, n + 1, "acelerado (simulaciones), no")
	HitStop.enabled = false

func test_reconoce_el_mando_de_cada_jugador() -> void:
	var j := JoypadInput.new()
	j.device = 2
	var c := CombinedInput.new()
	c.sources.append(KeyboardInput.new())
	var k := JoypadInput.new()
	k.device = 0
	c.sources.append(k)
	assert_true(JoypadInput.uses(j, 2))
	assert_false(JoypadInput.uses(j, 1))
	assert_true(JoypadInput.uses(c, 0), "J1: teclado y mando 0")
	assert_false(JoypadInput.uses(BotInput.new("idle"), 0))
