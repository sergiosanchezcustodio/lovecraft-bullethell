extends Node3D
## Prueba de rendimiento: N modelos voxel animados en pantalla.
## Uso: godot --path . scenes/bench.tscn --disable-vsync --resolution 1920x1080 -- count=150 model=acechador secs=10
## Opciones: count, model (lista separada por comas), secs, warmup, anim (true/false), shot (true/false)

var models: Array[Node3D] = []
var args: LaunchArgs
var _t := 0.0
var _frames_usec: Array[int] = []
var _gpu_ms: Array[float] = []
var _cpu_ms: Array[float] = []
var _last_usec := 0
var _warmup := 2.0
var _secs := 10.0
var _animate := true
var _vp: RID
var _draw_calls := 0
var _primitives := 0

func _ready() -> void:
	args = LaunchArgs.from_cmdline()
	var count := args.get_int("count", 150)
	var names := args.get_str("model", "acechador").split(",")
	_warmup = args.get_float("warmup", 2.0)
	_secs = args.get_float("secs", 10.0)
	_animate = args.get_bool("anim", true)
	var we := WorldEnvironment.new(); we.environment = Atmosphere.make_environment(); add_child(we)
	# Construcción de mallas (primera carga de cada modelo)
	for n: String in names:
		var t0 := Time.get_ticks_usec()
		VoxelBuilder.load_model("res://models/%s.json" % n).free()
		print("construcción de %s: %.0f ms" % [n, (Time.get_ticks_usec() - t0) / 1000.0])
	# Rejilla de modelos
	var cols := int(ceil(sqrt(count * 1.6)))
	var spacing := 1.7
	var rows := int(ceil(count / float(cols)))
	for i in count:
		var m := VoxelBuilder.load_model("res://models/%s.json" % names[i % names.size()])
		m.position = Vector3((i % cols - (cols - 1) * 0.5) * spacing, 0, (i / cols - (rows - 1) * 0.5) * spacing)
		m.rotation.y = randf() * TAU
		m.set_meta("phase", randf())
		add_child(m)
		models.append(m)
	# Suelo, luces y cámara isométrica que encuadra toda la rejilla
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(cols * spacing + 6, rows * spacing + 6); floor_mi.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.08, 0.1, 0.1); floor_mi.material_override = fm
	add_child(floor_mi)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, 20, 0); moon.light_color = Color(0.6, 0.72, 0.85)
	moon.light_energy = 0.45; moon.shadow_enabled = true
	add_child(moon)
	for k in 6:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(randf_range(-cols, cols) * spacing * 0.5, 1.6, randf_range(-rows, rows) * spacing * 0.5)
		lamp.light_color = Color(1.0, 0.72, 0.4); lamp.light_energy = 1.8; lamp.omni_range = 6.0
		lamp.shadow_enabled = k < 2
		add_child(lamp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = Vector3(-30, 45, 0)
	cam.size = max(cols, rows) * spacing * 0.75
	cam.position = cam.transform.basis.z * 60.0
	cam.far = 200.0
	add_child(cam)
	_vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)
	print("modelos: %d  renderizador: %s  resolución: %s" % [count, RenderingServer.get_current_rendering_method(), get_viewport().get_visible_rect().size])

func _process(delta: float) -> void:
	_t += delta
	if _animate:
		for m in models:
			var w: float = (_t + float(m.get_meta("phase"))) * TAU
			m.get_node("head").rotation.y = sin(w * 0.5) * 0.3
			m.get_node("arm_l").rotation.x = sin(w) * 0.2
			m.get_node("arm_r").rotation.x = -sin(w) * 0.2
			m.get_node("leg_l").rotation.x = -sin(w) * 0.2
			m.get_node("leg_r").rotation.x = sin(w) * 0.2
	var now := Time.get_ticks_usec()
	if _t > _warmup and _last_usec > 0:
		_frames_usec.append(now - _last_usec)
		_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(_vp))
		_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(_vp) + RenderingServer.get_frame_setup_time_cpu())
		_draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		_primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	_last_usec = now
	if _t > _warmup + _secs:
		_report()
		if args.get_bool("shot", false):
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://shots/bench_%s.png" % RenderingServer.get_current_rendering_method())
		get_tree().quit()
		set_process(false)

func _report() -> void:
	var ft: Array[int] = _frames_usec.duplicate()
	ft.sort()
	var n := ft.size()
	var total := 0
	for f in ft: total += f
	var avg_ms := total / float(n) / 1000.0
	var p99_ms := ft[int(n * 0.99)] / 1000.0
	var gpu := 0.0
	for g in _gpu_ms: gpu += g
	var cpu := 0.0
	for c in _cpu_ms: cpu += c
	print("RESULTADO fotogramas=%d  media=%.2f ms (%.0f FPS)  1%% peor=%.2f ms (%.0f FPS)  máx=%.2f ms  GPU=%.2f ms  CPU render=%.2f ms  draw calls=%d  primitivas=%d" % [
		n, avg_ms, 1000.0 / avg_ms, p99_ms, 1000.0 / p99_ms, ft[n - 1] / 1000.0,
		gpu / _gpu_ms.size(), cpu / _cpu_ms.size(), _draw_calls, _primitives])
