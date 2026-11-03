extends GutTest
## Hito 16.21: la expedición.

func after_each() -> void:
	GameSession.expedition = {}
	GameSession.carry.clear()

func test_el_mapa_lleva_al_jefe_por_caminos_sin_huecos() -> void:
	for seed in [1, 2, 3, 40, 99]:
		var rows := Expedition.generate(seed % 3, seed)
		assert_eq(rows.size(), int(Expedition.cfg().rows) + 1)
		assert_eq(String(rows[-1][0].kind), "jefe")
		assert_true((rows[0] as Array).all(func(n: Dictionary) -> bool: return n.kind == "combate"), "se empieza combatiendo")
		var last: Array = rows[-2]
		assert_eq(last.map(func(n: Dictionary) -> String: return n.kind), ["descanso", "buhonero"])
		for r in rows.size() - 1:
			for n: Dictionary in rows[r]: assert_false((n.links as Array).is_empty(), "todo nodo sigue")
			for j in (rows[r + 1] as Array).size():
				assert_true((rows[r] as Array).any(func(n: Dictionary) -> bool: return j in n.links), "todo nodo tiene entrada (%d, %d)" % [r + 1, j])

func test_siempre_igual_con_la_misma_semilla() -> void:
	assert_eq(JSON.stringify(Expedition.generate(1, 77)), JSON.stringify(Expedition.generate(1, 77)))

func test_se_avanza_por_los_caminos() -> void:
	Expedition.start(0, 5)
	assert_eq(Expedition.choices().size(), (Expedition.state().rows[0] as Array).size())
	var id := Expedition.enter(0, 0)
	assert_true(id.begins_with("expedicion:combate:p1_n"), id)
	var ch := Expedition.choices()
	assert_eq(ch.size(), (Expedition.node_at(0, 0).links as Array).size())
	assert_true(ch.all(func(x: Array) -> bool: return int(x[0]) == 1))
	assert_eq(Expedition.won(id, 80, 100.0), Expedition.MAP_ID)
	assert_eq(int(Expedition.state().money), 80, "la bolsa")

func test_los_niveles_y_el_buhonero() -> void:
	var lv := Expedition.make_level(Expedition.level_id("combate", "p1_n2", 1))
	assert_lt(lv.final_time, 200.0, "más corto")
	assert_true(lv.mid_enemies.is_empty())
	var el := Expedition.make_level(Expedition.level_id("elite", "p1_n2", 2))
	assert_gt(el.elite_cap, lv.elite_cap)
	assert_true(Expedition.peddler_now(Expedition.level_id("buhonero", "p2_n2", 3)))
	var boss := Expedition.make_level(Expedition.level_id("jefe", "p3_n5", 6))
	assert_eq(boss.final_enemy.id, &"cthulhu")
	assert_eq(Endless.base_of(Expedition.level_id("jefe", "p3_n5", 6)), "p3_n5")
	assert_eq(Expedition.won(Expedition.level_id("jefe", "p3_n5", 6), 0, 1.0) if Expedition.active() else "", "")

func test_las_curiosidades_cambian_la_bolsa_y_el_progreso() -> void:
	Expedition.start(0, 5)
	GameSession.carry = [{"level": 5, "xp": 0.0, "attrs": {}, "attrs_level1": {}, "passives": {}, "weapons": [["webly", 1]], "signs": []}]
	Expedition.choose({"money": 60, "bonus": 2, "weapon": 1, "passive": 1, "sign": 1, "hurt": 0.8})
	var st := Expedition.state()
	assert_eq(int(st.money), 60)
	assert_eq(int(st.bonus), 2)
	assert_eq(int(st.signs), 1)
	assert_almost_eq(float(st.hurt), 0.8, 0.001)
	assert_eq(int(GameSession.carry[0].weapons[0][1]), 2, "un nivel más al arma")
	assert_eq((GameSession.carry[0].passives as Dictionary).size(), 1, "un objeto nuevo")
	assert_false(Expedition.can_choose({"money": -100}), "sin dinero, no")
	Expedition.rest()
	assert_eq(int(st.bonus), 2 + int(Expedition.cfg().rest_bonus))

func test_record_por_parte() -> void:
	var s := SaveData.new()
	assert_false(Expedition.unlocked(s, 1))
	s.levels_won.append("p2_n5")
	assert_true(Expedition.unlocked(s, 1))
	assert_true(Expedition.record(s, 1, 900.0))
	assert_false(Expedition.record(s, 1, 950.0))
	assert_eq(Expedition.wins(s, 1), 2)
