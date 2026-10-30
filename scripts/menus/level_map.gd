class_name LevelMap
extends Control
## Mapa de niveles (D-25): las 3 partes × 5 niveles. Se elige una parte (04-10-2026): se
## juega desde su primer nivel y el progreso de los personajes pasa de un nivel al siguiente.
## Una parte se abre al superar la anterior. En las versiones de desarrollo (OS.is_debug_build)
## se puede elegir además cualquier nivel suelto, para depurar.
## Debajo, el escenario y las criaturas del nivel señalado. B / Esc vuelve a la selección.
## Al elegir, la ventana de los pactos del Necronomicón (hito 13.6, `PactMenu`): «Sellar y
## jugar» empieza; B vuelve al mapa. `pact_menu=false` (pruebas) empieza sin preguntar.

signal chosen(level_id: String)
signal closed

var _info_title: Label
var _info_text: Label
var _first: Button
var _endless_btn: Button
var _daily_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var won: Array = Saves.current.levels_won if Saves.current else []
	var w: Array = MenuKit.window(self, MenuKit.INK, 1500)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Elige parte", 50)
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
	var extra := HBoxContainer.new()                 # modos aparte: del día y sin fin
	extra.add_theme_constant_override("separation", 26)
	extra.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(extra)
	if (Daily.unlocked(Saves.current) or dev) and not Demo.on():   # partida del día (hito 13.9): tras el primer nivel
		var db := MenuKit.button("Partida del día" + ("" if Daily.unlocked(Saves.current) else "  ·  Desarrollo"), MenuKit.INK, 24)
		db.custom_minimum_size = Vector2(460, 58)
		db.focus_entered.connect(func() -> void:
			_info_title.text = "Partida del día · %s" % Daily.pretty(Daily.today(), false)
			_info_text.text = "El mismo escenario, investigador, compañero y pactos para todos, sacados de la fecha. El primer intento es el que cuenta.")
		db.pressed.connect(func() -> void: _daily(db))
		extra.add_child(db)
		_daily_btn = db
	if (Endless.unlocked(Saves.current) or dev) and not Demo.on():   # modo sin fin (hito 13.8): al vencer a Cthulhu
		var eb := MenuKit.button("La noche eterna" + ("" if Endless.unlocked(Saves.current) else "  ·  Desarrollo"), MenuKit.INK, 24)
		eb.custom_minimum_size = Vector2(460, 58)
		eb.focus_entered.connect(func() -> void:
			_info_title.text = "La noche eterna"
			_info_text.text = "Modo sin fin: eliges escenario y aguantas oleadas de las tres partes, con un horror cada cinco minutos. Récord por personaje y escenario.")
		eb.pressed.connect(func() -> void: _endless(eb))
		extra.add_child(eb)
		_endless_btn = eb
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
	var la := LaunchArgs.from_cmdline()                # capturas: pacts=noche,furia pact_open=true
	if la.has("pacts"): Pacts.set_active(Array(la.get_str("pacts").split(",", false)))
	if la.get_bool("pact_open") and _first: _pick.call_deferred(Campaign.first_of(0), _first)
	if la.get_bool("endless_open") and _endless_btn: _endless.call_deferred(_endless_btn)   # capturas
	if la.get_bool("daily_open") and _daily_btn: _daily.call_deferred(_daily_btn)

## Botón de una parte: empieza por su primer nivel.
func _part_button(pi: int, part: Dictionary, won: Array) -> Button:
	var first := Campaign.first_of(pi)
	var demo_out := not Demo.part_ok(pi)               # la demo (13.17): solo la parte 1
	var open := not demo_out and ((Saves.current != null and Saves.current.unlock_all) or Campaign.part_unlocked(pi, won))
	var playable := open and Campaign.exists(first)
	var b := MenuKit.button(Demo.LOCKED if demo_out else ("Jugar esta parte" if playable else ("Próximamente" if open else "Bloqueada")), MenuKit.INK, 24)
	b.custom_minimum_size = Vector2(460, 62)
	b.disabled = not playable
	b.focus_entered.connect(func() -> void:
		_info_title.text = "Parte %d · %s" % [pi + 1, part.title]
		_info_text.text = "%s. Cinco niveles seguidos: el nivel, las armas y los objetos de cada investigador pasan de uno al siguiente." % part.place)
	b.pressed.connect(func() -> void: _pick(first, b))
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
	b.focus_entered.connect(func() -> void:
		_info_title.text = l.name
		_info_text.text = "Criaturas: %s" % l.creatures)
	b.pressed.connect(func() -> void: _pick(l.id, b))
	return b

## Partida del día: la ventana del día y, al jugar, directa (sus pactos son los del día, D-44).
func _daily(from: Button) -> void:
	var m := DailyMenu.new()
	visible = false
	m.play.connect(func(id: String) -> void:
		visible = true
		Pacts.set_active(Daily.pick(Daily.date_of(id)).pacts)
		chosen.emit(id))
	m.closed.connect(func() -> void:
		visible = true
		from.grab_focus.call_deferred())
	get_parent().add_child(m)

## «La noche eterna»: elegir escenario y, después, los pactos (D-44: también en el sin fin).
func _endless(from: Button) -> void:
	var m := EndlessMenu.new()
	visible = false
	m.picked.connect(func(base: String) -> void:
		visible = true
		_pick(Endless.id_for(base), from))
	m.closed.connect(func() -> void:
		visible = true
		from.grab_focus.call_deferred())
	get_parent().add_child(m)

## Antes de empezar, los pactos (el mapa se esconde mientras tanto).
func _pick(level_id: String, from: Button) -> void:
	if not LaunchArgs.from_cmdline().get_bool("pact_menu", true):
		chosen.emit(level_id)
		return
	var m := PactMenu.new(level_id, Pacts.active())
	visible = false
	m.done.connect(func(ids: Array) -> void:
		Pacts.set_active(ids)
		chosen.emit(level_id))
	m.closed.connect(func() -> void:
		visible = true
		from.grab_focus.call_deferred())
	get_parent().add_child(m)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
