extends GutTest
## Logros (hito 2.14, D-32): progreso por estadísticas, recompensa una sola vez y guardado.

func _logro(id: String) -> AchievementData:
	for a in Achievements.all():
		if String(a.id) == id: return a
	return null

func test_hay_logros_y_todos_estan_bien_hechos() -> void:
	var list := Achievements.all()
	assert_gte(list.size(), 15)
	var ids := {}
	for a in list:
		assert_false(ids.has(a.id), "id repetido: %s" % a.id)
		ids[a.id] = true
		assert_gt(a.target, 0, String(a.id))
		assert_true(a.icon != null or a.icon_model != "", "sin imagen: %s" % a.id)
		assert_ne(Achievements.reward_text(a), "", "sin recompensa: %s" % a.id)

func test_se_cumple_al_llegar_al_objetivo_y_paga_una_vez() -> void:
	var s := SaveData.create()
	var a := _logro("cazador_100")
	s.stats["kills"] = 99
	assert_true(Achievements.check(s).is_empty())
	assert_almost_eq(Achievements.progress(s, a), 0.99, 0.001)
	s.stats["kills"] = 100
	var done := Achievements.check(s)
	assert_true(done.has(a))
	assert_eq(s.money, a.reward_money)
	assert_true(Achievements.check(s).is_empty(), "no se paga dos veces")
	assert_eq(s.money, a.reward_money)

func test_desbloquea_personajes_y_companeros() -> void:
	var s := SaveData.create()
	s.levels_won.append("p1_n1")
	s.stats["flawless"] = 1
	Achievements.check(s)
	assert_true(s.has_character("legrasse"))
	assert_true(s.has_pet("gato"))

func test_los_personajes_cuentan_los_de_inicio() -> void:
	var s := SaveData.create()
	assert_eq(Achievements.value(s, _logro("coleccionista")), 4)

func test_los_records_solo_suben() -> void:
	var s := SaveData.create()
	Achievements.record(s, "best_level", 12)
	Achievements.record(s, "best_level", 8)
	assert_eq(int(s.stats["best_level"]), 12)

func test_los_logros_se_guardan() -> void:
	var s := SaveData.create()
	s.stats["runs"] = 1
	Achievements.check(s)
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_true(back.achievements.has("primera_partida"))
	assert_eq(int(back.stats["runs"]), 1)
