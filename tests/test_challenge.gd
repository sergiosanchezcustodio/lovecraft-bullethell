extends GutTest
## Modo desafío (hito 15.2): datos, nivel, reglas y registro.

const KNOWN := ["no_dodge", "one_weapon", "arcane_only", "max_health", "spawn_rate", "enemy_health",
	"enemy_speed", "light", "lamp", "split_elites", "no_heal", "no_regen", "bullet_trail", "pet_idle"]

func after_each() -> void:
	Challenge.begin("")

func test_un_desafio_por_nivel_y_bien_hecho() -> void:
	var all := Challenge.all()
	assert_eq(all.size(), 15)
	var seen := {}
	for c: Dictionary in all:
		var base := String(c.level)
		assert_false(seen.has(base), "repetido: " + base)
		seen[base] = true
		assert_true(Campaign.exists(base), base)
		assert_ne(String(c.get("name", "")), "", base)
		assert_ne(String(c.get("text", "")), "", base)
		for k: String in c.effects: assert_true(KNOWN.has(k), "%s: efecto desconocido %s" % [base, k])

func test_el_nivel_del_desafio() -> void:
	assert_true(Challenge.is_challenge("desafio:p2_n3"))
	assert_eq(Challenge.base_of("desafio:p2_n3"), "p2_n3")
	var lv := Challenge.make_level("desafio:p1_n4")
	assert_eq(String(lv.id), "desafio:p1_n4")
	assert_true(lv.display_name.begins_with("Desafío · "))
	assert_eq(Campaign.next_in_part(String(lv.id)), "", "un desafío no sigue con la parte")

func test_reglas_activas_solo_en_un_desafio() -> void:
	Challenge.begin("desafio:p1_n4")
	assert_almost_eq(Challenge.value("max_health"), 0.5, 0.001)
	Challenge.begin("desafio:p2_n3")
	assert_almost_eq(Pacts.value("enemy_speed"), 1.3, 0.001, "las palancas de los pactos lo leen")
	Challenge.begin("desafio:p1_n5")
	assert_true(Pacts.has("no_heal"))
	Challenge.begin("p1_n5")
	assert_false(Challenge.active())
	assert_almost_eq(Challenge.value("max_health"), 1.0, 0.001)

func test_armas_nuevas_segun_el_desafio() -> void:
	var fire: WeaponData = load("res://data/weapons/webly.tres")
	var magic: WeaponData = null
	for w in DebugOptions.list_resources("res://data/weapons"):
		if (w as WeaponData).category == WeaponData.Category.MAGIC: magic = w
	assert_not_null(magic)
	assert_true(Challenge.new_weapon_ok(fire))
	Challenge.begin("desafio:p2_n2")                 # solo arcanas
	assert_false(Challenge.new_weapon_ok(fire))
	assert_true(Challenge.new_weapon_ok(magic))
	Challenge.begin("desafio:p1_n2")                 # una sola arma
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	autofree(p)
	var world := CombatWorld.new()
	add_child_autofree(world)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	for w in DebugOptions.list_resources("res://data/weapons"): p.progress.weapon_pool.append(w)
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	for i in 30:
		for o in p.progress.roll_options(p.weapons, rng):
			assert_ne(o.kind, PlayerProgress.Option.Kind.NEW_WEAPON, "sin armas nuevas")

func test_superados_se_cuentan_una_vez() -> void:
	var s := SaveData.new()
	assert_true(Challenge.record_win(s, "desafio:p1_n1", 300.0), "la primera vez es récord")
	assert_false(Challenge.record_win(s, "desafio:p1_n1", 320.0), "más lento, no")
	assert_true(Challenge.record_win(s, "desafio:p1_n1", 280.0), "más rápido, sí")
	assert_almost_eq(Challenge.best(s, "p1_n1"), 280.0, 0.01)
	Challenge.record_win(s, "desafio:p2_n1", 250.0)
	assert_eq(Challenge.won_count(s), 2)
	assert_true(Challenge.won(s, "p1_n1"))
	assert_true(s.levels_won.is_empty(), "no cuentan como niveles de campaña")
	var back := SaveData.from_dict(s.to_dict())
	assert_eq(Challenge.won_count(back), 2, "se guardan")

func test_el_diario_habla_del_desafio() -> void:
	var base := {"character": "dyer", "name": "William Dyer", "result": "won", "t": 300.0, "part": 1,
		"place": "Campamento", "date": "2026-10-31", "challenge": "Frágil como el hielo"}
	var won := Diary.compose(base, 1)
	assert_true("Frágil como el hielo" in String(won.text), String(won.text))
	var rec := base.duplicate()
	rec["record"] = true
	var e := Diary.compose(rec, 2)
	var lines: Array = (Diary.data().challenge as Dictionary).record
	var hit := false
	for l: String in lines:
		if l.format({"desafio": "Frágil como el hielo", "tiempo": "5:00"}).substr(1) in String(e.text): hit = true
	assert_true(hit, "frase de récord: " + String(e.text))
