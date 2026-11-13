extends GutTest
## Hito 20.20: Crawford Tillinghast (la Máquina del más allá revela a los enemigos y saca a los
## ocultos; cuanto más se usa seguida, más cordura quita al grupo; esquive que revela).

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

func _enemy(pos: Vector3, hp: float = 1000.0, id := "pinguino") -> Enemy:
	var d: EnemyData = (load("res://data/enemies/%s.tres" % id) as EnemyData).duplicate()
	d.max_health = hp
	var e := Enemy.new().setup(d, world, obstacles)
	e.position = pos
	root.add_child(e)
	return e

func _player(id: String, pos := Vector3.ZERO) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.world = world
	p.position = pos
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _machine(p: Player) -> WeaponSystem.Weapon:
	return p.weapons.add_weapon(load("res://data/weapons/maquina_mas_alla.tres"))

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT):
		world.clock += DT
		world.rebuild_grid()
		node._physics_process(DT)

func test_en_la_tienda_con_su_arma_y_dos_ramas() -> void:
	var c: CharacterData = load("res://data/characters/tillinghast.tres")
	assert_true(c.in_shop)
	assert_gt(c.price, 0)
	assert_gt(c.range_mult, 1.0, "ve más allá")
	assert_eq(c.dodge_style.id, &"mas_alla")
	assert_gt(c.dodge_style.reveal, 0.0)
	assert_true(FileAccess.file_exists("res://models/tillinghast.json"))
	var w: WeaponData = load("res://data/weapons/maquina_mas_alla.tres")
	assert_eq(w.delivery, WeaponData.Delivery.BEYOND)
	assert_gt(w.reveal_bonus, 0.0)
	assert_gt(w.sanity_cost, 0.0)
	assert_eq(w.evolves_with, &"valvula_maquina")
	assert_eq(w.evolution, &"lo_que_nos_rodea")
	assert_eq(w.evolution_alt, &"medusas_mas_alla")
	assert_gt((load("res://data/weapons/medusas_mas_alla.tres") as WeaponData).reveal_chain, 0.0)

func test_lo_revelado_recibe_mas_dano() -> void:
	var e := _enemy(Vector3(2, 0, 0))
	e.reveal(3.0, 0.3)
	assert_true(e.is_revealed())
	e.take_damage(Damage.new(10.0, 0.0))
	assert_almost_eq(e.health, 987.0, 0.01, "+30 %")
	e.reveal(1.0, 0.1)
	assert_almost_eq(e._reveal_k, 0.3, 0.001, "se queda con el mayor")

func test_la_onda_revela_lo_que_alcanza() -> void:
	var p := _player("tillinghast")
	var near := _enemy(Vector3(2, 0, 0))
	var far := _enemy(Vector3(12, 0, 0))
	var w := _machine(p)
	world.rebuild_grid()
	assert_true(p.weapons._beyond(w))
	var wave: Shockwave = world.fx.get_children().filter(func(n: Node) -> bool: return n is Shockwave)[0]
	_run(wave, 0.6)
	assert_true(near.is_revealed())
	assert_false(far.is_revealed())
	assert_lt(near.health, 1000.0)

func test_sin_enemigos_no_vibra_ni_cuesta() -> void:
	var p := _player("tillinghast")
	var w := _machine(p)
	var before := p.sanity
	world.rebuild_grid()
	assert_false(p.weapons._beyond(w))
	assert_eq(p.sanity, before)

func test_saca_al_excavador_enterrado() -> void:
	var e := _enemy(Vector3(2, 0, 0), 1000.0, "shoggoth_excavador")
	var b := e.behavior as BurrowBehavior
	b._bury(e, true)
	b._enter(BurrowBehavior.State.UNDER)
	var p := _player("tillinghast")
	var w := _machine(p)
	world.rebuild_grid()
	assert_true(p.weapons._beyond(w), "también vibra si solo hay ocultos")
	var wave: Shockwave = world.fx.get_children().filter(func(n: Node) -> bool: return n is Shockwave)[0]
	_run(wave, 0.6)
	assert_false(e.buried, "sale")
	assert_eq(b.state, BurrowBehavior.State.DAZED)
	assert_lt(e.health, 1000.0, "y le llega la onda")

func test_saca_al_sonambulo_de_la_bruma() -> void:
	var e := _enemy(Vector3(2, 0, 0), 1000.0, "sonambulo")
	var b := e.behavior as DreamBehavior
	b._away = 0.7
	e.buried = true
	e.visual.visible = false
	e.reveal(3.0, 0.3)
	assert_false(e.buried)
	assert_true(e.visual.visible)
	assert_almost_eq(e.position.x, 2.0, 0.001, "donde se desvaneció")

func test_cuanto_mas_seguida_mas_cordura_quita_al_grupo() -> void:
	var p := _player("tillinghast")
	var mate := _player("dyer", Vector3(4, 0, 0))
	var lone := _player("dyer", Vector3(20, 0, 0))
	_enemy(Vector3(2, 0, 0))
	var w := _machine(p)
	world.rebuild_grid()
	var cost := w.stat("sanity_cost")
	var s0 := p.sanity
	var m0 := mate.sanity
	p.weapons._beyond(w)
	assert_almost_eq(s0 - p.sanity, cost, 0.001)
	assert_almost_eq(m0 - mate.sanity, cost, 0.001, "también al compañero cercano")
	p.weapons._beyond(w)
	assert_almost_eq(s0 - p.sanity, cost * 3.0, 0.001, "el segundo pulso seguido, el doble")
	assert_eq(lone.sanity, lone.data.max_sanity, "al lejano, nada")
	world.clock += 60.0
	var s1 := p.sanity
	p.weapons._beyond(w)
	assert_almost_eq(s1 - p.sanity, cost, 0.001, "parada un rato, se enfría")

func test_las_medusas_revientan_al_morir_revelado() -> void:
	var e := _enemy(Vector3(0, 0, 0), 5.0)
	var n := _enemy(Vector3(1, 0, 0))
	world.rebuild_grid()
	e.reveal(3.0, 0.0, 20.0)
	e.take_damage(Damage.new(50.0, 0.0))
	assert_almost_eq(n.health, 980.0, 0.01)
	assert_true(n.is_revealed(), "y revela al vecino")
	assert_eq(n._reveal_chain, 0.0, "que no revienta a su vez")

func test_el_esquive_revela_a_los_de_alrededor() -> void:
	var p := _player("tillinghast")
	var e := _enemy(Vector3(1.5, 0, 0))
	world.rebuild_grid()
	p._on_dodge()
	assert_true(e.is_revealed())

func test_la_valvula_suma_al_dano_de_los_revelados() -> void:
	var cd := CharacterData.new()
	cd.reveal_add = 0.08
	var w: WeaponData = load("res://data/weapons/maquina_mas_alla.tres")
	assert_almost_eq(WeaponSystem.with_items(w, "reveal_bonus", 0.3, cd), 0.38, 0.0001)
	assert_eq(WeaponSystem.with_items(w, "reveal_bonus", 0.0, cd), 0.0, "a lo que no revela, nada")
