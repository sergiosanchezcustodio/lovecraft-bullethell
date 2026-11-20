extends GutTest
## Pasos de física de los enemigos más baratos (hito 23.6), sin cambiar cómo se mueven: lo nuevo
## da exactamente lo mismo que el cálculo de antes, que se repite aquí como referencia.

const ARENAS := ["campamento", "calles", "ciudad", "bosque", "auseil"]

func _mask_of(arena: String) -> ObstacleMap:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/%s.json" % arena))
	var om := ObstacleMap.new()
	assert_true(d.has("mask") and om.load_mask(d.mask), "%s: con mapa" % arena)
	return om

## `_push_mask` como era antes del atajo.
func _push_before(om: ObstacleMap, pos: Vector2, r: float) -> Vector2:
	if om.distance(pos) <= 0.0: pos = om._nearest_free(pos, r)
	for k in 4:
		var d := om.distance(pos)
		if d >= r: return pos
		var e := om._cell * 0.5
		var g := Vector2(om.distance(pos + Vector2(e, 0)) - om.distance(pos - Vector2(e, 0)),
			om.distance(pos + Vector2(0, e)) - om.distance(pos - Vector2(0, e)))
		if g.length() < 0.0001: return pos
		pos += g.normalized() * (r - d + 0.01)
	return pos

func test_apartar_del_decorado_da_lo_mismo_que_antes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for arena: String in ARENAS:
		var om := _mask_of(arena)
		var b := om.bounds
		var bad := 0
		for k in 4000:
			var p := Vector2(rng.randf_range(b.position.x, b.end.x), rng.randf_range(b.position.y, b.end.y))
			var r := rng.randf_range(0.25, 1.6)
			if not om.push_out(p, r).is_equal_approx(_push_before(om, p, r)): bad += 1
		assert_eq(bad, 0, "%s: 4000 puntos al azar, todos iguales" % arena)

## `FlowField.direction` como era antes de guardarla por celda.
func _direction_before(f: FlowField, from: Vector2) -> Vector2:
	var c := f.cell_of(from)
	if not f._inside(c): return Vector2.ZERO
	var best := f._dist[c.y * f.w + c.x] if f._free[c.y * f.w + c.x] == 1 else FlowField.INF_D
	var best_c := c
	for dv: Vector2i in FlowField.DIRS:
		var n := c + dv
		if not f._inside(n): continue
		var nk := n.y * f.w + n.x
		if f._free[nk] == 0: continue
		var cost := f._dist[nk] + (0.414 if dv.x != 0 and dv.y != 0 else 0.0)
		if cost < best:
			best = cost
			best_c = n
	if best_c == c: return Vector2.ZERO
	return (f.center(best_c.x, best_c.y) - from).normalized()

func test_la_direccion_del_flujo_da_lo_mismo_que_antes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for arena: String in ARENAS:
		var om := _mask_of(arena)
		var f := FlowField.new().setup(om, om.bounds)
		var b := om.bounds
		var bad := 0
		for pass_k in 3:                                    # tras cada pasada, lo guardado ya no vale
			var targets: Array[Vector2] = [Vector2(rng.randf_range(b.position.x, b.end.x), rng.randf_range(b.position.y, b.end.y))]
			f.rebuild(targets)
			for k in 3000:
				var p := Vector2(rng.randf_range(b.position.x - 1, b.end.x + 1), rng.randf_range(b.position.y - 1, b.end.y + 1))
				if not f.direction(p).is_equal_approx(_direction_before(f, p)): bad += 1
		assert_eq(bad, 0, "%s: 9000 puntos en tres pasadas, todos iguales" % arena)

func test_los_multiplicadores_de_velocidad_se_rehacen_cada_paso() -> void:
	Enemy._mul_frame = -1
	Enemy._frame_mults()
	assert_almost_eq(Enemy._mul_melee, Difficulty.melee_speed() * Pacts.value("enemy_speed") * DreamLands.haste(), 0.0001)
	assert_almost_eq(Enemy._mul_attack, Difficulty.attack(), 0.0001)
