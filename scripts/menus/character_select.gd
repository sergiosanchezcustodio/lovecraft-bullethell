class_name CharacterSelect
extends Control
## Selección de personaje (D-22, D-23), al estilo de Extremadura Survivors: cuatro marcos,
## uno por jugador. Cada dispositivo se une con Start (el teclado, con Intro) y maneja su
## marco con su propio mando: izquierda/derecha cambia de personaje o de compañero, A
## confirma y B deshace. LB/RB (Q/E con el teclado), mantenidos, giran el personaje para verlo
## de lado y de espaldas; mientras se elige compañero, giran el compañero. La entrada se lee aquí por dispositivo, sin el foco de Godot (que
## es uno para toda la pantalla). Cuando todos los presentes están listos se abre el mapa
## de niveles. Opciones detrás de `--` (capturas): join=N une N jugadores de prueba;
## ready=N deja listos los N primeros; pets=N deja a los N primeros eligiendo compañero; pick=id,id… elige personaje en cada marco;
## turn=grados los deja girados; map=true abre el mapa; auto_start=true, además, entra
## en el nivel 1 o en el de start_level= (probar el paso a la partida; en red, net_wait=N espera antes a N PCs más
## y net_players=N a N jugadores);
## acts=right,confirm… pulsa eso (ver `_play_acts`).
##
## En red (hito 9.2, D-10) es también la sala: arriba, el código y los conectados. El
## anfitrión lleva el estado (`NetSelect`); los invitados ven sus acciones al momento, las
## mandan y copian lo que reparte, cada uno con sus desbloqueos. Solo el anfitrión ve el mapa de niveles. Sin
## puestos en este PC, B pregunta si salir de la sala (o cerrarla, el anfitrión). Pruebas
## con dos ventanas: `select net_host=true net_upnp=false` y `select net_join=127.0.0.1`.

const BG := "res://resources/PantallasMenus/fondo_titulo_sin_texto_1080p_definitivo.png"
const DESIGN := Vector2(1920, 1080)
const FRAME := Vector2(420, 684)
const GAP := 26.0
const TOP := 96.0
## Recuadro del compañero, debajo del marco: título, nombre con flechas, modelo y estado.
const PET_H := 240.0
const PET_GAP := 10.0
## Escala de los compañeros en su visor, la misma para todos (se ven proporcionados: el perro
## más grande que el murciélago), y tamaño del visor: cabe el más alto (el perro, 0,85 m).
const PET_PX_PER_M := 130.0
const PET_VIEW := Vector2(380, 120)
const ICONS := "res://resources/PantallasMenus/iconos/ficha_%s.png"
## Píxeles por metro del personaje: los mismos que en la partida (1080 px para 15 m de alto).
const PX_PER_M := 1080.0 / 15.0
## Aumento del personaje en la ficha respecto a la partida.
const MODEL_ZOOM := 2.0
## Alto del visor del personaje.
const VIEW_H := 150.0 * MODEL_ZOOM
## Estadísticas de la columna derecha de la ficha, en el orden de sus iconos.
const STAT_ROWS: Array[String] = ["vida", "cordura", "esquive", "velocidad", "magia", "fisico", "fuego"]
const STICK := 0.6                          ## umbral del stick para contar como una pulsación

var state: SelectState
var args: LaunchArgs
var _frames: Array[_Frame] = []
var _map: LevelMap
var _stick := {}                            ## dispositivo -> dirección del stick ya contada
var _leaving := false
var _opening := false
var net_select: NetSelect                    ## en red; null en local
const LATE_WAIT := "De vuelta: entrarás al empezar el siguiente nivel"
var _me := SelectState.LOCAL                 ## PC de los jugadores de esta pantalla
var _stage: Control
var _modal: Control                          ## confirmación de salir de la sala
var _wait: PanelContainer                    ## aviso en el centro (conectando, eligiendo nivel)
var _wait_label: Label
var _wait_sub: Label                         ## segunda línea, más pequeña (quien vuelve: lo que pasa en la partida)
var _wait_dim: ColorRect                     ## oscurece los marcos detrás del aviso
var _room_code: Label                        ## "Sala", "Sala de …"
var _room_code_val: Label                    ## el código, en la letra del texto: la de los títulos dibuja el 0 como una o
var _room_status: Label
var _room_list: RichTextLabel                ## quién está, con el ping de color y si tiene otra versión

func _ready() -> void:
	TipIcon.hold = false
	args = LaunchArgs.from_cmdline()
	UiInput.configure()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var chars: Array[CharacterData] = []
	for r in DebugOptions.list_resources("res://data/characters"): chars.append(r)
	chars.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.order < b.order)
	var all_pets: Array = DebugOptions.list_resources("res://data/pets")
	var mine := SelectState.profile_from_save(Saves.current, chars, all_pets)   # desbloqueos y vestuario (D-34)
	state = SelectState.new().setup(chars, [], [] as Array[PetData])
	state.profiles[SelectState.LOCAL] = mine
	_build()
	BookTransition.arrive(self)                                       # viene del libro de la portada: desde negro
	state.changed.connect(_refresh)
	Devices.joy_disconnected.connect(func(d: int) -> void: _do(d, "leave"))
	if args.get_bool("net_host") and not Net.is_active():          # pruebas: abre la sala aquí mismo
		Net.host(RoomCode.BASE_PORT, args.get_bool("net_upnp", true))
	elif args.has("net_join") and not Net.is_active():
		var a := RoomCode.parse(args.get_str("net_join"))
		if not a.is_empty(): Net.join(a.ip, a.port)
	if Net.is_active(): _start_net(mine, all_pets)
	else: state.join(Devices.last_device)               # el que ha llegado desde el menú entra ya como J1
	_demo_from_args()
	_refresh()
	if args.has("pick"):                                # capturas: pick=peaslee,varga… un personaje por marco
		var ids := args.get_str("pick").split(",")
		for k in mini(ids.size(), state.joined().size()):
			for ci in state.characters.size():
				if String(state.characters[ci].id) == ids[k]: (state.seats[state.joined()[k]] as SelectState.Seat).character = ci
		_refresh()
	if args.has("vest") and state.confirm(0):            # capturas: J1 en el vestuario, N sombreros más allá
		for k in args.get_int("vest"): state.move(0, 1)
		state.vert(0, 1); state.move(0, 1); state.vert(0, 1); state.move(0, 1)
	if args.has("cursor"):                              # capturas: marca ese icono de la ficha en J1
		for k in args.get_int("cursor") + 1: _frames[0].move_cursor(1)
	if args.has("turn"):                                # capturas: todos girados ese ángulo (grados)
		for f in _frames: f.set_turn(deg_to_rad(args.get_float("turn")))
	if args.has("pacts"): Pacts.set_active(Array(args.get_str("pacts").split(",", false)))   # pacts=noche,furia (hito 13.6)
	if args.has("shots"):
		add_child(ShotTaker.new(args.get_floats("shots"), "res://shots/seleccion%s" % (("_" + args.get_str("tag")) if args.has("tag") else "")))
	if args.has("acts"): _play_acts(args.get_str("acts").split(",", false))

## Pruebas: `acts=right,confirm,…` pulsa eso con el primer dispositivo, una cada 0,4 s, desde
## el segundo 2 (en red, ya dentro de la sala). `wait` deja pasar un turno; `2:join` pulsa con
## el dispositivo de prueba 2 (otro jugador de este PC, que en partida lleva el bot de `bot=`).
func _play_acts(list: PackedStringArray) -> void:
	await get_tree().create_timer(2.0).timeout
	for a in list:
		if not is_inside_tree() or _leaving: return
		var dev := Devices.last_device
		if ":" in a:                                       # "2:join": con el 2.º dispositivo de prueba
			dev = -9 - int(a.get_slice(":", 0))
			a = a.get_slice(":", 1)
		if a != "wait": _do(dev, a)
		await get_tree().create_timer(0.4).timeout

func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	add_child(MenuKit.veil(1.1))
	theme = MenuKit.theme()                     # biblioteca gótica, como los menús (27-10-2026)
	var stage := Control.new()                  # todo en coordenadas de 1920x1080, centrado
	stage.size = DESIGN
	add_child(stage)
	_stage = stage
	var t := MenuKit.title("Elige a tu investigador", 50)
	t.size = Vector2(DESIGN.x, 70)
	t.position = Vector2(0, 18)
	stage.add_child(t)
	if Saves.current:
		var m := UiKit.label("Dinero  %s $" % MenuKit.money(Saves.current.money), 22, UiKit.GOLD)
		m.position = Vector2(DESIGN.x - 260, 22)
		stage.add_child(m)
	var total := FRAME.x * 4 + GAP * 3
	for i in 4:
		var f := _Frame.new(self, i)
		f.position = Vector2((DESIGN.x - total) * 0.5 + i * (FRAME.x + GAP), TOP)
		stage.add_child(f)
		_frames.append(f)
	var hint := MenuKit.hint("Start o Intro: unirse  ·  Izquierda/derecha: cambiar  ·  Arriba/abajo: ficha o prenda  ·  LB/RB o Q/E: girar  ·  A o Intro: elegir  ·  B o Esc: atrás")
	hint.size = Vector2(DESIGN.x, 30)
	hint.position = Vector2(0, DESIGN.y - 44)
	stage.add_child(hint)
	var fit := func() -> void:
		var vs := get_viewport().get_visible_rect().size
		var k := minf(vs.x / DESIGN.x, vs.y / DESIGN.y)
		stage.scale = Vector2.ONE * k
		stage.position = (vs - DESIGN * k) * 0.5
	get_viewport().size_changed.connect(fit)
	fit.call()

func _refresh() -> void:
	for f in _frames: f.refresh()
	if state.all_ready() and _map == null and not _leaving and (net_select == null or net_select.is_host()):
		_open_map.call_deferred()

# ---------------------------------------------------------------- entrada por dispositivo

func _input(event: InputEvent) -> void:
	if _map != null or _leaving or _modal != null: return
	var d: Variant = Devices.device_of(event)
	if d == null: return
	var dev: int = d
	if net_select != null and net_select.is_host() and _is_copy(event):
		get_viewport().set_input_as_handled()
		_copy_code()
		return
	# giro del modelo mientras se mantiene LB/RB o Q/E (se atiende también al soltar)
	var spin := _spin_input(event)
	if spin != 2:
		_do(dev, "spin%d" % spin)
		get_viewport().set_input_as_handled()
		return
	var act := _action(event, dev)
	if act == "": return
	get_viewport().set_input_as_handled()
	_do(dev, act)

## Una acción de un dispositivo de este PC: se aplica aquí (en local o siendo el anfitrión)
## o se manda al anfitrión.
func _do(dev: int, act: String) -> void:
	if net_select != null and not net_select.is_host(): _guest_action(dev, act)
	else: _apply(_me, dev, act)

## Aplica una acción de un jugador (de este PC o, en el anfitrión, de otro). Lo que solo se
## ve en un PC (la ficha marcada, la sacudida) solo pasa si el jugador es de este.
func _apply(peer: int, dev: int, act: String) -> void:
	if _map != null or _leaving: return
	var seat := state.seat_of(dev, peer)
	var fb := state.act(peer, dev, act)
	if peer == _me: _feedback(seat, fb)

## Lo que solo ve el PC del jugador tras su acción (ver `SelectState.act`).
func _feedback(seat: int, fb: String) -> void:
	match fb:
		"cursor-1": _frames[seat].move_cursor(-1)
		"cursor1": _frames[seat].move_cursor(1)
		"shake": _frames[seat].shake()
		"exit": _leave_screen()
		"freed":
			# en red, quedarse sin puesto no saca de la sala: hace falta otra B (y confirmarlo)
			if net_select == null and state.joined().is_empty(): _back_to_menu()

## Invitado: la acción se ve al momento en su copia y va al anfitrión (`NetSelect.predict`);
## lo que solo se ve aquí (ficha, sacudida, salir) no viaja.
func _guest_action(dev: int, act: String) -> void:
	if net_select.map_open or Net.state != NetSession.State.CONNECTED or Net.late: return   # quien vuelve, espera
	var seat := state.seat_of(dev, _me)
	_feedback(seat, net_select.predict(dev, act))

## Giro con LB/RB o Q/E: -1 o 1 al pulsar, 0 al soltar, 2 si el evento no es de giro.
func _spin_input(event: InputEvent) -> int:
	if event is InputEventJoypadButton:
		var b := event as InputEventJoypadButton
		if b.button_index == JOY_BUTTON_LEFT_SHOULDER: return -1 if b.pressed else 0
		if b.button_index == JOY_BUTTON_RIGHT_SHOULDER: return 1 if b.pressed else 0
	elif event is InputEventKey and not (event as InputEventKey).echo:
		var k := event as InputEventKey
		if k.physical_keycode == KEY_Q: return -1 if k.pressed else 0
		if k.physical_keycode == KEY_E: return 1 if k.pressed else 0
	return 2

## Traduce un evento a una acción del menú: left, right, confirm, back, join o "".
func _action(event: InputEvent, dev: int) -> String:
	if event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo: return ""
		match k.physical_keycode:
			KEY_UP, KEY_W: return "up"
			KEY_DOWN, KEY_S: return "down"
			KEY_LEFT, KEY_A: return "left"
			KEY_RIGHT, KEY_D: return "right"
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: return "confirm"
			KEY_ESCAPE, KEY_BACKSPACE: return "back"
		return ""
	if event is InputEventJoypadButton:
		var b := event as InputEventJoypadButton
		if not b.pressed: return ""
		match b.button_index:
			JOY_BUTTON_DPAD_UP: return "up"
			JOY_BUTTON_DPAD_DOWN: return "down"
			JOY_BUTTON_DPAD_LEFT: return "left"
			JOY_BUTTON_DPAD_RIGHT: return "right"
			JOY_BUTTON_A: return "confirm"
			JOY_BUTTON_START: return "join"
			JOY_BUTTON_B: return "back"
		return ""
	if event is InputEventJoypadMotion:
		var axis := (event as InputEventJoypadMotion).axis
		if axis != JOY_AXIS_LEFT_X and axis != JOY_AXIS_LEFT_Y: return ""
		# el stick cuenta una vez al pasar el umbral y otra al volver al centro (cada eje por separado)
		var v := (event as InputEventJoypadMotion).axis_value
		var dir := 1 if v > STICK else (-1 if v < -STICK else 0)
		var key := dev * 2 + (1 if axis == JOY_AXIS_LEFT_Y else 0)
		var prev: int = _stick.get(key, 0)
		_stick[key] = dir if absf(v) > 0.3 else 0
		if dir != 0 and prev == 0:
			if axis == JOY_AXIS_LEFT_Y: return "down" if dir > 0 else "up"
			return "right" if dir > 0 else "left"
	return ""

# ---------------------------------------------------------------- mapa y salida

func _open_map() -> void:
	if _opening: return                               # varios cambios seguidos piden abrirlo varias veces
	_opening = true
	await get_tree().create_timer(0.35).timeout      # que se vea el "Listo" del último
	_opening = false
	if not is_inside_tree() or _leaving or not state.all_ready() or _map != null: return
	if net_select != null and not Net.other_versions().is_empty():   # el juego sería otro en cada PC
		_fill_room()
		return
	if args.get_bool("auto_start"):                    # pruebas: directo al nivel 1
		if net_select != null and Net.peers.size() - 1 < args.get_int("net_wait", 0): return   # net_wait=N: espera a N PCs más
		if state.joined().size() < args.get_int("net_players", 0): return                   # net_players=N: y a N jugadores
		_start(args.get_str("start_level", "p1_n1"))      # start_level=p2_n5: otro nivel
		return
	_map = LevelMap.new()
	add_child(_map)
	TipIcon.hold = true                               # las burbujas de la ficha irían encima del mapa
	if net_select != null: net_select.map_open = true
	_map.chosen.connect(_start)
	_map.closed.connect(func() -> void:
		_map = null
		TipIcon.hold = false
		if net_select != null: net_select.map_open = false
		state.unready_all())

## El anfitrión (o el único PC) elige nivel: empieza para todos.
func _start(level_id: String) -> void:
	var players := NetSelect.players_of(state)
	if net_select != null: net_select.start(level_id, players)
	_enter(level_id, players)

## Pasa a la partida con esos jugadores: el relato del nivel y después la partida.
func _enter(level_id: String, players: Array) -> void:
	NetSelect.fill_session(level_id, players, _me, net_select != null)
	var pr: SelectState.Profile = state.profiles.get(_me)
	if Saves.current != null and pr != null and not pr.outfits.is_empty():   # el vestuario queda puesto
		for s in GameSession.seats:
			if s.is_local(): Saves.current.worn[String(s.character)] = s.worn.duplicate()
	if Saves.current != null: Saves.save()
	_leaving = true
	get_tree().change_scene_to_file("res://scenes/relato.tscn")

## Vuelve al menú principal; desde la red, con la ventana online abierta y `notice` en ella.
func _back_to_menu(notice: String = "") -> void:
	_leaving = true
	TitleScreen.skip_to_menu = true
	if net_select != null or notice != "":
		TitleScreen.reopen_online = true
		OnlineMenu.notice = notice
	get_tree().change_scene_to_file("res://scenes/title.tscn")

## B sin puestos en este PC: en local, al menú; en red, pregunta antes de dejar la sala.
func _leave_screen() -> void:
	if net_select == null:
		_back_to_menu()
		return
	var host := net_select.is_host()
	_modal = MenuKit.Confirm.new("¿Cerrar la sala? Los demás volverán al menú." if host else "¿Salir de la sala?",
		"Cerrar la sala" if host else "Salir")
	add_child(_modal)
	_modal.answered.connect(func(yes: bool) -> void:
		_modal = null
		if not yes: return
		_leaving = true
		Net.close()
		_back_to_menu())

# ---------------------------------------------------------------- red

func _start_net(mine: SelectState.Profile, all_pets: Array) -> void:
	net_select = NetSelect.new(Net, state, all_pets)
	net_select.apply_action = _apply
	net_select.map_changed.connect(func(open: bool) -> void:
		if not net_select.is_host(): _show_wait("El anfitrión está eligiendo nivel…" if open else ""))
	net_select.late_info.connect(func(where: String, goal: String) -> void:   # quien vuelve: cómo va la partida
		if Net.late and not _leaving: _show_wait(LATE_WAIT, "Ahora: %s · %s" % [where, goal]))
	net_select.started.connect(func(level_id: String, players: Array) -> void:
		if not _leaving: _enter(level_id, players))
	add_child(net_select)
	Net.closed.connect(func(reason: String) -> void:   # vacío: la ha cerrado este PC (al salir)
		if not _leaving and reason != "" and is_inside_tree(): _back_to_menu(reason))
	Net.failed.connect(func(reason: String) -> void:
		if not _leaving and is_inside_tree(): _back_to_menu(reason))
	Net.roster_changed.connect(_fill_room)
	Net.roster_changed.connect(func() -> void:          # se fue quien tenía otra versión: ya se puede empezar
		if is_inside_tree() and state.all_ready(): _refresh())
	Net.upnp_done.connect(func(_ok: bool, _m: String) -> void: _fill_room())
	_build_room()
	if Net.is_host():
		state.join(Devices.last_device)
	elif Net.state == NetSession.State.CONNECTED:
		_enter_room(mine)
	else:                                                 # conectando (pruebas: net_join=)
		_show_wait("Conectando…")
		Net.joined.connect(func() -> void:
			_show_wait("")
			_enter_room(mine), CONNECT_ONE_SHOT)
	_fill_room()

## Invitado: copia la sala del anfitrión y entra con su perfil y su dispositivo.
func _enter_room(mine: SelectState.Profile) -> void:
	_me = Net.my_id
	if Net.late:                                          # vuelve a una partida empezada (hito 9.5a)
		_show_wait(LATE_WAIT)
		_fill_room()
		return
	state.profiles = {SelectState.LOCAL: SelectState.Profile.new()}   # hasta que llegue la del anfitrión
	net_select.enter(mine, Devices.last_device)
	_fill_room()

func _build_room() -> void:
	var head := HBoxContainer.new()
	head.position = Vector2(28, 12)
	head.add_theme_constant_override("separation", 14)
	_stage.add_child(head)
	_room_code = MenuKit.title("", 30, MenuKit.INK)
	_room_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(_room_code)
	_room_code_val = UiKit.label("", 28, MenuKit.INK)
	_room_code_val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_room_code_val)
	_room_status = UiKit.label("", 16, UiKit.TEXT_DIM)
	_room_status.position = Vector2(30, 54)
	_room_status.size = Vector2(620, 24)
	_room_status.clip_text = true
	_stage.add_child(_room_status)
	_room_list = RichTextLabel.new()
	_room_list.bbcode_enabled = true
	_room_list.scroll_active = false
	_room_list.autowrap_mode = TextServer.AUTOWRAP_OFF
	_room_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room_list.add_theme_font_size_override("normal_font_size", 17)
	_room_list.add_theme_color_override("default_color", UiKit.TEXT)
	_room_list.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.02))
	_room_list.add_theme_constant_override("outline_size", 2)
	_room_list.position = Vector2(DESIGN.x - 740, 54)
	_room_list.size = Vector2(712, 28)
	_stage.add_child(_room_list)
	_wait_dim = ColorRect.new()
	_wait_dim.color = Color(0.0, 0.0, 0.02, 0.62)
	_wait_dim.position = Vector2(0, TOP - 6)
	_wait_dim.size = Vector2(DESIGN.x, DESIGN.y - TOP - 50)     # los marcos, sin la cabecera ni la ayuda
	_wait_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wait_dim.visible = false
	_stage.add_child(_wait_dim)
	_wait = PanelContainer.new()
	var wbox := VBoxContainer.new()
	wbox.add_theme_constant_override("separation", 10)
	_wait.add_child(wbox)
	MenuKit.dress(_wait, MenuKit.BRASS, Vector2(48, 28), 110.0)
	_wait_label = MenuKit.title("", 34, MenuKit.INK)
	_wait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wbox.add_child(_wait_label)
	_wait_sub = UiKit.label("", 22, UiKit.TEXT_DIM)
	_wait_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wait_sub.visible = false
	wbox.add_child(_wait_sub)
	_wait.visible = false
	_stage.add_child(_wait)

## Aviso en el centro ("" lo quita).
func _show_wait(text: String, sub := "") -> void:
	if _wait == null: return
	_wait_label.text = text
	_wait_sub.text = sub
	_wait_sub.visible = sub != ""
	_wait.visible = text != ""
	_wait_dim.visible = _wait.visible
	_wait.reset_size()
	_wait.position = (DESIGN - _wait.size) * 0.5

func _fill_room() -> void:
	if _room_code == null or not Net.is_active(): return
	if Net.is_host():
		var c := Net.codes()
		var code: String = c.internet if c.internet != "" else c.lan
		_room_code.text = "Sala" if code != "" else "Sala abierta"
		_room_code_val.text = code
		var bits := PackedStringArray()
		if c.internet != "" and c.lan != "": bits.append("en casa: %s" % c.lan)
		bits.append(Net.upnp_status)
		bits.append("Select o C: copiar")
		_room_status.text = "  ·  ".join(bits)
		var others := Net.other_versions()
		if not others.is_empty():
			_room_status.text = "No se puede empezar: %s %s otra versión (tú, la v%s)" % [
				", ".join(others), "tiene" if others.size() == 1 else "tienen", Net.version]
	else:
		var host_name := String(Net.peers.get(1, {}).get("name", ""))
		_room_code.text = ("Sala de %s" % host_name) if host_name != "" else "Sala"
		_room_code_val.text = ""
		var ping := int(Net.peers.get(Net.my_id, {}).get("ping", 0))
		_room_status.text = ("Ping %d ms" % ping) if ping > 0 else ("Conectando…" if Net.state != NetSession.State.CONNECTED else "Midiendo el ping…")
		if ping > Hud.PlayerPanel.PING_FAIR_MS: _room_status.text += "  ·  conexión lenta: se notará algo de retraso"
		var host_ver := String(Net.peers.get(1, {}).get("ver", Net.version))
		if host_ver != Net.version:                      # se entienden, pero el juego puede ser otro
			_room_status.text = "Otra versión (anfitrión v%s, tú v%s): no se puede empezar" % [host_ver, Net.version]
	var ids := Net.peers.keys()
	ids.sort()
	var names := PackedStringArray()
	for id in ids:
		var p: Dictionary = Net.peers[id]
		var who := String(p.name).replace("[", "(") + (" (tú)" if id == Net.my_id else "")
		var ms := int(p.ping)
		if id != 1 and ms > 0:                           # con el color de los paneles; lenta, dicho
			who += " [color=#%s]%d ms%s[/color]" % [Hud.PlayerPanel.ping_color(ms).to_html(false), ms,
				" (lenta)" if ms > Hud.PlayerPanel.PING_FAIR_MS else ""]
		var ver := String(p.get("ver", Net.version))
		if ver != Net.version: who += " [color=#%s](v%s)[/color]" % [Hud.PlayerPanel.PING_BAD.to_html(false), ver]
		names.append(who)
	_room_list.text = "[right]En la sala: %s  ·  v%s[/right]" % ["  ·  ".join(names), Net.version]

func _is_copy(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_BACK
	if event is InputEventKey:
		var k := event as InputEventKey
		return k.pressed and not k.echo and k.physical_keycode == KEY_C
	return false

func _copy_code() -> void:
	var c := Net.codes()
	var code: String = c.internet if c.internet != "" else c.lan
	if code == "": return
	DisplayServer.clipboard_set(code)
	_room_status.text = "Copiado: %s" % code

## Capturas: jugadores de prueba con dispositivos ficticios.
func _demo_from_args() -> void:
	for k in args.get_int("join", 0): state.join(-10 - k)
	var ready := args.get_int("ready", 0)
	var j := state.joined()
	for k in mini(ready, j.size()):
		state.confirm(j[k])
		if k % 2 == 1: state.move(j[k], 1)
		state.confirm(j[k])
	for k in mini(args.get_int("pets", 0), j.size()):     # eligiendo compañero, uno distinto cada uno
		state.confirm(j[k])
		for n in k * 3 + 1: state.move(j[k], 1)
	if args.get_bool("map"):
		for k in state.joined():
			while (state.seats[k] as SelectState.Seat).stage != SelectState.Stage.READY:
				if not state.confirm(k): state.move(k, 1)


## Marco de un jugador: el personaje en 3D, su ficha y, debajo, el compañero.
class _Frame extends Control:
	var owner_screen: CharacterSelect
	var index := 0
	var _panel: Panel
	var _head: Label
	var _jbox: PanelContainer
	var _view: _Preview
	var _pet_view: _Preview
	var _info: Control
	var _name: Label
	var _role: Label
	var _weapon: TipIcon
	var _tips: Array[TipIcon] = []            ## iconos de la ficha, en el orden de arriba/abajo
	var _cursor := -1                         ## icono marcado con el mando (-1: ninguno)
	var _outfit: PanelContainer                ## vestuario (D-34)
	var _outfit_rows: Array[Label] = []
	var _sheet_title: Label
	var _sheet_cols: Control
	var _passive: Label
	var _attr_vals: Dictionary = {}           ## atributo -> {icon, val}
	var _stat_vals: Dictionary = {}           ## estadística -> {icon, val}
	var _status: Label
	var _arrows: Array[Label] = []
	var _wbox: PanelContainer
	var _record: Label                        ## récord de «La noche eterna» con este personaje (13.8)
	var _empty: VBoxContainer
	var _who: Label                           ## en red, el nombre del PC del jugador
	var _pet: Panel
	var _pet_title: Label
	var _pet_name: Label
	var _pet_arrows: Array[Label] = []
	var _pet_note: Label
	var _shake := 0.0
	var _base_x := 0.0

	func _init(p_owner: CharacterSelect, p_index: int) -> void:
		owner_screen = p_owner
		index = p_index
		size = Vector2(FRAME.x, FRAME.y + PET_GAP + PET_H)

	func _ready() -> void:
		var color := Devices.COLORS[index]
		_panel = Panel.new()
		_panel.size = FRAME
		add_child(_panel)
		MenuKit.dress(_panel, MenuKit.BRASS, Vector2.ZERO, 72.0)   # madera y latón; refresh() lo tiñe
		_head = MenuKit.title("J%d" % (index + 1), 26, color)   # puesto vacío: arriba, centrado
		_head.size = Vector2(FRAME.x, 40)
		_head.position = Vector2(0, 22)                    # dentro del filete fino (15-17 px del borde)
		add_child(_head)
		_jbox = PanelContainer.new()                           # puesto ocupado: recuadro como el del arma
		_jbox.position = Vector2(20, 20)
		_jbox.custom_minimum_size = Vector2(92, 92)
		_jbox.add_theme_stylebox_override("panel", _frame(Color(0, 0, 0, 0.5), Color(MenuKit.BRASS.lerp(color, 0.6), 0.85), 2))
		add_child(_jbox)
		var jl := MenuKit.title("J%d" % (index + 1), 54, color)
		jl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_jbox.add_child(jl)
		_who = UiKit.label("", 16, color)
		_who.position = Vector2(22, 116)
		_who.size = Vector2(150, 22)
		_who.clip_text = true
		add_child(_who)
		# el personaje en 3D, en su propio mundo, a la escala de la partida
		_view = _Preview.new(Vector2(240, VIEW_H), PX_PER_M * MODEL_ZOOM, index)
		_view.position = Vector2((FRAME.x - 240) * 0.5, 4)
		add_child(_view)
		for side in [-1, 1]:
			var a := UiKit.label("◀" if side < 0 else "▶", 34, UiKit.GOLD)
			a.position = Vector2(26 if side < 0 else FRAME.x - 56, 20 + VIEW_H * 0.5)
			add_child(a)
			_arrows.append(a)
		# arma inicial, arriba a la derecha
		_wbox = PanelContainer.new()
		_wbox.position = Vector2(FRAME.x - 112, 20)
		_wbox.add_theme_stylebox_override("panel", _frame(Color(0, 0, 0, 0.5), Color(MenuKit.BRASS, 0.7), 2))
		add_child(_wbox)
		_record = UiKit.label("", 14, UiKit.TEXT_DIM)
		_record.position = Vector2(FRAME.x - 120, 222)
		_record.size = Vector2(108, 48)
		_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_record.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_record)
		_weapon = TipIcon.new(Vector2(72, 72))
		_weapon.placeholder = "Arma"
		_wbox.add_child(_weapon)
		_tips.append(_weapon)
		# ficha
		# ficha: cada bloque en una casilla fija, para que nada se mueva al cambiar de personaje
		_info = Control.new()
		_info.position = Vector2(14, 0)
		_info.size = Vector2(FRAME.x - 28, FRAME.y)
		_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_info)
		_name = _slot(MenuKit.title("", 32), 300, 40)
		_role = _slot(UiKit.label("", 16, UiKit.TEXT_DIM), 340, 24)
		_passive = _slot(UiKit.label("", 16, UiKit.TEXT), 364, 50)       # hasta dos líneas
		_passive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_sheet_title = _slot(MenuKit.title("Características y habilidades", 22, UiKit.GOLD), 418, 30)
		var cols := HBoxContainer.new()
		_sheet_cols = cols
		cols.alignment = BoxContainer.ALIGNMENT_CENTER
		cols.add_theme_constant_override("separation", 8)
		cols.position = Vector2(0, 452)
		cols.size = Vector2(_info.size.x, 0)
		_info.add_child(cols)
		cols.add_child(_column(Attributes.NAMES, _attr_vals, 44, 30))
		cols.add_child(_column(STAT_ROWS, _stat_vals, 132, 62))
		# vestuario (D-34): tapa las características mientras se elige
		_outfit = PanelContainer.new()
		_outfit.position = Vector2(14, 392)                # seis huecos (fase 14): algo más alto
		_outfit.custom_minimum_size = Vector2(FRAME.x - 28, FRAME.y - 404)
		_outfit.size = _outfit.custom_minimum_size
		_outfit.add_theme_stylebox_override("panel", _frame(Color(0.03, 0.022, 0.018, 0.97), Color(MenuKit.BRASS.lerp(color, 0.5), 0.75), 2))
		add_child(_outfit)
		var ob := VBoxContainer.new()
		ob.alignment = BoxContainer.ALIGNMENT_CENTER
		ob.add_theme_constant_override("separation", 1)
		_outfit.add_child(ob)
		ob.add_child(MenuKit.title("Vestuario", 22, UiKit.GOLD))
		for k in OutfitData.KEYS.size():
			var row := VBoxContainer.new()
			row.add_theme_constant_override("separation", -3)
			var tag := UiKit.label(OutfitData.SLOT_NAMES[k], 13, UiKit.TEXT_DIM)
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(tag)
			var val := MenuKit.title("", 18, UiKit.TEXT)
			val.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			val.custom_minimum_size.x = FRAME.x - 60
			row.add_child(val)
			ob.add_child(row)
			_outfit_rows.append(val)
		_outfit.visible = false
		# puesto vacío
		_empty = VBoxContainer.new()
		_empty.size = Vector2(FRAME.x, 0)
		_empty.position = Vector2(0, FRAME.y * 0.4)
		add_child(_empty)
		var join := MenuKit.title("Pulsa Start", 30, color)
		_empty.add_child(join)
		var join2 := UiKit.label("para unirte  ·  Intro con el teclado", 18, UiKit.TEXT_DIM)
		join2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_empty.add_child(join2)
		# compañero, debajo del marco: título, ◀ nombre ▶, el modelo girando y el estado
		_pet = Panel.new()
		_pet.position = Vector2(0, FRAME.y + PET_GAP)
		_pet.size = Vector2(FRAME.x, PET_H)
		add_child(_pet)
		MenuKit.dress(_pet, MenuKit.BRASS, Vector2.ZERO, 60.0)
		# todo entre los 20 px de arriba y de abajo: el filete fino va a 15-17 px del borde
		_pet_title = MenuKit.title("Elige compañero", 22, UiKit.GOLD)
		_pet_title.size = Vector2(FRAME.x, 30)
		_pet_title.position = Vector2(0, 18)
		_pet.add_child(_pet_title)
		_pet_name = MenuKit.title("", 20, color)
		_pet_name.size = Vector2(FRAME.x - 100, 26)
		_pet_name.position = Vector2(50, 46)
		_pet.add_child(_pet_name)
		for side in [-1, 1]:
			var a := UiKit.label("◀" if side < 0 else "▶", 24, UiKit.TEXT)
			a.position = Vector2(26 if side < 0 else FRAME.x - 46, 42)
			_pet.add_child(a)
			_pet_arrows.append(a)
		_pet_view = _Preview.new(PET_VIEW, PET_PX_PER_M, index + 2)
		_pet_view.position = Vector2((FRAME.x - PET_VIEW.x) * 0.5, 72)
		_pet.add_child(_pet_view)
		_pet_note = UiKit.label("", 16, UiKit.TEXT_DIM)
		_pet_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pet_note.size = Vector2(FRAME.x, 24)
		_pet_note.position = Vector2(0, 120)
		_pet.add_child(_pet_note)
		_status = MenuKit.title("", 20, color)
		_status.size = Vector2(FRAME.x, 26)
		_status.position = Vector2(0, PET_H - 48)
		_pet.add_child(_status)

	## Nombre de cada estadística derivada (Attributes.FORMULAS) y su fila en la ficha.
	const STAT_NAMES := {"health": "Puntos de vida", "sanity": "Puntos de cordura", "dodge": "Acción de esquiva",
		"speed": "Velocidad", "magic": "Ataques mágicos", "physical": "Ataques físicos", "firearm": "Ataques balísticos"}
	const STAT_KEYS := {"vida": "health", "cordura": "sanity", "esquive": "dodge", "velocidad": "speed",
		"magia": "magic", "fisico": "physical", "fuego": "firearm"}

	## Recuadro de latón con los márgenes de siempre (10 y 8 px: los anchos de la ficha se midieron con ellos).
	static func _frame(bg: Color, border: Color, width: int) -> StyleBoxFlat:
		var sb := MenuKit.box(bg, border, width)
		sb.content_margin_left = 10; sb.content_margin_right = 10
		return sb

	## Columna de la ficha: icono (con su descripción emergente), nombre y valor, en un
	## recuadro dorado. Atributos con su abreviatura (POD); estadísticas con su nombre.
	## Anchos fijos (tag_w, val_w: medidos con la fuente para el texto más largo, "+100 %")
	## y textos recortados, para que el recuadro no cambie de ancho con los valores.
	func _column(names: Array, into: Dictionary, tag_w: float, val_w: float) -> PanelContainer:
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", _frame(Color(0, 0, 0, 0.4), Color(MenuKit.BRASS, 0.5), 1))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		box.add_child(v)
		for n in names:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			row.custom_minimum_size.y = 27
			var icon := TipIcon.new(Vector2(24, 24))              # 25 % menores que los 32 originales
			icon.set_icon(load(ICONS % n), n)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
			_tips.append(icon)
			var is_attr: bool = n in Attributes.NAMES
			var tag := MenuKit.title(n if is_attr else STAT_NAMES[STAT_KEYS[n]], 17 if is_attr else 16, UiKit.GOLD)
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			tag.size_flags_vertical = Control.SIZE_FILL
			tag.clip_text = true
			tag.custom_minimum_size.x = tag_w
			row.add_child(tag)
			var val := MenuKit.title("", 20, UiKit.GOLD)
			val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			val.clip_text = true
			val.custom_minimum_size.x = val_w
			row.add_child(val)
			v.add_child(row)
			into[n] = {"icon": icon, "val": val}
		return box

	## Arriba/abajo con el mando o el teclado: marca el icono siguiente y enseña su descripción.
	func move_cursor(step: int) -> void:
		if _cursor < 0: _cursor = 0 if step > 0 else _tips.size() - 1
		else: _cursor = wrapi(_cursor + step, 0, _tips.size())
		for i in _tips.size(): _tips[i].selected = i == _cursor

	## Coloca una etiqueta centrada en una casilla fija de la ficha (y y alto en el marco).
	func _slot(l: Label, y: float, h: float) -> Label:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.clip_text = false
		l.position = Vector2(0, y)
		l.size = Vector2(_info.size.x, h)
		_info.add_child(l)
		return l

	## Reduce el cuerpo de una etiqueta hasta que quepa en una línea de su casilla (como
	## mucho hasta min_size). Para nombres y descripciones que no deben partirse.
	static func _fit_line(l: Label, max_size: int, min_size: int) -> void:
		var font := l.get_theme_font("font")
		var sz := max_size
		while sz > min_size and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > l.size.x:
			sz -= 1
		l.add_theme_font_size_override("font_size", sz)

	## Qué atributos forman una estadística, para las descripciones.
	static func _pair(stat: String) -> String:
		var p: Array = Attributes.FORMULAS[stat]
		return "%s + %s" % [Attributes.LONG[p[0]], Attributes.LONG[p[1]]]

	## Potenciador respecto a la base: +20 %, −5 % o +0 %.
	static func _bonus(mult: float) -> String:
		var pct := roundi((mult - 1.0) * 100.0)
		return ("+%d %%" % pct) if pct >= 0 else ("−%d %%" % -pct)

	## Deja el modelo girado un ángulo (como si el jugador lo hubiera girado con LB/RB).
	func set_turn(yaw: float) -> void:
		_view.set_turn(yaw)
		_pet_view.set_turn(yaw)

	func shake() -> void:
		if _shake <= 0.0: _base_x = position.x
		_shake = 0.3

	func refresh() -> void:
		var st := owner_screen.state
		var seat: SelectState.Seat = st.seats[index]
		var color := Devices.COLORS[index]
		var on := seat != null
		_empty.visible = not on
		for c in [_view, _info, _pet, _wbox]: (c as CanvasItem).visible = on
		var ready := on and seat.stage == SelectState.Stage.READY        # el latón se enciende con su color
		MenuKit.retint(_panel, MenuKit.BRASS.lerp(color, 0.5 if ready else 0.3) * (1.15 if ready else (0.95 if on else 0.5)), 0.95 if on else 0.7)
		_jbox.visible = on
		_who.visible = on and owner_screen.net_select != null
		if on: _who.text = st.profile_of(index).name
		if not on:
			_head.visible = true
			for a in _arrows: a.visible = false
			return
		var c: CharacterData = st.characters[seat.character]
		_head.visible = false
		_view.set_model(c.model, st.worn_of(index))
		var locked := st.is_locked(seat.character, index)
		var holder := st.holder_of(seat.character, index)   # quién lo ha confirmado ya (D-23)
		var unavailable := seat.stage == SelectState.Stage.CHARACTER and (locked or holder >= 0)
		_view.modulate = Color(0.25, 0.25, 0.3) if unavailable else Color.WHITE
		_name.text = c.display_name
		_role.text = c.role
		var wd: WeaponData = null
		if not c.starting_weapons.is_empty(): wd = load("res://data/weapons/%s.tres" % c.starting_weapons[0])
		_weapon.set_icon(wd.get_icon() if wd else null, wd.display_name if wd else "Sin arma", wd.description if wd else "")
		_passive.text = "Rasgo: " + c.passive_text
		var rec := Endless.best_of(Auto.save(), String(c.id))
		_record.text = "Noche eterna
%s" % Endless.clock(rec) if rec > 0.0 else ""
		_fit_line(_name, 32, 24)
		_fit_line(_role, 16, 13)
		var at := Attributes.initial(c)
		for n in Attributes.NAMES:
			var cell: Dictionary = _attr_vals[n]
			var l: Label = cell["val"]
			l.text = str(int(at[n]))
			l.add_theme_color_override("font_color", UiKit.GOLD if int(at[n]) > Attributes.BASE else UiKit.TEXT_DIM)
			var uses := PackedStringArray()
			for fs in Attributes.FORMULAS:
				if n in Attributes.FORMULAS[fs]: uses.append(String(STAT_NAMES[fs]).to_lower())
			(cell["icon"] as TipIcon).set_icon(load(ICONS % n), Attributes.LONG[n], "%s\nSube: %s." % [Attributes.DESC[n], ", ".join(uses)])
		for n in STAT_ROWS:
			var sk: String = STAT_KEYS[n]
			var m := Attributes.mult(at, sk)
			var cell: Dictionary = _stat_vals[n]
			var l: Label = cell["val"]
			var text := ""
			match sk:
				"health":
					l.text = str(roundi(c.max_health * m))
					text = "Puntos de vida al empezar."
				"sanity":
					l.text = str(roundi(c.max_sanity * m))
					text = "Cordura al empezar. A cero, crisis de parálisis."
				"dodge":
					l.text = _bonus(m / c.dodge_cooldown_mult)
					text = "Rapidez con la que se recarga el esquive."
				"speed":
					l.text = _bonus(m)
					text = "Velocidad al andar."
				"magic":
					l.text = _bonus(m)
					text = "Daño de las armas arcanas y de los Mitos."
				"physical":
					l.text = _bonus(m)
					text = "Daño de las armas cuerpo a cuerpo y lanzadas."
				"firearm":
					l.text = _bonus(m)
					text = "Daño de las armas de fuego."
			l.add_theme_color_override("font_color", UiKit.TEXT_DIM if l.text == "+0 %" else UiKit.GOLD)
			(cell["icon"] as TipIcon).set_icon(load(ICONS % n), STAT_NAMES[sk], "%s (%s)." % [text.trim_suffix("."), _pair(sk)])
		var choosing := seat.stage == SelectState.Stage.CHARACTER
		for a in _arrows: a.visible = choosing and st.choices(index).size() > 1
		match seat.stage:
			SelectState.Stage.CHARACTER:
				if holder >= 0: _status.text = "Lo lleva J%d" % (holder + 1)
				elif locked and not Demo.character_ok(c): _status.text = Demo.LOCKED
				elif locked: _status.text = "Se compra en la tienda (%s)" % MenuKit.money(c.price)
				else: _status.text = "A: elegir"
				_status.add_theme_color_override("font_color", MenuKit.DANGER if unavailable else UiKit.TEXT_DIM)
			SelectState.Stage.OUTFIT:
				_status.text = "Vestuario · A: confirmar"
				_status.add_theme_color_override("font_color", color)
			SelectState.Stage.PET:
				_status.text = "A: confirmar"
				_status.add_theme_color_override("font_color", color)
			SelectState.Stage.READY:
				_status.text = "¡Listo!"
				_status.add_theme_color_override("font_color", color)
		_paint_outfit(seat, color)
		var pets := st.pets_of(index)
		var pet: PetData = pets[seat.pet] if seat.pet < pets.size() else null
		var picking := seat.stage == SelectState.Stage.PET
		_pet_name.text = pet.display_name if pet else "Sin compañero"
		for a in _pet_arrows: a.visible = picking and pets.size() > 1
		_pet_view.set_model(pet.model if pet else "")
		_pet_note.text = "" if pet else ("Se consiguen en la tienda" if pets.size() == 1 else "Irás solo")
		var active := picking or seat.stage == SelectState.Stage.READY
		_pet_title.add_theme_color_override("font_color", UiKit.GOLD if active else Color(UiKit.GOLD, 0.45))
		_pet_name.add_theme_color_override("font_color", color if active else UiKit.TEXT_DIM)
		_pet_view.modulate = Color.WHITE if active else Color(0.55, 0.55, 0.6)
		MenuKit.retint(_pet, MenuKit.BRASS.lerp(color, 0.45 if picking else 0.2) * (1.1 if picking else 0.75), 0.95)

	func _paint_outfit(seat: SelectState.Seat, color: Color) -> void:
		_outfit.visible = seat.stage == SelectState.Stage.OUTFIT
		_sheet_title.visible = not _outfit.visible
		_sheet_cols.visible = not _outfit.visible
		if not _outfit.visible: return
		for k in OutfitData.KEYS.size():
			var id := String(seat.worn.get(SelectState.OUTFIT_KEYS[k], ""))
			var o := OutfitData.find(id) if id != "" else null
			var on := k == seat.outfit_row
			var l: Label = _outfit_rows[k]
			l.text = ("◀  %s  ▶" if on else "%s") % (o.display_name if o else OutfitData.empty_name(k))
			l.add_theme_color_override("font_color", color if on else UiKit.TEXT_DIM)

	func _process(delta: float) -> void:
		# LB/RB giran lo que se está eligiendo: el compañero en su paso; si no, el personaje
		var st := owner_screen.state
		var seat: SelectState.Seat = st.seats[index] if st else null
		var on_pet := seat != null and seat.stage == SelectState.Stage.PET
		var spin := seat.spin if seat != null else 0
		_view.spin = 0 if on_pet else spin
		_pet_view.spin = spin if on_pet else 0
		if _shake > 0.0:
			_shake -= delta
			position.x = _base_x + (sin(_shake * 80.0) * 6.0 * (_shake / 0.3) if _shake > 0.0 else 0.0)


## Visor 3D de un modelo (personaje o compañero), en su propio mundo: luz de la ficha, se
## balancea mirando al frente, respira con su animación de reposo y gira mientras se mantiene
## LB/RB (`spin`). Al cambiar de modelo vuelve a mirar al frente.
class _Preview extends SubViewportContainer:
	var spin := 0                             ## -1, 0 o 1 mientras se mantiene LB/RB (Q/E)
	var _vp: SubViewport
	var _holder: Node3D
	var _model: Node3D
	var _model_name := ""
	var _phase := 0.0
	var _t := 0.0
	var _yaw := 0.0                           ## giro elegido por el jugador (rad)
	var _user_turned := false                 ## deja de balancearse solo en cuanto el jugador lo gira
	var _cam: Camera3D
	const SPIN_SPEED := 2.6                   ## rad/s

	func _init(view: Vector2, px_per_m: float, phase: float) -> void:
		stretch = true
		size = view
		_phase = phase
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vp = SubViewport.new()
		_vp.own_world_3d = true
		_vp.transparent_bg = true
		_vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(_vp)
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.42, 0.42, 0.5)
		env.ambient_light_energy = 0.9
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.3
		var we := WorldEnvironment.new()
		we.environment = env
		_vp.add_child(we)
		var key := DirectionalLight3D.new()
		key.rotation_degrees = Vector3(-30, 30, 0)
		key.light_color = Color(1.0, 0.86, 0.66)
		key.light_energy = 1.4
		_vp.add_child(key)
		var rim := DirectionalLight3D.new()
		rim.rotation_degrees = Vector3(-20, 200, 0)
		rim.light_color = Color(0.5, 0.65, 1.0)
		rim.light_energy = 0.8
		_vp.add_child(rim)
		_cam = Camera3D.new()
		_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.size = view.y / px_per_m                    # la escala de la partida, aumentada
		_cam.position = Vector3(0, _cam.size * 0.5 - 0.06, 4.0)
		_vp.add_child(_cam)
		_holder = Node3D.new()
		_vp.add_child(_holder)

	## Pone otro modelo ("" para ninguno), vestido con `worn` (vestuario, D-34).
	func set_model(model_name: String, worn: Dictionary = {}) -> void:
		var key := model_name + str(worn)
		if key == _model_name: return
		var same := _model_name.begins_with(model_name + "{") and model_name != ""
		if not same:
			_user_turned = false              # otro personaje: vuelve a mirar al frente
			_yaw = 0.0
		if _model: _model.queue_free()
		_model = null
		_model_name = key
		if model_name == "": return
		_model = VoxelBuilder.load_model("res://models/%s.json" % model_name)
		OutfitData.apply(_model, model_name, worn)
		_holder.add_child(_model)

	## Lo deja girado un ángulo (como si el jugador lo hubiera girado con LB/RB).
	func set_turn(yaw: float) -> void:
		_user_turned = true
		_yaw = yaw

	func _process(delta: float) -> void:
		_t += delta
		if _model == null or not _model.is_inside_tree(): return
		if spin != 0:
			if not _user_turned: _yaw = _holder.rotation.y         # parte de donde estaba
			_user_turned = true
			_yaw += spin * SPIN_SPEED * delta
		if _user_turned: _holder.rotation.y = _yaw
		else: _holder.rotation.y = 0.35 + sin(_t * 0.6 + _phase) * 0.45   # se balancea, mirando al frente
		var mn := _model_name.get_slice("{", 0)
		Anims.pose(mn, "idle", _model, fposmod(_t / Anims.duration(mn, "idle"), 1.0))
