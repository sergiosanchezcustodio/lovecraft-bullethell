extends GutTest
## Modo sin fin «La noche eterna» (hito 13.8): nivel montado sobre un escenario, escalada y récords.

func test_id() -> void:
	assert_true(Endless.is_endless("sin_fin:p2_n3"))
	assert_false(Endless.is_endless("p2_n3"))
	assert_eq(Endless.base_of("sin_fin:p2_n3"), "p2_n3")
	assert_eq(Endless.base_of("p1_n1"), "p1_n1")
	assert_eq(Endless.id_for("p3_n2"), "sin_fin:p3_n2")

func test_nivel_sobre_el_escenario() -> void:
	var src: LevelData = load("res://data/levels/p2_n3.tres")
	var lv := Endless.make_level("sin_fin:p2_n3")
	assert_true(lv.endless)
	assert_eq(lv.arena, src.arena, "el escenario del nivel")
	assert_null(lv.final_enemy, "sin evento final")
	assert_false(lv.is_survival())
	assert_eq(lv.money_bonus, 0)
	var ids := lv.pool.map(func(d: EnemyData) -> String: return String(d.id))
	assert_has(ids, "pinguino", "de la parte 1")
	assert_has(ids, "acolito", "de la parte 2")
	assert_has(ids, "cultista", "de la parte 3")
	assert_does_not_have(ids, "acechador_tejados", "los que dependen de su escenario, no")
	assert_true(lv.pool.all(func(d: EnemyData) -> bool: return not d.unique))
	assert_eq(lv.mid_times[0], 300.0, "un jefe a los 5 minutos")
	assert_eq(lv.mid_times[1], 600.0)
	assert_eq(lv.mid_enemies.size(), lv.mid_times.size())
	assert_eq((load("res://data/levels/p2_n3.tres") as LevelData).final_time, src.final_time, "no toca el original")

func test_escalada() -> void:
	var lv := Endless.make_level("sin_fin:p1_n1")
	Endless.step(lv, 0.0, 1.0, 90)
	assert_eq(lv.number, 1)
	assert_eq(lv.max_alive, 90)
	Endless.step(lv, 600.0, 1.0, 90)
	assert_eq(lv.number, 5, "a los 10 minutos, todos los escalones")
	assert_almost_eq(lv.health_mult, 1.5, 0.001)
	assert_gt(lv.max_alive, 90)
	assert_eq(lv.elite_cap, 3)
	Endless.step(lv, 99999.0, 1.0, 90)
	assert_eq(lv.max_alive, 160, "con tope")

func test_records() -> void:
	var s := SaveData.new()
	assert_eq(Endless.best(s, "dyer", "p1_n1"), 0.0)
	assert_true(Endless.record(s, "dyer", "p1_n1", 125.0))
	assert_false(Endless.record(s, "dyer", "p1_n1", 100.0), "peor: no")
	assert_true(Endless.record(s, "dyer", "p1_n1", 200.0))
	assert_eq(Endless.best(s, "dyer", "p1_n1"), 200.0)
	assert_eq(Endless.best(s, "varga", "p1_n1"), 0.0, "por personaje")
	assert_eq(EndlessMenu.best_any(s, "p1_n1"), 200.0)
	assert_eq(int(s.stats.get("endless_best", 0)), 200)
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(Endless.best(back, "dyer", "p1_n1"), 200.0, "se guarda")

func test_abierto_al_vencer_a_cthulhu() -> void:
	var s := SaveData.new()
	assert_false(Endless.unlocked(s))
	s.levels_won.append("p3_n5")
	assert_true(Endless.unlocked(s))
	assert_false(Endless.unlocked(null))
