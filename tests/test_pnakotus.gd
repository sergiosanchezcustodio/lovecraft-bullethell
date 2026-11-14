extends GutTest
## Hito 21.15: la noche suelta «La sombra fuera del tiempo». Las trampillas de la Gran Raza y el viento
## (PolypWinds), los pólipos que casi no se ven (PolypBehavior) y el pólipo antiguo (PolypBossBehavior).

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(id := "dyer", at := Vector3.ZERO) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	p.position = at
	world.add_child(p)
	world.add_player(p)
	return p

func _enemy(id: String, at: Vector3, still := true) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/%s.tres" % id) as EnemyData).duplicate()
	if still:
		d.max_health = 1000.0
		d.move_speed = 0.0
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _winds(host := true) -> PolypWinds:
	var lv: LevelData = load("res://data/levels/noche_pnakotus.tres")
	var pw := PolypWinds.new().setup(world, lv, host)
	pw._next = 999.0                                  # sin trampillas sueltas: solo las de la prueba
	add_child_autofree(pw)
	return pw

func _step(pw: PolypWinds, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		for q in world.players: q.push = Vector3.ZERO
		pw._physics_process(DT)

func _at(pw: PolypWinds, i: int, off := Vector2.ZERO) -> Vector3:
	var p: Vector2 = pw.doors[i].pos + off
	return Vector3(p.x, 0.0, p.y)

# ------------------------------------------------------------------ la noche

func test_la_noche_y_su_nivel() -> void:
	var n := Nights.find("noche_pnakotus")
	assert_false(n.is_empty())
	var lv: LevelData = load("res://data/levels/noche_pnakotus.tres")
	assert_eq(String(lv.final_enemy.id), "polipo_antiguo")
	assert_gt(lv.trap_every, 0.0, "con trampillas")
	assert_lt(lv.trap_final_every, lv.trap_every, "más a menudo con el jefe suelto")
	assert_not_null(lv.trap_enemy)
	assert_true(bool(lv.trap_enemy.param("polyp", false)), "de las trampillas salen pólipos")
	assert_true(lv.pool.any(func(d: EnemyData) -> bool: return d.tags.has(&"humana")), "y los poseídos, que son de este mundo")
	assert_not_null(lv.weather)

func test_las_trampillas_de_la_arena() -> void:
	var pw := _winds()
	assert_eq(pw.doors.size(), 6, "las seis de la arena")
	assert_ne(pw.great, Vector2.INF, "y la gran trampilla del archivo")
	for d in pw.doors:
		assert_eq(d.state, PolypWinds.State.CLOSED)
		assert_not_null(d.lid, "con su tapa")

func test_las_trampillas_se_pisan() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/pnakotus.json"))
	var om := ObstacleMap.new()
	assert_true(om.load_mask(layout.mask))
	for p in layout.trapdoors + [layout.great_door]:
		assert_false(om.is_blocked(Vector2(p[0], p[1]), 0.4), "se puede estar en medio de la trampilla %s" % str(p))


# ------------------------------------------------------------------ las trampillas

func test_una_trampilla_silba_se_abre_y_sopla() -> void:
	var pw := _winds()
	var p := _player("dyer", _at(pw, 0, Vector2(3.0, 0.0)))
	pw.warn_door(0)
	assert_eq(pw.doors[0].state, PolypWinds.State.WARN)
	_step(pw, pw.level.trap_warn + 0.1)
	assert_eq(pw.doors[0].state, PolypWinds.State.OPEN)
	assert_eq(pw.opened, 1)
	_step(pw, DT)
	assert_gt(p.push.x, 0.5, "el viento aparta")
	p.position = _at(pw, 0, Vector2(0.3, 0.0))
	_step(pw, DT)
	assert_lt(p.push.length(), 0.2, "en medio, calma")
	p.position = _at(pw, 0, Vector2(pw.level.trap_wind_radius + 1.0, 0.0))
	_step(pw, DT)
	assert_eq(p.push, Vector3.ZERO, "lejos, nada")

func test_se_sella_de_pie_en_medio() -> void:
	var pw := _winds()
	var p := _player("dyer", _at(pw, 1, Vector2(12.0, 0.0)))
	pw.open_door(1)
	_step(pw, 0.5)
	p.position = _at(pw, 1)
	_step(pw, pw.level.trap_seal * 0.5)
	assert_eq(pw.doors[1].state, PolypWinds.State.OPEN, "aún no")
	assert_gt(float(pw.doors[1].seal), 0.3)
	p.position = _at(pw, 1, Vector2(5.0, 0.0))
	_step(pw, 0.5)
	var left := float(pw.doors[1].seal)
	assert_lt(left, 0.5, "si se sale, lo hecho se pierde despacio")
	assert_gt(left, 0.0)
	p.position = _at(pw, 1)
	_step(pw, pw.level.trap_seal + 0.1)
	assert_eq(pw.doors[1].state, PolypWinds.State.CLOSED)
	assert_eq(pw.sealed, 1)

func test_peaslee_las_sella_antes() -> void:
	var pw := _winds()
	var a := _player("dyer", _at(pw, 0))
	var b := _player("peaslee", _at(pw, 2))
	pw.open_door(0)
	pw.open_door(2)
	_step(pw, pw.level.trap_seal / PolypWinds.PEASLEE + 0.1)
	assert_eq(pw.doors[2].state, PolypWinds.State.CLOSED, "Peaslee, que las vio en sueños")
	assert_eq(pw.doors[0].state, PolypWinds.State.OPEN, "Dyer aún no")
	assert_not_null(a); assert_not_null(b)

func test_sellarla_mientras_silba_no_la_deja_abrirse() -> void:
	var pw := _winds()
	_player("dyer", _at(pw, 3))
	pw.warn_door(3)
	_step(pw, pw.level.trap_warn + 0.2)
	assert_eq(pw.doors[3].state, PolypWinds.State.CLOSED)
	assert_eq(pw.opened, 0, "no llegó a abrirse")
	assert_eq(pw.sealed, 1)

func test_las_cerradas_se_abren_al_azar_y_con_tope() -> void:
	var pw := _winds()
	_player("dyer", Vector3(60, 0, 60))
	pw._next = 0.0
	for k in 10:
		pw._next = 0.0
		_step(pw, DT)
	assert_eq(pw.open_count(), pw.level.trap_max, "como mucho trap_max a la vez")

func test_en_el_invitado_las_trampillas_llegan_del_anfitrion() -> void:
	var pw := _winds(false)
	_player("dyer", _at(pw, 0, Vector2(20.0, 0.0)))
	pw.remote({"a": "warn", "i": 4})
	assert_eq(pw.doors[4].state, PolypWinds.State.WARN)
	_step(pw, pw.level.trap_warn + 1.0)
	assert_eq(pw.doors[4].state, PolypWinds.State.WARN, "no la abre por su cuenta")
	pw.remote({"a": "open", "i": 4})
	assert_eq(pw.doors[4].state, PolypWinds.State.OPEN)
	pw.remote({"a": "seal", "i": 4})
	assert_eq(pw.doors[4].state, PolypWinds.State.CLOSED)
	pw.remote({"a": "great", "o": 1})
	assert_eq(pw.great_door.state, PolypWinds.State.OPEN)

func test_el_aliento_tira_de_todos() -> void:
	var pw := _winds()
	var p := _player("dyer", Vector3(40, 0, 40))
	pw.pull(Vector3(30, 0, 40), 1.0, 2.5)
	_step(pw, DT)
	assert_lt(p.push.x, -1.0, "hacia el jefe")
	_step(pw, 1.1)
	_step(pw, DT)
	assert_eq(p.push, Vector3.ZERO, "y se acaba")

# ------------------------------------------------------------------ los pólipos

func test_el_polipo_casi_no_se_ve_salvo_de_cerca_o_al_darle() -> void:
	var pw := _winds()
	var p := _player("dyer", Vector3(40, 0, 40))
	var e := _enemy("polipo_volador", Vector3(50, 0, 40))
	await get_tree().process_frame
	pw._process(DT)
	assert_almost_eq(pw.alpha_of(e), PolypWinds.MIN_ALPHA, 0.02, "de lejos, casi nada")
	e.take_damage(Damage.new(3.0, 0.0))
	pw._process(DT)
	assert_gt(pw.alpha_of(e), 0.5, "al recibir un golpe, se ve")
	p.position = Vector3(49, 0, 40)
	for k in 90: pw._process(DT)
	assert_almost_eq(pw.alpha_of(e), PolypWinds.MAX_ALPHA, 0.02, "de cerca, del todo")

func test_el_remolino_de_arena_lo_delata() -> void:
	var pw := _winds()
	_player("dyer", Vector3(40, 0, 40))
	_enemy("polipo_volador", Vector3(50, 0, 40))
	_enemy("poseido_yith", Vector3(45, 0, 45))
	await get_tree().process_frame
	pw._process(DT)
	assert_eq(pw._mm.multimesh.visible_instance_count, PolypWinds.GRAINS, "granos alrededor del pólipo, no del poseído")

func test_el_polipo_avisa_y_embiste() -> void:
	var p := _player("dyer", Vector3(0, 0, 0))
	var e := _enemy("polipo_volador", Vector3(4, 0, 0), false)
	var b := e.behavior as PolypBehavior
	assert_not_null(b)
	assert_true(e.data.ethereal, "atraviesa el decorado")
	assert_gt(e.position.y, 0.5, "flota")
	assert_false(b.touches(e), "sin embestir no toca")
	b._rush_cd = 0.0
	var v := b.update(e, p, DT)
	assert_eq(v, Vector3.ZERO, "el aviso: se para")
	assert_true(b.is_telling())
	for k in int(float(e.data.param("rush_tell", 0.6)) / DT) + 2: v = b.update(e, p, DT)
	assert_true(b.is_rushing())
	assert_true(b.touches(e))
	assert_almost_eq(v.length(), e.data.move_speed * float(e.data.param("rush_mult", 2.6)), 0.05)
	assert_lt(v.x, 0.0, "hacia el jugador")
	b.contact_damage(e)
	assert_false(b.is_rushing(), "un golpe por embestida")

# ------------------------------------------------------------------ el pólipo antiguo

func test_el_polipo_antiguo_sube_por_la_gran_trampilla() -> void:
	var pw := _winds()
	var p := _player("dyer", Vector3(0, 0, 10))
	var boss := _enemy("polipo_antiguo", Vector3(20, 0, 20), false)
	var b := boss.behavior as PolypBossBehavior
	assert_not_null(b)
	assert_almost_eq(boss.position.x, pw.great.x, 0.01, "sube por la gran trampilla")
	assert_almost_eq(boss.position.z, pw.great.y, 0.01)
	assert_eq(pw.great_door.state, PolypWinds.State.OPEN, "que se abre y sopla")
	assert_true(boss.buried, "al subir, aún sin cuerpo")
	for k in int(float(boss.data.param("rise_time", 2.5)) / DT) + 2: b.update(boss, p, DT)
	assert_true(b.has_body())
	assert_false(boss.buried)
	assert_true(boss.visual.visible)
	assert_true(b.touches(boss))
	b._t = 0.0
	b._gale = 99.0; b._breath = 99.0
	b.update(boss, p, DT)
	assert_eq(b.form, PolypBossBehavior.Form.VOID, "a ratos se deshace en el viento")
	assert_true(boss.buried, "sin cuerpo: no se le apunta ni se le da")
	assert_false(boss.visual.visible)
	assert_false(b.touches(boss))
	var v := b.update(boss, p, DT)
	assert_gt(v.length(), boss.data.move_speed * 1.5, "y se mueve deprisa")
	boss.reveal(3.0, 0.25)
	b.update(boss, p, DT)
	assert_true(b.has_body(), "lo que revela lo obliga a tener cuerpo")

func test_vuelve_con_un_golpe() -> void:
	_winds()
	var p := _player("dyer", Vector3(0, 0, 10))
	var boss := _enemy("polipo_antiguo", Vector3.ZERO, false)
	var b := boss.behavior as PolypBossBehavior
	b.form = PolypBossBehavior.Form.VOID
	b._t = 0.0
	b.update(boss, p, DT)
	assert_eq(b.form, PolypBossBehavior.Form.RETURNING, "avisa en el suelo")
	for k in int(float(boss.data.param("return_tell", 1.0)) / DT) + 2: b.update(boss, p, DT)
	assert_true(b.has_body())

func test_el_polipo_antiguo_por_fases_y_al_morir() -> void:
	var pw := _winds()
	var p := _player("dyer", Vector3(0, 0, 10))
	var boss := _enemy("polipo_antiguo", Vector3.ZERO, false)
	var b := boss.behavior as PolypBossBehavior
	assert_eq(b.phase_for(boss), 1)
	boss.health = boss.data.max_health * boss.health_scale * 0.45
	b.update(boss, p, DT)
	assert_eq(b.phase, 2)
	assert_eq(pw.open_count(), pw.doors.size(), "en la segunda fase silban todas las trampillas")
	for k in [2, 3]: assert_ne(String(boss.data.param("phase_text_%d" % k, "")), "", "grito de la fase %d" % k)
	b._on_death(boss)
	assert_eq(pw.great_door.state, PolypWinds.State.CLOSED, "al morir se cierra la gran trampilla")
	assert_true(boss.visual.visible)

# ------------------------------------------------------------------ el resto

func test_los_consejos_y_el_suelo_de_arena() -> void:
	var tips: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial.json"))
	var by := {}
	for t in tips.tips: by[String(t.id)] = t
	for id in ["trampilla", "polipos"]:
		assert_true(by.has(id), id)
		assert_true(bool(by[id].get("urgent", false)), "%s, urgente" % id)
	var amb: Dictionary = Ambient.config().get("arenas", {}).get("pnakotus", {})
	assert_eq(String(amb.get("step", "")), "sand")
	assert_true(Footprints.KINDS.has("sand"), "huellas en la arena")
	assert_true(FileAccess.file_exists("res://resources/sfx/step_sand_0.wav"))
