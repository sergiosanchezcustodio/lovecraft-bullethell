class_name ArenaBuilder
extends RefCounted
## Monta una arena a partir de su JSON (data/arenas/*.json, generado en tools/):
## suelo, mar, piezas de atrezo con colisión, luces de los faroles y límites.

const LAYER_WORLD := 1

## Devuelve el nodo raíz de la arena. Metadatos: "spawn" (Vector3), "size" (Vector2),
## "lights" (Array de OmniLight3D de los faroles) y "obstacles" (ObstacleMap, para que los
## enemigos rodeen el decorado sin cuerpo físico).
static func build(path: String, fog_volumes: bool = false) -> Node3D:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var root := Node3D.new()
	root.name = "Arena"
	var size := Vector2(data.size[0], data.size[1])
	root.set_meta("size", size)
	root.set_meta("spawn", Vector3(data.spawn[0], 0, data.spawn[1]))
	root.add_child(_ground(data, size))
	root.add_child(_sea(data, size))
	var lights: Array[OmniLight3D] = []
	var obstacles := ObstacleMap.new()
	obstacles.bounds = Rect2(-size * 0.5, size)
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	for p: Dictionary in data.props:
		var holder := Node3D.new()
		holder.position = Vector3(p.pos[0], 0, p.pos[1])
		holder.rotation_degrees.y = p.rot
		holder.scale = Vector3.ONE * float(p.scale)
		var m := VoxelBuilder.load_model("res://models/%s.json" % p.model)
		holder.add_child(m)
		props.add_child(holder)
		_collider(holder, m, data.colliders.get(p.model, {}), obstacles)
		if (m.get_meta("pivots") as Dictionary).has("light"):
			lights.append(_lamp(holder, m, data.lamp, fog_volumes))
	root.set_meta("lights", lights)
	root.set_meta("obstacles", obstacles)
	root.add_child(_walls(size))
	return root

## Suelo de nieve en losas de 0,5 m: nieve blanca (se ve gris azulada con la luz de luna), placas de hielo,
## roca asomando y nieve pisada alrededor del campamento. Por detrás (norte y oeste)
## se prolonga bajo los acantilados; por delante (sur y este) acaba en la orilla.
static func _ground(data: Dictionary, size: Vector2) -> MeshInstance3D:
	var g: Dictionary = data.ground
	var tile: float = g.tile
	var back: float = g.margin_back
	var noise := FastNoiseLite.new()
	noise.seed = int(g.seed)
	noise.frequency = 0.06
	var fine := FastNoiseLite.new()
	fine.seed = int(g.seed) + 1
	fine.frequency = 0.35
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -size.x * 0.5 - back; var x1 := size.x * 0.5
	var z0 := -size.y * 0.5 - back; var z1 := size.y * 0.5
	var nx := int((x1 - x0) / tile); var nz := int((z1 - z0) / tile)
	for i in nx:
		for j in nz:
			var x := x0 + i * tile; var z := z0 + j * tile
			var cx := x + tile * 0.5; var cz := z + tile * 0.5
			var n := noise.get_noise_2d(cx, cz)
			var f := fine.get_noise_2d(cx, cz)
			var c := Color(0.80, 0.84, 0.89).lerp(Color(0.88, 0.91, 0.95), f * 0.5 + 0.5)   # nieve
			if n > 0.42: c = Color(0.60, 0.72, 0.80).lerp(Color(0.66, 0.77, 0.84), f * 0.5 + 0.5)  # hielo
			elif n < -0.55: c = Color(0.30, 0.30, 0.31).lerp(Color(0.38, 0.37, 0.36), f * 0.5 + 0.5)  # roca
			var d := Vector2(cx, cz).length()
			if d < 14.0 and fine.get_noise_2d(cx * 0.4, cz * 0.4) > 0.05 - (14.0 - d) * 0.02:
				c = c.lerp(Color(0.70, 0.71, 0.74), 0.55)                                    # nieve pisada
			# losas contiguas (sin juntas: los huecos dibujaban una cuadrícula y dejaban ver el mar)
			var q := [Vector3(x, 0, z), Vector3(x, 0, z + tile), Vector3(x + tile, 0, z + tile), Vector3(x + tile, 0, z)]
			for k in [0, 2, 1, 0, 3, 2]:
				st.set_normal(Vector3.UP)
				st.set_color(c)
				st.add_vertex(q[k])
	# Frente de la plataforma de hielo en la orilla (sur y este)
	var edge := Color(0.55, 0.66, 0.74)
	var lvl: float = data.sea.level
	for seg in [[Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, 1)], [Vector3(x1, 0, z1), Vector3(x1, 0, z0), Vector3(1, 0, 0)]]:
		var a: Vector3 = seg[0]; var b: Vector3 = seg[1]; var nrm: Vector3 = seg[2]
		var q := [a, a + Vector3(0, lvl - 0.05, 0), b + Vector3(0, lvl - 0.05, 0), b]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(nrm)
			st.set_color(edge)
			st.add_vertex(q[k])
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi

## Mar helado y negro más allá de la orilla.
static func _sea(data: Dictionary, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Sea"
	var pm := PlaneMesh.new()
	pm.size = Vector2(size.x + 160, size.y + 160)
	mi.mesh = pm
	# por debajo del suelo solo asoma más allá de la orilla (sur y este)
	mi.position = Vector3(size.x * 0.5 + 20, float(data.sea.level), size.y * 0.5 + 20)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.015, 0.03, 0.045)
	mat.roughness = 0.12
	mat.metallic_specular = 0.8
	mi.material_override = mat
	return mi

static func _collider(holder: Node3D, m: Node3D, def: Dictionary, obstacles: ObstacleMap) -> void:
	if def.is_empty() or def.get("type", "none") == "none": return
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var aabb := _model_aabb(m)
	if def.type == "cylinder":
		var cyl := CylinderShape3D.new()
		cyl.radius = float(def.radius)
		cyl.height = maxf(aabb.size.y, 1.0)
		cs.shape = cyl
		cs.position.y = cyl.height * 0.5
		obstacles.add_circle(Vector2(holder.position.x, holder.position.z), cyl.radius * holder.scale.x)
	else:
		var box := BoxShape3D.new()
		var k: float = def.get("shrink", 1.0)
		box.size = Vector3(aabb.size.x * k, aabb.size.y, aabb.size.z * k)
		cs.shape = box
		cs.position = aabb.get_center()
		var c := holder.transform * aabb.get_center()
		obstacles.add_circle(Vector2(c.x, c.z), maxf(box.size.x, box.size.z) * 0.5 * holder.scale.x)
	body.add_child(cs)
	holder.add_child(body)

## Caja envolvente del modelo en el espacio del contenedor (sin su escala).
static func _model_aabb(m: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).get_aabb()
		b.position += (mi.get_parent() as Node3D).position
		box = b if first else box.merge(b)
		first = false
	return box

## Luz cálida del farol en el punto "light" del modelo.
static func _lamp(holder: Node3D, m: Node3D, def: Dictionary, fog_volume: bool) -> OmniLight3D:
	var pv: Array = m.get_meta("pivots")["light"]
	var local := Vector3(pv[0], pv[1], pv[2]) * float(m.get_meta("voxel_size"))
	var l := OmniLight3D.new()
	l.name = "Lamp"
	l.light_color = Color(def.color[0], def.color[1], def.color[2])
	l.light_energy = float(def.energy)
	l.omni_range = float(def.range) / holder.scale.x
	l.position = local
	l.light_volumetric_fog_energy = 4.0
	holder.add_child(l)
	if fog_volume:
		var fv := FogVolume.new()
		fv.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		fv.size = Vector3(3.0, 2.6, 3.0)
		fv.position = local
		var fm := FogMaterial.new()
		fm.density = 0.35
		fm.albedo = Color(1.0, 0.85, 0.7)
		fm.height_falloff = 0.0
		fm.edge_fade = 0.9
		fv.material = fm
		holder.add_child(fv)
	return l

## Paredes invisibles en los bordes de la arena.
static func _walls(size: Vector2) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Walls"
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var hx := size.x * 0.5; var hz := size.y * 0.5
	for w in [[Vector3(0, 1.5, -hz - 0.5), Vector3(size.x + 2, 3, 1)], [Vector3(0, 1.5, hz + 0.5), Vector3(size.x + 2, 3, 1)],
			[Vector3(-hx - 0.5, 1.5, 0), Vector3(1, 3, size.y + 2)], [Vector3(hx + 0.5, 1.5, 0), Vector3(1, 3, size.y + 2)]]:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[1]
		cs.shape = box
		cs.position = w[0]
		body.add_child(cs)
	return body
