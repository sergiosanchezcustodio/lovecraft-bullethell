extends GutTest
## Signos Mayores (hito 16.9): datos, cuándo se ganan, la elección y algunos efectos.

var world: CombatWorld
var p: Player

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	p = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	for up in DebugOptions.list_resources("res://data/upgrades"):
		p.progress.upgrade_pool.append(up)

func _save(all := true) -> SaveData:
	var s := SaveData.new()
	s.unlock_all = all
	return s

func test_datos_validos() -> void:
	var ids := {}
	var ach := {}
	for a in Achievements.all(): ach[String(a.id)] = true
	assert_eq(Signs.all().size(), 8)
	for s: Dictionary in Signs.all():
		assert_false(ids.has(s.id), "id repetido %s" % s.id)
		ids[s.id] = true
		assert_ne(String(s.get("name", "")), "")
		assert_ne(String(s.get("text", "")), "")
		assert_true(ach.has(String(s.unlock)), "%s: el logro %s existe" % [s.id, s.unlock])
		assert_gt(float(s.get("value", 0.0)), 0.0, "%s con valor" % s.id)

func test_uno_al_empezar_la_parte_y_otro_en_el_tercer_nivel() -> void:
	assert_eq(Signs.due(1), 1)
	assert_eq(Signs.due(2), 1)
	assert_eq(Signs.due(3), 2)
	assert_eq(Signs.due(5), 2)

func test_se_abren_con_logros() -> void:
	var s := _save(false)
	assert_true(Signs.unlocked(s).is_empty(), "sin logros, ninguno")
	s.achievements["cazador_100"] = "2026-11-03"
	assert_eq(Signs.unlocked(s), ["yog"] as Array[String])
	assert_eq(Signs.unlocked(_save()).size(), 8, "partida de pruebas: todos")
	assert_true(Signs.unlocked(null).is_empty())

func test_elegir_un_signo() -> void:
	p.progress.sign_save = _save()
	p.progress.signs_pending = 1
	p.progress.pending = 1
	var rng := RandomNumberGenerator.new()
	assert_true(p.progress.has_special(p.weapons))
	var opts := p.progress.next_options(p.weapons, rng)
	assert_eq(opts.size(), Signs.OFFER)
	assert_eq(opts[0].kind, PlayerProgress.Option.Kind.SIGN)
	var o := p.progress.option_for(PlayerProgress.key_of(opts[1]), p.weapons)   # en red llega como clave
	assert_not_null(o)
	p.progress.choose(o, p)
	assert_eq(p.progress.signs.size(), 1)
	assert_eq(p.progress.signs_pending, 0)
	assert_eq(p.progress.pending, 1, "elegir signo no gasta subidas")
	assert_false(p.progress.has_special(p.weapons))
	assert_ne(p.progress.next_options(p.weapons, rng)[0].kind, PlayerProgress.Option.Kind.SIGN)
	# no se ofrece el que ya lleva
	p.progress.signs_pending = 1
	for k in 20:
		for x in p.progress.sign_options(rng): assert_false(p.progress.signs.has(StringName(String(x.sign.id))))

func test_sin_signos_abiertos_no_hay_nada_que_elegir() -> void:
	p.progress.sign_save = _save(false)
	p.progress.signs_pending = 1
	assert_false(p.progress.has_special(p.weapons))
	assert_eq(p.progress.signs_pending, 0)

func test_pasan_de_nivel_con_el_progreso() -> void:
	p.progress.signs.append(&"cthugha")
	p.progress.signs.append(&"yog")
	var d := GameSession.snapshot(p)
	p.progress.signs.clear()
	GameSession.restore(p, d)
	assert_eq(p.progress.signs, [&"cthugha", &"yog"] as Array[StringName])

func test_nyarlathotep_y_tsathoggua_en_las_estadisticas() -> void:
	p.rebuild_stats()
	var crit := p.data.crit_chance
	assert_false(p.data.bonus_tags.has(Player.HELD_TAG))
	p.progress.signs.append(&"nyarlathotep")
	p.progress.signs.append(&"tsathoggua")
	p.rebuild_stats()
	assert_almost_eq(p.data.crit_chance, crit + Signs.value("nyarlathotep"), 0.001)
	assert_eq(float(p.data.bonus_tags.get(Player.HELD_TAG, 1.0)), Signs.value("tsathoggua"))

func test_hastur_sopla_cada_25_bajas() -> void:
	p.progress.signs.append(&"hastur")
	var waves := func() -> int: return world.fx.get_children().filter(func(n: Node) -> bool: return n is Shockwave).size()
	for k in int(Signs.value("hastur")) - 1: p.on_kill()
	assert_eq(waves.call(), 0, "aún no")
	p.on_kill()
	assert_eq(waves.call(), 1, "el viento")

func test_cthugha_deja_fuego_al_explotar() -> void:
	p.progress.signs.append(&"cthugha")
	var w := p.weapons.add_weapon(load("res://data/weapons/granada.tres"))
	var before := world.fx.get_child_count()
	p.weapons._throw(w, p.global_position + Vector3(3, 0, 0))
	var e: ThrownExplosive = world.fx.get_child(before)
	assert_false(e.zone.is_empty(), "la granada lleva fuego")
	assert_eq(int(e.zone.kind), WeaponData.Zone.FIRE)
