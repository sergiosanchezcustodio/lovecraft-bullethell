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

static func load_model(path: String) -> Node3D:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var all := {}            # ocupación global -> AO y cullado entre partes
	var parts := {}          # nombre -> Array de [pos, color]
	for v in data.voxels:
		var p := Vector3i(int(v[0]), int(v[1]), int(v[2]))
		all[p] = true
		var key: String = v[3] + ("#glow" if v.size() > 7 and v[7] == 1 else "")
		if not parts.has(key): parts[key] = []
		parts[key].append([p, Color(v[4], v[5], v[6])])
	var root := Node3D.new()
	root.name = "Profundo"
	root.set_meta("pivots", data.pivots)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.38   # piel húmeda
	mat.metallic_specular = 0.6
	var glow_mat := StandardMaterial3D.new()
	glow_mat.vertex_color_use_as_albedo = true
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var keys := parts.keys()
	keys.sort()   # partes base antes que sus capas "#glow"
	for key in keys:
		var pname: String = key.split("#")[0]
		var pivot := Vector3(data.pivots[pname][0], data.pivots[pname][1], data.pivots[pname][2])
		var pivot_node: Node3D = root.get_node_or_null(pname)
		if pivot_node == null:
			pivot_node = Node3D.new()
			pivot_node.name = pname
			pivot_node.position = pivot * VOXEL
			root.add_child(pivot_node)
		var mi := MeshInstance3D.new()
		mi.mesh = _build(parts[key], all, pivot)
		mi.material_override = glow_mat if key.ends_with("#glow") else mat
		pivot_node.add_child(mi)
	return root

static func _build(voxels: Array, all: Dictionary, pivot: Vector3) -> ArrayMesh:
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
				st.add_vertex((Vector3(p) + corners[i] - pivot) * VOXEL)
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
