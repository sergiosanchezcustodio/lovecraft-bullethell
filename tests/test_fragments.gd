extends GutTest
## Páginas sueltas y epílogo (hito 13.11).

func test_una_pagina_por_nivel() -> void:
	assert_eq(Fragments.total(), 15)
	for lv in Campaign.levels():
		var p := Fragments.page_of(String(lv.id))
		assert_false(p.is_empty(), "%s: sin página" % lv.id)
		if not p.is_empty(): assert_gt(String(p.text).length(), 120)
	assert_true(Fragments.page_of("sin_fin:p1_n1").is_empty())

func test_se_guardan_y_completan_su_relato() -> void:
	var s := SaveData.new()
	assert_false(Fragments.has(s, "p1_n2"))
	assert_eq(Fragments.add(s, "p1_n2"), 1)
	assert_eq(Fragments.add(s, "p1_n4"), 2)
	assert_eq(Fragments.add(s, "p1_n4"), 2, "sin repetir")
	assert_eq(Fragments.add(s, "p2_n1"), 1, "otro relato")
	assert_eq(int(s.stats.fragments), 3)
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_true(Fragments.has(back, "p1_n4"), "se guarda")
	var lib := Library.entries(back, "stories")
	var known := lib.filter(func(e: Dictionary) -> bool: return e.known)
	assert_eq(known.size(), 3)
	assert_eq(lib.size(), 15 + 2, "páginas y epílogos")

func test_sitios_libres_y_fijos() -> void:
	var o := ObstacleMap.new()
	o.bounds = Rect2(-30, -30, 60, 60)
	var a := Fragments.spots("p1_n1", o)
	assert_eq(a.size(), 6)
	assert_eq(Fragments.spots("p1_n1", o), a, "siempre los mismos para el nivel")
	assert_ne(Fragments.spots("p1_n2", o), a)
	for p in a:
		assert_gt(Vector2(p.x, p.z).length(), 8.9, "lejos del principio")
		assert_true(o.bounds.grow(-3.9).has_point(Vector2(p.x, p.z)))

func test_epilogos() -> void:
	assert_eq(Campaign.last_id(), "p3_n5")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
	for id in ["epilogo", "epilogo_locura"]:
		assert_true(d.has(id))
		assert_true(" ".join(PackedStringArray(d[id])).contains("{nombre}"))
	var s := SaveData.new()
	var lib := Library.entries(s, "stories").filter(func(e: Dictionary) -> bool: return e.section == "Epílogos")
	assert_eq(lib.size(), 2)
	assert_false(lib[1].text.contains(" de el "), "«del investigador»")
	s.mark_seen("epilogues", "epilogo_locura")
	assert_true(Library.entries(s, "stories").filter(func(e: Dictionary) -> bool: return e.id == "epilogo_locura")[0].known)

func test_boton_del_epilogo() -> void:
	var s := Menus.EndScreen.new("Nivel superado", PackedStringArray(), UiKit.GOLD)
	s.epilogue = true
	add_child_autofree(s)
	await get_tree().process_frame
	var labels := []
	for b in s.find_children("*", "Button", true, false): labels.append((b as Button).text)
	assert_has(labels, "Epílogo")
	var s2 := Menus.EndScreen.new("Nivel superado", PackedStringArray(), UiKit.GOLD)
	add_child_autofree(s2)
	await get_tree().process_frame
	assert_false(s2.find_children("*", "Button", true, false).any(func(b: Node) -> bool: return (b as Button).text == "Epílogo"))
