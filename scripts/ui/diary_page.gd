class_name DiaryPage
extends Control
## Una página del diario del investigador (hito 13.10) sobre la pantalla final: papel, tinta y la
## entrada de este nivel. Con varios jugadores de este PC, izquierda/derecha pasan de uno a otro.
## B / Esc / A la cierran.

const PAPER := Color(0.86, 0.79, 0.64)
const INK := Color(0.2, 0.13, 0.08)
const INK_DIM := Color(0.42, 0.34, 0.25)

var entries: Array = []
var _k := 0
var _who: Label
var _title: Label
var _text: Label

func _init(p_entries: Array) -> void:
	entries = p_entries

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = MenuKit.theme()                          # EB Garamond, como los relatos
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.6)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var paper := PanelContainer.new()
	paper.custom_minimum_size = Vector2(820, 0)
	paper.add_theme_stylebox_override("panel", UiKit.panel(PAPER, Color(0.45, 0.3, 0.15), 3))
	cc.add_child(paper)
	var m := MarginContainer.new()
	for side in ["left", "right"]: m.add_theme_constant_override("margin_" + side, 56)
	for side in ["top", "bottom"]: m.add_theme_constant_override("margin_" + side, 40)
	paper.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	m.add_child(box)
	_who = UiKit.label("", 20, INK_DIM, false)
	_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_who)
	_title = UiKit.label("", 30, INK, false)
	_title.add_theme_font_override("font", MenuKit.font())
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	var rule := ColorRect.new()
	rule.color = Color(INK, 0.35)
	rule.custom_minimum_size = Vector2(0, 2)
	box.add_child(rule)
	_text = UiKit.label("", 24, INK, false)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 700
	box.add_child(_text)
	var hint := UiKit.label(("Izquierda/derecha: otro investigador  ·  " if entries.size() > 1 else "") + "A, B o Esc: cerrar", 16, INK_DIM, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	_show()
	get_viewport().gui_release_focus()               # A y B, para esta página y no para los botones de debajo
	modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(self, "modulate:a", 1.0, 0.25)
	Auto.sfx("page")

func _show() -> void:
	if entries.is_empty(): return
	var e: Dictionary = entries[_k]
	_who.text = "Diario de %s%s" % [String(e.who).get_slice("· ", 1) if "· " in String(e.who) else String(e.who),
		"  (%d / %d)" % [_k + 1, entries.size()] if entries.size() > 1 else ""]
	_title.text = String(e.title)
	_text.text = String(e.text)

func _unhandled_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_left") and entries.size() > 1:
		_k = posmod(_k - 1, entries.size())
		_show()
		Auto.sfx("page")
	elif event.is_action_pressed("ui_right") and entries.size() > 1:
		_k = posmod(_k + 1, entries.size())
		_show()
		Auto.sfx("page")
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		queue_free()
