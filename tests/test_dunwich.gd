extends GutTest
## Hito 21.14: la noche suelta «El horror de Dunwich». Lo que no se ve (Unseen: huellas, el polvo de
## Ibn Ghazi, los chotacabras que se llevan a los caídos), los chotacabras (FlockBehavior) y el hermano
## de Wilbur (HorrorBehavior).

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
		d.movement = &"chase"
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _unseen(host := true) -> Unseen:
	var lv: LevelData = load("res://data/levels/noche_dunwich.tres")
	var un := Unseen.new().setup(world, lv, host)
	un._next = 999.0                                  # sin pulverizadores sueltos: solo los de la prueba
	add_child_autofree(un)
	return un

func _step(un: Unseen, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		un._physics_process(DT)

func _down(p: Player) -> void:
	p.revivable = true
	p.health = 0.0
	p.down_left = 10.0

# ------------------------------------------------------------------ la noche

func test_la_noche_y_su_nivel() -> void:
	var n := Nights.find("noche_dunwich")
	assert_false(n.is_empty())
	var lv: LevelData = load("res://data/levels/noche_dunwich.tres")
	assert_eq(String(lv.final_enemy.id), "hermano_wilbur")
	assert_gt(lv.powder_every, 0.0, "con el polvo de Ibn Ghazi")
	assert_gt(lv.powder_final_every, 0.0)
	assert_lt(lv.powder_final_every, lv.powder_every, "más a menudo con el jefe suelto")
	assert_not_null(lv.weather)
	assert_gt(lv.weather.lightning_every, 0.0, "con tormenta: el rayo del final")
	assert_true(bool(lv.final_enemy.param("unseen", false)))
	assert_true(lv.pool.any(func(d: EnemyData) -> bool: return bool(d.param("soul_eater", false))), "con chotacabras")

# ------------------------------------------------------------------ el polvo de Ibn Ghazi

func test_el_polvo_descubre_lo_que_no_es_de_este_mundo() -> void:
	var un := _unseen()
	var p := _player("dyer", Vector3(0, 0, 0))
	var bird := _enemy("chotacabras", Vector3(4, 0, 0))
	var devota := _enemy("devota_colinas", Vector3(-3, 0, 0))
	var far := _enemy("chotacabras", Vector3(30, 0, 0))
	un.spawn_at(Vector2(0.3, 0))
	assert_eq(un.sprayers.size(), 1)
	_step(un, 0.1)
	assert_eq(un.sprayers.size(), 0, "quien pasa por encima lo suelta")
	assert_eq(un.sprays, 1)
	assert_true(bird.is_revealed())
	assert_false(devota.is_revealed(), "las devotas son de este mundo")
	assert_false(far.is_revealed(), "fuera de la nube, no")
	var h := bird.health
	bird.take_damage(Damage.new(10.0, 0.0))
	assert_almost_eq(h - bird.health, 10.0 * (1.0 + Unseen.VULN), 0.01, "un 25 % más de daño")
	assert_eq(p.health, p.data.max_health)

func test_armitage_lo_suelta_mas_lejos() -> void:
	var un := _unseen()
	_player("armitage", Vector3(0, 0, 0))
	var lv := un.level
	var e := _enemy("chotacabras", Vector3(lv.powder_radius + 2.0, 0, 0))
	un.spawn_at(Vector2.ZERO)
	_step(un, 0.1)
	assert_true(e.is_revealed(), "×1,5 de nube")

func test_los_pulverizadores_aparecen_cerca_y_se_acaban() -> void:
	var un := _unseen()
	var p := _player("dyer", Vector3(0, 0, 0))
	p.health = 0.0                                    # que no los recoja
	_player("legrasse", Vector3(2, 0, 2))
	world.players[1].health = 0.0
	world.bounds = Rect2(-30, -30, 60, 60)
	un._spawn_near_players()
	p.health = 1.0                                    # vivo para que haya a quién arrimarse, lejos
	p.position = Vector3(50, 0, 50)
	assert_eq(un.sprayers.size(), 0, "sin nadie vivo, nada")
	p.position = Vector3.ZERO
	un._spawn_near_players()
	assert_eq(un.sprayers.size(), 1)
	var d: float = un.sprayers[0].pos.length()
	assert_between(d, 3.9, 9.1, "a unos pasos de un jugador")
	p.position = Vector3(25, 0, 25)
	_step(un, un.level.powder_life + 0.2)
	assert_eq(un.sprayers.size(), 0, "se acaba si nadie lo recoge")

func test_en_el_invitado_los_pulverizadores_llegan_del_anfitrion() -> void:
	var un := _unseen(false)
	_player("dyer", Vector3(20, 0, 0))
	var e := _enemy("chotacabras", Vector3(2, 0, 0))
	un.spawn_at(Vector2.ZERO)
	assert_true(un.sprayers.is_empty(), "no los decide")
	un.remote({"a": "add", "id": 7, "x": 0.0, "z": 0.0})
	assert_eq(un.sprayers.size(), 1)
	un.remote({"a": "use", "id": 7, "r": 8.0, "p": 0})
	assert_true(un.sprayers.is_empty())
	assert_eq(un.sprays, 1, "la nube se ve")
	assert_false(e.is_revealed(), "lo que descubre lo lleva el anfitrión")
	un.remote({"a": "bolt", "x": 1.0, "z": 2.0})
	assert_eq(un.bolts, 1, "el rayo del final, también")

# ------------------------------------------------------------------ huellas

func test_lo_que_no_se_ve_deja_huellas_y_lo_que_se_ve_no() -> void:
	var un := _unseen()
	_player("dyer", Vector3(30, 0, 0))
	var boss := _enemy("hermano_wilbur", Vector3(0, 0, 0))
	HorrorBehavior.set_hidden(boss, true)
	un._process(DT)                                   # primera vista: apunta dónde está
	for i in 10:
		boss.position.x += 0.5
		un._process(DT)
	var n := un.prints.size()
	assert_between(n, 2, 4, "una cada zancada (%s m)" % boss.data.param("print_step", 1.5))
	var sides := un.prints.map(func(p: Dictionary) -> float: return signf(p.pos.y))
	assert_true(sides.has(1.0) and sides.has(-1.0), "a un lado y a otro")
	HorrorBehavior.set_hidden(boss, false)
	for i in 10:
		boss.position.x += 0.5
		un._process(DT)
	assert_eq(un.prints.size(), n, "a la vista, sin huellas")
	var bird := _enemy("chotacabras", Vector3(0, 0, 5))
	for i in 10:
		bird.position.x += 0.5
		un._process(DT)
	assert_eq(un.prints.size(), n, "solo lo que no se ve")

func test_las_huellas_tienen_tope_y_se_borran() -> void:
	var un := _unseen()
	for i in Unseen.MAX_PRINTS + 5: un.add_print(Vector2(i, 0), 0.6)
	assert_eq(un.prints.size(), Unseen.MAX_PRINTS)
	assert_eq(un.prints[0].pos, Vector2(5, 0), "la más vieja deja sitio")
	for p in un.prints: p.age = Unseen.PRINT_LIFE + 1.0
	un._process(DT)
	assert_true(un.prints.is_empty())

# ------------------------------------------------------------------ los chotacabras y los caídos

func test_los_chotacabras_apuran_a_los_caidos_y_se_llevan_su_alma() -> void:
	var un := _unseen()
	var p := _player("dyer", Vector3(0, 0, 0))
	var q := _player("legrasse", Vector3(15, 0, 0))
	_down(p)
	_step(un, 0.3)
	assert_eq(p.down_haste, 0.0, "sin pájaros, nada")
	_enemy("chotacabras", Vector3(1, 0, 0))
	_enemy("chotacabras", Vector3(0, 0, 1))
	_step(un, 0.3)
	assert_almost_eq(p.down_haste, 2 * Unseen.SOUL_HASTE, 0.01)
	assert_eq(q.down_haste, 0.0)
	var left := p.down_left
	p._downed_step(1.0)
	assert_almost_eq(left - p.down_left, 1.0 + 2 * Unseen.SOUL_HASTE, 0.01, "su tiempo corre más deprisa")
	for i in 4: _enemy("chotacabras", Vector3(-1, 0, 0))
	_step(un, 0.3)
	assert_almost_eq(p.down_haste, Unseen.SOUL_MAX, 0.01, "con tope")
	p.down_left = 0.01
	p._downed_step(0.1)
	assert_true(p.is_eliminated)
	_step(un, 0.3)
	assert_eq(un.souls_taken, 1, "se llevan su alma")
	assert_eq(p.down_haste, 0.0)

func test_los_chotacabras_van_a_por_el_caido_y_luego_el_mas_herido() -> void:
	var a := _player("dyer", Vector3(0, 0, 0))
	var b := _player("legrasse", Vector3(10, 0, 0))
	var c := _player("armitage", Vector3(20, 0, 0))
	var bird := _enemy("chotacabras", Vector3(5, 0, 0), false)
	var fb := bird.behavior as FlockBehavior
	assert_not_null(fb)
	assert_eq(fb.prey(bird, a), a, "sin heridos, el que le toca")
	c.health = c.data.max_health * 0.2
	assert_eq(fb.prey(bird, a), c, "huele la sangre")
	_down(b)
	assert_eq(fb.prey(bird, a), b, "y antes, al caído")
	assert_false(fb.touches(bird), "rondando no toca")
	fb._dive = 0.0
	bird.position = Vector3(10, 0, 3)
	b.health = 1.0                                    # se levanta: vuelve a rondar al más herido
	fb.update(bird, a, DT)
	assert_true(fb.is_diving() or fb._dive > 0.0)

func test_los_chotacabras_vuelan() -> void:
	var p := _player("dyer", Vector3(0, 0, 0))
	var bird := _enemy("chotacabras", Vector3(6, 0, 0), false)
	var fb := bird.behavior as FlockBehavior
	for i in 30: fb.update(bird, p, DT)
	assert_gt(bird.position.y, 0.8, "a %s m del suelo" % bird.data.param("fly", 1.5))

# ------------------------------------------------------------------ el hermano de Wilbur

func test_el_hermano_de_wilbur_sale_de_la_granja_sin_verse() -> void:
	var p := _player("dyer", Vector3(0, 0, 0))
	var boss := _enemy("hermano_wilbur", Vector3(5, 0, 5), false)
	var from: Vector2 = boss.data.param("from", Vector2.ZERO)
	assert_almost_eq(boss.position.x, from.x, 0.01, "sale de la granja de los Whateley")
	assert_almost_eq(boss.position.z, from.y, 0.01)
	assert_true(boss.buried, "no se le puede apuntar ni dar")
	assert_false(boss.visual.visible)
	var b := boss.behavior as HorrorBehavior
	assert_not_null(b)
	assert_true(b.touches(boss), "aunque no se vea, pisa")
	assert_false(b.can_shoot(boss))
	var v := b.update(boss, p, DT)
	assert_gt(v.length(), 0.0, "va a por el jugador")
	boss.reveal(3.0, 0.25)
	var v2 := b.update(boss, p, DT)
	assert_true(b.is_shown())
	assert_false(boss.buried, "descubierto: se le puede dar")
	assert_true(boss.visual.visible)
	assert_almost_eq(v2.length(), v.length() * float(boss.data.param("reveal_slow", 0.6)), 0.05, "y va más despacio")
	boss._reveal_t = 0.0
	b.update(boss, p, DT)
	assert_true(boss.buried, "se le acaba y vuelve a no verse")

func test_el_hermano_de_wilbur_por_fases() -> void:
	var boss := _enemy("hermano_wilbur", Vector3.ZERO, false)
	var b := boss.behavior as HorrorBehavior
	assert_eq(b.phase_for(boss), 1)
	boss.health = boss.data.max_health * boss.health_scale * 0.45
	assert_eq(b.phase_for(boss), 2)
	boss.health = boss.data.max_health * boss.health_scale * 0.15
	assert_eq(b.phase_for(boss), 3)
	for k in [2, 3]: assert_ne(String(boss.data.param("phase_text_%d" % k, "")), "", "grito de la fase %d" % k)
	assert_not_null(boss.data.param("minion", null), "llama a los chotacabras")

func test_al_morir_cae_el_rayo() -> void:
	var un := _unseen()
	var boss := _enemy("hermano_wilbur", Vector3.ZERO, false)
	(boss.behavior as HorrorBehavior)._thunder(boss)
	assert_eq(un.bolts, 1)
	assert_true(boss.visual.visible, "se le ve al final")

func test_el_rayo_a_demanda_del_clima() -> void:
	var w := Weather.new()
	w.data = load("res://data/weather/tormenta_dunwich.tres")
	add_child_autofree(w)
	var n := w.lightning_count
	w.strike_now()
	assert_eq(w.lightning_count, n + 1)
	w.data = WeatherData.new()                        # sin rayos en este clima: nada
	w.strike_now()
	assert_eq(w.lightning_count, n + 1)
