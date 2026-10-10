extends GutTest
## Agua somera del pantano (hito 6.4): la capa "water" del mapa de la arena frena a los
## jugadores y a los enemigos que no nadan; los que tienen `emerge` salen del agua cerca de
## los jugadores, y los que se zambullen reaparecen en otra poza.

const DT := 1.0 / 60.0
var obstacles: ObstacleMap
var wet := Vector2.INF
var dry := Vector2.INF

func before_each() -> void:
	Difficulty.forced = 0                                  # topes sin multiplicar
	obstacles = ObstacleMap.new()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/pantano.json"))
	assert_true(obstacles.load_mask(data.mask), "carga el mapa del pantano")
	# un punto con agua y otro seco (el terraplén, en la diagonal), los dos libres
	for i in range(-25, 25):
		var p := Vector2(i, -i * 0.3 - 8.0)
		if wet == Vector2.INF and obstacles.water_at(p) > 0.5 and not obstacles.is_blocked(p, 0.6): wet = p
	for i in range(-20, 20):
		var p := Vector2(i, i) + Vector2(0.3, 0.3)
		if dry == Vector2.INF and obstacles.water_at(p) == 0.0 and not obstacles.is_blocked(p, 0.6): dry = p

func test_el_pantano_tiene_agua_y_el_terraplen_esta_seco() -> void:
	assert_true(obstacles.has_water())
	assert_ne(wet, Vector2.INF, "hay agua")
	assert_ne(dry, Vector2.INF, "el terraplén está seco")
	assert_not_null(obstacles.water_texture(), "y el suelo puede dibujarla")

func test_las_demas_arenas_no_tienen_agua() -> void:
	var o := ObstacleMap.new()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/carretera.json"))
	o.load_mask(data.mask)
	assert_false(o.has_water())
	assert_eq(o.water_at(Vector2.ZERO), 0.0)

func test_punto_de_agua_al_azar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 10:
		var p := obstacles.random_water(rng, dry, 3.0, 12.0)
		if p == Vector2.INF: continue
		assert_gt(obstacles.water_at(p), 0.5)
		assert_between(p.distance_to(dry), 3.0, 12.0)

func _enemy(path: String, at: Vector2) -> Enemy:
	var world := CombatWorld.new()
	add_child_autofree(world)
	world.obstacles = obstacles
	var e := Enemy.new().setup(load(path), world, obstacles)
	e.position = Vector3(at.x, 0, at.y)
	world.add_child(e)
	return e

func test_los_que_no_nadan_vadean_y_los_profundos_no() -> void:
	assert_true(_enemy("res://data/enemies/hibrido_h.tres", wet).wades(), "el híbrido vadea")
	assert_false(_enemy("res://data/enemies/hibrido_h.tres", dry).wades(), "en seco, no")
	assert_false(_enemy("res://data/enemies/profundo.tres", wet).wades(), "el Profundo nada")
	assert_false(_enemy("res://data/enemies/profundo_anciano.tres", wet).wades())

func test_el_jugador_va_mas_lento_en_el_agua_pero_no_al_esquivar() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	world.obstacles = obstacles
	var speeds := {}
	for where in [dry, wet]:
		var input := BotInput.new("right")
		var p := Player.new().setup(load("res://data/characters/dyer.tres"), input, Color.YELLOW)
		p.world = world
		world.add_child(p)
		world.add_player(p)
		for i in 20:                                           # siempre en el mismo sitio: solo cuenta dónde pisa
			p.position = Vector3(where.x, 0, where.y)
			p._physics_process(DT)
		speeds[where] = p.velocity.length()
		world.players.erase(p)
	assert_gt(speeds[dry], 0.5)
	assert_almost_eq(speeds[wet], speeds[dry] * WadeSplash.SLOW, 0.05, "en el agua, ×%.1f" % WadeSplash.SLOW)

func test_los_que_emergen_salen_del_agua_cerca_de_un_jugador() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	world.obstacles = obstacles
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.position = Vector3(dry.x, 0, dry.y)
	var root := Node3D.new()
	world.add_child(root)
	var l := LevelData.new()
	l.number = 5                                                   # escalones que pueden aparecer
	l.pool = [load("res://data/enemies/profundo_emergente.tres")]
	l.spawn_rate = [Vector2(0, 30.0), Vector2(300, 30.0)]
	l.max_alive = 3
	var d := WaveDirector.new().setup(l, world, obstacles, null, root)
	world.add_child(d)
	var born: Array[Vector2] = []
	d.enemy_spawned.connect(func(e: Enemy) -> void: born.append(Vector2(e.position.x, e.position.z)))
	for i in 10: d._physics_process(DT)
	assert_eq(d.alive.size(), 0, "primero, el aviso")
	assert_eq(d._emerging, 3, "cuentan para el tope mientras salen")
	await wait_seconds(WaveDirector.EMERGE_WARN + 0.3)
	assert_eq(d.alive.size(), 3, "y salen")
	for at in born:
		assert_gt(obstacles.water_at(at), 0.5, "en el agua")
		assert_between(at.distance_to(dry), 4.9, 9.1, "a 5-9 m del jugador")

func after_all() -> void:
	Difficulty.forced = -1
