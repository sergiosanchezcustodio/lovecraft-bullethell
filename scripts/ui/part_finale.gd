class_name PartFinale
extends CanvasLayer
## Final ilustrado de una parte (hito 21.17): al vencer a su jefe, antes de la pantalla de victoria,
## su ilustración a pantalla completa (`tools/gen_finales.py`) con un acercamiento lento y la frase
## que cierra el relato. A, Intro, Start, Esc o un clic la pasan (tras un momento, para que no se
## salte sin querer al pulsar en la pelea). Datos en `data/part_finales.json`, por nivel.
## Pruebas: `finale=false` la quita; con `autonext`/`autorestart` (bots) se pasa sola.

signal done

const DATA := "res://data/part_finales.json"
const MIN_TIME := 1.2                              ## s antes de poder pasarla
const AUTO_TIME := 2.5                             ## s con bots
const ZOOM := 1.07                                 ## acercamiento al cabo de ZOOM_TIME
const ZOOM_TIME := 16.0
const WORD_TIME := 0.11                            ## s por palabra de la frase

var _d: Dictionary
var _t := 0.0
var _closing := false
var _img: TextureRect
var _root: Control
var _hint: Label
var _auto := false

static var _all := {}

static func data_for(level_id: String) -> Dictionary:
	if _all.is_empty():
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_all = (v as Dictionary).get("finales", {}) if v is Dictionary else {}
	var d: Variant = _all.get(level_id, {})
	return d if d is Dictionary else {}

## ¿Se cuenta al superar `level_id`? (solo los niveles de la campaña con final; no los desafíos, el
## desfile ni las expediciones, que llevan otro id)
static func applies(level_id: String, la: LaunchArgs) -> bool:
	if la != null and not la.get_bool("finale", true): return false
	var d := data_for(level_id)
	return not d.is_empty() and ResourceLoader.exists(String(d.get("image", "")))

func _init(d: Dictionary, auto := false) -> void:
	_d = d
	_auto = auto
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.modulate.a = 0.0
	_root.theme = MenuKit.theme()                       # EB Garamond, como los relatos
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	_img = TextureRect.new()
	_img.texture = load(String(_d.image))
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_img)
	var shade := TextureRect.new()                      # abajo, oscuro, para que se lea la frase
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.88))
	g.add_point(0.55, Color(0, 0, 0, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -250
	box.offset_bottom = -54
	box.offset_left = 260
	box.offset_right = -260
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 14)
	_root.add_child(box)
	var head := MenuKit.title(String(_d.get("title", "")), 34, UiKit.GOLD)
	box.add_child(head)
	var line := UiKit.label(String(_d.get("text", "")), 30, Color(0.93, 0.89, 0.8))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	line.add_theme_constant_override("shadow_offset_x", 2)
	line.add_theme_constant_override("shadow_offset_y", 2)
	line.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING   # las líneas, ya partidas: no saltan
	line.visible_characters = 0
	box.add_child(line)
	_hint = MenuKit.hint("A o Intro: seguir")
	_hint.modulate.a = 0.0
	box.add_child(_hint)
	_img.pivot_offset = get_viewport().get_visible_rect().size * Vector2(0.5, 0.42)
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.9)
	var ends := word_ends(line.text)                   # palabra a palabra, como si se escribiera con tinta
	tw.tween_method(func(v: float) -> void: line.visible_characters = ends[mini(int(v), ends.size() - 1)],
		0.0, float(ends.size()) - 0.001, WORD_TIME * ends.size())
	tw.tween_property(_hint, "modulate:a", 1.0, 0.5)
	create_tween().tween_property(_img, "scale", Vector2.ONE * ZOOM, ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Auto.sfx("part_finale")                             # un acorde grave y largo (gen_sfx.py --finale)

## Dónde acaba cada palabra de `text` (en caracteres; la última, el final).
static func word_ends(text: String) -> Array[int]:
	var out: Array[int] = []
	for i in text.length():
		if text[i] == " " and i > 0 and text[i - 1] != " ": out.append(i)
	out.append(text.length())
	return out

func _process(delta: float) -> void:
	_t += delta
	if _auto and _t >= AUTO_TIME: close()

func _input(e: InputEvent) -> void:
	if (e is InputEventKey or e is InputEventJoypadButton or e is InputEventJoypadMotion or e is InputEventMouseButton) and e.is_pressed():
		get_viewport().set_input_as_handled()          # nada llega a lo de debajo (la Biblioteca) mientras se ve
	if _closing or _t < MIN_TIME: return
	var go := false
	if e is InputEventKey and e.pressed and not e.echo:
		go = (e as InputEventKey).physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]
	elif e is InputEventJoypadButton and e.pressed:
		go = (e as InputEventJoypadButton).button_index in [JOY_BUTTON_A, JOY_BUTTON_START, JOY_BUTTON_B]
	elif e is InputEventMouseButton and e.pressed:
		go = true
	if go:
		get_viewport().set_input_as_handled()
		close()

## Se funde a negro y avisa (la pantalla de victoria sale debajo).
func close() -> void:
	if _closing: return
	_closing = true
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		done.emit()
		queue_free())
