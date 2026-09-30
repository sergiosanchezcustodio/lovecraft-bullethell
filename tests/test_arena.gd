extends GutTest

const PATH := "res://data/arenas/campamento.json"
var arena: Node3D
var data: Dictionary

func before_all() -> void:
	arena = ArenaBuilder.build(PATH)
	data = JSON.parse_string(FileAccess.get_file_as_string(PATH))

func after_all() -> void:
	arena.free()

func test_monta_todas_las_piezas() -> void:
	assert_eq(arena.get_node("Props").get_child_count(), data.props.size())

func test_un_farol_una_luz() -> void:
	var faroles: int = data.props.filter(func(p: Dictionary) -> bool: return p.model == "atrezo_farol").size()
	var lights: Array = arena.get_meta("lights")
	assert_eq(lights.size(), faroles)
	assert_gt(faroles, 0)

func test_las_piezas_con_colision_bloquean_el_paso() -> void:
	# con el mapa de lo transitable, el centro de cada pieza sólida del campamento está bloqueado
	var obs: ObstacleMap = arena.get_meta("obstacles")
	assert_true(obs.has_mask())
	var half: Vector2 = arena.get_meta("size") * 0.5
	var libres := []
	for p: Dictionary in data.props:
		if absf(p.pos[0]) >= half.x - 0.01 or absf(p.pos[1]) >= half.y - 0.01: continue
		if data.colliders.get(p.model, {}).get("type", "none") == "none": continue
		if p.model in ["atrezo_farol", "atrezo_bandera", "atrezo_tripode"]: continue    # finos: el centro puede quedar entre celdas
		if not obs.is_blocked(Vector2(p.pos[0], p.pos[1]), 0.1): libres.append(p.model)
	assert_eq(libres, [])

func test_limites_y_aparicion_despejada() -> void:
	var obs: ObstacleMap = arena.get_meta("obstacles")
	var spawn: Vector3 = arena.get_meta("spawn")
	assert_false(obs.is_blocked(Vector2(spawn.x, spawn.z), 1.0), "la salida está despejada")
	assert_true(obs.is_blocked(Vector2(0, 40), 0.3), "el mar, al sur, no es transitable")
	assert_true(obs.is_blocked(Vector2(0, -40), 0.3), "detrás de los acantilados, tampoco")
	assert_false(arena.has_node("Walls"), "sin muros invisibles: los límites salen del mapa")
	# se llega más allá del antiguo cuadrado de 32 m hacia los acantilados (norte)
	assert_false(obs.is_blocked(Vector2(0, -33.5), 0.3))
	for p: Dictionary in data.props:
		assert_gt(Vector2(p.pos[0], p.pos[1]).distance_to(Vector2(spawn.x, spawn.z)), 3.0, "pieza encima de la aparición: " + str(p))

func test_las_balas_se_paran_en_la_cabana() -> void:
	var obs: ObstacleMap = arena.get_meta("obstacles")
	for p: Dictionary in data.props:
		if p.model == "atrezo_cabana": assert_true(obs.stops_bullet(Vector2(p.pos[0], p.pos[1])))
		if p.model == "atrezo_iglu": assert_true(obs.stops_bullet(Vector2(p.pos[0], p.pos[1]) + Vector2(1.6, 0)))
