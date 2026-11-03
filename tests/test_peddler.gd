extends GutTest
## El buhonero (hito 16.12): en qué niveles sale, sus datos y sus precios.

func _cfg() -> Dictionary:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ObjectiveDirector.DATA))
	return d.get("peddler", {})

func test_sale_en_los_niveles_2_y_4_de_cada_parte() -> void:
	var pc := _cfg()
	for part in [1, 2, 3]:
		for n in [1, 2, 3, 4, 5]:
			var id := "p%d_n%d" % [part, n]
			assert_eq(ObjectiveDirector.peddler_due(pc, id, false), n == 2 or n == 4, id)
	assert_false(ObjectiveDirector.peddler_due(pc, "p1_n2", true), "no en la partida del día")
	assert_false(ObjectiveDirector.peddler_due(pc, "no_existe", false))

func test_datos_validos() -> void:
	var pc := _cfg()
	var ids := []
	for g: Dictionary in pc.get("goods", []):
		ids.append(String(g.id))
		assert_gt(int(g.get("price", 0)), 0, String(g.id))
		if g.has("model"): assert_true(FileAccess.file_exists("res://models/%s.json" % g.model), String(g.model))
	assert_eq(ids, ["remedio", "baratija", "libro"])
	for k in ["p1", "p2", "p3"]:
		var v: Array = (pc.get("vendors", {}) as Dictionary).get(k, [])
		assert_eq(v.size(), 2, k)
		assert_true(FileAccess.file_exists("res://models/%s.json" % v[0]), "modelo de %s" % k)
		assert_true(Anims.duration(String(v[0]), "idle") > 0.0, "%s anima" % v[0])

func test_precios_por_parte() -> void:
	var o := Objective.new()
	autofree(o)
	var g := {"price": 110}
	assert_eq(o.price_of(g), 110)
	o.price_mult = 1.6
	assert_eq(o.price_of(g), 175, "redondeado a 5 $")
	o.price_mult = 2.2
	assert_eq(o.price_of({"price": 60}), 130)
