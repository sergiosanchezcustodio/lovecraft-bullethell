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
