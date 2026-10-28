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
	var out: Array = c.scan()
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
