class_name VoxelBuilder
extends RefCounted
## Construye un modelo voxel por partes (cada parte = MeshInstance3D con pivote propio).

const VOXEL := 0.03125  # 32 voxels = 1 metro de juego

const FACES := [
	[Vector3i(1,0,0),  [Vector3(1,0,0),Vector3(1,1,0),Vector3(1,1,1),Vector3(1,0,1)]],
	[Vector3i(-1,0,0), [Vector3(0,0,1),Vector3(0,1,1),Vector3(0,1,0),Vector3(0,0,0)]],
	[Vector3i(0,1,0),  [Vector3(0,1,0),Vector3(0,1,1),Vector3(1,1,1),Vector3(1,1,0)]],
	[Vector3i(0,-1,0), [Vector3(0,0,1),Vector3(0,0,0),Vector3(1,0,0),Vector3(1,0,1)]],
	[Vector3i(0,0,1),  [Vector3(1,0,1),Vector3(1,1,1),Vector3(0,1,1),Vector3(0,0,1)]],
	[Vector3i(0,0,-1), [Vector3(0,0,0),Vector3(0,1,0),Vector3(1,1,0),Vector3(1,0,0)]],
]

## Mallas ya construidas por ruta de modelo: todas las instancias de un modelo
## comparten mallas y materiales, y cada JSON se procesa una sola vez.
static var _cache := {}
static var _mats := {}   # "rugosidad/especular" -> material compartido
static var _glow_mat: StandardMaterial3D

## Devuelve una instancia nueva del modelo: un nodo por parte con su pivote.
static func load_model(path: String) -> Node3D:
	var model: Dictionary = _get_model(path)
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	root.set_meta("pivots", model.pivots)
	root.set_meta("voxel_size", model.voxel_size)
	for layer: Dictionary in model.layers:
		var pname: String = layer.part
		var pivot_node: Node3D = root.get_node_or_null(pname)
		if pivot_node == null:
			pivot_node = Node3D.new()
			pivot_node.name = pname
			pivot_node.position = layer.pivot * model.voxel_size
			root.add_child(pivot_node)
		var mi := MeshInstance3D.new()
		mi.mesh = layer.mesh
		mi.material_override = _glow_mat if layer.glow else model.material
		pivot_node.add_child(mi)
	# Para animar sin buscar ni recalcular en cada fotograma (Anims.reset/rest)
	var parts: Array[Node3D] = []
	var rest: Array[Vector3] = []
	var rest_by_name := {}
	var part_nodes := {}
	var meshes: Array[MeshInstance3D] = []
	for c: Node in root.get_children():
		var n := c as Node3D
		parts.append(n)
		rest.append(n.position)
		rest_by_name[n.name] = n.position
		part_nodes[String(n.name)] = n
		for m: Node in n.get_children(): meshes.append(m as MeshInstance3D)
	root.set_meta("parts", parts)
	root.set_meta("rest", rest)
	root.set_meta("rest_by_name", rest_by_name)
	root.set_meta("part_nodes", part_nodes)
	root.set_meta("meshes", meshes)
	return root

static func is_cached(path: String) -> bool:
	return _cache.has(path)

static func clear_cache() -> void:
	_cache.clear()

static func _get_model(path: String) -> Dictionary:
	if _cache.has(path): return _cache[path]
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_ensure_glow_material()
	var all := {}            # ocupación global -> oclusión ambiental
	var occ := {}            # ocupación por parte -> caras ocultas (entre partes solo las enterradas:
	                         # al girar un brazo o una pierna no deben quedar huecos en la unión)
	var parts := {}          # nombre -> Array de [pos, color]
	for v: Array in data.voxels:
		var p := Vector3i(int(v[0]), int(v[1]), int(v[2]))
		all[p] = true
		if not occ.has(v[3]): occ[v[3]] = {}
		occ[v[3]][p] = true
		var key: String = v[3] + ("#glow" if v.size() > 7 and v[7] == 1 else "")
		if not parts.has(key): parts[key] = []
		parts[key].append([p, Color(v[4], v[5], v[6])])
	var keys := parts.keys()
	keys.sort()   # partes base antes que sus capas "#glow"
	var vs: float = data.get("voxel_size", VOXEL)   # escala propia por modelo (jefes colosales, LOD)
	var layers: Array[Dictionary] = []
	for key: String in keys:
		var pname := key.get_slice("#", 0)
		var pv: Array = data.pivots[pname]
		var pivot := Vector3(pv[0], pv[1], pv[2])
		layers.append({"part": pname, "pivot": pivot, "glow": key.ends_with("#glow"),
			"mesh": _build(parts[key], occ[pname], all, pivot, vs)})
	# Material por modelo: las criaturas son de piel húmeda (valores por defecto);
	# ropa, plumas y atrezo declaran en el JSON una superficie mate.
	var mat := _material(float(data.get("roughness", 0.38)), float(data.get("specular", 0.6)))
	var model := {"pivots": data.pivots, "layers": layers, "voxel_size": vs, "material": mat}
	_cache[path] = model
	return model

static func _material(roughness: float, specular: float) -> StandardMaterial3D:
	var key := "%.2f/%.2f" % [roughness, specular]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = colors_are_srgb()
		m.roughness = roughness
		m.metallic_specular = specular
		_mats[key] = m
	return _mats[key]

static func _ensure_glow_material() -> void:
	if _glow_mat != null: return
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.vertex_color_use_as_albedo = true
	_glow_mat.vertex_color_is_srgb = colors_are_srgb()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

## Los colores de los modelos se calibraron en Compatibility, que no convierte
## sRGB a lineal. En Forward+ hay que declararlos sRGB para que se vean igual.
static func colors_are_srgb() -> bool:
	return RenderingServer.get_current_rendering_method() != "gl_compatibility"

static func _build(voxels: Array, own: Dictionary, all: Dictionary, pivot: Vector3, vs: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for item in voxels:
		var p: Vector3i = item[0]
		var col: Color = item[1]
		for f in FACES:
			var n: Vector3i = f[0]
			if own.has(p + n): continue
			# Entre partes distintas solo se quita la cara si está enterrada (dos voxels
			# ocupados por delante): las costuras, que pueden asomar al girar, se conservan.
			if all.has(p + n) and all.has(p + n + n): continue
			var corners: Array = f[1]
			var shades := []
			for c in corners:
				shades.append(_ao(p, n, c, all))
			var idx := [0, 2, 1, 0, 3, 2]
			if shades[0] + shades[2] < shades[1] + shades[3]:
				idx = [1, 3, 2, 1, 0, 3]   # evita artefactos de AO en diagonal
			for i in idx:
				st.set_normal(Vector3(n))
				st.set_color(col * shades[i])
				st.add_vertex((Vector3(p) + corners[i] - pivot) * vs)
	return st.commit()

static func _ao(p: Vector3i, n: Vector3i, corner: Vector3, all: Dictionary) -> float:
	# Oclusión ambiental clásica voxel: mira 2 laterales + diagonal junto al vértice
	var axes := []
	for a in [Vector3i(1,0,0), Vector3i(0,1,0), Vector3i(0,0,1)]:
		if a != n.abs(): axes.append(a)
	var d1: Vector3i = axes[0] * (1 if corner[_axis(axes[0])] > 0.5 else -1)
	var d2: Vector3i = axes[1] * (1 if corner[_axis(axes[1])] > 0.5 else -1)
	var s1 := all.has(p + n + d1)
	var s2 := all.has(p + n + d2)
	var c := all.has(p + n + d1 + d2)
	var occ := 3 if (s1 and s2) else int(s1) + int(s2) + int(c)
	return [1.0, 0.86, 0.74, 0.62][occ]

static func _axis(a: Vector3i) -> int:
	return 0 if a.x != 0 else (1 if a.y != 0 else 2)
