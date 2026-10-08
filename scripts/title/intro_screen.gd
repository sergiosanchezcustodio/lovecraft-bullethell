class_name IntroScreen
extends Control
## Arranque (hitos 5.1 y 5.2): la ficha del proyecto (data/credits.json: autor, con qué está
## hecho, aviso del uso de IA y licencia) y después la intro (data/library/intro.json: una
## frase por pantalla sobre la ilustración de la biblioteca, oscurecida y acercándose
## despacio). Cualquier botón principal pasa a la siguiente pantalla; mantenerlo 0,6 s salta
## todo. Al acabar, la portada. Configuración > Juego > "Ficha e intro al arrancar".
## Capturas: `godot --path . -- intro shots=2,8 tag=x` (por tiempo).

const FICHA_TIME := 9.0          ## s que dura la ficha si no se pulsa nada
const LINE_TIME := 4.2           ## s por frase de la intro
const FADE := 0.8
const HOLD_SKIP := 0.6           ## s manteniendo pulsado para saltarlo todo
const BG := "res://resources/PantallasMenus/fondo_titulo_sin_texto_1080p_definitivo.png"

var _pages: Array[Control] = []
var _durations: Array[float] = []
var _page := 0
var _t := 0.0
var _hold := 0.0
var _holding := false
var _bg: TextureRect
var _skip_lbl: Label
var _shots: PackedFloat64Array
var _tag := "intro"
var _clock := 0.0

func _ready() -> void:
	var la := LaunchArgs.from_cmdline()
	for s in la.get_str("shots").split(",", false): _shots.append(float(s))
	_tag = la.get_str("tag", "intro")
	var black := ColorRect.new()
	black.color = Color(0.01, 0.01, 0.015)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	_bg = TextureRect.new()
	_bg.texture = load(BG)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_bg.modulate = Color(0.22, 0.22, 0.26, 0.0)
	_bg.pivot_offset = Vector2(960, 540)
	add_child(_bg)
	_build_ficha()
	_build_intro()
	_skip_lbl = UiKit.label("Pulsa para seguir · mantén pulsado para saltar", 18, Color(0.7, 0.66, 0.56, 0.6))
	_skip_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_lbl.position = Vector2(-260, -56)
	_skip_lbl.size = Vector2(520, 30)
	_skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_skip_lbl)
	_show(0)

func _json(path: String) -> Dictionary:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else {}

func _centered_box(width: float) -> VBoxContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(width, 0)
	box.add_theme_constant_override("separation", 18)
	c.add_child(box)
	c.modulate.a = 0.0
	_pages.append(c)
	return box

func _para(text: String, size: int, color: Color) -> Label:
	var l := UiKit.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _build_ficha() -> void:
	var d := _json("res://data/credits.json")
	var box := _centered_box(1100)
	box.add_child(MenuKit.title(String(d.get("titulo", "")), 52))
	var sep := HSeparator.new()
	sep.modulate = Color(MenuKit.INK, 0.4)
	box.add_child(sep)
	for line in d.get("lineas", []): box.add_child(_para(String(line), 24, Color(0.88, 0.84, 0.76)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)
	box.add_child(MenuKit.title("Uso de inteligencia artificial", 30))
	box.add_child(_para(String(d.get("ia", "")), 21, Color(0.80, 0.78, 0.72)))
	box.add_child(gap.duplicate())
	box.add_child(_para(String(d.get("licencia", "")), 20, Color(0.66, 0.62, 0.54)))
	_durations.append(FICHA_TIME)

func _build_intro() -> void:
	var d := _json("res://data/library/intro.json")
	for f in d.get("frases", []):
		var box := _centered_box(1200)
		var l := _para(String(f), 38, MenuKit.INK)
		l.add_theme_font_override("font", MenuKit.font())
		box.add_child(l)
		_durations.append(LINE_TIME)

func _show(i: int) -> void:
	_page = i
	_t = 0.0

func _process(delta: float) -> void:
	_clock += delta
	_t += delta
	if _holding:
		_hold += delta
		if _hold >= HOLD_SKIP: _finish()
	var dur := _durations[_page]
	for k in _pages.size():
		var a := 0.0
		if k == _page: a = clampf(minf(_t / FADE, (dur - _t) / FADE), 0.0, 1.0)
		_pages[k].modulate.a = a
	# la ilustración aparece con la intro (no con la ficha) y se acerca despacio
	var want := 0.0 if _page == 0 else 1.0
	_bg.modulate.a = move_toward(_bg.modulate.a, want, delta * 0.6)
	_bg.scale = Vector2.ONE * (1.0 + _clock * 0.004)
	if _t >= dur: _next()
	if not _shots.is_empty() and _clock >= _shots[0]:
		_shots.remove_at(0)
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://shots/%s_%04.1fs.png" % [_tag, _clock])
		if _shots.is_empty(): get_tree().quit()

func _next() -> void:
	if _page + 1 >= _pages.size():
		_finish()
	else:
		_show(_page + 1)

func _finish() -> void:
	set_process(false)
	Settings.set_value("intro_seen", true)
	get_tree().change_scene_to_file.call_deferred("res://scenes/title.tscn")

func _input(event: InputEvent) -> void:
	var down := false
	var up := false
	if event is InputEventKey and not event.echo:
		var k := (event as InputEventKey).keycode
		if k in TitleScreen.PRESS_KEYS:
			down = event.pressed; up = not event.pressed
	elif event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).button_index in TitleScreen.PRESS_BUTTONS:
			down = event.pressed; up = not event.pressed
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		down = event.pressed; up = not event.pressed
	if down:
		_holding = true
		_hold = 0.0
		get_viewport().set_input_as_handled()
	elif up and _holding:
		_holding = false
		if _hold < HOLD_SKIP:                            # pulsación corta: la siguiente pantalla
			_t = maxf(_t, _durations[_page] - FADE)
		get_viewport().set_input_as_handled()
