extends GutTest
## Pactos del Necronomicón (hito 13.6): cuáles valen, cómo suman sus efectos y las maldiciones
## que se aplican en el jugador.

func after_each() -> void:
	Pacts.set_active([])

func test_hasta_tres_sin_repetir_ni_desconocidos() -> void:
	assert_eq(Pacts.clean(["noche", "noche", "nada", "furia", "carne", "icor"]), ["noche", "furia", "carne"])
	Pacts.set_active(["carne", "furia", "noche", "icor"])
	assert_eq(Pacts.active().size(), Pacts.max_count())

func test_efectos_se_multiplican_y_se_rehacen() -> void:
	assert_eq(Pacts.value("xp"), 1.0, "sin pactos, nada cambia")
	assert_false(Pacts.has("split_elites"))
	Pacts.set_active(["carne", "estirpe"])
	assert_almost_eq(Pacts.value("xp"), 1.96, 0.001, "1,4 × 1,4")
	assert_almost_eq(Pacts.value("enemy_health"), 1.35, 0.001)
	assert_true(Pacts.has("split_elites"))
	Pacts.set_active(["furia"])
	assert_eq(Pacts.value("xp"), 1.0, "la caché se rehace al cambiarlos")
	assert_almost_eq(Pacts.value("money"), 1.4, 0.001)

func test_todos_tienen_maldicion_y_premio() -> void:
	for p: Dictionary in Pacts.all():
		assert_ne(String(p.get("curse", "")), "", p.id)
		assert_ne(String(p.get("reward", "")), "", p.id)
		assert_false((p.get("effects", {}) as Dictionary).is_empty(), p.id)

func test_superados_en_el_hueco() -> void:
	var s := SaveData.create()
	Pacts.record_win(s, "p1_n2", ["noche", "furia", "carne"])
	Pacts.record_win(s, "p1_n2", ["noche"])
	assert_eq(Pacts.won_on(s, "p1_n2").size(), 3)
	assert_eq(Pacts.won_on(s, "p1_n1").size(), 0)
	assert_eq(int(s.stats.pact_levels), 2)
	assert_eq(int(s.stats.pact3_levels), 1)
	Pacts.record_win(s, "p1_n3", [])
	assert_eq(int(s.stats.pact_levels), 2, "sin pactos no cuenta")

func _player() -> Player:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	return p

func test_sin_consuelo_nada_cura() -> void:
	var p := _player()
	Pacts.set_active(["consuelo"])
	p.health = p.data.max_health * 0.5
	p._physics_process(1.0 / 60.0)
	var before := p.health
	p.health += 30.0                                  # comida, baúl, subida…
	p._physics_process(1.0 / 60.0)
	assert_almost_eq(p.health, before, 0.01, "vuelve a la de antes")
	p.health -= 10.0                                  # el daño sí entra
	p._physics_process(1.0 / 60.0)
	assert_almost_eq(p.health, before - 10.0, 0.01)

func test_susurros_sin_recuperar_cordura() -> void:
	var p := _player()
	Pacts.set_active(["susurros"])
	p.sanity = p.data.max_sanity * 0.5
	var s0 := p.sanity
	for i in 600: p._physics_process(1.0 / 60.0)
	assert_almost_eq(p.sanity, s0, 0.01, "10 s sin nadie: sigue igual")
	Pacts.set_active([])
	for i in 600: p._physics_process(1.0 / 60.0)
	assert_gt(p.sanity, s0, "sin el pacto, se recupera")
