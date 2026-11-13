extends GutTest
## Hito 21.5: los compañeros crecen. Al nivel PetTricks.level() de su jugador eligen entre dos trucos
## (data/pet_tricks.json), con dos cartas en la ventana de la subida que no gastan la subida.

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player() -> Player:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _pet(id: String, p: Player) -> Pet:
	var pet := Pet.new().setup(load("res://data/pets/%s.tres" % id), p, world, null)
	world.add_child(pet)
	p.pet = pet
	return pet

func _dummy(at: Vector3) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	d.max_health = 1000.0
	d.move_speed = 0.0
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _run(pet: Pet, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		pet._physics_process(DT)

func test_cada_companero_tiene_dos_trucos_bien_hechos() -> void:
	var fields := PetData.new()
	for r in DebugOptions.list_resources("res://data/pets"):
		var id := String((r as PetData).id)
		var ts := PetTricks.for_pet(id)
		assert_eq(ts.size(), 2, id)
		var seen := {}
		for t: Dictionary in ts:
			assert_false(seen.has(t.id), "%s: %s repetido" % [id, t.id])
			seen[t.id] = true
			assert_ne(String(t.get("nombre", "")), "", "%s %s" % [id, t.id])
			assert_ne(String(t.get("texto", "")), "", "%s %s" % [id, t.id])
			var mods: Dictionary = t.get("mods", {})
			var fx := String(t.get("efecto", ""))
			assert_true(fx in PetTricks.EFFECTS, "%s: efecto %s" % [t.id, fx])
			assert_true(fx != "" or not mods.is_empty(), "%s hace algo" % t.id)
			for k: String in mods:
				assert_true(k.ends_with("*") or k.ends_with("+"), "%s: %s" % [t.id, k])
				assert_true(k.trim_suffix("*").trim_suffix("+") in fields, "%s: %s no es de PetData" % [t.id, k])

func test_al_nivel_cinco_se_ofrecen_sus_dos_trucos_sin_gastar_la_subida() -> void:
	var p := _player()
	var pet := _pet("gato", p)
	assert_eq(p.progress.pet_id, "gato", "el compañero se apunta en el progreso")
	p.progress.level = PetTricks.level() - 1
	assert_true(p.progress.trick_options().is_empty(), "aún no")
	p.progress.level = PetTricks.level()
	p.progress.pending = 1
	assert_true(p.progress.has_special(p.weapons))
	var opts := p.progress.next_options(p.weapons, RandomNumberGenerator.new())
	assert_eq(opts.size(), 2)
	for o in opts: assert_eq(o.kind, PlayerProgress.Option.Kind.TRICK)
	assert_eq(PlayerProgress.key_of(opts[1]), "t:ronroneo")
	var again := p.progress.option_for("t:ronroneo", p.weapons)
	assert_not_null(again, "en red, la clave vuelve a dar la carta")
	p.progress.choose(again, p)
	assert_eq(p.progress.pet_trick, "ronroneo")
	assert_eq(pet.trick.get("id"), "ronroneo", "lo aprende en el momento")
	assert_eq(p.progress.pending, 1, "no gasta la subida")
	assert_false(p.progress.has_special(p.weapons), "y no se vuelve a ofrecer")
	assert_ne(opts[0].title(), "")
	assert_ne(opts[0].text(), "")

func test_sin_companero_no_hay_trucos() -> void:
	var p := _player()
	p.progress.level = 9
	assert_true(p.progress.trick_options().is_empty())

func test_los_mods_cambian_una_copia() -> void:
	var p := _player()
	var pet := _pet("sapo", p)
	var base := pet.data
	var every := base.attack_every
	pet.learn("buen_escupidor")
	assert_almost_eq(pet.data.attack_every, every * 0.55, 0.001)
	assert_almost_eq(base.attack_every, every, 0.001, "el recurso no se toca")
	pet.learn("")
	assert_eq(pet.data, base, "olvidarlo vuelve a sus datos")

func test_el_truco_va_en_el_progreso_y_lo_aprende_solo() -> void:
	var p := _player()
	var pet := _pet("perro", p)
	p.progress.pet_trick = "arrastre"
	_run(pet, DT)
	assert_eq(pet.trick.get("id"), "arrastre", "al ver el progreso (red, nivel siguiente)")
	assert_almost_eq(pet.knock_k(), 4.0, 0.001)
	var snap := GameSession.snapshot(p)
	assert_eq(snap.get("trick"), "arrastre")
	p.progress.pet_trick = ""
	GameSession.restore(p, snap)
	assert_eq(p.progress.pet_trick, "arrastre", "pasa de un nivel a otro")

func test_dos_zarpas_da_tambien_al_de_al_lado() -> void:
	var p := _player()
	var pet := _pet("migo", p)
	pet.learn("cadena")
	var a := _dummy(Vector3(2, 0, 0))
	var b := _dummy(Vector3(3.5, 0, 0))
	world.rebuild_grid()
	pet.strike(a)
	assert_lt(a.health, 1000.0)
	assert_lt(b.health, 1000.0, "salta al más cercano")
	assert_eq(pet.hits, 2)

func test_el_ronroneo_duerme_cada_tres_golpes() -> void:
	var p := _player()
	var pet := _pet("gato", p)
	pet.learn("ronroneo")
	var e := _dummy(Vector3(1, 0, 0))
	for i in 2:
		pet.on_hit(e)
		pet._hit_frame = -1                         # golpes en pasos distintos
	assert_false(e.is_dreaming())
	pet.on_hit(e)
	assert_true(e.is_dreaming(), "al tercero, se duerme")

func test_el_aullido_confunde_a_los_de_alrededor() -> void:
	var p := _player()
	var pet := _pet("perro", p)
	pet.learn("aullido")
	var e := _dummy(Vector3(2, 0, 0))
	world.rebuild_grid()
	pet._trick_t = 0.0
	pet._trick_step(DT)
	assert_true(e.is_confused())
	assert_gt(pet._trick_t, 6.0, "y espera a volver a aullar")

func test_la_vigilia_devuelve_cordura() -> void:
	var p := _player()
	var pet := _pet("buho", p)
	pet.learn("vigilia")
	p.sanity = 10.0
	for i in 60: pet._trick_step(DT)
	assert_almost_eq(p.sanity, 10.5, 0.02)

func test_la_leche_de_cabra_cura() -> void:
	var p := _player()
	var pet := _pet("cabra", p)
	pet.learn("leche")
	p.health = 50.0
	var e := _dummy(Vector3(1, 0, 0))
	pet.on_hit(e)
	assert_almost_eq(p.health, 50.0 + p.data.max_health * 0.01, 0.01)
