class_name DifficultyMenu
extends CanvasLayer
## Pausa > Dificultad (temporal, D-42, 29-10-2026): para que el autor calibre el juego. Arriba la
## dificultad general (mueve todas); debajo cada característica del 1 al 10 con lo que multiplica
## a su lado. El 3 es la de siempre. Se aplica al seguir jugando (la vida, en los enemigos que
## salgan después), se guarda en la configuración y cada cambio se apunta en
## user://logs/dificultad.txt con el nivel y el minuto. B / Esc vuelve a la pausa; Start la cierra.
## Abajo, el historial (hito 13.2): las combinaciones jugadas, con lo que pasó en cada una (del
## registro de partidas de `FallReport`); A vuelve a una.
## Capturas: `debug_menu=N dif_menu=true` (lo abre en vez de la depuración; `dif_hist=true`, el historial).

signal back
signal close

const ACCENT := Color(0.95, 0.72, 0.4)
const LOG := "user://logs/dificultad.txt"
## Nombre corto de cada valor, cuando la característica tiene más de uno.
const SHORT := {"rate": "ritmo", "cap": "vivos", "mental": "mental", "horror": "presencia",
	"melee": "cuerpo", "shooter": "disparo", "attack": "ataques", "warn": "aviso"}

var game: Node
var _list: VBoxContainer
var _general: OptionRow
var _rows := {}                          ## característica -> OptionRow
var _status: Label
var _in_history := false
const HISTORY := 10                      ## combinaciones que se enseñan

func _init(p_game: Node) -> void:
	game = p_game
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	var dim := MenuKit.veil()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := PanelContainer.new()
	panel.theme = MenuKit.theme()
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	MenuKit.heading(box, "Dificultad (temporal)", 40, ACCENT)
	var note := UiKit.label("Para calibrar el juego: el 3 es la de siempre; el 1, casi Investigador; el 5, Pesadilla.", 16, UiKit.TEXT_DIM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(900, 0)
	_list.add_theme_constant_override("separation", 2)
	box.add_child(_list)
	_status = UiKit.label("Se nota al seguir jugando; la vida, en los enemigos que salgan después.", 16, ACCENT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	_build()
	var hint := UiKit.label("Arriba/abajo: elegir · Izquierda/derecha: cambiar · B o Esc: volver · Start: seguir jugando", 15, UiKit.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	MenuKit.dress(panel, MenuKit.BRASS, Vector2(36, 26), 120.0)
	panel.resized.connect(func() -> void: panel.position = (get_viewport().get_visible_rect().size - panel.size) * 0.5)
	if OS.get_cmdline_user_args().has("dif_hist=true"): _show_history()
	else: _general.grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).keycode == KEY_ESCAPE):
		if _in_history: _show_main()
		else: back.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
		close.emit()
		get_viewport().set_input_as_handled()

func _build() -> void:
	var nums: Array[String] = []
	for i in Difficulty.LEVELS: nums.append(str(i + 1))
	_general = OptionRow.new("Dificultad general", nums, maxi(Difficulty.general(), 1) - 1, func(i: int) -> void:
		_change("general", i + 1), Callable(), ACCENT)
	_list.add_child(_general)
	_line(" ")
	for c in Difficulty.CATS:
		var row := OptionRow.new(String(Difficulty.CATS[c].name), names_for(c), int(Difficulty.levels()[c]) - 1,
			func(i: int) -> void: _change(c, i + 1), Callable(), ACCENT)
		_list.add_child(row)
		_rows[c] = row
		_line("      " + String(Difficulty.CATS[c].help))
	_line(" ")
	_list.add_child(OptionRow.new("Volver al 3 (la de siempre)", [] as Array[String], 0, Callable(), func() -> void:
		_change("general", Difficulty.BASE), ACCENT))
	var hist := history()
	if not hist.is_empty():
		var h := OptionRow.new("Partidas jugadas", [] as Array[String], 0, Callable(), _show_history, ACCENT)
		h.set_value_text(MenuKit.count(hist.size(), "combinación", "combinaciones"))
		_list.add_child(h)
	_show_general()

func _clear() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_rows.clear()

func _show_main() -> void:
	_in_history = false
	_clear()
	_build()
	_general.grab_focus.call_deferred()

## Las combinaciones jugadas, la última arriba: nombre y resultados en la fila; debajo, sus
## características (si no son todas iguales), la fecha y el nivel de la última partida.
func _show_history() -> void:
	_in_history = true
	_clear()
	var first: OptionRow = null
	for h: Dictionary in history():
		var lv: Dictionary = h.levels
		var g := general_of(lv)
		var now := Difficulty.describe(lv) == Difficulty.describe()
		var row := OptionRow.new((("%d en todo" % g) if g > 0 else "Personalizada") + ("  (la de ahora)" if now else ""),
			[] as Array[String], 0, Callable(), func() -> void: _pick(lv), ACCENT)
		row.set_value_text(results_text(h))
		_list.add_child(row)
		if first == null: first = row
		var d := String(h.date)                                     # "2026-10-29 19:30:55" -> "29-10 19:30"
		var info := "última, %s-%s %s en %s" % [d.substr(8, 2), d.substr(5, 2), d.substr(11, 5), h.level]
		_line("      " + (info if g > 0 else differences(lv) + "  ·  " + info))
	_line(" ")
	var back_row := OptionRow.new("Volver", [] as Array[String], 0, Callable(), _show_main, ACCENT)
	_list.add_child(back_row)
	(first if first != null else back_row).grab_focus.call_deferred()
	_status.text = "A: jugar con esa combinación · B: volver"

func _pick(lv: Dictionary) -> void:
	var before := Difficulty.describe()
	Difficulty.set_levels(lv)
	if Difficulty.describe() != before: _log("historial", 0)
	_show_main()
	_status.text = "Vuelves a: %s" % Difficulty.describe()

## Nombre corto de cada característica (el historial).
const TINY := {"numero": "número", "vida": "vida", "jefes": "jefes", "dano": "daño", "cordura": "cordura",
	"velocidad": "velocidad", "balas": "balas", "agresividad": "agresividad", "elites": "élites"}

## "daño 6, velocidad 5; el resto, 4": lo que se aparta del nivel más repetido.
static func differences(lv: Dictionary) -> String:
	var counts := {}
	for c in Difficulty.CATS:
		var v := int(lv.get(c, Difficulty.BASE))
		counts[v] = int(counts.get(v, 0)) + 1
	var common := Difficulty.BASE
	for v in counts: if counts[v] > counts.get(common, 0): common = v
	var parts := PackedStringArray()
	for c in Difficulty.CATS:
		var v := int(lv.get(c, Difficulty.BASE))
		if v != common: parts.append("%s %d" % [TINY[c], v])
	return "%s; el resto, %d" % [", ".join(parts), common]

## La general de unos niveles: la de todas si coinciden; -1 si no.
static func general_of(lv: Dictionary) -> int:
	var first := -1
	for c in Difficulty.CATS:
		var v := int(lv.get(c, Difficulty.BASE))
		if first < 0: first = v
		elif v != first: return -1
	return first

## "4 partidas · 3 superadas · caídas 1:03, 2:10".
static func results_text(h: Dictionary) -> String:
	var out := MenuKit.count(int(h.games), "partida") + "  ·  " + MenuKit.count(int(h.won), "superada")
	var falls: Array = h.falls
	if not falls.is_empty():
		var ts := PackedStringArray()
		for t in falls.slice(0, 3): ts.append("%d:%02d" % [int(t) / 60, int(t) % 60])
		out += "  ·  caídas " + ", ".join(ts) + ("…" if falls.size() > 3 else "")
	return out

## Del registro de partidas (`FallReport.RUNS`): cada combinación jugada, la más reciente
## primero, con sus partidas, las superadas, los minutos de las caídas (de la más reciente a la
## más antigua) y la fecha y el nivel de la última. `path`: otro fichero (tests).
static func history(path := "", limit := HISTORY) -> Array:
	var out: Array = []
	if path == "": path = FallReport.runs_path()
	if not FileAccess.file_exists(path): return out
	var lines := FileAccess.get_file_as_string(path).split("
", false)
	var by_key := {}
	for i in range(lines.size() - 1, -1, -1):
		var json := JSON.new()
		if json.parse(lines[i]) != OK: continue           # una línea a medias: fuera, sin quejarse
		var rec = json.data
		if not (rec is Dictionary) or not (rec.get("levels") is Dictionary): continue
		var key := Difficulty.describe(rec.levels)
		if not by_key.has(key):
			if out.size() >= limit: continue
			by_key[key] = {"levels": rec.levels, "games": 0, "won": 0, "falls": [],
				"date": String(rec.get("date", "")), "level": String(rec.get("level", ""))}
			out.append(by_key[key])
		var h: Dictionary = by_key[key]
		h.games += 1
		if String(rec.get("result", "")) == "superado": h.won += 1
		else: h.falls.append(int(rec.get("t", 0)))
	return out

## "3 · ×2,6 · ×1,5": el nivel y lo que multiplica cada valor de la característica.
static func names_for(cat: String) -> Array[String]:
	var keys: Array = (Difficulty.CATS[cat] as Dictionary).keys().filter(
		func(k: String) -> bool: return k != "name" and k != "help" and k != "ramp")
	var out: Array[String] = []
	for i in Difficulty.LEVELS:
		var parts: Array[String] = [str(i + 1)]
		for k in keys:
			var x := "×" + String.num(float(Difficulty.CATS[cat][k][i]), 2).replace(".", ",")
			parts.append((String(SHORT[k]) + " " + x) if keys.size() > 1 else x)
		out.append("  ·  ".join(parts))
	return out

func _line(text: String) -> void:
	var l := UiKit.label(text, 14, UiKit.TEXT_DIM)
	_list.add_child(l)

func _change(cat: String, lv: int) -> void:
	var before := Difficulty.describe()
	if cat == "general":
		Difficulty.set_all(lv)
		var levels := Difficulty.levels()
		for c in _rows:
			var r: OptionRow = _rows[c]
			r.index = int(levels[c]) - 1
			r._show()
	else:
		Difficulty.set_cat(cat, lv)
	_show_general()
	if Difficulty.describe() != before: _log(cat, lv)

func _show_general() -> void:
	var g := Difficulty.general()
	if g > 0:
		_general.index = g - 1
		_general._show()
	else:
		_general.set_value_text("◀  Personalizada  ▶")

## Una línea al registro de dificultad (también la del informe de cada partida, `FallReport`).
static func append_log(line: String) -> void:
	print("DIFICULTAD ", line)
	FallReport._append(LOG, line)

## Cada cambio, con el nivel y el minuto, para saber luego qué se probó y dónde.
func _log(cat: String, lv: int) -> void:
	var where := ""
	if game != null and "director" in game and game.director != null:
		var d: WaveDirector = game.director
		var t := int(d.time)
		where = "%s · %02d:%02d · " % [String(d.level.id) if d.level != null else "?", t / 60, t % 60]
	var line := "%s · %s%s → %d · %s" % [Time.get_datetime_string_from_system(false, true), where, cat, lv, Difficulty.describe()]
	append_log(line)
	_status.text = "Apuntado en el registro de dificultad (%s)." % ProjectSettings.globalize_path(LOG).get_file()
