extends Node3D
## Visor de modelos: capturas fijas y fotogramas de animación.
##   godot --path . -- still <yaw> <modelos> [opciones]
##   godot --path . -- anim <yaw> <modelos> <animación> [opciones]
## <modelos>: un nombre de models/, "lineup" (los cuatro profundos) o varios separados por comas.
## Opciones clave=valor: propiedades del Environment (fog_density=0.03), de las luces
## (moon.light_energy=0.6, lamp.*, rim.*), de la cámara (cam.size=4), tag=sufijo,
## frames=N (fotogramas de animación) y floor=false.

const LINEUP: Array[String] = ["clasico", "bruto", "acechador", "abisal"]
const GAP := 0.3   # separación entre modelos de un grupo, en metros

var mode := "still"
var yaw := 0.0
var spec := "clasico"
var anim := "walk"
var names: Array[String] = []
var models: Array[Node3D] = []
var nframes := 24
var frame := 0
var tag := ""

func _ready() -> void:
	get_window().size = Vector2i(1000, 1000)   # las capturas del visor son cuadradas; el juego va a 1920x1080
	var la := LaunchArgs.from_cmdline()
	var pos := la.positional
	if pos.size() > 0: mode = pos[0]
	if pos.size() > 1: yaw = float(pos[1])
	if pos.size() > 2: spec = pos[2]
	if pos.size() > 3: anim = pos[3]
	if spec == "lineup": names = LINEUP.duplicate()
	else:
		for n in spec.split(","): names.append(n)
	nframes = la.get_int("frames", roundi(Anims.duration(names[0], anim) * 24.0))
	if la.has("tag"): tag = "_" + la.get_str("tag")
	var env := Atmosphere.make_environment()
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	# Modelos en fila, cada uno dentro de un contenedor que lleva el giro
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = Vector3(-30, 45, 0)
	var right := cam.transform.basis.x
	var widths: Array[float] = []
	for n in names:
		var m := VoxelBuilder.load_model("res://models/%s.json" % n)
		var holder := Node3D.new()
		holder.rotation_degrees.y = yaw
		holder.add_child(m)
		add_child(holder)
		models.append(m)
		widths.append(_extent(m, right))
	var total := GAP * (names.size() - 1)
	for w in widths: total += w
	var x := -total * 0.5
	for i in models.size():
		(models[i].get_parent() as Node3D).position = right * (x + widths[i] * 0.5)
		x += widths[i] + GAP
	# Cámara que encuadra el grupo (con margen extra para las animaciones)
	var up := cam.transform.basis.y
	var rx := _range(right)
	var ry := _range(up)
	var center := right * (rx.x + rx.y) * 0.5 + up * (ry.x + ry.y) * 0.5
	var margin := 1.3 if mode == "anim" else 1.12
	var aspect := 1.0
	cam.size = maxf(ry.y - ry.x, (rx.y - rx.x) / aspect) * margin
	cam.position = center + cam.transform.basis.z * 20.0
	cam.far = 60.0
	add_child(cam)
	# Luna fría, farol cálido y contraluz verdosa, colocados respecto al grupo
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, 20, 0)
	moon.light_color = Color(0.6, 0.72, 0.85); moon.light_energy = 0.45
	moon.shadow_enabled = true
	add_child(moon)
	var k := maxf(1.0, cam.size / 2.3)
	var lamp := _omni(center + Vector3(1.4, 1.0, 1.6) * k, Color(1.0, 0.72, 0.4), 1.8, 5.0 * k, true)
	var rim := _omni(center + Vector3(-1.2, 0.5, -1.5) * k, Color(0.4, 0.95, 0.75), 1.2, 4.0 * k, false)
	if names.size() > 1:
		_omni(center + Vector3(-1.6, 1.0, 1.8) * k, Color(1.0, 0.72, 0.4), 1.6, 5.0 * k, false)
	# Ajustes al vuelo
	var targets := {"moon": moon, "lamp": lamp, "rim": rim, "cam": cam}
	for key: String in la.options:
		if key in ["tag", "frames", "floor"]: continue
		var obj: Object = env
		var prop := key
		if "." in key:
			obj = targets[key.get_slice(".", 0)]
			prop = key.get_slice(".", 1)
		obj.set(prop, str_to_var(la.get_str(key)))
	if la.get_bool("floor", true): _floor(center, cam.size)

func _omni(p: Vector3, c: Color, energy: float, rng: float, shadow: bool) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = p; l.light_color = c; l.light_energy = energy; l.omni_range = rng
	l.shadow_enabled = shadow
	add_child(l)
	return l

## Anchura del modelo a lo largo de un eje (en reposo, con su giro).
func _extent(m: Node3D, axis: Vector3) -> float:
	var lo := INF; var hi := -INF
	var basis := Basis(Vector3.UP, deg_to_rad(yaw))
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var aabb: AABB = (mi as MeshInstance3D).get_aabb()
		var off := (mi.get_parent() as Node3D).position
		for i in 8:
			var d := (basis * (aabb.get_endpoint(i) + off)).dot(axis)
			lo = minf(lo, d); hi = maxf(hi, d)
	return hi - lo

## Mínimo y máximo de todos los modelos proyectados sobre un eje de la cámara.
func _range(axis: Vector3) -> Vector2:
	var lo := INF; var hi := -INF
	for m in models:
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			var aabb: AABB = (mi as MeshInstance3D).get_aabb()
			var xf: Transform3D = (mi as MeshInstance3D).global_transform
			for i in 8:
				var d := (xf * aabb.get_endpoint(i)).dot(axis)
				lo = minf(lo, d); hi = maxf(hi, d)
	return Vector2(lo, hi)

func _floor(center: Vector3, size: float) -> void:
	# Losas húmedas voxel alrededor del grupo
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true; mat.roughness = 0.3
	mat.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tile := 0.5
	var n := int(ceil(size * 1.6 / tile)) + 4
	var ox := floorf(center.x / tile); var oz := floorf(center.z / tile)
	for i in range(-n, n):
		for j in range(-n, n):
			var h := rng.randf_range(-0.03, 0.0)
			var g := rng.randf_range(0.09, 0.15)
			var c := Color(g * 0.8, g, g * 0.95)
			if rng.randf() < 0.15: c = Color(0.1, 0.16, 0.12)  # musgo
			var x0 := (ox + i) * tile + 0.01; var z0 := (oz + j) * tile + 0.01; var s := tile - 0.02
			var q := [Vector3(x0, h, z0), Vector3(x0, h, z0 + s), Vector3(x0 + s, h, z0 + s), Vector3(x0 + s, h, z0)]
			for kk in [0, 2, 1, 0, 3, 2]:
				st.set_normal(Vector3.UP); st.set_color(c); st.add_vertex(q[kk])
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = mat
	add_child(mi)

func _process(_delta: float) -> void:
	frame += 1
	var fname := spec.replace(",", "-")
	if mode == "anim":
		var t := (frame - 5) / float(nframes)
		for i in models.size():
			Anims.pose(names[i], anim, models[i], fposmod(t, 1.0))
		if frame >= 5 and frame < 5 + nframes:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://shots/%s_%s_%03d%s.png" % [fname, anim, frame - 5, tag])
		elif frame >= 5 + nframes:
			get_tree().quit()
	else:
		if frame == 8:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://shots/%s_%d%s.png" % [fname, int(yaw), tag])
			get_tree().quit()
