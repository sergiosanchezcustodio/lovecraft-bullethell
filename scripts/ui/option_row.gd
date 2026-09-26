class_name OptionRow
extends Button
## Fila de un menú de opciones: título a la izquierda y valor a la derecha ("◀ valor ▶").
## El valor se cambia con izquierda/derecha o con confirmar (A / Intro). Sin valores, la
## fila es una acción que se ejecuta al confirmar. La usan la configuración y la depuración.

var title := ""
var names: Array[String] = []
var index := 0
var on_change: Callable
var run: Callable
var _value: Label

func _init(p_title: String, p_names: Array[String], p_index: int, p_on_change: Callable, p_run: Callable,
		accent: Color = UiKit.GOLD, action_accent: Color = Color(0.45, 0.9, 0.75)) -> void:
	title = p_title; names = p_names; index = p_index; on_change = p_on_change; run = p_run
	var styled := UiKit.button("", action_accent if run.is_valid() else accent, 18)
	for s in ["normal", "hover", "focus", "pressed", "disabled"]:
		add_theme_stylebox_override(s, styled.get_theme_stylebox(s if s != "disabled" else "normal"))
	for c in ["font_color", "font_focus_color", "font_hover_color"]:
		add_theme_color_override(c, styled.get_theme_color(c))
	add_theme_color_override("font_disabled_color", UiKit.TEXT_DIM)
	styled.free()
	add_theme_font_size_override("font_size", 18)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(0, 40)
	text = ("▸ " if run.is_valid() else "") + title
	_value = UiKit.label("", 18, UiKit.GOLD)
	_value.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_value.offset_left = -420
	_value.offset_right = -12
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_value)
	pressed.connect(func() -> void:
		if run.is_valid(): run.call()
		else: step(1))
	_show()

func _gui_input(event: InputEvent) -> void:
	if names.is_empty(): return
	if event.is_action_pressed("ui_left", true):
		step(-1)
		accept_event()
	elif event.is_action_pressed("ui_right", true):
		step(1)
		accept_event()

func step(dir: int) -> void:
	if names.is_empty() or disabled: return
	index = posmod(index + dir, names.size())
	_show()
	on_change.call(index)

## Cambia el texto del valor sin llamar a on_change (p. ej. "Pulsa una tecla…").
func set_value_text(t: String) -> void:
	_value.text = t

func _show() -> void:
	_value.text = "" if names.is_empty() else "◀  %s  ▶" % names[index]

## Nombres de una lista de números: `pattern` con %d (entero) o %s (hasta dos decimales).
static func fmt(vals: Array, pattern: String, k: float = 1.0) -> Array[String]:
	var out: Array[String] = []
	for v in vals:
		var x := float(v) * k
		out.append(pattern % (int(round(x)) if pattern.contains("%d") else String.num(snappedf(x, 0.01))))
	return out

## Posición de `v` en `vals` o, si no está, `fallback`.
static func idx(vals: Array, v: Variant, fallback: int) -> int:
	var i := vals.find(v)
	return i if i >= 0 else fallback
