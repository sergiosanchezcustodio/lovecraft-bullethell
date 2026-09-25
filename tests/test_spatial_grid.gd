extends GutTest

var grid: SpatialGrid

func before_each() -> void:
	grid = SpatialGrid.new(2.0)

func test_consulta_circular_con_radios() -> void:
	var a := grid.insert(Vector2(0, 0), 0.5)
	var b := grid.insert(Vector2(3, 0), 0.5)
	var c := grid.insert(Vector2(10, 10), 0.5)
	var hits := grid.query_circle(Vector2(1.4, 0), 0.2)
	assert_eq(Array(hits), [], "a 1,4 m de a y 1,6 de b: ninguno toca con radio 0,2")
	hits = grid.query_circle(Vector2(1.0, 0), 0.6)
	assert_eq(Array(hits), [a])
	hits = grid.query_circle(Vector2(1.5, 0), 1.2)
	assert_true(a in hits and b in hits and not (c in hits))

func test_sin_repetidos_aunque_ocupe_varias_celdas() -> void:
	grid.insert(Vector2(1.9, 1.9), 1.5)          # abarca varias celdas
	assert_eq(grid.query_circle(Vector2(2, 2), 3.0).size(), 1)

func test_el_mas_cercano() -> void:
	grid.insert(Vector2(5, 0), 0.3)
	var near := grid.insert(Vector2(-2, 1), 0.3)
	grid.insert(Vector2(0, 7), 0.3)
	assert_eq(grid.nearest(Vector2.ZERO, 20.0), near)
	assert_eq(grid.nearest(Vector2.ZERO, 1.0), -1, "fuera de alcance")

func test_el_mas_cercano_coincide_con_fuerza_bruta() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var pts: Array[Vector2] = []
	for i in 200:
		var p := Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
		pts.append(p)
		grid.insert(p, 0.4)
	for k in 20:
		var q := Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
		var brute := 0
		for i in pts.size():
			if pts[i].distance_to(q) < pts[brute].distance_to(q): brute = i
		assert_eq(grid.nearest(q, 100.0), brute)

func test_zona_mas_densa() -> void:
	grid.insert(Vector2(8, 0), 0.3)                  # aislado
	var centro := grid.insert(Vector2(-6, 0), 0.3)
	for off in [Vector2(0.8, 0), Vector2(-0.8, 0), Vector2(0, 0.8), Vector2(0, -0.8)]:
		grid.insert(Vector2(-6, 0) + off, 0.3)
	assert_eq(grid.densest(Vector2.ZERO, 12.0, 1.0), centro)

func test_danio_y_su_tipo() -> void:
	assert_eq(Damage.new(10, 0).kind(), Damage.Kind.PHYSICAL)
	assert_eq(Damage.new(0, 5).kind(), Damage.Kind.MENTAL)
	assert_eq(Damage.new(4, 4).kind(), Damage.Kind.MIXED)
	var d := Damage.new(10, 6).scaled(0.5)
	assert_eq([d.physical, d.mental], [5.0, 3.0])
