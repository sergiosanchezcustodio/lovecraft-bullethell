extends GutTest
## Hito 22.6: la noche suelta «La música de Erich Zann». La viola de la buhardilla (ZannViola), que en
## cada compás aparta a los enemigos y hiere a lo de fuera; su frenesí, que quita cordura; lo que hay
## tras la ventana (VoidBehavior), que la hace callar y tira de todos; y el desafío «Allegro furioso».

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	Challenge.begin("")

func after_each() -> void:
	Challenge.begin("")

func _player(at := Vector3.ZERO) -> Player:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	p.position = at
	world.add_child(p)
	world.add_player(p)
	return p

func _enemy(id: String, at: Vector3) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/%s.tres" % id) as EnemyData).duplicate()
	d.max_health = 1000.0
	d.move_speed = 0.0
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _level(period := 1.5) -> LevelData:
	var lv: LevelData = (load("res://data/levels/noche_zann.tres") as LevelData).duplicate()
	lv.viola_period = period
	return lv

func _viola(lv: LevelData = null, host := true) -> ZannViola:
	var zv := ZannViola.new().setup(world, lv if lv != null else _level(), host)
	zv.place(Vector2.ZERO, 10.0)                       # la ventana en el origen, para medir
	add_child_autofree(zv)
	return zv

func _step(zv: ZannViola, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		for q in world.players: q.push = Vector3.ZERO
		zv._physics_process(DT)

# ------------------------------------------------------------------ la noche

func test_la_noche_y_su_nivel() -> void:
	var n := Nights.find("noche_zann")
	assert_false(n.is_empty())
	assert_eq(String(n.abre), "p4_n5")
	var lv: LevelData = load("res://data/levels/noche_zann.tres")
	assert_eq(String(lv.final_enemy.id), "tras_ventana")
	assert_gt(lv.viola_period, lv.viola_period_end, "la viola se acelera")
	assert_lt(lv.viola_period_end, lv.viola_frenzy, "y acaba en frenesí")
	assert_lt(lv.viola_period_boss, lv.viola_period_end, "con el jefe, más deprisa aún")
	assert_true(lv.pool.any(func(d: EnemyData) -> bool: return d.tags.has(&"humana")), "los vecinos, de este mundo")
	assert_true(lv.pool.any(func(d: EnemyData) -> bool: return bool(d.param("outer", false))), "los jirones, de fuera")
	assert_true(bool(lv.final_enemy.param("outer", false)), "el jefe también")
	assert_not_null(lv.weather)

func test_la_ventana_sale_de_la_arena() -> void:
	var zv := ZannViola.new().setup(world, _level(), true)
	add_child_autofree(zv)
	assert_ne(zv.window, Vector3.INF, "la buhardilla de Zann")
	assert_gt(zv.window.y, 6.0, "en lo alto")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/auseil.json"))
	assert_true(layout.walkable.has("aus_escalones"), "los escalones se pisan")

func test_sin_viola_no_suena() -> void:
	var zv := _viola(_level(0.0))
	_step(zv, 3.0)
	assert_eq(zv.beats, 0)

# ------------------------------------------------------------------ el compás

func test_cada_compas_aparta_y_solo_hiere_a_lo_de_fuera() -> void:
	var zv := _viola()
	var vecino := _enemy("vecino_auseil", Vector3(6, 0, 0))
	var jiron := _enemy("jiron_noche", Vector3(0, 0, 6))
	zv.beat()
	_step(zv, 0.6)                                     # la onda pasa por los 6 m
	assert_eq(zv.pushed, 2, "aparta a los dos")
	assert_gt(vecino._knock.x, 0.5, "hacia fuera de la ventana")
	assert_gt(jiron._knock.z, 0.5)
	assert_eq(zv.hurt, 1, "y solo hiere al jirón")
	assert_lt(jiron.health, 1000.0)
	assert_eq(vecino.health, 1000.0)

func test_lejos_de_la_ventana_empuja_menos() -> void:
	var zv := _viola()
	var cerca := _enemy("vecino_auseil", Vector3(3, 0, 0))
	var lejos := _enemy("vecino_auseil", Vector3(30, 0, 0))
	zv.beat()
	_step(zv, 2.2)
	assert_gt(cerca._knock.x, lejos._knock.x * 1.5)
	assert_gt(lejos._knock.x, 0.0, "pero aún empuja")

func test_el_invitado_no_mueve_a_los_enemigos() -> void:
	var zv := _viola(null, false)
	var e := _enemy("vecino_auseil", Vector3(4, 0, 0))
	zv.beat()
	_step(zv, 0.5)
	assert_eq(zv.pushed, 0)
	assert_eq(e._knock, Vector3.ZERO)

func test_suena_a_su_compas() -> void:
	var zv := _viola(_level(1.0))
	_step(zv, 4.3)                                     # el primero a 1,2 s; después, cada 1 s
	assert_between(zv.beats, 3, 4)

# ------------------------------------------------------------------ el frenesí

func test_el_frenesi_quita_cordura_y_el_compas_corriente_no() -> void:
	var p := _player(Vector3(5, 0, 0))
	var zv := _viola()
	var s0 := p.sanity
	zv.beat()
	_step(zv, 0.5)
	assert_eq(p.sanity, s0, "a 1,5 s por compás no es frenesí")
	var zf := _viola(_level(0.6))
	assert_true(zf.frenzy())
	zf.beat()
	_step(zf, 0.5)
	assert_lt(p.sanity, s0, "el frenesí sí")
	assert_true(zf.frenzy_seen, "para el consejo")
	assert_gt(zf.drained, 0)

# ------------------------------------------------------------------ el jefe

func test_calla_y_no_suena() -> void:
	var zv := _viola(_level(0.5))
	zv.hush(2.0)
	_step(zv, 1.8)
	assert_eq(zv.beats, 0, "mientras calla, nada")
	_step(zv, 1.0)
	assert_gt(zv.beats, 0, "y vuelve")

func test_el_viento_de_la_ventana_tira_hacia_el() -> void:
	var p := _player(Vector3(8, 0, 0))
	var zv := _viola()
	zv.pull(Vector3.ZERO, 0.5, 2.0)
	world.rebuild_grid()
	p.push = Vector3.ZERO
	zv._physics_process(DT)
	assert_lt(p.push.x, -0.5, "hacia la ventana")
	_step(zv, 0.6)
	p.push = Vector3.ZERO
	zv._physics_process(DT)
	assert_eq(p.push, Vector3.ZERO, "y se acaba")

func test_el_jefe_y_sus_fases() -> void:
	var d: EnemyData = load("res://data/enemies/tras_ventana.tres")
	assert_true(d.unique)
	assert_eq(String(d.movement), "void")
	assert_true(bool(d.param("face_camera", false)), "siempre de cara a la cámara")
	assert_not_null(d.param("spawn", null), "llama a los jirones")
	assert_true(ResourceLoader.exists(String(d.param("ring", ""))), "y su anillo existe")
	var e := _enemy("tras_ventana", Vector3(0, 0, 4))
	var b := VoidBehavior.new()
	e.health = e.data.max_health * e.health_scale * 0.7
	assert_eq(b.phase_for(e), 1)
	e.health = e.data.max_health * e.health_scale * 0.5
	assert_eq(b.phase_for(e), 2)
	e.health = e.data.max_health * e.health_scale * 0.2
	assert_eq(b.phase_for(e), 3)

# ------------------------------------------------------------------ el desafío y los textos

func test_el_desafio_se_abre_con_la_noche_y_acelera_la_viola() -> void:
	var s := SaveData.new()
	assert_false(Challenge.unlocked(s, "noche_zann"))
	Nights.record_win(s, "noche_zann")
	assert_true(Challenge.unlocked(s, "noche_zann"), "al superar la noche")
	var c := Challenge.find("noche_zann")
	assert_false(c.is_empty())
	var zv := _viola()
	var p0 := zv.period()
	Challenge.begin(Challenge.id_for("noche_zann"))
	assert_almost_eq(zv.period(), p0 * 0.7, 0.001, "Allegro furioso")
	var lv := Challenge.make_level(Challenge.id_for("noche_zann"))
	assert_gt(lv.viola_period, 0.0, "el desafío lleva su viola")

func test_el_articulo_del_jefe() -> void:
	assert_eq(Hud.with_article("Lo que hay tras la ventana"), "lo que hay tras la ventana")
	assert_eq(Hud.with_a("Lo que hay tras la ventana"), "a lo que hay tras la ventana")
	assert_eq(Hud._the("What lies beyond the window"), "what lies beyond the window", "y en inglés")
