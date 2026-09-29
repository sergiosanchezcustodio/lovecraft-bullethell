class_name MainMenu
extends Control
## Menú principal, debajo del título de la portada: Jugar, Tienda, Configuración y Salir.
## Quieto a propósito (GDD 8.1): lo importante es qué opción está señalada.
## Jugar abre la elección de local u online (online, desactivado hasta la fase 9, D-24).
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
	for pair in [["Jugar", _open_play], ["Tienda", _open_shop], ["Configuración", _open_settings], ["Salir", _ask_quit]]:
		var b := MenuKit.button(pair[0], MenuKit.INK, 32)
		b.custom_minimum_size = Vector2(380, 60)
		b.pressed.connect(pair[1])
		col.add_child(b)
		_buttons.append(b)
	col.resized.connect(func() -> void:
		var vs := get_viewport().get_visible_rect().size
		col.position = Vector2((vs.x - col.size.x) * 0.5, vs.y * 0.64))
	# partida en uso, abajo a la izquierda
	if Saves.slot >= 0:
		var l := UiKit.label("Partida %d  ·  %s $" % [Saves.slot + 1, MenuKit.money(Saves.current.money)], 20, UiKit.TEXT_DIM)
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		l.offset_left = 24
		l.offset_top = -44
		add_child(l)
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

## Abre una ventana encima; al cerrarse, el foco vuelve al botón que la abrió.
func _push(popup: Control, from: int) -> void:
	_popup = popup
	add_child(popup)
	popup.tree_exited.connect(func() -> void:
		_popup = null
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
	var online := MenuKit.button("Jugar online  ·  Próximamente", MenuKit.INK, 26)
	online.custom_minimum_size = Vector2(480, 64)
	online.disabled = true
	online.add_theme_color_override("font_disabled_color", UiKit.TEXT_DIM)
	online.add_theme_stylebox_override("disabled", UiKit.panel(Color(0.04, 0.04, 0.05, 0.8), Color(UiKit.TEXT_DIM, 0.2)))
	box.add_child(online)
	box.add_child(MenuKit.hint("B o Esc: volver"))
	_closes_with_cancel(p)
	_push(p, 0)
	local.grab_focus.call_deferred()

func _open_shop() -> void:
	var s := ShopMenu.new()
	_push(s, 1)

## Tienda abierta en una pestaña (capturas: `open=menu_tienda tab=N`).
func open_shop_tab(tab: int) -> void:
	_open_shop()
	(_popup as ShopMenu)._show_tab.call_deferred(tab)

func _open_settings() -> void:
	var s := SettingsMenu.new()
	s.closed.connect(func() -> void: pass)
	_push(s, 2)

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
	_push(c, 3)

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
