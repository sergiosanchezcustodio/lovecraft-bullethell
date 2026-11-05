extends GutTest
## Hito 16.34: decorado que se rompe con las explosiones.

func _arena(models: Array) -> Node3D:
	var a := Node3D.new()
	a.set_meta("size", Vector2(40, 40))
	var obs := ObstacleMap.new()
	a.set_meta("obstacles", obs)
	var props := Node3D.new()
	props.name = "Props"
	a.add_child(props)
	for it: Array in models:
		var h := Node3D.new()
		h.position = it[1]
		var m := VoxelBuilder.load_model("res://models/%s.json" % it[0])
		h.add_child(m)
		props.add_child(h)
		obs.add_circle(Vector2(h.position.x, h.position.z), 0.4)
	add_child_autofree(a)
	return a

## Un mapa de 8 × 8 m (celdas de 25 cm) con un bloque de 1 × 1 m en el centro, como lo deja
## tools/gen_mapa_transitable.py (distancia entre centros, en 1/32 m).
func _mask_map() -> ObstacleMap:
	var o := ObstacleMap.new()
	o._n = 32
	o._cell = 0.25
	o._origin = Vector2(-4, -4)
	o._mask.resize(32 * 32 * 3)
	var blocked := func(i: int, j: int) -> bool: return i >= 14 and i < 18 and j >= 14 and j < 18
	for j in 32:
		for i in 32:
			var k := (j * 32 + i) * 3
			if blocked.call(i, j):
				o._mask[k] = 1
				o._mask[k + 1] = 1
				continue
			var best := INF
			for jj in range(14, 18):
				for ii in range(14, 18): best = minf(best, Vector2(i - ii, j - jj).length() * 0.25)
			o._mask[k + 2] = clampi(roundi(best / o._dist_step), 0, 255)
	return o

func test_quitar_del_mapa() -> void:
	var o := _mask_map()
	assert_true(o.is_blocked(Vector2(0, 0), 0.3), "el bloque estorba")
	assert_true(o.stops_bullet(Vector2(0, 0)), "y para las balas")
	var n := o.clear_box(Transform3D.IDENTITY, Vector2(-0.5, -0.5), Vector2(0.5, 0.5), 0.05)
	assert_eq(n, 16, "las 16 celdas del bloque")
	assert_false(o.is_blocked(Vector2(0, 0), 0.3), "ya se pasa")
	assert_false(o.stops_bullet(Vector2(0, 0)))
	assert_gt(o.distance(Vector2(0.6, 0)), 2.0, "y la distancia alrededor se ha recalculado")

func test_quitar_girado() -> void:
	var o := _mask_map()
	# la misma caja vista desde un contenedor girado 90°: sale igual
	var h := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO)
	assert_eq(o.clear_box(h.affine_inverse(), Vector2(-0.5, -0.5), Vector2(0.5, 0.5), 0.05), 16)

func test_sin_mapa_quita_el_circulo() -> void:
	var o := ObstacleMap.new()
	o.add_circle(Vector2(2, 2), 0.5)
	o.add_circle(Vector2(-3, 0), 0.5)
	assert_eq(o.clear_box(Transform3D(Basis(), Vector3(2, 0, 2)).affine_inverse(), Vector2(-0.4, -0.4), Vector2(0.4, 0.4)), 1)
	assert_eq(o.count(), 1)
	assert_false(o.is_blocked(Vector2(2, 2), 0.3))
	assert_true(o.is_blocked(Vector2(-3, 0), 0.3))

func test_que_piezas_se_rompen() -> void:
	var a := _arena([["inn_barril", Vector3(0, 0, 0)], ["inn_barril", Vector3(6, 0, 0)],
		["inn_barril", Vector3(-6, 0, 0)], ["inn_barril", Vector3(-6.3, 0, 0.1)],      # dos que se tocan: no
		["inn_barril", Vector3(19.5, 0, 0)],                                            # en el borde: no
		["inn_farola", Vector3(0, 0, 6)]])                                              # no es de las que se rompen
	var ps := DecorBreak.candidates(a)
	assert_eq(ps.size(), 2)
	for p in ps:
		assert_eq(p.material, "wood")
		assert_almost_eq(p.distance_to(p.center()), 0.0, 0.001)

func test_explosiones() -> void:
	var a := _arena([["inn_barril", Vector3(0, 0, 0)], ["prv_muro_bajo", Vector3(8, 0, 0)]])
	var d := DecorBreak.new().setup(a, null)
	a.add_child(d)
	watch_signals(d)
	assert_eq(d.pieces.size(), 2)
	var wall: DecorBreak.Piece = d.pieces[1]
	assert_eq(wall.material, "stone")
	DecorBreak.blast(Vector3(20, 0, 0), 2.0)
	assert_false(d.pieces[0].broken or wall.broken, "lejos no toca")
	DecorBreak.blast(wall.center(), 2.0)
	assert_false(wall.broken, "el muro aguanta una")
	DecorBreak.blast(wall.center(), 2.0)
	assert_true(wall.broken, "a la segunda cae")
	assert_signal_emitted_with_parameters(d, "piece_broken", [1])
	assert_false(d.pieces[0].broken, "el barril, lejos, sigue")
	assert_false((a.get_meta("obstacles") as ObstacleMap).is_blocked(Vector2(8, 0), 0.2), "por donde estaba el muro se pasa")
	assert_not_null(d.get_node_or_null("Rubble_1"), "quedan cascotes")
	var m := DecorBreak.new().setup(a, null, true)
	assert_eq(m.mirror, true)
	m.free()

func test_en_red() -> void:
	assert_not_null(load("res://scripts/net/net_game.gd"), "compila con el suceso «decor»")
	assert_true(NetSession.PROTOCOL >= 18, "el 18 trajo el decorado roto")
	var on := Quality.presets().map(func(p: Dictionary) -> int: return int(p.get("decor_rubble", 0)))
	assert_eq(on, [16, 28, 40, 56])
