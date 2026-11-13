extends GutTest
## Combinaciones (hito 13.7): cuáles salen, entre jugadores distintos o entre armas distintas de
## uno (21.6), y las seis de la fase 20.

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

func test_las_armas_de_un_mismo_jugador_se_combinan() -> void:
	_zone(WeaponData.Zone.ACID, Vector3.ZERO, &"J1:lanzaquimicos")
	_zone(WeaponData.Zone.FIRE, Vector3(1, 0, 0), &"J1:molotov")
	assert_eq(int(combos.fired.get("nube_toxica", 0)), 1, "armas distintas de J1: sí (21.6)")

func test_una_misma_arma_no_se_combina_consigo() -> void:
	_zone(WeaponData.Zone.GAS, Vector3.ZERO, &"J1:granada")
	Combos.blast(world, Vector3(1, 0, 0), 2.0, &"J1:granada")
	assert_true(combos.fired.is_empty())
	combos.solo = true
	Combos.blast(world, Vector3(1, 0, 0), 2.0, &"J1:granada")
	assert_eq(int(combos.fired.get("deflagracion", 0)), 1, "con combos_solo, sí")

func test_lo_que_deja_una_combinacion_no_se_vuelve_a_combinar() -> void:
	assert_false(combos._pair_t(&"J1:combo", &"J2:molotov"))
	assert_true(combos._pair_t(&"J1:molotov", &"J2:molotov"))
	assert_eq(Combos.weapon_of(&"J3:formula"), "formula")

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
	assert_true(world.stats.has(&"J2:combo"), "sino en la fila Combinaciones de quien la provoca (21.6)")

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

# ---------------------------------------------------------------- las de la fase 20 (hito 21.6)

func _canvas(pos: Vector3, tag := &"J1:lienzo") -> Canvas:
	Damage.ctx = tag
	var c := Canvas.new().setup(world, pos, Vector3.FORWARD, 6.0, 4.5, 10.0, 5.0, 0.4, 1.0, {})
	world.fx.add_child(c)
	Damage.ctx = &""
	return c

func _dream(pos: Vector3, tag := &"J1:sueno") -> DreamZone:
	Damage.ctx = tag
	var z := DreamZone.new().setup(world, pos, 2.6, 4.0, 0.0, 0.5, 0.45, 0.6, 0.0, {})
	world.fx.add_child(z)
	Damage.ctx = &""
	return z

func _ghouls() -> Array:
	return world.fx.get_children().filter(func(n: Node) -> bool: return n is Reanimated)

func test_pesadilla_el_rayo_despierta_a_los_que_suenan() -> void:
	var e := _enemy(Vector3(3, 0, 1.5))
	world.rebuild_grid()
	var z := _dream(Vector3(3, 0, 0))
	e.dream(3.0)
	e.stun(3.0)
	Combos.beam(world, Vector3.ZERO, Vector3.RIGHT, 9.0, 0.4, 20.0, &"J1:rayo")
	assert_eq(int(combos.fired.get("pesadilla", 0)), 1)
	assert_almost_eq(e.health, 1000.0 - 40.0, 0.5, "el doble del rayo, aunque no lo toque")
	assert_false(e.is_dreaming(), "despierta")
	assert_false(z.ending(), "el sueño sigue")
	Combos.beam(world, Vector3.ZERO, Vector3.RIGHT, 9.0, 0.4, 20.0, &"J1:rayo")
	assert_eq(int(combos.fired.get("pesadilla", 0)), 1, "una vez por sueño")
	assert_true(world.stats.has(&"J1:combo"))

func test_un_sueno_vacio_no_se_combina() -> void:
	world.rebuild_grid()
	_dream(Vector3(3, 0, 0))
	Combos.beam(world, Vector3.ZERO, Vector3.RIGHT, 9.0, 0.4, 20.0, &"J1:rayo")
	assert_false(combos.fired.has("pesadilla"), "sin nadie dentro, nada")

func test_pesadilla_tambien_con_la_electricidad() -> void:
	var e := _enemy(Vector3(0.5, 0, 0))
	world.rebuild_grid()
	_dream(Vector3.ZERO, &"J2:sueno")
	Combos.chain(world, e, 10.0, &"J1:tesla")
	assert_eq(int(combos.fired.get("pesadilla", 0)), 1)

func test_ceniza_azul_las_sales_abren_el_lienzo() -> void:
	var cv := _canvas(Vector3(1, 0, 0), &"J1:lienzo")
	var life := cv.ally_life
	Damage.ctx = &"J2:sales"
	var sc := SaltCircle.new().setup(world, Vector3.ZERO, 2.8, 10.0, 2, 4.0, 0.4, 0.0, {})
	world.fx.add_child(sc)
	Damage.ctx = &""
	sc._formula()
	assert_eq(int(combos.fired.get("ceniza_azul", 0)), 1)
	assert_true(cv.broken, "el cuadro se abre")
	assert_almost_eq(cv.ally_life, life * 1.6, 0.01, "y sus necrófagos duran más")
	var g := _ghouls()
	assert_eq(g.size(), 1)
	assert_eq((g[0] as Reanimated).look, "ward", "de ceniza azul")

func test_lienzo_rasgado_por_un_tajo() -> void:
	var cv := _canvas(Vector3(1, 0, 0), &"J1:lienzo")
	Combos.slash(world, Vector3.ZERO, 1.6, &"J1:machete")
	assert_eq(int(combos.fired.get("lienzo_rasgado", 0)), 1, "con tus propias armas")
	assert_true(cv.broken)
	assert_almost_eq(cv.power, 2.0, 0.01)
	assert_eq((_ghouls()[0] as Reanimated).look, "pickman")
	var far := _canvas(Vector3(6, 0, 0))
	Combos.slash(world, Vector3.ZERO, 1.6, &"J1:machete")
	assert_false(far.broken, "lejos, nada")

func test_oleo_ardiente_el_fuego_quema_el_lienzo() -> void:
	var cv := _canvas(Vector3(1, 0, 0), &"J1:lienzo")
	_zone(WeaponData.Zone.FIRE, Vector3.ZERO, &"J2:molotov")
	assert_eq(int(combos.fired.get("oleo_ardiente", 0)), 1)
	assert_true(cv.broken)
	var fires := get_tree().get_nodes_in_group(&"combo_zones").filter(func(n: Node) -> bool:
		return (n as DamageZone).kind == WeaponData.Zone.FIRE and n.has_meta("combo_used") and (n as DamageZone).radius > 2.0)
	assert_eq(fires.size(), 1, "un charco de fuego grande")

func test_vision_la_maquina_duerme_a_los_del_sueno() -> void:
	var e := _enemy(Vector3(0.5, 0, 0))
	world.rebuild_grid()
	var z := _dream(Vector3.ZERO, &"J2:sueno")
	var life := z.life
	Combos.wave(world, Vector3(2, 0, 0), 3.0, &"J1:maquina", false)
	assert_false(combos.fired.has("vision"), "una onda cualquiera, no")
	Combos.wave(world, Vector3(2, 0, 0), 3.0, &"J1:maquina", true)
	assert_eq(int(combos.fired.get("vision", 0)), 1)
	assert_true(e.is_dreaming())
	assert_gt(z.life, life, "el sueño dura más")

func test_esquirlas_angulares_el_angulo_que_cruza_un_signo() -> void:
	Damage.ctx = &"J2:signo"
	var s := Sigil.new().setup(world, Vector3(2, 0, 0), 1.5, 4.0, 1.0, 0.4, 0.0, 1.0, {})
	world.fx.add_child(s)
	Damage.ctx = &"J1:angulos"
	var bm := world.bullets
	bm.spawn(BulletManager.Team.PLAYER, BulletManager.Style.ANGLE, Vector3(0, 0, 0), Vector3(8, 0, 0), 0.16, 0.45,
		Damage.new(10.0, 0.0), 2.0, 0, 0.5, -1, 0, -0.3)
	Damage.ctx = &""
	combos._physics_process(0.016)
	assert_true(bm.angle_hook.is_valid(), "con un signo, los ángulos miran")
	for i in 20: bm._physics_process(1.0 / 60.0)
	assert_eq(int(combos.fired.get("esquirlas_angulares", 0)), 1)
	assert_eq(bm.count, 6, "la bala se abre en seis esquirlas")
	bm.clear()
	Damage.ctx = &"J1:angulos"
	bm.spawn(BulletManager.Team.PLAYER, BulletManager.Style.ANGLE, Vector3(2, 0, 0), Vector3(8, 0, 0), 0.16, 0.45,
		Damage.new(10.0, 0.0), 0.1, 0, 0.5, -1, 0, -0.3)
	Damage.ctx = &""
	combos.cfg.cooldown = 0.0
	for i in 3: bm._physics_process(1.0 / 60.0)
	assert_eq(int(combos.fired.get("esquirlas_angulares", 0)), 1, "la que sale de dentro (el signo bajo Gilman), no")
	s.queue_free()
	await get_tree().process_frame
	combos._physics_process(0.016)
	assert_false(bm.angle_hook.is_valid(), "sin signos, nada que mirar")
