extends GutTest
## Objetos rompibles, recompensas y congelación del tiempo.

var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	world.fx = Node3D.new()
	world.add_child(world.fx)
	add_child_autofree(world)

func test_se_golpean_pero_no_se_apuntan() -> void:
	var b := Breakable.new().setup(world, Vector3(1, 0, 0))
	world.fx.add_child(b)
	world.rebuild_grid()
	assert_null(world.nearest_enemy(Vector3.ZERO, 5.0), "un barril no es un enemigo")
	assert_eq(world.enemies_in_circle(Vector3.ZERO, 5.0).size(), 1, "pero las explosiones lo alcanzan")
	b.take_damage(Damage.new(100.0, 0.0))
	assert_false(b.is_alive())
	assert_eq(world.breakables.size(), 0)

func test_la_congelacion_caduca() -> void:
	world.freeze_time(5.0)
	assert_gt(world.freeze_t, 0.0)
	world._physics_process(6.0)
	assert_lte(world.freeze_t, 0.0)

func test_las_recompensas_tienen_modelo() -> void:
	for m in Pickup.MODELS: assert_true(FileAccess.file_exists("res://models/%s.json" % m), m)
	var total := 0.0
	for w in Pickup.WEIGHTS: total += w
	assert_almost_eq(total, 1.0, 0.001)

func test_al_pisarla_se_recoge() -> void:
	var p := Player.new()
	p.data = load("res://data/characters/dyer.tres").duplicate()
	p.health = 10.0
	world.players.append(p)
	add_child_autofree(p)
	p.health = 10.0
	var k := Pickup.new().setup(world, Vector3.ZERO, Pickup.Kind.FOOD)
	world.fx.add_child(k)
	k._physics_process(0.016)
	assert_gt(p.health, 10.0, "la comida cura")
	assert_true(k.is_queued_for_deletion())
