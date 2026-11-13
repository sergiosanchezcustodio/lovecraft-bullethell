extends GutTest
## Hito 20.18: Charles Dexter Ward (sales que levantan a los caídos, la sombra de Curwen y el
## esquive en polvo).

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

func _data() -> EnemyData:
	return load("res://data/enemies/pinguino.tres") as EnemyData

func _enemy(pos: Vector3, hp: float = 1000.0) -> Enemy:
	var d: EnemyData = _data().duplicate()
	d.max_health = hp
	var e := Enemy.new().setup(d, world, obstacles)
	e.position = pos
	root.add_child(e)
	return e

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT):
		world.clock += DT
		world.rebuild_grid()
		node._physics_process(DT)

func _risen() -> Array:
	return world.fx.get_children().filter(func(n: Node) -> bool: return n is Reanimated and (n as Reanimated).look == "ward")

func _player(id: String) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func test_en_la_tienda_con_su_arma_y_dos_ramas() -> void:
	var c: CharacterData = load("res://data/characters/ward.tres")
	assert_true(c.in_shop)
	assert_gt(c.price, 0)
	assert_lt(c.max_health, 90.0, "poca vida")
	assert_eq(c.dodge_style.id, &"polvo")
	assert_true(c.dodge_style.dust)
	assert_gt(c.low_sanity_bonus, 0.0)
	assert_true(FileAccess.file_exists("res://models/ward.json"))
	var w: WeaponData = load("res://data/weapons/sales_esenciales.tres")
	assert_eq(w.delivery, WeaponData.Delivery.SALTS)
	assert_gt(w.sanity_cost, 0.0, "cuesta cordura")
	assert_eq(w.evolves_with, &"frasco_custodes")
	assert_eq(w.evolution, &"cabeza_dragon")
	assert_eq(w.evolution_alt, &"cola_dragon")
	assert_gt((load("res://data/weapons/cola_dragon.tres") as WeaponData).ally_blast, 0.0, "la Cola del Dragón revienta")

func test_los_restos_se_apuntan_y_se_olvidan() -> void:
	world.add_remains(_data(), Vector3(2, 0, 0))
	world.add_remains(_data(), Vector3(2.5, 0, 0))
	world.add_remains(_data(), Vector3(-6, 0, 0))
	assert_eq(world.remains_spot(Vector3.ZERO, 7.0, 1.5).x, 2.0, "donde más han caído")
	assert_eq(world.remains_spot(Vector3(30, 0, 0), 7.0, 1.5), Vector3.INF, "ninguno a su alcance")
	var got := world.take_remains(Vector3(2, 0, 0), 1.5, 1)
	assert_eq(got.size(), 1)
	assert_eq((got[0][1] as Vector3).x, 2.5, "el más reciente primero")
	assert_eq(world.remains.size(), 2, "lo que se levanta ya no está")
	world.clock += CombatWorld.REMAINS_LIFE + 1.0
	assert_eq(world.remains_spot(Vector3.ZERO, 7.0, 1.5), Vector3.INF, "pasado un rato, se olvidan")
	for i in CombatWorld.REMAINS_MAX + 10: world.add_remains(_data(), Vector3.ZERO)
	assert_eq(world.remains.size(), CombatWorld.REMAINS_MAX, "con tope")

func test_al_morir_deja_sus_restos_salvo_los_unicos() -> void:
	var e := _enemy(Vector3(1, 0, 0), 5.0)
	e.take_damage(Damage.new(50.0, 0.0))
	assert_eq(world.remains.size(), 1)
	var u := _enemy(Vector3(3, 0, 0), 5.0)
	u.data.unique = true
	u.take_damage(Damage.new(50.0, 0.0))
	assert_eq(world.remains.size(), 1, "un jefe no se levanta")

func test_las_sales_levantan_a_los_caidos_y_danan() -> void:
	var e := _enemy(Vector3(1, 0, 0))
	for i in 3: world.add_remains(_data(), Vector3(0.5 * i, 0, 0.5))
	var s := SaltCircle.new().setup(world, Vector3.ZERO, 2.8, 5.0, 2, 4.0, 0.4, 0.0, {})
	world.fx.add_child(s)
	_run(s, 0.5)
	assert_true(s.done)
	assert_eq(s.risen, 2, "como mucho `count`")
	assert_eq(_risen().size(), 2)
	assert_eq(world.remains.size(), 1, "queda uno para la próxima vez")
	assert_almost_eq(e.health, 1000.0 - 5.0 * SaltCircle.FORMULA, 0.01, "la fórmula daña")

func test_sin_restos_no_levanta_a_nadie() -> void:
	var s := SaltCircle.new().setup(world, Vector3.ZERO, 2.8, 5.0, 2, 4.0, 0.4, 0.0, {})
	world.fx.add_child(s)
	_run(s, 0.5)
	assert_eq(s.risen, 0)

func test_la_cola_del_dragon_revienta_al_deshacerse() -> void:
	var e := _enemy(Vector3(0.9, 0, 0))
	var g := Reanimated.new().setup(world, _data(), Vector3.ZERO, Vector3.FORWARD, 0.3, {})
	g.look = "ward"
	g.dps = 0.0
	g.blast = 40.0
	world.fx.add_child(g)
	_run(g, 0.5)
	assert_true(g.blasted)
	assert_almost_eq(e.health, 960.0, 0.01)

func test_sin_nadie_cerca_no_gasta_cordura() -> void:
	var p := _player("ward")
	p.weapons.add_weapon(load("res://data/weapons/sales_esenciales.tres"))
	var before := p.sanity
	_run(p.weapons, 5.0)
	assert_eq(p.sanity, before, "espera a que haya a quién")
	_enemy(Vector3(3, 0, 0))
	_run(p.weapons, 5.0)
	assert_lt(p.sanity, before, "con enemigos cerca, recita y paga")

func test_la_sombra_de_curwen() -> void:
	var p := _player("ward")
	p.sanity = p.data.max_sanity
	var full := p.damage_mult(WeaponData.Category.MAGIC)
	p.sanity = 0.0
	assert_almost_eq(p.damage_mult(WeaponData.Category.MAGIC) / full, 1.4, 0.001, "+40 % a cero")
	p.sanity = p.data.max_sanity * 0.5
	assert_almost_eq(p.damage_mult(WeaponData.Category.MAGIC) / full, 1.2, 0.001)

func test_el_frasco_hace_que_los_aliados_golpeen_mas() -> void:
	for i in 2: world.add_remains(_data(), Vector3.ZERO)
	var s := SaltCircle.new().setup(world, Vector3.ZERO, 2.8, 4.0, 2, 4.0, 0.4, 0.0, {})
	s.power = 1.15
	world.fx.add_child(s)
	_run(s, 0.5)
	for g: Reanimated in _risen(): assert_almost_eq(g.dps, 4.0 / 0.4 * 1.15, 0.001)
