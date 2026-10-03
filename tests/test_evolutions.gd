extends GutTest
## Evoluciones de armas (D-06): arma al nivel máximo + su objeto -> evolución en un baúl.

func test_cada_evolucion_existe_y_no_sale_al_subir_de_nivel() -> void:
	for w in DamageRules.all_weapons():
		if w.evolution == &"": continue
		var ev: WeaponData = load("res://data/weapons/%s.tres" % w.evolution)
		assert_not_null(ev, String(w.evolution))
		assert_true(ev.evolved, "%s marcada como evolución" % ev.id)
		assert_true(ResourceLoader.exists("res://data/upgrades/%s.tres" % w.evolves_with), String(w.evolves_with))

func test_evoluciona_solo_al_maximo_y_con_el_objeto() -> void:
	var ws := WeaponSystem.new()
	var w := ws.add_weapon(load("res://data/weapons/webly.tres"))
	assert_null(ws.evolvable({"iman": 1}), "nivel 1: todavía no")
	w.level = w.data.max_level
	assert_null(ws.evolvable({}), "sin la brújula, no")
	assert_eq(ws.evolvable({"iman": 1}), w)
	ws.evolve(w)
	assert_eq(String(w.data.id), "revolver_vigia")
	assert_null(ws.evolvable({"iman": 1}), "una evolución no vuelve a evolucionar")
	ws.free()
