class_name ReplayView
extends CanvasLayer
## «Ver la caída» (hito 15.1): las imágenes de `DeathReplay` a media velocidad, en bucle, sobre la
## pantalla final, con una barra de tiempo. A o B la cierran (como `DiaryPage`).

const SPEED := 0.5                             ## media velocidad: 5 s se ven en 10

var frames: Array[Image] = []
var _tex: ImageTexture
var _rect: TextureRect
var _bar: ColorRect
var _t := 0.0
var _hint: Label
var _task := -1                                ## guardando el GIF (WorkerThreadPool)
var _gif_path := ""
var _gif_ok := false

func _init(p_frames: Array[Image]) -> void:
	frames = p_frames
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.92)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	MenuKit.heading(box, "La caída", 44, Color(0.86, 0.22, 0.18))
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MenuKit.dress(frame)
	box.add_child(frame)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	frame.add_child(inner)
	_tex = ImageTexture.create_from_image(frames[0])
	_rect = TextureRect.new()
	_rect.texture = _tex
	_rect.custom_minimum_size = Vector2(1280, 720)
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inner.add_child(_rect)
	var track := ColorRect.new()
	track.color = Color(0.2, 0.15, 0.1)
	track.custom_minimum_size = Vector2(1280, 6)
	inner.add_child(track)
	_bar = ColorRect.new()
	_bar.color = UiKit.GOLD
	_bar.size = Vector2(0, 6)
	track.add_child(_bar)
	_hint = UiKit.label(_hint_text(), 22, UiKit.TEXT_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hint)
	get_viewport().gui_release_focus()             # A y B, para esta ventana y no para los botones de debajo
	Auto.sfx("page")
	if LaunchArgs.from_cmdline().get_bool("replay_gif"): save_gif.call_deferred()   # pruebas

func _hint_text() -> String:
	return "Los últimos %d segundos, a media velocidad  ·  Y o G: guardar como GIF  ·  A o B para volver" % roundi(frames.size() / DeathReplay.FPS)

## Carpeta de las fotos (la del modo foto): Imágenes/Lovecraft Library, o `photo_dir=`.
static func gif_dir() -> String:
	var la := LaunchArgs.from_cmdline()
	if la.has("photo_dir"): return la.get_str("photo_dir")
	return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).path_join(PhotoMode.DIR_NAME)

## Guarda la repetición como GIF (a velocidad real) en un hilo, para compartirla.
func save_gif() -> void:
	if _task >= 0: return
	var dir := gif_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	_gif_path = dir.path_join("caida_%s.gif" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_"))
	_hint.text = "Guardando el GIF…"
	var fr := frames
	var path := _gif_path
	_task = WorkerThreadPool.add_task(func() -> void:
		var bytes := GifWriter.encode(fr, roundi(100.0 / DeathReplay.FPS))
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_buffer(bytes)
			f.close()
		_gif_ok = f != null)

## Abre la carpeta donde quedó el GIF (como «Abrir la carpeta» del modo foto).
func open_folder() -> void:
	if _gif_path != "" and not LaunchArgs.from_cmdline().get_bool("halt_shots"):   # en pruebas, no
		OS.shell_open(_gif_path.get_base_dir())

func _process(delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_hint.text = ("Guardado: %s  ·  X o F: abrir la carpeta  ·  A o B para volver" % _gif_path.get_file()) if _gif_ok else "No se pudo guardar el GIF  ·  A o B para volver"
		Auto.sfx("page")
		print("GIF de la caída: ", _gif_path if _gif_ok else "error")
	var length := frames.size() / DeathReplay.FPS
	_t = fmod(_t + delta * SPEED, length + 1.0)    # un segundo quieto en la última antes de volver
	var i := mini(int(_t * DeathReplay.FPS), frames.size() - 1)
	_tex.update(frames[i])
	_bar.size.x = 1280.0 * float(i + 1) / frames.size()

func _unhandled_input(e: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if (e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_G) 			or (e is InputEventJoypadButton and e.pressed and (e as InputEventJoypadButton).button_index == JOY_BUTTON_Y):
		save_gif()
	elif _gif_ok and ((e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_F) 			or (e is InputEventJoypadButton and e.pressed and (e as InputEventJoypadButton).button_index == JOY_BUTTON_X)):
		open_folder()
	elif e.is_action_pressed("ui_cancel") or e.is_action_pressed("ui_accept"):
		queue_free()

func _exit_tree() -> void:
	if _task >= 0: WorkerThreadPool.wait_for_task_completion(_task)   # no dejar el hilo a medias
