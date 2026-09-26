class_name CharacterSelect
extends Control
## Selección de personaje (D-22, D-23), al estilo de Extremadura Survivors: cuatro marcos,
## uno por jugador. Cada dispositivo se une con Start (el teclado, con Intro) y maneja su
## marco con su propio mando: izquierda/derecha cambia de personaje o de compañero, A
## confirma y B deshace. La entrada se lee aquí por dispositivo, sin el foco de Godot (que
## es uno para toda la pantalla). Cuando todos los presentes están listos se abre el mapa
## de niveles. Opciones detrás de `--` (capturas): join=N une N jugadores de prueba;
## ready=N deja listos los N primeros; map=true abre el mapa; auto_start=true, además, entra
## en el nivel 1 (probar el paso a la partida).

const BG := "res://resources/PantallasMenus/fondo_titulo_sin_texto_1080p_definitivo.png"
const DESIGN := Vector2(1920, 1080)
const FRAME := Vector2(400, 610)
const GAP := 34.0
const TOP := 150.0
const STICK := 0.6                          ## umbral del stick para contar como una pulsación

var state: SelectState
var args: LaunchArgs
var _frames: Array[_Frame] = []
var _map: LevelMap
var _stick := {}                            ## dispositivo -> dirección del stick ya contada
var _leaving := false
var _opening := false

func _ready() -> void:
	args = LaunchArgs.from_cmdline()
	UiInput.configure()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var chars: Array[CharacterData] = []
	for r in DebugOptions.list_resources("res://data/characters"): chars.append(r)
	var pets: Array[PetData] = []
	var owned: Array = Saves.current.pets if Saves.current else []
	for r in DebugOptions.list_resources("res://data/pets"):
		if owned.has(String((r as PetData).id)) or (r as PetData).price == 0: pets.append(r)
	state = SelectState.new().setup(chars, Saves.current.characters if Saves.current else [], pets)
	_build()
	state.changed.connect(_refresh)
	Devices.joy_disconnected.connect(func(d: int) -> void:
		var s := state.seat_of(d)
		if s >= 0: state.leave(s))
	# el que ha llegado hasta aquí desde el menú entra ya como J1
	state.join(Devices.last_device)
	_demo_from_args()
	_refresh()
	if args.has("shots"):
		add_child(ShotTaker.new(args.get_floats("shots"), "res://shots/seleccion%s" % (("_" + args.get_str("tag")) if args.has("tag") else "")))

func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var stage := Control.new()                  # todo en coordenadas de 1920x1080, centrado
	stage.size = DESIGN
	add_child(stage)
	var t := MenuKit.title("Elige a tu investigador", 50)
	t.size = Vector2(DESIGN.x, 70)
	t.position = Vector2(0, 50)
	stage.add_child(t)
	if Saves.current:
		var m := UiKit.label("Dinero  %s" % MenuKit.money(Saves.current.money), 22, UiKit.GOLD)
		m.position = Vector2(DESIGN.x - 260, 30)
		stage.add_child(m)
	var total := FRAME.x * 4 + GAP * 3
	for i in 4:
		var f := _Frame.new(self, i)
		f.position = Vector2((DESIGN.x - total) * 0.5 + i * (FRAME.x + GAP), TOP)
		stage.add_child(f)
		_frames.append(f)
	var hint := MenuKit.hint("Start o Intro: unirse  ·  Izquierda/derecha: cambiar  ·  A o Intro: elegir  ·  B o Esc: atrás")
	hint.size = Vector2(DESIGN.x, 30)
	hint.position = Vector2(0, DESIGN.y - 60)
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
	if state.all_ready() and _map == null and not _leaving:
		_open_map.call_deferred()

# ---------------------------------------------------------------- entrada por dispositivo

func _input(event: InputEvent) -> void:
	if _map != null or _leaving: return
	var d: Variant = Devices.device_of(event)
	if d == null: return
	var dev: int = d
	var act := _action(event, dev)
	if act == "": return
	get_viewport().set_input_as_handled()
	var seat := state.seat_of(dev)
	if seat < 0:
		if act in ["join", "confirm"]: state.join(dev)
		elif act == "back" and state.joined().is_empty(): _back_to_menu()
		return
	match act:
		"left": state.move(seat, -1)
		"right": state.move(seat, 1)
		"confirm", "join":
			if not state.confirm(seat): _frames[seat].shake()
		"back":
			if not state.back(seat) and state.joined().is_empty(): _back_to_menu()

## Traduce un evento a una acción del menú: left, right, confirm, back, join o "".
func _action(event: InputEvent, dev: int) -> String:
	if event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo: return ""
		match k.physical_keycode:
			KEY_LEFT, KEY_A: return "left"
			KEY_RIGHT, KEY_D: return "right"
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: return "confirm"
			KEY_ESCAPE, KEY_BACKSPACE: return "back"
		return ""
	if event is InputEventJoypadButton:
		var b := event as InputEventJoypadButton
		if not b.pressed: return ""
		match b.button_index:
			JOY_BUTTON_DPAD_LEFT: return "left"
			JOY_BUTTON_DPAD_RIGHT: return "right"
			JOY_BUTTON_A: return "confirm"
			JOY_BUTTON_START: return "join"
			JOY_BUTTON_B: return "back"
		return ""
	if event is InputEventJoypadMotion and (event as InputEventJoypadMotion).axis == JOY_AXIS_LEFT_X:
		# el stick cuenta una vez al pasar el umbral y otra al volver al centro
		var v := (event as InputEventJoypadMotion).axis_value
		var dir := 1 if v > STICK else (-1 if v < -STICK else 0)
		var prev: int = _stick.get(dev, 0)
		_stick[dev] = dir if absf(v) > 0.3 else 0
		if dir != 0 and prev == 0: return "right" if dir > 0 else "left"
	return ""

# ---------------------------------------------------------------- mapa y salida

func _open_map() -> void:
	if _opening: return                               # varios cambios seguidos piden abrirlo varias veces
	_opening = true
	await get_tree().create_timer(0.35).timeout      # que se vea el "Listo" del último
	_opening = false
	if not is_inside_tree() or _leaving or not state.all_ready() or _map != null: return
	if args.get_bool("auto_start"):                    # pruebas: directo al nivel 1
		_start("p1_n1")
		return
	_map = LevelMap.new()
	add_child(_map)
	_map.chosen.connect(_start)
	_map.closed.connect(func() -> void:
		_map = null
		state.unready_all())

func _start(level_id: String) -> void:
	GameSession.clear()
	GameSession.level = StringName(level_id)
	for i in state.joined():
		var s: SelectState.Seat = state.seats[i]
		var seat := GameSession.Seat.new()
		seat.slot = i
		seat.device = s.device
		seat.guid = Devices.guid(s.device) if s.device >= Devices.KEYBOARD else ""
		seat.character = state.characters[s.character].id
		var pet: PetData = state.pets[s.pet]
		seat.pet = pet.id if pet else &""
		GameSession.seats.append(seat)
	_leaving = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _back_to_menu() -> void:
	_leaving = true
	TitleScreen.skip_to_menu = true
	get_tree().change_scene_to_file("res://scenes/title.tscn")

## Capturas: jugadores de prueba con dispositivos ficticios.
func _demo_from_args() -> void:
	for k in args.get_int("join", 0): state.join(-10 - k)
	var ready := args.get_int("ready", 0)
	var j := state.joined()
	for k in mini(ready, j.size()):
		state.confirm(j[k])
		if k % 2 == 1: state.move(j[k], 1)
		state.confirm(j[k])
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
	var _view: SubViewportContainer
	var _vp: SubViewport
	var _holder: Node3D
	var _model: Node3D
	var _model_name := ""
	var _info: VBoxContainer
	var _name: Label
	var _role: Label
	var _weapon: Label
	var _passive: Label
	var _stats: Label
	var _status: Label
	var _arrows: Array[Label] = []
	var _empty: VBoxContainer
	var _pet: PanelContainer
	var _pet_label: Label
	var _t := 0.0
	var _shake := 0.0
	var _base_x := 0.0

	func _init(p_owner: CharacterSelect, p_index: int) -> void:
		owner_screen = p_owner
		index = p_index
		size = Vector2(FRAME.x, FRAME.y + 90)

	func _ready() -> void:
		var color := Devices.COLORS[index]
		_panel = Panel.new()
		_panel.size = FRAME
		_panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.022, 0.03, 0.9), Color(color, 0.25), 10))
		add_child(_panel)
		_head = MenuKit.title("J%d" % (index + 1), 26, color)
		_head.size = Vector2(FRAME.x, 40)
		_head.position = Vector2(0, 10)
		add_child(_head)
		# el personaje en 3D, en su propio mundo
		_view = SubViewportContainer.new()
		_view.stretch = true
		_view.size = Vector2(FRAME.x - 20, 330)
		_view.position = Vector2(10, 50)
		add_child(_view)
		_vp = SubViewport.new()
		_vp.own_world_3d = true
		_vp.transparent_bg = true
		_vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_view.add_child(_vp)
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
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 2.05
		cam.position = Vector3(0, 0.9, 4.0)             # el modelo mide 1,72 m: cabe con su gorro
		_vp.add_child(cam)
		_holder = Node3D.new()
		_vp.add_child(_holder)
		for side in [-1, 1]:
			var a := UiKit.label("◀" if side < 0 else "▶", 34, color)
			a.position = Vector2(14 if side < 0 else FRAME.x - 44, 190)
			add_child(a)
			_arrows.append(a)
		# ficha
		_info = VBoxContainer.new()
		_info.position = Vector2(22, 372)
		_info.size = Vector2(FRAME.x - 44, 0)
		_info.add_theme_constant_override("separation", 4)
		add_child(_info)
		_name = MenuKit.title("", 30)
		_info.add_child(_name)
		_role = UiKit.label("", 16, UiKit.TEXT_DIM)
		_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_info.add_child(_role)
		_weapon = UiKit.label("", 17, UiKit.TEXT)
		_weapon.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_weapon.custom_minimum_size.x = FRAME.x - 44
		_info.add_child(_weapon)
		_passive = UiKit.label("", 17, UiKit.TEXT)
		_passive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_passive.custom_minimum_size.x = FRAME.x - 44
		_info.add_child(_passive)
		_stats = UiKit.label("", 16, UiKit.TEXT_DIM)
		_info.add_child(_stats)
		_status = MenuKit.title("", 24, color)
		_status.size = Vector2(FRAME.x, 36)
		_status.position = Vector2(0, FRAME.y - 42)
		add_child(_status)
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
		# compañero, debajo del marco
		_pet = PanelContainer.new()
		_pet.position = Vector2(0, FRAME.y + 14)
		_pet.custom_minimum_size = Vector2(FRAME.x, 70)
		_pet.size = Vector2(FRAME.x, 70)
		_pet.clip_contents = true
		add_child(_pet)
		_pet_label = UiKit.label("", 19, UiKit.TEXT)
		_pet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_pet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_pet_label.custom_minimum_size.x = FRAME.x - 24
		_pet.add_child(_pet_label)

	func shake() -> void:
		if _shake <= 0.0: _base_x = position.x
		_shake = 0.3

	func refresh() -> void:
		var st := owner_screen.state
		var seat: SelectState.Seat = st.seats[index]
		var color := Devices.COLORS[index]
		var on := seat != null
		_empty.visible = not on
		for c in [_view, _info, _status, _pet]: (c as CanvasItem).visible = on
		_panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.022, 0.03, 0.9 if on else 0.6),
			Color(color, 0.85 if on and seat.stage == SelectState.Stage.READY else (0.45 if on else 0.18)), 10))
		if not on:
			_head.text = "J%d" % (index + 1)
			for a in _arrows: a.visible = false
			return
		var c: CharacterData = st.characters[seat.character]
		_head.text = "J%d  ·  %s" % [index + 1, Devices.device_name(seat.device) if seat.device >= Devices.KEYBOARD else "Prueba"]
		_set_model(c.model)
		var locked := st.is_locked(seat.character)
		var holder := -1                            # quién lo ha confirmado ya (D-23)
		for j in st.seats.size():
			if j != index and st.seats[j] != null and (st.seats[j] as SelectState.Seat).stage != SelectState.Stage.CHARACTER 					and (st.seats[j] as SelectState.Seat).character == seat.character:
				holder = j
		var unavailable := seat.stage == SelectState.Stage.CHARACTER and (locked or holder >= 0)
		_view.modulate = Color(0.25, 0.25, 0.3) if unavailable else Color.WHITE
		_name.text = c.display_name
		_role.text = c.role
		var wnames := PackedStringArray()
		for wid in c.starting_weapons:
			var wd: WeaponData = load("res://data/weapons/%s.tres" % wid)
			wnames.append(wd.display_name if wd else String(wid))
		_weapon.text = "Arma: " + ", ".join(wnames)
		_passive.text = "Rasgo: " + c.passive_text
		_stats.text = "Vida %d  ·  Cordura %d  ·  Velocidad %s" % [c.max_health, c.max_sanity, String.num(c.move_speed, 1).replace(".", ",")]
		var choosing := seat.stage == SelectState.Stage.CHARACTER
		for a in _arrows: a.visible = choosing and st.choices(index).size() > 1
		match seat.stage:
			SelectState.Stage.CHARACTER:
				if holder >= 0: _status.text = "Lo lleva J%d" % (holder + 1)
				elif locked: _status.text = "Se compra en la tienda (%s)" % MenuKit.money(c.price)
				else: _status.text = "A: elegir"
				_status.add_theme_color_override("font_color", MenuKit.DANGER if unavailable else UiKit.TEXT_DIM)
			SelectState.Stage.PET:
				_status.text = "Elige compañero"
				_status.add_theme_color_override("font_color", color)
			SelectState.Stage.READY:
				_status.text = "¡Listo!"
				_status.add_theme_color_override("font_color", color)
		var pet: PetData = st.pets[seat.pet]
		var pet_name := pet.display_name if pet else "Ninguno"
		var picking := seat.stage == SelectState.Stage.PET
		_pet_label.text = ("◀  Compañero: %s  ▶" if picking and st.pets.size() > 1 else "Compañero: %s") % pet_name
		if st.pets.size() == 1: _pet_label.text += "
Se consiguen en la tienda"

		_pet.add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.022, 0.03, 0.9), Color(color, 0.85 if picking else 0.2), 8))
		_pet_label.add_theme_color_override("font_color", UiKit.TEXT if picking or seat.stage == SelectState.Stage.READY else UiKit.TEXT_DIM)

	func _set_model(model_name: String) -> void:
		if model_name == _model_name: return
		if _model: _model.queue_free()
		_model_name = model_name
		_model = VoxelBuilder.load_model("res://models/%s.json" % model_name)
		_holder.add_child(_model)

	func _process(delta: float) -> void:
		_t += delta
		if _model and _model.is_inside_tree():
			_holder.rotation.y = 0.35 + sin(_t * 0.6 + index) * 0.45       # se balancea, mirando al frente
			Anims.pose(_model_name, "idle", _model, fposmod(_t / Anims.duration(_model_name, "idle"), 1.0))
		if _shake > 0.0:
			_shake -= delta
			position.x = _base_x + (sin(_shake * 80.0) * 6.0 * (_shake / 0.3) if _shake > 0.0 else 0.0)
