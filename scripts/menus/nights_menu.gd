class_name NightsMenu
extends Control
## Noches sueltas (fase 21, bloque D): una carta por noche de `data/nights.json`, con su título, el
## lugar, las criaturas y ✓ si ya la has superado; abajo, su presentación. Cada una se abre al
## superar su nivel de la campaña (en las versiones de desarrollo, todas). Junto a la presentación,
## la miniatura de su mapa (`resources/maps/<id>.png`, oscurecida si está cerrada). B / Esc vuelve
## al mapa. `picked` da el id del nivel.

signal picked(id: String)
signal closed

const ACCENT := Color(0.62, 0.5, 0.82)

var _text: Label
var _map: TextureRect
var _maps := {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, Color(0.36, 0.26, 0.5), 1300)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Noches sueltas", 48, ACCENT.lightened(0.2))
	var sub := UiKit.label("Relatos aparte de la campaña: un escenario, sus criaturas y su horror, en una sola noche. Se empieza de cero. Superadas: %d de %d." % [Nights.won_count(Saves.current), Nights.all().size()], 19, UiKit.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 1150
	box.add_child(sub)
	var dev := OS.is_debug_build()
	var first: Button = null
	var prev: Button = null
	for n: Dictionary in Nights.all():
		var id := String(n.id)
		var open := Nights.unlocked(Saves.current, id)
		var wins := Nights.wins(Saves.current, id)
		var need := Campaign.levels().filter(func(l: Dictionary) -> bool: return String(l.id) == String(n.get("abre", "")))
		var lock := "Supera «%s» para abrirla" % String(need[0].name) if not need.is_empty() else "Cerrada"
		var b := MenuKit.button("%s%s\n%s" % ["✓ " if wins > 0 else "", String(n.titulo) if open or dev else lock,
			String(n.lugar) + ("  ·  Desarrollo" if dev and not open else "")], MenuKit.INK, 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(1150, 84)
		b.disabled = not (open or dev) or not ResourceLoader.exists("res://data/levels/%s.tres" % id)
		b.focus_entered.connect(func() -> void:
			_text.text = "%s\n\n%s" % [String(n.texto), String(n.criaturas)] if open or dev else lock
			_show_map(id, open or dev))
		b.pressed.connect(func() -> void:
			picked.emit(id)
			queue_free())
		box.add_child(b)
		if prev != null:
			b.focus_neighbor_top = b.get_path_to(prev)
			prev.focus_neighbor_bottom = prev.get_path_to(b)
		prev = b
		if first == null and not b.disabled: first = b
	var row := HBoxContainer.new()                 # la miniatura del mapa y, a su lado, la presentación
	row.add_theme_constant_override("separation", 26)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var frame := PanelContainer.new()
	var sb := MenuKit.box(Color(0.03, 0.025, 0.02, 1.0), MenuKit.BRASS, 2)
	for side in ["left", "right", "top", "bottom"]: sb.set("content_margin_" + side, 4)
	frame.add_theme_stylebox_override("panel", sb)
	row.add_child(frame)
	_map = TextureRect.new()
	_map.custom_minimum_size = Vector2(354, 236)
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_map)
	_text = UiKit.label("", 20, UiKit.TEXT)
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(770, 236)
	row.add_child(_text)
	box.add_child(MenuKit.hint("A o Intro: jugar  ·  B o Esc: volver al mapa"))
	if first != null: first.grab_focus.call_deferred()

## La miniatura de la noche (oscurecida si aún está cerrada).
func _show_map(id: String, open: bool) -> void:
	if not _maps.has(id):
		var path := "res://resources/maps/%s.png" % id
		_maps[id] = load(path) if ResourceLoader.exists(path) else null
	_map.texture = _maps[id]
	_map.modulate = Color.WHITE if open else Color(0.22, 0.2, 0.25)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
