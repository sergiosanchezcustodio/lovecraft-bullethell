extends GutTest
## Enemigos nuevos de la fase 15 (hito 15.3): el expedicionario se levanta si no lo rematan y el
## tambor del tamborilero acelera a los cercanos.

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

func _enemy(id: String, pos: Vector3) -> Enemy:
	var e := Enemy.new().setup(load("res://data/enemies/%s.tres" % id), world, obstacles)
	e.position = pos
	root.add_child(e)
	e._rise_wait = 0.0                              # ya ha aparecido
	return e

func _step(e: Enemy, seconds: float) -> void:
	for i in int(seconds / DT): e._physics_process(DT)

func test_los_tres_existen_y_salen_en_su_nivel() -> void:
	for pair in [["expedicionario", "p1_n2"], ["nadador", "p2_n4"], ["nadador", "p2_n5"], ["tamborilero", "p3_n2"]]:
		var d: EnemyData = load("res://data/enemies/%s.tres" % pair[0])
		assert_true(FileAccess.file_exists("res://models/%s.json" % d.model), d.model)
		assert_ne(Library.text("enemies", String(d.id)), "", "texto del bestiario de " + pair[0])
		var lv: LevelData = load("res://data/levels/%s.tres" % pair[1])
		assert_true(lv.pool.any(func(x: EnemyData) -> bool: return x.id == d.id), "%s en %s" % pair)

func test_el_expedicionario_se_levanta_si_no_lo_rematan() -> void:
	var e := _enemy("expedicionario", Vector3.ZERO)
	e.take_damage(Damage.new(1e4, 0.0))
	assert_true(e.is_alive(), "cae, pero no muere")
	assert_eq(e.anim, "down")
	_step(e, e.data.revive_time + 0.1)
	assert_almost_eq(e.health, e.data.max_health * e.health_scale * e.data.revive, 0.01, "se levanta con media vida")
	_step(e, 1.0)
	assert_eq(e.anim, "walk")
	e.take_damage(Damage.new(1e4, 0.0))
	assert_false(e.is_alive(), "la segunda vez, muere")

func test_caido_un_golpe_lo_remata() -> void:
	var e := _enemy("expedicionario", Vector3.ZERO)
	e.take_damage(Damage.new(1e4, 0.0))
	_step(e, 0.5)
	e.take_damage(Damage.new(1.0, 0.0))
	assert_false(e.is_alive())

func test_el_tambor_acelera_a_los_cercanos() -> void:
	var drum := _enemy("tamborilero", Vector3.ZERO)
	var near := _enemy("cultista", Vector3(3, 0, 0))
	var far := _enemy("cultista", Vector3(20, 0, 0))
	for e in [drum, near, far]: world.enemies.append(e)
	_step(drum, 0.1)
	assert_gt(near.drum_t, 0.0, "el cercano, al ritmo")
	assert_eq(far.drum_t, 0.0, "el lejano, no")
