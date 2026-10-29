class_name PactMenu
extends Control
## Pactos del Necronomicón (hito 13.6): ventana para sellar hasta tres antes del nivel. Cada
## fila, un pacto con su maldición y su premio (y un sello si ya se superó este nivel con él);
## A lo sella o lo rompe. Abajo, «Sellar y jugar» (o «Jugar sin pactos») y B / Esc vuelve sin
## cambiar nada. `done` da los sellados.

signal done(ids: Array)
signal closed

var level_id := ""                          ## para enseñar los superados aquí
var picked: Array = []
var _rows := {}                             ## id -> Button
var _go: Button
var _count: Label

func _init(p_level := "", p_picked: Array = []) -> void:
	level_id = p_level
	picked = Pacts.clean(p_picked)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, Color(0.55, 0.12, 0.12), 1180)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Pactos del Necronomicón", 46, Color(0.85, 0.25, 0.2))
	_count = UiKit.label("", 20, UiKit.TEXT_DIM)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_count)
	var won := Pacts.won_on(Saves.current, level_id)
	var buttons: Array = []
	for p: Dictionary in Pacts.all():
		var b := MenuKit.button("", MenuKit.INK, 20)
		b.custom_minimum_size = Vector2(1100, 72)
		var col := VBoxContainer.new()                   # dos líneas: nombre, y maldición → premio
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.offset_left = 22; col.offset_right = -18; col.offset_top = 6; col.offset_bottom = -6
		col.add_theme_constant_override("separation", 0)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(col)
		var name_l := UiKit.label("", 22, UiKit.TEXT)
		name_l.add_theme_font_override("font", MenuKit.body_font(true))
		col.add_child(name_l)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		col.add_child(line)
		var curse := UiKit.label(String(p.curse), 18, Color(0.88, 0.5, 0.44))
		var arrow := UiKit.label("→", 18, UiKit.TEXT_DIM)
		var reward := UiKit.label(String(p.reward), 18, UiKit.GOLD)
		for l: Label in [curse, arrow, reward]:
			l.add_theme_font_override("font", MenuKit.body_font(false))
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.add_child(l)
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.set_meta("name_l", name_l)
		var id := String(p.id)
		b.pressed.connect(func() -> void: _toggle(id))
		b.set_meta("pact", p)
		b.set_meta("won", won.has(id))
		_rows[id] = b
		box.add_child(b)
		buttons.append(b)
	_go = MenuKit.button("", MenuKit.INK, 26)
	_go.custom_minimum_size = Vector2(420, 58)
	_go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_go.pressed.connect(func() -> void:
		done.emit(picked.duplicate())
		queue_free())
	box.add_child(_go)
	buttons.append(_go)
	MenuKit.chain_focus(buttons)
	box.add_child(MenuKit.hint("A o Intro: sellar o romper  ·  B o Esc: volver"))
	_refresh()
	(buttons[0] as Control).grab_focus.call_deferred()

func _toggle(id: String) -> void:
	if picked.has(id): picked.erase(id)
	elif picked.size() < Pacts.max_count(): picked.append(id)
	else:
		Auto.sfx("ui_back")
		return
	Auto.sfx("page")
	_refresh()

func _refresh() -> void:
	for id in _rows:
		var b: Button = _rows[id]
		var p: Dictionary = b.get_meta("pact")
		var on := picked.has(id)
		var name_l: Label = b.get_meta("name_l")
		name_l.text = "%s%s%s" % ["✦  " if on else "○  ", p.name, "   · superado aquí" if bool(b.get_meta("won")) else ""]
		name_l.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4) if on else UiKit.TEXT)
	_count.text = "Hasta %d maldiciones, cada una con su premio. Duran hasta que las cambies.  ·  Selladas: %d de %d" % [
		Pacts.max_count(), picked.size(), Pacts.max_count()]
	_go.text = "Jugar sin pactos" if picked.is_empty() else "Sellar y jugar"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
