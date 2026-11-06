class_name MainMenu
extends Control
## Menú principal, debajo del título de la portada: Jugar, Tienda, Biblioteca (con los logros como un tomo), Configuración y Salir.
## Quieto a propósito (GDD 8.1): lo importante es qué opción está señalada.
## Jugar abre la elección de local u online (online desde la fase 9, D-10).
## B / Esc vuelve a la elección de partida.

signal play_local
signal back                               ## volver a la ventana de huecos

var _buttons: Array[Button] = []
var _popup: Control                       ## ventana abierta encima (jugar, tienda, configuración, salir)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	col.custom_minimum_size = Vector2(380, 0)
	add_child(col)
	var opts := [["Jugar", _open_play], ["Tienda", _open_shop], ["Biblioteca", _open_library],
			["Configuración", _open_settings], ["Salir", _ask_quit]]
	if Review.available(): opts.insert(4, ["Revisión de arte (temporal)", _open_review])   # solo en desarrollo
	for pair in opts:
		var b := MenuKit.plain_button(pair[0], 34)        # sin caja, sobre la ilustración (27-10-2026)
		b.custom_minimum_size = Vector2(380, 52)
		b.pressed.connect(pair[1])
		col.add_child(b)
		_buttons.append(b)
	col.resized.connect(func() -> void:
		var vs := get_viewport().get_visible_rect().size
		# al 60 % del alto, o más arriba si no cabe sobre la ayuda de abajo (interfaz Grande: «Salir» la pisaba)
		col.position = Vector2((vs.x - col.size.x) * 0.5, minf(vs.y * 0.6, vs.y - 52.0 - col.size.y)))
	# partida en uso, abajo a la izquierda
	if Saves.slot >= 0:
		var l := UiKit.label("", 20, UiKit.TEXT_DIM)
		_money_lbl = l
		_refresh_money()
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		l.offset_left = 24
		l.offset_top = -44
		add_child(l)
	var ver := UiKit.label(Demo.version_text(), 18, UiKit.TEXT_DIM)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)   # la versión: en red, la misma en todos los PC
	ver.offset_left = -140
	ver.offset_right = -24
	ver.offset_top = -44
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(ver)
	var h := MenuKit.hint("A o Intro: elegir  ·  B o Esc: cambiar de partida")
	h.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	h.offset_top = -40
	h.offset_left = -400
	h.offset_right = 400
	add_child(h)
	_hint = h
	_buttons[0].grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _popup != null: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back.emit()

var _money_lbl: Label
var _hint: Label                          ## ayuda de abajo: se esconde con una ventana abierta, que trae la suya

func _refresh_money() -> void:
	if _money_lbl != null and Saves.current != null:
		_money_lbl.text = "Partida %d  ·  %s $" % [Saves.slot + 1, MenuKit.money(Saves.current.money)]

## Abre una ventana encima; al cerrarse, el foco vuelve al botón que la abrió.
const LOGO_CLEAR := 560.0                       ## px de arriba que ocupa el logo (a 1080 de alto)

## Centra la ventana `root` (de MenuKit.window) en lo que queda bajo el logo, sin taparlo: centrada
## en la columna entera caía encima de «Surviving» (05-11-2026). `top`, en px a 1080 de alto. Si no
## cabe ahí (interfaz Grande o Muy grande), vuelve al centro de la pantalla.
static func below_logo(root: Control, top: float) -> void:
	for c in root.get_children():                   # el centrador; el velo sigue tapándolo todo
		if c is CenterContainer:
			var cc := c as Control
			var place := func() -> void:
				if not cc.is_inside_tree(): return
				var h := cc.get_viewport().get_visible_rect().size.y
				var a := top / 1080.0
				if cc.get_combined_minimum_size().y > h * (1.0 - a) - 16.0: a = 0.0
				if not is_equal_approx(cc.anchor_top, a):
					cc.anchor_top = a
					cc.offset_top = 0.0
			cc.minimum_size_changed.connect(place)
			cc.tree_entered.connect(place)
			if cc.is_inside_tree(): place.call()

func _push(popup: Control, from: int) -> void:
	_popup = popup
	add_child(popup)
	if _hint: _hint.visible = false            # con la interfaz Grande, Jugar bajaba hasta ella
	MenuKit.trap_focus(popup)                  # el mando no se escapa a los botones de detrás
	popup.tree_exited.connect(func() -> void:
		_popup = null
		if _hint: _hint.visible = true
		_refresh_money()                           # la tienda y los logros cambian el dinero
		if is_inside_tree(): _buttons[from].grab_focus.call_deferred())

# ---------------------------------------------------------------- opciones

func _open_play() -> void:
	var p := Control.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(p, MenuKit.INK, 560)
	below_logo(w[0], LOGO_CLEAR)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Jugar", 46)
	var local := MenuKit.button("Jugar en local", MenuKit.INK, 30)
	local.custom_minimum_size = Vector2(480, 64)
	local.pressed.connect(func() -> void: play_local.emit())
	box.add_child(local)
	var online := MenuKit.button("Jugar online" + ("  ·  " + Demo.LOCKED if Demo.on() else ""), MenuKit.INK, 24 if Demo.on() else 30)
	online.custom_minimum_size = Vector2(480, 64)
	online.disabled = Demo.on()                     # la demo (13.17): solo en local
	online.pressed.connect(func() -> void:          # sustituye a esta ventana al cerrarse
		p.tree_exited.connect(_open_online, CONNECT_ONE_SHOT)
		p.queue_free())
	box.add_child(online)
	box.add_child(MenuKit.hint("B o Esc: volver"))
	_closes_with_cancel(p)
	_push(p, 0)
	local.grab_focus.call_deferred()

## "Jugar online" (fase 9, D-10). Capturas y pruebas: `open=menu_online`.
func _open_online() -> void:
	if is_inside_tree(): _push(OnlineMenu.new(), 0)

func _open_shop() -> void:
	var s := ShopMenu.new()
	_push(s, 1)

## Tienda abierta en una pestaña (capturas: `open=menu_tienda tab=N`).
func open_shop_tab(tab: int) -> void:
	_open_shop()
	(_popup as ShopMenu)._show_tab.call_deferred(tab)

func _open_achievements() -> void:
	_push(AchievementsMenu.new(), 2)

func _open_library() -> void:
	_push(LibraryMenu.new(), 2)

## Biblioteca abierta en un tomo (capturas: `open=menu_biblioteca tome=N cursor=N`).
func open_library_at(tome: int, cursor: int) -> void:
	_open_library()
	if tome >= 0: (_popup as LibraryMenu).open_at.call_deferred(tome, cursor)

func _open_review() -> void:
	_push(ReviewMenu.new(), 4)

func _open_settings() -> void:
	var s := SettingsMenu.new()
	s.closed.connect(func() -> void: pass)
	_push(s, 3)

## Configuración abierta en una pestaña (capturas: `open=menu_config tab=N`).
func open_settings_tab(tab: int) -> void:
	_open_settings()
	(_popup as SettingsMenu)._show_tab.call_deferred(tab)

func _ask_quit() -> void:
	var c := MenuKit.Confirm.new("¿Salir del juego?", "Salir")
	c.answered.connect(func(yes: bool) -> void:
		if yes:
			Saves.save()
			get_tree().quit())
	_push(c, _buttons.size() - 1)

## Las ventanas sencillas se cierran con B / Esc.
func _closes_with_cancel(p: Control) -> void:
	var closer := _CancelCloser.new()
	p.add_child(closer)


## Cierra su ventana (el nodo padre) con B / Esc.
class _CancelCloser extends Node:
	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			get_parent().queue_free()
