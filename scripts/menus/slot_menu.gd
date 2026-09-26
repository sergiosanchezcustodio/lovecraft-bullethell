class_name SlotMenu
extends Control
## Ventana de huecos de partida (tras la portada): tres huecos con su resumen (tiempo
## jugado, objetos comprados, compañeros desbloqueados y dinero) y, debajo de cada uno
## con partida, un botón para borrarlo con confirmación. Elegir un hueco vacío empieza
## una partida nueva. B / Esc cierra la ventana.

signal chosen(slot: int)
signal closed

var _cards: Array[Button] = []
var _deletes: Array[Button] = []
var _root: Control
var _busy := false                       ## hay una confirmación abierta

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build(0)

func _build(focus_slot: int) -> void:
	if _root: _root.queue_free()
	_cards.clear()
	_deletes.clear()
	var w: Array = MenuKit.window(self)
	_root = w[0]
	var box: VBoxContainer = w[1]
	box.add_child(MenuKit.title("Elige partida", 52))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	for i in Saves.SLOTS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		row.add_child(col)
		var d: SaveData = Saves.peek(i)
		var card := _card(i, d)
		col.add_child(card)
		_cards.append(card)
		var del := MenuKit.button("Borrar", MenuKit.DANGER, 22)
		del.custom_minimum_size = Vector2(0, 50)
		del.pressed.connect(_ask_delete.bind(i, d))
		# sin partida no hay nada que borrar, pero se reserva el hueco para que no bailen
		del.modulate.a = 1.0 if d != null else 0.0
		del.disabled = d == null
		del.focus_mode = Control.FOCUS_ALL if d != null else Control.FOCUS_NONE
		col.add_child(del)
		_deletes.append(del)
	box.add_child(MenuKit.hint("Flechas o cruceta: moverse  ·  A o Intro: elegir  ·  B o Esc: volver"))
	_cards[clampi(focus_slot, 0, _cards.size() - 1)].grab_focus.call_deferred()

func _card(i: int, d: SaveData) -> Button:
	var b := MenuKit.button("", MenuKit.INK, 24)
	b.custom_minimum_size = Vector2(380, 300)
	b.pressed.connect(func() -> void:
		if _busy: return
		chosen.emit(i))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 22; v.offset_right = -22; v.offset_top = 18; v.offset_bottom = -18
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var t := MenuKit.title("Partida %d" % (i + 1), 34)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	if d == null:
		var gap := Control.new(); gap.custom_minimum_size.y = 40
		v.add_child(gap)
		var e := UiKit.label("Vacía", 26, UiKit.TEXT_DIM)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(e)
		var n := UiKit.label("Empezar una partida nueva", 19, UiKit.TEXT_DIM)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
	else:
		for pair in [["Tiempo jugado", SaveData.format_time(d.play_time)], ["Objetos comprados", str(d.items_bought())],
				["Compañeros", str(d.pets.size())], ["Dinero", MenuKit.money(d.money)]]:
			v.add_child(_line(pair[0], pair[1]))
	for c in v.get_children(): (c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _line(label: String, value: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a := UiKit.label(label, 20, UiKit.TEXT_DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(a)
	var b := UiKit.label(value, 22, UiKit.GOLD)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(b)
	return h

func _ask_delete(i: int, d: SaveData) -> void:
	if _busy or d == null: return
	_busy = true
	var c := MenuKit.Confirm.new("¿Borrar la Partida %d?\n\nSe perderá todo su progreso: %s de juego, %s de dinero, %s y %s." % [
		i + 1, SaveData.format_time(d.play_time), MenuKit.money(d.money), MenuKit.count(d.items_bought(), "objeto"),
		MenuKit.count(d.pets.size(), "compañero")], "Borrar")
	add_child(c)
	c.answered.connect(func(yes: bool) -> void:
		_busy = false
		if yes:
			Saves.delete(i)
			_build(i)
		else:
			_deletes[i].grab_focus.call_deferred())

## Abre la confirmación del primer hueco con partida (capturas: `open=slots_borrar`).
func ask_first_delete() -> void:
	for i in Saves.SLOTS:
		var d: SaveData = Saves.peek(i)
		if d != null:
			_ask_delete(i, d)
			return

func _unhandled_input(event: InputEvent) -> void:
	if _busy: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
