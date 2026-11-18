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
var _challenge_btn: Button
var _nights_btn: Button
var _madness_row: OptionRow
var _col_w := 460.0                                   ## ancho de cada columna de parte
const ROW_INDENT := 30                                ## sitio para el camino de tinta (21.18)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var won: Array = Saves.current.levels_won if Saves.current else []
	var four := Campaign.parts().size() > 3           # la parte 4 (21.12): columnas más estrechas y ventana más ancha
	_col_w = 390.0 if four else 460.0
	var w: Array = MenuKit.window(self, MenuKit.INK, 1720 if four else 1500)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, L.t("Elige parte"), 50)
	var dev := OS.is_debug_build()
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20 if four else 26)
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(cols)
	var all := Campaign.levels()
	var la0 := LaunchArgs.from_cmdline()
	var seen := InkPath.Seen.get_seen(Saves.current)  # lo que ya se vio del mapa: eso no se anima
	if la0.has("ink_seen"): seen = {"open": Array(la0.get_str("ink_seen").split(",", false)), "won": Array(la0.get_str("ink_won_seen", "").split(",", false))}   # capturas
	var first_look := Saves.current != null and not Saves.current.records.has("map_ink") and not la0.has("ink_seen")   # partidas de antes: sin animar todo
	var now_open: Array = []
	var ink_delay := 0.0
	var pi := 0
	for part: Dictionary in Campaign.parts():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		cols.add_child(col)
		col.add_child(MenuKit.title(L.t("Parte %d") % (pi + 1), 22, UiKit.TEXT_DIM))
		var pt := MenuKit.title(part.title, 28)
		pt.custom_minimum_size.x = _col_w
		pt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # «La búsqueda onírica…», en dos líneas: todas a la misma altura
		pt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if four: pt.custom_minimum_size.y = 76
		col.add_child(pt)
		var place := UiKit.label(part.place, 16, UiKit.TEXT_DIM)
		place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		place.custom_minimum_size.x = _col_w
		col.add_child(place)
		col.add_child(_part_button(pi, part, won))
		var holder := MarginContainer.new()           # el camino de tinta a la izquierda de los niveles (21.18)
		holder.add_theme_constant_override("margin_left", ROW_INDENT)
		col.add_child(holder)
		var rows := VBoxContainer.new()
		rows.add_theme_constant_override("separation", 8)
		holder.add_child(rows)
		var opened: Array[bool] = []
		var beaten: Array[bool] = []
		var s_open: Array[bool] = []
		var s_won: Array[bool] = []
		for l: Dictionary in all.filter(func(e: Dictionary) -> bool: return e.part == pi):
			if dev: rows.add_child(_level_button(l, won))
			else: rows.add_child(_level_line(l, won))
			opened.append(_is_open(l, won))
			beaten.append(won.has(l.id))
			s_open.append(first_look or (seen.open as Array).has(l.id))
			s_won.append(first_look or (seen.won as Array).has(l.id))
			if opened.back(): now_open.append(l.id)
		var ink := InkPath.new()
		holder.add_child(ink)
		ink.setup(rows, opened, beaten, s_open, s_won, pi)
		ink.play.call_deferred(la0.get_bool("ink_instant"), ink_delay)
		ink_delay += ink.duration() + (0.15 if ink.duration() > 0.0 else 0.0)   # la parte siguiente, al acabar esta
		pi += 1
	if Saves.current != null and InkPath.Seen.mark(Saves.current, now_open, won.duplicate()): Saves.save()
	var extra := HBoxContainer.new()                 # modos aparte: del día y sin fin
	extra.add_theme_constant_override("separation", 26)
	extra.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(extra)
	if (Daily.unlocked(Saves.current) or dev) and not Demo.on():   # partida del día (hito 13.9): tras el primer nivel
		var db := MenuKit.button(L.t("Partida del día") + ("" if Daily.unlocked(Saves.current) else L.t("  ·  Desarrollo")), MenuKit.INK, 24)
		db.custom_minimum_size = Vector2(460, 58)
		db.focus_entered.connect(func() -> void:
			_info_title.text = L.t("Partida del día · %s") % Daily.pretty(Daily.today(), false)
			_info_text.text = L.t("El mismo escenario, investigador, compañero y pactos para todos, sacados de la fecha. El primer intento es el que cuenta."))
		db.pressed.connect(func() -> void: _daily(db))
		extra.add_child(db)
		_daily_btn = db
	if (Endless.unlocked(Saves.current) or dev) and not Demo.on():   # modo sin fin (hito 13.8): al vencer a Cthulhu
		var eb := MenuKit.button(L.t("La noche eterna") + ("" if Endless.unlocked(Saves.current) else L.t("  ·  Desarrollo")), MenuKit.INK, 24)
		eb.custom_minimum_size = Vector2(460, 58)
		eb.focus_entered.connect(func() -> void:
			_info_title.text = L.t("La noche eterna")
			_info_text.text = L.t("Modo sin fin: eliges escenario y aguantas oleadas de todas las partes, con un horror cada cinco minutos. Récord por personaje y escenario."))
		eb.pressed.connect(func() -> void: _endless(eb))
		extra.add_child(eb)
		_endless_btn = eb
	var all_parts := range(Campaign.parts().size())   # la parte 4 también (21.12, mejoras)
	var exp_open := all_parts.filter(func(p: int) -> bool: return Expedition.unlocked(Saves.current, p) and Demo.part_ok(p))
	if (not exp_open.is_empty() or dev) and not Demo.on() and not Net.is_active():   # expedición (hito 16.21): al superar una parte, sin red
		var xb := MenuKit.button(L.t("Expedición") + ("" if not exp_open.is_empty() else L.t("  ·  Desarrollo")), MenuKit.INK, 24)
		xb.custom_minimum_size = Vector2(460, 58)
		xb.focus_entered.connect(func() -> void:
			_info_title.text = L.t("Expedición")
			_info_text.text = L.t("Una tirada por una parte con un mapa de caminos que se bifurcan: combates, élites, el buhonero, curiosidades y descansos, y el jefe al final. Lo que ganas solo vale en esa expedición. Se abre la de cada parte al superarla. Sin red."))
		xb.pressed.connect(func() -> void: _expedition(xb, exp_open if not dev else all_parts))
		extra.add_child(xb)
		if LaunchArgs.from_cmdline().get_bool("expedition_open"):   # capturas (recorrido de las ventanas)
			_expedition.call_deferred(xb, exp_open if not dev else all_parts)
	if (BossRush.unlocked(Saves.current) or dev) and not Demo.on():   # desfile de jefes (hito 16.22): al vencer a Cthulhu
		var rb := MenuKit.button(L.t("Desfile de jefes") + ("" if BossRush.unlocked(Saves.current) else L.t("  ·  Desarrollo")), MenuKit.INK, 24)
		rb.custom_minimum_size = Vector2(460, 58)
		rb.focus_entered.connect(func() -> void:
			_info_title.text = L.t("Desfile de jefes")
			var best := BossRush.best_any(Saves.current)
			_info_text.text = L.t("Los jefes de la campaña seguidos, cada uno en su escenario: Gedney, el shoggoth primigenio, Obed Marsh, Madre Hydra y Padre Dagon, el viejo Castro, Cthulhu y Nyarlathotep. Empiezas fuerte y lo que ganas pasa de uno a otro. Sin pactos. Récord del tiempo total por personaje.") + ("" if best <= 0.0 else L.t(" Tu récord: %s.") % Endless.clock(best)))
		rb.pressed.connect(func() -> void:
			Pacts.set_active([])
			GameSession.carry.clear()
			chosen.emit(BossRush.id_for(1)))
		extra.add_child(rb)
	if Challenge.any_unlocked(Saves.current) or dev:   # desafíos (hito 15.2): al superar un nivel
		var cb := MenuKit.button(L.t("Desafíos") + ("" if Challenge.any_unlocked(Saves.current) else L.t("  ·  Desarrollo")), MenuKit.INK, 24)
		cb.custom_minimum_size = Vector2(460, 58)
		cb.focus_entered.connect(func() -> void:
			_info_title.text = L.t("Desafíos")
			_info_text.text = L.t("Cada nivel superado abre su desafío: el mismo escenario con reglas fijas (sin esquive, una sola arma, a oscuras…). Superados: %d de %d.") % [Challenge.won_count(Saves.current), Challenge.all().size()])
		cb.pressed.connect(func() -> void: _challenges(cb))
		extra.add_child(cb)
		_challenge_btn = cb
	if (Nights.any_unlocked(Saves.current) or dev) and not Demo.on():   # noches sueltas (fase 21, bloque D)
		var nb := MenuKit.button(L.t("Noches sueltas") + ("" if Nights.any_unlocked(Saves.current) else L.t("  ·  Desarrollo")), MenuKit.INK, 24)
		nb.custom_minimum_size = Vector2(460, 58)
		nb.focus_entered.connect(func() -> void:
			_info_title.text = L.t("Noches sueltas")
			_info_text.text = L.t("Relatos aparte de la campaña, en una sola noche: un escenario, dos criaturas y su horror. Se abre cada una al superar una parte. Superadas: %d de %d.") % [Nights.won_count(Saves.current), Nights.all().size()])
		nb.pressed.connect(func() -> void: _nights(nb))
		extra.add_child(nb)
		_nights_btn = nb
	if extra.get_child_count() > 4:                  # cinco modos (16.21, 16.22): más estrechos, que quepan
		extra.add_theme_constant_override("separation", 14)
		for b: Button in extra.get_children():
			b.custom_minimum_size.x = 0.0
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", 21)
		extra.custom_minimum_size.x = 1520
	var top := Madness.unlocked(Saves.current)        # grados de locura (16.14): al vencer a Cthulhu
	if top > 0 or (dev and LaunchArgs.from_cmdline().get_bool("madness_open")):
		top = maxi(top, 1)
		var names: Array[String] = []
		for g in top + 1: names.append(Madness.title(g))
		var row := OptionRow.new(L.t("Grado de locura"), names, mini(GameSession.madness, top), func(i: int) -> void:
			Madness.set_grade(i)
			_show_madness(i), Callable())
		row.custom_minimum_size = Vector2(946, 54)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.focus_entered.connect(func() -> void: _show_madness(GameSession.madness))
		box.add_child(row)
		_madness_row = row
	var sep := HSeparator.new()
	box.add_child(sep)
	_info_title = MenuKit.title("", 28)
	box.add_child(_info_title)
	_info_text = UiKit.label("", 19, UiKit.TEXT)
	_info_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_text.custom_minimum_size = Vector2(1300, 56)
	box.add_child(_info_text)
	box.add_child(MenuKit.hint((L.t("Desarrollo: también se puede elegir un nivel suelto  ·  ") if dev else "") + L.t("A o Intro: jugar  ·  B o Esc: volver a la selección")))
	if _first: _first.grab_focus.call_deferred()
	var la := LaunchArgs.from_cmdline()                # capturas: pacts=noche,furia pact_open=true
	if la.has("pacts"): Pacts.set_active(Array(la.get_str("pacts").split(",", false)))
	if la.get_bool("pact_open") and _first: _pick.call_deferred(Campaign.first_of(0), _first)
	if la.get_bool("endless_open") and _endless_btn: _endless.call_deferred(_endless_btn)   # capturas
	if la.get_bool("daily_open") and _daily_btn: _daily.call_deferred(_daily_btn)
	if la.get_bool("nights_open") and _nights_btn: _nights.call_deferred(_nights_btn)   # capturas
	if la.get_bool("challenge_open") and _challenge_btn: _challenges.call_deferred(_challenge_btn)
	if la.get_bool("madness_open") and _madness_row: _madness_row.grab_focus.call_deferred()   # capturas
	if la.has("madness") and _madness_row:
		_madness_row.index = la.get_int("madness")
		_madness_row.step(0)

## Lo que trae el grado de locura señalado (16.14).
func _show_madness(g: int) -> void:
	_info_title.text = L.t("Grado de locura · ") + Madness.title(g)
	_info_text.text = (L.t("La campaña de siempre. Al vencer a Cthulhu se abre el grado siguiente.") if g <= 0
		else Madness.describe(g) + L.t(" El grado siguiente se abre al vencer a Cthulhu en este."))

## Botón de una parte: empieza por su primer nivel.
func _part_button(pi: int, part: Dictionary, won: Array) -> Button:
	var first := Campaign.first_of(pi)
	var demo_out := not Demo.part_ok(pi)               # la demo (13.17): solo la parte 1
	var open := not demo_out and ((Saves.current != null and Saves.current.unlock_all) or Campaign.part_unlocked(pi, won))
	var playable := open and Campaign.exists(first)
	var b := MenuKit.button(Demo.locked() if demo_out else (L.t("Jugar esta parte") if playable else (L.t("Próximamente") if open else "Bloqueada")), MenuKit.INK, 24)
	b.custom_minimum_size = Vector2(_col_w, 62)
	b.disabled = not playable
	b.focus_entered.connect(func() -> void:
		_info_title.text = L.t("Parte %d · %s") % [pi + 1, part.title]
		_info_text.text = L.t("%s. Cinco niveles seguidos: el nivel, las armas y los objetos de cada investigador pasan de uno al siguiente.") % part.place)
	b.pressed.connect(func() -> void: _pick(first, b))
	if playable and _first == null: _first = b
	return b

## Nivel de una parte, solo informativo (fuera de las versiones de desarrollo).
func _level_line(l: Dictionary, won: Array) -> Label:
	var lab := UiKit.label("%d.  %s" % [l.number, l.name], 17, UiKit.TEXT if won.has(l.id) else UiKit.TEXT_DIM)   # el sello de lacre dice si está superado (21.18)
	lab.custom_minimum_size = Vector2(_col_w - ROW_INDENT, 34)
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lab

## ¿Abierto el nivel? (el camino de tinta llega hasta él)
func _is_open(l: Dictionary, won: Array) -> bool:
	return Saves.current.has_level(l.id) if Saves.current else Campaign.is_unlocked(l.id, won)

func _level_button(l: Dictionary, won: Array) -> Button:
	var unlocked := Saves.current.has_level(l.id) if Saves.current else Campaign.is_unlocked(l.id, won)
	var playable := unlocked and Campaign.exists(l.id)
	var tag := "" if playable else (L.t("  ·  Próximamente") if unlocked else L.t("  ·  Bloqueado"))
	var b := MenuKit.button("%d.  %s%s" % [l.number, l.name, tag], MenuKit.INK, 19)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(_col_w - ROW_INDENT, 58)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = not playable
	b.add_theme_color_override("font_disabled_color", Color(UiKit.TEXT_DIM, 0.55 if not unlocked else 0.9))
	b.focus_entered.connect(func() -> void:
		_info_title.text = l.name
		_info_text.text = L.t("Criaturas: %s") % l.creatures)
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

## Expedición (16.21): elegir la parte y al mapa. Sin pactos.
func _expedition(from: Button, parts: Array) -> void:
	var pop := Control.new()
	pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_parent().add_child(pop)
	visible = false
	var w: Array = MenuKit.window(pop, Color(0.42, 0.34, 0.18), 900)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, L.t("Expedición"), 42, UiKit.GOLD)
	var first: Button = null
	var pi := 0
	for part: Dictionary in Campaign.parts():
		var p := pi
		var wins := Expedition.wins(Saves.current, p)
		var b := MenuKit.button("%s%s" % [String(part.title), (L.t("  ·  completadas: %d") % wins) if wins > 0 else ""], MenuKit.INK, 22)
		b.custom_minimum_size = Vector2(760, 60)
		b.disabled = not parts.has(p)
		b.pressed.connect(func() -> void:
			pop.queue_free()
			visible = true
			Pacts.set_active([])
			Expedition.start(p)
			chosen.emit(Expedition.MAP_ID))
		box.add_child(b)
		if first == null and not b.disabled: first = b
		pi += 1
	box.add_child(MenuKit.hint(L.t("A o Intro: empezar  ·  B o Esc: volver al mapa")))
	var back := func() -> void:
		pop.queue_free()
		visible = true
		from.grab_focus.call_deferred()
	var cancel := _CancelCatcher.new()
	cancel.on_cancel = back
	pop.add_child(cancel)
	if first != null: first.grab_focus.call_deferred()

## Atiende B / Esc en una ventana hecha con código.
class _CancelCatcher extends Node:
	var on_cancel: Callable
	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			on_cancel.call()

## Desafíos (hito 15.2): sin pactos, directo a jugar.
func _challenges(from: Button) -> void:
	var m := ChallengeMenu.new()
	visible = false
	m.picked.connect(func(id: String) -> void:
		visible = true
		Pacts.set_active([])
		chosen.emit(id))
	m.closed.connect(func() -> void:
		visible = true
		from.grab_focus.call_deferred())
	get_parent().add_child(m)

## Noches sueltas: se empiezan de cero, con los pactos que elijas.
func _nights(from: Button) -> void:
	var m := NightsMenu.new()
	visible = false
	m.picked.connect(func(id: String) -> void:
		visible = true
		GameSession.carry.clear()
		_pick(id, from))
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
