extends GutTest
## Hito 20.21: Edward Derby y Asenath Waite (dos cuerpos que se cambian en cada esquive: Edward
## golpea de cerca y Asenath mira de lejos; El umbral cambia con ellos).

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

func _player(pos := Vector3.ZERO) -> Player:
	var p := Player.new().setup(load("res://data/characters/derby.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.world = world
	p.position = pos
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _waves() -> Array:
	return world.fx.get_children().filter(func(n: Node) -> bool: return n is Shockwave)

func _run(node: Node, seconds: float) -> void:
	for i in int(seconds / DT):
		world.clock += DT
		world.rebuild_grid()
		node._physics_process(DT)

func test_en_la_tienda_con_dos_cuerpos_y_dos_ramas() -> void:
	var c: CharacterData = load("res://data/characters/derby.tres")
	assert_true(c.in_shop)
	assert_gt(c.price, 0)
	assert_eq(c.alt_model, "asenath")
	assert_gt(c.swap_restore, 0.0)
	assert_eq(c.dodge_style.id, &"umbral")
	assert_true(c.dodge_style.swap)
	assert_true(FileAccess.file_exists("res://models/derby.json"))
	assert_true(FileAccess.file_exists("res://models/asenath.json"))
	var w: WeaponData = load("res://data/weapons/el_umbral.tres")
	assert_eq(w.delivery, WeaponData.Delivery.THRESHOLD)
	assert_eq(w.evolves_with, &"aldaba_derby")
	assert_eq(w.evolution, &"lo_que_llamo")
	assert_eq(w.evolution_alt, &"ojos_de_ephraim")
	assert_gt((load("res://data/weapons/lo_que_llamo.tres") as WeaponData).swap_blast, 0.0)

func test_el_esquive_cambia_de_cuerpo_y_vuelve() -> void:
	var p := _player()
	var edward := p.model
	assert_eq(p.form, 0)
	assert_eq(p.model_name, "derby")
	p._on_dodge()
	assert_eq(p.form, 1, "la forma cambia al momento")
	assert_eq(p.model, edward, "el modelo, escondido en el destello")
	p._swap_model()
	assert_eq(p.model_name, "asenath")
	assert_ne(p.model, edward)
	assert_eq(p.model.get_parent(), p.visual)
	assert_null(edward.get_parent(), "el otro cuerpo, guardado fuera")
	var asenath := p.model
	p._on_dodge()
	p._swap_model()
	assert_eq(p.form, 0)
	assert_eq(p.model, edward, "vuelve el mismo Edward")
	p._on_dodge()
	p._swap_model()
	assert_eq(p.model, asenath, "y la misma Asenath: no se construye otra vez")

func test_edward_golpea_de_cerca_sin_balas() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/el_umbral.tres"))
	var near := _enemy(Vector3(1.5, 0, 0))
	var before := p.sanity
	world.rebuild_grid()
	assert_true(p.weapons._fire(w))
	assert_lt(near.health, 1000.0)
	assert_eq(world.bullets.count, 0, "Edward no dispara")
	assert_eq(p.sanity, before, "ni le cuesta cordura")

func test_asenath_mira_de_lejos_y_le_cuesta_cordura() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/el_umbral.tres"))
	var far := _enemy(Vector3(6, 0, 0))
	p.swap_form()
	var before := p.sanity
	world.rebuild_grid()
	assert_true(p.weapons._fire(w))
	assert_eq(world.bullets.count, int(w.stat("count")), "dos miradas")
	assert_lt(p.sanity, before)
	assert_eq(far.health, 1000.0, "aún no ha llegado")

func test_asenath_espera_a_tener_a_quien_mirar() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/el_umbral.tres"))
	p.swap_form()
	world.rebuild_grid()
	assert_false(p.weapons._fire(w))
	assert_eq(world.bullets.count, 0)

func test_el_dano_es_fisico_de_cerca_y_magico_de_lejos() -> void:
	var p := _player()
	var w := p.weapons.add_weapon(load("res://data/weapons/el_umbral.tres"))
	p.data.melee_mult = 1.5
	var base := w.stat("damage")
	assert_almost_eq(p.weapons.dmg(w, false), base * p.damage_mult(WeaponData.Category.PHYSICAL) * 1.5, 0.001,
		"Edward: físico y cuerpo a cuerpo")
	p.swap_form()
	assert_almost_eq(p.weapons.dmg(w, false), base * p.damage_mult(WeaponData.Category.MAGIC), 0.001,
		"Asenath: mágico, sin el cuerpo a cuerpo")

func test_cada_cambio_devuelve_vida_y_cordura() -> void:
	var p := _player()
	p.health = 50.0
	p.sanity = 40.0
	p.swap_form()
	assert_almost_eq(p.health, 53.0, 0.001)
	assert_almost_eq(p.sanity, 43.0, 0.001)
	p.health = p.data.max_health
	p.swap_form()
	assert_eq(p.health, p.data.max_health, "sin pasarse del máximo")

func test_lo_que_llamo_suelta_una_onda_al_cambiar() -> void:
	var p := _player()
	p.weapons.add_weapon(load("res://data/weapons/el_umbral.tres"))
	p.swap_form()
	assert_eq(_waves().size(), 0, "sin la rama, no hay onda")
	var q := _player(Vector3(20, 0, 0))
	q.weapons.add_weapon(load("res://data/weapons/lo_que_llamo.tres"))
	var e := _enemy(Vector3(22, 0, 0))
	world.rebuild_grid()
	q.swap_form()
	var waves := _waves()
	assert_eq(waves.size(), 1)
	_run(waves[0], 0.5)
	assert_lt(e.health, 1000.0)

func test_la_aldaba_pega_mas_al_ileso() -> void:
	var e := _enemy(Vector3(3, 0, 0))
	var d := Damage.new(10.0, 0.0)
	d.bonus = {Player.FRESH_TAG: 1.12}
	e.take_damage(d)
	assert_almost_eq(e.health, 1000.0 - 11.2, 0.001, "el primer golpe, un 12 % más")
	var d2 := Damage.new(10.0, 0.0)
	d2.bonus = {Player.FRESH_TAG: 1.12}
	e.take_damage(d2)
	assert_almost_eq(e.health, 1000.0 - 21.2, 0.001, "el segundo, normal")

func test_en_red_el_otro_pc_ve_el_cambio() -> void:
	var p := _player()
	p.swap_form()
	assert_true((p.net_flags() & Player.NET_FORM) != 0)
	var q := _player(Vector3(5, 0, 0))
	q.net_apply(Vector3(5, 0, 0), 0.0, Vector3.ZERO, 0, q.health, q.sanity, Player.NET_FORM)
	assert_eq(q.form, 1)
	q._swap_model()
	assert_eq(q.model_name, "asenath")
	q.net_apply(Vector3(5, 0, 0), 0.0, Vector3.ZERO, 0, q.health, q.sanity, 0)
	assert_eq(q.form, 0)
