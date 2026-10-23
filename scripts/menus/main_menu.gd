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
	col.add_theme_constant_override("separation", 12)
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	col.custom_minimum_size = Vector2(380, 0)
	add_child(col)
	var opts := [["Jugar", _open_play], ["Tienda", _open_shop], ["Biblioteca", _open_library],
			["Configuración", _open_settings], ["Salir", _ask_quit]]
	if Review.available(): opts.insert(4, ["Revisión de arte (temporal)", _open_review])   # solo en desarrollo
	for pair in opts:
		var b := MenuKit.button(pair[0], MenuKit.INK, 30)
		b.custom_minimum_size = Vector2(380, 54)
		b.pressed.connect(pair[1])
		col.add_child(b)
		_buttons.append(b)
	col.resized.connect(func() -> void:
		var vs := get_viewport().get_visible_rect().size
		col.position = Vector2((vs.x - col.size.x) * 0.5, vs.y * 0.6))
	# partida en uso, abajo a la izquierda
	if Saves.slot >= 0:
		var l := UiKit.label("", 20, UiKit.TEXT_DIM)
		_money_lbl = l
		_refresh_money()
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		l.offset_left = 24
		l.offset_top = -44
		add_child(l)
	var ver := UiKit.label("v" + String(ProjectSettings.get_setting("application/config/version", "?")), 18, UiKit.TEXT_DIM)
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
	_buttons[0].grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _popup != null: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back.emit()

var _money_lbl: Label

func _refresh_money() -> void:
	if _money_lbl != null and Saves.current != null:
		_money_lbl.text = "Partida %d  ·  %s $" % [Saves.slot + 1, MenuKit.money(Saves.current.money)]

## Abre una ventana encima; al cerrarse, el foco vuelve al botón que la abrió.
func _push(popup: Control, from: int) -> void:
	_popup = popup
	add_child(popup)
	MenuKit.trap_focus(popup)                  # el mando no se escapa a los botones de detrás
	popup.tree_exited.connect(func() -> void:
		_popup = null
		_refresh_money()                           # la tienda y los logros cambian el dinero
		if is_inside_tree(): _buttons[from].grab_focus.call_deferred())

# ---------------------------------------------------------------- opciones

func _open_play() -> void:
	var p := Control.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(p, MenuKit.INK, 560)
	var box: VBoxContainer = w[1]
	box.add_child(MenuKit.title("Jugar", 46))
	var local := MenuKit.button("Jugar en local", MenuKit.INK, 30)
	local.custom_minimum_size = Vector2(480, 64)
	local.pressed.connect(func() -> void: play_local.emit())
	box.add_child(local)
	var online := MenuKit.button("Jugar online", MenuKit.INK, 30)
	online.custom_minimum_size = Vector2(480, 64)
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
