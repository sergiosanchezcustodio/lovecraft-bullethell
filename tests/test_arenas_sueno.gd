extends GutTest
## Hito 21.9: las cinco arenas de la parte 4, Las Tierras del Sueño (el bosque y Ulthar, Dylath-Leen, Leng,
## Zin y Kadath). Que cada nivel apunte a su arena, que existan sus modelos y su mapa, que las luces propias
## ("lamps") sean de modelos que tienen dónde poner la luz y que los puntos de cada mecánica se puedan pisar.

const LEVELS := {"p4_n1": "bosque", "p4_n2": "dylath", "p4_n3": "leng", "p4_n4": "zin", "p4_n5": "kadath"}
## Puntos de la arena que usarán las mecánicas (hito 21.10): hay que poder estar en ellos.
const SPOTS := {"bosque": ["spawn", "slab"], "dylath": ["spawn", "galley"], "leng": ["spawn", "monastery_door", "village"],
	"zin": ["spawn", "koth"], "kadath": ["spawn", "gate"]}

func _layout(arena: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/%s.json" % arena))

func test_cada_nivel_tiene_su_arena_y_su_mapa() -> void:
	for id: String in LEVELS:
		var lv: LevelData = load("res://data/levels/%s.tres" % id)
		assert_eq(lv.part, 4, id)
		assert_eq(lv.number, int(id.right(1)), id)
		assert_eq(lv.arena, "res://data/arenas/%s.json" % LEVELS[id], id)
		assert_true(ResourceLoader.exists("res://resources/maps/%s.png" % id), "el mapa de %s" % id)

func test_los_modelos_existen() -> void:
	for arena: String in LEVELS.values():
		var d := _layout(arena)
		var models := {}
		for p: Dictionary in d.props: models[p.model] = true
		if d.has("barrier"):
			for m: String in d.barrier.models: models[m] = true
		for m: String in models:
			assert_true(FileAccess.file_exists("res://models/%s.json" % m), "%s: falta %s" % [arena, m])

func test_las_luces_propias_son_de_modelos_con_luz() -> void:
	for arena: String in LEVELS.values():
		var d := _layout(arena)
		for m: String in d.get("lamps", {}):
			var md: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://models/%s.json" % m))
			assert_true((md.pivots as Dictionary).has("light"), "%s: %s no tiene «light»" % [arena, m])

func test_los_puntos_de_las_mecanicas_se_pisan() -> void:
	for arena: String in SPOTS:
		var d := _layout(arena)
		var om := ObstacleMap.new()
		assert_true(om.load_mask(d.mask), arena)
		for key: String in SPOTS[arena]:
			assert_true(d.has(key), "%s: falta «%s»" % [arena, key])
			var p: Array = d[key]
			assert_false(om.is_blocked(Vector2(p[0], p[1]), 0.4), "%s: se puede estar en «%s» %s" % [arena, key, str(p)])

func test_la_meseta_toma_el_color_de_la_arena() -> void:
	var b: Dictionary = _layout("leng").barrier
	var root := ArenaBuilder._barrier(b, Vector2(64, 64))
	var plateau := root.get_node("Plateau") as MeshInstance3D
	var arrays := plateau.mesh.surface_get_arrays(0)
	var c: Color = (arrays[Mesh.ARRAY_COLOR] as PackedColorArray)[0]
	assert_almost_eq(c.r, float(b.plateau_color[0]), 0.01, "sin nieve en Leng")
	root.free()
