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
## Caché en disco de las mallas construidas (ver VoxelMeshCache). Sube BUILDER_VERSION
## cuando cambie la forma de construir las mallas, para invalidar lo guardado.
const BUILDER_VERSION := 4
const DISK_CACHE_DIR := "user://voxcache"
static var use_disk_cache := true
static var _mats := {}   # "rugosidad/especular" -> material compartido
static var _glow_mat: StandardMaterial3D

## Devuelve una instancia nueva del modelo: un nodo por parte con su pivote. Si el JSON
## trae "parents" ({"fore_l": "arm_l"}), esa parte cuelga de la otra: al girar el brazo, el
## antebrazo va con él y además se dobla por su propio pivote (el codo).
static func load_model(path: String) -> Node3D:
	var model: Dictionary = _get_model(path)
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	root.set_meta("pivots", model.pivots)
	root.set_meta("voxel_size", model.voxel_size)
	var order: Array[String] = []                   # partes en orden de creación
	for layer: Dictionary in model.layers:
		var pname: String = layer.part
		var pivot_node: Node3D = root.get_node_or_null(pname)
		if pivot_node == null:
			pivot_node = Node3D.new()
			pivot_node.name = pname
			pivot_node.position = layer.pivot * model.voxel_size
			root.add_child(pivot_node)
			order.append(pname)
		var mi := MeshInstance3D.new()
		mi.mesh = layer.mesh
		mi.material_override = _glow_mat if layer.glow else model.material
		pivot_node.add_child(mi)
	# Jerarquía: cada parte con padre pasa a colgar de él, con la posición relativa a su pivote
	var parents: Dictionary = model.get("parents", {})
	# Un padre sin voxels (el muslo bajo una falda o una sotana, que lo tapa entero) sigue
	# haciendo falta como articulación: se crea vacío para que la espinilla cuelgue de él.
	for pname in order.duplicate():
		var pp := String(parents.get(pname, ""))
		if pp == "" or root.has_node(pp) or not model.pivots.has(pp): continue
		var pv: Array = model.pivots[pp]
		var empty := Node3D.new()
		empty.name = pp
		empty.position = Vector3(pv[0], pv[1], pv[2]) * model.voxel_size
		root.add_child(empty)
		order.append(pp)
	for pname in order:
		if not parents.has(pname): continue
		var n: Node3D = root.get_node(pname)
		var parent: Node3D = root.get_node_or_null(String(parents[pname]))
		if parent == null: continue
		var pos := n.position - parent.position
		root.remove_child(n)
		parent.add_child(n)
		n.position = pos
	# Para animar sin buscar ni recalcular en cada fotograma (Anims.reset/rest)
	var parts: Array[Node3D] = []
	var rest: Array[Vector3] = []
	var rest_by_name := {}
	var part_nodes := {}
	var meshes: Array[MeshInstance3D] = []
	for pname in order:
		var n: Node3D = root.find_child(pname, true, false)
		parts.append(n)
		rest.append(n.position)
		rest_by_name[n.name] = n.position
		part_nodes[String(n.name)] = n
		for m: Node in n.get_children():
			if m is MeshInstance3D: meshes.append(m as MeshInstance3D)
	root.set_meta("parts", parts)
	root.set_meta("rest", rest)
	root.set_meta("rest_by_name", rest_by_name)
	root.set_meta("part_nodes", part_nodes)
	root.set_meta("meshes", meshes)
	return root

## Viste un modelo con una prenda del vestuario (models/vest_*.json, con los mismos pivotes):
## las mallas de cada parte de la prenda pasan a la parte igual del modelo, así que se animan
## con ella. Una prenda de cabeza oculta el sombrero del personaje (parte "hat").
static func dress(root: Node3D, garment_path: String, hides_hat := false) -> bool:
	if not model_exists(garment_path): return false
	var g := load_model(garment_path)
	var nodes: Dictionary = root.get_meta("part_nodes")
	var meshes: Array[MeshInstance3D] = root.get_meta("meshes")
	for pname in (g.get_meta("part_nodes") as Dictionary):
		var src: Node3D = g.get_meta("part_nodes")[pname]
		var dst: Node3D = nodes.get(pname)
		if dst == null: continue
		for c in src.get_children():
			if c is MeshInstance3D:
				src.remove_child(c)
				dst.add_child(c)
				meshes.append(c as MeshInstance3D)
	g.free()
	if hides_hat and nodes.has("hat"): (nodes["hat"] as Node3D).visible = false
	return true

static func is_cached(path: String) -> bool:
	return _cache.has(path)

static func clear_cache() -> void:
	_cache.clear()

static func _get_model(path: String) -> Dictionary:
	if _cache.has(path): return _cache[path]
	_ensure_glow_material()
	var disk_path := _disk_cache_path(path)
	if use_disk_cache and ResourceLoader.exists(disk_path):
		var c := ResourceLoader.load(disk_path, "", ResourceLoader.CACHE_MODE_IGNORE) as VoxelMeshCache
		if c != null and c.meshes.size() == c.parts.size():
			var layers_c: Array[Dictionary] = []
			for i in c.parts.size():
				layers_c.append({"part": c.parts[i], "pivot": c.layer_pivots[i], "glow": c.glows[i], "mesh": c.meshes[i]})
			var m := {"pivots": c.pivots, "parents": c.parents, "layers": layers_c, "voxel_size": c.voxel_size,
				"material": _material(c.roughness, c.specular)}
			_cache[path] = m
			return m
	var data: Dictionary = JSON.parse_string(read_text(path))
	var all := {}            # ocupación global -> oclusión ambiental
	var occ := {}            # ocupación por parte -> caras ocultas (solo dentro de la misma parte:
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
			"mesh": _build(parts[key], occ[pname], all, pivot, vs, bool(data.get("no_bottom", false)))})
	# Material por modelo: las criaturas son de piel húmeda (valores por defecto);
	# ropa, plumas y atrezo declaran en el JSON una superficie mate.
	var rough := float(data.get("roughness", 0.38))
	var spec := float(data.get("specular", 0.6))
	var model := {"pivots": data.pivots, "parents": data.get("parents", {}), "layers": layers, "voxel_size": vs,
		"material": _material(rough, spec)}
	_cache[path] = model
	if use_disk_cache: _save_disk_cache(path, disk_path, model, rough, spec)
	return model

## Los modelos van en JSON (models/*.json) o, en las builds exportadas, comprimidos con el
## formato de Godot y ZSTD (models/*.json.z, de tools/empaquetar_modelos.gd: los JSON ocupan
## ~280 MB). Se piden siempre por su ruta .json; si no está, se lee el .json.z.
static func source_file(path: String) -> String:
	if FileAccess.file_exists(path): return path
	if FileAccess.file_exists(path + ".z"): return path + ".z"
	return path

static func model_exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".z")

static func read_text(path: String) -> String:
	var src := source_file(path)
	if src.ends_with(".z"):
		var f := FileAccess.open_compressed(src, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
		return f.get_as_text() if f != null else ""
	return FileAccess.get_file_as_string(src)

## Ruta en la caché de disco: cambia si cambia el JSON (fecha y tamaño) o el constructor.
static func _disk_cache_path(path: String) -> String:
	path = source_file(path)
	var f := FileAccess.open(path, FileAccess.READ)
	var size := f.get_length() if f != null else 0
	return "%s/%s_%d_%d_v%d.res" % [DISK_CACHE_DIR, path.get_file().get_basename(),
		FileAccess.get_modified_time(path), size, BUILDER_VERSION]

static func _save_disk_cache(path: String, disk_path: String, model: Dictionary, rough: float, spec: float) -> void:
	DirAccess.make_dir_recursive_absolute(DISK_CACHE_DIR)
	# borrar versiones anteriores del mismo modelo
	var base := path.get_file().get_basename() + "_"
	for f in DirAccess.get_files_at(DISK_CACHE_DIR):
		if f.begins_with(base) and f.get_slice("_", f.get_slice_count("_") - 1).begins_with("v"):
			var rest := f.trim_prefix(base)
			if rest.count("_") == 2: DirAccess.remove_absolute(DISK_CACHE_DIR + "/" + f)
	var c := VoxelMeshCache.new()
	c.pivots = model.pivots
	c.parents = model.get("parents", {})
	c.voxel_size = model.voxel_size
	c.roughness = rough
	c.specular = spec
	for layer: Dictionary in model.layers:
		c.parts.append(layer.part)
		c.layer_pivots.append(layer.pivot)
		c.glows.append(layer.glow)
		c.meshes.append(layer.mesh)
	ResourceSaver.save(c, disk_path)

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

## no_bottom (JSON "no_bottom": true, atrezo fijo): sin las caras que miran hacia abajo, que la
## cámara isométrica nunca ve; en piezas planas (témpanos, costa) son casi la mitad.
static func _build(voxels: Array, own: Dictionary, all: Dictionary, pivot: Vector3, vs: float, no_bottom := false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for item in voxels:
		var p: Vector3i = item[0]
		var col: Color = item[1]
		for f in FACES:
			var n: Vector3i = f[0]
			# Solo se quitan las caras que tapa un voxel de la MISMA parte. Entre partes
			# distintas se conservan todas: al girar un brazo, una pierna o la cabeza queda
			# al aire lo que tapaban (con el brazo pegado al tronco, el costado se veía hueco).
			if own.has(p + n): continue
			if no_bottom and n.y < 0: continue
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
