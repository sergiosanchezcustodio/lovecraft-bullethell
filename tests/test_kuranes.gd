extends GutTest
## Hito 20.22: Kuranes (zonas de sueño donde los enemigos van cada vez más despacio, sus balas se
## frenan y los investigadores descansan; esquive que deja un sueño donde estaba).

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

func _player(pos := Vector3.ZERO, id := "kuranes") -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.world = world
	p.position = pos
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _zones() -> Array:
	return world.fx.get_children().filter(func(n: Node) -> bool: return n is DreamZone)

func _zone(pos: Vector3, life := 4.0, rest := 0.0) -> DreamZone:
	var z := DreamZone.new().setup(world, pos, 2.6, life, 3.0, 0.5, 0.45, 0.6, rest, {})
	world.fx.add_child(z)
	return z

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT):
		world.clock += DT
		world.rebuild_grid()
		node._physics_process(DT)

func test_en_la_tienda_con_su_arma_y_dos_ramas() -> void:
	var c: CharacterData = load("res://data/characters/kuranes.tres")
	assert_true(c.in_shop)
	assert_gt(c.price, 0)
	assert_gt(c.sanity_regen, 0.0, "medio dormido")
	assert_eq(c.dodge_style.id, &"sueno")
	assert_gt(c.dodge_style.dream, 0.0)
	assert_true(FileAccess.file_exists("res://models/kuranes.json"))
	var w: WeaponData = load("res://data/weapons/ensueno_celephais.tres")
	assert_eq(w.delivery, WeaponData.Delivery.DREAM)
	assert_lt(w.slow_factor, 1.0)
	assert_eq(w.evolves_with, &"adormidera")
	assert_eq(w.evolution, &"ooth_nargai")
	assert_eq(w.evolution_alt, &"serannian")
	assert_gt((load("res://data/weapons/ooth_nargai.tres") as WeaponData).dream_sleep, 0.0)
	assert_gt((load("res://data/weapons/serannian.tres") as WeaponData).dream_follow, 0.0)

func test_dentro_van_cada_vez_mas_despacio_y_sueñan() -> void:
	var e := _enemy(Vector3(1, 0, 0))
	var far := _enemy(Vector3(9, 0, 0))
	var z := _zone(Vector3.ZERO)
	_run(z, 0.1)
	var first := e.speed_mult()
	assert_lt(first, 1.0, "al entrar ya se frena")
	assert_true(e.is_dreaming())
	_run(z, 1.5)
	assert_lt(e.speed_mult(), first, "y cada vez más")
	assert_almost_eq(e.speed_mult(), 0.45, 0.01, "hasta el freno entero")
	assert_eq(far.speed_mult(), 1.0, "el de fuera, no")
	assert_false(far.is_dreaming())
	assert_lt(e.health, 1000.0, "y daña poco a poco")

func test_frena_las_balas_enemigas_que_entran() -> void:
	var z := _zone(Vector3.ZERO)
	world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, Vector3(1, 0.8, 0), Vector3(4, 0, 0),
		0.2, 0.2, Damage.new(5.0, 0.0), 3.0, 0, 0.0, -1)
	_run(z, 0.05)
	assert_eq(z.slowed, 1)

func test_los_investigadores_descansan_dentro() -> void:
	var p := _player()
	var q := _player(Vector3(10, 0, 0))
	p.sanity = 40.0
	q.sanity = 40.0
	var z := _zone(Vector3.ZERO, 4.0, 1.0)
	_run(z, 1.0)
	assert_almost_eq(p.sanity, 41.0, 0.05, "el de dentro recupera")
	assert_eq(q.sanity, 40.0, "el de fuera, no")

func test_se_apaga_y_se_va() -> void:
	var z := _zone(Vector3.ZERO, 0.5)
	_run(z, 0.6)
	assert_true(z.ending())
	_run(z, 0.6)
	assert_true(z.is_queued_for_deletion())

func test_sin_enemigos_no_sueña_ni_cuesta() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/ensueno_celephais.tres"))
	var before := p.sanity
	world.rebuild_grid()
	assert_false(p.weapons._fire(w))
	assert_eq(p.sanity, before)
	assert_eq(_zones().size(), 0)

func test_el_arma_pone_el_sueño_donde_hay_enemigos() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/ensueno_celephais.tres"))
	_enemy(Vector3(5, 0, 0))
	var before := p.sanity
	world.rebuild_grid()
	assert_true(p.weapons._fire(w))
	var zs := _zones()
	assert_eq(zs.size(), 1)
	assert_lt((zs[0] as DreamZone).global_position.distance_to(Vector3(5, 0, 0)), 0.5)
	assert_lt(p.sanity, before, "cuesta cordura")

func test_ooth_nargai_duerme_a_los_que_se_quedan() -> void:
	var e := _enemy(Vector3(1, 0, 0))
	var z := _zone(Vector3.ZERO)
	z.sleep = 2.0
	_run(z, 1.0)
	assert_eq(z.slept, 0, "aún no")
	_run(z, 1.0)
	assert_eq(z.slept, 1)
	assert_gt(e._stun, 0.0, "dormido")
	_run(z, 1.5)
	assert_eq(z.slept, 1, "una vez cada uno")

func test_serannian_va_con_el_y_no_se_amontona() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/serannian.tres"))
	world.rebuild_grid()
	assert_true(p.weapons._fire(w), "sale aunque no haya nadie")
	assert_false(p.weapons._fire(w), "una a la vez")
	var z: DreamZone = _zones()[0]
	p.position = Vector3(3, 0, 2)
	_run(z, 0.05)
	assert_lt(z.global_position.distance_to(Vector3(3, 0, 2)), 0.01, "le sigue")

func test_el_esquive_deja_un_sueño_donde_estaba() -> void:
	var p := _player()
	var e := _enemy(Vector3(0.5, 0, 0))
	world.rebuild_grid()
	p._on_dodge()
	var zs := _zones()
	assert_eq(zs.size(), 1)
	_run(zs[0], 0.1)
	assert_lt(e.speed_mult(), 1.0)
	assert_eq(e.health, 1000.0, "el del esquive no daña")

func test_la_adormidera_frena_mas() -> void:
	var cd := CharacterData.new()
	cd.slow_add = 0.06
	var w: WeaponData = load("res://data/weapons/ensueno_celephais.tres")
	assert_almost_eq(WeaponSystem.with_items(w, "slow_factor", 0.45, cd), 0.39, 0.0001)
	assert_eq(WeaponSystem.with_items(w, "slow_factor", 1.0, cd), 1.0, "lo que no frena, nada")
