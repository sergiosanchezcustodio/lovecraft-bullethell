extends GutTest
## Hito 16.33: la noche avanza durante el nivel.

func _base() -> Dictionary:
	return {"sun_energy": 0.4, "sun_color": Color(0.6, 0.7, 0.86), "ambient_energy": 0.5,
		"ambient_color": Color(0.4, 0.45, 0.5), "background": Color(0.1, 0.12, 0.15), "pitch": -30.0, "stars": 1.0}

func test_curva() -> void:
	assert_almost_eq(NightCycle.dusk_k(0.0, 240.0), 1.0, 0.001, "empieza en el crepúsculo")
	assert_almost_eq(NightCycle.dusk_k(240.0 * float(NightCycle.config().to), 240.0), 0.0, 0.001, "noche cerrada antes del final")
	assert_almost_eq(NightCycle.dusk_k(500.0, 240.0), 0.0, 0.001, "y se queda")
	assert_between(NightCycle.dusk_k(100.0, 240.0), 0.01, 0.99)
	assert_gt(NightCycle.dusk_k(60.0, 240.0), NightCycle.dusk_k(120.0, 240.0), "siempre a más noche")

func test_acaba_en_la_luz_de_la_arena() -> void:
	var b := _base()
	var l := NightCycle.blend(b, 0.0, 0.0)
	for k in b: assert_eq(l[k], b[k], "noche cerrada = la luz aprobada (%s)" % k)

func test_crepusculo_y_alba() -> void:
	var b := _base()
	var d := NightCycle.blend(b, 1.0, 0.0)
	assert_gt(d.sun_energy, b.sun_energy, "más luz al anochecer")
	assert_gt((d.sun_color as Color).r - (d.sun_color as Color).b, (b.sun_color as Color).r - (b.sun_color as Color).b, "más cálida")
	assert_gt(d.pitch, b.pitch, "más baja: sombras largas")
	assert_lt(d.stars, b.stars, "casi sin estrellas")
	var a := NightCycle.blend(b, 0.0, 1.0)
	assert_gt(a.sun_energy, b.sun_energy)
	assert_almost_eq(a.stars, 0.0, 0.001, "al alba se van")

func test_arenas() -> void:
	assert_gt(NightCycle.amount("calles"), 0.0)
	assert_eq(NightCycle.amount("tuneles"), 0.0, "bajo tierra no")
	assert_eq(NightCycle.amount("campamento"), 0.0, "ni en la Antártida")
	for a: String in NightCycle.config().arenas:
		assert_true(FileAccess.file_exists("res://data/arenas/%s.json" % a), a)

func test_aplica_a_la_luna() -> void:
	var moon := DirectionalLight3D.new()
	moon.light_energy = 0.4
	moon.rotation_degrees = Vector3(-30, 20, 0)
	add_child_autofree(moon)
	var env := Environment.new()
	env.ambient_light_energy = 0.5
	var n := NightCycle.new().setup(moon, env, null, null, "calles")
	add_child_autofree(n)
	assert_gt(moon.light_energy, 0.4, "sin director: el principio, crepúsculo")
	assert_gt(env.ambient_light_energy, 0.5)
