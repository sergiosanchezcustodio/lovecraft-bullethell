class_name MenuKit
extends RefCounted
## Piezas comunes de los menús de fuera de la partida (huecos, menú principal, tienda,
## configuración): la fuente de la portada para los títulos, ventanas centradas y el
## diálogo de confirmación. Los colores y botones salen de UiKit.

const FONT_PATH := "res://resources/fonts/IMFeENsc28P.ttf"
const INK := Color(0.93, 0.82, 0.58)          ## dorado viejo de la portada
const DANGER := Color(0.86, 0.3, 0.24)

static var _font: FontFile

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

## Botón con la fuente de la portada.
static func button(text: String, accent: Color = UiKit.GOLD, size: int = 28) -> Button:
	var b := UiKit.button(text, accent, size)
	b.add_theme_font_override("font", font())
	return b

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
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	var sb := UiKit.panel(Color(0.025, 0.028, 0.04, 0.95), Color(accent, 0.55), 10)
	sb.content_margin_left = 34; sb.content_margin_right = 34
	sb.content_margin_top = 26; sb.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size.x = min_width
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	return [root, box]

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
