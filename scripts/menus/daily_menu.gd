class_name DailyMenu
extends Control
## Partida del día (hito 13.9): lo que toca hoy (escenario, investigador, compañero y pactos),
## tu intento que cuenta, la racha y los resultados de los amigos que has comparado (sus códigos,
## pegados del portapapeles). `play` empieza la partida; B / Esc vuelve al mapa.

signal play(level_id: String)
signal closed

var date := ""
var _friends: VBoxContainer
var _note: Label
var _picker: RoomCodePicker

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	date = Daily.today()
	var p := Daily.pick(date)
	var save := Auto.save()
	var w: Array = MenuKit.window(self, Color(0.55, 0.42, 0.2), 1100)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "La partida del día", 46)
	box.add_child(_center(UiKit.label(_cap(Daily.pretty(date)), 22, UiKit.TEXT_DIM)))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	box.add_child(cc)
	var lv := _level_name(String(p.level))
	var pacts := Pacts.names(p.pacts)
	for row: Array in [["Escenario", lv], ["Investigador", _res_name("characters", String(p.character))],
			["Compañero", _res_name("pets", String(p.pet))], ["Pactos", pacts if pacts != "" else "ninguno"]]:
		var k := UiKit.label(String(row[0]), 20, UiKit.TEXT_DIM)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(k)
		grid.add_child(UiKit.label(String(row[1]), 20, MenuKit.INK))
	var r := Daily.result(save, date)
	var mine := "Aún no la has jugado: el primer intento es el que cuenta." if r.is_empty() \
		else "Tu intento: %s · %d bajas" % [Endless.clock(float(r.t)), int(r.kills)]
	box.add_child(_center(UiKit.label(mine, 21, UiKit.TEXT)))
	var st := Daily.streak(save, date)
	box.add_child(_center(UiKit.label("Racha: %d %s  ·  la mejor: %d" % [st, "día" if st == 1 else "días", Daily.best_streak(save)], 19, UiKit.TEXT_DIM)))
	if not r.is_empty():
		box.add_child(_center(UiKit.label("Tu código: %s" % Daily.encode(date, float(r.t), int(r.kills), String(r.character), int(r.get("players", 1))), 19, UiKit.TEXT_DIM)))
	_friends = VBoxContainer.new()
	_friends.add_theme_constant_override("separation", 2)
	box.add_child(_friends)
	_fill_friends()
	_note = _center(UiKit.label("", 18, UiKit.TEXT_DIM))
	box.add_child(_note)
	var b_play := MenuKit.button("Jugar" if r.is_empty() else "Jugar (práctica)", MenuKit.INK, 26)
	b_play.custom_minimum_size = Vector2(520, 58)
	b_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_play.pressed.connect(func() -> void:
		play.emit(Daily.id_for(date))
		queue_free())
	box.add_child(b_play)
	box.add_child(_center(UiKit.label("Código de un amigo", 19, UiKit.TEXT_DIM)))
	_picker = RoomCodePicker.new(12, Daily.ALPHABET)   # con el mando, letra a letra (o X para pegar)
	_picker.submitted.connect(_compare)
	box.add_child(_picker)
	var b_cmp := MenuKit.button("Comparar", MenuKit.INK, 22)
	b_cmp.custom_minimum_size = Vector2(520, 52)
	b_cmp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_cmp.pressed.connect(_compare)
	box.add_child(b_cmp)
	b_play.focus_neighbor_bottom = b_play.get_path_to(_picker)
	b_cmp.focus_neighbor_top = b_cmp.get_path_to(_picker)
	box.add_child(MenuKit.hint("Casillas: cruceta o teclado para las letras · X o Ctrl+V: pegar · A: comparar (vacías: lo que haya en el portapapeles)  ·  B o Esc: volver"))
	b_play.grab_focus.call_deferred()
	var la := LaunchArgs.from_cmdline()               # capturas: daily_code=7K2M-QX4A-90BD
	if la.has("daily_code"): _compare_code.call_deferred(la.get_str("daily_code"))

static func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)

func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 1000
	return l

static func _level_name(id: String) -> String:
	for l in Campaign.levels():
		if String(l.id) == id: return String(l.name)
	return id

static func _res_name(dir: String, id: String) -> String:
	var path := "res://data/%s/%s.tres" % [dir, id]
	return String(load(path).get("display_name")) if ResourceLoader.exists(path) else id

## Lee las casillas (o, vacías, el portapapeles); si es un código de hoy, lo guarda y lo enseña.
func _compare() -> void:
	_compare_code(_picker.text() if _picker.text() != "" else DisplayServer.clipboard_get())

func _compare_code(code: String) -> void:
	var d := Daily.decode(code)
	if d.is_empty():
		_note.text = "No es un código válido (12 letras, como 7K2M-QX4A-90BD): revisa las letras."
		return
	if String(d.date) != date:
		_note.text = "Ese código es de la partida del %s, no de la de hoy." % Daily.pretty(String(d.date), false)
		return
	Daily.add_friend(Auto.save(), d)
	if Auto.save() != null: Auto.node("Saves").call("save")
	_note.text = ""
	_fill_friends()

func _fill_friends() -> void:
	for c in _friends.get_children(): c.queue_free()
	var mine := Daily.result(Auto.save(), date)
	for code: String in Daily.friends(Auto.save(), date):
		var d := Daily.decode(code)
		if d.is_empty(): continue
		var line := "Amigo (%s%s): %s · %d bajas" % [_res_name("characters", String(d.character)),
			", %d jugadores" % d.players if int(d.players) > 1 else "", Endless.clock(float(d.t)), int(d.kills)]
		if not mine.is_empty():
			var diff := float(mine.t) - float(d.t)
			line += "  —  " + ("le sacas %s" % Endless.clock(diff) if diff > 0.0 else ("te saca %s" % Endless.clock(-diff) if diff < 0.0 else "empate"))
		_friends.add_child(_center(UiKit.label(line, 19, Color(0.85, 0.78, 0.62))))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
