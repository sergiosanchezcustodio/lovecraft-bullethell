extends GutTest
## Evoluciones de armas (D-06): arma al nivel máximo + su objeto -> evolución en un baúl.

func test_cada_evolucion_existe_y_no_sale_al_subir_de_nivel() -> void:
	for w in DamageRules.all_weapons():
		if w.evolution == &"": continue
		var ev: WeaponData = load("res://data/weapons/%s.tres" % w.evolution)
		assert_not_null(ev, String(w.evolution))
		assert_true(ev.evolved, "%s marcada como evolución" % ev.id)
		assert_true(ResourceLoader.exists("res://data/upgrades/%s.tres" % w.evolves_with), String(w.evolves_with))

func test_evoluciona_solo_al_maximo_y_con_el_objeto() -> void:
	var ws := WeaponSystem.new()
	var w := ws.add_weapon(load("res://data/weapons/webly.tres"))
	assert_null(ws.evolvable({"iman": 1}), "nivel 1: todavía no")
	w.level = w.data.max_level
	assert_null(ws.evolvable({}), "sin la brújula, no")
	assert_eq(ws.evolvable({"iman": 1}), w)
	ws.evolve(w)
	assert_eq(String(w.data.id), "revolver_vigia")
	assert_null(ws.evolvable({"iman": 1}), "una evolución no vuelve a evolucionar")
	ws.free()

# ---------------- segunda rama (hito 16.8) y aviso en la subida (16.15) ----------------

func test_cada_arma_base_tiene_dos_ramas_distintas() -> void:
	var n := 0
	for w in DamageRules.all_weapons():
		if w.evolved or w.evolution == &"": continue
		n += 1
		var b := w.branches()
		assert_eq(b.size(), 2, "%s con dos ramas" % w.id)
		if b.size() < 2: continue
		assert_ne(b[0], b[1])
		var alt: WeaponData = load("res://data/weapons/%s.tres" % b[1])
		assert_not_null(alt, String(b[1]))
		assert_true(alt.evolved, "%s marcada como evolución" % alt.id)
		assert_eq(alt.evolution, &"", "una rama no vuelve a evolucionar")
		assert_ne(alt.description, "", "%s con descripción" % alt.id)
	assert_eq(n, 50, "las 50 armas base")

func _player() -> Player:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	for up in DebugOptions.list_resources("res://data/upgrades"):
		p.progress.upgrade_pool.append(up)
	return p

func test_elegir_la_segunda_rama() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/thompson.tres"))
	w.level = w.data.max_level
	p.progress.passives[w.data.evolves_with] = 1
	p.progress.pending = 2
	assert_true(p.progress.evolution_options(p.weapons).is_empty(), "sin baúl, nada que elegir")
	p.progress.evolving.append(&"thompson")
	var opts := p.progress.next_options(p.weapons, RandomNumberGenerator.new())
	assert_eq(opts.size(), 2, "las dos ramas")
	assert_eq(opts[0].kind, PlayerProgress.Option.Kind.EVOLUTION)
	assert_eq(String(opts[1].weapon.id), "thompson_federal")
	var o := p.progress.option_for(PlayerProgress.key_of(opts[1]), p.weapons)   # en red llega como clave
	assert_not_null(o)
	p.progress.choose(o, p)
	assert_eq(String(w.data.id), "thompson_federal")
	assert_eq(w.level, 1)
	assert_eq(p.progress.pending, 2, "elegir rama no gasta subidas")
	assert_true(p.progress.evolving.is_empty())
	assert_eq(p.progress.next_options(p.weapons, RandomNumberGenerator.new())[0].kind != PlayerProgress.Option.Kind.EVOLUTION, true,
		"después, la subida de siempre")

func test_la_rama_pendiente_se_olvida_si_ya_no_esta_el_arma() -> void:
	var p := _player()
	p.progress.evolving.append(&"thompson")
	assert_true(p.progress.evolution_options(p.weapons).is_empty())
	assert_true(p.progress.evolving.is_empty())

func test_aviso_de_evolucion_en_la_carta() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/webly.tres"))
	var item: UpgradeData = load("res://data/upgrades/%s.tres" % w.data.evolves_with)
	var o := PlayerProgress.Option.new()
	o.kind = PlayerProgress.Option.Kind.PASSIVE
	o.upgrade = item
	o.to_level = 1
	p.progress.mark_hint(o, p.weapons)
	assert_string_contains(o.evo_hint, "al nivel 5")
	assert_false(o.evo_ready)
	w.level = w.data.max_level
	p.progress.mark_hint(o, p.weapons)
	assert_eq(o.evo_hint, "Evoluciona: Webly Mk VI")
	assert_true(o.evo_ready, "completa la evolución: brilla")
	o.to_level = 2                                   # ya lo lleva: no avisa
	p.progress.mark_hint(o, p.weapons)
	assert_eq(o.evo_hint, "")
	# al revés: el arma al nivel 5 con el objeto ya puesto
	w.level = w.data.max_level - 1
	p.progress.passives[item.id] = 1
	var lv := PlayerProgress.Option.new()
	lv.kind = PlayerProgress.Option.Kind.WEAPON_LEVEL
	lv.weapon = w.data
	lv.to_level = w.data.max_level
	p.progress.mark_hint(lv, p.weapons)
	assert_true(lv.evo_ready)
	assert_string_contains(lv.evo_hint, item.display_name)
