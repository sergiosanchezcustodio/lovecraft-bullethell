class_name PhotoMode
extends CanvasLayer
## Modo foto (hito 13.12): desde la pausa, con la partida congelada. Una cámara libre propia
## (mover, girar, inclinar, acercar; isométrica o en perspectiva) sin HUD ni avisos, con
## profundidad de campo, gradación, viñeta y los investigadores a la vista u ocultos. La foto
## va a `Imágenes/Lovecraft Library` (`photo_dir=` para pruebas). Al salir, todo vuelve como
## estaba (`_exit_tree`). En red, solo en el PC que tiene la pausa (que es de todos); si el
## anfitrión la quita, se cierra (`game.net_resume`).
## Controles: stick izquierdo / WASD mueve; stick derecho / Q-E y R-F gira e inclina; LT-RT /
## Z-X / rueda acerca; A / Espacio, foto; Y / Tab, oculta el panel; cruceta y flechas, opciones;
## B / Esc, a la pausa; Start, a jugar.
## Pruebas: `photo_at=t` (abre la pausa y el modo foto a los t s), `photo_auto=true` (captura
## del panel en shots/, una foto y sale), `photo_dof=0..2`, `photo_grade=N`, `photo_persp=true`,
## `photo_vignette=0..2`, `photo_hide=true`, `photo_yaw=`, `photo_pitch=` y `photo_zoom=`.

signal back
signal close

const ACCENT := Color(0.95, 0.82, 0.55)
const DIR_NAME := "Lovecraft Library"
const FOV := 38.0                          ## grados, en perspectiva
const PITCH_MIN := -82.0
const PITCH_MAX := -8.0
const SIZE_MIN := 4.0
const SIZE_MAX := 40.0
const ORTHO_DIST := 45.0
const EYE := 0.8                           ## m sobre el suelo del punto que mira (como GameCamera)
## Profundidad de campo: [m nítidos a cada lado del foco, m de transición, cantidad].
const DOF := [[], [7.0, 12.0, 0.06], [2.5, 6.0, 0.14]]
const DOF_NAMES: Array[String] = ["No", "Suave", "Fuerte"]
const VIGNETTE_NAMES: Array[String] = ["No", "Suave", "Fuerte"]
## Gradaciones de la foto: "" es la de la partida; las demás, como las de data/grades.json.
const EXTRA_GRADES := {
	"sepia": {"name": "Sepia", "shadows": [0.07, 0.015, -0.07], "highlights": [0.09, 0.035, -0.09], "saturation": 0.0},
	"bn": {"name": "Blanco y negro", "shadows": [0.0, 0.0, 0.0], "highlights": [0.0, 0.0, 0.0], "saturation": 0.0},
	"luna": {"name": "Luna fría", "shadows": [-0.04, 0.0, 0.07], "highlights": [-0.02, 0.02, 0.05], "saturation": 0.7},
}

var game: Node
var cam: Camera3D
var pivot := Vector3.ZERO                  ## punto del suelo al que mira
var yaw := 45.0
var pitch := -30.0
var view := 16.0                           ## alto visible (o su equivalente en perspectiva)
var persp := false
var dof := 0
var vignette := 0
var grade := 0                             ## índice en _grades
var hide_players := 0                     ## 0: a la vista; 1: sin los anillos del suelo; 2: ocultos
var _grades: Array = []                    ## [[nombre, gradación o null (la de la partida)]]
var _panel: PanelContainer
var _hint: Label
var _note: Label
var _vig: ColorRect
var _flash: ColorRect
var _hidden: Array[CanvasItem] = []        ## lo que se ha ocultado al entrar (para devolverlo)
var _hidden_layers: Array[CanvasLayer] = []
var _hidden_3d: Array[Node3D] = []
var _old_cam: Camera3D
var _env: Environment
var _env_saved := {}
var _last_ms := 0
var _busy := false
var _auto_t := -1.0

func _init(p_game: Node) -> void:
	game = p_game
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

# ------------------------------------------------------------------ entrar y salir

func _ready() -> void:
	_env = game.get("_env") as Environment
	if _env != null:
		_env_saved = {"on": _env.adjustment_enabled, "cc": _env.adjustment_color_correction, "sat": _env.adjustment_saturation}
	_grades = [["La de la partida", null], ["Sin gradación", {}]]
	for k in ["p1", "p2", "p3"]:
		var g := Atmosphere.grade_for(k)
		if not g.is_empty(): _grades.append([String(g.get("name", k)).get_slice(",", 0), g])
	for k in EXTRA_GRADES: _grades.append([String(EXTRA_GRADES[k].name), EXTRA_GRADES[k]])
	_old_cam = game.get("camera") as Camera3D
	_hide_overlays()
	cam = Camera3D.new()
	cam.name = "PhotoCamera"
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cam.near = 0.3
	cam.far = 200.0
	cam.attributes = CameraAttributesPractical.new()
	game.add_child(cam)
	if _old_cam != null:
		view = _old_cam.size
		pivot = _ground_at_center(_old_cam)
		cam.cull_mask = _old_cam.cull_mask
		cam.environment = _old_cam.environment
	var la: LaunchArgs = game.get("args")
	if la != null:
		dof = clampi(la.get_int("photo_dof", 0), 0, 2)
		vignette = clampi(la.get_int("photo_vignette", 0), 0, 2)
		persp = la.get_bool("photo_persp")
		hide_players = clampi(la.get_int("photo_hide", 0), 0, 2)
		yaw = la.get_float("photo_yaw", yaw)
		pitch = clampf(la.get_float("photo_pitch", pitch), PITCH_MIN, PITCH_MAX)
		view = clampf(la.get_float("photo_zoom", view), SIZE_MIN, SIZE_MAX)
		grade = clampi(la.get_int("photo_grade", 0), 0, _grades.size() - 1)
		if la.get_bool("photo_auto"): _auto_t = 0.0
	_place()
	cam.make_current()
	_build_ui()
	_apply_grade()
	_apply_dof()
	_apply_vignette()
	_apply_hide()
	_last_ms = Time.get_ticks_msec()
	Auto.sfx("menu_open")

func _exit_tree() -> void:
	for c in _hidden: if is_instance_valid(c): c.visible = true
	for l in _hidden_layers: if is_instance_valid(l): l.visible = true
	for n in _hidden_3d: if is_instance_valid(n): n.visible = true
	if _env != null and not _env_saved.is_empty():
		_env.adjustment_enabled = _env_saved.on
		_env.adjustment_color_correction = _env_saved.cc
		_env.adjustment_saturation = _env_saved.sat
	if is_instance_valid(_old_cam): _old_cam.make_current()
	if is_instance_valid(cam): cam.queue_free()

## Fuera el HUD, los avisos y los números: todas las capas de pantalla salvo las que son parte
## de la imagen (la ventisca, por debajo de 0, y la viñeta de la cordura).
func _hide_overlays() -> void:
	for n in game.get_tree().root.find_children("*", "CanvasLayer", true, false):
		var l := n as CanvasLayer
		if l == self or not l.visible or l.layer < 0 or l is SanityFx: continue
		l.visible = false
		_hidden_layers.append(l)
	for n in game.find_children("*", "DamageNumbers", true, false):
		var d := n as Node3D
		if d.visible:
			d.visible = false
			_hidden_3d.append(d)

## Punto al que mira una cámara, en el suelo: su eje cruza la altura de `_place` (0,8 m) ahí
## encima, así que la vista de la foto empieza igual que la del juego.
static func _ground_at_center(c: Camera3D) -> Vector3:
	var o := c.global_position
	var d := -c.global_basis.z
	if absf(d.y) < 0.001: return Vector3(o.x, 0.0, o.z)
	var p := o + d * ((EYE - o.y) / d.y)
	return Vector3(p.x, 0.0, p.z)

# ------------------------------------------------------------------ cámara

func _distance() -> float:
	return ORTHO_DIST if not persp else view * 0.5 / tan(deg_to_rad(FOV) * 0.5)

func _place() -> void:
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0), EULER_ORDER_YXZ)
	cam.transform = Transform3D(b, pivot + Vector3(0, EYE, 0) + b.z * _distance())
	if persp:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = FOV
	else:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = view
	_apply_dof()

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var dt := clampf((now - _last_ms) / 1000.0, 0.0, 0.1)     # tiempo real: la partida está en pausa
	_last_ms = now
	if _auto_t >= 0.0: _auto_step(dt)
	if _busy: return
	var mv := Vector2.ZERO
	var rot := Vector2.ZERO
	var zoom := 0.0
	if Input.is_physical_key_pressed(KEY_A): mv.x -= 1
	if Input.is_physical_key_pressed(KEY_D): mv.x += 1
	if Input.is_physical_key_pressed(KEY_W): mv.y += 1
	if Input.is_physical_key_pressed(KEY_S): mv.y -= 1
	if Input.is_physical_key_pressed(KEY_Q): rot.x -= 1
	if Input.is_physical_key_pressed(KEY_E): rot.x += 1
	if Input.is_physical_key_pressed(KEY_R): rot.y += 1
	if Input.is_physical_key_pressed(KEY_F): rot.y -= 1
	if Input.is_physical_key_pressed(KEY_Z): zoom -= 1
	if Input.is_physical_key_pressed(KEY_X): zoom += 1
	if not JoypadInput.disabled():
		for dev in Input.get_connected_joypads():
			mv += _stick(dev, JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y) * Vector2(1, -1)
			rot += _stick(dev, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y) * Vector2(1, -1)
			zoom += Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_LEFT) - Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_RIGHT)
	if mv == Vector2.ZERO and rot == Vector2.ZERO and absf(zoom) < 0.05: return
	mv = mv.limit_length(1.0)
	var right := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))       # en el suelo, según hacia dónde mira
	var fwd := Vector3(-sin(deg_to_rad(yaw)), 0, -cos(deg_to_rad(yaw)))
	pivot += (right * mv.x + fwd * mv.y) * view * 0.7 * dt
	pivot = _clamp_to_world(pivot)
	yaw = fmod(yaw - rot.x * 75.0 * dt, 360.0)
	pitch = clampf(pitch + rot.y * 45.0 * dt, PITCH_MIN, PITCH_MAX)
	view = clampf(view * exp(zoom * 1.1 * dt), SIZE_MIN, SIZE_MAX)
	_place()

static func _stick(dev: int, ax: JoyAxis, ay: JoyAxis) -> Vector2:
	var v := Vector2(Input.get_joy_axis(dev, ax), Input.get_joy_axis(dev, ay))
	return Vector2.ZERO if v.length() < 0.2 else v * ((v.length() - 0.2) / 0.8) / v.length()

func _clamp_to_world(p: Vector3) -> Vector3:
	var w: Variant = game.get("world")
	if w == null: return p
	var r: Rect2 = (w as CombatWorld).bounds
	return Vector3(clampf(p.x, r.position.x, r.end.x), 0.0, clampf(p.z, r.position.y, r.end.y))

# ------------------------------------------------------------------ opciones

func _apply_grade() -> void:
	if _env == null: return
	var g: Variant = _grades[grade][1]
	if g == null:
		_env.adjustment_enabled = _env_saved.on
		_env.adjustment_color_correction = _env_saved.cc
		_env.adjustment_saturation = _env_saved.sat
	else:
		Atmosphere.set_grade(_env, float(game.get("grade_gamma")), g)

## Enfoca el punto del suelo que se está mirando; lo de delante y lo de detrás se desenfoca.
func _apply_dof() -> void:
	if cam == null: return
	var a := cam.attributes as CameraAttributesPractical
	var on := dof > 0
	a.dof_blur_far_enabled = on
	a.dof_blur_near_enabled = on
	if not on: return
	var d: Array = DOF[dof]
	var focus := _distance()
	a.dof_blur_far_distance = focus + float(d[0])
	a.dof_blur_far_transition = float(d[1])
	a.dof_blur_near_distance = maxf(focus - float(d[0]), 0.1)
	a.dof_blur_near_transition = minf(float(d[1]), maxf(focus - float(d[0]) - 0.1, 0.1))
	a.dof_blur_amount = float(d[2])

func _apply_vignette() -> void:
	if _vig == null: return
	_vig.visible = vignette > 0
	(_vig.material as ShaderMaterial).set_shader_parameter("strength", [0.0, 0.45, 0.85][vignette])

## Investigadores sin los anillos (y el aro del abatido) o, con sus compañeros, ocultos, para
## fotografiar el escenario.
func _apply_hide() -> void:
	for q: Player in game.get("players"):
		for n: Variant in [q, q.pet]:
			if n is Node3D: (n as Node3D).visible = hide_players < 2
		for r: Variant in [q.get("_ring"), q.get("_down_ring")]:
			if r is Node3D:
				if hide_players >= 1 and (r as Node3D).visible:
					(r as Node3D).visible = false
					_hidden_3d.append(r)
				elif hide_players == 0 and _hidden_3d.has(r):
					(r as Node3D).visible = true
					_hidden_3d.erase(r)

# ------------------------------------------------------------------ interfaz

func _build_ui() -> void:
	_vig = ColorRect.new()                                 # la viñeta sale en la foto: va aparte del panel
	_vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://scripts/fx/photo_vignette.gdshader")
	_vig.material = sm
	add_child(_vig)
	_panel = PanelContainer.new()
	_panel.theme = MenuKit.theme()
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(560, 0)
	_panel.add_child(box)
	MenuKit.heading(box, "Modo foto", 36, ACCENT)
	var rows: Array[OptionRow] = []
	var gn: Array[String] = []
	for g in _grades: gn.append(String(g[0]))
	rows.append(OptionRow.new("Gradación", gn, grade, func(i: int) -> void: grade = i; _apply_grade(), Callable(), ACCENT))
	rows.append(OptionRow.new("Profundidad de campo", DOF_NAMES, dof, func(i: int) -> void: dof = i; _apply_dof(), Callable(), ACCENT))
	rows.append(OptionRow.new("Viñeta", VIGNETTE_NAMES, vignette, func(i: int) -> void: vignette = i; _apply_vignette(), Callable(), ACCENT))
	rows.append(OptionRow.new("Proyección", ["Isométrica", "Perspectiva"] as Array[String], 1 if persp else 0,
		func(i: int) -> void: persp = i == 1; _place(), Callable(), ACCENT))
	rows.append(OptionRow.new("Investigadores", ["A la vista", "Sin anillos", "Ocultos"] as Array[String], hide_players,
		func(i: int) -> void: hide_players = i; _apply_hide(), Callable(), ACCENT))
	rows.append(OptionRow.new("Volver a la vista del juego", [] as Array[String], 0, Callable(), _reset_view, ACCENT))
	rows.append(OptionRow.new("Abrir la carpeta de fotos", [] as Array[String], 0, Callable(),
		func() -> void: OS.shell_open(ProjectSettings.globalize_path(photo_dir())), ACCENT))
	for r in rows:
		r.focus_mode = Control.FOCUS_ALL
		box.add_child(r)
	_note = UiKit.label("", 16, ACCENT)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_note)
	_hint = UiKit.label("Mover: stick izq. / WASD  ·  Girar e inclinar: stick der. / Q-E, R-F\nAcercar: LT-RT / Z-X / rueda  ·  A / Espacio: foto  ·  Y / Tab: ocultar el panel\nB / Esc: a la pausa  ·  Start: a jugar", 15, UiKit.TEXT_DIM)
	box.add_child(_hint)
	MenuKit.dress(_panel, MenuKit.BRASS, Vector2(30, 22), 90.0)
	_panel.resized.connect(func() -> void: _panel.position = Vector2(40, get_viewport().get_visible_rect().size.y - _panel.size.y - 40))
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	add_child(_flash)
	rows[0].grab_focus.call_deferred()

func _reset_view() -> void:
	yaw = 45.0
	pitch = -30.0
	persp = false
	if _old_cam != null:
		view = _old_cam.size
		pivot = _ground_at_center(_old_cam)
	for r in _panel.find_children("*", "OptionRow", true, false):
		if (r as OptionRow).title == "Proyección": (r as OptionRow).index = 0; (r as OptionRow).step(0)
	_place()

func _input(event: InputEvent) -> void:
	if _busy: return
	var key := event as InputEventKey
	var joy := event as InputEventJoypadButton
	var mb := event as InputEventMouseButton
	if key != null and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_SPACE: _shoot(); get_viewport().set_input_as_handled()
			KEY_TAB: _toggle_panel(); get_viewport().set_input_as_handled()
			KEY_ESCAPE: back.emit(); get_viewport().set_input_as_handled()
	elif joy != null and joy.pressed and not JoypadInput.disabled():
		match joy.button_index:
			JOY_BUTTON_A: _shoot(); get_viewport().set_input_as_handled()
			JOY_BUTTON_Y: _toggle_panel(); get_viewport().set_input_as_handled()
			JOY_BUTTON_B: back.emit(); get_viewport().set_input_as_handled()
			JOY_BUTTON_START: close.emit(); get_viewport().set_input_as_handled()
	elif mb != null and mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		view = clampf(view * (0.9 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1), SIZE_MIN, SIZE_MAX)
		_place()
		get_viewport().set_input_as_handled()

func _toggle_panel() -> void:
	_panel.visible = not _panel.visible

# ------------------------------------------------------------------ la foto

## Carpeta de las fotos: Imágenes/Lovecraft Library (o `photo_dir=`).
func photo_dir() -> String:
	var la: LaunchArgs = game.get("args")
	if la != null and la.has("photo_dir"): return la.get_str("photo_dir")
	return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).path_join(DIR_NAME)

## Quita el panel, espera a que se dibuje sin él, guarda la imagen y lo vuelve a poner con un destello.
func _shoot() -> void:
	if _busy: return
	_busy = true
	var was := _panel.visible
	_panel.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := photo_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var fname := "lovecraft_%s.png" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := dir.path_join(fname)
	var err := img.save_png(path)
	_panel.visible = was
	_note.text = ("Foto guardada: %s" % fname) if err == OK else "No se ha podido guardar la foto (%s)" % error_string(err)
	if err == OK and game.get("args") != null and (game.get("args") as LaunchArgs).get_bool("log"): print("FOTO ", ProjectSettings.globalize_path(path))
	Auto.sfx("ui_accept")
	_flash.color.a = 0.55
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(_flash, "color:a", 0.0, 0.35)
	_busy = false

## photo_auto=true: captura del panel en shots/, una foto y sale (pruebas).
var _auto_stage := 0
func _auto_step(dt: float) -> void:
	_auto_t += dt
	if _auto_stage == 0 and _auto_t > 1.2:
		_auto_stage = 1
		await RenderingServer.frame_post_draw
		var tag := String(game.get("_shot_tag"))
		get_viewport().get_texture().get_image().save_png("res://shots/game%s_modo_foto.png" % tag)
	elif _auto_stage == 1 and _auto_t > 1.6:
		_auto_stage = 2
		_shoot()
	elif _auto_stage == 2 and _auto_t > 2.6:
		_auto_stage = 3
		game.get_tree().quit()
