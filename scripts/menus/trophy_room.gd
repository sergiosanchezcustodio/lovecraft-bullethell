class_name TrophyRoom
extends Control
## Sala de trofeos (hito 16.28; tomo XI de la Biblioteca): una sala 3D con tres vitrinas (Trophies:
## conjuntos, jefes y logros grandes). Cada hueco tiene su peana; lo ganado sale encima, en
## miniatura, y lo que falta deja la peana vacía, así que la sala se va llenando. La cámara va de
## hueco en hueco; el que tiene el foco gira despacio con su animación de reposo y abajo sale su
## placa (nombre, qué es, la nota y los datos).
## Flechas o cruceta: recorrer (de una vitrina pasa a la de al lado); LB/RB o Q/E: otra vitrina;
## B / Esc: volver. Capturas: `open=menu_biblioteca tome=10 cursor=N` (N: el hueco, de todas).

signal closed

const SLOT_W := 20.0 / 32.0                      ## de gen_trofeos.py (huecos de 20 x 23 voxels)
const SLOT_H := 23.0 / 32.0
const BASE_Y := 10.0 / 32.0                      ## altura de la primera balda
const SLOT_Z := -6.5 / 32.0                      ## centro del hueco, de delante a atrás
const ROWS := 3
const GAP := 0.9                                 ## entre vitrinas
const PEANA_H := 5.0 / 48.0
const FIT_H := 0.5                               ## lo más alto y ancho que cabe sobre la peana
const FIT_W := 0.5
const CAM_BACK := 4.4
const MID_Y := BASE_Y + ROWS * SLOT_H * 0.5      ## media altura de las baldas: la cámara no sube ni baja mucho

var save: SaveData
var cursor := -1                                 ## hueco con el foco (-1: el primero de los jefes)
var _items: Array[Dictionary] = []
var _cases: Array = []                           ## por vitrina: [índices en _items]
var _origin: Array[Vector3] = []                 ## posición de cada vitrina
var _slots: Array[Vector3] = []                  ## por trofeo: centro de la peana (arriba)
var _turns: Array = []                           ## por trofeo: el contenedor que gira (o null)
var _models: Array = []
var _vp: SubViewport
var _cam: Camera3D
var _spot: SpotLight3D
var _cam_target := Vector3.ZERO
var _cam_pos := Vector3.ZERO
var _look := Vector3.ZERO
var _anim_t := 0.0
var _name: Label
var _kind: Label
var _text: Label
var _facts: Label
var _count: Label
var _plaque: Control
var _loading: Label
var _task := -1                                  ## hilo que construye las mallas
var _t0 := 0

func _ready() -> void:
	if save == null: save = Saves.current
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var t0 := Time.get_ticks_msec()
	_items = Trophies.all(save)
	var box := SubViewportContainer.new()
	box.stretch = true
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = get_viewport().msaa_3d             # el de la calidad gráfica
	_vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	box.add_child(_vp)
	_t0 = t0
	_build_ui()
	_loading = UiKit.label("Encendiendo las lámparas…", 24, UiKit.TEXT_DIM)
	_loading.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_loading)
	_plaque.visible = false
	get_viewport().gui_release_focus()
	# las mallas que no estén en la caché se construyen en otro hilo (la primera vez, unos 3 s):
	# la sala se monta cuando acaba, sin congelar la pantalla
	var paths: Array[String] = []
	for m: String in Trophies.CASE_MODELS + ["sala_pared", "sala_suelo", "trofeo_peana"]: paths.append("res://models/%s.json" % m)
	for t: Dictionary in _items:
		if t.earned: paths.append("res://models/%s.json" % t.model)
	_task = WorkerThreadPool.add_task(func() -> void:
		for p in paths:
			if VoxelBuilder.model_exists(p): VoxelBuilder.warm(p), false, "TrophyRoom")

## Con las mallas listas: la sala, el foco y la placa.
func _finish() -> void:
	_build_room()
	_loading.queue_free()
	_plaque.visible = true
	if cursor < 0:
		for i in _items.size():
			if int(_items[i].case) == 1:
				cursor = i
				break
	cursor = clampi(cursor, 0, maxi(_items.size() - 1, 0))
	if LaunchArgs.from_cmdline().get_bool("log"):
		var n := Trophies.count(save)
		print("SALA DE TROFEOS %d ms  %d de %d" % [Time.get_ticks_msec() - _t0, n.x, n.y])
	_cam_target = _focus_point(cursor)
	_cam_pos = Vector3(_origin[1].x, 1.6, 7.5)       # entra desde lejos y se acerca
	_look = Vector3(_origin[1].x, 1.2, 0)
	_show(cursor)

# ------------------------------------------------------------------ sala

func _build_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.012, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.27, 0.22)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.04, 0.035)
	env.fog_density = 0.04
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	# las tres vitrinas, juntas por los costados (las anchuras salen de sus columnas)
	var widths: Array[float] = []
	var total := 0.0
	for c in Trophies.CASE_COLS.size():
		widths.append(Trophies.CASE_COLS[c] * SLOT_W + 6.0 / 32.0)
		total += widths[c]
	total += GAP * (widths.size() - 1)
	var x := -total * 0.5
	for c in widths.size():
		_origin.append(Vector3(x + widths[c] * 0.5, 0, 0))
		x += widths[c] + GAP
		_vp.add_child(_place(Trophies.CASE_MODELS[c], _origin[c]))
		_glass(_origin[c], widths[c])
		var lamp := OmniLight3D.new()                # luz cálida dentro de cada vitrina, arriba
		lamp.light_color = Color(1.0, 0.78, 0.5)
		lamp.light_energy = 1.6
		lamp.omni_range = 3.2
		lamp.omni_attenuation = 1.4
		lamp.position = _origin[c] + Vector3(0, BASE_Y + ROWS * SLOT_H + 0.05, 0.35)
		_vp.add_child(lamp)
		var low := OmniLight3D.new()
		low.light_color = Color(1.0, 0.72, 0.45)
		low.light_energy = 0.8
		low.omni_range = 2.4
		low.position = _origin[c] + Vector3(0, BASE_Y + SLOT_H, 0.6)
		_vp.add_child(low)
		_cases.append([])
	_vp.add_child(_place("sala_pared", Vector3(0, 0, -0.62)))
	_vp.add_child(_place("sala_suelo", Vector3(0, -1.0 / 16.0, -0.62)))
	var moon := DirectionalLight3D.new()            # luna fría por una ventana que no se ve
	moon.rotation_degrees = Vector3(-35, -40, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.18
	_vp.add_child(moon)
	_spot = SpotLight3D.new()                       # la del hueco con el foco
	_spot.light_color = Color(1.0, 0.9, 0.75)
	_spot.light_energy = 1.6
	_spot.spot_range = 2.5
	_spot.spot_angle = 13.0
	_spot.spot_attenuation = 0.6
	_vp.add_child(_spot)
	_cam = Camera3D.new()
	_cam.fov = 34.0
	_cam.current = true
	_vp.add_child(_cam)
	# peanas y trofeos
	for i in _items.size():
		var t: Dictionary = _items[i]
		var c := int(t.case)
		var k: int = (_cases[c] as Array).size()
		(_cases[c] as Array).append(i)
		var cols := Trophies.CASE_COLS[c]
		var col := k % cols
		var row := k / cols                          # 0 = la balda de arriba
		var shelf := ROWS - 1 - mini(row, ROWS - 1)
		var p := _origin[c] + Vector3(-cols * SLOT_W * 0.5 + (col + 0.5) * SLOT_W, BASE_Y + shelf * SLOT_H + 1.0 / 32.0, SLOT_Z)
		_vp.add_child(_place("trofeo_peana", p))
		_slots.append(p + Vector3(0, PEANA_H, 0))
		var turn: Node3D = null
		var m: Node3D = null
		if t.earned and VoxelBuilder.model_exists("res://models/%s.json" % t.model):
			turn = Node3D.new()
			turn.position = p + Vector3(0, PEANA_H, 0)
			_vp.add_child(turn)
			m = VoxelBuilder.load_model("res://models/%s.json" % t.model)
			turn.add_child(m)
			if not (t.worn as Dictionary).is_empty(): OutfitData.apply(m, String(t.model), t.worn)
			if Anims.has_anim(String(t.model), "idle"): Anims.pose(String(t.model), "idle", m, 0.25)
			_fit(m)
			turn.rotation.y = 0.35
		_turns.append(turn)
		_models.append(m)

func _place(model: String, at: Vector3) -> Node3D:
	var holder := Node3D.new()                     # la posición, en un contenedor
	holder.position = at
	holder.add_child(VoxelBuilder.load_model("res://models/%s.json" % model))
	return holder

## El cristal de la vitrina: casi transparente, con el brillo de las luces.
func _glass(at: Vector3, width: float) -> void:
	var q := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width - 6.0 / 32.0, ROWS * SLOT_H)
	q.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.7, 0.8, 0.85, 0.05)
	mat.roughness = 0.25                             # brillo ancho y suave (fino, parecía un punto suelto)
	mat.metallic_specular = 0.6
	mat.rim_enabled = true
	mat.rim = 0.3
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.position = at + Vector3(0, BASE_Y + ROWS * SLOT_H * 0.5, 2.0 / 32.0)
	_vp.add_child(q)

## Encoge el modelo para que quepa en el hueco, con los pies sobre la peana y centrado.
func _fit(m: Node3D) -> void:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in m.get_meta("meshes", []):
		var a: AABB = mi.global_transform * mi.get_aabb()
		box = a if first else box.merge(a)
		first = false
	if first: return
	var base := m.get_parent() as Node3D
	var local := base.global_transform.affine_inverse() * box
	var s := minf(FIT_H / maxf(local.size.y, 0.01), FIT_W / maxf(maxf(local.size.x, local.size.z), 0.01))
	s = minf(s, 1.4)
	base.scale = Vector3.ONE * s
	var c := local.get_center()
	m.position = Vector3(-c.x, -local.position.y, -c.z)

# ------------------------------------------------------------------ placa

func _build_ui() -> void:
	var shade := TextureRect.new()                   # sombra arriba, para que se lea el título
	var g := GradientTexture2D.new()
	g.fill_from = Vector2(0, 0); g.fill_to = Vector2(0, 1)
	g.gradient = Gradient.new()
	g.gradient.set_color(0, Color(0, 0, 0, 0.75))
	g.gradient.set_color(1, Color(0, 0, 0, 0))
	shade.texture = g
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 190
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top.position.y = 36
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(top)
	var t := MenuKit.title("Sala de trofeos", 46, UiKit.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(t)
	_count = UiKit.label("", 19, UiKit.TEXT_DIM)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_count)
	var n := Trophies.count(save)
	_count.text = "%d de %d trofeos" % [n.x, n.y]
	var panel := PanelContainer.new()                # placa de tamaño fijo, abajo en el centro
	panel.theme = MenuKit.theme()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
	panel.offset_left = -500; panel.offset_right = 500
	panel.offset_top = -250; panel.offset_bottom = -30
	add_child(panel)
	_plaque = panel
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	_kind = UiKit.label("", 16, UiKit.GOLD)
	_kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_kind)
	_name = MenuKit.title("", 34, UiKit.TEXT)
	col.add_child(_name)
	_text = UiKit.label("", 18, UiKit.TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 920
	_text.max_lines_visible = 3
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_text)
	_facts = UiKit.label("", 17, UiKit.TEXT_DIM)
	_facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_facts)
	var hint := UiKit.label("Flechas: recorrer  ·  LB/RB o Q/E: otra vitrina  ·  B o Esc: volver", 15, UiKit.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)
	col.move_child(hint, -1)
	MenuKit.dress(panel, MenuKit.BRASS, Vector2(36, 22), 100.0)

func _show(i: int) -> void:
	if _items.is_empty(): return
	var t: Dictionary = _items[i]
	var c := int(t.case)
	var place := (_cases[c] as Array).find(i) + 1
	_kind.text = "%s  ·  %d de %d" % [Trophies.CASES[c], place, (_cases[c] as Array).size()]
	if t.earned:
		_name.text = String(t.name)
		_text.text = String(t.text)
		_facts.text = "  ·  ".join(PackedStringArray([String(t.kind)] + Array(t.facts)))
	else:
		_name.text = "???"
		_text.text = _missing(t)
		_facts.text = "  ·  ".join(PackedStringArray(Array(t.facts))) if c == 2 else ""
	_name.add_theme_color_override("font_color", UiKit.TEXT if t.earned else UiKit.TEXT_DIM)
	_cam_target = _focus_point(i)
	_spot.position = _slots[i] + Vector3(0, 0.95, 0.7)
	_spot.look_at(_slots[i] + Vector3(0, 0.18, 0), Vector3.UP)

func _missing(t: Dictionary) -> String:
	match int(t.case):
		0: return "Peana vacía. Completa un conjunto del vestuario para que su maniquí ocupe este sitio."
		1: return "Peana vacía. Aquí irá la figura del próximo jefe que caiga."
	return "Peana vacía. " + String(t.text)

func _focus_point(i: int) -> Vector3:
	if _slots.is_empty(): return Vector3(0, 1, 0)
	return _slots[i] + Vector3(0, 0.22, 0)

# ------------------------------------------------------------------ cada fotograma

func _process(delta: float) -> void:
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task): return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_finish()
	if _cam == null: return
	var look := Vector3(_cam_target.x, lerpf(MID_Y, _cam_target.y, 0.4) - 0.2, _cam_target.z)   # algo abajo: la placa tapa el pie
	var want := Vector3(_cam_target.x, lerpf(MID_Y, _cam_target.y, 0.3) + 0.35, CAM_BACK)
	var k := 1.0 - exp(-delta * 5.0)
	_cam_pos = _cam_pos.lerp(want, k)
	_look = _look.lerp(look, k)
	_cam.position = _cam_pos
	_cam.look_at(_look, Vector3.UP)
	_anim_t += delta
	for i in _turns.size():
		var turn: Node3D = _turns[i]
		if turn == null: continue
		if i == cursor:
			turn.rotation.y += 0.7 * delta
			var model_name := String(_items[i].model)
			if Anims.has_anim(model_name, "idle"):
				Anims.pose(model_name, "idle", _models[i], fposmod(_anim_t / Anims.duration(model_name, "idle"), 1.0))
		else:
			turn.rotation.y = lerp_angle(turn.rotation.y, 0.35, 1.0 - exp(-delta * 3.0))

# ------------------------------------------------------------------ entrada

func _exit_tree() -> void:
	if _task < 0: return                               # no dejar el hilo suelto (como LevelPreload._wait:
	while not WorkerThreadPool.is_task_completed(_task):   # atendiendo al servidor de dibujo, o se cuelga)
		RenderingServer.force_sync()
		OS.delay_usec(200)
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
		return
	var to := -1
	if _items.is_empty() or _slots.is_empty(): return    # aún montándose
	if event.is_action_pressed("ui_left", true): to = _step(-1, 0)
	elif event.is_action_pressed("ui_right", true): to = _step(1, 0)
	elif event.is_action_pressed("ui_up", true): to = _step(0, -1)
	elif event.is_action_pressed("ui_down", true): to = _step(0, 1)
	elif event is InputEventJoypadButton and event.pressed:
		var b := (event as InputEventJoypadButton).button_index
		if b == JOY_BUTTON_LEFT_SHOULDER: to = _jump(-1)
		elif b == JOY_BUTTON_RIGHT_SHOULDER: to = _jump(1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_Q: to = _jump(-1)
		elif (event as InputEventKey).keycode == KEY_E: to = _jump(1)
	if to < 0: return
	get_viewport().set_input_as_handled()
	if to != cursor:
		cursor = to
		_show(cursor)
		Auto.sfx("ui_move")

## Hueco de al lado: en horizontal pasa a la vitrina vecina (a la misma balda); en vertical, no sale.
func _step(dx: int, dy: int) -> int:
	if _items.is_empty(): return -1
	var c := int(_items[cursor].case)
	var list: Array = _cases[c]
	var k := list.find(cursor)
	var cols := Trophies.CASE_COLS[c]
	var col := k % cols
	var row := k / cols
	if dy != 0:
		var nk := k + dy * cols
		return int(list[nk]) if nk >= 0 and nk < list.size() else cursor
	col += dx
	if col >= 0 and col < cols and row * cols + col < list.size(): return int(list[row * cols + col])
	var nc := c + dx
	if nc < 0 or nc >= _cases.size() or (_cases[nc] as Array).is_empty(): return cursor
	var nl: Array = _cases[nc]
	var ncols := Trophies.CASE_COLS[nc]
	var nrow := mini(row, (nl.size() - 1) / ncols)
	var ncol := 0 if dx > 0 else ncols - 1
	return int(nl[mini(nrow * ncols + ncol, nl.size() - 1)])

## Primera peana de la vitrina de al lado.
func _jump(dc: int) -> int:
	var c := int(_items[cursor].case) + dc
	if c < 0 or c >= _cases.size() or (_cases[c] as Array).is_empty(): return cursor
	return int((_cases[c] as Array)[0])
