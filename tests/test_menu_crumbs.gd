extends GutTest
## Hito 20.5: la ruta encima del título de las ventanas de fuera de la partida.

func after_each() -> void:
	MenuKit.page_turn = true

func _win(title: String) -> Label:
	var holder := Control.new()
	add_child_autofree(holder)
	var w: Array = MenuKit.window(holder, MenuKit.INK, 300)
	return MenuKit.heading(w[1], title)

func test_sola_no_se_ve() -> void:
	var t := _win("Logros")
	assert_eq(MenuKit.crumb_of(t), "")

func test_lleva_las_de_debajo_y_la_pestana() -> void:
	var a := _win("Jugar")
	var b := _win("La noche eterna")
	assert_eq(MenuKit.crumb_of(b), "Jugar" + MenuKit.CRUMB_SEP + "La noche eterna")
	MenuKit.crumb_tail(a, "Personajes")
	assert_eq(MenuKit.crumb_of(a), "Jugar" + MenuKit.CRUMB_SEP + "Personajes")

func test_las_cerradas_no_cuentan() -> void:
	var a := _win("Tienda")
	a.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().queue_free()
	await get_tree().process_frame
	var b := _win("Logros")
	assert_eq(MenuKit.crumb_of(b), "", "la tienda ya se cerró")

func test_en_la_partida_sin_ruta() -> void:
	MenuKit.page_turn = false
	_win("Pausa")
	var b := _win("Configuración")
	assert_eq(MenuKit.crumb_of(b), "")
