extends GutTest
## Economía (hito 2.13a, D-31): dólares por enemigo, baúles arcanos y guardado del dinero.

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(pos: Vector3) -> Player:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.global_position = pos
	return p

func test_cada_enemigo_vale_su_dinero() -> void:
	assert_eq((load("res://data/enemies/pinguino.tres") as EnemyData).money, 1)
	assert_eq((load("res://data/enemies/fragmento.tres") as EnemyData).money, 2)
	var elite: EnemyData = load("res://data/enemies/acechador.tres")
	assert_true(elite.elite)
	assert_eq(elite.money, 25)

func test_el_nivel_da_bono_y_baules() -> void:
	var lv: LevelData = load("res://data/levels/p1_n1.tres")
	assert_gt(lv.money_bonus, 0)
	assert_gt(lv.chest_every, 0.0)
	assert_lte(lv.chest_money.x, lv.chest_money.y)

func test_el_baul_se_abre_al_llegar_y_da_dinero_vida_y_cordura() -> void:
	var p := _player(Vector3(5, 0, 0))
	p.health = 10.0
	p.sanity = 10.0
	var c := ArcaneChest.new().setup(world, Vector3.ZERO, 40, 0.2)
	world.fx.add_child(c)
	var got := [0]
	c.opened.connect(func(ch: ArcaneChest, _by: Player) -> void: got[0] = ch.money)
	c._physics_process(DT)
	assert_false(c.is_open, "lejos: sigue cerrado")
	p.global_position = Vector3(0.5, 0, 0)
	c._physics_process(DT)
	assert_true(c.is_open)
	assert_eq(got[0], 40)
	assert_almost_eq(p.health, 10.0 + p.data.max_health * 0.2, 0.01)
	assert_almost_eq(p.sanity, 10.0 + p.data.max_sanity * 0.2, 0.01)

func test_un_derribado_no_abre_el_baul() -> void:
	var p := _player(Vector3.ZERO)
	p.health = 0.0
	var c := ArcaneChest.new().setup(world, Vector3.ZERO, 40, 0.2)
	world.fx.add_child(c)
	c._physics_process(DT)
	assert_false(c.is_open)

func test_el_director_saca_baules_con_su_ritmo_y_su_tope() -> void:
	_player(Vector3.ZERO)
	var lv: LevelData = (load("res://data/levels/p1_n1.tres") as LevelData).duplicate()
	lv.chest_every = 1.0
	lv.chest_max = 2
	lv.spawn_rate = [Vector2(0, 0.0)] as Array[Vector2]
	var root := Node3D.new()
	add_child_autofree(root)
	var d := WaveDirector.new().setup(lv, world, null, null, root)
	add_child_autofree(d)
	for i in int(6.0 / DT): d._physics_process(DT)
	var n := get_tree().get_nodes_in_group(&"chests").size()
	assert_eq(n, 2, "como mucho dos cerrados a la vez")
