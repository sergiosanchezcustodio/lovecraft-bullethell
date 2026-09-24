extends GutTest

func test_separa_posicionales_opciones_y_banderas() -> void:
	var la := LaunchArgs.parse(PackedStringArray(["still", "0", "count=150", "--secs=8", "--god"]))
	assert_eq(la.positional, ["still", "0"] as Array[String])
	assert_eq(la.get_int("count"), 150)
	assert_eq(la.get_float("secs"), 8.0)
	assert_true(la.get_bool("god"))

func test_valores_por_defecto_si_falta_la_opcion() -> void:
	var la := LaunchArgs.parse(PackedStringArray([]))
	assert_eq(la.get_int("count", 7), 7)
	assert_eq(la.get_str("model", "acechador"), "acechador")
	assert_false(la.get_bool("god"))
	assert_eq(la.get_floats("shots"), [] as Array[float])

func test_lista_de_tiempos_para_capturas() -> void:
	var la := LaunchArgs.parse(PackedStringArray(["shots=2,10.5,30"]))
	assert_eq(la.get_floats("shots"), [2.0, 10.5, 30.0] as Array[float])
