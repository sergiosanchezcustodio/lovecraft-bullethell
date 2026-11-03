extends GutTest
## Hito 16.32: haces de luna.

func _arena(size := Vector2(48, 48)) -> Node3D:
	var a := Node3D.new()
	a.set_meta("size", size)
	a.set_meta("light", {"sun_rot": [-70, 160]})
	var props := Node3D.new()
	props.name = "Props"
	a.add_child(props)
	add_child_autofree(a)
	return a

func _wall(a: Node3D, model: String, pos: Vector3, rot: float) -> void:
	var h := Node3D.new()
	h.position = pos
	h.rotation_degrees.y = rot
	var m := Node3D.new()
	m.name = model
	h.add_child(m)
	a.get_node("Props").add_child(h)

func test_forma_del_ventanal() -> void:
	var W := MoonShafts.SHAPE_WINDOW
	assert_eq(MoonShafts.mask(W, true, 0.0, 0.25, 0.3), 1.0, "un cristal")
	assert_eq(MoonShafts.mask(W, true, 0.0, 0.5, 0.3), 0.0, "el parteluz")
	assert_eq(MoonShafts.mask(W, false, 0.0, 0.5, 0.3), 1.0, "sin parteluz")
	assert_eq(MoonShafts.mask(W, true, 0.0, 0.05, 0.98), 0.0, "fuera del arco")
	assert_eq(MoonShafts.mask(W, true, 0.0, 1.2, 0.5), 0.0)
	var G := MoonShafts.SHAPE_GAP
	assert_eq(MoonShafts.mask(G, false, 1.0, 0.5, 0.5), 1.0, "el centro de la grieta")
	assert_eq(MoonShafts.mask(G, false, 1.0, 0.0, 0.0), 0.0, "la esquina")

func test_ventanales_del_estudio() -> void:
	var a := _arena()
	_wall(a, "prv_muro", Vector3(-24, 0, -6), 90.0)     # pared oeste: la luz entra
	_wall(a, "prv_muro", Vector3(-6, 0, -24), 0.0)      # pared norte: le llega rasante, no
	var sh := MoonShafts.plan(a, "estudio")
	assert_eq(sh.size(), 2, "los dos ventanales elegidos de la pared oeste")
	for s in sh:
		assert_almost_eq(s.w0.x, -24.0, 0.01, "la abertura, en la cara de la pared")
		var f := s.landing()
		assert_gt(f.x, -24.0, "cae dentro del estudio")
		assert_almost_eq(f.y, 0.0, 0.001, "en el suelo")
		var c := s.corners()
		for i in range(4, 8): assert_almost_eq(c[i].y, 0.0, 0.001)
		# del mundo a (a, b, t) y vuelta: el centro de la abertura es (0,5, 0,5, 0)
		var l := s.to_local() * s.center()
		assert_almost_eq(l, Vector3(0.5, 0.5, 0.0), Vector3.ONE * 0.001)

func test_grietas_de_los_tuneles() -> void:
	var a := _arena(Vector2(64, 64))
	var sh := MoonShafts.plan(a, "tuneles")
	var gaps: Array = MoonShafts.config().tuneles.gaps
	assert_eq(sh.size(), gaps.size())
	for i in sh.size():
		var f := sh[i].landing()
		assert_almost_eq(Vector2(f.x, f.z), Vector2(gaps[i].at[0], gaps[i].at[1]), Vector2.ONE * 0.01, "cae donde dice")
		assert_almost_eq(sh[i].center().y, float(MoonShafts.config().tuneles.height), 0.01)
		assert_lt(sh[i].d.y, -0.5, "la luna de la arena, de arriba")

func test_arenas_y_calidad() -> void:
	assert_true(MoonShafts.has_shafts("estudio"))
	assert_false(MoonShafts.has_shafts("calles"))
	var on := Quality.presets().map(func(p: Dictionary) -> bool: return bool(p.get("moon_shafts", false)))
	assert_eq(on, [false, false, true, true], "solo en Alta y Ultra")

func test_se_monta() -> void:
	var a := _arena(Vector2(64, 64))
	var m := MoonShafts.new().setup(a, "tuneles")
	a.add_child(m)
	assert_eq(m.shafts.size(), 6)
	for s in m.shafts:
		assert_not_null(s.light.light_projector, "el foco dibuja la grieta")
		assert_true(s.light.shadow_enabled, "sin sombras no sale el proyector")
