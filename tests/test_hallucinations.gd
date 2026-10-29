extends GutTest
## Alucinaciones con poca cordura (hito 13.4): cuánto, el HUD que miente y que no entran en el combate.

func test_fuerza_segun_la_cordura() -> void:
	assert_eq(Hallucinations.strength(0.5), 0.0, "por encima del 30 %, nada")
	assert_eq(Hallucinations.strength(0.3), 0.0)
	assert_almost_eq(Hallucinations.strength(0.15), 0.5, 0.001)
	assert_eq(Hallucinations.strength(0.0), 1.0, "a cero, todo")
	assert_true(Hallucinations.enabled(), "salen por defecto (se quitan en Configuración)")

func test_el_hud_miente_un_momento_y_vuelve() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	var game := Node.new()
	add_child_autofree(game)
	var h := Hallucinations.new().setup(game)
	add_child_autofree(h)
	h._hud(p)
	assert_true(p.hud_lie.x >= 0.0 or p.hud_lie.y >= 0.0, "el panel enseña otra cosa")
	assert_eq(h.count("hud"), 1)
	h._items_step(2.0)
	assert_eq(p.hud_lie, Vector2(-1, -1), "y vuelve a la de verdad")
	assert_eq(h.count("hud"), 0)
	assert_eq(world.enemies.size(), 0, "nada entra en el combate")

func test_los_datos_cargan() -> void:
	var game := Node.new()
	add_child_autofree(game)
	var h := Hallucinations.new().setup(game)
	assert_eq((h._cfg.get("every", []) as Array).size(), 2)
	assert_true((h._cfg.get("weights", {}) as Dictionary).has("phantom"))
	h.free()
