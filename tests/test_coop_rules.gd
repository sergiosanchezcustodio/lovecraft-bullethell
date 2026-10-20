extends GutTest
## Reglas del cooperativo (hito 2.10): experiencia compartida con subidas por turnos (D-39),
## reanimación, escalado de la dificultad y subida de nivel por cuadrante.

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(id: String, pos: Vector3, i: int = 0) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Devices.COLORS[i])
	p.index = i
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.global_position = pos
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func test_la_experiencia_es_de_todos_y_se_sube_por_turnos() -> void:
	var rules: ProgressionData = load("res://data/progression/default.tres")
	var a := PlayerProgress.new(rules)
	var b := PlayerProgress.new(rules)
	var team := TeamXp.new(rules, [a, b] as Array[PlayerProgress])
	assert_almost_eq(team.xp_to_next(), rules.xp_to_next(1) * rules.coop_xp(2), 0.001)
	assert_eq(team.next(), a, "empieza J1")
	b.add_xp(team.xp_to_next() + 0.1)              # la recoge el J2, pero el turno es del J1
	assert_eq(a.level, 2)
	assert_eq(b.level, 1, "el otro espera su turno")
	assert_eq(a.pending, 1)
	assert_eq(b.pending, 0)
	assert_eq(team.next(), b)
	assert_almost_eq(b.xp_fraction(), a.xp_fraction(), 0.0001, "la barra es común")
	a.add_xp(team.xp_to_next())
	assert_eq(b.level, 2, "ahora sube el J2")
	assert_eq(team.next(), a, "y vuelve al J1")

func test_cada_subida_cuesta_segun_el_nivel_de_quien_tiene_el_turno() -> void:
	var rules: ProgressionData = load("res://data/progression/default.tres")
	var a := PlayerProgress.new(rules)
	var b := PlayerProgress.new(rules)
	var team := TeamXp.new(rules, [a, b] as Array[PlayerProgress])
	a.level = 6                                    # p. ej. con el Diario de expedición
	assert_almost_eq(team.xp_to_next(), rules.xp_to_next(6) * rules.coop_xp(2), 0.001)
	team.turn = 1
	assert_almost_eq(team.xp_to_next(), rules.xp_to_next(1) * rules.coop_xp(2), 0.001)

func test_cada_jugador_mejora_al_ritmo_de_antes() -> void:
	# antes subían todos a la vez con la curva ×1,5, ×1,9 y ×2,3; ahora uno por turno: entre N
	var rules: ProgressionData = load("res://data/progression/default.tres")
	var before := [1.0, 1.5, 1.9, 2.3]
	for n in range(1, 5):
		assert_almost_eq(rules.coop_xp(n) * n, before[n - 1], 0.05, "%d jugadores" % n)

func test_la_barra_lleva_el_color_de_quien_sube() -> void:
	var rules: ProgressionData = load("res://data/progression/default.tres")
	var a := PlayerProgress.new(rules)
	var b := PlayerProgress.new(rules)
	a.color = Color.RED
	b.color = Color.BLUE
	var team := TeamXp.new(rules, [a, b] as Array[PlayerProgress])
	assert_eq(b.xp_color(), Color.RED)
	team.add(team.xp_to_next())
	assert_eq(a.xp_color(), Color.BLUE)
	assert_true(b.is_next(), "el marco va a quien sube la próxima vez")
	assert_false(a.is_next())
	assert_false(PlayerProgress.new(rules).is_next(), "en solitario, sin marco")

func test_un_companero_al_lado_reanima_al_derribado() -> void:
	var down := _player("dyer", Vector3.ZERO, 0)
	var helper := _player("olmstead", Vector3(1, 0, 0), 1)
	down.revivable = true
	down.take_damage(Damage.new(9999, 0))
	assert_true(down.is_downed())
	var revived := [false]
	down.revived.connect(func() -> void: revived[0] = true)
	for i in int((down.rules.revive_time + 0.1) / DT): down._physics_process(DT)
	assert_true(revived[0])
	assert_gt(down.health, 0.0)
	assert_almost_eq(down.health, down.data.max_health * down.rules.revive_health, 0.01)
	assert_true(is_instance_valid(helper))

func test_sin_nadie_al_lado_queda_eliminado() -> void:
	var down := _player("dyer", Vector3.ZERO, 0)
	_player("olmstead", Vector3(10, 0, 0), 1)
	down.revivable = true
	down.take_damage(Damage.new(9999, 0))
	var gone := [false]
	down.eliminated.connect(func() -> void: gone[0] = true)
	for i in int((down.rules.down_time + 0.2) / DT): down._physics_process(DT)
	assert_true(gone[0])
	assert_true(down.is_eliminated)
	assert_false(down.is_downed())

func test_whipple_reanima_antes() -> void:
	var a := _player("dyer", Vector3.ZERO, 0)
	var doc := _player("whipple", Vector3(1, 0, 0), 1)
	a.revivable = true
	a.take_damage(Damage.new(9999, 0))
	for i in 60: a._physics_process(DT)
	assert_almost_eq(a.revive_progress, 1.0 * doc.data.revive_speed, 0.05)

func test_en_solitario_no_hay_derribo() -> void:
	var p := _player("dyer", Vector3.ZERO)
	p.take_damage(Damage.new(9999, 0))
	assert_eq(p.down_left, -1.0)

func test_la_dificultad_crece_con_los_jugadores() -> void:
	var lv := LevelData.new()
	assert_eq(LevelData.coop(lv.coop_health, 1), 1.0)
	assert_gt(LevelData.coop(lv.coop_health, 4), LevelData.coop(lv.coop_health, 2))
	assert_gt(LevelData.coop(lv.coop_spawn, 3), 1.0)
	assert_eq(LevelData.coop(lv.coop_spawn, 9), lv.coop_spawn[lv.coop_spawn.size() - 1], "más de 4: el último")

func test_la_subida_por_cuadrante_termina_cuando_eligen_todos() -> void:
	var a := _player("dyer", Vector3.ZERO, 0)
	var b := _player("olmstead", Vector3(2, 0, 0), 1)
	var rng := RandomNumberGenerator.new()
	var entries: Array[Dictionary] = []
	for q in [a, b]:
		q.progress.weapon_pool.append(load("res://data/weapons/tesla.tres"))
		q.progress.pending = 1
		entries.append({"player": q, "options": q.progress.roll_options(q.weapons, rng), "title": "J"})
	var picked := []
	var menu := CoopLevelUp.new(entries, func(q: Player, o: PlayerProgress.Option) -> void:
		picked.append(q)
		q.progress.choose(o, q))
	var done := [false]
	menu.finished.connect(func() -> void: done[0] = true)
	add_child(menu)
	for i in 90: menu._process(DT)
	assert_eq(picked.size(), 2, "los bots eligen solos")
	assert_true(done[0])
	assert_eq(a.progress.pending, 0)
	assert_eq(b.progress.pending, 0)
