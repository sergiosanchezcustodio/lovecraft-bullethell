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
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-35, 40, 0)
	l.light_energy = 1.3
	vp.add_child(l)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.3
	we.environment = env
	vp.add_child(we)
	return vp.get_texture()
