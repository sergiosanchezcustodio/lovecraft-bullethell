extends GutTest
## Hito 16.22: desfile de jefes.

func test_seis_jefes_en_orden_y_en_su_escenario() -> void:
	assert_eq(BossRush.stages().size(), 6)
	assert_eq(BossRush.next("desfile:1"), "desfile:2")
	assert_eq(BossRush.next("desfile:6"), "", "tras el último, nada")
	assert_eq(BossRush.number_of("desfile:3"), 3)
	assert_eq(BossRush.number_of("p1_n1"), 0)
	assert_eq(Endless.base_of("desfile:2"), "p1_n5", "el escenario, del nivel de la campaña")
	for n in range(1, 7):
		var id := BossRush.id_for(n)
		var b := BossRush.boss_of(id)
		assert_not_null(b, id)
		assert_true(b.unique, "%s: %s es un jefe" % [id, b.id])

func test_el_nivel_saca_al_jefe_enseguida_y_sin_intermedios() -> void:
	var lv := BossRush.make_level("desfile:3")
	assert_eq(String(lv.id), "desfile:3")
	assert_eq(lv.final_enemy.id, &"obed_marsh")
	assert_eq(lv.final_survive, 0.0, "sin la horda del Arrecife")
	assert_lt(lv.final_time, 30.0)
	assert_true(lv.mid_enemies.is_empty())
	var last := BossRush.make_level("desfile:6")
	assert_eq(last.final_enemy.id, &"cthulhu")
	assert_not_null(last.final_next, "y lo que le sigue")

func test_el_record_es_el_menor_tiempo() -> void:
	var s := SaveData.new()
	assert_true(BossRush.record(s, "dyer", 600.0), "el primero")
	assert_false(BossRush.record(s, "dyer", 650.0))
	assert_true(BossRush.record(s, "dyer", 500.0))
	assert_eq(BossRush.best(s, "dyer"), 500.0)
	BossRush.record(s, "lake", 450.0)
	assert_eq(BossRush.best_any(s), 450.0)
	assert_false(BossRush.unlocked(s))
	s.levels_won.append("p3_n5")
	assert_true(BossRush.unlocked(s), "al vencer a Cthulhu")
