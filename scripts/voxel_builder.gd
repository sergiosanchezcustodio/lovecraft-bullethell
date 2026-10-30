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
const BUILDER_VERSION := 8
const UNDER_SINK := 0.03                         ## voxels que se hunden las caras de lo tapado por otra parte (bit 64)
const DISK_CACHE_DIR := "user://voxcache"
static var use_disk_cache := true
static var _mats := {}   # "rugosidad/especular" -> material compartido
static var _glow_mat: StandardMaterial3D

## Versión del arte a comparar (revisión de arte, 14-10-2026): con `arte=v1` al lanzar, cada
## modelo que tenga una copia `models/<nombre>_v1.json` (la versión de antes de rehacerlo) se
## carga de ella. Sin el argumento, la versión nueva.
static var _variant = null

static func variant_path(path: String) -> String:
	if _variant == null:
		_variant = ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("arte="): _variant = a.substr(5)
	if _variant == "" or not path.ends_with(".json"): return path
	var alt: String = path.trim_suffix(".json") + "_" + str(_variant) + ".json"
	if FileAccess.file_exists(alt) or FileAccess.file_exists(alt + ".z"): return alt
	return path

## Devuelve una instancia nueva del modelo: un nodo por parte con su pivote. Si el JSON
## trae "parents" ({"fore_l": "arm_l"}), esa parte cuelga de la otra: al girar el brazo, el
## antebrazo va con él y además se dobla por su propio pivote (el codo).
static func load_model(path: String) -> Node3D:
	path = variant_path(path)
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
		if pname == "flag" and not layer.glow: mi.material_override = _flag_material(model.material)   # ondea al viento
		if pname == "cloth" and not layer.glow: mi.material_override = _cloth_material(model.material)   # ropa tendida, redes
		if int(layer.get("kind", 0)) == KIND_WINDOW: mi.material_override = window_material()
		elif int(layer.get("kind", 0)) == KIND_SKY: mi.material_override = sky_glass_material()
		mi.set_meta("kind", int(layer.get("kind", 1 if layer.glow else 0)))
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
	# posiciones de los pivotes antes de colgar nada: con cadenas de dos niveles (mano -> brazo ->
	# cuerpo), el brazo puede estar ya colgado del cuerpo y su posición ser relativa a él
	var pivot_pos := {}
	for pname in order: pivot_pos[pname] = (root.get_node(pname) as Node3D).position
	for pname in order:
		if not parents.has(pname): continue
		var n: Node3D = root.get_node_or_null(pname)
		if n == null: n = root.find_child(pname, true, false)
		var pp := String(parents[pname])
		var parent: Node3D = root.find_child(pp, true, false)
		if parent == null: continue
		n.get_parent().remove_child(n)
		parent.add_child(n)
		n.position = pivot_pos[pname] - pivot_pos[pp]
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
## con ella. Una prenda de cabeza oculta el sombrero del personaje (parte "hat"). Las piezas que
## el personaje no tiene (GRAFT: el tentáculo) se le añaden colgando de la misma parte que en la
## prenda, y entran en las listas de Anims.reset.
const GRAFT := ["tail"]

static func dress(root: Node3D, garment_path: String, hides_hat := false) -> bool:
	if not model_exists(garment_path): return false
	var g := load_model(garment_path)
	var nodes: Dictionary = root.get_meta("part_nodes")
	var meshes: Array[MeshInstance3D] = root.get_meta("meshes")
	for pname in (g.get_meta("part_nodes") as Dictionary):
		var src: Node3D = g.get_meta("part_nodes")[pname]
		var dst: Node3D = nodes.get(pname)
		if dst == null and pname == "skirt": dst = nodes.get("torso")   # cuerpos de antes del hito 12.3
		if dst == null and GRAFT.has(pname): dst = _graft(root, src)
		if dst == null: continue
		for c in src.get_children():
			if c is MeshInstance3D:
				src.remove_child(c)
				dst.add_child(c)
				meshes.append(c as MeshInstance3D)
	_marks(g, nodes)
	g.free()
	if hides_hat and nodes.has("hat"): (nodes["hat"] as Node3D).visible = false
	return true

## Pieza de la prenda que el personaje no tiene: un nodo vacío en el mismo sitio, colgado de la
## misma parte (los pivotes de prenda y personaje son los mismos).
static func _graft(root: Node3D, src: Node3D) -> Node3D:
	var nodes: Dictionary = root.get_meta("part_nodes")
	var parent: Node3D = nodes.get(String(src.get_parent().name))
	if parent == null: return null
	var n := Node3D.new()
	n.name = src.name
	n.position = src.position
	parent.add_child(n)
	nodes[String(n.name)] = n
	(root.get_meta("parts") as Array).append(n)
	(root.get_meta("rest") as Array).append(n.position)
	(root.get_meta("rest_by_name") as Dictionary)[n.name] = n.position
	return n

## Puntos sin voxels de una prenda (fase 14): "smoke_*" echa humo de pipa desde la cabeza;
## "beam" y "beam_to", la luz de la linterna desde el antebrazo derecho, en esa dirección (no en
## la calidad Baja: `torch_light` en data/quality.json).
static func _marks(g: Node3D, nodes: Dictionary) -> void:
	var piv: Dictionary = g.get_meta("pivots")
	var vs := float(g.get_meta("voxel_size"))
	if piv.has("beam") and piv.has("beam_to") and nodes.has("fore_r") and not (nodes["fore_r"] as Node3D).has_node("Beam") \
			and bool(Quality.value("torch_light", true)):
		var fp: Array = piv["fore_r"]
		var a: Array = piv["beam"]
		var b: Array = piv["beam_to"]
		var from := (Vector3(a[0], a[1], a[2]) - Vector3(fp[0], fp[1], fp[2])) * vs
		var dir := (Vector3(b[0], b[1], b[2]) - Vector3(a[0], a[1], a[2])).normalized()
		var spot := SpotLight3D.new()
		spot.name = "Beam"
		spot.light_color = Color(1.0, 0.93, 0.74)
		spot.light_energy = 2.2
		spot.spot_range = 7.0
		spot.spot_angle = 22.0
		spot.spot_attenuation = 0.8
		spot.shadow_enabled = false
		spot.light_volumetric_fog_energy = 1.5
		spot.position = from
		spot.basis = Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.BACK)
		(nodes["fore_r"] as Node3D).add_child(spot)
	for k: String in piv:
		if not k.begins_with("smoke") or not nodes.has("head") or not piv.has("head"): continue
		var head: Node3D = nodes["head"]
		if head.has_node(k): continue
		var pv: Array = piv[k]
		var hp: Array = piv["head"]
		var e := VoxelFx.emitter("pipe", 0.05)
		e.name = k
		e.position = (Vector3(pv[0], pv[1], pv[2]) - Vector3(hp[0], hp[1], hp[2])) * vs
		head.add_child(e)

static func is_cached(path: String) -> bool:
	return _cache.has(path)

## Olvida un modelo ya construido para que la próxima carga lea el JSON de nuevo (revisión de
## arte: el modelo cambia en disco con el juego abierto).
static func forget(path: String) -> void:
	_cache.erase(path)

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
				var kd: int = c.kinds[i] if i < c.kinds.size() else int(c.glows[i])
				layers_c.append({"part": c.parts[i], "pivot": c.layer_pivots[i], "glow": c.glows[i], "kind": kd, "mesh": c.meshes[i]})
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
		var g := int(v[7]) if v.size() > 7 else 0                   # 1 luz, 2 ventana que se enciende, 3 cristal con cielo
		var key: String = v[3] + ("" if g <= 0 else ["", "#glow", "#gwin", "#gsky"][clampi(g, 1, 3)])
		if not parts.has(key): parts[key] = []
		# noveno valor (opcional): caras que dan al hueco cerrado de su parte y no se construyen
		# (bits +x, -x, +y, -y, +z, -z en el orden de FACES; voxlib.inner_faces)
		parts[key].append([p, Color(v[4], v[5], v[6]), int(v[8]) if v.size() > 8 else 0])
	var keys := parts.keys()
	keys.sort()   # partes base antes que sus capas "#glow"
	var vs: float = data.get("voxel_size", VOXEL)   # escala propia por modelo (jefes colosales, LOD)
	var layers: Array[Dictionary] = []
	for key: String in keys:
		var pname := key.get_slice("#", 0)
		var pv: Array = data.pivots[pname]
		var pivot := Vector3(pv[0], pv[1], pv[2])
		var kind := 1 if key.ends_with("#glow") else (2 if key.ends_with("#gwin") else (3 if key.ends_with("#gsky") else 0))
		layers.append({"part": pname, "pivot": pivot, "glow": kind > 0, "kind": kind,
			"mesh": _build(parts[key], occ[pname], all, pivot, vs, bool(data.get("no_bottom", false)), kind == KIND_WINDOW)})
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
		c.kinds.append(int(layer.get("kind", 0)))
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

## Material de las banderas (parte "flag"): el de la pieza, con las ondas del viento en el
## shader de vértices (scripts/fx/flag_wave.gdshader). Uno compartido por cada material base.
static var _flag_mats := {}
static func _flag_material(base: StandardMaterial3D) -> ShaderMaterial:
	if not _flag_mats.has(base):
		var m := ShaderMaterial.new()
		m.shader = preload("res://scripts/fx/flag_wave.gdshader")
		m.set_shader_parameter("colors_srgb", colors_are_srgb())
		m.set_shader_parameter("roughness_v", base.roughness)
		m.set_shader_parameter("specular_v", base.metallic_specular)
		_flag_mats[base] = m
	return _flag_mats[base]

## Capas especiales (glow 2 y 3 en el JSON, 16-10-2026, ambiente de los escenarios)
const KIND_WINDOW := 2      ## ventana que se enciende y se apaga sola (window_glow.gdshader)
const KIND_SKY := 3         ## cristal que refleja el cielo de noche con estrellas (sky_glass.gdshader)
static var _window_mat: ShaderMaterial
static var _sky_mat: ShaderMaterial
static func window_material() -> ShaderMaterial:
	if _window_mat == null:
		_window_mat = ShaderMaterial.new()
		_window_mat.shader = preload("res://scripts/fx/window_glow.gdshader")
		_window_mat.set_shader_parameter("colors_srgb", colors_are_srgb())
	return _window_mat
static func sky_glass_material() -> ShaderMaterial:
	if _sky_mat == null:
		_sky_mat = ShaderMaterial.new()
		_sky_mat.shader = preload("res://scripts/fx/sky_glass.gdshader")
		_sky_mat.set_shader_parameter("colors_srgb", colors_are_srgb())
	return _sky_mat

## Material de la parte "cloth" (ropa tendida, redes; 16-10-2026): cuelga de su pivote y se mece
## con el viento (sway.gdshader con `hang`).
static var _cloth_mats := {}
static func _cloth_material(base: StandardMaterial3D) -> ShaderMaterial:
	if not _cloth_mats.has(base):
		var m := ShaderMaterial.new()
		m.shader = preload("res://scripts/fx/sway.gdshader")
		m.set_shader_parameter("colors_srgb", colors_are_srgb())
		m.set_shader_parameter("roughness_v", base.roughness)
		m.set_shader_parameter("specular_v", base.metallic_specular)
		m.set_shader_parameter("hang", true)
		m.set_shader_parameter("amplitude", 0.09)
		m.set_shader_parameter("height", 1.0)
		m.set_shader_parameter("speed", 1.8)
		_cloth_mats[base] = m
	return _cloth_mats[base]

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
static func _build(voxels: Array, own: Dictionary, all: Dictionary, pivot: Vector3, vs: float, no_bottom := false, ids := false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var comp := _components(voxels) if ids else {}
	for item in voxels:
		var p: Vector3i = item[0]
		var col: Color = item[1]
		var inner: int = item[2]
		# bit 64: voxel tapado por el de otra parte en el mismo sitio (el costado bajo el brazo):
		# sus caras se hunden un poco para que, donde coinciden, se vea la otra (voxlib.under_kept)
		var sink := Vector3.ZERO
		if ids: st.set_uv(Vector2(float(comp[p]), 0.0))       # ventana a la que pertenece (window_glow.gdshader)
		for fi in FACES.size():
			var f: Array = FACES[fi]
			var n: Vector3i = f[0]
			# Solo se quitan las caras que tapa un voxel de la MISMA parte. Entre partes
			# distintas se conservan todas: al girar un brazo, una pierna o la cabeza queda
			# al aire lo que tapaban (con el brazo pegado al tronco, el costado se veía hueco).
			if own.has(p + n): continue
			if no_bottom and n.y < 0: continue
			if inner & (1 << fi): continue                        # da al hueco cerrado de su parte
			var corners: Array = f[1]
			sink = Vector3(n) * UNDER_SINK if inner & 64 else Vector3.ZERO
			var shades := []
			for c in corners:
				shades.append(_ao(p, n, c, all))
			var idx := [0, 2, 1, 0, 3, 2]
			if shades[0] + shades[2] < shades[1] + shades[3]:
				idx = [1, 3, 2, 1, 0, 3]   # evita artefactos de AO en diagonal
			for i in idx:
				st.set_normal(Vector3(n))
				st.set_color(col * shades[i])
				st.add_vertex((Vector3(p) + corners[i] - sink - pivot) * vs)
	return st.commit()

## Ventanas (voxels con glow 2): cada grupo de voxels a menos de 2 de otro (salta el parteluz y
## los junquillos de 1 voxel) es una ventana con su número, para que se enciendan por separado.
static func _components(voxels: Array) -> Dictionary:
	var cell := {}
	for item in voxels: cell[item[0]] = -1
	var n := 0
	for item in voxels:
		var s: Vector3i = item[0]
		if cell[s] >= 0: continue
		n += 1
		cell[s] = n
		var stack: Array[Vector3i] = [s]
		while not stack.is_empty():
			var p: Vector3i = stack.pop_back()
			for dx in [-2, -1, 0, 1, 2]:
				for dy in [-2, -1, 0, 1, 2]:
					for dz in [-2, -1, 0, 1, 2]:
						var q := p + Vector3i(dx, dy, dz)
						if cell.get(q, 0) == -1:
							cell[q] = n
							stack.append(q)
	return cell

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
