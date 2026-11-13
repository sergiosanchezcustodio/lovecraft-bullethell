extends GutTest
## Hito 21.4: sucesos de la noche (NightEvents, data/night_events.json).

const RULES := ["elite_weight", "elites", "money", "xp", "enemy_speed", "marine_weight", "marine_speed", "player_speed"]

var world: CombatWorld
var root: Node3D
var obstacles: ObstacleMap
var director: WaveDirector

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)
	world.obstacles = obstacles
	var level := (load("res://data/levels/p1_n1.tres") as LevelData).duplicate()
	director = WaveDirector.new().setup(level, world, obstacles, null, root)
	world.add_child(director)

func after_each() -> void:
	NightEvents.current = {}

func _events(arena := "campamento") -> NightEvents:
	var ne := NightEvents.new().setup(null, director, world, null, null, arena, true)
	add_child_autofree(ne)
	ne.set_physics_process(false)
	return ne

func test_los_datos_estan_bien() -> void:
	var sfx: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json")) as Dictionary)["eventos"]
	assert_true(sfx.has("omen"), "el augurio")
	for e: Dictionary in NightEvents.all():
		assert_ne(String(e.get("nombre", "")), "", e.id)
		assert_ne(String(e.get("texto", "")), "", e.id)
		assert_gt(float(e.get("duracion", 0.0)), 5.0, e.id)
		if String(e.get("sonido", "")) != "": assert_true(sfx.has(String(e.sonido)), "%s: %s" % [e.id, e.sonido])
		for k: String in (e.get("efectos", {}) as Dictionary): assert_true(k in RULES, "%s: %s" % [e.id, k])
		var w := String((e.get("visual", {}) as Dictionary).get("weather", ""))
		if w != "": assert_true(ResourceLoader.exists(w), w)

func test_cada_arena_tiene_al_menos_uno() -> void:
	for f in DirAccess.open("res://data/levels").get_files():
		if not f.ends_with(".tres") or not f.begins_with("p"): continue
		var l: LevelData = load("res://data/levels/" + f)
		var arena := l.arena.get_file().get_basename()
		assert_false(NightEvents.for_arena(arena).is_empty(), "%s (%s)" % [f, arena])
	assert_false(NightEvents.for_arena("estudio").any(func(e: Dictionary) -> bool: return e.id == "luna_sangre"), "la luna no entra en el estudio")
	assert_true(NightEvents.for_arena("muelle").any(func(e: Dictionary) -> bool: return e.id == "marea"))
	assert_false(NightEvents.for_arena("calles").any(func(e: Dictionary) -> bool: return e.id == "marea"))

func test_uno_o_dos_por_nivel_en_su_momento() -> void:
	var ft := director.level.final_time
	var counts := {}
	for seed in 40:
		var ne := _events("campamento")
		ne.plan(seed)
		assert_between(ne.schedule.size(), 1, 2)
		counts[ne.schedule.size()] = true
		var ids := []
		for i in ne.schedule.size():
			var s: Array = ne.schedule[i]
			var span: Array = NightEvents.data()["primero" if i == 0 else "segundo"]
			assert_between(float(s[0]), ft * float(span[0]), ft * float(span[1]))
			assert_false(ids.has(s[1]), "dos distintos")
			ids.append(s[1])
			assert_true(NightEvents.for_arena("campamento").any(func(e: Dictionary) -> bool: return e.id == s[1]))
		ne.free()
	assert_eq(counts.size(), 2, "a veces uno y a veces dos")
	var same := _events()
	same.plan(7)
	var again := _events()
	again.plan(7)
	assert_eq(same.schedule, again.schedule, "la misma semilla, los mismos sucesos")

func test_las_reglas_duran_lo_que_el_suceso() -> void:
	var ne := _events()
	ne.plan(0, "luna_sangre", 1.0)
	assert_eq(NightEvents.value("money"), 1.0)
	director.time = 1.5
	ne.step(0.1)
	assert_eq(NightEvents.value("money"), 2.0, "el doble de dólares")
	var elite := EnemyData.new()
	elite.tier = 4
	var common := EnemyData.new()
	common.tier = 1
	assert_eq(NightEvents.weight_of(common), 1.0)
	assert_eq(NightEvents.weight_of(elite), 3.0, "élites, más a menudo")
	assert_eq(NightEvents.value("elites"), 2.0, "y el doble a la vez")
	for i in 40: ne.step(1.0)
	assert_true(NightEvents.current.is_empty(), "acaba a los 30 s")
	assert_eq(NightEvents.value("money"), 1.0)

func test_la_marea_y_la_ventisca_cambian_la_rapidez() -> void:
	var marine := EnemyData.new()
	marine.tags = [&"marina"] as Array[StringName]
	var other := EnemyData.new()
	var ne := _events("muelle")
	ne.start("marea")
	assert_almost_eq(NightEvents.speed_of(marine), 1.2, 0.001)
	assert_eq(NightEvents.speed_of(other), 1.0)
	assert_eq(NightEvents.weight_of(marine), 4.0)
	ne.stop()
	ne.start("ventisca")
	assert_almost_eq(NightEvents.speed_of(other), 0.75, 0.001)
	ne.stop()
	assert_eq(NightEvents.speed_of(other), 1.0)

func test_la_ventisca_frena_a_los_investigadores() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	var speed := p.data.move_speed
	var ne := _events()
	ne.start("ventisca")
	assert_almost_eq(p.data.move_speed, speed * 0.88, 0.001)
	ne.stop()
	assert_almost_eq(p.data.move_speed, speed, 0.001)

func test_el_silencio_y_luego_la_horda() -> void:
	var ne := _events()
	ne.start("silencio")
	assert_true(director.spawning_paused, "nadie aparece")
	var before := director.alive.size()
	for i in 9: ne.step(1.0)
	assert_true(director.spawning_paused)
	ne.step(1.1)
	assert_false(director.spawning_paused, "a los 10 s, vuelven")
	assert_gt(director.alive.size(), before + 8, "y llega una horda")
	for i in 10: ne.step(1.0)
	assert_true(NightEvents.current.is_empty())

func test_no_empieza_con_el_evento_final() -> void:
	var ne := _events()
	ne.plan(0, "niebla", 1.0)
	director._final_done = true
	director.time = 2.0
	ne.step(0.1)
	assert_true(NightEvents.current.is_empty())

func test_la_lluvia_de_estrellas_deja_gemas() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	var ne := _events()
	ne.start("estrellas")
	var before := world.fx.get_child_count()
	ne.step(0.01)
	assert_gt(world.fx.get_child_count(), before, "cae una estrella")
