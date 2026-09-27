extends GutTest
## Arsenal I (hito 2.6): zonas de daño, estados de los enemigos, bengalas, fuegos
## artificiales, granada al impacto y lanzallamas.

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

func _player(id: String) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT): node._physics_process(DT)

func test_la_zona_de_fuego_quema_a_los_de_dentro() -> void:
	var inside := _enemy(Vector3(0.5, 0, 0))
	var outside := _enemy(Vector3(5, 0, 0))
	world.rebuild_grid()
	var z := DamageZone.new().setup(world, WeaponData.Zone.FIRE, Vector3.ZERO, 1.5, 2.0, 10.0)
	world.fx.add_child(z)
	_run(z, 1.0)
	assert_almost_eq(inside.health, 1000.0 - 10.0, 3.1, "unos 10 de daño en un segundo")
	assert_eq(outside.health, 1000.0)

func test_el_acido_deja_vulnerable() -> void:
	var e := _enemy(Vector3.ZERO)
	world.rebuild_grid()
	var z := DamageZone.new().setup(world, WeaponData.Zone.ACID, Vector3.ZERO, 1.5, 2.0, 0.0, 3.0)
	world.fx.add_child(z)
	_run(z, 0.1)
	assert_true(e.is_vulnerable())
	e.take_damage(Damage.new(100.0, 0.0))
	assert_almost_eq(e.health, 1000.0 - 125.0, 0.01, "+25 % de daño")

func test_la_bengala_atrae_a_los_cercanos_pero_no_a_las_elites() -> void:
	var e := _enemy(Vector3(4, 0, 0))
	var elite := _enemy(Vector3(-4, 0, 0))
	elite.data.elite = true
	world.rebuild_grid()
	var f := Flare.new().setup(world, Vector3.ZERO, 3.0, 7.0)
	world.fx.add_child(f)
	for i in 12: f._physics_process(DT)
	assert_gt(e._lure_t, 0.0)
	assert_eq(elite._lure_t, 0.0)

func test_los_fuegos_artificiales_se_dividen_al_apagarse() -> void:
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.PLAYER, Vector3.ZERO, Vector3(10, 0, 0),
		0.2, 0.2, Damage.new(10, 0), 0.05, 0, 1.0, -1, 6)
	for i in 5: world.bullets._physics_process(DT)
	assert_eq(world.bullets.count, 6, "una bala se convierte en seis chispas")

func test_la_granada_explota_al_impactar() -> void:
	var p := _player("dyer")
	var w := p.weapons.get_weapon(&"granada")
	if w == null: w = p.weapons.add_weapon(load("res://data/weapons/granada.tres"))
	var e := _enemy(Vector3(5, 0, 0))
	world.rebuild_grid()
	p.weapons._throw(w, Vector3(5, 0, 0))
	var g: ThrownExplosive = world.fx.get_child(world.fx.get_child_count() - 1)
	_run(g, w.stat("flight_time") + 0.05)
	assert_lt(e.health, 1000.0, "sin mecha: daña al caer")

func test_el_lanzallamas_quema_en_su_cono() -> void:
	var p := _player("dyer")
	var w := p.weapons.add_weapon(load("res://data/weapons/flammenwerfer.tres"))
	var ahead := _enemy(Vector3(3, 0, 0))
	var behind := _enemy(Vector3(-3, 0, 0))
	world.rebuild_grid()
	p.weapons._flame(w, Vector3(10, 0, 0))
	var jet: FlameJet = world.fx.get_child(world.fx.get_child_count() - 1)
	_run(jet, 0.5)
	assert_lt(ahead.health, 1000.0)
	assert_eq(behind.health, 1000.0)
