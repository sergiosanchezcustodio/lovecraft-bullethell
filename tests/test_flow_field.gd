extends GutTest
## Mapa de flujo: los enemigos rodean el decorado en lugar de quedarse pegados.

func test_rodea_un_muro() -> void:
	var obs := ObstacleMap.new()
	obs.bounds = Rect2(-10, -10, 20, 20)
	for z in range(-6, 7): obs.add_circle(Vector2(0, z), 0.6)        # muro vertical en x = 0
	var f := FlowField.new().setup(obs, obs.bounds)
	f.rebuild([Vector2(5, 0)] as Array[Vector2])                       # jugador al otro lado
	var from := Vector2(-5, 0)
	assert_false(f.clear_line(from, Vector2(5, 0)), "el muro tapa la línea recta")
	# siguiendo el flujo se llega al jugador
	var p := from
	for k in 200:
		var d := f.direction(p)
		if d == Vector2.ZERO: break
		p += d * 0.25
		assert_false(obs.is_blocked(p, 0.3), "nunca entra en el muro (paso %d)" % k)
		if p.distance_to(Vector2(5, 0)) < 1.5: break
	assert_lt(p.distance_to(Vector2(5, 0)), 1.5, "llega rodeando el muro")

func test_rincon_cerrado_no_es_alcanzable() -> void:
	var obs := ObstacleMap.new()
	obs.bounds = Rect2(-10, -10, 20, 20)
	for a in 24:                                                       # anillo cerrado alrededor de (−5, −5)
		obs.add_circle(Vector2(-5, -5) + Vector2.from_angle(a * TAU / 24) * 2.5, 0.6)
	var f := FlowField.new().setup(obs, obs.bounds)
	f.rebuild([Vector2(5, 5)] as Array[Vector2])
	assert_true(f.reachable(Vector2(0, 0)), "lo abierto se alcanza")
	assert_false(f.reachable(Vector2(-5, -5)), "dentro del anillo no se llega: ahí no aparece nadie")
	assert_false(f.reachable(Vector2(30, 0)), "fuera de la arena tampoco")

func test_pasillo_del_ancho_del_cuerpo() -> void:
	var obs := ObstacleMap.new()
	obs.bounds = Rect2(-10, -10, 20, 20)
	obs.add_circle(Vector2(0, 1.6), 0.5)                               # esquina junto a la línea
	var f := FlowField.new().setup(obs, obs.bounds)
	assert_true(f.clear_line(Vector2(-5, 0), Vector2(5, 0)), "el centro pasa")
	assert_false(f.clear_line(Vector2(-5, 0), Vector2(5, 0), 1.2), "un cuerpo ancho rozaría la esquina")
