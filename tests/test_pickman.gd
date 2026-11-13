extends GutTest
## Hito 20.17: Richard Upton Pickman (lienzos que atraen, revientan y sueltan un necrófago;
## esquive por un cuadro).

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

func _canvas(life := 6.0) -> Canvas:
	var c := Canvas.new().setup(world, Vector3.ZERO, Vector3.FORWARD, life, 4.5, 10.0, 3.0, 0.4, 1.0, {})
	world.fx.add_child(c)
	return c

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT):
		world.rebuild_grid()
		node._physics_process(DT)

func _ghouls() -> Array:
	return world.fx.get_children().filter(func(n: Node) -> bool: return n is Reanimated and (n as Reanimated).look == "pickman")

func test_en_la_tienda_con_su_arma_y_dos_ramas() -> void:
	var c: CharacterData = load("res://data/characters/pickman.tres")
	assert_true(c.in_shop)
	assert_gt(c.price, 0)
	assert_eq(c.dodge_style.id, &"cuadro")
	assert_true(c.dodge_style.frames)
	assert_lt(c.mental_mult, 1.0, "pierde menos cordura")
	assert_true(FileAccess.file_exists("res://models/pickman.json"))
	assert_true(FileAccess.file_exists("res://models/necrofago.json"))
	assert_true(FileAccess.file_exists("res://models/lienzo.json"))
	var w: WeaponData = load("res://data/weapons/lienzos.tres")
	assert_eq(w.delivery, WeaponData.Delivery.CANVAS)
	assert_eq(w.evolves_with, &"foto_modelo")
	assert_eq(w.evolution, &"galeria_pickman")
	assert_eq(w.evolution_alt, &"modelo_natural")
	assert_eq((load("res://data/weapons/modelo_natural.tres") as WeaponData).split_count, 2.0, "tres necrófagos")

func test_el_lienzo_atrae_y_deja_vulnerables() -> void:
	var near := _enemy(Vector3(3, 0, 0))
	var far := _enemy(Vector3(8, 0, 0))
	var c := _canvas()
	_run(c, 0.3)
	assert_true(near.is_vulnerable())
	assert_gt(near._lure_t, 0.0, "atraído")
	assert_false(far.is_vulnerable())

func test_al_romperse_revienta_y_sale_el_necrofago() -> void:
	var e := _enemy(Vector3(0.3, 0, 0))
	var c := _canvas()
	_run(c, 3.0)
	assert_true(c.broken, "lo rompen a toques")
	assert_lt(e.health, 1000.0, "el salpicón hace daño")
	assert_eq(_ghouls().size(), 1)

func test_tambien_revienta_al_acabarse() -> void:
	var c := _canvas(0.5)
	_run(c, 0.7)
	assert_true(c.broken)
	assert_eq(_ghouls().size(), 1)

func test_el_modelo_del_natural_suelta_tres() -> void:
	var c := _canvas(0.3)
	c.ghouls = 3
	_run(c, 0.5)
	assert_eq(_ghouls().size(), 3)

func test_la_fotografia_alarga_los_aliados() -> void:
	var cd: CharacterData = (load("res://data/characters/pickman.tres") as CharacterData).duplicate()
	var w: WeaponData = load("res://data/weapons/lienzos.tres")
	var base := WeaponSystem.with_items(w, "ally_time", w.ally_time, cd)
	cd.ally_mult = 1.12
	assert_almost_eq(WeaponSystem.with_items(w, "ally_time", w.ally_time, cd), base * 1.12, 0.001)
