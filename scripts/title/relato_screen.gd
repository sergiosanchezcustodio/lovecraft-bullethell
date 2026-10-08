class_name RelatoScreen
extends Control
## Relato del nivel (hito 5.3), entre el mapa (o "Siguiente nivel") y la partida: el título
## del nivel y sus frases (data/library/relatos.json) apareciendo una tras otra sobre el mapa
## del lugar, oscurecido. Pulsar adelanta (muestra lo que falta o, si ya está todo, empieza);
## mantener pulsado 0,8 s lo salta, con un aro que se llena. Sin relato, va directo a la partida.
## Capturas: `godot --path . -- relato level=p1_n1 shots=3,9 tag=x`.

const LINE_DELAY := 2.3          ## s entre frase y frase
const FADE := 0.7
const HOLD_SKIP := 0.8
const GAME := "res://scenes/game.tscn"

var _lines: Array[Label] = []
var _t := 0.0
var _hold := 0.0
var _holding := false
var _ring: Control
var _shots: PackedFloat64Array
var _tag := "relato"

static func has_relato(level_id: String) -> bool:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
	return d is Dictionary and (d as Dictionary).has(level_id)

func _ready() -> void:
	var la := LaunchArgs.from_cmdline()
	for s in la.get_str("shots").split(",", false): _shots.append(float(s))
	_tag = la.get_str("tag", "relato")
	var id := la.get_str("level", String(GameSession.level)) if la.has("level") else String(GameSession.level)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
	if not (d is Dictionary) or not (d as Dictionary).has(id):
		_go()
		return
	var black := ColorRect.new()
	black.color = Color(0.01, 0.01, 0.015)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var map := "res://resources/maps/%s.png" % id
	if ResourceLoader.exists(map):
		var bg := TextureRect.new()
		bg.texture = load(map)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bg.modulate = Color(0.2, 0.2, 0.23)
		add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1150, 0)
	box.add_theme_constant_override("separation", 22)
	c.add_child(box)
	var info := {}
	for lv in Campaign.levels():
		if String(lv.get("id", "")) == id: info = lv
	var part := int(id.substr(1, 1)); var num := int(id.substr(4, 1))
	box.add_child(MenuKit.title("Parte %d · Nivel %d" % [part, num], 26, Color(0.75, 0.68, 0.52)))
	box.add_child(MenuKit.title(String(info.get("name", "")), 46))
	var sep := HSeparator.new()
	sep.modulate = Color(MenuKit.INK, 0.4)
	box.add_child(sep)
	for s in (d as Dictionary)[id]:
		var l := UiKit.label(String(s), 28, Color(0.90, 0.86, 0.78))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		box.add_child(l)
		_lines.append(l)
	var hint := UiKit.label("Pulsa para seguir · mantén pulsado para saltar", 18, Color(0.7, 0.66, 0.56, 0.6))
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-260, -56)
	hint.size = Vector2(520, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	_ring = Control.new()
	_ring.position = Vector2(1840, 1000)
	_ring.draw.connect(_draw_ring)
	add_child(_ring)

func _draw_ring() -> void:
	if _hold <= 0.0: return
	_ring.draw_arc(Vector2.ZERO, 26, -PI / 2, -PI / 2 + TAU * clampf(_hold / HOLD_SKIP, 0, 1), 40, MenuKit.INK, 5.0, true)

func _process(delta: float) -> void:
	_t += delta
	for i in _lines.size():
		_lines[i].modulate.a = clampf((_t - 0.4 - i * LINE_DELAY) / FADE, 0.0, 1.0)
	if _holding:
		_hold += delta
		if _hold >= HOLD_SKIP: _go()
	if _ring: _ring.queue_redraw()
	if not _shots.is_empty() and _t >= _shots[0]:
		_shots.remove_at(0)
		get_viewport().get_texture().get_image().save_png("res://shots/%s_%04.1fs.png" % [_tag, _t])
		if _shots.is_empty(): get_tree().quit()

func _all_shown() -> bool:
	return _t >= 0.4 + (_lines.size() - 1) * LINE_DELAY + FADE

func _go() -> void:
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GAME)

func _input(event: InputEvent) -> void:
	var down := false
	var up := false
	if event is InputEventKey and not event.echo and (event as InputEventKey).keycode in TitleScreen.PRESS_KEYS:
		down = event.pressed; up = not event.pressed
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index in TitleScreen.PRESS_BUTTONS:
		down = event.pressed; up = not event.pressed
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		down = event.pressed; up = not event.pressed
	if down:
		_holding = true
		_hold = 0.0
		get_viewport().set_input_as_handled()
	elif up and _holding:
		_holding = false
		var short := _hold < HOLD_SKIP
		_hold = 0.0
		if short:
			if _all_shown(): _go()
			else: _t = 0.4 + (_lines.size() - 1) * LINE_DELAY + FADE     # muestra todo
		get_viewport().set_input_as_handled()
