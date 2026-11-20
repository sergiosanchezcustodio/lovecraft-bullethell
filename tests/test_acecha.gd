extends GutTest
## Hito 23.8: la noche suelta «El que acecha en la oscuridad». Las farolas de Federal Hill (Blackout) y los
## apagones de la tormenta; las sombras del campanario (DarkBehavior), que no entran en la luz y se queman
## en ella; los sectarios que apagan farolas (DouseBehavior); el Morador de las Tinieblas
## (HaunterBehavior); y el desafío «Corriente cortada».

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	Challenge.begin("")

func after_each() -> void:
	Challenge.begin("")

func _player(at := Vector3.ZERO, who := "dyer") -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % who), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	p.position = at
	world.add_child(p)
	world.add_player(p)
	return p

func _enemy(id: String, at: Vector3, speed := 0.0) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/%s.tres" % id) as EnemyData).duplicate()
	d.max_health = 1000.0
	if speed >= 0.0: d.move_speed = speed
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _level() -> LevelData:
	return (load("res://data/levels/noche_acecha.tres") as LevelData).duplicate()

func _blackout(lv: LevelData = null, host := true) -> Blackout:
	var b := Blackout.new().setup(world, lv if lv != null else _level(), host)
	add_child_autofree(b)
	return b

func _step_b(b: Blackout, secs: float) -> void:
	for i in int(secs / DT): b._physics_process(DT)

# ------------------------------------------------------------------ la noche

func test_la_noche_y_su_nivel() -> void:
	var n := Nights.find("noche_acecha")
	assert_false(n.is_empty())
	assert_eq(String(n.abre), "p4_n5")
	var lv: LevelData = load("res://data/levels/noche_acecha.tres")
	assert_eq(String(lv.final_enemy.id), "morador_tinieblas")
	assert_gt(lv.blackout_on, lv.blackout_on_end, "los apagones, cada vez más a menudo")
	assert_lt(lv.blackout_off, lv.blackout_off_end, "y más largos")
	assert_true(lv.pool.any(func(d: EnemyData) -> bool: return d.movement == &"douse"), "los sectarios")
	assert_true(lv.pool.any(func(d: EnemyData) -> bool: return bool(d.param("dark", false))), "las sombras")
	assert_not_null(lv.weather)
	assert_gt(lv.weather.lightning_every, 0.0, "la tormenta trae rayos")

func test_el_campanario_sale_de_la_arena() -> void:
	var b := _blackout()
	assert_ne(b.steeple, Vector3.INF, "el Trapezoedro")
	assert_gt(b.steeple.y, 12.0, "en lo alto del campanario")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/federal.json"))
	var lamps := (layout.props as Array).filter(func(p: Dictionary) -> bool: return p.model == "fed_farola")
	assert_gt(lamps.size(), 10, "farolas por las calles")
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://models/fed_farola.json"))
	assert_true((m.pivots as Dictionary).has("light") and (m.pivots as Dictionary).has("globe"), "con su luz y su globo")

# ------------------------------------------------------------------ las farolas

func test_una_farola_alumbra_y_el_apagon_la_quita() -> void:
	var b := _blackout()
	b.add_lamp(Vector2(10, 0))
	assert_ne(b.light_at(Vector3(11, 0, 0), 0.5), Vector3.INF, "junto a la farola, luz")
	assert_eq(b.light_at(Vector3(20, 0, 0), 0.5), Vector3.INF, "lejos, oscuridad")
	b.cut(3.0)
	assert_false(b.power)
	assert_eq(b.light_at(Vector3(11, 0, 0), 0.5), Vector3.INF, "sin corriente, a oscuras")
	_step_b(b, 3.2)
	assert_true(b.power, "vuelve la luz")
	assert_ne(b.light_at(Vector3(11, 0, 0), 0.5), Vector3.INF)

func test_la_tormenta_corta_la_luz_sola() -> void:
	var lv := _level()
	lv.blackout_on = 2.0
	lv.blackout_off = 1.0
	var b := _blackout(lv)
	_step_b(b, 2.2)
	assert_eq(b.cuts, 1, "a los 2 s, el primer apagón")
	assert_false(b.power)
	_step_b(b, 1.2)
	assert_true(b.power)

func test_el_invitado_no_corta_la_luz_por_su_cuenta() -> void:
	var lv := _level()
	lv.blackout_on = 1.0
	var b := _blackout(lv, false)
	_step_b(b, 2.0)
	assert_eq(b.cuts, 0)
	b.remote({"a": "cut", "t": 2.0})
	assert_false(b.power, "lo que diga el anfitrión")
	b.remote({"a": "on"})
	assert_true(b.power)

func test_una_farola_apagada_y_su_vuelta() -> void:
	var b := _blackout()
	b.add_lamp(Vector2(0, 0))
	b.add_lamp(Vector2(30, 0))
	assert_eq(b.nearest_lit(Vector3(1, 0, 0), 5.0), 0)
	b.douse(0, 2.0)
	assert_false(b.lit_lamp(0))
	assert_eq(b.nearest_lit(Vector3(1, 0, 0), 5.0), -1, "la apagada no cuenta")
	_step_b(b, 2.2)
	assert_true(b.lit_lamp(0), "vuelve sola")

func test_el_farol_del_jugador_tambien_alumbra() -> void:
	var b := _blackout()
	_player(Vector3(0, 0, 0))
	assert_ne(b.light_at(Vector3(1.0, 0, 0), 0.5), Vector3.INF, "al lado, su farol")
	assert_eq(b.light_at(Vector3(5.0, 0, 0), 0.5), Vector3.INF)

func test_a_oscuras_se_pierde_cordura_y_el_farol_alumbra_menos() -> void:
	var b := _blackout()
	var p := _player()
	var r0 := (p.get_node("CarryLight") as OmniLight3D).omni_range
	var s0 := p.sanity
	b.cut(3.0)
	for i in 120:
		b._physics_process(DT)
		b._process(DT)
	assert_lt(p.sanity, s0, "la oscuridad pesa")
	assert_lt((p.get_node("CarryLight") as OmniLight3D).omni_range, r0 * 0.8, "el farol, más corto")

func test_el_farol_de_blake_alumbra_mas() -> void:
	var b := _blackout()
	var p := _player(Vector3.ZERO, "blake")
	var r0 := (p.get_node("CarryLight") as OmniLight3D).omni_range
	b._process(DT)
	assert_almost_eq((p.get_node("CarryLight") as OmniLight3D).omni_range, r0 * Blackout.BLAKE, 0.01, "conoce la iglesia por su hermano")

# ------------------------------------------------------------------ lo de la oscuridad

func test_la_sombra_no_entra_en_la_luz_y_se_quema() -> void:
	var b := _blackout()
	b.add_lamp(Vector2(0, 0))
	var p := _player(Vector3(0, 0, 0))
	var e := _enemy("sombra_alada", Vector3(1.0, 0, 0), 2.6)    # dentro de la luz
	var beh := e.behavior as DarkBehavior
	for i in 60: beh.update(e, p, DT)
	assert_gt(beh.burned, 0.0, "la luz la quema")
	assert_eq(beh.state, DarkBehavior.State.FLEE, "y huye")

func test_la_sombra_a_oscuras_no_se_quema() -> void:
	var b := _blackout()
	var p := _player(Vector3(0, 0, 0))
	var e := _enemy("sombra_alada", Vector3(8.0, 0, 0), 2.6)
	var beh := e.behavior as DarkBehavior
	for i in 60: beh.update(e, p, DT)
	assert_eq(beh.burned, 0.0)
	assert_false(beh.touches(e), "con luz, solo golpea en picado")
	b.cut(5.0)
	assert_true(beh.touches(e), "a oscuras, siempre")

func test_el_rayo_lo_alumbra_todo() -> void:
	var b := _blackout()
	b.flash_lit = true
	assert_ne(DarkBehavior.light_for(world, Vector3(40, 0, 40), 0.5), Vector3.INF)

func test_el_sectario_apaga_la_farola() -> void:
	var b := _blackout()
	b.add_lamp(Vector2(0, 0))
	var p := _player(Vector3(20, 0, 0))
	var e := _enemy("sectario_estrellado", Vector3(0.8, 0, 0))
	var beh := e.behavior as DouseBehavior
	beh._cd = 0.0
	for i in 150:
		beh.update(e, p, DT)
		b._physics_process(DT)
	assert_eq(beh.doused, 1, "en 1,4 s la apaga")
	assert_false(b.lit_lamp(0))

func test_el_sectario_va_a_por_una_farola_cerca() -> void:
	var b := _blackout()
	b.add_lamp(Vector2(4, 0))
	var p := _player(Vector3(-20, 0, 0))
	var e := _enemy("sectario_estrellado", Vector3(0, 0, 0), 1.9)
	var beh := e.behavior as DouseBehavior
	beh._cd = 0.0
	var v := beh.update(e, p, DT)
	assert_gt(v.x, 0.0, "hacia la farola, no hacia el jugador")

# ------------------------------------------------------------------ el Morador

func test_el_morador_baja_del_campanario_y_la_luz_lo_quema() -> void:
	var b := _blackout()
	var p := _player(Vector3(0, 0, 0))
	var e := _enemy("morador_tinieblas", Vector3.ZERO, 2.0)
	var beh := e.behavior as HaunterBehavior
	assert_almost_eq(e.position.x, b.steeple.x, 0.01, "sale del campanario")
	assert_false(beh.has_body(), "aún sin cuerpo")
	for i in 170: beh.update(e, p, DT)
	assert_true(beh.has_body())
	b.add_lamp(Vector2(e.position.x, e.position.z))          # una farola justo debajo
	var h0 := e.health
	for i in 60: beh.update(e, p, DT)
	assert_gt(beh.burned, 0.0)
	assert_lt(e.health, h0)
	assert_false(beh.touches(e), "con luz y sin picado, no toca")

func test_a_oscuras_el_morador_se_lanza() -> void:
	var b := _blackout()
	var p := _player(Vector3(0, 0, 0))
	var e := _enemy("morador_tinieblas", Vector3.ZERO, 2.0)
	var beh := e.behavior as HaunterBehavior
	beh.form = HaunterBehavior.Form.OUT
	e.position = Vector3(12, 1.6, 0)                         # fuera de la luz del farol
	b.cut(30.0)
	beh._swoop = 0.0
	beh.update(e, p, DT)
	await get_tree().create_timer(1.2).timeout
	assert_eq(beh.swoops, 1, "en picado tras el aviso")
	assert_true(beh.touches(e))

func test_el_rayo_deslumbra_al_morador() -> void:
	var b := _blackout()
	var p := _player(Vector3(0, 0, 0))
	var e := _enemy("morador_tinieblas", Vector3.ZERO, 2.0)
	var beh := e.behavior as HaunterBehavior
	beh.form = HaunterBehavior.Form.OUT
	b.flash_lit = true
	beh.update(e, p, DT)
	assert_gt(beh._dazed, 0.0)
	assert_eq(beh.update(e, p, DT), Vector3.ZERO, "quieto mientras no ve")

func test_las_fases_del_morador() -> void:
	var b := _blackout()
	b.add_lamp(Vector2(8, 0))                                # fuera de su luz, pero cerca
	var p := _player(Vector3(30, 0, 0))
	var e := _enemy("morador_tinieblas", Vector3.ZERO, 0.0)
	var beh := e.behavior as HaunterBehavior
	beh.form = HaunterBehavior.Form.OUT
	e.position = Vector3(0, 1.6, 0)
	e.health = e.data.max_health * e.health_scale * 0.5
	beh._break = 0.0
	beh.update(e, p, DT)
	assert_eq(beh.phase, 2)
	assert_false(b.lit_lamp(0), "revienta la farola más cerca")
	e.health = e.data.max_health * e.health_scale * 0.2
	beh._cut = 0.0
	beh.update(e, p, DT)
	assert_eq(beh.phase, 3)
	assert_false(b.power, "y corta la corriente")

# ------------------------------------------------------------------ el desafío

func test_el_desafio_corta_la_luz_mas_a_menudo() -> void:
	var b := _blackout()
	var t0 := b.on_time()
	Challenge.begin(Challenge.id_for("noche_acecha"))
	assert_almost_eq(b.on_time(), t0 * 0.5, 0.01)
	var save := SaveData.new()
	assert_false(Challenge.unlocked(save, "noche_acecha"))
	Nights.record_win(save, "noche_acecha")
	assert_true(Challenge.unlocked(save, "noche_acecha"), "se abre al superar la noche")

func test_el_logro_de_las_sombras_quemadas() -> void:
	var s := SaveData.new()
	var a: AchievementData = null
	for x in Achievements.all():
		if String(x.id) == "sombras_quemadas": a = x
	assert_not_null(a)
	for i in 40: Achievements.add(s, "shadows_burned")
	assert_true(Achievements.check(s).has(a))
