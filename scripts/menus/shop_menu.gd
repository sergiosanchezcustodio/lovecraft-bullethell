class_name ShopMenu
extends Control
## Tienda (D-31, hito 2.13b): cuatro pestañas (potenciadores, personajes, compañeros y
## mejoras) con lo que hay, su nivel, lo que cuesta el siguiente y lo que hace. A compra (con
## confirmación), LB/RB o Q/E cambian de pestaña y B / Esc cierra. Lo comprado se guarda al
## momento. Detrás, la tienda de antigüedades con el anciano (ShopBackdrop).
## Vestuario (fase 14): una sección por hueco (izquierda/derecha), iconos dibujados de antemano
## (tools/iconos_vestuario.gd) y, a la izquierda, el probador (OutfitFitting) con la prenda marcada.
## La última sección, Conjuntos (14.8), compra de una vez lo que falta de cada uno, con descuento.

signal closed

var save: SaveData
var _tab := 0
var _tabs: Array[Button] = []
var _list: VBoxContainer
var _money: Label
var _note: Label
var _first: Control
var _focus_id := ""                          ## artículo a enfocar al redibujar (tras comprar)
const OUTFIT_TAB := int(ShopItem.Section.OUTFIT)
var _sub := 0                                ## sección del vestuario (OutfitData.Slot, o SETS_SUB)
const SETS_SUB := 6                          ## la sección de los conjuntos, tras los seis huecos
var _subs: HBoxContainer
var _sub_btns: Array[Button] = []
var _fitting: OutfitFitting
var _fitting_box: CenterContainer
var _hint: Label

func _ready() -> void:
	if save == null: save = Saves.current
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ShopBackdrop.new())                             # la tienda de antigüedades con el anciano
	var w: Array = MenuKit.window(self, UiKit.GOLD, 900)
	var box: VBoxContainer = w[1]
	var win_root: Control = w[0]
	(win_root.get_child(0) as ColorRect).color = Color(0, 0, 0.02, 0.12)   # sin oscurecer la escena
	(win_root.get_child(1) as Control).anchor_left = 0.47                  # la ventana, a la derecha
	MenuKit.heading(box, "Tienda", 48)
	_money = UiKit.label("", 24, UiKit.GOLD)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_money)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	for i in Shop.SECTIONS.size():
		var b := MenuKit.button(Shop.SECTIONS[i], UiKit.GOLD, 20)
		b.custom_minimum_size = Vector2(160, 46)          # caben las cinco pestañas
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_show_tab.bind(i))
		tabs.add_child(b)
		_tabs.append(b)
	_subs = HBoxContainer.new()                               # secciones del vestuario
	_subs.alignment = BoxContainer.ALIGNMENT_CENTER
	_subs.add_theme_constant_override("separation", 4)
	box.add_child(_subs)
	for k in OutfitData.SECTION_NAMES.size() + 1:              # y Conjuntos
		var b := MenuKit.button("", UiKit.GOLD, 15)
		b.custom_minimum_size = Vector2(0, 38)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: _show_sub(k))
		_subs.add_child(b)
		_sub_btns.append(b)
	_fitting_box = CenterContainer.new()                      # el probador, a la izquierda
	_fitting_box.anchor_right = 0.45
	_fitting_box.anchor_bottom = 1.0
	add_child(_fitting_box)
	_fitting = OutfitFitting.new()
	_fitting_box.add_child(_fitting)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(840, 520)
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
	_hint = MenuKit.hint("")
	box.add_child(_hint)
	var la := LaunchArgs.from_cmdline()                        # capturas: shop_sub=3 shop_char=2
	_sub = la.get_int("shop_sub", 0)
	for n in la.get_int("shop_char", 0): _fitting.next_character()
	_show_tab(0)

func _show_sub(k: int) -> void:
	_sub = k
	_focus_id = ""
	_show_tab(_tab)

func _show_tab(i: int) -> void:
	_tab = i
	for k in _tabs.size():
		_tabs[k].add_theme_color_override("font_color", UiKit.GOLD if k == i else UiKit.TEXT_DIM)
		_tabs[k].add_theme_stylebox_override("normal", MenuKit.box(Color(0.16, 0.1, 0.05, 0.9) if k == i else Color(0.04, 0.03, 0.025, 0.6),
			Color(MenuKit.BRASS, 0.85 if k == i else 0.25), 1))
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_first = null
	var focus: Control = null
	var rows: Array = []
	var outfits := i == OUTFIT_TAB
	_subs.visible = outfits
	_fitting_box.visible = outfits
	_hint.text = ("Arriba/abajo: elegir  ·  Izquierda/derecha: sección  ·  A o Intro: comprar  ·  X o R: investigador  ·  LB/RB: pestaña  ·  B: volver" if outfits
		else "Arriba/abajo: elegir  ·  A o Intro: comprar  ·  LB/RB o Q/E: pestaña  ·  B o Esc: volver")
	var entries := Shop.in_section(i)
	if outfits:
		var counts := {}
		for e in entries: counts[int(e.outfit.slot)] = int(counts.get(int(e.outfit.slot), 0)) + 1
		var sets_done := 0
		for s: Dictionary in OutfitSets.all():
			if OutfitSets.is_complete(save, s): sets_done += 1
		for k in _sub_btns.size():
			var mine := 0
			for e in entries:
				if int(e.outfit.slot) == k and Shop.is_maxed(save, e): mine += 1
			if k == SETS_SUB:
				_sub_btns[k].text = "Conjuntos %d/%d" % [sets_done, OutfitSets.all().size()]
			else:
				_sub_btns[k].text = "%s %d/%d" % [OutfitData.SECTION_NAMES[k], mine, int(counts.get(k, 0))]
			_sub_btns[k].visible = counts.has(k) or (k == SETS_SUB and not OutfitSets.all().is_empty())
			_sub_btns[k].add_theme_color_override("font_color", UiKit.GOLD if k == _sub else UiKit.TEXT_DIM)
			_sub_btns[k].add_theme_stylebox_override("normal", MenuKit.box(Color(0.16, 0.1, 0.05, 0.9) if k == _sub else Color(0.04, 0.03, 0.025, 0.6),
				Color(MenuKit.BRASS, 0.85 if k == _sub else 0.25), 1))
		entries = entries.filter(func(e: Shop.Entry) -> bool: return int(e.outfit.slot) == _sub)
		if _sub == SETS_SUB:
			for s: Dictionary in OutfitSets.all():
				var srow := _set_row(s)
				rows.append(srow)
				if _first == null: _first = srow
				if "set:" + String(s.id) == _focus_id: focus = srow
	for e in entries:
		var row := _row(e)
		rows.append(row)
		if _first == null: _first = row
		if e.id == _focus_id: focus = row
		if e.id in Shop.TOGGLES and Shop.level_of(save, e) > 0:   # el Pacto se rompe y se renueva
			var on := Shop.is_active(save, e.id)
			var tb := MenuKit.button(("Activo: sí (pulsa para romperlo)" if on else "Activo: no (pulsa para renovarlo)"),
				Color(0.85, 0.35, 0.95) if on else UiKit.TEXT_DIM, 20)
			tb.custom_minimum_size = Vector2(810, 44)
			tb.pressed.connect(func() -> void:
				save.toggles[e.id] = not Shop.is_active(save, e.id)
				Saves.save()
				_focus_id = e.id + ":toggle"
				_say("Pacto %s." % ("renovado" if Shop.is_active(save, e.id) else "roto"))
				_show_tab(_tab))
			_list.add_child(tb)
			rows.append(tb)
			if _focus_id == e.id + ":toggle": focus = tb
	MenuKit.chain_focus(rows)                                 # arriba y abajo no salen de la lista
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
	var compact := e.outfit != null                           # vestuario: filas más bajas, hay muchas
	b.custom_minimum_size = Vector2(810, 76 if compact else 92)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16; h.offset_right = -16; h.offset_top = 8; h.offset_bottom = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var pic := TextureRect.new()                              # imagen del artículo
	pic.texture = _icon(e)
	pic.custom_minimum_size = Vector2(60, 60) if compact else Vector2(76, 76)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(pic)                                          # comprado: lo dice la etiqueta, la imagen no se atenúa
	h.add_theme_constant_override("separation", 14)
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
	d.custom_minimum_size.x = 500
	col.add_child(d)
	# con tres líneas de descripción no cabe en 92 px: la fila crece con lo que lleva
	d.resized.connect(func() -> void:
		b.custom_minimum_size.y = maxf(76.0 if compact else 92.0, col.get_combined_minimum_size().y + 28.0))
	if compact:
		var slot_key: String = OutfitData.KEYS[int(e.outfit.slot)]
		b.focus_entered.connect(func() -> void: _fitting.show_worn({slot_key: String(e.outfit.id)}))
	var tag := ""
	var color := UiKit.GOLD
	if Demo.shop_locked(e):                                   # la demo (13.17)
		tag = "Juego completo"
		color = UiKit.TEXT_DIM
	elif maxed:
		tag = "Comprado" if e.prices.size() == 1 else "Completo"
		color = Color(0.45, 0.9, 0.35)                        # verde
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

## Fila de un conjunto (14.8): nombre, las prendas (las que faltan, en claro), iconos de cada una
## y lo que cuesta lo que falta. Marcada, el probador lo enseña entero.
func _set_row(s: Dictionary) -> Button:
	var done := OutfitSets.is_complete(save, s)
	var price := OutfitSets.price(save, s)
	var b := MenuKit.button("", UiKit.GOLD, 22)
	b.custom_minimum_size = Vector2(810, 96)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16; h.offset_right = -16; h.offset_top = 8; h.offset_bottom = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	b.add_child(h)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)
	col.add_child(UiKit.label(String(s.name), 22, UiKit.TEXT))
	var pics := HBoxContainer.new()                           # una imagen por prenda; las que faltan, apagadas
	pics.add_theme_constant_override("separation", 4)
	pics.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(pics)
	var missing := OutfitSets.missing(save, s)
	var names := PackedStringArray()
	for k: String in s.pieces:
		var o := OutfitData.find(String(s.pieces[k]))
		if o == null: continue
		names.append(o.display_name)
		var pic := TextureRect.new()
		pic.texture = o.icon()
		pic.custom_minimum_size = Vector2(40, 40)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if missing.has(String(o.id)): pic.modulate = Color(1, 1, 1, 0.35)
		pics.add_child(pic)
	var d := UiKit.label(", ".join(names), 14, UiKit.TEXT_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 520
	col.add_child(d)
	d.resized.connect(func() -> void: b.custom_minimum_size.y = maxf(96.0, col.get_combined_minimum_size().y + 20.0))
	var tag := "Completo"
	var color := Color(0.45, 0.9, 0.35)
	if not done:
		tag = "%s $" % MenuKit.money(price)
		color = UiKit.GOLD if OutfitSets.can_buy(save, s) else UiKit.TEXT_DIM
	var t := UiKit.label(tag, 24, color)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var worn := OutfitSets.as_worn(s)
	b.focus_entered.connect(func() -> void: _fitting.show_worn(worn))
	b.pressed.connect(_try_buy_set.bind(s))
	_list.add_child(b)
	return b

func _try_buy_set(s: Dictionary) -> void:
	_focus_id = "set:" + String(s.id)
	if OutfitSets.is_complete(save, s):
		_say("Ya tienes todo el conjunto.")
		return
	var price := OutfitSets.price(save, s)
	if not OutfitSets.can_buy(save, s):
		_say("Te faltan %s $." % MenuKit.money(price - save.money))
		return
	var n := OutfitSets.missing(save, s).size()
	var c := MenuKit.Confirm.new("¿Comprar %s (%d %s) por %s $?" % [String(s.name), n, "prenda" if n == 1 else "prendas", MenuKit.money(price)],
		"Comprar", "Cancelar", UiKit.GOLD)
	add_child(c)
	c.answered.connect(func(yes: bool) -> void:
		if yes and OutfitSets.buy(save, s):
			Saves.save()
			_say("Comprado: %s." % String(s.name))
		_show_tab(_tab))

## Imagen de un artículo: la dibujada o, si no hay, su modelo renderizado (una vez).
var _icons := {}
func _icon(e: Shop.Entry) -> Texture2D:
	if e.icon != null: return e.icon
	if e.icon_model == "": return null
	var key := e.icon_model + ":" + e.icon_mode
	if not _icons.has(key): _icons[key] = ModelIcon.make(self, e.icon_model, e.icon_mode, 160)
	return _icons[key]

func _try_buy(e: Shop.Entry) -> void:
	_focus_id = e.id
	if Demo.shop_locked(e):
		_say(Demo.LOCKED + ".")
		return
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

## En el vestuario, izquierda/derecha cambian de sección y X o R de investigador en el probador.
## En _input: la lista se queda con izquierda/derecha antes de que lleguen a _unhandled_input.
func _input(event: InputEvent) -> void:
	if _tab != OUTFIT_TAB or not is_visible_in_tree(): return
	if get_child_count() > 1 and get_child(get_child_count() - 1) is MenuKit.Confirm: return
	var step := 0
	if event.is_action_pressed("ui_left"): step = -1
	elif event.is_action_pressed("ui_right"): step = 1
	var visible_subs: Array[int] = []
	for k in _sub_btns.size():
		if _sub_btns[k].visible: visible_subs.append(k)
	if step != 0 and not visible_subs.is_empty():
		get_viewport().set_input_as_handled()
		_show_sub(visible_subs[posmod(visible_subs.find(_sub) + step, visible_subs.size())])
		return
	var swap: bool = (event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_X) 		or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_R)
	if swap:
		get_viewport().set_input_as_handled()
		_fitting.next_character()

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
