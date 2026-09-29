extends GutTest
## Arsenal II (hito 2.7): las ocho armas mágicas. Signo que frena balas, Resonador que las
## deshace, fuegos fatuos teledirigidos, rayo cuyo daño crece, polvo que ralentiza y debilita,
## orbes Mi-Go que disparan solos, estasis con daño aplazado y maldición que se contagia.

const DT := 1.0 / 60.0
var world: CombatWorld
var root: Node3D
var obstacles: ObstacleMap

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)

func _enemy(pos: Vector3, hp: float = 1000.0) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	d.max_health = hp
	var e := Enemy.new().setup(d, world, obstacles)
	e.position = pos
	root.add_child(e)
	return e

func _player(id: String = "varga") -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _weapon(p: Player, id: String) -> WeaponSystem.Weapon:
	return p.weapons.add_weapon(load("res://data/weapons/%s.tres" % id))

func _enemy_bullet(pos: Vector3, vel: Vector3) -> void:
	world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, pos, vel, 0.2, 0.2,
		Damage.new(5, 0), 10.0)

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT): node._physics_process(DT)

func test_las_ocho_armas_magicas_existen_y_cuestan_cordura() -> void:
	for id in ["signo", "resonador", "farolero", "lente", "polvo", "migo", "yith", "daga"]:
		var wd: WeaponData = load("res://data/weapons/%s.tres" % id)
		assert_not_null(wd, id)
		assert_eq(wd.category, WeaponData.Category.MAGIC, id)
		assert_gt(wd.sanity_cost, 0.0, id)
		assert_eq(wd.level_mods.size(), wd.max_level - 1, id)
		assert_eq(wd.level_text.size(), wd.max_level - 1, id)

func test_el_signo_frena_las_balas_enemigas_una_sola_vez() -> void:
	_enemy_bullet(Vector3(0.5, 0, 0), Vector3(10, 0, 0))
	_enemy_bullet(Vector3(9, 0, 0), Vector3(10, 0, 0))
	var s := Sigil.new().setup(world, Vector3.ZERO, 2.0, 3.0, 0.0, 0.4, 0.0, 0.5, {})
	world.fx.add_child(s)
	s._physics_process(DT)
	s._physics_process(DT)
	assert_eq(s.slowed, 1, "solo la de dentro, y una vez")
	assert_almost_eq(world.bullets._vel[0].length(), 5.0, 0.01)
	assert_almost_eq(world.bullets._vel[1].length(), 10.0, 0.01)

func test_el_signo_dana_y_empuja_hacia_fuera() -> void:
	var e := _enemy(Vector3(1, 0, 0))
	world.rebuild_grid()
	var s := Sigil.new().setup(world, Vector3.ZERO, 2.0, 3.0, 5.0, 0.4, 2.0, 0.5, {})
	world.fx.add_child(s)
	s._physics_process(DT)
	assert_eq(e.health, 995.0)
	assert_gt(e._knock.x, 0.0, "hacia fuera")

func test_el_resonador_deshace_las_balas_que_alcanza() -> void:
	var p := _player()
	_enemy_bullet(Vector3(1, 0, 0), Vector3.ZERO)
	_enemy_bullet(Vector3(0, 0, 2), Vector3.ZERO)
	_enemy_bullet(Vector3(12, 0, 0), Vector3.ZERO)
	var w := _weapon(p, "resonador")
	assert_true(p.weapons._pulse(w), "hay balas cerca: vibra")
	var wave: Shockwave = world.fx.get_child(world.fx.get_child_count() - 1)
	_run(wave, 0.5)
	assert_eq(wave.cleared, 2)
	assert_eq(world.bullets.count, 1, "la lejana sigue")

func test_el_resonador_no_vibra_sin_nada_cerca() -> void:
	var p := _player()
	var w := _weapon(p, "resonador")
	assert_false(p.weapons._pulse(w))

func test_los_fuegos_fatuos_giran_hacia_el_enemigo() -> void:
	var e := _enemy(Vector3(0, 0, 4))
	world.rebuild_grid()
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.WISP, Vector3.ZERO, Vector3(8, 0, 0),
		0.2, 0.2, Damage.new(1, 0), 3.0, 0, 1.0, -1, 0, 6.0)
	for i in 20: world.bullets._physics_process(DT)
	assert_gt(world.bullets._vel[0].z, 2.0, "se tuerce hacia el enemigo, que está en +Z")
	assert_true(is_instance_valid(e))

func test_la_lente_aumenta_el_dano_sobre_el_mismo_enemigo() -> void:
	var p := _player()
	var e := _enemy(Vector3(3, 0, 0))
	world.rebuild_grid()
	var b := TetherBeam.new().setup(p, world, 10.0, 0.25, 0.5, 3.0, 8.0, 5.0, {})
	world.fx.add_child(b)
	var hits: Array[float] = []
	var last := e.health
	for i in int(1.3 / DT):
		b._physics_process(DT)
		if e.health < last:
			hits.append(last - e.health)
			last = e.health
	assert_gte(hits.size(), 4)
	assert_eq(hits[0], 10.0)
	assert_gt(hits[3], hits[0] * 2.0, "va creciendo")
	assert_lte(hits[hits.size() - 1], 30.0, "tope: el triple")

func test_el_polvo_ralentiza_y_debilita() -> void:
	var e := _enemy(Vector3.ZERO)
	world.rebuild_grid()
	var z := DamageZone.new().setup(world, WeaponData.Zone.DUST, Vector3.ZERO, 2.0, 3.0, 0.0)
	z.slow_k = 0.6
	z.weak_k = 0.7
	world.fx.add_child(z)
	z._physics_process(DT)
	assert_almost_eq(e.speed_mult(), 0.6, 0.001)
	e._physics_process(DT)
	assert_almost_eq(e.runner.damage_mult, 0.7, 0.001, "sus balas hacen menos daño")

func test_el_polvo_frena_menos_a_las_elites() -> void:
	var e := _enemy(Vector3.ZERO)
	e.data.elite = true
	e.slow(1.0, 0.6)
	assert_almost_eq(e.speed_mult(), 0.8, 0.001)

func test_los_orbes_mi_go_disparan_solos() -> void:
	var p := _player()
	_enemy(Vector3(4, 0, 0))
	world.rebuild_grid()
	var w := _weapon(p, "migo")
	assert_true(p.weapons._drone(w))
	var d: MiGoDrones = p.weapons._drones[w]
	_run(d, 2.0)
	assert_gte(d.shots, 2)
	assert_gt(world.bullets.count, 0)
	assert_false(p.weapons._drone(w), "mientras vuelan no se vuelven a lanzar")

func test_la_estasis_guarda_el_dano_y_lo_aplica_aumentado() -> void:
	var e := _enemy(Vector3.ZERO)
	e.stasis(1.0)
	e.take_damage(Damage.new(20.0, 0.0))
	assert_eq(e.health, 1000.0, "congelado: aún no le hace nada")
	assert_true(e.in_stasis())
	_run(e, 1.1)
	assert_false(e.in_stasis())
	assert_almost_eq(e.health, 1000.0 - 30.0, 0.01, "20 × 1,5")

func test_la_bala_de_yith_congela_al_impactar() -> void:
	var e := _enemy(Vector3(1, 0, 0))
	world.rebuild_grid()
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.YITH, Vector3.ZERO, Vector3(20, 0, 0),
		0.3, 0.2, Damage.new(10, 0), 1.0, 0, 1.0, -1, 0, 0.0, BulletManager.Effect.STASIS, 1.5)
	for i in 10: world.bullets._physics_process(DT)
	assert_true(e.in_stasis())

func test_el_congelado_no_se_mueve() -> void:
	var p := _player()
	p.position = Vector3(5, 0, 0)
	var e := _enemy(Vector3.ZERO)
	e.stasis(1.0)
	var before := e.position
	_run(e, 0.5)
	assert_eq(e.position, before)

func test_la_maldicion_dana_con_el_tiempo() -> void:
	var e := _enemy(Vector3.ZERO)
	e.curse(2.0, 10.0, 0)
	_run(e, 1.05)
	assert_almost_eq(e.health, 1000.0 - 10.0, 5.1, "unos 10 por segundo")

func test_la_maldicion_salta_al_morir() -> void:
	var dying := _enemy(Vector3.ZERO, 5.0)
	var near1 := _enemy(Vector3(1, 0, 0))
	var near2 := _enemy(Vector3(0, 0, 1.5))
	var near3 := _enemy(Vector3(-2, 0, 0))
	var far := _enemy(Vector3(10, 0, 0))
	world.rebuild_grid()
	dying.curse(3.0, 5.0, 2)
	dying.take_damage(Damage.new(10.0, 0.0))
	assert_true(near1.is_cursed())
	assert_true(near2.is_cursed())
	assert_false(near3.is_cursed(), "salta a los dos más cercanos")
	assert_false(far.is_cursed())

func test_la_daga_espera_a_tener_a_alguien_cerca() -> void:
	var p := _player()
	var w := _weapon(p, "daga")
	var e := _enemy(Vector3(6, 0, 0))
	world.rebuild_grid()
	assert_false(p.weapons._stab(w))
	e.position = Vector3(1.5, 0, 0)
	world.rebuild_grid()
	assert_true(p.weapons._stab(w))
	assert_true(e.is_cursed())
	assert_lt(e.health, 1000.0)

func test_las_armas_magicas_cuestan_cordura_al_usarse() -> void:
	var p := _player("dyer")                  # sin el rasgo de Varga (mitad de coste)
	_enemy(Vector3(2, 0, 0))
	world.rebuild_grid()
	for id in ["signo", "farolero", "yith", "polvo"]:
		var w := _weapon(p, id)
		var s := p.sanity
		p.weapons._fire(w)
		assert_lt(p.sanity, s, id)
