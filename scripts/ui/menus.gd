class_name Menus
extends RefCounted
## Menús de la partida: subida de nivel (elige 1 de 3 mejoras; pausa la partida en
## solitario, D-16), pausa y fin de partida (caída o nivel superado). Todos son capas
## que siguen funcionando con el árbol en pausa y se manejan con teclado, mando o ratón.
## La pausa y el fin de partida van en una ventana de biblioteca gótica (MenuKit, 27-10-2026).
## LevelUpMenu ya no lo abre la partida (CoopLevelUp); se queda para sus tests.


## Subida de nivel: tres tarjetas; se elige con las flechas o la cruceta y
## confirmar (Intro / A), con las teclas 1-3 o con el ratón. Durante el primer medio
## segundo no acepta pulsaciones, para no elegir sin querer mientras se esquiva o se
## dispara a la carrera.
class LevelUpMenu extends CanvasLayer:
	signal chosen(option: PlayerProgress.Option)
	var options: Array[PlayerProgress.Option] = []
	var title := ""
	var _buttons: Array[Button] = []
	var _ready_to_pick := false
	const INPUT_DELAY := 0.5

	func _init(p_options: Array[PlayerProgress.Option], p_title: String) -> void:
		options = p_options
		title = p_title
		layer = 20
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _ready() -> void:
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.02, 0.55)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		box.add_theme_constant_override("separation", 22)
		add_child(box)
		var t := UiKit.label(title, 34, UiKit.XP)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(t)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(row)
		for i in options.size():
			var o := options[i]
			var accent := _accent(o)
			var b := UiKit.button("%d   %s\n\n%s\n\n%s" % [i + 1, o.title(), o.text(), _kind(o)], accent, 20)
			b.custom_minimum_size = Vector2(330, 210)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.pressed.connect(_pick.bind(i))
			row.add_child(b)
			_buttons.append(b)
		var hint := UiKit.label("Flechas o cruceta para elegir · Intro o A para confirmar · 1, 2, 3", 15, UiKit.TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hint)
		box.resized.connect(func() -> void: box.position = (get_viewport().get_visible_rect().size - box.size) * 0.5)
		for b in _buttons: b.disabled = true
		get_tree().create_timer(INPUT_DELAY, true, false, true).timeout.connect(func() -> void:
			_ready_to_pick = true
			for b in _buttons: b.disabled = false
			if not _buttons.is_empty(): _buttons[0].grab_focus())

	func _accent(o: PlayerProgress.Option) -> Color:
		match o.kind:
			PlayerProgress.Option.Kind.NEW_WEAPON: return UiKit.GOLD
			PlayerProgress.Option.Kind.WEAPON_LEVEL: return Color(1.0, 0.55, 0.25)
		return o.upgrade.color

	func _kind(o: PlayerProgress.Option) -> String:
		match o.kind:
			PlayerProgress.Option.Kind.NEW_WEAPON: return "ARMA NUEVA"
			PlayerProgress.Option.Kind.WEAPON_LEVEL: return "MEJORA DE ARMA"
		return "PASIVA"

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			var k := (event as InputEventKey).keycode
			if _ready_to_pick and k >= KEY_1 and k <= KEY_3 and k - KEY_1 < options.size():
				_pick(k - KEY_1)
				get_viewport().set_input_as_handled()

	func _pick(i: int) -> void:
		if not _ready_to_pick: return
		_ready_to_pick = false
		chosen.emit(options[i])
		queue_free()


## Pausa (Esc o Start): continuar, reiniciar, depuración o salir.
class PauseMenu extends CanvasLayer:
	signal resume
	signal restart
	signal debug
	signal difficulty                           ## temporal (D-42): calibrar la dificultad
	signal photo                                ## modo foto (hito 13.12)
	signal quit
	var _buttons: Array[Button] = []
	var guest := false                          ## en red, un invitado: solo Continuar y Menú principal
	var ping := Callable()                      ## en red, invitado: () -> ms hasta el anfitrión (debajo, con su punto)
	var _ping_dot: Label
	var _ping_lbl: Label
	var _ping_t := 0.0

	func _init(p_guest := false) -> void:
		guest = p_guest
		layer = 30
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _ready() -> void:
		var w: Array = MenuKit.window(self, MenuKit.INK, 440)
		var dim: Control = w[0]
		var box: VBoxContainer = w[1]
		var ver := UiKit.label(Demo.version_text(), 18, UiKit.TEXT_DIM)
		ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)   # a mano al apuntar un fallo
		ver.offset_left = -140
		ver.offset_right = -24
		ver.offset_top = -44
		ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dim.add_child(ver)
		box.add_theme_constant_override("separation", 14)
		MenuKit.heading(box, "Pausa", 48)
		var rows := [["Continuar", resume], ["Modo foto", photo], ["Menú principal", quit]] if guest else 			[["Continuar", resume], ["Modo foto", photo], ["Dificultad (temporal)", difficulty], ["Reiniciar", restart], ["Depuración", debug], ["Menú principal", quit]]
		for pair in rows:
			var b := MenuKit.button(pair[0], MenuKit.INK, 28)
			b.custom_minimum_size = Vector2(340, 58)
			var sig: Signal = pair[1]
			b.pressed.connect(func() -> void: sig.emit())
			box.add_child(b)
			_buttons.append(b)
		if ping.is_valid():                         # conexión con el anfitrión, como en los paneles del HUD
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 8)
			_ping_dot = UiKit.label("●", 22)
			row.add_child(_ping_dot)
			_ping_lbl = UiKit.label("", 18, UiKit.TEXT_DIM)
			row.add_child(_ping_lbl)
			box.add_child(row)
			_show_ping()
		_buttons[0].grab_focus.call_deferred()

	func _process(delta: float) -> void:
		_ping_t += delta
		if _ping_lbl != null and _ping_t >= 0.5:      # el ping llega cada 2 s
			_ping_t = 0.0
			_show_ping()

	func _show_ping() -> void:
		var ms := int(ping.call())
		_ping_dot.add_theme_color_override("font_color", Hud.PlayerPanel.ping_color(ms))
		_ping_lbl.text = "Conexión con el anfitrión: %d ms" % ms if ms >= 0 else "Sin conexión con el anfitrión"

	## B en el mando: vuelve al juego (Esc y Start ya los atiende pause_watch). Oculta, con la
	## depuración encima, no hace nada: B es "volver" en ese menú.
	func _unhandled_input(event: InputEvent) -> void:
		if not visible: return
		if event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_B:
			get_viewport().set_input_as_handled()
			resume.emit()

	## Vuelve a mostrarse al salir de la depuración o la dificultad, con el foco en su botón.
	func show_again(button := "Depuración") -> void:
		visible = true
		for b in _buttons:
			if b.text == button: b.grab_focus.call_deferred()


## Fin de partida: caída o nivel superado, con un resumen y reintentar o salir.
class EndScreen extends CanvasLayer:
	static func _logs_button() -> Button:
		var logs := MenuKit.button("Abrir la carpeta de registros de conexión", MenuKit.INK, 20)
		logs.custom_minimum_size = Vector2(420, 44)
		logs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		logs.pressed.connect(NetLog.open_folder)
		return logs

	signal restart
	signal quit
	signal next_level
	signal pacts
	var has_next := false                       ## "Siguiente nivel", primero y con el foco
	var pacts_open := false                     ## botón de los pactos del Necronomicón (hito 13.6), tras el de seguir
	var _first: Button
	var waiting := ""                           ## en red, un invitado: este aviso y solo "Salir"
	var leave_text := "Salir de la partida"     ## el botón de salir, con `waiting`
	var logs_button := false                    ## botón de la carpeta de registros de red (tras un corte)
	var title := ""
	var lines: PackedStringArray = []
	var accent := UiKit.GOLD
	var report: Control = null                  ## informe al caer (hito 13.1, `FallReport.panel`), a la derecha
	var diary: Array = []                       ## entradas del diario (hito 13.10): {who, color, title, text}
	var replay: Array[Image] = []               ## los últimos segundos antes de caer (hito 15.1, `DeathReplay`)
	var epilogue := false                       ## al vencer el final de la campaña: «Epílogo», el primero (13.11)
	signal epilogue_open

	func _init(p_title: String, p_lines: PackedStringArray, p_accent: Color) -> void:
		title = p_title
		lines = p_lines
		accent = p_accent
		layer = 30
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _ready() -> void:
		var win: Array = MenuKit.window(self, MenuKit.INK, 620)
		var root: Control = win[0]
		var box: VBoxContainer = win[1]
		box.add_theme_constant_override("separation", 12)
		root.modulate.a = 0.0                          # entra despacio: la partida se ve terminar
		create_tween().tween_property(root, "modulate:a", 1.0, 0.9)
		MenuKit.heading(box, title, 56, accent)
		if report != null:                             # con informe: el resumen y los botones a la
			var cols := HBoxContainer.new()            # izquierda, el informe a la derecha
			cols.add_theme_constant_override("separation", 40)
			box.add_child(cols)
			box = VBoxContainer.new()
			box.add_theme_constant_override("separation", 12)
			box.custom_minimum_size.x = 460
			box.alignment = BoxContainer.ALIGNMENT_CENTER
			cols.add_child(box)
			cols.add_child(report)
		for l in lines:
			var ll := UiKit.label(l, 22, UiKit.TEXT)
			ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(ll)
		var gap := Control.new(); gap.custom_minimum_size.y = 12
		box.add_child(gap)
		if waiting != "":
			var w := UiKit.label(waiting, 22, UiKit.TEXT_DIM)
			w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(w)
			var leave := MenuKit.button(leave_text, MenuKit.INK, 28)
			leave.custom_minimum_size = Vector2(360, 58)
			leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # no tan ancho como un título largo
			leave.pressed.connect(func() -> void: quit.emit())
			var ep := _epilogue_button(box)
			box.add_child(leave)
			_diary_button(box, leave)
			_replay_button(box)
			if ep != null: leave = ep
			if logs_button: box.add_child(_logs_button())   # se cortó: el registro es lo que hay que enviar
			leave.grab_focus.call_deferred()
			return
		var nxt: Button = _epilogue_button(box)
		if has_next:
			nxt = MenuKit.button("Siguiente nivel", MenuKit.INK, 28)
			nxt.custom_minimum_size = Vector2(360, 58)
			nxt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			nxt.pressed.connect(func() -> void: next_level.emit())
			box.add_child(nxt)
		if pacts_open:
			var pb := MenuKit.button("Pactos del Necronomicón…", MenuKit.INK, 24)
			pb.custom_minimum_size = Vector2(360, 52)
			pb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			pb.pressed.connect(func() -> void: pacts.emit())
			box.add_child(pb)
		var again := MenuKit.button("Reintentar", MenuKit.INK, 28)
		again.custom_minimum_size = Vector2(360, 58)
		again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		again.pressed.connect(func() -> void: restart.emit())
		box.add_child(again)
		var out := MenuKit.button("Menú principal", MenuKit.INK, 28)
		out.custom_minimum_size = Vector2(360, 58)
		out.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		out.pressed.connect(func() -> void: quit.emit())
		box.add_child(out)
		_diary_button(box, out)
		_replay_button(box)
		if logs_button: box.add_child(_logs_button())
		_first = nxt if nxt != null else again
		_first.grab_focus.call_deferred()

	## «Epílogo» (hito 13.11): después del último nivel, lo que vino después.
	func _epilogue_button(box: VBoxContainer) -> Button:
		if not epilogue: return null
		var b := MenuKit.button("Fin de la demo" if Demo.on() else "Epílogo", MenuKit.INK, 28)
		b.custom_minimum_size = Vector2(360, 58)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func() -> void: epilogue_open.emit())
		box.add_child(b)
		return b

	## «Diario del investigador» (hito 13.10): abre las entradas de este nivel encima.
	func _diary_button(box: VBoxContainer, back: Button) -> void:
		if diary.is_empty(): return
		var b := MenuKit.button("Diario del investigador" if diary.size() == 1 else "Diarios de los investigadores", MenuKit.INK, 22)
		b.custom_minimum_size = Vector2(360, 50)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func() -> void:
			var page := DiaryPage.new(diary)
			page.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(page)
			page.tree_exited.connect(func() -> void: if is_inside_tree(): b.grab_focus.call_deferred()))
		box.add_child(b)
		if LaunchArgs.from_cmdline().get_bool("diary_open"): b.pressed.emit.call_deferred()   # capturas

	func _replay_button(box: VBoxContainer) -> void:
		if replay.is_empty(): return
		var b := MenuKit.button("Ver la caída", MenuKit.INK, 22)
		b.custom_minimum_size = Vector2(360, 50)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func() -> void:
			var v := ReplayView.new(replay)
			add_child(v)
			v.tree_exited.connect(func() -> void: if is_inside_tree(): b.grab_focus.call_deferred()))
		box.add_child(b)
		if LaunchArgs.from_cmdline().get_bool("replay_open"): b.pressed.emit.call_deferred()   # capturas

	## Vuelve a dar el foco (al cerrar una ventana encima, como la de los pactos).
	func focus_next() -> void:
		if _first != null: _first.grab_focus.call_deferred()
