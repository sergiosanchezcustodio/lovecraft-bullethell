extends Node3D

var model: Node3D
var t := 0.0
var frame := 0
@export var out_prefix := "res://shots/f"
var mode := "still"   # still | anim
var yaw := 0.0
var mname := "clasico"
var anim_kind := "walk"
var nframes := 24

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: mode = args[0]
	if args.size() > 1: yaw = float(args[1])
	if args.size() > 2: mname = args[2]
	if args.size() > 3: anim_kind = args[3]
	if anim_kind == "pounce": nframes = 36
	if anim_kind == "idle": nframes = 32
	# Entorno
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.45)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.09, 0.09)
	env.fog_density = 0.04
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	# Cámara isométrica ortográfica
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.3
	cam.rotation_degrees = Vector3(-30, 45, 0)
	cam.position = Vector3(6, 6.0, 6) + Vector3(0, 1.0, 0)
	cam.position = Vector3(0, 0.62, 0) + cam.transform.basis.z * 10.0
	add_child(cam)
	# Luz principal fría (luna) + luz cálida (farol) + contraluz verdosa
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, 20, 0)
	moon.light_color = Color(0.6, 0.72, 0.85); moon.light_energy = 0.45
	moon.shadow_enabled = true
	add_child(moon)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(1.4, 1.6, 1.6); lamp.light_color = Color(1.0, 0.72, 0.4)
	lamp.light_energy = 1.8; lamp.omni_range = 5.0; lamp.shadow_enabled = true
	add_child(lamp)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.2, 2.2, -1.5); rim.light_color = Color(0.4, 0.95, 0.75)
	rim.light_energy = 1.2; rim.omni_range = 4.0
	add_child(rim)
	# Suelo: losas húmedas voxel
	_floor()
	if mname == "lineup":
		cam.size = 5.2
		cam.position = Vector3(0, 0.75, 0) + cam.transform.basis.z * 10.0
		var names := ["clasico", "bruto", "acechador", "abisal"]
		var right := cam.transform.basis.x
		for i in names.size():
			var m := VoxelBuilder.load_model("res://models/%s.json" % names[i])
			m.position = right * ((i - 1.5) * 1.25)
			m.rotation_degrees.y = yaw
			add_child(m)
			if i == 0: model = m
		var l2 := OmniLight3D.new(); l2.position = Vector3(-1.6, 1.6, 1.8); l2.light_color = Color(1.0, 0.72, 0.4)
		l2.light_energy = 1.6; l2.omni_range = 5.0; add_child(l2)
	else:
		if mname.begins_with("acechador"):
			cam.size = 2.35
			cam.position = Vector3(0, 0.5, 0.15) + cam.transform.basis.z * 10.0
		model = VoxelBuilder.load_model("res://models/%s.json" % mname)
		model.rotation_degrees.y = yaw
		add_child(model)

func _floor() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true; mat.roughness = 0.3
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tile := 0.5
	for i in range(-9, 9):
		for j in range(-9, 9):
			var h := rng.randf_range(-0.03, 0.0)
			var g := rng.randf_range(0.09, 0.15)
			var c := Color(g * 0.8, g, g * 0.95)
			if rng.randf() < 0.15: c = Color(0.1, 0.16, 0.12)  # musgo
			var bx := BoxMesh.new()
			var x0 := i * tile + 0.01; var z0 := j * tile + 0.01; var s := tile - 0.02
			var y1 := h
			var q := [Vector3(x0,y1,z0),Vector3(x0,y1,z0+s),Vector3(x0+s,y1,z0+s),Vector3(x0+s,y1,z0)]
			for k in [0,2,1,0,3,2]:
				st.set_normal(Vector3.UP); st.set_color(c); st.add_vertex(q[k])
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = mat
	add_child(mi)

func _process(delta: float) -> void:
	frame += 1
	if mode == "anim":
		t = (frame - 5) / float(nframes)
		if anim_kind == "idle": _idle(t)
		elif anim_kind == "pounce": _pounce(t)
		else: _animate(t)
		if frame >= 5 and frame < 5 + nframes:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://shots/%s_%s_%03d.png" % [mname, anim_kind, frame - 5])
		elif frame >= 5 + nframes:
			get_tree().quit()
	else:
		if frame == 8:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://shots/%s_%d.png" % [mname, int(yaw)])
			get_tree().quit()

func _animate(time: float) -> void:
	# Ciclo de caminar encorvado y torpe (1 s)
	var w := time * TAU
	model.get_node("leg_l").rotation.x = sin(w) * 0.5
	model.get_node("leg_r").rotation.x = -sin(w) * 0.5
	model.get_node("arm_l").rotation.x = -sin(w) * 0.35
	model.get_node("arm_r").rotation.x = sin(w) * 0.35
	model.get_node("torso").rotation.z = sin(w) * 0.06
	model.get_node("head").rotation.z = sin(w) * 0.08
	model.get_node("head").rotation.x = sin(w * 2.0) * 0.05
	model.position.y = abs(sin(w)) * 0.03

func _n(n: String) -> Node3D: return model.get_node(n)

func _idle(t: float) -> void:
	# Al acecho: respiración, la cabeza vigila a izquierda y derecha
	var w := t * TAU
	_n("torso").scale = Vector3(1.0 + sin(w * 2.0) * 0.012, 1.0 + sin(w * 2.0) * 0.025, 1.0)
	_n("head").rotation = Vector3(sin(w * 2.0) * 0.03, sin(w) * 0.28, sin(w) * 0.05)
	_n("head").position.y = _p("head").y + sin(w * 2.0) * 0.008
	_n("arm_l").rotation.x = sin(w * 2.0) * 0.03
	_n("arm_r").rotation.x = sin(w * 2.0 + 0.8) * 0.03

func _p(n: String) -> Vector3:
	var a: Array = model.get_meta("pivots")[n]
	return Vector3(a[0], a[1], a[2]) * VoxelBuilder.VOXEL

func _ease(x: float) -> float: return x * x * (3.0 - 2.0 * x)

func _pounce(t: float) -> void:
	# 0-0.35 se agazapa | 0.35-0.62 salta al frente | 0.62-0.8 aterriza | 0.8-1 vuelve a posición
	var crouch := 0.0; var air := 0.0; var fwd := 0.0; var reach := 0.0
	if t < 0.35:
		crouch = _ease(t / 0.35)
	elif t < 0.62:
		var u := (t - 0.35) / 0.27
		crouch = 1.0 - _ease(min(1.0, u * 3.0)); air = sin(u * PI); fwd = u; reach = sin(u * PI)
	elif t < 0.8:
		var u := (t - 0.62) / 0.18
		fwd = 1.0; crouch = sin(u * PI) * 0.6
	else:
		var u := _ease((t - 0.8) / 0.2)
		fwd = 1.0 - u
	var facing := model.transform.basis.z
	model.position = facing * fwd * 0.3 + Vector3(0, air * 0.2 - crouch * 0.05, 0)
	model.rotation.x = -reach * 0.25 + crouch * 0.12
	_n("head").rotation.x = crouch * 0.25 - reach * 0.35
	_n("arm_l").rotation.x = -reach * 1.1 + crouch * 0.2
	_n("arm_r").rotation.x = -reach * 1.1 + crouch * 0.2
	_n("leg_l").rotation.x = reach * 0.9 - crouch * 0.25
	_n("leg_r").rotation.x = reach * 0.9 - crouch * 0.25
