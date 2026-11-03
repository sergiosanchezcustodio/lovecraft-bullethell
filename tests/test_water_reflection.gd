extends GutTest
## Hito 16.31: reflejos en el agua.

func test_camara_espejo() -> void:
	var t := Transform3D.IDENTITY
	t.basis = Basis.from_euler(Vector3(deg_to_rad(-30), deg_to_rad(45), 0))
	t.origin = Vector3(3, 20, 5)
	var m := WaterReflection.mirrored(t)
	assert_almost_eq(m.origin.y, -20.0, 0.001, "debajo del suelo")
	assert_almost_eq(m.basis.determinant(), 1.0, 0.001, "un giro de verdad, no una simetría")
	var f := -t.basis.z
	var fm := -m.basis.z
	assert_almost_eq(fm.y, -f.y, 0.001, "mira hacia arriba lo que la otra hacia abajo")
	assert_almost_eq(Vector2(fm.x, fm.z).distance_to(Vector2(f.x, f.z)), 0.0, 0.001)
	# el punto del suelo en el centro de la vista es el mismo para las dos cámaras
	var g := t.origin + f * (-t.origin.y / f.y)
	var gm := m.origin + fm * (-m.origin.y / fm.y)
	assert_almost_eq(g.distance_to(gm), 0.0, 0.001)

func test_agua() -> void:
	var a := Node3D.new()
	add_child_autofree(a)
	assert_false(WaterReflection.has_water(a))
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	a.add_child(sea)
	assert_true(WaterReflection.has_water(a))

func test_calidad() -> void:
	var on := Quality.presets().map(func(p: Dictionary) -> bool: return bool(p.get("reflections", false)))
	assert_eq(on, [false, false, true, true], "solo en Alta y Ultra")
