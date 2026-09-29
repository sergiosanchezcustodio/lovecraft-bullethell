class_name ShopMenu
extends Control
## Tienda (D-31, hito 2.13b): cuatro pestañas (potenciadores, personajes, compañeros y
## mejoras) con lo que hay, su nivel, lo que cuesta el siguiente y lo que hace. A compra (con
## confirmación), LB/RB o Q/E cambian de pestaña y B / Esc cierra. Lo comprado se guarda al
## momento. El fondo es provisional: la tienda de antigüedades con el anciano llega en el
## hito 2.13d.

signal closed

var save: SaveData
var _tab := 0
var _tabs: Array[Button] = []
var _list: VBoxContainer
var _money: Label
var _note: Label
var _first: Control
var _focus_id := ""                          ## artículo a enfocar al redibujar (tras comprar)

func _ready() -> void:
	if save == null: save = Saves.current
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, UiKit.GOLD, 980)
	var box: VBoxContainer = w[1]
	box.add_child(MenuKit.title("Tienda", 48))
	_money = UiKit.label("", 24, UiKit.GOLD)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_money)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 12)
	box.add_child(tabs)
	for i in Shop.SECTIONS.size():
		var b := MenuKit.button(Shop.SECTIONS[i], UiKit.GOLD, 24)
		b.custom_minimum_size = Vector2(210, 50)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_show_tab.bind(i))
		tabs.add_child(b)
		_tabs.append(b)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(920, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_right", 14)
	scroll.add_child(margin)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	margin.add_child(_list)
	_note = UiKit.label("", 18, UiKit.TEXT)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_note)
	box.add_child(MenuKit.hint("Arriba/abajo: elegir  ·  A o Intro: comprar  ·  LB/RB o Q/E: pestaña  ·  B o Esc: volver"))
	_show_tab(0)

func _show_tab(i: int) -> void:
	_tab = i
	for k in _tabs.size():
		_tabs[k].add_theme_color_override("font_color", UiKit.GOLD if k == i else UiKit.TEXT_DIM)
		_tabs[k].add_theme_stylebox_override("normal", UiKit.panel(Color(0.1, 0.1, 0.13, 0.95) if k == i else Color(0.05, 0.05, 0.07, 0.8),
			Color(UiKit.GOLD, 0.8 if k == i else 0.2)))
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_first = null
	var focus: Control = null
	for e in Shop.in_section(i):
		var row := _row(e)
		if _first == null: _first = row
		if e.id == _focus_id: focus = row
	_money.text = "Dinero: %s $" % MenuKit.money(save.money if save else 0)
	var target := focus if focus != null else _first
	if target: target.grab_focus.call_deferred()

## Fila de un artículo: nombre y nivel, precio del siguiente, y lo que hace debajo.
func _row(e: Shop.Entry) -> Button:
	var lv := Shop.level_of(save, e)
	var maxed := Shop.is_maxed(save, e)
	var price := Shop.next_price(save, e)
	var afford := Shop.can_buy(save, e)
	var b := MenuKit.button("", UiKit.GOLD, 22)
	b.custom_minimum_size = Vector2(880, 92)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16; h.offset_right = -16; h.offset_top = 8; h.offset_bottom = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(col)
	var name := e.name
	if e.prices.size() > 1:                                   # potenciadores: nivel en puntos
		name += "   " + "●".repeat(lv) + "○".repeat(e.prices.size() - lv)
	col.add_child(UiKit.label(name, 22, UiKit.TEXT))
	var d := UiKit.label(e.description, 15, UiKit.TEXT_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 640
	col.add_child(d)
	var tag := ""
	var color := UiKit.GOLD
	if maxed:
		tag = "Comprado" if e.prices.size() == 1 else "Completo"
		color = UiKit.XP
	else:
		tag = "%s $" % MenuKit.money(price)
		if not afford: color = UiKit.TEXT_DIM
	var t := UiKit.label(tag, 24, color)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	b.pressed.connect(_try_buy.bind(e))
	_list.add_child(b)
	return b

func _try_buy(e: Shop.Entry) -> void:
	_focus_id = e.id
	if Shop.is_maxed(save, e):
		_say("Ya lo tienes.")
		return
	var price := Shop.next_price(save, e)
	if not Shop.can_buy(save, e):
		_say("Te faltan %s $." % MenuKit.money(price - save.money))
		return
	var what := e.name if e.prices.size() == 1 else "%s (nivel %d)" % [e.name, Shop.level_of(save, e) + 1]
	var c := MenuKit.Confirm.new("¿Comprar %s por %s $?" % [what, MenuKit.money(price)], "Comprar", "Cancelar", UiKit.GOLD)
	add_child(c)
	c.answered.connect(func(yes: bool) -> void:
		if yes and Shop.buy(save, e):
			Saves.save()
			_say("Comprado: %s." % e.name)
		_show_tab(_tab))

func _say(text: String) -> void:
	_note.text = text
	_note.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_note, "modulate:a", 0.0, 0.6)

func _unhandled_input(event: InputEvent) -> void:
	if get_child_count() > 1 and get_child(get_child_count() - 1) is MenuKit.Confirm: return
	var tab_step := 0
	if event is InputEventJoypadButton and event.pressed:
		var b := (event as InputEventJoypadButton).button_index
		if b == JOY_BUTTON_LEFT_SHOULDER: tab_step = -1
		elif b == JOY_BUTTON_RIGHT_SHOULDER: tab_step = 1
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_Q: tab_step = -1
		elif k == KEY_E: tab_step = 1
	if tab_step != 0:
		get_viewport().set_input_as_handled()
		_focus_id = ""
		_show_tab(posmod(_tab + tab_step, Shop.SECTIONS.size()))
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
