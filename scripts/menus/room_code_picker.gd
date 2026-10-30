class_name RoomCodePicker
extends HBoxContainer
## Código de sala con el mando (hito 9.2): ocho casillas como "K7Q2-M9XA". Izquierda/derecha
## cambian de casilla; arriba/abajo, la letra (alfabeto de `RoomCode`); A conecta
## (`submitted`); X pega lo que haya en el portapapeles. Va a la par que el campo de texto:
## lo que se escribe con el teclado aparece aquí (`set_text`) y lo de aquí, allí (`changed`).
## También el código de la partida del día (hito 13.9): 12 casillas con el alfabeto de `Daily`
## (`RoomCodePicker.new(12, Daily.ALPHABET)`); con el foco, las teclas escriben y Ctrl+V pega.

signal changed(text: String)
signal submitted

const BLANK := "_"

var CELLS := 8                              ## casillas (un guion cada cuatro)
var alphabet := RoomCode.ALPHABET

var cells: Array[String] = []               ## una letra por casilla ("" si está vacía)
var pos := 0                                ## casilla con el cursor
var _labels: Array[Label] = []

func _init(p_cells := 8, p_alphabet := "") -> void:
	CELLS = p_cells
	if p_alphabet != "": alphabet = p_alphabet
	for i in CELLS: cells.append("")
	focus_mode = Control.FOCUS_ALL
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)

func _ready() -> void:
	for i in CELLS:
		if i > 0 and i % 4 == 0:
			var dash := UiKit.label("-", 34, UiKit.TEXT_DIM)
			add_child(dash)
		var box := PanelContainer.new()
		box.custom_minimum_size = Vector2(52, 64)
		var l := UiKit.label("", 34, MenuKit.INK)       # la letra de los títulos dibuja el 0 como una o
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(l)
		add_child(box)
		_labels.append(l)
	focus_entered.connect(_paint)
	focus_exited.connect(_paint)
	_paint()

## El código escrito: "K7Q2-M9XA" (las casillas vacías no cuentan).
func text() -> String:
	var groups := PackedStringArray()
	for i in range(0, CELLS, 4):
		var g := "".join(cells.slice(i, i + 4))
		if g != "": groups.append(g)
	return "-".join(groups)

## Copia un texto escrito a mano. Si es una dirección (lleva punto o dos puntos), vacía las casillas.
func set_text(t: String) -> void:
	for i in CELLS: cells[i] = ""
	if not ("." in t or ":" in t):
		var k := 0
		for ch in t.to_upper():
			ch = {"O": "0", "I": "1", "L": "1"}.get(ch, ch)
			if k < CELLS and alphabet.contains(ch):
				cells[k] = ch
				k += 1
	_paint()

## Arriba/abajo: la letra siguiente o la anterior del alfabeto (una vacía empieza en 0).
func cycle(dir: int) -> void:
	var at := alphabet.find(cells[pos]) if cells[pos] != "" else (-1 if dir > 0 else 0)
	cells[pos] = alphabet[posmod(at + dir, alphabet.length())]
	_paint()
	changed.emit(text())

func move(dir: int) -> void:
	pos = clampi(pos + dir, 0, CELLS - 1)
	_paint()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left", true): move(-1)
	elif event.is_action_pressed("ui_right", true): move(1)
	elif event.is_action_pressed("ui_up", true): cycle(1)
	elif event.is_action_pressed("ui_down", true): cycle(-1)
	elif event.is_action_pressed("ui_accept"): submitted.emit()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).ctrl_pressed 			and (event as InputEventKey).keycode == KEY_V:
		set_text(DisplayServer.clipboard_get().strip_edges())
		changed.emit(text())
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_BACKSPACE:
		if cells[pos] == "" and pos > 0: pos -= 1
		cells[pos] = ""
		_paint()
		changed.emit(text())
	elif event is InputEventKey and (event as InputEventKey).pressed and _typed(event as InputEventKey) != "":
		cells[pos] = _typed(event as InputEventKey)
		pos = mini(pos + 1, CELLS - 1)
		_paint()
		changed.emit(text())
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed \
			and (event as InputEventJoypadButton).button_index == JOY_BUTTON_X:
		set_text(DisplayServer.clipboard_get().strip_edges())
		changed.emit(text())
	else: return
	accept_event()

## Letra del alfabeto que da una tecla ("" si no es ninguna; O vale por 0 e I/L por 1).
func _typed(e: InputEventKey) -> String:
	if e.unicode <= 32: return ""
	var ch := String.chr(e.unicode).to_upper()
	ch = {"O": "0", "I": "1", "L": "1"}.get(ch, ch)
	return ch if alphabet.contains(ch) else ""

func _paint() -> void:
	if _labels.is_empty(): return
	var focused := has_focus()
	for i in CELLS:
		var on := focused and i == pos
		_labels[i].text = cells[i] if cells[i] != "" else BLANK
		_labels[i].add_theme_color_override("font_color", MenuKit.INK if cells[i] != "" else UiKit.TEXT_DIM)
		var box := _labels[i].get_parent() as PanelContainer
		box.add_theme_stylebox_override("panel", MenuKit.box(Color(0.16, 0.1, 0.05, 0.95) if on else Color(0.04, 0.03, 0.025, 0.9),
			Color(MenuKit.BRASS, 0.95 if on else 0.3), 2 if on else 1))
