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

func test_las_piezas_con_colision_la_tienen() -> void:
	var sin_colision := 0
	for holder: Node in arena.get_node("Props").get_children():
		if holder.find_children("*", "StaticBody3D", false, false).is_empty(): sin_colision += 1
	assert_eq(sin_colision, 0)

func test_limites_y_aparicion_despejada() -> void:
	var walls := arena.get_node("Walls") as StaticBody3D
	assert_eq(walls.get_child_count(), 4)
	var spawn: Vector3 = arena.get_meta("spawn")
	for p: Dictionary in data.props:
		assert_gt(Vector2(p.pos[0], p.pos[1]).distance_to(Vector2(spawn.x, spawn.z)), 3.0, "pieza encima de la aparición: " + str(p))
