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
	root.set_meta("light", data.get("light", {}))
	root.add_child(_ground(data, size))
	if data.has("sea"): root.add_child(_sea(data, size))     # arenas de interior: sin mar
	if data.has("barrier"): root.add_child(_barrier(data.barrier, size))
	var lights: Array[OmniLight3D] = []
	var obstacles := ObstacleMap.new()
	obstacles.bounds = Rect2(-size * 0.5, size)
	# mapa de lo transitable (tools/gen_mapa_transitable.py): con él, los límites y los
	# obstáculos siguen lo dibujado y sobran los cuerpos físicos del decorado
	var masked := data.has("mask") and obstacles.load_mask(data.mask)
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	for p: Dictionary in data.props:
		var holder := Node3D.new()
		holder.position = Vector3(p.pos[0], 0, p.pos[1])
		# lo que queda en el mar (más allá de la orilla, al sur o al este) flota a la altura del agua
		if data.has("sea") and (p.pos[0] > size.x * 0.5 or p.pos[1] > size.y * 0.5):
			holder.position.y = float(data.sea.level) - 0.15
		holder.rotation_degrees.y = p.rot
		holder.scale = Vector3.ONE * float(p.scale)
		var m := VoxelBuilder.load_model("res://models/%s.json" % p.model)
		holder.add_child(m)
		# lo que está en el mar o en la orilla solo haría sombra sobre el agua, que no la recibe
		if p.model in data.get("no_shadow", []):
			for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		props.add_child(holder)
		_collider(holder, m, data.colliders.get(p.model, {}), obstacles, not masked)
		if (m.get_meta("pivots") as Dictionary).has("light"):
			lights.append(_lamp(holder, m, data.lamp, fog_volumes))
	root.set_meta("lights", lights)
	root.set_meta("obstacles", obstacles)
	if not masked: root.add_child(_walls(size))
	return root

## Luz propia de la arena (JSON "light"): sol o luna y entorno. Claves opcionales: sun_rot
## [x, y], sun_color, sun_energy, ambient_color, ambient_energy, background, fog_color,
## fog_density y exposure (solo Forward+).
static func apply_light(l: Dictionary, sun: DirectionalLight3D, env: Environment) -> void:
	if l.is_empty(): return
	var col := func(a: Array) -> Color: return Color(a[0], a[1], a[2])
	if l.has("sun_rot"): sun.rotation_degrees = Vector3(l.sun_rot[0], l.sun_rot[1], 0)
	if l.has("sun_color"): sun.light_color = col.call(l.sun_color)
	if l.has("sun_energy"): sun.light_energy = l.sun_energy
	if l.has("ambient_color"): env.ambient_light_color = col.call(l.ambient_color)
	if l.has("ambient_energy"): env.ambient_light_energy = l.ambient_energy
	if l.has("background"): env.background_color = col.call(l.background)
	if l.has("fog_color"): env.fog_light_color = col.call(l.fog_color)
	if l.has("fog_density"): env.fog_density = l.fog_density
	if l.has("exposure") and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		env.tonemap_exposure = l.exposure

## Suelo de nieve en losas de 0,5 m: nieve blanca (se ve gris azulada con la luz de luna), placas de hielo,
## roca asomando y nieve pisada alrededor del campamento. Por detrás (norte y oeste)
## se prolonga bajo los acantilados; por delante (sur y este) acaba en la orilla.
static func _ground(data: Dictionary, size: Vector2) -> MeshInstance3D:
	var g: Dictionary = data.ground
	var tile: float = g.tile
	var back: float = g.margin_back
	var front: float = g.get("margin_front", 0.0)     # sin mar: el suelo sigue por delante
	var noise := FastNoiseLite.new()
	noise.seed = int(g.seed)
	noise.frequency = 0.06
	var fine := FastNoiseLite.new()
	fine.seed = int(g.seed) + 1
	fine.frequency = 0.35
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -size.x * 0.5 - back; var x1 := size.x * 0.5 + front
	var z0 := -size.y * 0.5 - back; var z1 := size.y * 0.5 + front
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
	var lvl: float = data.sea.level if data.has("sea") else 0.0
	for seg in [] if not data.has("sea") else [[Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, 1)], [Vector3(x1, 0, z1), Vector3(x1, 0, z0), Vector3(1, 0, 0)]]:
		var a: Vector3 = seg[0]; var b: Vector3 = seg[1]; var nrm: Vector3 = seg[2]
		var q := [a, a + Vector3(0, lvl - 0.05, 0), b + Vector3(0, lvl - 0.05, 0), b]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(nrm)
			st.set_color(edge)
			st.add_vertex(q[k])
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = st.commit()
	# El color y el relieve fino salen del shader (celdas de 12,5 cm); el color de vértice
	# ya no se usa.
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/level/snow_ground.gdshader")
	if g.has("camp_radius"): mat.set_shader_parameter("camp_radius", float(g.camp_radius))   # nieve pisada
	mi.material_override = mat
	return mi

## Mar helado más allá de la orilla (sea.gdshader: baldosas de agua con oleaje y espuma).
static func _sea(data: Dictionary, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Sea"
	var pm := PlaneMesh.new()
	pm.size = Vector2(size.x + 200, size.y + 200)
	mi.mesh = pm
	# por debajo del suelo solo asoma más allá de la orilla (sur y este)
	mi.position = Vector3(size.x * 0.5 + 30, float(data.sea.level), size.y * 0.5 + 30)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/level/sea.gdshader")
	mat.set_shader_parameter("shore", size * 0.5)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Barrera que cierra la arena por detrás (norte y oeste): tramos de acantilado repetidos
## y solapados, y una meseta nevada detrás que llega hasta donde alcanza la cámara.
## data: {"models": [...], "sides": ["north", "west"], "line": m desde el centro hasta el
## frente, "spacing": m entre tramos, "from"/"to": m a lo largo, "y": altura de la base,
## "plateau": altura de la meseta}.
static func _barrier(b: Dictionary, size: Vector2) -> Node3D:
	var root := Node3D.new()
	root.name = "Barrier"
	var models: Array = b.models
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var line: float = b.line
	if b.has("placements"):                  # medidos por gen_mapa_transitable.py: justo ahí
		for pl: Array in b.placements:
			var holder := Node3D.new()
			holder.position = Vector3(pl[0], pl[1], pl[2])
			holder.rotation_degrees.y = pl[3]
			holder.scale = Vector3(1.0, pl[4], 1.0)
			var m := VoxelBuilder.load_model("res://models/%s.json" % pl[5])
			for mi in m.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(m)
			root.add_child(holder)
	for side: String in ([] if b.has("placements") else b.sides):
		var t: float = b.from
		var k := 0
		while t <= float(b.to):
			var holder := Node3D.new()
			var jitter := rng.randf_range(-0.6, 0.6)
			if side == "north":
				holder.position = Vector3(t, float(b.y), -line + jitter)
			else:
				holder.position = Vector3(-line + jitter, float(b.y), t)
				holder.rotation_degrees.y = 90.0                       # el frente (+Z) mira al este
			holder.scale = Vector3(1.0, rng.randf_range(0.9, 1.12), 1.0)
			var m := VoxelBuilder.load_model("res://models/%s.json" % models[(k * 7 + 3) % models.size()])
			for mi in m.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(m)
			root.add_child(holder)
			t += float(b.spacing) + rng.randf_range(-0.4, 0.4)
			k += 1
	# meseta nevada detrás de la barrera (en L: norte y oeste)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = b.plateau
	var far := 90.0
	var back := line + 3.0                                            # empieza bajo la cumbre
	for r in [Rect2(-far, -far, 2.0 * far, far - back), Rect2(-far, -back, far - back, far + back)]:
		var q := [Vector3(r.position.x, h, r.position.y), Vector3(r.position.x, h, r.end.y),
			Vector3(r.end.x, h, r.end.y), Vector3(r.end.x, h, r.position.y)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_color(Color(0.84, 0.88, 0.93))
			st.add_vertex(q[i])
	var plateau := MeshInstance3D.new()
	plateau.name = "Plateau"
	plateau.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	mat.roughness = 0.9
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	plateau.material_override = mat
	plateau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(plateau)
	return root

## Colisión de una pieza: su círculo en el mapa de obstáculos (con mapa de lo transitable,
## solo para dibujarlo en el mapa del nivel) y, sin él, un cuerpo físico para el jugador.
static func _collider(holder: Node3D, m: Node3D, def: Dictionary, obstacles: ObstacleMap, physical := true) -> void:
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
	if physical: holder.add_child(body)
	else: body.free()

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
