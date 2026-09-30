class_name ModelIcon
extends RefCounted
## Imagen de un modelo voxel para los menús: lo renderiza una vez en un SubViewport (hijo de
## `host`) y devuelve la textura. "head" encuadra la cabeza (retratos de personajes);
## "full", el modelo entero de tres cuartos (compañeros, iconos de la tienda).

static func make(host: Node, model_name: String, mode: String = "full", px: int = 128) -> Texture2D:
	var vp := SubViewport.new()
	# se renderiza una sola vez: sin interpolación, o saldría a medio camino desde el origen
	vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	vp.size = Vector2i(px, px)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(vp)
	var m := VoxelBuilder.load_model("res://models/%s.json" % model_name)
	vp.add_child(m)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	if mode == "head":
		var head: Vector3 = Anims.rest(m, "head") + Vector3(0, 0.2, 0)
		cam.size = 0.62
		cam.rotation_degrees = Vector3(-12, 25, 0)
		cam.position = head + cam.transform.basis.z * 3.0
	else:
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in m.get_meta("meshes"):
			var b := m.transform.affine_inverse() * mi.global_transform * mi.get_aabb()   # en el espacio del modelo
			box = b if first else box.merge(b)
			first = false
		cam.rotation_degrees = Vector3(-25, 35, 0)
		cam.size = maxf(box.size.x, maxf(box.size.y, box.size.z)) * 0.95
		cam.position = box.get_center() + cam.transform.basis.z * 4.0
	vp.add_child(cam)
	# iluminación de estudio: luz principal cálida, relleno frío suave y poco ambiente. Con un
	# ambiente gris fuerte y una sola luz, el modelo salía plano y lavado, como tras una niebla.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, 50, 0)
	key.light_energy = 1.35
	key.light_color = Color(1.0, 0.95, 0.88)
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -60, 0)
	fill.light_energy = 0.4
	fill.light_color = Color(0.75, 0.82, 1.0)
	vp.add_child(fill)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.14, 0.16)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	we.environment = env
	vp.add_child(we)
	return vp.get_texture()
