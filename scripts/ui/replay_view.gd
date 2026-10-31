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
	var hint := UiKit.label("Los últimos %d segundos, a media velocidad  ·  A o B para volver" % roundi(frames.size() / DeathReplay.FPS),
		22, UiKit.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	get_viewport().gui_release_focus()             # A y B, para esta ventana y no para los botones de debajo
	Auto.sfx("page")

func _process(delta: float) -> void:
	var length := frames.size() / DeathReplay.FPS
	_t = fmod(_t + delta * SPEED, length + 1.0)    # un segundo quieto en la última antes de volver
	var i := mini(int(_t * DeathReplay.FPS), frames.size() - 1)
	_tex.update(frames[i])
	_bar.size.x = 1280.0 * float(i + 1) / frames.size()

func _unhandled_input(e: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if e.is_action_pressed("ui_cancel") or e.is_action_pressed("ui_accept"):
		queue_free()
