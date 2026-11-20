class_name RunCodeMenu
extends Control
## «Jugar el código de un amigo» (hito 23.9), en el archivo de expediciones de la Biblioteca: las 20
## casillas del código (`RunCode`), lo que trae y, si este hueco ya tiene ese nivel abierto, a jugar
## la misma noche (en solitario, con el J1, como al repetir una del archivo).

signal closed

var _picker: RoomCodePicker
var _note: Label
var _what: Label
var _play: Button
var _found := {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, Color(0.42, 0.34, 0.18), 1420)
	var box: VBoxContainer = w[1]
	box.add_theme_constant_override("separation", 14)
	MenuKit.heading(box, L.t("El código de un amigo"), 40, UiKit.GOLD)
	box.add_child(_center(UiKit.label(L.t("Con su código juegas la misma noche que jugó: el mismo nivel, investigador, compañero, pactos y locura, y las mismas oleadas, baúles y subidas. Luego comparáis cuánto aguantó cada uno."), 20, UiKit.TEXT)))
	_picker = RoomCodePicker.new(RunCode.LENGTH, RunCode.ALPHABET)
	_picker.submitted.connect(_submit)
	_picker.changed.connect(func(_t: String) -> void: _show({}))
	box.add_child(_picker)
	_what = _center(UiKit.label("", 21, MenuKit.INK))
	box.add_child(_what)
	_note = _center(UiKit.label("", 19, UiKit.TEXT_DIM))
	box.add_child(_note)
	_play = MenuKit.button(L.t("Leer el código"), MenuKit.INK, 26)
	_play.custom_minimum_size = Vector2(520, 58)
	_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play.pressed.connect(_submit)
	box.add_child(_play)
	_picker.focus_neighbor_bottom = _picker.get_path_to(_play)
	_play.focus_neighbor_top = _play.get_path_to(_picker)
	box.add_child(MenuKit.hint(L.t("Casillas: cruceta o teclado para las letras · X o Ctrl+V: pegar · A: leer (vacías: lo que haya en el portapapeles)  ·  B o Esc: volver")))
	_picker.grab_focus.call_deferred()
	var la := LaunchArgs.from_cmdline()               # capturas y pruebas: run_code=7K2M-…
	if la.has("run_code"):
		_picker.set_text(la.get_str("run_code"))
		_submit.call_deferred()

## A o «Leer»: lee el código (o, ya leído y abierto, a jugarlo).
func _submit() -> void:
	if not _found.is_empty() and bool(_found.get("open", false)):
		_start(_found)
		return
	var code := _picker.text()
	if code == "":
		code = DisplayServer.clipboard_get().strip_edges()
		_picker.set_text(code)
	read(code)

## Lee `code` y dice lo que trae (público para los tests).
func read(code: String) -> Dictionary:
	var d := RunCode.decode(code)
	if d.has("error"):
		_show({})
		_note.text = RunCode.error_text(d)
		return d
	d["open"] = RunCode.open_for(Auto.save(), String(d.level))
	_show(d)
	return d

func _show(d: Dictionary) -> void:
	_found = d
	_what.text = RunCode.describe(d) if not d.is_empty() else ""
	if d.is_empty():
		_note.text = ""
		_play.text = L.t("Leer el código")
	elif bool(d.open):
		_note.text = L.t("Semilla %d. En solitario, desde el principio del nivel.") % int(d.seed)
		_play.text = L.t("Jugar esta noche")
		_play.grab_focus.call_deferred()
		if LaunchArgs.from_cmdline().get_bool("run_code_play"): _start.call_deferred(d)   # pruebas: a jugarla
	else:
		_note.text = L.t("Aún no has llegado a ese nivel: ábrelo en la campaña y vuelve con el código.")
		_play.text = L.t("Leer el código")

func _start(d: Dictionary) -> void:
	if Auto.save() != null: Auto.node("Saves").call("save")
	RunCode.prepare(d, Devices.last_device)
	get_tree().change_scene_to_file("res://scenes/relato.tscn")

static func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 900
	return l

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
