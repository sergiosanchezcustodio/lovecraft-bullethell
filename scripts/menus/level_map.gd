class_name LevelMap
extends Control
## Mapa de niveles (D-25): las 3 partes × 5 niveles. Se elige una parte (04-10-2026): se
## juega desde su primer nivel y el progreso de los personajes pasa de un nivel al siguiente.
## Una parte se abre al superar la anterior. En las versiones de desarrollo (OS.is_debug_build)
## se puede elegir además cualquier nivel suelto, para depurar.
## Debajo, el escenario y las criaturas del nivel señalado. B / Esc vuelve a la selección.

signal chosen(level_id: String)
signal closed

var _info_title: Label
var _info_text: Label
var _first: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var won: Array = Saves.current.levels_won if Saves.current else []
	var w: Array = MenuKit.window(self, MenuKit.INK, 1500)
	var box: VBoxContainer = w[1]
	box.add_child(MenuKit.title("Elige parte", 50))
	var dev := OS.is_debug_build()
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 26)
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(cols)
	var all := Campaign.levels()
	var pi := 0
	for part: Dictionary in Campaign.parts():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		cols.add_child(col)
		col.add_child(MenuKit.title("Parte %d" % (pi + 1), 22, UiKit.TEXT_DIM))
		var pt := MenuKit.title(part.title, 28)
		pt.custom_minimum_size.x = 460
		col.add_child(pt)
		var place := UiKit.label(part.place, 16, UiKit.TEXT_DIM)
		place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(place)
		col.add_child(_part_button(pi, part, won))
		for l: Dictionary in all.filter(func(e: Dictionary) -> bool: return e.part == pi):
			if dev: col.add_child(_level_button(l, won))
			else: col.add_child(_level_line(l, won))
		pi += 1
	var sep := HSeparator.new()
	box.add_child(sep)
	_info_title = MenuKit.title("", 28)
	box.add_child(_info_title)
	_info_text = UiKit.label("", 19, UiKit.TEXT)
	_info_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_text.custom_minimum_size = Vector2(1300, 56)
	box.add_child(_info_text)
	box.add_child(MenuKit.hint(("Desarrollo: también se puede elegir un nivel suelto  ·  " if dev else "") + "A o Intro: jugar  ·  B o Esc: volver a la selección"))
	if _first: _first.grab_focus.call_deferred()

## Botón de una parte: empieza por su primer nivel.
func _part_button(pi: int, part: Dictionary, won: Array) -> Button:
	var first := Campaign.first_of(pi)
	var open := (Saves.current != null and Saves.current.unlock_all) or Campaign.part_unlocked(pi, won)
	var playable := open and Campaign.exists(first)
	var b := MenuKit.button("Jugar esta parte" if playable else ("Próximamente" if open else "Bloqueada"), MenuKit.INK, 24)
	b.custom_minimum_size = Vector2(460, 62)
	b.disabled = not playable
	b.add_theme_stylebox_override("disabled", UiKit.panel(Color(0.03, 0.03, 0.04, 0.7), Color(UiKit.TEXT_DIM, 0.12)))
	b.focus_entered.connect(func() -> void:
		_info_title.text = "Parte %d · %s" % [pi + 1, part.title]
		_info_text.text = "%s. Cinco niveles seguidos: el nivel, las armas y los objetos de cada investigador pasan de uno al siguiente." % part.place)
	b.pressed.connect(func() -> void: chosen.emit(first))
	if playable and _first == null: _first = b
	return b

## Nivel de una parte, solo informativo (fuera de las versiones de desarrollo).
func _level_line(l: Dictionary, won: Array) -> Label:
	var done := "✓ " if won.has(l.id) else ""
	var lab := UiKit.label("%s%d.  %s" % [done, l.number, l.name], 17, UiKit.TEXT if won.has(l.id) else UiKit.TEXT_DIM)
	lab.custom_minimum_size = Vector2(460, 34)
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lab

func _level_button(l: Dictionary, won: Array) -> Button:
	var unlocked := Saves.current.has_level(l.id) if Saves.current else Campaign.is_unlocked(l.id, won)
	var playable := unlocked and Campaign.exists(l.id)
	var tag := "" if playable else ("  ·  Próximamente" if unlocked else "  ·  Bloqueado")
	var done := "✓ " if won.has(l.id) else ""
	var b := MenuKit.button("%s%d.  %s%s" % [done, l.number, l.name, tag], MenuKit.INK, 19)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(460, 58)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = not playable
	b.add_theme_color_override("font_disabled_color", Color(UiKit.TEXT_DIM, 0.55 if not unlocked else 0.9))
	b.add_theme_stylebox_override("disabled", UiKit.panel(Color(0.03, 0.03, 0.04, 0.7), Color(UiKit.TEXT_DIM, 0.12)))
	b.focus_entered.connect(func() -> void:
		_info_title.text = l.name
		_info_text.text = "Criaturas: %s" % l.creatures)
	b.pressed.connect(func() -> void: chosen.emit(l.id))
	return b

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
