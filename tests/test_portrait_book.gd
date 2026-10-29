extends GutTest
## Hito 12.14: el libro que se abre de la portada a la selección y los retratos con estado.

func test_el_retrato_sangra_con_poca_vida_y_se_pierde_con_poca_cordura() -> void:
	assert_eq(Hud.portrait_state(1.0, 1.0, false, false), Vector2.ZERO, "entero y cuerdo, nada")
	assert_eq(Hud.portrait_state(0.5, 0.4, false, false), Vector2.ZERO, "hasta la mitad de la vida y el 40 % de cordura, nada")
	var s := Hud.portrait_state(0.3, 0.24, false, false)
	assert_between(s.x, 0.4, 0.6, "a medias")
	assert_between(s.y, 0.4, 0.6)
	assert_eq(Hud.portrait_state(0.9, 0.9, true, true), Vector2.ONE, "abatido y en la crisis, del todo")

func test_la_seleccion_llega_desde_negro_solo_si_viene_del_libro() -> void:
	var n := Node.new()
	add_child_autofree(n)
	BookTransition.pending = false
	BookTransition.arrive(n)
	assert_eq(n.get_child_count(), 0, "sin libro, nada")
	BookTransition.pending = true
	BookTransition.arrive(n)
	assert_eq(n.get_child_count(), 1, "con libro, un negro que se aclara")
	assert_false(BookTransition.pending, "una sola vez")

func test_el_libro_usa_la_ilustracion_de_la_biblioteca() -> void:
	assert_eq(BookTransition.ART, LibraryMenu.ART, "la misma ilustración")
	assert_true(BookTransition.RIGHT_PAGE.position.x >= 0.5 and BookTransition.RIGHT_PAGE.end.x <= 1.0)
