class_name OnlineMenu
extends Control
## "Jugar online" (hitos 9.1 y 9.2, D-10): crear una sala o unirse a una con su código o su IP.
## Crear abre la sala y pasa a la selección de personaje, que hace también de sala (código y
## conectados arriba); unirse conecta y, al entrar, pasa a la selección del anfitrión.
## El código se escribe con el teclado o, con el mando, en las casillas de debajo
## (`RoomCodePicker`). B / Esc vuelve atrás (cortando la conexión a medias); desde la
## elección, cierra la ventana. Pruebas: `net_host=true` abre la sala al entrar y
## `net_join=<código|IP>` se une sola (con `open=menu_online` en la portada); `net_upnp=false`
## no toca el router.

const SELECT_SCENE := "res://scenes/select.tscn"

## Aviso para la próxima vez que se abra (por qué se ha vuelto de la sala).
static var notice := ""
static var _args_used := false

var _box: VBoxContainer
var _view := ""                            ## "" o "join"
var _status: Label
var _field: LineEdit
var _picker: RoomCodePicker
var _connect_btn: Button
var _leaving := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, MenuKit.INK, 720)
	_box = w[1]
	Net.failed.connect(_on_failed)
	Net.closed.connect(_on_closed)
	Net.joined.connect(_on_joined)
	_show_choice()
	if notice != "":
		_on_failed(notice)
		notice = ""
	var la := LaunchArgs.from_cmdline()
	if _args_used: return                         # las opciones de prueba valen solo la primera vez
	_args_used = true
	if la.get_bool("net_host"): _host.call_deferred()
	elif la.has("net_join"):
		_show_join()
		_field.text = la.get_str("net_join")
		_picker.set_text(_field.text)
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
	_status = null; _field = null; _picker = null; _connect_btn = null

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
	_text("La primera vez, Windows puede preguntar si deja pasar la conexión: acepta en redes privadas y públicas.", 17, UiKit.TEXT_DIM)
	_box.add_child(MenuKit.hint("B o Esc: volver"))
	_focus(create)

## Abre la sala y pasa a la selección (que hace de sala). Si no se puede, `failed` dice por qué.
func _host() -> void:
	if _leaving: return
	if Net.host(RoomCode.BASE_PORT, LaunchArgs.from_cmdline().get_bool("net_upnp", true)) != OK: return
	_go_to_select()

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
	_picker = RoomCodePicker.new()
	_box.add_child(_picker)
	_field.text_changed.connect(func(t: String) -> void: _picker.set_text(t))
	_picker.changed.connect(func(t: String) -> void: _field.text = t)
	_picker.submitted.connect(_connect)
	_connect_btn = _button("Conectar", _connect)
	# arriba y abajo: campo, casillas y botón (en las casillas, arriba y abajo cambian la letra)
	_field.focus_neighbor_bottom = _field.get_path_to(_picker)
	_connect_btn.focus_neighbor_top = _connect_btn.get_path_to(_picker)
	_status = _text("", 20, UiKit.TEXT_DIM)
	_box.add_child(MenuKit.hint("Mando: cruceta para las letras · A: conectar · X: pegar  ·  Teclado: Intro conecta · Ctrl+V pega  ·  B o Esc: volver"))
	_focus(_picker if Devices.last_device != Devices.KEYBOARD else _field)

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

func _on_joined() -> void:
	if _view != "join": return
	_status.text = "Dentro. Entrando en la sala…"
	_go_to_select()

func _go_to_select() -> void:
	_leaving = true
	get_tree().change_scene_to_file(SELECT_SCENE)

func _on_failed(reason: String) -> void:
	if _status == null: _status = _text("", 20, UiKit.TEXT_DIM)
	_status.text = reason
	_status.add_theme_color_override("font_color", MenuKit.DANGER)
	if _connect_btn != null: _connect_btn.disabled = false

func _on_closed(reason: String) -> void:
	if reason == "" or not is_inside_tree() or _leaving: return       # la cerró este PC
	if _view == "join":
		var typed := _field.text if _field != null else ""
		_show_join()
		_field.text = typed                          # para reintentar sin escribirlo otra vez
		_picker.set_text(typed)
	else: _show_choice()
	_on_failed(reason)
