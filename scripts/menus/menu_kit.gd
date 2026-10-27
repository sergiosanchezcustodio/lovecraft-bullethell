class_name MenuKit
extends RefCounted
## Piezas comunes de los menús de fuera de la partida (huecos, menú principal, tienda,
## configuración): la fuente de la portada para los títulos, ventanas centradas y el
## diálogo de confirmación.
## Estilo de biblioteca gótica (27-10-2026): ventanas de madera oscura con filete de latón y
## esquinas de filigrana (gothic_panel.gdshader; resources/ui/menu_esquina.png, de
## tools/gen_adornos_menu.py), separador de latón bajo los títulos, texto en EB Garamond (tema de
## las ventanas: el HUD no cambia) y la opción elegida con luz de vela que parpadea y dos rombos.

const FONT_PATH := "res://resources/fonts/IMFeENsc28P.ttf"
const BODY_FONT_PATH := "res://resources/fonts/EBGaramond.ttf"
const INK := Color(0.93, 0.82, 0.58)          ## dorado viejo de la portada
const DANGER := Color(0.86, 0.3, 0.24)
const BRASS := Color(0.74, 0.56, 0.3)         ## latón viejo de los marcos
const CANDLE := Color(1.0, 0.56, 0.2)         ## luz de vela de la opción elegida
const TEXT := Color(0.84, 0.77, 0.64)         ## texto de los botones
const TEXT_LIT := Color(1.0, 0.93, 0.76)      ## y con el foco
const VALUE := Color(0.98, 0.8, 0.48)         ## valores de las filas de opciones
const CORNER := preload("res://resources/ui/menu_esquina.png")
const DIVIDER := preload("res://resources/ui/menu_separador.png")
const PANEL_SHADER := preload("res://scripts/menus/gothic_panel.gdshader")
const DIM_SHADER := preload("res://scripts/menus/gothic_dim.gdshader")

static var _font: FontFile
static var _theme: Theme
static var _lit: Array[StyleBox] = []         ## estilos con luz de vela (parpadean juntos)
static var _ticking := false
static var _panels: Array = []                 ## [WeakRef al fondo, ShaderMaterial]: su resplandor parpadea con la vela

static func font() -> FontFile:
	if _font == null:
		_font = load(FONT_PATH) as FontFile         # como recurso importado: el .ttf suelto no va en la build
	return _font

## Título con la fuente de la portada.
static func title(text: String, size: int = 44, color: Color = INK) -> Label:
	var l := UiKit.label(text, size, color)
	l.add_theme_font_override("font", font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

## Tema de los menús: el texto en EB Garamond (los títulos y botones llevan la de la portada).
## EB Garamond con cifras alineadas y de ancho fijo (el reloj del HUD no baila).
static func body_font(numbers := false) -> FontVariation:
	var ts := TextServerManager.get_primary_interface()
	var f := FontVariation.new()
	f.base_font = load(BODY_FONT_PATH) as FontFile
	f.variation_opentype = {ts.name_to_tag("wght"): 560}
	if numbers: f.opentype_features = {ts.name_to_tag("lnum"): 1, ts.name_to_tag("tnum"): 1}
	return f

static func theme() -> Theme:
	if _theme == null:
		_theme = Theme.new()
		var f := FontVariation.new()               # algo más gruesa que la normal: se lee mejor sobre lo oscuro
		f.base_font = load(BODY_FONT_PATH) as FontFile
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 520}
		_theme.default_font = f
	return _theme

## Latón del marco según el acento: el de peligro, enrojecido.
static func brass_for(accent: Color) -> Color:
	return BRASS.lerp(accent, 0.45) if accent == DANGER else BRASS

## Botón con la fuente de la portada: sombrío y con filete fino; con el foco, luz de vela que
## parpadea, filete entero y dos rombos de latón a los lados.
static func button(text: String, accent: Color = UiKit.GOLD, size: int = 28) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size)
	_text_colors(b)
	var metal := brass_for(accent)
	b.add_theme_stylebox_override("normal", box(Color(0.05, 0.036, 0.028, 0.6), Color(metal, 0.35), 1))
	b.add_theme_stylebox_override("disabled", box(Color(0.05, 0.036, 0.028, 0.45), Color(metal, 0.2), 1))
	b.add_theme_color_override("font_disabled_color", Color(TEXT, 0.5))
	var lit := lit_box(metal)
	b.add_theme_stylebox_override("focus", lit)
	b.add_theme_stylebox_override("hover", lit)
	b.add_theme_stylebox_override("pressed", box(Color(0.22, 0.13, 0.06, 0.92), metal.lightened(0.3), 2))
	_marks(b, metal)
	_start_flicker()
	return b

## Botón sin caja (el menú principal, sobre la ilustración): solo el texto y, con el foco, un
## halo de vela alargado detrás y los dos rombos.
static func plain_button(text: String, size: int = 30) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size)
	_text_colors(b)
	b.add_theme_color_override("font_outline_color", Color(0.01, 0.008, 0.006, 0.9))
	b.add_theme_constant_override("outline_size", 6)
	var empty := StyleBoxEmpty.new()
	empty.content_margin_top = 6; empty.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", empty)
	var g := Gradient.new()
	g.set_color(0, Color(CANDLE, 0.42))
	g.set_color(1, Color(CANDLE, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 256; tex.height = 64
	var halo := StyleBoxTexture.new()
	halo.texture = tex
	halo.content_margin_top = 6; halo.content_margin_bottom = 6
	_lit.append(halo)
	b.add_theme_stylebox_override("focus", halo)
	b.add_theme_stylebox_override("hover", halo)
	b.add_theme_stylebox_override("pressed", halo)
	_marks(b, BRASS)
	_start_flicker()
	return b

static func _text_colors(b: Button) -> void:
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_focus_color", TEXT_LIT)
	b.add_theme_color_override("font_hover_color", TEXT_LIT)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)

## Caja de los botones y filas: fondo, filete de latón y esquinas casi rectas.
static func box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 18; sb.content_margin_right = 18
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	return sb

## Caja con luz de vela (la opción elegida): parpadea con las demás.
static func lit_box(metal: Color = BRASS, glow := 14) -> StyleBoxFlat:
	var lit := box(Color(0.15, 0.09, 0.045, 0.88), metal.lightened(0.15), 2)
	lit.shadow_size = glow
	_lit.append(lit)
	_start_flicker()
	return lit

## Velo que tapa la pantalla detrás de una ventana: más oscuro hacia los bordes.
static func veil(strength := 1.0) -> ColorRect:
	var dim := ColorRect.new()
	var dm := ShaderMaterial.new()
	dm.shader = DIM_SHADER
	dm.set_shader_parameter("strength", strength)
	dim.material = dm
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return dim

## Rombos de latón a los lados del texto cuando el botón tiene el foco o el ratón encima.
static func _marks(b: Button, metal: Color) -> void:
	var m := Control.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	m.draw.connect(func() -> void:
		if b.text == "" or not (b.has_focus() or b.is_hovered()): return
		var font_size := b.get_theme_font_size("font_size")
		var w := b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var cy := m.size.y * 0.5
		var r := maxf(4.0, font_size * 0.17)
		for side: float in [-1.0, 1.0]:
			var cx := m.size.x * 0.5 + side * (w * 0.5 + r * 3.2)
			var pts := PackedVector2Array([Vector2(cx, cy - r), Vector2(cx + r, cy), Vector2(cx, cy + r), Vector2(cx - r, cy)])
			m.draw_circle(Vector2(cx, cy), r * 2.2, Color(CANDLE, 0.12))
			m.draw_colored_polygon(pts, metal.lightened(0.35)))
	for sig: Signal in [b.focus_entered, b.focus_exited, b.mouse_entered, b.mouse_exited]:
		sig.connect(m.queue_redraw)

## La luz de vela de los botones elegidos parpadea un poco (todos a la vez: es la misma vela).
static func _start_flicker() -> void:
	if _ticking: return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null: return
	_ticking = true
	tree.process_frame.connect(func() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var f := 0.82 + 0.1 * sin(t * 7.3) + 0.06 * sin(t * 17.9 + 1.3) + 0.04 * sin(t * 31.0)
		for i in range(_lit.size() - 1, -1, -1):
			var sb := _lit[i]
			if sb.get_reference_count() <= 2:          # solo quedan esta lista y `sb`: el botón ya no existe
				_lit.remove_at(i)
			elif sb is StyleBoxFlat:
				(sb as StyleBoxFlat).shadow_color = Color(CANDLE, 0.3 * f)
			else:
				(sb as StyleBoxTexture).modulate_color = Color(1, 1, 1, f)
		for i in range(_panels.size() - 1, -1, -1):
			if (_panels[i][0] as WeakRef).get_ref() == null: _panels.remove_at(i)
			else: (_panels[i][1] as ShaderMaterial).set_shader_parameter("glow", f / 0.82))

## Separador de latón (bajo el título de una ventana).
static func divider(width: float = 380.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = DIVIDER
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(width, width * DIVIDER.get_height() / DIVIDER.get_width())
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate = Color(1, 1, 1, 0.9)
	return r

## Título de ventana con su separador debajo, pegado a él.
static func heading(parent: Container, text: String, size: int = 44, color: Color = INK) -> Label:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -int(size * 0.18))
	parent.add_child(v)
	var t := title(text, size, color)
	v.add_child(t)
	v.add_child(divider(clampf(size * 7.0, 240.0, 380.0)))
	return t

## Estilo de una fila de opciones (OptionRow) o de una pestaña: sombría, con un filete abajo; con
## el foco, la luz de vela de los botones.
static func style_row(b: Button, selected := false) -> void:
	var normal := box(Color(0.05, 0.036, 0.028, 0.75 if selected else 0.45), Color(BRASS, 0.75 if selected else 0.22), 1)
	normal.content_margin_left = 14
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("disabled", normal)
	var lit := lit_box(BRASS, 10)
	lit.content_margin_left = 14
	for s in ["hover", "focus", "pressed"]: b.add_theme_stylebox_override(s, lit)
	_text_colors(b)

## Número con separador de miles: 1250 -> "1.250".
static func money(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

## "1 objeto", "4 objetos". `plural` vacío: se añade una "s".
static func count(n: int, singular: String, plural: String = "") -> String:
	return "%d %s" % [n, singular if n == 1 else (plural if plural != "" else singular + "s")]

## Ventana centrada: fondo oscurecido que tapa la pantalla y un panel con su contenido.
## Devuelve [capa, caja vertical del contenido].
static func window(parent: Node, accent: Color = INK, min_width: float = 0.0) -> Array:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(root)
	root.theme = theme()
	var dim := veil()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP       # tapa lo de detrás también para el ratón
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = min_width
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	dress(panel, brass_for(accent))
	appear(panel)
	return [root, box]

## Viste un panel de madera y latón (gothic_panel.gdshader) con las esquinas de filigrana: lo
## que ya tenga dentro pasa a un margen; debajo, la madera y, encima, las esquinas. Sirve para un
## PanelContainer (ventanas, selector de mejoras, depuración) o un Panel suelto (la ficha).
## `brass`: el color del latón (el de un jugador, mezclado, en cooperativo).
static func dress(panel: Control, brass: Color = BRASS, margin := Vector2(46, 34), corner := 150.0) -> void:
	var kids := panel.get_children()
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var bg := ColorRect.new()                     # madera y latón (el shader sigue su tamaño)
	var pm := ShaderMaterial.new()
	pm.shader = PANEL_SHADER
	pm.set_shader_parameter("brass", brass)
	bg.material = pm
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.resized.connect(func() -> void: pm.set_shader_parameter("size", bg.size))
	panel.add_child(bg)
	_panels.append([weakref(bg), pm])
	_start_flicker()
	panel.move_child(bg, 0)
	if panel is PanelContainer:                   # el contenido, dentro de un margen
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", int(margin.x))
		m.add_theme_constant_override("margin_right", int(margin.x))
		m.add_theme_constant_override("margin_top", int(margin.y))
		m.add_theme_constant_override("margin_bottom", int(margin.y - 2))
		m.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_child(m)
		for k in kids:
			panel.remove_child(k)
			m.add_child(k)
	else:
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var corners := Control.new()                  # esquinas de filigrana, encima del marco
	corners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(corners)
	if not panel is Container: corners.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.set_meta("gothic", [pm, corners])
	var tint := _corner_tint(brass)
	for k in 4:
		var c := TextureRect.new()
		c.texture = CORNER
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_SCALE
		c.flip_h = k % 2 == 1
		c.flip_v = k >= 2
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.anchor_left = float(k % 2); c.anchor_right = c.anchor_left
		c.anchor_top = float(k / 2); c.anchor_bottom = c.anchor_top
		corners.add_child(c)
	var fit := func() -> void:                    # en ventanas bajas las esquinas encogen: no tapan el texto
		var w := minf(corner, minf(corners.size.x, corners.size.y) * 0.32) if corners.size.y > 0.0 else corner
		var h := w * CORNER.get_height() / CORNER.get_width()
		var inset := w * 0.04
		for k in 4:
			var c := corners.get_child(k) as Control
			var x0 := -inset if k % 2 == 0 else -w + inset
			var y0 := -inset if k < 2 else -h + inset
			c.offset_left = x0; c.offset_right = x0 + w
			c.offset_top = y0; c.offset_bottom = y0 + h
	corners.resized.connect(fit)
	fit.call()
	corners.modulate = tint

## Cambia el latón (y la opacidad) de un panel vestido con dress(): la selección de personaje lo
## enciende con el color del jugador al unirse y al estar listo.
static func retint(panel: Control, brass: Color, alpha := 0.97) -> void:
	var g: Array = panel.get_meta("gothic", [])
	if g.is_empty(): return
	(g[0] as ShaderMaterial).set_shader_parameter("brass", brass)
	(g[0] as ShaderMaterial).set_shader_parameter("alpha", alpha)
	(g[1] as Control).modulate = _corner_tint(brass)

static func _corner_tint(brass: Color) -> Color:
	return Color(clampf(brass.r / BRASS.r, 0, 1.6), clampf(brass.g / BRASS.g, 0, 1.6), clampf(brass.b / BRASS.b, 0, 1.6))

## Entrada de una ventana: un fundido y un pequeño acercamiento.
static func appear(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.resized.connect(func() -> void: panel.pivot_offset = panel.size * 0.5)
	var start := func() -> void:
		if not is_instance_valid(panel) or not panel.is_inside_tree(): return   # se cerró antes de empezar
		panel.scale = Vector2(0.975, 0.975)
		var tw := panel.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(panel, "modulate:a", 1.0, 0.18)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.22)
	if panel.is_inside_tree(): start.call_deferred()       # se abrió con el menú ya en escena
	else: panel.ready.connect(start, CONNECT_ONE_SHOT)
	Auto.sfx("menu_open")                                   # una página al abrirse
	panel.tree_exiting.connect(func() -> void: _closed(panel))

## Sonido al cerrarse una ventana, solo si se cierra para volver (B, Esc, «Cancelar»…): no si se
## acaba de aceptar algo (ya sonó) ni si se va toda la escena (al empezar la partida o salir).
static func _closed(panel: Control) -> void:
	var n: Node = panel                           # cerrar es borrarla (queue_free) a ella o a un padre;
	while n != null and not n.is_queued_for_deletion():   # al cambiar de escena solo se quita del árbol
		n = n.get_parent()
	if n == null: return
	var sfx := Auto.node("Sfx")
	if sfx == null or Time.get_ticks_msec() - int(sfx.get("last_accept_ms")) < 300: return
	Auto.sfx("ui_back")

## Línea de ayuda de controles al pie de una ventana.
static func hint(text: String) -> Label:
	var l := UiKit.label(text, 17, UiKit.TEXT_DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Confirmación de sí o no. El foco empieza en "no" (lo seguro). B / Esc también es "no".
## Encierra el foco en una ventana mientras está abierta: los controles de detrás dejan de
## poder recibirlo y, al cerrarse, lo recuperan. Sin esto, el mando (que busca el control más
## cercano en la dirección pulsada) saltaba a los botones de detrás de la ventana.
static func trap_focus(root: Control) -> void:
	var saved := {}                              # id del control -> su focus_mode
	for c in root.get_tree().root.find_children("*", "Control", true, false):
		var ctl := c as Control
		if ctl == root or root.is_ancestor_of(ctl) or ctl.focus_mode == Control.FOCUS_NONE: continue
		saved[ctl.get_instance_id()] = ctl.focus_mode
		ctl.focus_mode = Control.FOCUS_NONE
	root.tree_exiting.connect(func() -> void:
		for id in saved:
			var o := instance_from_id(id)
			if o != null and is_instance_valid(o): (o as Control).focus_mode = saved[id])

## Lista vertical: arriba y abajo recorren las filas y no salen de ella por los extremos.
static func chain_focus(rows: Array) -> void:
	for i in rows.size():
		var r := rows[i] as Control
		r.focus_neighbor_top = r.get_path_to(rows[maxi(i - 1, 0)])
		r.focus_neighbor_bottom = r.get_path_to(rows[mini(i + 1, rows.size() - 1)])
		r.focus_neighbor_left = r.get_path_to(r)
		r.focus_neighbor_right = r.get_path_to(r)

class Confirm extends Control:
	signal answered(yes: bool)
	var _text := ""
	var _yes := ""
	var _no := ""
	var _accent := DANGER
	var _no_button: Button

	func _init(p_text: String, p_yes: String, p_no: String = "Cancelar", p_accent: Color = DANGER) -> void:
		_text = p_text; _yes = p_yes; _no = p_no; _accent = p_accent
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _ready() -> void:
		var w: Array = MenuKit.window(self, _accent, 640)
		var box: VBoxContainer = w[1]
		var l := UiKit.label(_text, 24, UiKit.TEXT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 560
		box.add_child(l)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		box.add_child(row)
		_no_button = MenuKit.button(_no, UiKit.GOLD, 26)
		_no_button.custom_minimum_size = Vector2(220, 58)
		_no_button.pressed.connect(_answer.bind(false))
		row.add_child(_no_button)
		var yes := MenuKit.button(_yes, _accent, 26)
		yes.custom_minimum_size = Vector2(220, 58)
		yes.pressed.connect(_answer.bind(true))
		row.add_child(yes)
		# izquierda y derecha pasan de un botón al otro; arriba y abajo no se van a ningún sitio
		for b: Button in [_no_button, yes]:
			var other := yes if b == _no_button else _no_button
			b.focus_neighbor_left = b.get_path_to(other)
			b.focus_neighbor_right = b.get_path_to(other)
			b.focus_neighbor_top = b.get_path_to(b)
			b.focus_neighbor_bottom = b.get_path_to(b)
		MenuKit.trap_focus(self)
		_no_button.grab_focus.call_deferred()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_answer(false)

	func _answer(yes: bool) -> void:
		answered.emit(yes)
		queue_free()
