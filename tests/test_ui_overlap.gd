extends GutTest
## Revisión de textos que pisan los marcos (ui_check=true, scripts/ui/ui_overlap_check.gd).

const Check := preload("res://scripts/ui/ui_overlap_check.gd")

func _panel() -> Panel:
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	var p := Panel.new()
	p.position = Vector2(100, 100)
	p.size = Vector2(500, 300)
	layer.add_child(p)
	MenuKit.dress(p, MenuKit.BRASS, Vector2.ZERO, 60.0)
	return p

func _label(p: Control, text: String, at: Vector2) -> Label:
	var l := MenuKit.title(text, 24)
	l.position = at
	l.size = Vector2(p.size.x - at.x * 2.0, 32)
	p.add_child(l)
	return l

func test_texto_sobre_el_filete() -> void:
	var p := _panel()
	_label(p, "Elige compañero", Vector2(0, 4))
	var c := Check.new()
	add_child_autofree(c)
	await wait_frames(2)
	var out: Array = c.scan().filter(func(x: String) -> bool: return x.contains("«"))   # (y, solo él arriba, descentrado)
	assert_eq(out.size(), 1, str(out))
	assert_string_contains(String(out[0]), "Elige compañero")

func test_texto_dentro_del_marco() -> void:
	var p := _panel()
	_label(p, "Elige compañero", Vector2(0, 120))
	var c := Check.new()
	add_child_autofree(c)
	await wait_frames(2)
	var out: Array = c.scan()
	assert_eq(out.size(), 0, str(out))

func test_recuadro_con_borde() -> void:
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	var box := PanelContainer.new()
	box.position = Vector2(100, 100)
	var sb := MenuKit.box(Color.BLACK, MenuKit.BRASS, 2)
	sb.set_content_margin_all(0)
	box.add_theme_stylebox_override("panel", sb)
	layer.add_child(box)
	var l := UiKit.label("Ataques balísticos", 20)
	box.add_child(l)                                # sin margen: el texto toca el borde
	var c := Check.new()
	add_child_autofree(c)
	await wait_frames(2)
	assert_eq(c.scan().size(), 1)

## 05-11-2026: filas anchas con más hueco a un lado del marco que al otro.
func test_fila_desplazada() -> void:
	var p := _panel()
	var b := MenuKit.button("Pantalla completa", MenuKit.INK, 20)
	b.position = Vector2(40, 140)
	b.size = Vector2(400, 40)                    # 40 a la izquierda, 60 a la derecha
	p.add_child(b)
	var c := Check.new()
	add_child_autofree(c)
	await wait_frames(2)
	var out: Array = c.scan()
	assert_eq(out.size(), 1, str(out))
	assert_string_contains(String(out[0]), "filas desplazadas")
	b.position.x = 50                            # centrada
	c._seen.clear()
	await wait_frames(1)
	assert_eq(c.scan().size(), 0)

## El hueco de la barra de desplazamiento (MenuKit.scroll_gutter): sin barra, ninguno; con barra,
## a los dos lados, para que las filas sigan centradas.
func test_hueco_de_la_barra() -> void:
	var sc := ScrollContainer.new()
	sc.size = Vector2(400, 200)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child_autofree(sc)
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(m)
	var list := VBoxContainer.new()
	m.add_child(list)
	MenuKit.scroll_gutter(sc, m)
	var row := Control.new()
	row.custom_minimum_size = Vector2(10, 50)
	list.add_child(row)
	await wait_frames(3)
	assert_eq(m.get_theme_constant("margin_right"), 0, "sin barra, sin hueco")
	assert_eq(m.get_theme_constant("margin_left"), 0)
	for i in 10:
		var r := Control.new()
		r.custom_minimum_size = Vector2(10, 50)
		list.add_child(r)
	await wait_frames(3)
	assert_true(sc.get_v_scroll_bar().visible)
	assert_eq(m.get_theme_constant("margin_right"), 14, "con barra, su hueco")
	assert_eq(m.get_theme_constant("margin_left"), 14 + int(sc.get_v_scroll_bar().get_combined_minimum_size().x), "y el mismo al otro lado")

## El rótulo del nivel se quita deprisa cuando se abre la pausa o la pantalla final.
func test_rotulo_se_quita() -> void:
	var host := Node.new()
	add_child_autofree(host)
	var card := LevelCard.enter(host, "p1_n1", "Campamento")
	await wait_frames(2)
	card.dismiss()
	await wait_seconds(0.45)
	assert_false(is_instance_valid(card), "se ha ido")

## Una estadística de las comparaciones no se parte entre dos líneas.
func test_estadistica_entera() -> void:
	var rows: Array[Dictionary] = [{"name": "Daño de la zona", "before": "13,3/s", "after": "18,62/s", "good": true},
		{"name": "Atraviesa", "before": "0", "after": "2", "good": true}]
	var s := StatCompare.bbcode(rows)
	var parts := s.split("    ")
	assert_eq(parts.size(), 2, "se rompe entre una y otra")
	for p in parts:
		var plain := RegEx.create_from_string(r"\[[^\]]*\]").sub(p, "", true)
		assert_false(plain.contains(" "), "sin espacios que rompan dentro: " + plain)
	assert_string_contains(s, "/" + char(0x2060) + "s")

## Una ventana que no cabe en la pantalla (interfaz Grande) se encoge alrededor del centro; una
## que cabe, no cambia.
func test_ventana_que_no_cabe() -> void:
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(host)
	var w: Array = MenuKit.window(host, MenuKit.INK, 400)
	var root: Control = w[0]
	var center: CenterContainer = root.get_child(1)
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(300, 200)
	(w[1] as VBoxContainer).add_child(tall)
	await wait_frames(3)
	assert_eq(center.scale, Vector2.ONE, "cabe: sin encoger")
	var vs := get_viewport().get_visible_rect().size
	tall.custom_minimum_size.y = vs.y * 1.5
	await wait_frames(3)
	assert_lt(center.scale.x, 1.0, "no cabe: se encoge")
	var r := (center.get_child(0) as Control).get_global_rect()
	assert_true(Rect2(Vector2.ZERO, vs).grow(1.0).encloses(r), "y queda dentro: %s" % r)
	assert_almost_eq(r.get_center().x, vs.x * 0.5, 2.0, "centrada")
