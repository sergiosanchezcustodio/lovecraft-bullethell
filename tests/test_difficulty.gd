extends GutTest
## Dificultad del 1 al 10 por características (D-42, temporal): el 3 es la Normal de antes, el 1
## casi Investigador y el 5 Pesadilla; tablas completas, red, migración y el menú de la pausa.

func after_each() -> void:
	Difficulty.forced = 0                                  # como la deja pre_run.gd

func test_cada_caracteristica_tiene_diez_niveles_que_suben() -> void:
	for c in Difficulty.CATS:
		for k in Difficulty.CATS[c]:
			if k == "name" or k == "help": continue
			var vals: Array = Difficulty.CATS[c][k]
			assert_eq(vals.size(), Difficulty.LEVELS, "%s/%s" % [c, k])
			if k == "ramp": continue                          # la rampa no es más dura por ser menor
			for i in range(1, vals.size()):
				if k == "warn": assert_true(vals[i] <= vals[i - 1], "el aviso baja: %s" % c)
				else: assert_true(vals[i] >= vals[i - 1], "sube: %s/%s %d" % [c, k, i + 1])

func test_el_3_es_la_normal_de_antes() -> void:
	Difficulty.forced = 3
	assert_almost_eq(Difficulty.value("numero", "rate"), 2.6, 0.001)
	assert_almost_eq(Difficulty.value("numero", "cap"), 1.5, 0.001)
	assert_almost_eq(Difficulty.value("numero", "ramp"), 0.4, 0.001)
	assert_almost_eq(Difficulty.damage(), 1.4, 0.001)
	assert_almost_eq(Difficulty.mental(), 1.7, 0.001)
	assert_almost_eq(Difficulty.horror(), 1.0, 0.001)
	assert_almost_eq(Difficulty.melee_speed(), 1.18, 0.001)
	for v in [Difficulty.health(), Difficulty.boss_health(), Difficulty.shooter_speed(), Difficulty.bullet_speed(),
			Difficulty.attack(), Difficulty.warn()]:
		assert_almost_eq(v, 1.0, 0.001, "lo nuevo, como antes")
	assert_eq(Difficulty.elites(2), 2)

func test_el_1_es_investigador_y_el_5_pesadilla() -> void:
	Difficulty.forced = 1
	assert_eq([Difficulty.value("numero", "rate"), Difficulty.value("numero", "cap"), Difficulty.damage(), Difficulty.mental(),
		Difficulty.horror(), Difficulty.melee_speed()], [1.0, 1.0, 1.0, 1.0, 0.4, 1.0])
	Difficulty.forced = 5
	assert_eq([Difficulty.value("numero", "rate"), Difficulty.value("numero", "cap"), Difficulty.damage(), Difficulty.mental(),
		Difficulty.horror(), Difficulty.melee_speed(), Difficulty.health()], [4.0, 1.8, 1.8, 2.2, 1.5, 1.32, 1.2])

func test_neutra_para_los_tests_y_elites_al_menos_una() -> void:
	Difficulty.forced = 0
	assert_eq(Difficulty.rate(), 1.0)
	assert_eq(Difficulty.damage(), 1.0)
	Difficulty.forced = 1
	assert_eq(Difficulty.elites(1), 1, "si el nivel tiene élites, al menos una")
	assert_eq(Difficulty.elites(0), 0)
	Difficulty.forced = 10
	assert_eq(Difficulty.elites(2), 6)

func test_en_red_manda_la_del_anfitrion() -> void:
	Difficulty.forced = -1
	Difficulty.set_net({"vida": 7, "dano": 12})
	var lv := Difficulty.levels()
	assert_eq(lv.vida, 7)
	assert_eq(lv.dano, 10, "dentro de 1..10")
	assert_eq(lv.numero, 3, "lo que no llega, el 3")
	assert_almost_eq(Difficulty.health(), 1.5, 0.001)
	assert_eq(Difficulty.general(), -1, "personalizada")
	Difficulty.net = null

func test_la_de_tres_pasa_a_1_3_o_5() -> void:
	var s = load("res://scripts/save/settings.gd").new()
	s.path = "user://test_settings_dificultad.json"
	var f := FileAccess.open(s.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"difficulty": 2}))
	f.close()
	s.load_file()
	assert_eq(int(s.values.dif_levels.vida), 5, "Pesadilla -> 5")
	f = FileAccess.open(s.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"difficulty": 1}))
	f.close()
	s.load_file()
	assert_eq(int(s.values.dif_levels.agresividad), 3, "Normal -> 3")
	DirAccess.remove_absolute(s.path)
	s.free()

func test_el_menu_dice_lo_que_multiplica() -> void:
	var n := DifficultyMenu.names_for("numero")
	assert_eq(n.size(), 10)
	assert_eq(n[2], "3  ·  ritmo ×2,6  ·  vivos ×1,5")
	assert_eq(DifficultyMenu.names_for("vida")[9], "10  ·  ×2,25")
