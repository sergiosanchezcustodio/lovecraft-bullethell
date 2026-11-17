extends GutTest
## Hito 22.3: logros de la parte 4 y de las noches sueltas, y sus trofeos.

func _a(id: String) -> AchievementData:
	for a in Achievements.all():
		if String(a.id) == id: return a
	return null

func test_los_seis_logros_existen() -> void:
	for id in ["galera_varada", "sin_redes", "trampillas", "gran_gug", "tres_caras", "tres_noches"]:
		var a := _a(id)
		assert_not_null(a, id)
		if a != null:
			assert_ne(a.description, "", "%s: con descripción" % id)
			assert_true(a.icon_model == "" or FileAccess.file_exists("res://models/%s.json" % a.icon_model), "%s: su icono" % id)

func test_bajas_de_una_criatura() -> void:
	var s := SaveData.new()
	var a := _a("gran_gug")
	assert_eq(Achievements.value(s, a), 0)
	Library.add_kill(s, "gug_koth", "dyer")
	assert_eq(Achievements.value(s, a), 1)
	assert_true(Achievements.check(s).has(a), "se cumple al vencerlo")

func test_tres_noches_distintas() -> void:
	var s := SaveData.new()
	var a := _a("tres_noches")
	for n in 2: Nights.record_win(s, "noche_color")
	assert_eq(Achievements.value(s, a), 1, "la misma noche dos veces cuenta una")
	Nights.record_win(s, "noche_dunwich")
	Nights.record_win(s, "noche_pnakotus")
	assert_eq(Achievements.value(s, a), 3)

func test_las_trampillas_suman() -> void:
	var s := SaveData.new()
	for i in 25: Achievements.add(s, "traps_sealed")
	assert_true(Achievements.check(s).has(_a("trampillas")))

func test_la_vitrina_de_jefes_con_las_noches() -> void:
	var ids := Trophies.bosses().map(func(e: EnemyData) -> String: return String(e.id))
	for id in ["color_pozo", "hermano_wilbur", "polipo_antiguo", "tras_ventana"]: assert_true(ids.has(id), "el jefe de la noche: %s" % id)
	assert_lte(ids.size(), Trophies.CASE_COLS[1] * 3, "caben en la vitrina")
	assert_true(FileAccess.file_exists("res://models/%s.json" % Trophies.CASE_MODELS[1]))

func test_trofeos_de_los_logros_grandes() -> void:
	var big := Trophies.big_achievements().map(func(a: AchievementData) -> String: return String(a.id))
	for id in ["tres_caras", "tres_noches"]:
		assert_true(big.has(id), "%s es grande" % id)
		var m := String(Trophies.ACHIEVEMENT_MODELS.get(id, ""))
		assert_true(FileAccess.file_exists("res://models/%s.json" % m), "%s: su trofeo" % id)
	assert_lte(big.size(), Trophies.CASE_COLS[2] * 3, "caben en su vitrina")
