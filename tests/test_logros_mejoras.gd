extends GutTest
## Logros de los investigadores secretos y de la pesca (04-11-2026).

func _ach(id: String) -> AchievementData:
	for a in Achievements.all():
		if String(a.id) == id: return a
	return null

func test_existen_y_no_llenan_la_vitrina() -> void:
	for id in ["llave_de_plata", "sangre_de_dunwich", "paciencia_de_pescador", "lo_que_guarda_la_marea"]:
		var a := _ach(id)
		assert_not_null(a, id)
		if a != null: assert_lt(a.reward_money, Trophies.BIG_REWARD, "%s no es un logro grande (la vitrina tiene 12 huecos)" % id)
	assert_eq(Trophies.big_achievements().size(), 12)

func test_la_pesca_cuenta_piezas_y_especies() -> void:
	var s := SaveData.new()
	Fishing.record(s, "arenque", false)
	Fishing.record(s, "arenque", false)
	Fishing.record(s, "mano", true)
	assert_eq(Achievements.value(s, _ach("paciencia_de_pescador")), 3)
	assert_eq(Achievements.value(s, _ach("lo_que_guarda_la_marea")), 2)
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Fishing.PATH))
	assert_eq(_ach("lo_que_guarda_la_marea").target, (d.catches as Array).size(), "todas las especies del muelle")

func test_los_secretos_tienen_su_logro() -> void:
	for c in Secrets.all():
		var found := false
		for a in Achievements.all(): found = found or a.stat == "won_" + String(c.id)
		assert_true(found, "logro de %s" % c.id)
	var s := SaveData.new()
	Achievements.add(s, "won_carter")
	var done := Achievements.check(s)
	assert_true(done.any(func(a: AchievementData) -> bool: return a.id == &"llave_de_plata"))
