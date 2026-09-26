class_name DebugMenu
extends CanvasLayer
## Menú de depuración (pausa > Depuración): personaje, armas, pasivas, enemigos y partida.
## Cada fila es un valor que se cambia con izquierda/derecha o con confirmar (A / Intro), o
## una acción que se ejecuta al confirmar. Los cambios se aplican al momento y se guardan en
## DebugOptions, así que se conservan al reiniciar. B / Esc vuelve a la pausa; Start la cierra.

signal back                 ## volver al menú de pausa
signal close                ## cerrar también la pausa y seguir jugando
signal restart              ## reiniciar la partida (cambio de personaje, restablecer)

const ACCENT := Color(0.45, 0.9, 0.75)

var game: Node
var _list: VBoxContainer
var _scroll: ScrollContainer
var _first: Control
var _status: Label

func _init(p_game: Node) -> void:
	game = p_game
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.03, 0.035, 0.05, 0.94), Color(ACCENT, 0.5), 8))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var t := UiKit.label("Depuración", 34, ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(760, 760)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	var margin := MarginContainer.new()                 # las filas no tocan la barra de desplazamiento
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_child(_list)
	_scroll.add_child(margin)
	_build()
	_status = UiKit.label(" ", 16, ACCENT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	var hint := UiKit.label("Arriba/abajo: elegir · Izquierda/derecha o A: cambiar · B o Esc: volver · Start: seguir jugando", 15, UiKit.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	panel.resized.connect(func() -> void: panel.position = (get_viewport().get_visible_rect().size - panel.size) * 0.5)
	if _first: _first.grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).keycode == KEY_ESCAPE):
		back.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
		close.emit()
		get_viewport().set_input_as_handled()

func _say(text: String) -> void:
	_status.text = text

# ---------------------------------------------------------------- filas

func _build() -> void:
	var p: Player = game.player
	var d: WaveDirector = game.director

	_header("Personaje")
	var chars := DebugOptions.list_resources("res://data/characters")
	var char_names: Array[String] = []
	var char_ids: Array[String] = []
	for c: CharacterData in chars:
		char_names.append(c.display_name + ("" if chars.size() > 1 else " (único)"))
		char_ids.append(String(c.id))
	_choice("Personaje", char_names, maxi(char_ids.find(String(p.data.id)), 0), func(i: int) -> void:
		if char_ids[i] == String(p.data.id): return
		DebugOptions.set_value("character", char_ids[i])
		restart.emit())
	var styles := DebugOptions.list_resources("res://data/dodges")
	var style_names: Array[String] = []
	var style_ids: Array[String] = []
	for s: DodgeStyle in styles:
		style_names.append(s.display_name)
		style_ids.append(String(s.id))
	var cur_style := String(p.data.dodge_style.id) if p.data.dodge_style else "deslizar"
	_choice("Esquive", style_names, maxi(style_ids.find(cur_style), 0), func(i: int) -> void:
		DebugOptions.set_value("dodge", style_ids[i])
		p.apply_dodge_style(styles[i])
		DebugOptions.rebuild_stats(p))            # el esquive fija estadísticas que tocan las pasivas
	_toggle("Invulnerable", p.god, func(on: bool) -> void:
		DebugOptions.set_value("god", on)
		p.god = on)
	var speeds := DebugOptions.SPEED_MULTS
	_choice("Velocidad al andar", OptionRow.fmt(speeds, "%d %%", 100.0), OptionRow.idx(speeds, float(DebugOptions.get_value("speed", 1.0)), 1),
		func(i: int) -> void:
			DebugOptions.set_value("speed", speeds[i])
			DebugOptions.rebuild_stats(p))
	_action("Vida al máximo", func() -> void:
		p.health = p.data.max_health
		_say("Vida: %d" % p.health))
	_action("Cordura al máximo", func() -> void:
		p.sanity = p.data.max_sanity
		_say("Cordura: %d" % p.sanity))
	_action("Vaciar la cordura (provoca la crisis)", func() -> void:
		p.sanity = 0.0
		_say("Cordura a cero: la crisis empieza al seguir jugando"))
	_action("Subir un nivel", func() -> void:
		p.progress.add_xp(p.progress.xp_to_next() - p.progress.xp + 0.01)
		_say("Nivel %d: elegirás la mejora al seguir jugando" % p.progress.level))

	_header("Armas")
	for wd: WeaponData in DebugOptions.list_resources("res://data/weapons"):
		var owned := p.weapons.get_weapon(wd.id)
		var names: Array[String] = ["Sin ella"]
		for lv in range(1, wd.max_level + 1): names.append("Nivel %d" % lv)
		_choice(wd.display_name, names, owned.level if owned else 0, func(i: int) -> void:
			var levels: Dictionary = DebugOptions.get_value("weapons", {})
			levels[String(wd.id)] = i
			DebugOptions.set_value("weapons", levels)
			DebugOptions.apply_weapons(p))
	_action("Todas las armas al máximo", func() -> void:
		var levels := {}
		for wd: WeaponData in DebugOptions.list_resources("res://data/weapons"): levels[String(wd.id)] = wd.max_level
		DebugOptions.set_value("weapons", levels)
		DebugOptions.apply_weapons(p)
		_refresh_all())

	_header("Mejoras pasivas")
	for up: UpgradeData in p.progress.upgrade_pool:
		var names: Array[String] = ["Sin ella"]
		for lv in range(1, up.max_level + 1): names.append("Nivel %d" % lv)
		_choice("%s  (%s)" % [up.display_name, up.description], names, int(p.progress.passives.get(up.id, 0)),
			func(i: int) -> void:
				var levels: Dictionary = DebugOptions.get_value("passives", {})
				levels[String(up.id)] = i
				DebugOptions.set_value("passives", levels)
				DebugOptions.rebuild_stats(p))

	_header("Enemigos")
	if d == null:
		var l := UiKit.label("Sin nivel (campo de pruebas): no hay oleadas.", 17, UiKit.TEXT_DIM)
		_list.add_child(l)
	else:
		var counts := DebugOptions.ENEMY_COUNTS
		var count_names: Array[String] = []
		for c in counts: count_names.append("Los del nivel" if c < 0 else str(c))
		_choice("Enemigos en pantalla", count_names, OptionRow.idx(counts, int(DebugOptions.get_value("enemies", -1)), 0),
			func(i: int) -> void:
				DebugOptions.set_value("enemies", counts[i])
				DebugOptions.apply_world(game)
				if counts[i] > 0 and d.alive.size() > counts[i]: _trim_enemies(counts[i]))
		var kinds := DebugOptions.list_resources("res://data/enemies")
		var kind_names: Array[String] = ["Todos los del nivel"]
		var kind_ids: Array[String] = [""]
		for e: EnemyData in kinds:
			kind_names.append("Solo " + e.display_name)
			kind_ids.append(String(e.id))
		_choice("Tipo", kind_names, OptionRow.idx(kind_ids, String(DebugOptions.get_value("enemy_kind", "")), 0),
			func(i: int) -> void:
				DebugOptions.set_value("enemy_kind", kind_ids[i])
				DebugOptions.apply_world(game))
		_toggle("Oleadas en pausa", d.spawning_paused, func(on: bool) -> void:
			DebugOptions.set_value("spawning_paused", on)
			DebugOptions.apply_world(game))
		_action("Matar a todos", func() -> void:
			var n := d.alive.size()
			_trim_enemies(0)
			_say("%d enemigos abatidos" % n))
		_action("Lanzar el evento final", func() -> void:
			d.trigger_final()
			_say("Evento final lanzado"))

	_header("Partida")
	var scales := DebugOptions.TIME_SCALES
	_choice("Velocidad del juego", OptionRow.fmt(scales, "x%s", 1.0), OptionRow.idx(scales, float(DebugOptions.get_value("time_scale", 1.0)), 2),
		func(i: int) -> void: DebugOptions.set_value("time_scale", scales[i]))     # se aplica al volver
	var cams := DebugOptions.CAMERA_SIZES
	var cam_now := (game.camera as GameCamera).view_size
	_choice("Altura visible de la cámara", OptionRow.fmt(cams, "%d m", 1.0), OptionRow.idx(cams, cam_now, 1), func(i: int) -> void:
		DebugOptions.set_value("camera", cams[i])
		(game.camera as GameCamera).view_size = cams[i])
	_toggle("Información en pantalla (FPS, enemigos, balas)", DebugOptions.get_value("info", false), func(on: bool) -> void:
		DebugOptions.set_value("info", on))
	_toggle("Música", not Music.is_muted(), func(on: bool) -> void: Music.set_muted(not on))
	_action("Restablecer todo y reiniciar", func() -> void:
		DebugOptions.clear()
		restart.emit())

## Quita enemigos hasta dejar `keep` vivos (los abate: sueltan su experiencia).
func _trim_enemies(keep: int) -> void:
	var d: WaveDirector = game.director
	var list := d.alive.duplicate()
	for i in range(keep, list.size()):
		var e: Enemy = list[i]
		if is_instance_valid(e) and e.is_alive(): e.take_damage(Damage.new(1e9, 0.0))

func _header(text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = 6 if _list.get_child_count() > 0 else 0
	_list.add_child(gap)
	_list.add_child(UiKit.label(text.to_upper(), 18, ACCENT))

func _choice(title: String, names: Array[String], index: int, on_change: Callable) -> OptionRow:
	var r := OptionRow.new(title, names, clampi(index, 0, names.size() - 1), on_change, Callable(), UiKit.GOLD, ACCENT)
	_add(r)
	return r

func _toggle(title: String, on: bool, on_change: Callable) -> OptionRow:
	return _choice(title, ["No", "Sí"] as Array[String], 1 if on else 0, func(i: int) -> void: on_change.call(i == 1))

func _action(title: String, run: Callable) -> OptionRow:
	var r := OptionRow.new(title, [] as Array[String], 0, Callable(), run, UiKit.GOLD, ACCENT)
	_add(r)
	return r

func _add(r: OptionRow) -> void:
	_list.add_child(r)
	if _first == null: _first = r

func _refresh_all() -> void:
	var focus_idx := -1
	var focused := get_viewport().gui_get_focus_owner()
	for i in _list.get_child_count():
		if _list.get_child(i) == focused: focus_idx = i
	for c in _list.get_children(): c.queue_free()
	_first = null
	await get_tree().process_frame
	_build()
	if focus_idx >= 0 and focus_idx < _list.get_child_count() and _list.get_child(focus_idx) is OptionRow:
		(_list.get_child(focus_idx) as OptionRow).grab_focus()
	elif _first: _first.grab_focus()
