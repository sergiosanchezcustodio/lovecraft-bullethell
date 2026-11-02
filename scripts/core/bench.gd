extends Node3D
## Prueba de rendimiento: N modelos voxel animados en pantalla.
## Uso: godot --path . scenes/bench.tscn --disable-vsync --resolution 1920x1080 -- count=150 model=acechador secs=10
## Opciones: count, model (lista separada por comas), secs, warmup, anim (true/false), shot (true/false)
## Hito 16.3: `mode=mm` dibuja cada tipo con un MultiMesh y las poses grabadas (HordeMesh);
## `move=true` los hace andar en círculo (como los enemigos, que se mueven en cada fotograma) y
## `pose_hz=30` posa los de nodos a ese ritmo, desfasados (como la partida con más de 50).

var models: Array[Node3D] = []
var model_names: Array[String] = []
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
var _mm := false
var _move := false
var _pose_hz := 0.0
var _home: Array[Vector3] = []
var _phase: Array[float] = []
var _holders: Array[Node3D] = []
var _acc: Array[float] = []
var _types := {}                       # modelo -> {horde, layer, idx: Array[int]}
var _slots: Array = []                 # la plaza de cada uno en su capa (como Enemy.horde_cell/slot)

class Slot:
	var horde_cell := Vector2i.ZERO
	var horde_slot := -1

func _ready() -> void:
	args = LaunchArgs.from_cmdline()
	var count := args.get_int("count", 150)
	var names := args.get_str("model", "acechador").split(",")
	_warmup = args.get_float("warmup", 2.0)
	_secs = args.get_float("secs", 10.0)
	_animate = args.get_bool("anim", true)
	_mm = args.get_str("mode", "nodes") == "mm"
	_move = args.get_bool("move", false)
	_pose_hz = args.get_float("pose_hz", 0.0)
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
	if _mm:
		for n: String in names:
			var t0 := Time.get_ticks_usec()
			var h := HordeMesh.get_type(n)
			var c := 0
			for i in count: if names[i % names.size()] == n: c += 1
			_types[n] = {"horde": h, "layer": HordeMesh.Layer.new(h, self), "idx": []}
			print("grabado de %s: %.0f ms" % [n, (Time.get_ticks_usec() - t0) / 1000.0])
	for i in count:
		var n: String = names[i % names.size()]
		var home := Vector3((i % cols - (cols - 1) * 0.5) * spacing, 0, (i / cols - (rows - 1) * 0.5) * spacing)
		_home.append(home)
		_phase.append(randf())
		_acc.append(randf())
		model_names.append(n)
		_slots.append(Slot.new())
		if _mm:
			(_types[n].idx as Array).append(i)
			continue
		var m := VoxelBuilder.load_model("res://models/%s.json" % n)
		var holder := Node3D.new()   # el giro y la posición van en el contenedor; Anims toca el modelo
		holder.position = home
		holder.rotation.y = randf() * TAU
		holder.add_child(m)
		m.set_meta("phase", _phase[i])
		add_child(holder)
		models.append(m)
		_holders.append(holder)
	# Suelo, luces y cámara isométrica que encuadra toda la rejilla
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(cols * spacing + 6, rows * spacing + 6); floor_mi.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.08, 0.1, 0.1); floor_mi.material_override = fm
	add_child(floor_mi)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, 20, 0); moon.light_color = Color(0.6, 0.72, 0.85)
	moon.light_energy = 0.45; moon.shadow_enabled = args.get_bool("shadows", true)
	add_child(moon)
	for k in 6:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(randf_range(-cols, cols) * spacing * 0.5, 1.6, randf_range(-rows, rows) * spacing * 0.5)
		lamp.light_color = Color(1.0, 0.72, 0.4); lamp.light_energy = 1.8; lamp.omni_range = 6.0
		lamp.shadow_enabled = k < 2 and args.get_bool("shadows", true)
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
	var tp := Time.get_ticks_usec()
	if _mm: _update_mm()
	elif _animate:
		for i in models.size():
			var n := model_names[i]
			if _move:
				var a := _t * 0.8 + _phase[i] * TAU
				_holders[i].position = _home[i] + Vector3(cos(a), 0, sin(a)) * 0.5
				_holders[i].rotation.y = -a
			if _pose_hz > 0.0:
				_acc[i] += delta
				if _acc[i] < 1.0 / _pose_hz: continue
				_acc[i] = fmod(_acc[i], 1.0 / _pose_hz)
			var ph := fposmod(_t / Anims.duration(n, "walk") + float(models[i].get_meta("phase")), 1.0)
			Anims.pose(n, "walk", models[i], ph)
	if _t > _warmup: _script_usec += Time.get_ticks_usec() - tp
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

var _script_usec := 0

## Hito 16.3: un búfer por tipo (transformación y fila de la pose de cada uno), de una vez.
func _update_mm() -> void:
	for n: String in _types:
		var ty: Dictionary = _types[n]
		var h: HordeMesh = ty.horde
		var layer: HordeMesh.Layer = ty.layer
		var dur := h.duration("walk")
		for i: int in ty.idx:
			var pos := _home[i]
			var yaw := 0.0
			if _move:
				var a := _t * 0.8 + _phase[i] * TAU
				pos += Vector3(cos(a), 0, sin(a)) * 0.5
				yaw = -a
			layer.place(_slots[i], Transform3D(Basis(Vector3.UP, yaw), pos), Color(h.row("walk", fposmod(_t / dur + _phase[i], 1.0)) if _animate else 0, 0, 0, 0))
		layer.flush()

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
	print("RESULTADO script (pose o búfer) %.3f ms por fotograma" % (_script_usec / 1000.0 / n))
