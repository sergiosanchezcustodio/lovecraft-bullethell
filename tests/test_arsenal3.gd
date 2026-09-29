extends GutTest
## Arsenal II, segunda tanda (hito 2.7b): las 4 de fuego y las 5 físicas. Rayo que salta,
## tirador que busca a la élite y hace críticos, torreta, pistolas adelante y atrás, suero que
## levanta aliados, bumerán de ida y vuelta, red que inmoviliza, grieta que avanza y estocada.

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

func _player(id: String = "dyer") -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _weapon(p: Player, id: String) -> WeaponSystem.Weapon:
	return p.weapons.add_weapon(load("res://data/weapons/%s.tres" % id))

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT): node._physics_process(DT)

func _last_fx() -> Node:
	return world.fx.get_child(world.fx.get_child_count() - 1)

func test_las_nueve_armas_existen_con_su_grupo() -> void:
	var groups := {"tesla": 1, "springfield": 1, "lewis": 1, "lugers": 1,
		"west": 0, "bumeran": 0, "red": 0, "martillo": 0, "estoque": 0}
	for id in groups:
		var wd: WeaponData = load("res://data/weapons/%s.tres" % id)
		assert_not_null(wd, id)
		assert_eq(int(wd.category), int(groups[id]), id)
		assert_eq(wd.level_mods.size(), wd.max_level - 1, id)
		assert_eq(wd.level_text.size(), wd.max_level - 1, id)

func test_los_tres_grupos_quedan_equilibrados() -> void:
	var n := [0, 0, 0]
	for wd: WeaponData in DebugOptions.list_resources("res://data/weapons"): n[wd.category] += 1
	assert_eq(n, [11, 12, 11], "11 físicas, 12 de fuego y 11 mágicas (GDD 5.3)")

func test_el_rayo_tesla_salta_de_enemigo_en_enemigo() -> void:
	var p := _player()
	var a := _enemy(Vector3(2, 0, 0))
	var b := _enemy(Vector3(4.5, 0, 0))
	var c := _enemy(Vector3(7, 0, 0))
	var far := _enemy(Vector3(15, 0, 0))
	world.rebuild_grid()
	var w := _weapon(p, "tesla")
	assert_true(p.weapons._chain(w, Vector3.ZERO))
	assert_lt(a.health, 1000.0)
	assert_lt(b.health, 1000.0)
	assert_lt(c.health, 1000.0)
	assert_eq(far.health, 1000.0, "demasiado lejos para saltar")
	assert_gt(1000.0 - a.health, 1000.0 - c.health, "cada salto hace menos")

func test_el_springfield_busca_a_la_elite() -> void:
	var p := _player()
	_enemy(Vector3(2, 0, 0))
	var elite := _enemy(Vector3(6, 0, 0))
	elite.data.elite = true
	world.rebuild_grid()
	assert_eq(world.strongest_enemy(Vector3.ZERO, 10.0), elite)

func test_sin_elites_busca_al_de_mas_vida() -> void:
	_enemy(Vector3(2, 0, 0), 50.0)
	var big := _enemy(Vector3(6, 0, 0), 400.0)
	world.rebuild_grid()
	assert_eq(world.strongest_enemy(Vector3.ZERO, 10.0), big)

func test_el_springfield_hace_criticos() -> void:
	var p := _player()
	var w := _weapon(p, "springfield")
	w.data = w.data.duplicate()
	w.data.crit_chance = 1.0
	p.weapons._spawn_bullet(w, Vector3.RIGHT)
	assert_almost_eq(world.bullets._phys[0], p.weapons.dmg(w) * 3.0, 0.01)

func test_la_lewis_dispara_sola() -> void:
	_enemy(Vector3(5, 0, 0))
	world.rebuild_grid()
	var t := Turret.new().setup(world, Vector3.ZERO, 3.0, 0.2, 5.0, 10.0, 26.0, -1)
	world.fx.add_child(t)
	_run(t, 1.0)
	assert_gte(t.shots, 4)
	_run(t, 3.0)
	assert_false(is_instance_valid(t) and not t.is_queued_for_deletion(), "se retira al acabar")

func test_las_lugers_disparan_delante_y_detras() -> void:
	var p := _player()
	p.motor.facing = Vector3(1, 0, 0)
	var w := _weapon(p, "lugers")
	p.weapons._fire(w)
	assert_eq(world.bullets.count, 2)
	assert_almost_eq(world.bullets._vel[0].normalized().dot(world.bullets._vel[1].normalized()), -1.0, 0.01)

func test_el_inyectado_que_muere_se_levanta_como_aliado() -> void:
	var e := _enemy(Vector3.ZERO, 10.0)
	var victim := _enemy(Vector3(0.6, 0, 0))
	world.rebuild_grid()
	e.inject(4.0)
	e.take_damage(Damage.new(50.0, 0.0))
	var ally: Reanimated = null
	for c in world.fx.get_children():
		if c is Reanimated: ally = c
	assert_not_null(ally, "se levanta")
	world.rebuild_grid()
	_run(ally, 1.0)
	assert_gt(ally.hits, 0)
	assert_lt(victim.health, 1000.0, "ataca a los suyos")

func test_el_no_inyectado_no_se_levanta() -> void:
	var e := _enemy(Vector3.ZERO, 10.0)
	e.take_damage(Damage.new(50.0, 0.0))
	for c in world.fx.get_children(): assert_false(c is Reanimated)

func test_el_bumeran_golpea_a_la_ida_y_a_la_vuelta() -> void:
	var p := _player()
	var e := _enemy(Vector3(3, 0, 0))
	world.rebuild_grid()
	var b := Boomerang.new().setup(p, world, Vector3.RIGHT, 5.0, 12.0, 0.5, 10.0, 0.0, {})
	world.fx.add_child(b)
	for i in int(3.0 / DT):
		if not is_instance_valid(b) or b.is_queued_for_deletion(): break
		world.rebuild_grid()
		b._physics_process(DT)
	assert_eq(e.health, 980.0, "dos golpes: ida y vuelta")

func test_la_red_inmoviliza_y_a_las_elites_solo_las_frena() -> void:
	var e := _enemy(Vector3(0.5, 0, 0))
	var elite := _enemy(Vector3(-0.5, 0, 0))
	elite.data.elite = true
	world.rebuild_grid()
	var t := ThrownExplosive.new()
	t.setup(world, Vector3(0, 1, 0), Vector3.ZERO, 0.1, 0.0, 2.0, 3.0, Color.WHITE)
	t.configure("red", 1.0, {}, 0.0, {})
	t.net = 2.0
	world.fx.add_child(t)
	_run(t, 0.2)
	assert_true(e.is_rooted())
	assert_false(elite.is_rooted())
	assert_lt(elite.speed_mult(), 1.0)

func test_el_inmovil_no_se_mueve() -> void:
	var p := _player()
	p.position = Vector3(5, 0, 0)
	var e := _enemy(Vector3.ZERO)
	e.root(1.0)
	_run(e, 0.5)
	assert_eq(e.position, Vector3.ZERO)

func test_la_grieta_avanza_y_golpea_una_vez_a_cada_uno() -> void:
	var near := _enemy(Vector3(1.5, 0, 0))
	var far := _enemy(Vector3(5, 0, 0))
	var side := _enemy(Vector3(3, 0, 3))
	world.rebuild_grid()
	var f := Fissure.new().setup(world, Vector3.ZERO, Vector3.RIGHT, 6.0, 12.0, 0.7, 10.0, 0.3, {})
	world.fx.add_child(f)
	_run(f, 0.2)
	assert_eq(near.health, 990.0)
	assert_eq(far.health, 1000.0, "aún no ha llegado")
	_run(f, 0.6)
	assert_eq(near.health, 990.0, "una sola vez")
	assert_eq(far.health, 990.0)
	assert_eq(side.health, 1000.0, "fuera de la línea")

func test_la_estocada_atraviesa_la_linea_y_espera_sin_nadie_cerca() -> void:
	var p := _player()
	var w := _weapon(p, "estoque")
	assert_false(p.weapons._thrust(w))
	var a := _enemy(Vector3(1, 0, 0))
	var b := _enemy(Vector3(2.5, 0, 0))
	var off := _enemy(Vector3(0, 0, 2.5))
	world.rebuild_grid()
	assert_true(p.weapons._thrust(w))
	assert_lt(a.health, 1000.0)
	assert_lt(b.health, 1000.0)
	assert_eq(off.health, 1000.0)

func test_el_rasgo_de_johansen_vale_para_el_estoque() -> void:
	var p := _player("johansen")
	var w := _weapon(p, "estoque")
	assert_almost_eq(p.weapons.dmg(w), w.stat("damage") * p.damage_mult(w.data.category) * p.data.melee_mult, 0.01)
