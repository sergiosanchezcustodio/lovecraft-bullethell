class_name ModelIcon
extends RefCounted
## Imagen de un modelo voxel para los menús: lo renderiza una vez en un SubViewport (hijo de
## `host`) y devuelve la textura. "head" encuadra la cabeza (retratos de personajes);
## "full", el modelo entero de tres cuartos (compañeros, iconos de la tienda), encajado con
## margen según lo que ocupa visto desde la cámara. Con `fixed` > 0 (m de alto del encuadre),
## todos a la misma escala y con los pies en el mismo sitio (bestiario de la Biblioteca).

const FULL_ROT := Vector3(-25, 35, 0)
const MARGIN := 1.12

## Lo que ocupa el modelo visto con la cámara de "full" (m, lo mayor de ancho y alto).
static func frame_size(model_name: String) -> float:
	var m := VoxelBuilder.load_model("res://models/%s.json" % model_name)
	var r := _projected(m, Basis.from_euler(FULL_ROT * PI / 180.0))
	m.free()
	return maxf(r.size.x, r.size.y)

## Caja del modelo proyectada en el plano de la cámara (x a la derecha, y arriba).
static func _projected(m: Node3D, basis: Basis) -> Rect2:
	var r := Rect2()
	var first := true
	for mi: MeshInstance3D in m.get_meta("meshes"):
		var xf := Transform3D()                    # de la malla a la raíz del modelo (cuelga de su parte)
		var n: Node = mi
		while n != m and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b: AABB = xf * mi.get_aabb()
		for i in 8:
			var c := b.get_endpoint(i)
			var p := Vector2(c.dot(basis.x), c.dot(basis.y))
			r = Rect2(p, Vector2.ZERO) if first else r.expand(p)
			first = false
	return r

static func make(host: Node, model_name: String, mode: String = "full", px: int = 128, fixed := 0.0) -> Texture2D:
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
		cam.rotation_degrees = FULL_ROT
		var bs := cam.transform.basis
		var r := _projected(m, bs)
		var c := r.get_center()
		if fixed > 0.0:
			cam.size = fixed
			c.y = r.position.y + fixed * 0.5 * 0.9          # pies abajo, todos a la misma altura
		else:
			cam.size = maxf(r.size.x, r.size.y) * MARGIN
		var far := 0.0
		for mi: MeshInstance3D in m.get_meta("meshes"): far = maxf(far, mi.get_aabb().size.length())
		cam.position = bs.x * c.x + bs.y * c.y + bs.z * (far + 4.0)
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
