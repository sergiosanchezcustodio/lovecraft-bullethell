extends GutTest
## Hito 21.16: retratos pintados de los investigadores.

func test_cada_investigador_tiene_su_retrato() -> void:
	for c: CharacterData in DebugOptions.list_resources("res://data/characters"):
		var t := Portraits.of(c.model)
		assert_not_null(t, "%s: falta resources/retratos/%s.jpg" % [c.id, c.model])
		if t != null: assert_eq(t.get_width(), t.get_height(), "%s: cuadrado" % c.id)

func test_sin_retrato_null() -> void:
	assert_null(Portraits.of(""))
	assert_null(Portraits.of("no_existe"))

func test_la_tienda_usa_el_retrato() -> void:
	for e: Shop.Entry in Shop.catalog():
		if e.section == ShopItem.Section.CHARACTER:
			assert_eq(e.icon, Portraits.of(e.icon_model), e.id)

func test_derby_tiene_tambien_el_de_asenath() -> void:   # se alternan en la selección
	var d: CharacterData = load("res://data/characters/derby.tres")
	assert_not_null(Portraits.of(d.alt_model))
