extends GutTest
## Hito 21.18: el camino de tinta y los sellos de lacre del mapa de niveles.

func _make(opened: Array[bool], beaten: Array[bool], s_open: Array[bool], s_won: Array[bool]) -> InkPath:
	var rows := VBoxContainer.new()
	for i in opened.size():
		var c := Control.new()
		c.custom_minimum_size = Vector2(200, 50)
		rows.add_child(c)
	var holder := Control.new()
	holder.add_child(rows)
	add_child_autofree(holder)
	var ink := InkPath.new()
	holder.add_child(ink)
	ink.setup(rows, opened, beaten, s_open, s_won)
	return ink

func test_lo_ya_visto_no_se_anima() -> void:
	var ink := _make([true, true, true, false, false], [true, true, false, false, false],
		[true, true, false, false, false], [true, false, false, false, false])
	assert_eq(ink.ink_from, 1.0, "la tinta empieza en el último nivel ya visto abierto")
	assert_eq(ink.stamps[0], 1.0, "el sello que ya estaba, puesto")
	assert_eq(ink.stamps[1], 0.0, "el nuevo, por estampar")
	assert_eq(ink.new_seals, [1] as Array[int])
	ink.play(true)
	assert_eq(ink.ink, 2.0, "hasta el último abierto")
	assert_eq(ink.stamps[1], 1.0)

func test_sin_nada_nuevo_queda_igual() -> void:
	var o: Array[bool] = [true, true, false]
	var w: Array[bool] = [true, false, false]
	var ink := _make(o, w, o, w)
	assert_eq(ink.ink_from, 1.0)
	assert_true(ink.new_seals.is_empty())

func test_los_puntos_siguen_a_las_filas() -> void:
	var o: Array[bool] = [true, true]
	var w: Array[bool] = [false, false]
	var ink := _make(o, w, o, w)
	await wait_process_frames(2)
	var a := ink.point(0)
	var b := ink.point(1)
	assert_almost_eq(a.x, InkPath.X, 0.5, "a la izquierda de las filas")
	assert_gt(b.y, a.y, "uno debajo de otro")

func test_lo_visto_se_guarda_en_la_partida() -> void:
	var s := SaveData.new()
	assert_eq(InkPath.Seen.get_seen(s).open, [])
	assert_true(InkPath.Seen.mark(s, ["p1_n1", "p1_n2"], ["p1_n1"]), "cambia")
	assert_false(InkPath.Seen.mark(s, ["p1_n1", "p1_n2"], ["p1_n1"]), "lo mismo otra vez: no hace falta guardar")
	assert_eq(InkPath.Seen.get_seen(s).won, ["p1_n1"])

func test_el_sello_suena() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
	var ev: Dictionary = d.eventos
	assert_true(ev.has("seal"))
