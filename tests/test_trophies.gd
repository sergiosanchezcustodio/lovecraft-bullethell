extends GutTest
## Hito 16.28: sala de trofeos.

func test_jefes_en_orden_de_campana() -> void:
	var b := Trophies.bosses()
	var ids := b.map(func(e: EnemyData) -> String: return String(e.id))
	assert_eq(ids.size(), 21)
	assert_eq(ids[0], "antiguo_despierto", "el primero del 1.2")
	assert_true(ids.find("gedney") < ids.find("obed_marsh"))
	assert_has(ids, "cthulhu")
	for e: EnemyData in b: assert_true(e.unique and e.tier >= 4, String(e.id))

func test_vitrinas_y_modelos() -> void:
	var save := SaveData.new()
	var all := Trophies.all(save)
	for c in Trophies.CASES.size():
		var n := all.filter(func(t: Dictionary) -> bool: return int(t.case) == c).size()
		assert_true(n > 0 and n <= Trophies.CASE_COLS[c] * 3, "cabe en su vitrina: %d" % c)
	for t: Dictionary in all:
		assert_false(t.earned, "nada ganado aún: " + String(t.id))
		assert_true(VoxelBuilder.model_exists("res://models/%s.json" % t.model), "modelo de " + String(t.id))
	for m: String in Trophies.CASE_MODELS + ["sala_pared", "sala_suelo", "trofeo_peana"]:
		assert_true(VoxelBuilder.model_exists("res://models/%s.json" % m), m)

func test_logros_grandes_con_trofeo_propio() -> void:
	for a in Trophies.big_achievements():
		assert_true(a.reward_money >= Trophies.BIG_REWARD)
		assert_true(Trophies.ACHIEVEMENT_MODELS.has(String(a.id)), "trofeo de " + String(a.id))

func test_se_va_llenando() -> void:
	var save := SaveData.new()
	Library.add_kill(save, "gedney", "dyer")
	Library.add_kill(save, "gedney", "dyer")
	save.achievements["rico"] = "2026-11-03T12:00:00"
	var won := Trophies.all(save).filter(func(t: Dictionary) -> bool: return t.earned)
	assert_eq(won.size(), 2)
	var g: Dictionary = won.filter(func(t: Dictionary) -> bool: return t.id == "gedney")[0]
	assert_has(g.facts, "Vencido 2 veces")
	assert_eq(Library.count_known(save, "trophies"), Vector2i(2, Trophies.all(save).size()))
