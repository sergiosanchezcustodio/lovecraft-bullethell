class_name SettingsMenu
extends Control
## Configuración: pestañas de vídeo, audio, controles, juego y nube (hito 10.3). Cada cambio se aplica y se
## guarda al momento (Settings). LB/RB o Q/E cambian de pestaña; B / Esc cierra.
## Controles: al confirmar una fila se espera la tecla o el botón nuevo (Esc cancela). Si
## otra acción lo usaba, se intercambian.

signal closed

const TABS := ["Vídeo", "Audio", "Controles", "Juego", "Nube"]

var _tab := 0
var _head: Label                         ## el título, para la ruta (hito 20.5)
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
	_head = MenuKit.heading(box, L.t("Configuración"), 48)
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
	scroll.add_child(margin)
	MenuKit.scroll_gutter(scroll, margin)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	margin.add_child(_list)
	Cloud.changed.connect(_on_cloud_changed)
	box.add_child(MenuKit.hint(L.t("Arriba/abajo: elegir  ·  Izquierda/derecha o A: cambiar  ·  LB/RB o Q/E: pestaña  ·  B o Esc: volver")))
	_show_tab(0)

func _show_tab(i: int) -> void:
	_capture = {}
	_tab = i
	MenuKit.crumb_tail(_head, TABS[i])
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
	var row := LaunchArgs.from_cmdline().get_int("focus_row", -1)      # capturas: focus_row=N elige la fila N
	if row >= 0:
		var rows := _list.get_children().filter(func(c: Node) -> bool: return c is OptionRow)
		if row < rows.size(): _first = rows[row]
	if _first: _first.grab_focus.call_deferred()

# ---------------------------------------------------------------- pestañas

func _video() -> void:
	_choice(L.t("Perfil de ajustes"), Settings.PROFILES, int(Settings.get_value("profile")), func(i: int) -> void:
		Settings.switch_profile(i)
		_show_tab.call_deferred(0))
	_note(L.t("Cada perfil guarda lo de esta pestaña y el tamaño de la interfaz: cámbialo al pasar de la tele o el monitor a un portátil o a la Steam Deck."))
	_toggle(L.t("Pantalla completa"), Settings.get_value("fullscreen"), func(on: bool) -> void:
		Settings.set_value("fullscreen", on)
		Settings.apply_video())
	var res: Array[String] = []
	for r in Settings.RESOLUTIONS: res.append("%d × %d" % [r.x, r.y])
	_choice(L.t("Tamaño de la ventana"), res, int(Settings.get_value("resolution")), func(i: int) -> void:
		Settings.set_value("resolution", i)
		Settings.apply_video())
	_toggle(L.t("Sincronización vertical"), Settings.get_value("vsync"), func(on: bool) -> void:
		Settings.set_value("vsync", on)
		Settings.apply_video())
	var fps: Array[String] = []
	for f in Settings.FPS_LIMITS: fps.append("Sin límite" if f == 0 else str(f))
	_choice(L.t("Límite de FPS"), fps, OptionRow.idx(Settings.FPS_LIMITS, int(Settings.get_value("fps_limit")), 0), func(i: int) -> void:
		Settings.set_value("fps_limit", Settings.FPS_LIMITS[i])
		Settings.apply_video())
	var preview := VideoPreview.new()              # (hito 20.12), encima: al bajar a la calidad, se ve
	_list.add_child(preview)
	_choice(L.t("Calidad gráfica"), Quality.names(), int(Settings.get_value("quality")), func(i: int) -> void:
		Settings.set_value("quality", i)
		Settings.apply_video()
		preview.refresh())
	_note(L.t("Suavizado, sombras, oclusión ambiental (Ultra), niebla de los faroles, enemigos que se desmoronan y manchas. Lo de la partida cambia al empezar el siguiente nivel."))
	var wfx: Array[String] = [L.t("Mínimos"), "Rebajados", "Enteros", L.t("Automático")]
	_choice(L.t("Efectos de las armas"), wfx, int(Settings.get_value("weapon_fx")), func(i: int) -> void:
		Settings.set_value("weapon_fx", i)
		preview.refresh())
	_note(L.t("Estelas, chispas, casquillos y acentos de las evoluciones. «Automático»: enteros con uno o dos jugadores y mínimos con tres o cuatro, para leer mejor la pantalla y que vaya más fluido. Nunca pasan de lo que permite la calidad gráfica."))
	_action(L.t("Ajustes para Steam Deck y portátiles"), func() -> void:
		Settings.apply_handheld()
		_show_tab(0))
	_note(L.t("Pasa al perfil Portátil y le pone pantalla completa, 40 fps con sincronía, calidad Baja e interfaz Grande. En una Steam Deck se ponen solos la primera vez."))
	_choice(L.t("Resolución del 3D (rendimiento)"), OptionRow.fmt(Settings.SCALES_3D, "%d %%", 100.0),
		OptionRow.idx(Settings.SCALES_3D, float(Settings.get_value("scale_3d")), 3), func(i: int) -> void:
			Settings.set_value("scale_3d", Settings.SCALES_3D[i])
			Settings.apply_video())
	var steps: Array[String] = []
	for k in Settings.BRIGHTNESS.size(): steps.append("%+d" % (k - 3) if k != 3 else "0")
	var pattern := BrightnessPattern.new()
	_choice("Brillo", steps, int(Settings.get_value("brightness")), func(i: int) -> void:
		Settings.set_value("brightness", i)
		pattern.queue_redraw()
		preview.refresh())
	_list.add_child(pattern)
	_note(L.t("Ajusta hasta que el ojo de la izquierda apenas se vea y el de la derecha se vea bien."))
	_reset_tab("video", L.t("el vídeo"), 0)

func _audio() -> void:
	for pair in [[L.t("Volumen general"), "vol_master"], [L.t("Música"), "vol_music"], ["Efectos", "vol_sfx"],
			[L.t("Armas e impactos"), "vol_weapons"], [L.t("Ambiente de los escenarios"), "vol_ambient"]]:
		var key: String = pair[1]
		var steps: Array[String] = []
		for k in 11: steps.append("%d %%" % (k * 10))
		_choice(pair[0], steps, int(round(float(Settings.get_value(key)) * 10.0)), func(i: int) -> void:
			Settings.set_value(key, i / 10.0)
			Settings.apply_audio())
	_toggle(L.t("Música que crece con el combate"), Settings.get_value("music_layers"), func(on: bool) -> void:
		Settings.set_value("music_layers", on))
	_note(L.t("Suma percusión y coros a la pista cuantos más enemigos hay; con el jefe, solo los coros."))
	_toggle(L.t("Avisos de lo que llega de fuera de la pantalla"), Settings.get_value("offscreen_cues"), func(on: bool) -> void:
		Settings.set_value("offscreen_cues", on))
	_note(L.t("Las élites y los ataques fuertes que no se ven suenan por su lado y se marcan en el borde."))
	_reset_tab("audio", L.t("el audio"), 1)

func _controls() -> void:
	_header("Teclado")
	for pair in Settings.REMAP_ACTIONS:
		_remap_row(pair[0], pair[1], false)
	_note(L.t("Las flechas también mueven, sea cual sea la tecla elegida."))
	_header("Mando")
	for pair in Settings.REMAP_ACTIONS:
		if pair[0] in [&"up", &"down", &"left", &"right"]: continue
		_remap_row(pair[0], pair[1], true)
	_note(L.t("El mando se mueve con el stick izquierdo o con la cruceta."))
	_action(L.t("Restablecer los controles de fábrica"), func() -> void:
		Settings.reset_controls()
		_show_tab(2))

func _game() -> void:
	var dist: Array[String] = ["Desactivadas", "25 %", "50 %", "75 %", "100 %"]
	_choice(L.t("Distorsiones de pantalla (cordura baja)"), dist, int(round(float(Settings.get_value("distortion")) * 4.0)), func(i: int) -> void:
		Settings.set_value("distortion", i / 4.0))
	_note(L.t("Nunca ocultan ni falsean las balas. Desactívalas si te marean."))
	_toggle(L.t("Alucinaciones (cordura baja)"), Settings.get_value("hallucinations"), func(on: bool) -> void:
		Settings.set_value("hallucinations", on))
	_note(L.t("Por debajo del 30 % de cordura ves criaturas y gemas que no están y tu panel miente un momento. No hacen daño."))
	var wx: Array[String] = ["Apagado", "Reducido", "Completo"]
	var wpre := VideoPreview.new("weather")         # (hito 20.12), encima de su fila
	_list.add_child(wpre)
	_choice(L.t("Clima (nieve, lluvia, niebla…)"), wx, int(Settings.get_value("weather")), func(i: int) -> void:
		Settings.set_value("weather", i)
		wpre.refresh())
	# La dificultad está en la pausa, del 1 al 10 por características, mientras el autor la calibra (D-42)
	_toggle(L.t("Locura acumulada (cada crisis baja la cordura máxima)"), Settings.get_value("madness"), func(on: bool) -> void:
		Settings.set_value("madness", on))
	_toggle(L.t("Consejos en la partida"), Settings.get_value("tips"), func(on: bool) -> void:
		Settings.set_value("tips", on))
	if Saves.current != null and Saves.current.has_seen("tips", "move"):
		_action(L.t("Volver a ver los consejos"), func() -> void:      # en este hueco (hito 13.3)
			Saves.current.seen["tips"] = []
			Saves.save()
			_show_tab(3))
	_note("Accesibilidad")
	var sizes: Array[String] = [L.t("Pequeño (desde 1080 de alto)"), "Normal", "Grande", L.t("Muy grande")]
	_choice(L.t("Tamaño de la interfaz"), sizes, int(Settings.get_value("ui_scale")), func(i: int) -> void:
		Settings.set_value("ui_scale", i)
		Settings.apply_ui())
	_choice(L.t("Texto de los relatos y el diario"), Reading.NAMES, int(Settings.get_value("reading_size")), func(i: int) -> void:
		Settings.set_value("reading_size", i))
	_toggle(L.t("Más contraste en los relatos y el diario"), Settings.get_value("reading_contrast"), func(on: bool) -> void:
		Settings.set_value("reading_contrast", on))
	_note(L.t("Aparte del tamaño de la interfaz, que se suma encima."))
	var pal: Array[String] = ["Normales", L.t("Alto contraste")]
	_choice(L.t("Colores de las balas"), pal, int(Settings.get_value("bullet_palette")), func(i: int) -> void:
		Settings.set_value("bullet_palette", i)
		Flashes.refresh())
	_note(L.t("Alto contraste: físicas en amarillo y blanco, mentales en cian. Se distinguen también por la forma: bola maciza o anillo. Los efectos de tus armas, más grises y tenues."))
	var fl: Array[String] = ["Reducidos", "Normales"]
	_choice(L.t("Destellos (golpes y rayos)"), fl, int(Settings.get_value("flashes")), func(i: int) -> void:
		Settings.set_value("flashes", i)
		Flashes.refresh())
	var sh: Array[String] = [L.t("Sin temblor"), "25 %", "50 %", "75 %", "100 %"]
	_choice(L.t("Temblor de la cámara"), sh, int(round(float(Settings.get_value("shake")) * 4.0)), func(i: int) -> void:
		Settings.set_value("shake", i / 4.0))
	var dn: Array[String] = ["No", L.t("Solo los golpes fuertes"), "Todos"]
	_choice(L.t("Números de daño"), dn, DamageNumbers.mode_of(Settings.get_value("damage_numbers")), func(i: int) -> void:
		Settings.set_value("damage_numbers", i)
		DamageNumbers.set_mode(i))
	_choice(L.t("Velocidad del juego"), OptionRow.fmt(Settings.GAME_SPEEDS, "%d %%", 100.0),
		OptionRow.idx(Settings.GAME_SPEEDS, float(Settings.get_value("game_speed")), 3), func(i: int) -> void:
		Settings.set_value("game_speed", Settings.GAME_SPEEDS[i]))
	_note(L.t("Todo va más despacio o más deprisa: enemigos, balas y tú. En la partida online, siempre al 100 %."))
	_toggle(L.t("Pausa al perder el foco o desconectar un mando"), Settings.get_value("auto_pause"), func(on: bool) -> void:
		Settings.set_value("auto_pause", on))
	var intro: Array[String] = ["Siempre", L.t("Solo la primera vez")]
	_choice(L.t("Ficha e intro al arrancar"), intro, int(Settings.get_value("intro")), func(i: int) -> void:
		Settings.set_value("intro", i))
	_choice(L.t("Vibración del mando"), Rumble.NAMES, Rumble.level_index(Settings.get_value("vibration")), func(i: int) -> void:
		Settings.set_value("vibration", Rumble.LEVELS[i])
		if i > 0 and Devices.last_device >= 0: Input.start_joy_vibration(Devices.last_device, 0.3 * Rumble.LEVELS[i], 0.5 * Rumble.LEVELS[i], 0.2))   # para notarla (16.30)
	_note(L.t("Al recibir golpes, con las explosiones cercanas, los jefes, las subidas de nivel y las crisis de cordura."))
	var fpsm: Array[String] = ["No", "FPS", "Detallado"]
	_choice(L.t("Mostrar FPS"), fpsm, Settings.fps_mode(), func(i: int) -> void:
		Settings.set_value("show_fps", i)
		Settings.apply_video())
	_note(L.t("Detallado: también lo que tarda cada fotograma, de media y en el 1 % peor (los tirones), de los últimos 300."))
	_reset_tab("game", L.t("lo de esta pestaña (juego y accesibilidad)"), 3)
	_action(L.t("Restablecer toda la configuración"), func() -> void:
		var c := MenuKit.Confirm.new(L.t("¿Restablecer toda la configuración (vídeo, audio, controles y juego)?"), "Restablecer")
		add_child(c)
		c.answered.connect(func(yes: bool) -> void:
			if yes: Settings.reset_all()
			_show_tab(3)))

## Copia de las partidas en la nube (fase 10): conectar, sincronizar y desconectar.
func _cloud() -> void:
	_header(L.t("Copia en la nube con GitHub"))
	_cloud_status = UiKit.label(_cloud_text(), 20, UiKit.TEXT)
	_cloud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(_cloud_status)
	if not Cloud.connected():
		var open := func() -> void:
			var m := CloudConnectMenu.new()
			add_child(m)
			m.closed.connect(_show_tab.bind(4))
		_action(L.t("Conectar con GitHub"), open)
		if Cloud.demo in ["codigo", "bajadas"] and not _demo_opened:   # capturas: `cloud_demo=codigo|bajadas`
			_demo_opened = true
			open.call_deferred()
		_note(L.t("Guarda una copia de tus tres partidas y de tus controles en un gist secreto de tu cuenta de GitHub, para seguir jugando en otro PC. Las partidas siguen guardándose aquí como siempre: sin conexión se juega igual."))
		_note(L.t("Hace falta una cuenta de GitHub (gratis). El juego solo pide permiso para los gists."))
		return
	_toggle(L.t("Subir cada partida al guardarla"), Cloud.auto, func(on: bool) -> void:
		Cloud.auto = on
		Cloud.save_file())
	var now := _action(L.t("Sincronizar ahora"), Callable())
	now.run = func() -> void:
		if Cloud.syncing: return
		now.set_value_text("Sincronizando…")
		await Cloud.sync()
		if not is_instance_valid(now): return
		now.set_value_text("")
		await CloudConflictMenu.resolve_all(self)
		if is_inside_tree(): _show_tab(4)
	if Cloud.gist_url() != "":
		_action(L.t("Ver la copia en GitHub"), func() -> void:
			if Cloud.demo == "": OS.shell_open(Cloud.gist_url()))   # capturas: sin navegador
	_action(L.t("Desconectar este PC"), func() -> void:
		var c := MenuKit.Confirm.new(L.t("¿Desconectar la cuenta de GitHub de este PC?

La copia se queda en la nube y tus partidas, aquí."), "Desconectar")
		add_child(c)
		c.answered.connect(func(yes: bool) -> void:
			if yes: Cloud.disconnect_github()
			_show_tab(4)))
	_note(L.t("Se suben las tres partidas y los controles; el vídeo y el audio son de cada PC. Al abrir la elección de partida se baja lo jugado en otros PC. Si una partida ha cambiado aquí y en otro PC, el juego pregunta con cuál quedarse."))
	_note(L.t("El gist es secreto: no aparece en tu perfil, pero lo puede abrir quien tenga su enlace. Las partidas no llevan datos personales."))

func _on_cloud_changed() -> void:
	if _cloud_status != null and is_instance_valid(_cloud_status): _cloud_status.text = _cloud_text()

func _cloud_text() -> String:
	if not Cloud.connected():
		var e := Cloud.error_text(Cloud.error)
		return "Sin conectar." + ("  " + e if e != "" else "")
	var t := L.t("Conectado como %s.") % Cloud.login
	if Cloud.syncing: t += L.t("  Sincronizando…")
	elif Cloud.error != "": t += "  " + Cloud.error_text(Cloud.error)
	elif Cloud.last_sync != "": t += "  Última copia: %s." % Cloud.when(Cloud.last_sync)
	if not Cloud.conflicts.is_empty(): t += L.t("  %s por decidir.") % MenuKit.count(Cloud.conflicts.size(), "partida")
	return t

# ---------------------------------------------------------------- controles: captura

func _remap_row(action: StringName, label: String, joy: bool) -> void:
	var r := _action(label, Callable())
	var show := func() -> void:
		r.set_value_text(Settings.joy_name(Settings.joy_for(action)) if joy else Settings.key_name(Settings.key_for(action)))
	show.call()
	r.run = func() -> void:
		_capture = {"row": r, "action": action, "joy": joy, "show": show}
		r.set_value_text(L.t("Pulsa un botón del mando…  (Esc: cancelar)") if joy else L.t("Pulsa una tecla…  (Esc: cancelar)"))
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

## «Restablecer esta pestaña» (hito 20.15): solo sus valores (`Settings.GROUPS`), con confirmación.
func _reset_tab(group: String, what: String, tab: int) -> void:
	_action(L.t("Restablecer esta pestaña"), func() -> void:
		var c := MenuKit.Confirm.new(L.t("¿Volver a dejar %s como de fábrica?") % what, "Restablecer")
		add_child(c)
		c.answered.connect(func(yes: bool) -> void:
			if yes: Settings.reset_group(group)
			_show_tab(tab)))

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
