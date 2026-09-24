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
static var _mat: StandardMaterial3D
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
		mi.material_override = _glow_mat if layer.glow else _mat
		pivot_node.add_child(mi)
	return root

static func is_cached(path: String) -> bool:
	return _cache.has(path)

static func clear_cache() -> void:
	_cache.clear()

static func _get_model(path: String) -> Dictionary:
	if _cache.has(path): return _cache[path]
	_ensure_materials()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var all := {}            # ocupación global -> AO y cullado entre partes
	var parts := {}          # nombre -> Array de [pos, color]
	for v: Array in data.voxels:
		var p := Vector3i(int(v[0]), int(v[1]), int(v[2]))
		all[p] = true
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
			"mesh": _build(parts[key], all, pivot, vs)})
	var model := {"pivots": data.pivots, "layers": layers, "voxel_size": vs}
	_cache[path] = model
	return model

static func _ensure_materials() -> void:
	if _mat != null: return
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.vertex_color_is_srgb = colors_are_srgb()
	_mat.roughness = 0.38   # piel húmeda
	_mat.metallic_specular = 0.6
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.vertex_color_use_as_albedo = true
	_glow_mat.vertex_color_is_srgb = colors_are_srgb()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

## Los colores de los modelos se calibraron en Compatibility, que no convierte
## sRGB a lineal. En Forward+ hay que declararlos sRGB para que se vean igual.
static func colors_are_srgb() -> bool:
	return RenderingServer.get_current_rendering_method() != "gl_compatibility"

static func _build(voxels: Array, all: Dictionary, pivot: Vector3, vs: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for item in voxels:
		var p: Vector3i = item[0]
		var col: Color = item[1]
		for f in FACES:
			var n: Vector3i = f[0]
			if all.has(p + n): continue
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
