extends GutTest
## Hito 16.35: cielos de los relatos.

func test_cielo_de_cada_relato() -> void:
	assert_eq(RelatoScreen.sky_for("p1_n2"), "aurora", "la Antártida, con aurora")
	assert_eq(RelatoScreen.sky_for("p3_n4"), "tormenta")
	assert_eq(RelatoScreen.sky_for("p3_n5"), "rlyeh")
	assert_eq(RelatoScreen.sky_for("p2_n3"), "luna", "el de su parte")

func test_datos() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RelatoScreen.SKIES))
	var skies: Dictionary = d.skies
	var used: Array = (d.parts as Dictionary).values() + (d.levels as Dictionary).values()
	for k: String in used: assert_true(skies.has(k), "existe el cielo %s" % k)
	for k: String in skies:
		var m := int(skies[k].get("mode", 0))
		assert_between(m, 0, 3, k)
		if skies[k].has("cover"): assert_between(float(skies[k].cover), 0.3, 0.7, k)
	var relatos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
	for id: String in relatos:
		if id.begins_with("p"): assert_ne(RelatoScreen.sky_for(id), "", "el relato %s tiene cielo" % id)

func test_nubes_de_la_portada() -> void:
	var cfg := TitleScreenConfig.new()
	assert_true(cfg.clouds_enabled)
	assert_eq(cfg.clouds_block, 0.0, "sobre la pintura, suaves")
	var sh: Shader = load("res://scripts/title/window_sky.gdshader")
	assert_true(sh.code.contains("clouds_strength"))
