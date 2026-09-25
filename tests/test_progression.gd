extends GutTest

const DT := 1.0 / 60.0
var rules: ProgressionData

func before_each() -> void:
	rules = load("res://data/progression/default.tres")

func _player() -> Player:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	p.weapons.add_weapon(load("res://data/weapons/dinamita.tres"))
	p.progress.weapon_pool = [load("res://data/weapons/dinamita.tres"), load("res://data/weapons/revolver.tres")] as Array[WeaponData]
	for f in ["velocidad", "vida", "cordura", "reflejos", "iman"]:
		p.progress.upgrade_pool.append(load("res://data/upgrades/%s.tres" % f))
	return p

# ---------------- experiencia ----------------
func test_curva_de_experiencia_creciente() -> void:
	assert_eq(rules.xp_to_next(1), rules.xp_base)
	var prev := 0.0
	for lv in range(1, 15):
		var need := rules.xp_to_next(lv)
		assert_gt(need, prev, "el nivel %d pide más que el anterior" % lv)
		prev = need

func test_subir_varios_niveles_de_golpe() -> void:
	var pr := PlayerProgress.new(rules)
	watch_signals(pr)
	pr.add_xp(rules.xp_to_next(1) + rules.xp_to_next(2) + 1.0)
	assert_eq(pr.level, 3)
	assert_eq(pr.pending, 2)
	assert_almost_eq(pr.xp, 1.0, 0.001)
	assert_signal_emit_count(pr, "leveled_up", 2)

# ---------------- mejoras ----------------
func test_opciones_distintas_y_validas() -> void:
	var p := _player()
	var rng := RandomNumberGenerator.new(); rng.seed = 1
	for i in 20:
		var opts := p.progress.roll_options(p.weapons, rng)
		assert_eq(opts.size(), 3)
		var keys := {}
		for o in opts:
			var k := o.title()
			assert_false(keys.has(k), "opción repetida: " + k)
			keys[k] = true
			if o.kind == PlayerProgress.Option.Kind.NEW_WEAPON:
				assert_null(p.weapons.get_weapon(o.weapon.id), "no ofrece como nueva un arma que ya tiene")

func test_elegir_arma_nueva_subir_arma_y_pasiva() -> void:
	var p := _player()
	var o := PlayerProgress.Option.new()
	o.kind = PlayerProgress.Option.Kind.NEW_WEAPON
	o.weapon = load("res://data/weapons/revolver.tres")
	p.progress.choose(o, p)
	assert_not_null(p.weapons.get_weapon(&"revolver"))
	o = PlayerProgress.Option.new()
	o.kind = PlayerProgress.Option.Kind.WEAPON_LEVEL
	o.weapon = load("res://data/weapons/dinamita.tres")
	o.to_level = 2
	p.progress.choose(o, p)
	assert_eq(p.weapons.get_weapon(&"dinamita").level, 2)
	var speed := p.data.move_speed
	o = PlayerProgress.Option.new()
	o.kind = PlayerProgress.Option.Kind.PASSIVE
	o.upgrade = load("res://data/upgrades/velocidad.tres")
	o.to_level = 1
	p.progress.choose(o, p)
	assert_almost_eq(p.data.move_speed, speed * 1.08, 0.001)

func test_las_pasivas_no_tocan_el_recurso_compartido() -> void:
	var p := _player()
	var o := PlayerProgress.Option.new()
	o.kind = PlayerProgress.Option.Kind.PASSIVE
	o.upgrade = load("res://data/upgrades/vida.tres")
	o.to_level = 1
	p.progress.choose(o, p)
	assert_eq(p.data.max_health, 120.0)
	assert_eq(p.health, 120.0, "la vida ganada se rellena")
	var shared: CharacterData = load("res://data/characters/dyer.tres")
	assert_eq(shared.max_health, 100.0, "el .tres del personaje no cambia")

func test_armas_al_maximo_no_se_ofrecen() -> void:
	var p := _player()
	p.weapons.get_weapon(&"dinamita").level = 5
	p.progress.weapon_pool = [load("res://data/weapons/dinamita.tres")] as Array[WeaponData]
	p.progress.upgrade_pool.clear()
	var rng := RandomNumberGenerator.new()
	assert_eq(p.progress.roll_options(p.weapons, rng).size(), 0)

# ---------------- cordura y crisis ----------------
func test_recuperacion_de_cordura() -> void:
	var s := SanityState.new(rules)
	var san := s.update(1.0, 50.0, 100.0, false)
	assert_gt(san, 50.0, "se recupera lejos de los horrores")
	assert_eq(s.update(1.0, 50.0, 100.0, true), 50.0, "cerca de un enemigo no")
	s.on_mental_damage()
	assert_eq(s.update(0.5, 50.0, 100.0, false), 50.0, "justo después de un daño mental no")

func test_crisis_de_paralisis_intermitente() -> void:
	var s := SanityState.new(rules)
	s.rng.seed = 3
	s.update(DT, 0.0, 100.0, false)
	assert_true(s.in_crisis)
	assert_eq(s.crisis_kind, &"paralisis")
	assert_between(s.crisis_duration, rules.crisis_min, rules.crisis_max)
	var frozen := 0.0
	var trembling := 0.0
	var t := 0.0
	var san := 0.0
	while s.in_crisis and t < 10.0:
		if s.is_frozen(): frozen += DT
		if s.is_trembling(): trembling += DT
		san = s.update(DT, san, 100.0, false)
		t += DT
	assert_false(s.in_crisis, "la crisis termina")
	assert_almost_eq(t, s.crisis_duration, 0.05)
	var cycles := s.crisis_duration / rules.paralysis_period
	assert_almost_eq(frozen, cycles * rules.paralysis_freeze, 0.5, "congelado a ratos, no todo el tiempo")
	assert_gt(trembling, 0.0, "cada congelación se avisa")
	assert_almost_eq(san, 100.0 * rules.crisis_restore, 0.001, "recupera el 30 %")

func test_el_jugador_congelado_no_se_mueve_pero_dispara() -> void:
	var p := _player()
	p.sanity = 0.0
	var e := TrainingDummy.new().setup(p.world, "pinguino")
	e.position = Vector3(4, 0, 0)
	p.world.add_child(e)
	p.world.rebuild_grid()
	var froze := false
	for i in 90:
		p._physics_process(DT)
		if p.sanity_state.is_frozen():
			froze = true
			assert_true(p.motor.locked)
			assert_eq(p.motor.step(DT, Vector2(1, 0), true), Vector3.ZERO)
	assert_true(froze)

func test_muerte_al_perder_toda_la_vida() -> void:
	var p := _player()
	watch_signals(p)
	p.take_damage(Damage.new(999, 0))
	assert_eq(p.health, 0.0)
	assert_signal_emitted(p, "downed")
	assert_false(p.is_hittable())
