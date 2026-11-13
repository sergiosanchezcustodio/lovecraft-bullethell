extends GutTest
## Hito 20.2: fuera de la partida las ventanas entran como una página que gira sobre el lomo; en
## la partida (MenuKit.page_turn = false), con el fundido corto de siempre. Las dos acaban planas.

func after_each() -> void:
	MenuKit.page_turn = true

func _open() -> Control:
	var holder := Control.new()
	add_child_autofree(holder)
	var w: Array = MenuKit.window(holder, MenuKit.INK, 400)
	(w[1] as VBoxContainer).add_child(MenuKit.button("Prueba"))
	return (w[1] as Control).get_parent().get_parent()

func test_la_pagina_gira_y_queda_plana() -> void:
	var panel := _open()
	await get_tree().process_frame
	assert_lt(panel.scale.x, 0.95, "empieza girada")
	assert_eq(panel.pivot_offset.x, 0.0, "gira sobre el borde izquierdo")
	await get_tree().create_timer(MenuKit.PAGE_TIME + 0.15).timeout
	assert_almost_eq(panel.scale, Vector2.ONE, Vector2(0.001, 0.001), "plana al final")
	assert_eq(panel.modulate, Color.WHITE, "con su color, sin sombra")

func test_en_la_partida_entra_como_siempre() -> void:
	MenuKit.page_turn = false
	var panel := _open()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(panel.scale.x, 0.9, "sin girar")
	await get_tree().create_timer(0.4).timeout
	assert_almost_eq(panel.scale, Vector2.ONE, Vector2(0.001, 0.001))
