extends GutTest
## Eventos intermedios (hito 6.5): minijefes a mitad de nivel, una sola vez, con aviso; las
## oleadas siguen y el nivel no se supera al matarlos (solo con el evento final).

const DT := 1.0 / 60.0
var world: CombatWorld
var root: Node3D
var obstacles: ObstacleMap

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	var player := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(player)
	world.add_player(player)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)

func test_el_minijefe_sale_una_vez_a_su_hora_y_no_acaba_el_nivel() -> void:
	var l := LevelData.new()
	l.number = 5
	l.pool = [load("res://data/enemies/pinguino.tres")]
	l.spawn_rate = [Vector2(0, 0.0), Vector2(300, 0.0)]
	l.mid_enemies = [load("res://data/enemies/fragmento.tres")]
	l.mid_times = [1.0]
	l.mid_texts = ["¡Ahí viene!"]
	l.final_time = 999.0
	var d := WaveDirector.new().setup(l, world, obstacles, null, root)
	world.add_child(d)
	var events: Array[String] = []
	d.mid_event.connect(func(_e: Enemy, text: String) -> void: events.append(text))
	var done := [false]
	d.level_completed.connect(func() -> void: done[0] = true)
	for i in 50: d._physics_process(DT)
	assert_eq(d.alive.size(), 0, "aún no")
	for i in 30: d._physics_process(DT)
	assert_eq(events, ["¡Ahí viene!"] as Array[String], "una vez, con su texto")
	assert_eq(d.mid_alive.size(), 1)
	for i in 120: d._physics_process(DT)
	assert_eq(events.size(), 1, "no se repite")
	var e: Enemy = d.mid_alive[0]
	e.take_damage(Damage.new(99999.0, 0.0))
	assert_eq(d.mid_alive.size(), 0, "muerto, deja de ser el objetivo")
	assert_false(done[0], "matarlo no supera el nivel")

func test_tras_el_final_sale_el_jefe_y_el_nivel_se_supera_al_matarlo_a_el() -> void:
	var l := LevelData.new()
	l.number = 5
	l.pool = [load("res://data/enemies/pinguino.tres")]
	l.spawn_rate = [Vector2(0, 0.0), Vector2(300, 0.0)]
	l.final_time = 0.5
	l.final_wave = 0
	l.final_enemy = load("res://data/enemies/fragmento.tres")
	l.final_next = load("res://data/enemies/pinguino.tres")
	l.final_next_text = "¡El jefe!"
	var d := WaveDirector.new().setup(l, world, obstacles, null, root)
	world.add_child(d)
	var boss := []
	d.boss_event.connect(func(e: Enemy, text: String) -> void: boss.append(text))
	var done := [false]
	d.level_completed.connect(func() -> void: done[0] = true)
	for i in 40: d._physics_process(DT)
	var first := d.final_target()
	assert_eq(first.data.id, &"fragmento")
	first.take_damage(Damage.new(99999.0, 0.0))
	assert_false(done[0], "muerto el final, aún queda el jefe")
	assert_eq(boss, ["¡El jefe!"])
	assert_eq(d.final_target().data.id, &"pinguino")
	d.final_target().take_damage(Damage.new(99999.0, 0.0))
	assert_true(done[0], "muerto el jefe, nivel superado")
