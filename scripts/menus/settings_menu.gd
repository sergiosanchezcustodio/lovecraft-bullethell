class_name SettingsMenu
extends Control
## Configuración: pestañas de vídeo, audio, controles, juego y nube (hito 10.3). Cada cambio se aplica y se
## guarda al momento (Settings). LB/RB o Q/E cambian de pestaña; B / Esc cierra.
## Controles: al confirmar una fila se espera la tecla o el botón nuevo (Esc cancela). Si
## otra acción lo usaba, se intercambian.

signal closed

const TABS := ["Vídeo", "Audio", "Controles", "Juego", "Nube"]

var _tab := 0
var _tabs: Array[Button] = []
var _list: VBoxContainer
var _first: Control
var _cloud_status: Label
var _demo_opened := false
var _capture: Dictionary = {}            ## {"row", "action", "joy"} mientras se espera una tecla o botón

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, MenuKit.INK, 900)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Configuración", 48)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 12)
	box.add_child(tabs)
	for i in TABS.size():
		var b := MenuKit.button(TABS[i], MenuKit.INK, 24)
		b.custom_minimum_size = Vector2(190, 50)
		b.focus_mode = Control.FOCUS_NONE              # se cambian con LB/RB, Q/E o el ratón
		b.pressed.connect(_show_tab.bind(i))
		tabs.add_child(b)
		_tabs.append(b)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(840, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_right", 14)
	scroll.add_child(margin)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	margin.add_child(_list)
	Cloud.changed.connect(_on_cloud_changed)
	box.add_child(MenuKit.hint("Arriba/abajo: elegir  ·  Izquierda/derecha o A: cambiar  ·  LB/RB o Q/E: pestaña  ·  B o Esc: volver"))
	_show_tab(0)

func _show_tab(i: int) -> void:
	_capture = {}
	_tab = i
	for k in _tabs.size():
		_tabs[k].add_theme_color_override("font_color", MenuKit.INK if k == i else UiKit.TEXT_DIM)
		_tabs[k].add_theme_stylebox_override("normal", MenuKit.box(Color(0.16, 0.1, 0.05, 0.9) if k == i else Color(0.04, 0.03, 0.025, 0.6),
			Color(MenuKit.BRASS, 0.95 if k == i else 0.25), 2 if k == i else 1))
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_first = null
	_cloud_status = null
	match i:
		0: _video()
		1: _audio()
		2: _controls()
		3: _game()
		4: _cloud()
	if _first: _first.grab_focus.call_deferred()

# ---------------------------------------------------------------- pestañas

func _video() -> void:
	_toggle("Pantalla completa", Settings.get_value("fullscreen"), func(on: bool) -> void:
		Settings.set_value("fullscreen", on)
		Settings.apply_video())
	var res: Array[String] = []
	for r in Settings.RESOLUTIONS: res.append("%d × %d" % [r.x, r.y])
	_choice("Tamaño de la ventana", res, int(Settings.get_value("resolution")), func(i: int) -> void:
		Settings.set_value("resolution", i)
		Settings.apply_video())
	_toggle("Sincronización vertical", Settings.get_value("vsync"), func(on: bool) -> void:
		Settings.set_value("vsync", on)
		Settings.apply_video())
	var fps: Array[String] = []
	for f in Settings.FPS_LIMITS: fps.append("Sin límite" if f == 0 else str(f))
	_choice("Límite de FPS", fps, OptionRow.idx(Settings.FPS_LIMITS, int(Settings.get_value("fps_limit")), 0), func(i: int) -> void:
		Settings.set_value("fps_limit", Settings.FPS_LIMITS[i])
		Settings.apply_video())
	_choice("Calidad gráfica", Quality.names(), int(Settings.get_value("quality")), func(i: int) -> void:
		Settings.set_value("quality", i)
		Settings.apply_video())
	_note("Suavizado, sombras, oclusión ambiental (Ultra), niebla de los faroles, enemigos que se desmoronan y manchas. Lo de la partida cambia al empezar el siguiente nivel.")
	_choice("Resolución del 3D (rendimiento)", OptionRow.fmt(Settings.SCALES_3D, "%d %%", 100.0),
		OptionRow.idx(Settings.SCALES_3D, float(Settings.get_value("scale_3d")), 3), func(i: int) -> void:
			Settings.set_value("scale_3d", Settings.SCALES_3D[i])
			Settings.apply_video())
	var steps: Array[String] = []
	for k in Settings.BRIGHTNESS.size(): steps.append("%+d" % (k - 3) if k != 3 else "0")
	var pattern := BrightnessPattern.new()
	_choice("Brillo", steps, int(Settings.get_value("brightness")), func(i: int) -> void:
		Settings.set_value("brightness", i)
		pattern.queue_redraw())
	_list.add_child(pattern)
	_note("Ajusta hasta que el ojo de la izquierda apenas se vea y el de la derecha se vea bien.")

func _audio() -> void:
	for pair in [["Volumen general", "vol_master"], ["Música", "vol_music"], ["Efectos", "vol_sfx"],
			["Armas e impactos", "vol_weapons"], ["Ambiente de los escenarios", "vol_ambient"]]:
		var key: String = pair[1]
		var steps: Array[String] = []
		for k in 11: steps.append("%d %%" % (k * 10))
		_choice(pair[0], steps, int(round(float(Settings.get_value(key)) * 10.0)), func(i: int) -> void:
			Settings.set_value(key, i / 10.0)
			Settings.apply_audio())
	_toggle("Música que crece con el combate", Settings.get_value("music_layers"), func(on: bool) -> void:
		Settings.set_value("music_layers", on))
	_note("Suma percusión y coros a la pista cuantos más enemigos hay; con el jefe, solo los coros.")
	_toggle("Avisos de lo que llega de fuera de la pantalla", Settings.get_value("offscreen_cues"), func(on: bool) -> void:
		Settings.set_value("offscreen_cues", on))
	_note("Las élites y los ataques fuertes que no se ven suenan por su lado y se marcan en el borde.")

func _controls() -> void:
	_header("Teclado")
	for pair in Settings.REMAP_ACTIONS:
		_remap_row(pair[0], pair[1], false)
	_note("Las flechas también mueven, sea cual sea la tecla elegida.")
	_header("Mando")
	for pair in Settings.REMAP_ACTIONS:
		if pair[0] in [&"up", &"down", &"left", &"right"]: continue
		_remap_row(pair[0], pair[1], true)
	_note("El mando se mueve con el stick izquierdo o con la cruceta.")
	_action("Restablecer los controles de fábrica", func() -> void:
		Settings.reset_controls()
		_show_tab(2))

func _game() -> void:
	var dist: Array[String] = ["Desactivadas", "25 %", "50 %", "75 %", "100 %"]
	_choice("Distorsiones de pantalla (cordura baja)", dist, int(round(float(Settings.get_value("distortion")) * 4.0)), func(i: int) -> void:
		Settings.set_value("distortion", i / 4.0))
	_note("Nunca ocultan ni falsean las balas. Desactívalas si te marean.")
	_toggle("Alucinaciones (cordura baja)", Settings.get_value("hallucinations"), func(on: bool) -> void:
		Settings.set_value("hallucinations", on))
	_note("Por debajo del 30 % de cordura ves criaturas y gemas que no están y tu panel miente un momento. No hacen daño.")
	var wx: Array[String] = ["Apagado", "Reducido", "Completo"]
	_choice("Clima (nieve, lluvia, niebla…)", wx, int(Settings.get_value("weather")), func(i: int) -> void:
		Settings.set_value("weather", i))
	# La dificultad está en la pausa, del 1 al 10 por características, mientras el autor la calibra (D-42)
	_toggle("Locura acumulada (cada crisis baja la cordura máxima)", Settings.get_value("madness"), func(on: bool) -> void:
		Settings.set_value("madness", on))
	_toggle("Consejos en la partida", Settings.get_value("tips"), func(on: bool) -> void:
		Settings.set_value("tips", on))
	if Saves.current != null and Saves.current.has_seen("tips", "move"):
		_action("Volver a ver los consejos", func() -> void:      # en este hueco (hito 13.3)
			Saves.current.seen["tips"] = []
			Saves.save()
			_show_tab(3))
	_note("Accesibilidad")
	var sizes: Array[String] = ["Pequeño", "Normal", "Grande", "Muy grande"]
	_choice("Tamaño de la interfaz", sizes, int(Settings.get_value("ui_scale")), func(i: int) -> void:
		Settings.set_value("ui_scale", i)
		Settings.apply_ui())
	var pal: Array[String] = ["Normales", "Alto contraste"]
	_choice("Colores de las balas", pal, int(Settings.get_value("bullet_palette")), func(i: int) -> void:
		Settings.set_value("bullet_palette", i))
	_note("Alto contraste: físicas en amarillo y blanco, mentales en cian. Se distinguen también por la forma: bola maciza o anillo.")
	var fl: Array[String] = ["Reducidos", "Normales"]
	_choice("Destellos (golpes y rayos)", fl, int(Settings.get_value("flashes")), func(i: int) -> void:
		Settings.set_value("flashes", i))
	var sh: Array[String] = ["Sin temblor", "25 %", "50 %", "75 %", "100 %"]
	_choice("Temblor de la cámara", sh, int(round(float(Settings.get_value("shake")) * 4.0)), func(i: int) -> void:
		Settings.set_value("shake", i / 4.0))
	var dn: Array[String] = ["No", "Solo los golpes fuertes", "Todos"]
	_choice("Números de daño", dn, DamageNumbers.mode_of(Settings.get_value("damage_numbers")), func(i: int) -> void:
		Settings.set_value("damage_numbers", i)
		DamageNumbers.set_mode(i))
	var intro: Array[String] = ["Siempre", "Solo la primera vez"]
	_choice("Ficha e intro al arrancar", intro, int(Settings.get_value("intro")), func(i: int) -> void:
		Settings.set_value("intro", i))
	_toggle("Vibración del mando", Settings.get_value("vibration"), func(on: bool) -> void:
		Settings.set_value("vibration", on))
	_toggle("Mostrar FPS", Settings.get_value("show_fps"), func(on: bool) -> void:
		Settings.set_value("show_fps", on)
		Settings.apply_video())
	_action("Restablecer toda la configuración", func() -> void:
		var c := MenuKit.Confirm.new("¿Restablecer toda la configuración (vídeo, audio, controles y juego)?", "Restablecer")
		add_child(c)
		c.answered.connect(func(yes: bool) -> void:
			if yes: Settings.reset_all()
			_show_tab(3)))

## Copia de las partidas en la nube (fase 10): conectar, sincronizar y desconectar.
func _cloud() -> void:
	_header("Copia en la nube con GitHub")
	_cloud_status = UiKit.label(_cloud_text(), 20, UiKit.TEXT)
	_cloud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(_cloud_status)
	if not Cloud.connected():
		var open := func() -> void:
			var m := CloudConnectMenu.new()
			add_child(m)
			m.closed.connect(_show_tab.bind(4))
		_action("Conectar con GitHub", open)
		if Cloud.demo in ["codigo", "bajadas"] and not _demo_opened:   # capturas: `cloud_demo=codigo|bajadas`
			_demo_opened = true
			open.call_deferred()
		_note("Guarda una copia de tus tres partidas y de tus controles en un gist secreto de tu cuenta de GitHub, para seguir jugando en otro PC. Las partidas siguen guardándose aquí como siempre: sin conexión se juega igual.")
		_note("Hace falta una cuenta de GitHub (gratis). El juego solo pide permiso para los gists.")
		return
	_toggle("Subir cada partida al guardarla", Cloud.auto, func(on: bool) -> void:
		Cloud.auto = on
		Cloud.save_file())
	var now := _action("Sincronizar ahora", Callable())
	now.run = func() -> void:
		if Cloud.syncing: return
		now.set_value_text("Sincronizando…")
		await Cloud.sync()
		if not is_instance_valid(now): return
		now.set_value_text("")
		await CloudConflictMenu.resolve_all(self)
		if is_inside_tree(): _show_tab(4)
	if Cloud.gist_url() != "":
		_action("Ver la copia en GitHub", func() -> void:
			if Cloud.demo == "": OS.shell_open(Cloud.gist_url()))   # capturas: sin navegador
	_action("Desconectar este PC", func() -> void:
		var c := MenuKit.Confirm.new("¿Desconectar la cuenta de GitHub de este PC?

La copia se queda en la nube y tus partidas, aquí.", "Desconectar")
		add_child(c)
		c.answered.connect(func(yes: bool) -> void:
			if yes: Cloud.disconnect_github()
			_show_tab(4)))
	_note("Se suben las tres partidas y los controles; el vídeo y el audio son de cada PC. Al abrir la elección de partida se baja lo jugado en otros PC. Si una partida ha cambiado aquí y en otro PC, el juego pregunta con cuál quedarse.")
	_note("El gist es secreto: no aparece en tu perfil, pero lo puede abrir quien tenga su enlace. Las partidas no llevan datos personales.")

func _on_cloud_changed() -> void:
	if _cloud_status != null and is_instance_valid(_cloud_status): _cloud_status.text = _cloud_text()

func _cloud_text() -> String:
	if not Cloud.connected():
		var e := Cloud.error_text(Cloud.error)
		return "Sin conectar." + ("  " + e if e != "" else "")
	var t := "Conectado como %s." % Cloud.login
	if Cloud.syncing: t += "  Sincronizando…"
	elif Cloud.error != "": t += "  " + Cloud.error_text(Cloud.error)
	elif Cloud.last_sync != "": t += "  Última copia: %s." % Cloud.when(Cloud.last_sync)
	if not Cloud.conflicts.is_empty(): t += "  %s por decidir." % MenuKit.count(Cloud.conflicts.size(), "partida")
	return t

# ---------------------------------------------------------------- controles: captura

func _remap_row(action: StringName, label: String, joy: bool) -> void:
	var r := _action(label, Callable())
	var show := func() -> void:
		r.set_value_text(Settings.joy_name(Settings.joy_for(action)) if joy else Settings.key_name(Settings.key_for(action)))
	show.call()
	r.run = func() -> void:
		_capture = {"row": r, "action": action, "joy": joy, "show": show}
		r.set_value_text("Pulsa un botón del mando…  (Esc: cancelar)" if joy else "Pulsa una tecla…  (Esc: cancelar)")
	r.text = label

func _input(event: InputEvent) -> void:
	if _capture.is_empty(): return
	var done := false
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE: done = true
		elif not _capture.joy:
			Settings.set_key(_capture.action, k)
			done = true
	elif event is InputEventJoypadButton and event.pressed and _capture.joy:
		Settings.set_joy(_capture.action, (event as InputEventJoypadButton).button_index)
		done = true
	if done:
		get_viewport().set_input_as_handled()
		_capture = {}
		_show_tab.call_deferred(2)                     # redibuja: puede haberse intercambiado otra

func _unhandled_input(event: InputEvent) -> void:
	if not _capture.is_empty() or get_child_count() > 1 and get_child(get_child_count() - 1) is MenuKit.Confirm: return
	if get_child(get_child_count() - 1) is CloudConnectMenu or get_child(get_child_count() - 1) is CloudConflictMenu: return
	var tab_step := 0
	if event is InputEventJoypadButton and event.pressed:
		var b := (event as InputEventJoypadButton).button_index
		if b == JOY_BUTTON_LEFT_SHOULDER: tab_step = -1
		elif b == JOY_BUTTON_RIGHT_SHOULDER: tab_step = 1
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_Q: tab_step = -1
		elif k == KEY_E: tab_step = 1
	if tab_step != 0:
		get_viewport().set_input_as_handled()
		_show_tab(posmod(_tab + tab_step, TABS.size()))
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()

# ---------------------------------------------------------------- filas

func _header(text: String) -> void:
	if _list.get_child_count() > 0:
		var gap := Control.new(); gap.custom_minimum_size.y = 6
		_list.add_child(gap)
	_list.add_child(UiKit.label(text.to_upper(), 18, MenuKit.INK))

func _note(text: String) -> void:
	var l := UiKit.label(text, 16, UiKit.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(l)

func _choice(title: String, names: Array[String], index: int, on_change: Callable) -> OptionRow:
	var r := OptionRow.new(title, names, clampi(index, 0, names.size() - 1), on_change, Callable(), MenuKit.INK)
	_add(r)
	return r

func _toggle(title: String, on: bool, on_change: Callable) -> OptionRow:
	return _choice(title, ["No", "Sí"] as Array[String], 1 if on else 0, func(i: int) -> void: on_change.call(i == 1))

func _action(title: String, run: Callable) -> OptionRow:
	var r := OptionRow.new(title, [] as Array[String], 0, Callable(), run if run.is_valid() else func() -> void: pass, MenuKit.INK)
	_add(r)
	return r

func _add(r: OptionRow) -> void:
	_list.add_child(r)
	if _first == null: _first = r
