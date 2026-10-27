class_name CloudConnectMenu
extends Control
## Conectar la cuenta de GitHub (hito 10.3): pide un código a GitHub, lo enseña en grande, abre
## github.com/login/device en el navegador y lo copia al portapapeles, y espera a que el jugador lo
## autorice. Al conectar, sincroniza y resuelve los conflictos que haya. B / Esc cancela. Al lado de
## la dirección, un código QR con ella (27-10-2026): con el móvil se abre la página sin escribirla.

signal closed

const URL := "https://github.com/login/device"

var _code: Label
var _qr: TextureRect
var _status: Label
var _buttons: HBoxContainer
var _opened := false
var _done := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, MenuKit.INK, 820)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Conectar con GitHub", 44)
	box.add_child(_text("1. Abre esta página en el navegador (se abre sola):", UiKit.TEXT))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	box.add_child(row)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)
	col.add_child(MenuKit.title("github.com/login/device", 30, UiKit.GOLD))
	var phone := _text("o, con el móvil, escanea este código", UiKit.TEXT_DIM, 18)
	phone.custom_minimum_size.x = 420
	col.add_child(phone)
	_qr = TextureRect.new()
	_qr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_qr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(_qr)
	_show_qr(URL)
	box.add_child(_text("2. Escribe este código y autoriza el juego:", UiKit.TEXT))
	_code = MenuKit.title("Pidiendo el código…", 72, MenuKit.INK)
	box.add_child(_code)
	_status = _text("", UiKit.TEXT_DIM)
	box.add_child(_status)
	box.add_child(_text("El juego solo pide permiso para los gists: guarda una copia de tus partidas en un gist secreto de tu cuenta.", UiKit.TEXT_DIM, 16))
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 20)
	box.add_child(_buttons)
	_button("Abrir la página", _open_page)
	_button("Copiar el código", func() -> void:
		if Cloud.pending.has("user_code"):
			DisplayServer.clipboard_set(Cloud.pending.user_code)
			_status.text = "Código copiado. Pégalo en la página de GitHub.")
	_button("Cancelar", _close)
	box.add_child(MenuKit.hint("A o Intro: elegir  ·  B o Esc: cancelar"))
	MenuKit.trap_focus(self)
	_buttons.get_child(0).grab_focus.call_deferred()
	Cloud.changed.connect(_refresh)
	_run()

func _run() -> void:
	var ok: bool = await Cloud.connect_github()
	if not is_inside_tree() or _done: return
	if not ok:
		_code.text = "—"
		_status.text = Cloud.error_text(Cloud.error) if Cloud.error != "" else "Cancelado."
		return
	_code.text = "Conectado"
	_status.text = "Cuenta de GitHub: %s. Comprobando la nube…" % Cloud.login
	await Cloud.sync()
	if not is_inside_tree() or _done: return
	await CloudConflictMenu.resolve_all(self)
	if is_inside_tree() and not _done: _close()

func _refresh() -> void:
	if _done or not Cloud.pending.has("user_code"): return
	_code.text = Cloud.pending.user_code
	var uri := String(Cloud.pending.get("verification_uri", URL))
	if uri != _qr.get_meta("url", ""): _show_qr(uri)
	if _status.text == "": _status.text = "Esperando a que lo autorices en GitHub…"
	if not _opened:
		_opened = true
		DisplayServer.clipboard_set(Cloud.pending.user_code)
		_status.text = "Esperando a que lo autorices en GitHub… (el código ya está copiado)"
		_open_page()

func _show_qr(url: String) -> void:
	var img := QrCode.image(url, 5, Color(0.05, 0.04, 0.04), Color(0.95, 0.93, 0.88))
	if img != null: _qr.texture = ImageTexture.create_from_image(img)
	_qr.set_meta("url", url)

func _open_page() -> void:
	if Cloud.demo != "": return                        # capturas: sin navegador
	OS.shell_open(String(Cloud.pending.get("verification_uri", URL)))

func _close() -> void:
	if _done: return
	_done = true
	Cloud.cancel_connect()
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _text(t: String, color: Color, size := 22) -> Label:
	var l := UiKit.label(t, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 740
	return l

func _button(t: String, run: Callable) -> void:
	var b := MenuKit.button(t, UiKit.GOLD, 24)
	b.custom_minimum_size = Vector2(230, 56)
	b.pressed.connect(run)
	_buttons.add_child(b)
