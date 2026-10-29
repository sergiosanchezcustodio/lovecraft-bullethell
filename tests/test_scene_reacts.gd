extends GutTest
## Luz que reacciona y destrucción que se queda (hito 12.11): faroles que empujan las ráfagas,
## velas que se apagan, astillas de los rompibles, hollín en las paredes y nieve apartada.

func after_each() -> void:
	for i in 2: Gusts.current[i] = Vector4(0, 0, 0, 1)

## Un muro que para las balas en x >= 2 m (rejilla de 0,25 m de -5 a 5).
func _wall_map() -> ObstacleMap:
	var o := ObstacleMap.new()
	var n := 40
	var mask := PackedByteArray()
	mask.resize(n * n * 3)
	for j in n:
		for i in n:
			var x := -5.0 + (i + 0.5) * 0.25
			var k := (j * n + i) * 3
			mask[k] = 1 if x >= 2.0 else 0
			mask[k + 1] = 1 if x >= 2.0 else 0
			mask[k + 2] = 0 if x >= 2.0 else mini(int((2.0 - x) * 32.0), 255)   # distancia al muro, en 1/32 m
	o._mask = mask
	o._n = n
	o._cell = 0.25
	o._origin = Vector2(-5, -5)
	return o

func test_una_explosion_empuja_los_faroles_hacia_fuera() -> void:
	assert_eq(Ambient._blast_push(Vector3(1, 2, 0)), Vector2.ZERO, "sin ráfagas, nada")
	Gusts.current[0] = Vector4(0, 0, 0.2, 6.0)
	var p := Ambient._blast_push(Vector3(1, 2, 0))
	assert_gt(p.x, 0.15, "hacia fuera, con toda la fuerza cerca")
	assert_almost_eq(p.y, 0.0, 0.001)
	assert_lt(Ambient._blast_push(Vector3(5, 0, 0)).x, p.x, "menos lejos")
	assert_eq(Ambient._blast_push(Vector3(7, 0, 0)), Vector2.ZERO, "fuera del radio, nada")

func test_las_velas_se_apagan_y_vuelven_a_prender() -> void:
	var a := Ambient.new()                              # fuera del árbol: su _ready quiere una arena
	var holder := Node3D.new()
	add_child_autofree(holder)
	var fx := VoxelFx.emitter("candle", 0.03)
	holder.add_child(fx)
	fx.global_position = Vector3(1, 1, 0)
	var light := OmniLight3D.new()
	holder.add_child(light)
	a._candles.append([fx, 0.0, light])
	Gusts.current[0] = Vector4(0, 0, 0.07, 2.2)        # un esquive al lado: no la apaga
	light.light_energy = 1.0
	a._candle_step(0.016)
	assert_eq(a._candles[0][1], 0.0, "un esquive no apaga una vela")
	Gusts.current[0] = Vector4(0, 0, 0.21, 6.6)        # una explosión
	light.light_energy = 1.0
	a._candle_step(0.016)
	assert_gt(a._candles[0][1], 2.0, "apagada unos segundos")
	assert_false(fx.emitting)
	assert_lt(light.light_energy, 0.5, "la luz de su pieza baja")
	Gusts.current[0] = Vector4(0, 0, 0, 1)
	a._candle_step(5.0)
	assert_eq(a._candles[0][1], 0.0, "vuelve a prender")
	assert_true(fx.emitting)
	a.free()

func test_los_rompibles_dejan_astillas_con_tope() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var old := Debris.limit
	Debris.limit = 30
	Debris.scatter(fx, Vector3.ZERO, [Color.BROWN, Color.TAN], 10)
	var d: Debris = fx.get_meta("debris")
	assert_eq(d.count(), 10)
	for i in 5: Debris.scatter(fx, Vector3(i, 0, 0), [Color.BROWN], 10)
	assert_eq(d.count(), 30, "como mucho el tope")
	d._process(Debris.LIFE + 1.0)
	assert_eq(d.count(), 0, "y se van")
	Debris.limit = old

func test_las_astillas_estan_tumbadas_en_el_suelo() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	Debris.scatter(fx, Vector3(3, 0, 3), [Color.BROWN], 6, 0.5)
	var d: Debris = fx.get_meta("debris")
	d._process(Debris.APPEAR + 0.01)
	for i in 6:
		var x: Transform3D = d._xf[i]                      # sin pantalla, el MultiMesh no las guarda
		assert_lt(x.origin.y, 0.1, "a ras de suelo")
		assert_lt(Vector2(x.origin.x - 3, x.origin.z - 3).length(), 0.51, "alrededor")
		var size := x.basis.get_scale()
		assert_lt(size.y, size.x, "planas")

func test_el_hollin_solo_con_algo_cerca() -> void:
	var o := _wall_map()
	assert_true(WallScorch.near_something(o, Vector2(0.5, 0), 2.5), "el muro está a 1,5 m")
	assert_false(WallScorch.near_something(o, Vector2(-1.5, 0), 2.5), "a 3,5 m, nada")
	assert_false(WallScorch.near_something(ObstacleMap.new(), Vector2.ZERO, 2.5), "sin máscara (campo de pruebas), nada")

func test_el_hollin_tiene_tope_y_solo_pinta_el_decorado() -> void:
	var ws := WallScorch.new()
	add_child_autofree(ws)
	var old := WallScorch.limit
	WallScorch.limit = 3
	for i in 5: ws._add(Vector2(2, i), 2.2)
	assert_eq(ws.count(), 5)
	var dc: Decal = ws._decals[4][0]
	assert_almost_eq(dc.global_basis.y.normalized().y, 1.0, 0.01, "proyecta hacia abajo")
	assert_eq(dc.cull_mask, ArenaBuilder.VIS_DECOR, "solo el decorado")
	ws._process(1.0)
	assert_eq(ws.count(), 3, "las que sobran, deprisa")
	ws._process(WallScorch.LIFE)
	assert_eq(ws.count(), 0)
	WallScorch.limit = old

func test_la_nieve_apartada_compila() -> void:
	var s: Shader = load("res://scripts/fx/snow_blast.gdshader")
	assert_not_null(s)
	assert_true(s.get_shader_uniform_list().any(func(u: Dictionary) -> bool: return u.name == "fade"), "se desvanece en GroundMarks")
