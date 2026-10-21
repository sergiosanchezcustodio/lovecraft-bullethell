class_name OnlineMenu
extends Control
## "Jugar online" (hito 9.1, D-10): crear una sala o unirse a una con su código o su IP.
## La sala muestra los códigos (el de la red de casa y, si UPnP abrió el puerto, el de
## internet) y los conectados con su ping. La selección de personaje en red llega en el 9.2.
## B / Esc vuelve atrás (cerrando la sala o la conexión); desde la elección, cierra la ventana.
## Pruebas: `net_host=true` abre la sala al entrar y `net_join=<código|IP>` se une sola
## (con `open=menu_online` en la portada); `net_upnp=false` no toca el router.

var _box: VBoxContainer
var _view := ""                            ## "", "host" o "join"
var _status: Label
var _roster: VBoxContainer
var _codes: VBoxContainer
var _field: LineEdit
var _connect_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, MenuKit.INK, 720)
	_box = w[1]
	Net.roster_changed.connect(_fill_roster)
	Net.upnp_done.connect(_on_upnp)
	Net.failed.connect(_on_failed)
	Net.closed.connect(_on_closed)
	Net.joined.connect(_on_joined)
	_show_choice()
	var la := LaunchArgs.from_cmdline()
	if la.get_bool("net_host"): _host.call_deferred()
	elif la.has("net_join"):
		_show_join()
		_field.text = la.get_str("net_join")
		_connect.call_deferred()

func _exit_tree() -> void:
	if Net.state == NetSession.State.CONNECTING: Net.close()   # a medias no se queda nada abierto

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _view == "":
			queue_free()
		else:
			Net.close()
			_show_choice()

func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_status = null; _roster = null; _codes = null; _field = null; _connect_btn = null

func _button(text: String, cb: Callable) -> Button:
	var b := MenuKit.button(text, MenuKit.INK, 28)
	b.custom_minimum_size = Vector2(520, 60)
	b.pressed.connect(cb)
	var row := CenterContainer.new()
	row.add_child(b)
	_box.add_child(row)
	return b

func _text(text: String, size: int = 22, color: Color = UiKit.TEXT) -> Label:
	var l := UiKit.label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 640
	_box.add_child(l)
	return l

## Foco en el siguiente fotograma, si el control sigue ahí (al cambiar de vista en el mismo
## fotograma, el de la anterior ya no está).
func _focus(c: Control) -> void:
	var go := func() -> void: if is_instance_valid(c) and c.is_inside_tree(): c.grab_focus()
	go.call_deferred()

# ---------------------------------------------------------------- vistas

func _show_choice() -> void:
	_clear()
	_view = ""
	_box.add_child(MenuKit.title("Jugar online", 46))
	_text("Hasta cuatro jugadores en total, en uno o varios PC.", 20, UiKit.TEXT_DIM)
	var create := _button("Crear sala", _host)
	_button("Unirse a una sala", _show_join)
	_box.add_child(MenuKit.hint("B o Esc: volver"))
	_focus(create)

func _host() -> void:
	_clear()
	_view = "host"
	_box.add_child(MenuKit.title("Sala abierta", 44))
	_codes = VBoxContainer.new()
	_codes.add_theme_constant_override("separation", 6)
	_box.add_child(_codes)
	_box.add_child(MenuKit.title("En la sala", 28))
	_roster = VBoxContainer.new()
	_box.add_child(_roster)
	_text("La primera vez, Windows puede preguntar si deja pasar la conexión: acepta en redes privadas y públicas.", 17, UiKit.TEXT_DIM)
	var copy := _button("Copiar el código", _copy_code)
	_button("Cerrar la sala", func() -> void:
		Net.close()
		_show_choice())
	_box.add_child(MenuKit.hint("B o Esc: cerrar la sala"))
	_focus(copy)
	if Net.host(RoomCode.BASE_PORT, LaunchArgs.from_cmdline().get_bool("net_upnp", true)) != OK: return   # `failed` ya ha dicho por qué
	_fill_codes()
	_fill_roster()

func _show_join() -> void:
	_clear()
	_view = "join"
	_box.add_child(MenuKit.title("Unirse a una sala", 44))
	_text("Escribe el código que te ha dado el anfitrión (o su IP).", 20, UiKit.TEXT_DIM)
	_field = LineEdit.new()
	_field.placeholder_text = "K7Q2-M9XA   o   83.45.201.7"
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.custom_minimum_size = Vector2(520, 60)
	_field.add_theme_font_size_override("font_size", 28)
	_field.add_theme_stylebox_override("normal", UiKit.panel(Color(0.06, 0.06, 0.08, 0.95), Color(MenuKit.INK, 0.4)))
	_field.add_theme_stylebox_override("focus", UiKit.panel(Color(0.08, 0.08, 0.1, 0.95), Color(MenuKit.INK, 0.9)))
	_field.text_submitted.connect(func(_t: String) -> void: _connect())
	var row := CenterContainer.new()
	row.add_child(_field)
	_box.add_child(row)
	_connect_btn = _button("Conectar", _connect)
	_status = _text("", 20, UiKit.TEXT_DIM)
	_roster = VBoxContainer.new()
	_box.add_child(_roster)
	_box.add_child(MenuKit.hint("Intro: conectar  ·  Ctrl+V: pegar  ·  B o Esc: volver"))
	_focus(_field)

# ---------------------------------------------------------------- acciones

func _connect() -> void:
	if _field == null or Net.state == NetSession.State.CONNECTING: return
	var a := RoomCode.parse(_field.text)
	if a.is_empty():
		_status.text = "No reconozco ese código: revisa las letras (8, con o sin guion) o escribe la IP."
		_status.add_theme_color_override("font_color", MenuKit.DANGER)
		return
	_status.remove_theme_color_override("font_color")
	_status.text = "Conectando con %s:%d…" % [a.ip, a.port]
	if Net.join(a.ip, a.port) == OK: _connect_btn.disabled = true

func _copy_code() -> void:
	var c := Net.codes()
	var code: String = c.internet if c.internet != "" else c.lan
	if code == "": return
	DisplayServer.clipboard_set(code)
	if _status == null: _status = _text("", 18, UiKit.TEXT_DIM)
	_status.text = "Copiado: %s" % code

func _on_upnp(_ok: bool, _message: String) -> void:
	_fill_codes()

func _on_joined() -> void:
	if _view != "join": return
	_status.text = "Dentro. Esperando a que el anfitrión empiece…"
	_field.editable = false
	_fill_roster()

func _on_failed(reason: String) -> void:
	if _status == null: _status = _text("", 20, UiKit.TEXT_DIM)
	_status.text = reason
	_status.add_theme_color_override("font_color", MenuKit.DANGER)
	if _connect_btn != null: _connect_btn.disabled = false

func _on_closed(reason: String) -> void:
	if reason == "" or not is_inside_tree(): return       # la cerró este PC
	if _view == "join":
		var typed := _field.text if _field != null else ""
		_show_join()
		_field.text = typed                          # para reintentar sin escribirlo otra vez
	else: _show_choice()
	_on_failed(reason)

# ---------------------------------------------------------------- relleno

func _fill_codes() -> void:
	if _codes == null: return
	for c in _codes.get_children(): c.queue_free()
	var c := Net.codes()
	if c.lan != "": _codes.add_child(_code_line("En tu red (misma casa)", c.lan))
	if c.internet != "": _codes.add_child(_code_line("Por internet", c.internet))
	var up := UiKit.label("%s  ·  puerto %d (UDP)" % [Net.upnp_status, Net.port], 18, UiKit.TEXT_DIM)
	up.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_codes.add_child(up)
	if c.internet == "" and not Net.upnp_status.begins_with("Buscando"):
		var help := UiKit.label("Para jugar por internet: abre ese puerto en el router hacia %s, o usad Tailscale o ZeroTier y daos la IP que os asigne." % (Net.local_ip if Net.local_ip != "" else "este PC"), 17, UiKit.TEXT_DIM)
		help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		help.custom_minimum_size.x = 640
		_codes.add_child(help)

func _code_line(what: String, code: String) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.add_child(UiKit.label(what, 22, UiKit.TEXT_DIM))
	var c := UiKit.label(code, 40, MenuKit.INK)   # la fuente de la portada dibuja el 0 como una o
	row.add_child(c)
	return row

func _fill_roster() -> void:
	if _roster == null: return
	for c in _roster.get_children(): c.queue_free()
	var ids := Net.peers.keys()
	ids.sort()
	for k in ids.size():
		var id: int = ids[k]
		var p: Dictionary = Net.peers[id]
		var who := String(p.name) + ("  (anfitrión)" if id == 1 else "") + ("  ·  tú" if id == Net.my_id else "")
		var extra := ""
		if id != 1: extra = ("  ·  %d ms" % int(p.ping)) if int(p.ping) > 0 else "  ·  midiendo…"
		var n := int(p.locals)
		var many := ("  ·  %d jugadores" % n) if n > 1 else ""
		var l := UiKit.label(who + many + extra, 22, Devices.COLORS[mini(k, Devices.COLORS.size() - 1)])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_roster.add_child(l)
	if _view == "host" and ids.size() == 1:
		var wait := UiKit.label("Esperando a que se una alguien…", 20, UiKit.TEXT_DIM)
		wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_roster.add_child(wait)
