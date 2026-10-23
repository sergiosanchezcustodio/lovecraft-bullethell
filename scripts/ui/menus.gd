class_name Menus
extends RefCounted
## Menús de la partida: subida de nivel (elige 1 de 3 mejoras; pausa la partida en
## solitario, D-16), pausa y fin de partida (caída o nivel superado). Todos son capas
## que siguen funcionando con el árbol en pausa y se manejan con teclado, mando o ratón.


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
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.02, 0.6)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var ver := UiKit.label("v" + String(ProjectSettings.get_setting("application/config/version", "?")), 18, UiKit.TEXT_DIM)
		ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)   # a mano al apuntar un fallo
		ver.offset_left = -140
		ver.offset_right = -24
		ver.offset_top = -44
		ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dim.add_child(ver)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 14)
		add_child(box)
		var t := UiKit.label("Pausa", 40)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(t)
		var rows := [["Continuar", resume], ["Menú principal", quit]] if guest else 			[["Continuar", resume], ["Reiniciar", restart], ["Depuración", debug], ["Menú principal", quit]]
		for pair in rows:
			var b := UiKit.button(pair[0])
			b.custom_minimum_size = Vector2(300, 56)
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
		box.resized.connect(func() -> void: box.position = (get_viewport().get_visible_rect().size - box.size) * 0.5)
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

	## Vuelve a mostrarse al salir de la depuración, con el foco en su botón.
	func show_again() -> void:
		visible = true
		_buttons[2].grab_focus.call_deferred()


## Fin de partida: caída o nivel superado, con un resumen y reintentar o salir.
class EndScreen extends CanvasLayer:
	static func _logs_button() -> Button:
		var logs := UiKit.button("Abrir la carpeta de registros de conexión", UiKit.TEXT_DIM, 18)
		logs.custom_minimum_size = Vector2(420, 44)
		logs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		logs.pressed.connect(NetLog.open_folder)
		return logs

	signal restart
	signal quit
	signal next_level
	var has_next := false                       ## "Siguiente nivel", primero y con el foco
	var waiting := ""                           ## en red, un invitado: este aviso y solo "Salir"
	var leave_text := "Salir de la partida"     ## el botón de salir, con `waiting`
	var logs_button := false                    ## botón de la carpeta de registros de red (tras un corte)
	var title := ""
	var lines: PackedStringArray = []
	var accent := UiKit.GOLD

	func _init(p_title: String, p_lines: PackedStringArray, p_accent: Color) -> void:
		title = p_title
		lines = p_lines
		accent = p_accent
		layer = 30
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _ready() -> void:
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.02, 0.0)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		create_tween().tween_property(dim, "color:a", 0.7, 1.0)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 14)
		add_child(box)
		var t := UiKit.label(title, 52, accent)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(t)
		for l in lines:
			var ll := UiKit.label(l, 20, UiKit.TEXT)
			ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(ll)
		var gap := Control.new(); gap.custom_minimum_size.y = 12
		box.add_child(gap)
		if waiting != "":
			var w := UiKit.label(waiting, 22, UiKit.TEXT_DIM)
			w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(w)
			var leave := UiKit.button(leave_text, accent)
			leave.custom_minimum_size = Vector2(300, 56)
			leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # no tan ancho como un título largo
			leave.pressed.connect(func() -> void: quit.emit())
			box.add_child(leave)
			if logs_button: box.add_child(_logs_button())   # se cortó: el registro es lo que hay que enviar
			box.resized.connect(func() -> void: box.position = (get_viewport().get_visible_rect().size - box.size) * 0.5)
			leave.grab_focus.call_deferred()
			return
		var nxt: Button = null
		if has_next:
			nxt = UiKit.button("Siguiente nivel", accent)
			nxt.custom_minimum_size = Vector2(300, 56)
			nxt.pressed.connect(func() -> void: next_level.emit())
			box.add_child(nxt)
		var again := UiKit.button("Reintentar", accent)
		again.custom_minimum_size = Vector2(300, 56)
		again.pressed.connect(func() -> void: restart.emit())
		box.add_child(again)
		var out := UiKit.button("Menú principal", accent)
		out.custom_minimum_size = Vector2(300, 56)
		out.pressed.connect(func() -> void: quit.emit())
		box.add_child(out)
		if logs_button: box.add_child(_logs_button())
		box.resized.connect(func() -> void: box.position = (get_viewport().get_visible_rect().size - box.size) * 0.5)
		(nxt if nxt != null else again).grab_focus.call_deferred()
