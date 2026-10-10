extends GutTest
## Evento de supervivencia (hito 6.3, la horda del Arrecife): al llegar a final_time llega la
## horda a su ritmo y con su tope, y el nivel se supera al aguantar final_survive s.

const DT := 1.0 / 60.0
var world: CombatWorld
var root: Node3D
var obstacles: ObstacleMap

func before_each() -> void:
	Difficulty.forced = 0                                  # topes sin multiplicar
	world = CombatWorld.new()
	add_child_autofree(world)
	var player := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(player)
	world.add_player(player)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)

func _level() -> LevelData:
	var l := LevelData.new()
	l.pool = [load("res://data/enemies/pinguino.tres")]
	l.spawn_rate = [Vector2(0, 0.0), Vector2(300, 0.0)]          # sin oleadas: solo cuenta la horda
	l.final_time = 1.0
	l.final_survive = 2.0
	l.final_rate = 30.0
	l.final_cap = 10
	l.final_pool = [load("res://data/enemies/fragmento.tres")]
	return l

func test_la_horda_llega_con_su_tope_y_el_nivel_se_supera_al_aguantar() -> void:
	var d := WaveDirector.new().setup(_level(), world, obstacles, null, root)
	world.add_child(d)
	var done := [false]
	d.level_completed.connect(func() -> void: done[0] = true)
	for i in 50: d._physics_process(DT)
	assert_eq(d.alive.size(), 0, "antes del evento no aparece nadie")
	for i in 60: d._physics_process(DT)
	assert_eq(d.alive.size(), 10, "la horda llena hasta su tope")
	for e in d.alive: assert_eq(e.data.id, &"fragmento", "de su propio grupo")
	assert_false(done[0])
	assert_gt(d.survive_left(), 0.0)
	for i in 120: d._physics_process(DT)
	assert_true(done[0], "aguantada la horda, nivel superado")
	assert_true(d.completed)

func after_all() -> void:
	Difficulty.forced = -1
