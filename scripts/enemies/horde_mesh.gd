class_name HordeMesh
extends RefCounted
## Hordas con instancias (hito 16.3, prototipo). Un tipo de enemigo dibujado con un solo
## MultiMesh: la malla es el modelo entero (cada vértice sabe de qué parte es) y las poses de sus
## animaciones se graban una vez en una textura, posando un modelo de verdad con las mismas
## funciones de `Anims` que mueven los nodos. Así no hay un nodo por parte ni por enemigo, ni
## pose en GDScript cada fotograma: por enemigo solo se escribe su transformación y su fila.

const FPS := 30.0                          ## fotogramas grabados por segundo de animación

var model_name := ""
var mesh: ArrayMesh
var material: ShaderMaterial
var anim_rows := {}                        ## animación -> [primera fila, fotogramas, duración]
var parts: Array[Node3D] = []
var _first: Array = []                     ## la primera animación (si piden una que no hay)

## Graba el tipo: malla combinada y textura de poses de `anims`.
static func build(p_model: String, anims: Array[String]) -> HordeMesh:
	var h := HordeMesh.new()
	h.model_name = p_model
	var rig := VoxelBuilder.load_model("res://models/%s.json" % p_model)
	# las partes que llevan malla (y las vacías que hacen de articulación) en orden fijo
	for p: Node3D in rig.get_meta("parts"): h.parts.append(p)
	h.mesh = _combined(rig, h.parts)
	var rows: Array = []                   # Array de Array[Transform3D] (una por parte)
	for a in anims:
		var dur := Anims.duration(p_model, a)
		var n := maxi(1, int(round(dur * FPS)))
		h.anim_rows[a] = [rows.size(), n, dur]
		for f in n:
			Anims.pose(p_model, a, rig, f / float(n))
			rows.append(_part_transforms(rig, h.parts))
	h._first = h.anim_rows[anims[0]]
	h.material = ShaderMaterial.new()
	h.material.shader = preload("res://scripts/enemies/horde.gdshader")
	h.material.set_shader_parameter("anim_tex", _texture(rows, h.parts.size()))
	h.material.set_shader_parameter("colors_srgb", VoxelBuilder.colors_are_srgb())
	var base := (rig.get_meta("meshes")[0] as MeshInstance3D).material_override as StandardMaterial3D
	if base != null:
		h.material.set_shader_parameter("roughness_v", base.roughness)
		h.material.set_shader_parameter("specular_v", base.metallic_specular)
	rig.free()
	return h

## Fila de la textura para la animación `a` en la fase `t` (0..1).
func row(a: String, t: float) -> int:
	var r: Array = anim_rows[a] if anim_rows.has(a) else _first
	var n: int = r[1]
	return int(r[0]) + clampi(int(t * n), 0, n - 1)

func duration(a: String) -> float:
	var r: Array = anim_rows[a] if anim_rows.has(a) else _first
	return float(r[2])

## Un MultiMesh de este tipo para `count` enemigos.
func multimesh(count: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = material
	mi.custom_aabb = AABB(Vector3(-200, -5, -200), Vector3(400, 20, 400))   # las partes se mueven en el shader
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return mi

## Transformación de cada parte respecto a la raíz del modelo, con lo que la animación hace a
## la raíz (balanceo, saltos) incluido.
static func _part_transforms(rig: Node3D, parts: Array[Node3D]) -> Array:
	var out: Array = []
	for p in parts:
		var t := p.transform
		var up := p.get_parent() as Node3D
		while up != null and up != rig:
			t = up.transform * t
			up = up.get_parent() as Node3D
		out.append(rig.transform * t)
	return out

static func _texture(rows: Array, nparts: int) -> ImageTexture:
	var img := Image.create(nparts * 3, rows.size(), false, Image.FORMAT_RGBAF)
	for y in rows.size():
		var ts: Array = rows[y]
		for i in nparts:
			var t: Transform3D = ts[i]
			var b := t.basis
			img.set_pixel(i * 3, y, Color(b.x.x, b.y.x, b.z.x, t.origin.x))
			img.set_pixel(i * 3 + 1, y, Color(b.x.y, b.y.y, b.z.y, t.origin.y))
			img.set_pixel(i * 3 + 2, y, Color(b.x.z, b.y.z, b.z.z, t.origin.z))
	return ImageTexture.create_from_image(img)

## Todas las mallas de las partes en una (solo la capa normal; las de luz, aparte si hiciera falta),
## con el número de parte en UV2.x.
static func _combined(rig: Node3D, parts: Array[Node3D]) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uv2 := PackedVector2Array()
	var idx := PackedInt32Array()
	for mi: MeshInstance3D in rig.get_meta("meshes"):
		if int(mi.get_meta("kind", 0)) != 0: continue
		var pi := parts.find(mi.get_parent() as Node3D)
		if pi < 0: continue
		var arr := mi.mesh.surface_get_arrays(0)
		var base := verts.size()
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		verts.append_array(v)
		norms.append_array(arr[Mesh.ARRAY_NORMAL])
		cols.append_array(arr[Mesh.ARRAY_COLOR])
		for k in v.size(): uv2.append(Vector2(pi, 0))
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if ix.is_empty():
			for k in v.size(): idx.append(base + k)
		else:
			for k in ix: idx.append(base + k)
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = verts
	a[Mesh.ARRAY_NORMAL] = norms
	a[Mesh.ARRAY_COLOR] = cols
	a[Mesh.ARRAY_TEX_UV2] = uv2
	a[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return m

## Un tipo en pantalla, repartido por celdas de `CELL` m: cada celda, su MultiMesh con la caja
## ajustada a los suyos. Con una sola caja para todos, cada luz con sombra (la luna en sus
## cascadas, los faroles en sus seis caras) los dibujaba todos: cinco veces más triángulos.
## Uso por fotograma: `add` de cada enemigo y `commit`.
class Layer:
	const CELL := 3.0
	var horde: HordeMesh
	var parent: Node
	var margin: AABB
	var _cells := {}                     ## Vector2i -> MultiMeshInstance3D
	var _xf: Array[Transform3D] = []     ## lo de este fotograma
	var _row := PackedFloat32Array()
	var _flash := PackedFloat32Array()

	func _init(p_horde: HordeMesh, p_parent: Node) -> void:
		horde = p_horde
		parent = p_parent
		margin = horde.mesh.get_aabb().grow(0.5)

	func add(t: Transform3D, row: int, flash := 0.0) -> void:
		_xf.append(t)
		_row.append(row)
		_flash.append(flash)

	func commit() -> void:
		var groups := {}                 # celda -> Array de índices (los Array no se copian al tocarlos)
		for k in _xf.size():
			var o := _xf[k].origin
			var c := Vector2i(floori(o.x / CELL), floori(o.z / CELL))
			if not groups.has(c): groups[c] = []
			(groups[c] as Array).append(k)
		for c: Vector2i in _cells:
			if not groups.has(c): (_cells[c] as MultiMeshInstance3D).multimesh.visible_instance_count = 0
		for c: Vector2i in groups:
			var ids: Array = groups[c]
			var n := ids.size()
			var mmi: MultiMeshInstance3D = _cells.get(c)
			if mmi == null:
				mmi = horde.multimesh(0)
				parent.add_child(mmi)
				_cells[c] = mmi
			var mm := mmi.multimesh
			if mm.instance_count < n: mm.instance_count = maxi(8, nearest_po2(n))
			var b := PackedFloat32Array()
			b.resize(mm.instance_count * 16)
			var box := AABB(_xf[ids[0]].origin, Vector3.ZERO)
			var w := 0
			for k: int in ids:
				var t := _xf[k]
				var bs := t.basis
				b[w] = bs.x.x; b[w + 1] = bs.y.x; b[w + 2] = bs.z.x; b[w + 3] = t.origin.x
				b[w + 4] = bs.x.y; b[w + 5] = bs.y.y; b[w + 6] = bs.z.y; b[w + 7] = t.origin.y
				b[w + 8] = bs.x.z; b[w + 9] = bs.y.z; b[w + 10] = bs.z.z; b[w + 11] = t.origin.z
				b[w + 12] = _row[k]; b[w + 13] = _flash[k]
				w += 16
				box = box.expand(t.origin)
			mm.buffer = b
			mm.visible_instance_count = n
			mmi.custom_aabb = AABB(box.position + margin.position, box.size + margin.size)
		_xf.clear()
		_row.resize(0)
		_flash.resize(0)
