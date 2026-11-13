extends GutTest
## Hito 20.19: Walter Gilman (ángulos que doblan esquinas y atraviesan el decorado; esquive por
## un ángulo imposible; blanco más pequeño).

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
	p.world = world
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _angle(vel: Vector3, every := 0.2, life := 3.0) -> void:
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.ANGLE, Vector3.ZERO, vel, 0.2, 0.3,
		Damage.new(10.0, 0.0), life, 0, 1.0, -1, 0, -every)

func test_en_la_tienda_con_su_arma_y_dos_ramas() -> void:
	var c: CharacterData = load("res://data/characters/gilman.tres")
	assert_true(c.in_shop)
	assert_gt(c.price, 0)
	assert_eq(c.dodge_style.id, &"angulo")
	assert_true(c.dodge_style.phase)
	assert_lt(c.hurt_radius, CharacterData.new().hurt_radius, "blanco más pequeño")
	assert_true(FileAccess.file_exists("res://models/gilman.json"))
	var w: WeaponData = load("res://data/weapons/angulos_imposibles.tres")
	assert_gt(w.angle_turn, 0.0)
	assert_eq(w.bullet_look, "angle")
	assert_eq(w.evolves_with, &"estatuilla_balaustrada")
	assert_eq(w.evolution, &"geometria_bruja")
	assert_eq(w.evolution_alt, &"trono_azathoth")
	assert_gt((load("res://data/weapons/trono_azathoth.tres") as WeaponData).split_count, 0.0, "se abre en esquirlas")

func test_el_angulo_dobla_en_angulo_recto_hacia_el_enemigo() -> void:
	var e := _enemy(Vector3(4, 0, 4))
	_angle(Vector3(10, 0, 0))                        # sale hacia +X; el enemigo, a 45° a la izquierda
	var dirs: Array[Vector3] = []
	for i in 90:
		world.rebuild_grid()
		world.bullets._physics_process(DT)
		if world.bullets.count == 0: break
		var v: Vector3 = world.bullets._vel[0].normalized()
		if dirs.is_empty() or not dirs[-1].is_equal_approx(v): dirs.append(v)
	assert_lt(e.health, 1000.0, "acaba dando")
	assert_gt(dirs.size(), 1, "ha girado")
	for k in range(1, dirs.size()):
		assert_almost_eq(absf(dirs[k].dot(dirs[k - 1])), 0.0, 0.001, "siempre en ángulo recto")

func test_sin_enemigos_sigue_recto() -> void:
	_angle(Vector3(10, 0, 0))
	for i in 30: world.bullets._physics_process(DT)
	assert_true(world.bullets._vel[0].normalized().is_equal_approx(Vector3.RIGHT))

func test_las_esquirlas_tambien_doblan() -> void:
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.ANGLE, Vector3.ZERO, Vector3(10, 0, 0), 0.2, 0.3,
		Damage.new(10.0, 0.0), 0.05, 0, 1.0, -1, 4, -0.2)
	for i in 5: world.bullets._physics_process(DT)
	assert_eq(world.bullets.count, 4)
	for i in world.bullets.count: assert_lt(world.bullets._home[i], 0.0)

func test_el_arma_sale_torcida_y_con_su_aspecto() -> void:
	var p := _player("gilman")
	p.weapons.add_weapon(load("res://data/weapons/angulos_imposibles.tres"))
	_enemy(Vector3(5, 0, 0))
	for i in 120:
		world.rebuild_grid()
		p.weapons._physics_process(DT)
		if world.bullets.count > 0: break
	assert_gt(world.bullets.count, 0)
	assert_eq(world.bullets._style[0], BulletManager.Style.ANGLE)
	assert_lt(world.bullets._home[0], 0.0)
	var v: Vector3 = world.bullets._vel[0].normalized()
	assert_almost_eq(absf(v.x), absf(v.z), 0.2, "a 45° del objetivo")

func test_la_estatuilla_agranda_las_balas() -> void:
	var cd := CharacterData.new()
	var bullet: WeaponData = load("res://data/weapons/angulos_imposibles.tres")
	var thrown: WeaponData = load("res://data/weapons/bateria_morteros.tres")
	cd.proj_size_mult = 1.12
	assert_almost_eq(WeaponSystem.with_items(bullet, "projectile_radius", 0.2, cd), 0.224, 0.0001)
	assert_almost_eq(WeaponSystem.with_items(bullet, "projectile_size", 0.3, cd), 0.336, 0.0001)
	assert_eq(WeaponSystem.with_items(thrown, "projectile_radius", 0.2, cd), 0.2, "solo las balas")

func test_el_esquive_atraviesa_pero_no_sale_de_la_arena() -> void:
	world.obstacles = obstacles
	var p := _player("gilman")
	p.velocity = Vector3(24, 0, 0)
	p._phase_move(0.5)
	assert_almost_eq(p.position.x, 12.0, 0.001, "en línea recta, sin rodear nada")
	p._phase_move(2.0)
	assert_almost_eq(p.position.x, 32.0 - p.data.collision_radius, 0.001, "hasta el límite")
