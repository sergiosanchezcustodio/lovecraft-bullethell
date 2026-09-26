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
		_font = FontFile.new()
		_font.load_dynamic_font(FONT_PATH)
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
		_no_button.grab_focus.call_deferred()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_answer(false)

	func _answer(yes: bool) -> void:
		answered.emit(yes)
		queue_free()
