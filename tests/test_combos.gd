extends GutTest
## Combinaciones en cooperativo (hito 13.7): cuáles salen, solo entre jugadores distintos.

var world: CombatWorld
var root: Node3D
var obstacles: ObstacleMap
var combos: Combos

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)
	combos = Combos.attach(world)
	combos.cfg.cooldown = 0.0

func _enemy(pos: Vector3, hp: float = 1000.0) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	d.max_health = hp
	var e := Enemy.new().setup(d, world, obstacles)
	e.position = pos
	root.add_child(e)
	return e

func _zone(kind: int, pos: Vector3, tag: StringName, r := 1.5) -> DamageZone:
	Damage.ctx = tag
	var z := DamageZone.new().setup(world, kind, pos, r, 4.0, 5.0)
	world.fx.add_child(z)
	Damage.ctx = &""
	return z

func test_dueño_de_la_etiqueta() -> void:
	assert_eq(Combos.owner_of(&"J2:molotov"), 1)
	assert_eq(Combos.owner_of(&"combo"), -1)
	assert_eq(Combos.owner_of(&""), -1)

func test_fuego_sobre_acido_de_otro_da_nube_toxica() -> void:
	var acid := _zone(WeaponData.Zone.ACID, Vector3.ZERO, &"J1:lanzaquimicos")
	_zone(WeaponData.Zone.FIRE, Vector3(1, 0, 0), &"J2:molotov")
	assert_eq(int(combos.fired.get("nube_toxica", 0)), 1)
	assert_true(acid.has_meta("combo_used"), "el ácido se consume")
	var gas := get_tree().get_nodes_in_group(&"combo_zones").filter(func(n: Node) -> bool:
		return (n as DamageZone).kind == WeaponData.Zone.GAS)
	assert_eq(gas.size(), 1, "nace la nube")

func test_del_mismo_jugador_no_se_combinan() -> void:
	_zone(WeaponData.Zone.ACID, Vector3.ZERO, &"J1:lanzaquimicos")
	_zone(WeaponData.Zone.FIRE, Vector3(1, 0, 0), &"J1:molotov")
	assert_true(combos.fired.is_empty())
	combos.solo = true
	_zone(WeaponData.Zone.FIRE, Vector3(0.5, 0, 0), &"J1:molotov")
	assert_eq(int(combos.fired.get("nube_toxica", 0)), 1, "con combos_solo, sí")

func test_lejos_no_se_tocan() -> void:
	_zone(WeaponData.Zone.ACID, Vector3.ZERO, &"J1:lanzaquimicos")
	_zone(WeaponData.Zone.FIRE, Vector3(5, 0, 0), &"J2:molotov")
	assert_true(combos.fired.is_empty())

func test_explosion_sobre_gas_deflagra_y_daña() -> void:
	var e := _enemy(Vector3(0.5, 0, 0))
	world.rebuild_grid()
	_zone(WeaponData.Zone.GAS, Vector3.ZERO, &"J1:gas")
	Combos.blast(world, Vector3(1, 0, 0), 2.0, &"J2:granada")
	assert_eq(int(combos.fired.get("deflagracion", 0)), 1)
	assert_lt(e.health, 1000.0, "el estallido daña")
	assert_false(world.stats.has(&"J2:granada"), "no cuenta para el arma")

func test_onda_aviva_las_llamas_de_otro() -> void:
	var f := _zone(WeaponData.Zone.FIRE, Vector3(2, 0, 0), &"J1:molotov")
	var r0 := f.radius
	var life0 := f.life
	Combos.wave(world, Vector3.ZERO, 4.0, &"J2:formula")
	assert_eq(int(combos.fired.get("tormenta_fuego", 0)), 1)
	assert_gt(f.radius, r0)
	assert_gt(f.life, life0)
	assert_gt(f.drift.x, 0.0, "hacia fuera")
	Combos.wave(world, Vector3.ZERO, 4.0, &"J2:formula")
	assert_eq(int(combos.fired.get("tormenta_fuego", 0)), 1, "una vez por llama")

func test_rayo_por_el_signo_de_otro_se_abre() -> void:
	Damage.ctx = &"J1:signo"
	var s := Sigil.new().setup(world, Vector3(3, 0, 0), 1.5, 4.0, 1.0, 0.4, 0.0, 1.0, {})
	world.fx.add_child(s)
	Damage.ctx = &""
	var side := _enemy(Vector3(3 + 4.0 * cos(deg_to_rad(35.0)), 0, 4.0 * sin(deg_to_rad(35.0))))
	world.rebuild_grid()
	Combos.beam(world, Vector3.ZERO, Vector3.RIGHT, 9.0, 0.4, 20.0, &"J2:trapezoedro")
	assert_eq(int(combos.fired.get("prisma", 0)), 1)
	assert_lt(side.health, 1000.0, "un rayo nuevo alcanza al de un lado")
	Combos.beam(world, Vector3(0, 0, 6), Vector3.RIGHT, 9.0, 0.4, 20.0, &"J2:trapezoedro")
	assert_eq(int(combos.fired.get("prisma", 0)), 1, "si no lo cruza, nada")

func test_electricidad_en_el_acido_salta_a_todos() -> void:
	var a := _enemy(Vector3(0.3, 0, 0))
	var b := _enemy(Vector3(-0.6, 0, 0.4))
	world.rebuild_grid()
	_zone(WeaponData.Zone.ACID, Vector3.ZERO, &"J1:lanzaquimicos")
	Combos.chain(world, a, 20.0, &"J2:tesla")
	assert_eq(int(combos.fired.get("charco_conductor", 0)), 1)
	assert_lt(b.health, 1000.0)

func test_el_invitado_no_decide() -> void:
	var guest_world := CombatWorld.new()
	add_child_autofree(guest_world)
	var g := Combos.attach(guest_world, true)
	assert_null(Combos.of(guest_world))
	g.replay(["deflagracion", Vector3.ZERO, [2.0]])
	assert_eq(int(g.fired.get("deflagracion", 0)), 1, "repite lo que se ve")
