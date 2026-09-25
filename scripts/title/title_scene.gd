extends Node3D
## Portada de "Lovecraft Library: Surviving Cthulhu" (D-21, GDD 7.1). Escena 3D en tiempo
## real, sin los límites de rendimiento de la partida: cámara en perspectiva, niebla
## volumétrica, iluminación global, reflejos en el hielo, tormenta con relámpagos entre
## las montañas y nieve. Todo se mueve poco: la portada da sensación de vida sin disputar
## la atención.
## Opciones (detrás de `--`): quality=low, shots=..., tag=..., strike=2.5 (fuerza un
## relámpago en ese segundo, para capturas), nolightning=true.

var args: LaunchArgs
var env: Environment
var camera: Camera3D
var sky_mat: ShaderMaterial
var lightning: TitleLightning
var storm_light: DirectionalLight3D
var bolt_light: OmniLight3D
var _t := 0.0
# Encuadre: el título ocupa la franja superior (cielo); debajo, Cthulhu en el collado;
# el lago en el centro y el campamento abajo a la izquierda.
var _cam_base := Vector3(0.0, 6.0, 32.0)
var _cam_target := Vector3(0.0, 17.0, -150.0)
var _high := true

func _ready() -> void:
	args = LaunchArgs.from_cmdline()
	_high = args.get_str("quality", "high") != "low"
	_make_environment()
	_make_lights()
	_make_terrain()
	_make_camp()
	_make_placeholders()
	_make_snow()
	if _high: _make_mist()
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.near = 0.2
	camera.far = 1200.0
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera)
	_place_camera(0.0)
	lightning = TitleLightning.new()
	lightning.camera = camera
	lightning.strength = 0.0 if args.get_bool("nolightning") else 1.0
	lightning.flashed.connect(_on_flash)
	add_child(lightning)
	if args.has("shots"):
		var tag := ("_" + args.get_str("tag")) if args.has("tag") else ""
		add_child(ShotTaker.new(args.get_floats("shots"), "res://shots/portada%s" % tag))

# ---------------- entorno ----------------
func _make_environment() -> void:
	env = Environment.new()
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = preload("res://scripts/title/storm_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Luz ambiental de color fijo: si saliera del cielo, cada relámpago iluminaría el valle
	# entero como si fuera de día.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.38, 0.5)
	env.ambient_light_energy = 0.55
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.35
	env.glow_enabled = true
	env.glow_intensity = 0.7
	# Sin bloom general: el halo convertía cada copo de nieve en una bola borrosa. Solo
	# brillan de verdad los ojos, el farol y los relámpagos (por encima del umbral).
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	# Niebla de profundidad (perspectiva aérea hasta las montañas del fondo)
	env.fog_enabled = true
	env.fog_light_color = Color(0.13, 0.17, 0.22)
	env.fog_density = 0.0016
	env.fog_sky_affect = 0.25
	env.fog_height = 30.0
	env.fog_height_density = 0.01
	if _high:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0035
		env.volumetric_fog_albedo = Color(0.75, 0.8, 0.88)
		env.volumetric_fog_length = 140.0
		env.volumetric_fog_detail_spread = 1.5
		env.volumetric_fog_ambient_inject = 0.35
		env.ssr_enabled = true                         # reflejos en el lago helado
		env.ssr_max_steps = 96
		env.ssr_fade_in = 0.1
		env.ssr_depth_tolerance = 0.4
		env.ssao_enabled = true
		env.ssao_intensity = 1.6
		env.sdfgi_enabled = true                       # iluminación global (rebote del farol)
		env.sdfgi_use_occlusion = true
		env.sdfgi_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	if _high:
		var cam_attr := CameraAttributesPractical.new()
		cam_attr.dof_blur_far_enabled = true
		cam_attr.dof_blur_far_distance = 180.0
		cam_attr.dof_blur_far_transition = 120.0
		cam_attr.dof_blur_amount = 0.05
		we.camera_attributes = cam_attr
	add_child(we)

func _make_lights() -> void:
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	moon.rotation_degrees = Vector3(-22, -70, 0)             # luna baja desde la izquierda: rasante, modela las crestas
	moon.light_color = Color(0.62, 0.72, 0.9)
	moon.light_energy = 0.8
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 400.0
	moon.light_volumetric_fog_energy = 1.2
	add_child(moon)
	# Contraluz de la tormenta: desde detrás de las montañas hacia la cámara; se enciende
	# con cada relámpago y recorta las crestas (y la silueta de Cthulhu)
	storm_light = DirectionalLight3D.new()
	storm_light.name = "StormLight"
	storm_light.rotation_degrees = Vector3(-5, 8, 0)             # rasante: recorta, no ilumina el suelo
	storm_light.light_color = Color(0.7, 0.8, 1.0)
	storm_light.light_energy = 0.0
	storm_light.shadow_enabled = _high
	storm_light.light_volumetric_fog_energy = 3.0
	add_child(storm_light)
	bolt_light = OmniLight3D.new()
	bolt_light.light_color = Color(0.72, 0.82, 1.0)
	bolt_light.omni_range = 260.0
	bolt_light.omni_attenuation = 1.2
	bolt_light.light_energy = 0.0
	bolt_light.light_volumetric_fog_energy = 4.0
	add_child(bolt_light)

func _on_flash(k: float, at: Vector3) -> void:
	sky_mat.set_shader_parameter("flash", k * 0.7)
	if k > 0.0:
		sky_mat.set_shader_parameter("flash_dir", (at + Vector3(0, 60, 0) - _cam_base).normalized())
	storm_light.light_energy = 0.9 * k
	bolt_light.position = at + Vector3(0, 40, 30)
	bolt_light.light_energy = 5.0 * k

# ---------------- terreno y atrezo ----------------
func _prop(model: String, pos: Vector3, rot_y: float = 0.0, scale: float = 1.0) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees.y = rot_y
	holder.scale = Vector3.ONE * scale
	holder.add_child(VoxelBuilder.load_model("res://models/%s.json" % model))
	add_child(holder)
	return holder

func _make_terrain() -> void:
	for m in ["portada_cordillera", "portada_colinas", "portada_llanura", "portada_primer_termino", "portada_lago"]:
		_prop(m, Vector3.ZERO)

## Restos del campamento en primer término: la tienda, cajas, el farol encendido (la única
## luz cálida, que contrasta con el azul de la tormenta).
func _make_camp() -> void:
	_prop("atrezo_tienda", Vector3(-15.0, 0.0, -6.0), 30)
	_prop("atrezo_caja", Vector3(-11.2, 0.0, -2.4), 20)
	_prop("atrezo_caja", Vector3(-10.6, 0.0, -1.6), 55)
	_prop("atrezo_bidon", Vector3(-12.2, 0.0, -0.9))
	var farol := _prop("atrezo_farol", Vector3(-8.8, 0.0, 0.2), 200)
	var lamp := OmniLight3D.new()
	var m: Node3D = farol.get_child(0)
	var pv: Array = m.get_meta("pivots")["light"]
	lamp.position = Vector3(pv[0], pv[1], pv[2]) * float(m.get_meta("voxel_size"))
	lamp.light_color = Color(1.0, 0.66, 0.34)
	lamp.light_energy = 3.2
	lamp.omni_range = 14.0
	lamp.shadow_enabled = true
	lamp.light_volumetric_fog_energy = 2.0
	lamp.set_meta("flicker", true)
	farol.add_child(lamp)
	_lamp = lamp
	_prop("atrezo_roca", Vector3(19.0, 0.0, -3.0), 40, 1.8)
	_prop("atrezo_roca", Vector3(24.0, 0.0, -9.0), 10, 2.4)
	_prop("atrezo_bloques_hielo", Vector3(13.5, 0.0, 1.0), -25, 1.1)

var _lamp: OmniLight3D

## Marcadores provisionales (P.1) para juzgar la composición: las criaturas de verdad
## llegan en P.2. Cthulhu tras el collado; tres criaturas grandes en el término medio.
func _make_placeholders() -> void:
	if args.get_bool("noplaceholders"): return
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.02, 0.03, 0.03)
	dark.roughness = 0.9
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new(); cap.radius = 28.0; cap.height = 110.0
	body.mesh = cap
	body.material_override = dark
	body.position = Vector3(4, 8, -265)
	add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new(); sph.radius = 20.0; sph.height = 40.0
	head.mesh = sph
	head.material_override = dark
	head.position = Vector3(4, 68, -262)
	add_child(head)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_mat.albedo_color = Color(0.9, 0.35, 0.15)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.4, 0.15)
	eye_mat.emission_energy_multiplier = 3.0
	for sx in [-9.0, 9.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new(); es.radius = 2.4; es.height = 4.8
		eye.mesh = es
		eye.material_override = eye_mat
		eye.position = Vector3(4 + sx * 0.7, 70, -243)
		add_child(eye)
	_prop("acechador", Vector3(-15.0, 0.0, -4.0), 30, 3.2)
	_prop("fragmento", Vector3(17.0, 0.0, -9.0), -40, 3.6)
	_prop("pinguino", Vector3(5.0, 1.5, -38.0), 10, 4.0)

func _make_snow() -> void:
	var p := GPUParticles3D.new()
	p.amount = 1100 if _high else 400
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.visibility_aabb = AABB(Vector3(-60, -30, -60), Vector3(120, 60, 90))
	p.position = Vector3(0, 16, -18)                        # a más de 20 m: sin copos gigantes
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(40, 8, 16)
	pm.direction = Vector3(0.35, -1, 0.1)
	pm.spread = 12.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 3.4
	pm.gravity = Vector3(0.4, -0.6, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.2
	pm.turbulence_noise_scale = 6.0
	pm.scale_min = 0.05
	pm.scale_max = 0.1
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true        # sin esto se descarta la escala: todos los copos medían 1 m
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.5, 0.56, 0.66, 0.75)
	var disc := GradientTexture2D.new()                      # copo redondo y difuminado
	disc.fill = GradientTexture2D.FILL_RADIAL
	disc.fill_from = Vector2(0.5, 0.5)
	disc.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	disc.gradient = g
	m.albedo_texture = disc
	quad.material = m
	p.draw_pass_1 = quad
	add_child(p)

## Bancos de niebla que derivan por el valle, entre el lago y las colinas.
func _make_mist() -> void:
	var fv := FogVolume.new()
	fv.size = Vector3(220, 14, 120)
	fv.position = Vector3(0, 3, -55)
	fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://scripts/title/mist.gdshader")
	fm.set_shader_parameter("density", 0.4)
	fv.material = fm
	add_child(fv)

# ---------------- animación ----------------
func _place_camera(t: float) -> void:
	# Vaivén muy lento y un leve avance: la vista respira sin marear
	var sway := Vector3(sin(t * 0.07) * 1.4, sin(t * 0.05) * 0.35, -sin(t * 0.035) * 1.2)
	camera.position = _cam_base + sway
	camera.look_at(_cam_target + Vector3(sway.x * 3.0, 0, 0), Vector3.UP)

var _fps_frames: Array[float] = []

func _process(delta: float) -> void:
	_t += delta
	if args.has("perf") and _t > 3.0:
		_fps_frames.append(delta)
		if _t > 3.0 + args.get_float("perf"):
			var avg := 0.0
			for f in _fps_frames: avg += f
			avg /= _fps_frames.size()
			_fps_frames.sort()
			print("PORTADA calidad=%s media=%.2f ms (%.0f FPS) 1%% peor=%.2f ms" % [args.get_str("quality", "high"), avg * 1000.0, 1.0 / avg, _fps_frames[int(_fps_frames.size() * 0.99)] * 1000.0])
			get_tree().quit()
	_place_camera(_t)
	if _lamp != null:                                         # la llama del farol titila
		_lamp.light_energy = 3.0 + sin(_t * 7.3) * 0.18 + sin(_t * 12.9 + 1.3) * 0.12
	if args.has("strike") and _t >= args.get_float("strike") and _t - delta < args.get_float("strike"):
		lightning.strike_now()
