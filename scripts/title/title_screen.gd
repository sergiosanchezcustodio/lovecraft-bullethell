extends Control
## Pantalla de título: la ilustración de la biblioteca (resources/PantallasMenus/) con
## animaciones sutiles y la entrada del título con su halo de niebla.
## Cada efecto se configura o se quita por separado en data/title/portada.tres
## (TitleScreenConfig). Para probar, detrás de `--`:
##   off=velas,niebla,nubes,luna,relampago,ojos,acercamiento,motas,titulo,halo,aviso
##   shots=2,6,9 tag=x   capturas en esos segundos     t=6   empieza en ese segundo
##   strike=3            relámpago en ese segundo      eyes=3  brillo de ojos en ese segundo
##   perf=8              mide el rendimiento
## Intro / Espacio / A / Start: salta la presentación y, con el aviso visible, entra en la partida.

const DESIGN := Vector2(1920, 1080)
const BG := "res://resources/PantallasMenus/fondo_titulo_sin_texto_1080p_definitivo.png"
const TITLE_TEX := "res://resources/PantallasMenus/Texto_titulo.png"
const LUCES := "res://resources/PantallasMenus/mascara_luces.png"
const ZONAS := "res://resources/PantallasMenus/mascara_zonas.png"
const FONT := "res://resources/fonts/IMFeENsc28P.ttf"
const TITLE_PAD := 0.06
const NEXT_SCENE := "res://scenes/game.tscn"

var cfg: TitleScreenConfig
var args: LaunchArgs
var stage: Control                ## ilustración y capas animadas (se acerca)
var front: Control                ## título y aviso (fijos)
var bg: TextureRect
var sky_mat: ShaderMaterial
var bg_mat: ShaderMaterial
var fog_mat: ShaderMaterial
var title: TextureRect
var title_mat: ShaderMaterial
var prompt: Label
var fade: ColorRect
var dust: GPUParticles2D
var t := 0.0
var _next_strike := 6.0
var _strike_t := -1.0
var _rng := RandomNumberGenerator.new()
var _done := false

func _ready() -> void:
	args = LaunchArgs.from_cmdline()
	cfg = (load("res://data/title/portada.tres") as TitleScreenConfig).duplicate()
	_apply_off(args.get_str("off"))
	UiInput.configure()
	_rng.randomize()
	_next_strike = _rng.randf_range(4.0, 7.0)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	_build_stage()
	_build_front()
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	get_viewport().size_changed.connect(_layout)
	_layout()
	t = args.get_float("t", 0.0)
	if args.has("shots"):
		var tag := ("_" + args.get_str("tag")) if args.has("tag") else ""
		add_child(ShotTaker.new(args.get_floats("shots"), "res://shots/titulo%s" % tag))

## off=niebla,motas… apaga esos efectos (para compararlos sin tocar la configuración).
func _apply_off(list: String) -> void:
	var names := {"velas": "candles_enabled", "niebla": "fog_enabled", "nubes": "clouds_enabled",
		"luna": "moon_enabled", "relampago": "lightning_enabled", "ojos": "eyes_enabled",
		"acercamiento": "zoom_enabled", "motas": "dust_enabled", "titulo": "title_enabled",
		"halo": "halo_enabled", "aviso": "prompt_enabled"}
	for n in list.split(",", false):
		if names.has(n): cfg.set(names[n], false)

func _full(c: Control) -> void:
	c.position = Vector2.ZERO
	c.size = DESIGN
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_stage() -> void:
	stage = Control.new()
	stage.size = DESIGN
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	var luces: Texture2D = load(LUCES)
	var zonas: Texture2D = load(ZONAS)
	bg = TextureRect.new()
	bg.texture = load(BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS     # 4K reducida sin aliasing
	_full(bg)
	bg_mat = ShaderMaterial.new()
	bg_mat.shader = preload("res://scripts/title/background.gdshader")
	bg_mat.set_shader_parameter("luces", luces)
	bg.material = bg_mat
	stage.add_child(bg)
	var fog := ColorRect.new()
	_full(fog)
	fog_mat = ShaderMaterial.new()
	fog_mat.shader = preload("res://scripts/title/floor_fog.gdshader")
	fog_mat.set_shader_parameter("zonas", zonas)
	fog.material = fog_mat
	stage.add_child(fog)
	var sky := ColorRect.new()
	_full(sky)
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = preload("res://scripts/title/window_sky.gdshader")
	sky_mat.set_shader_parameter("zonas", zonas)
	sky.material = sky_mat
	stage.add_child(sky)
	dust = _make_dust()
	stage.add_child(dust)
	_push_params()

## Motas de polvo en la luz de las velas de la izquierda.
func _make_dust() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	var area := cfg.dust_area
	p.position = (area.position + area.size * 0.5) * DESIGN
	p.amount = cfg.dust_amount
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.visibility_rect = Rect2(-area.size * DESIGN, area.size * DESIGN * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(area.size.x * DESIGN.x * 0.5, area.size.y * DESIGN.y * 0.5, 0)
	pm.direction = Vector3(0.3, -1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 7.0
	pm.gravity = Vector3(0, -1.5, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 2.0
	pm.turbulence_noise_scale = 3.0
	pm.scale_min = 0.08
	pm.scale_max = 0.22
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.8, 0.5, 0), Color(1, 0.8, 0.5, 0.7), Color(1, 0.75, 0.45, 0.5), Color(1, 0.7, 0.4, 0)])
	var rt := GradientTexture1D.new()
	rt.gradient = ramp
	pm.color_ramp = rt
	p.process_material = pm
	var dot := GradientTexture2D.new()
	dot.width = 32; dot.height = 32
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = g
	p.texture = dot
	var cm := CanvasItemMaterial.new()
	cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = cm
	p.emitting = cfg.dust_enabled
	p.visible = cfg.dust_enabled
	return p

func _build_front() -> void:
	front = Control.new()
	front.size = DESIGN
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(front)
	var tex: Texture2D = load(TITLE_TEX)
	title = TextureRect.new()
	title.texture = tex
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_SCALE
	title.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := cfg.title_width * DESIGN.x
	var h := w * tex.get_height() / tex.get_width()
	var full := Vector2(w, h) / (1.0 - 2.0 * TITLE_PAD)      # con margen para el halo
	title.size = full
	title.position = cfg.title_center * DESIGN - full * 0.5
	title_mat = ShaderMaterial.new()
	title_mat.shader = preload("res://scripts/title/title_halo.gdshader")
	title_mat.set_shader_parameter("pad", TITLE_PAD)
	title.material = title_mat
	title.visible = cfg.title_enabled
	front.add_child(title)
	prompt = Label.new()
	prompt.text = cfg.prompt_text
	var font := FontFile.new()
	font.load_dynamic_font(FONT)
	prompt.add_theme_font_override("font", font)
	prompt.add_theme_font_size_override("font_size", 40)
	prompt.add_theme_color_override("font_color", Color(0.93, 0.82, 0.58))
	prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	prompt.add_theme_constant_override("outline_size", 10)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.size = Vector2(DESIGN.x, 60)
	prompt.position = Vector2(0, cfg.prompt_y * DESIGN.y - 30)
	prompt.modulate.a = 0.0
	front.add_child(prompt)

## Parámetros de configuración -> shaders (se llama al crear y si cambia la configuración).
func _push_params() -> void:
	for pair in [["candles_enabled", "candles_enabled"], ["flicker_strength", "flicker_strength"],
			["flicker_speed", "flicker_speed"], ["flame_wobble", "flame_wobble"], ["spill_strength", "spill_strength"]]:
		bg_mat.set_shader_parameter(pair[1], cfg.get(pair[0]))
	fog_mat.set_shader_parameter("fog_strength", cfg.fog_strength if cfg.fog_enabled else 0.0)
	fog_mat.set_shader_parameter("fog_speed", cfg.fog_speed)
	fog_mat.set_shader_parameter("fog_color", cfg.fog_color)
	for n in ["clouds_enabled", "clouds_strength", "clouds_speed", "clouds_color", "moon_enabled", "moon_pos",
			"moon_radius", "moon_halo_strength", "moon_halo_period", "moon_color", "lightning_enabled",
			"eyes_enabled", "eye_left", "eye_right", "eyes_color"]:
		sky_mat.set_shader_parameter(n, cfg.get(n))

## Escenario y título cubren la pantalla conservando la proporción (se recorta lo que sobre).
func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var s := maxf(vs.x / DESIGN.x, vs.y / DESIGN.y)
	var offset := (vs - DESIGN * s) * 0.5
	for c: Control in [stage, front]:
		c.pivot_offset = (cfg.zoom_center * DESIGN) if c == stage else Vector2.ZERO
		c.position = offset - c.pivot_offset * (1.0 - s)
		c.scale = Vector2.ONE * s
	stage.set_meta("base_scale", s)

func _process(delta: float) -> void:
	t += delta
	# fundido desde negro
	fade.color.a = 1.0 - smoothstep(0.0, cfg.fade_in_time, t)
	# acercamiento lento durante la presentación
	if cfg.zoom_enabled:
		var z := cfg.zoom_amount * _ease_out(clampf(t / cfg.zoom_time, 0.0, 1.0))
		stage.scale = Vector2.ONE * float(stage.get_meta("base_scale")) * (1.0 + z)
	# título: primero la niebla, luego las letras
	var r := clampf((t - cfg.title_delay) / cfg.title_reveal_time, 0.0, 1.0)
	title_mat.set_shader_parameter("reveal", r)
	title_mat.set_shader_parameter("halo_enabled", cfg.halo_enabled)
	title_mat.set_shader_parameter("halo_radius", cfg.halo_radius)
	title_mat.set_shader_parameter("halo_strength", cfg.halo_strength)
	title_mat.set_shader_parameter("halo_color", cfg.halo_color)
	# aviso de pulsar, respirando despacio
	if cfg.prompt_enabled and t > cfg.prompt_delay:
		var k := clampf((t - cfg.prompt_delay) / 1.2, 0.0, 1.0)
		prompt.modulate.a = k * (0.62 + 0.38 * sin((t - cfg.prompt_delay) * 1.8))
	_lightning(delta)
	_eyes()
	if args.has("perf"): _perf(delta)

## Relámpago tenue y espaciado dentro del ventanal (nunca dos destellos fuertes seguidos).
func _lightning(delta: float) -> void:
	if not cfg.lightning_enabled:
		sky_mat.set_shader_parameter("flash", 0.0)
		return
	if args.has("strike") and t >= args.get_float("strike") and t - delta < args.get_float("strike"):
		_next_strike = 0.0
	_next_strike -= delta
	if _next_strike <= 0.0 and _strike_t < 0.0:
		_strike_t = 0.0
	var k := 0.0
	if _strike_t >= 0.0:
		_strike_t += delta
		var s := _strike_t
		if s < 0.05: k = s / 0.05
		elif s < 0.14: k = lerpf(1.0, 0.3, (s - 0.05) / 0.09)
		elif s < 0.2: k = lerpf(0.3, 0.6, (s - 0.14) / 0.06)
		elif s < 0.8: k = 0.6 * pow(1.0 - (s - 0.2) / 0.6, 2.0)
		else:
			_strike_t = -1.0
			_next_strike = _rng.randf_range(cfg.lightning_min_interval, cfg.lightning_max_interval)
	sky_mat.set_shader_parameter("flash", k * cfg.lightning_strength)

## Los ojos de Cthulhu se encienden despacio de vez en cuando (y con los relámpagos).
func _eyes() -> void:
	if not cfg.eyes_enabled:
		sky_mat.set_shader_parameter("eyes_glow", 0.0)
		return
	var start := args.get_float("eyes", 2.5)
	var c := fposmod(t - start, cfg.eyes_period)
	var g := 0.0
	if t >= start:
		if c < 1.4: g = smoothstep(0.0, 1.4, c)
		elif c < 2.4: g = 1.0
		elif c < 4.2: g = 1.0 - smoothstep(2.4, 4.2, c)
	g = maxf(g * 0.8, 0.12)                                  # nunca del todo apagados
	sky_mat.set_shader_parameter("eyes_glow", g * cfg.eyes_strength)

static func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = (event as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	elif event is InputEventJoypadButton and event.pressed:
		pressed = (event as InputEventJoypadButton).button_index in [JOY_BUTTON_A, JOY_BUTTON_START]
	if not pressed: return
	get_viewport().set_input_as_handled()
	var end_intro := maxf(cfg.prompt_delay, cfg.title_delay + cfg.title_reveal_time) + 0.01
	if t < end_intro:
		t = end_intro                                        # salta la presentación
	elif not _done:
		_done = true
		get_tree().change_scene_to_file(NEXT_SCENE)          # hasta que existan los menús

var _frames: Array[float] = []
func _perf(delta: float) -> void:
	if t < 2.0: return
	_frames.append(delta)
	if t > 2.0 + args.get_float("perf"):
		var avg := 0.0
		for f in _frames: avg += f
		avg /= _frames.size()
		print("TITULO media=%.2f ms (%.0f FPS)" % [avg * 1000.0, 1.0 / avg])
		get_tree().quit()
