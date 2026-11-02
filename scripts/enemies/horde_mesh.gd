class_name HordeMesh
extends RefCounted
## Hordas con instancias (hito 16.3). Un tipo de enemigo dibujado con MultiMesh: la malla es el
## modelo entero (cada vértice lleva en UV2.x el número de su parte) y las poses de todas sus
## animaciones se graban una vez en una textura, posando un modelo de verdad con las mismas
## funciones de `Anims` que mueven los nodos (no hay que reescribir ninguna animación). Por
## enemigo y fotograma solo se escribe su transformación, su fila de la textura y su tinte
## (`HordeDraw`); no hay un nodo por parte ni pose en GDScript.
##
## Además de las animaciones de su familia (`DURATION`), se graban tres más si la familia las
## tiene: `_hit` (el golpe sobre el paso), `_windup` (la preparación del ataque, de 0 a 1) y
## `_strike` (el golpe al soltar). Mientras duran, sustituyen a la animación (en los nodos se
## sumaban a ella).

const FPS := 60.0                          ## fotogramas grabados por segundo de animación
const MAX_ROWS := 120                      ## por animación (las largas, a menos fotogramas por segundo)
const WINDUP_ROWS := 16

var model_name := ""
var mesh: ArrayMesh
var anim_rows := {}                        ## animación -> [primera fila, fotogramas, duración]
var parts: Array[Node3D] = []
var height := 1.2                          ## altura del modelo en reposo (cifras de daño)
var _first: Array = []                     ## la primera animación (si piden una que no hay)

static var _types := {}                    ## modelo -> HordeMesh, o null si no se puede

## El tipo de este modelo, grabado la primera vez (o null si no tiene animaciones que grabar).
static func get_type(p_model: String) -> HordeMesh:
	if not _types.has(p_model): _types[p_model] = build(p_model)
	return _types[p_model]

static func has_type(p_model: String) -> bool:
	return _types.has(p_model)

## Graba el tipo: malla combinada y textura con las poses de todas sus animaciones.
static func build(p_model: String) -> HordeMesh:
	var s: Script = Anims.script_for(p_model)
	var path := "res://models/%s.json" % p_model
	if s == null or s.get("DURATION") == null: return null
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path): return null
	var h := HordeMesh.new()
	h.model_name = p_model
	var rig := VoxelBuilder.load_model(path)
	for p: Node3D in rig.get_meta("parts"): h.parts.append(p)
	h.mesh = _combined(rig, h.parts)
	if h.mesh == null:
		rig.free()
		return null
	h.height = maxf(0.8, h.mesh.get_aabb().end.y)
	var rows: Array = []                   # Array de Array[Transform3D] (una por parte)
	var anims: Array = (s.get("DURATION") as Dictionary).keys()
	for a: String in anims:
		var dur := Anims.duration(p_model, a)
		var n := clampi(int(round(dur * FPS)), 1, MAX_ROWS)
		h.anim_rows[a] = [rows.size(), n, dur]
		for f in n:
			Anims.pose(p_model, a, rig, f / float(n))
			rows.append(_part_transforms(rig, h.parts))
	var base := "walk" if anims.has("walk") else String(anims[0])
	if Anims.has_hit(p_model):
		var ht := Anims.hit_time(p_model, 0.6)
		var n := clampi(int(round(ht * FPS)), 2, MAX_ROWS)
		h.anim_rows["_hit"] = [rows.size(), n, ht]
		for f in n:
			Anims.pose(p_model, base, rig, 0.0)
			Anims.hit(p_model, rig, f / float(n - 1))
			rows.append(_part_transforms(rig, h.parts))
	if Anims.has_windup(p_model):
		for kind in ["_windup", "_strike"]:
			h.anim_rows[kind] = [rows.size(), WINDUP_ROWS, 1.0]
			for f in WINDUP_ROWS:
				var k := f / float(WINDUP_ROWS - 1)
				Anims.pose(p_model, base, rig, 0.0)
				Anims.windup(p_model, rig, k if kind == "_windup" else 0.0, k if kind == "_strike" else 0.0, 0.0)
				rows.append(_part_transforms(rig, h.parts))
	h._first = h.anim_rows[String(anims[0])]
	var tex := _texture(rows, h.parts.size())
	var rough := 0.9
	var spec := 0.25
	for mi: MeshInstance3D in rig.get_meta("meshes"):
		var bm := mi.material_override as StandardMaterial3D
		if bm != null and int(mi.get_meta("kind", 0)) == 0:
			rough = bm.roughness
			spec = bm.metallic_specular
			break
	for si in h.mesh.get_surface_count():
		var m := ShaderMaterial.new()
		m.shader = preload("res://scripts/enemies/horde.gdshader")
		m.set_shader_parameter("anim_tex", tex)
		m.set_shader_parameter("colors_srgb", VoxelBuilder.colors_are_srgb())
		m.set_shader_parameter("roughness_v", rough)
		m.set_shader_parameter("specular_v", spec)
		m.set_shader_parameter("glow", h.mesh.surface_get_name(si) == "glow")
		h.mesh.surface_set_material(si, m)
	rig.free()
	return h

## Fila de la textura para la animación `a` en la fase `t` (0..1).
func row(a: String, t: float) -> int:
	var r: Array = anim_rows[a] if anim_rows.has(a) else _first
	var n: int = r[1]
	return int(r[0]) + clampi(int(t * n), 0, n - 1)

func has_anim(a: String) -> bool:
	return anim_rows.has(a)

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
	mi.custom_aabb = AABB(Vector3(-200, -5, -200), Vector3(400, 20, 400))   # las partes se mueven en el shader
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return mi

## Transformación de cada parte respecto a la raíz del modelo, con lo que la animación hace a
## la raíz (balanceo, saltos) incluido.
static func _part_transforms(rig: Node3D, p_parts: Array[Node3D]) -> Array:
	var out: Array = []
	for p in p_parts:
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

## Las mallas de las partes en una, con el número de parte en UV2.x: una superficie con la capa
## normal y, si hay, otra («glow») con las luces (ojos, faroles), sin sombreado.
static func _combined(rig: Node3D, p_parts: Array[Node3D]) -> ArrayMesh:
	var m := ArrayMesh.new()
	for glow in [false, true]:
		var verts := PackedVector3Array()
		var norms := PackedVector3Array()
		var cols := PackedColorArray()
		var uv2 := PackedVector2Array()
		var idx := PackedInt32Array()
		for mi: MeshInstance3D in rig.get_meta("meshes"):
			var kind := int(mi.get_meta("kind", 0))
			if kind > 1 or (kind == 1) != glow or mi.mesh == null: continue
			var pi := p_parts.find(mi.get_parent() as Node3D)
			if pi < 0: continue
			var arr := mi.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if v.is_empty(): continue
			var base := verts.size()
			verts.append_array(v)
			norms.append_array(arr[Mesh.ARRAY_NORMAL])
			cols.append_array(arr[Mesh.ARRAY_COLOR])
			var u := PackedVector2Array()
			u.resize(v.size())
			u.fill(Vector2(pi, 0))
			uv2.append_array(u)
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if ix.is_empty():
				for k in v.size(): idx.append(base + k)
			else:
				for k in ix: idx.append(base + k)
		if verts.is_empty(): continue
		var a := []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = verts
		a[Mesh.ARRAY_NORMAL] = norms
		a[Mesh.ARRAY_COLOR] = cols
		a[Mesh.ARRAY_TEX_UV2] = uv2
		a[Mesh.ARRAY_INDEX] = idx
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		m.surface_set_name(m.get_surface_count() - 1, "glow" if glow else "body")
	return m if m.get_surface_count() > 0 else null

## Un tipo en pantalla, repartido por celdas de `CELL` m: cada celda, su MultiMesh con una caja
## fija (la celda y lo que mide el modelo). Con una sola caja para todos, cada luz con sombra (la
## luna en sus cascadas, los faroles en sus seis caras) los dibujaba todos: cinco veces más
## triángulos; con celdas de 3 m, el doble de dibujos que con nodos. Cada enemigo tiene su plaza en
## la celda en la que está (`Enemy.horde_cell` y `horde_slot`) y escribe la suya en la copia de la
## celda; al cambiar de celda o irse, el último de la celda pasa a su hueco. Una vez por fotograma
## (`flush`), cada celda sube su copia entera: con `set_instance_transform`, Godot leía de la GPU
## el búfer de cada MultiMesh nuevo y el de cada hueco que se movía, y eso eran tirones.
class Layer:
	const CELL := 6.0
	var horde: HordeMesh
	var parent: Node
	var margin: AABB
	var _cells := {}                     ## Vector2i -> Cell
	var _lift := 0.0                     ## lo más alto que ha ido uno (los que vuelan o saltan)

	func _init(p_horde: HordeMesh, p_parent: Node) -> void:
		horde = p_horde
		parent = p_parent
		var b := horde.mesh.get_aabb()
		# lo que mide el modelo (hasta 1,5 de escala) y un poco de holgura por lo que se mueve
		margin = AABB(b.position * 1.5 - Vector3(0.3, 0.5, 0.3), b.size * 1.5 + Vector3(0.6, 0.8, 0.6))

	func _box(c: Vector2i) -> AABB:
		return AABB(Vector3(c.x * CELL, 0.0, c.y * CELL) + margin.position, Vector3(CELL, _lift, CELL) + margin.size)

	## Coloca al enemigo: transformación y (fila, color del tinte empaquetado, alfa, 0).
	func place(e: Object, t: Transform3D, custom: Color) -> void:   # Enemy (o lo que tenga horde_cell y horde_slot)
		var c := Vector2i(floori(t.origin.x / CELL), floori(t.origin.z / CELL))
		if t.origin.y > _lift:                         # alguien vuela más alto: cajas más altas
			_lift = t.origin.y + 0.5
			for k: Vector2i in _cells: (_cells[k] as Cell).mmi.custom_aabb = _box(k)
		if e.horde_slot < 0 or c != e.horde_cell:
			if e.horde_slot >= 0: remove(e)
			var cell: Cell = _cells.get(c)
			if cell == null:
				cell = Cell.new(horde.multimesh(0), _box(c))
				parent.add_child(cell.mmi)
				_cells[c] = cell
			e.horde_cell = c
			e.horde_slot = cell.add(e)
		(_cells[c] as Cell).write(e.horde_slot, t, custom)

	func remove(e: Object) -> void:
		if e.horde_slot < 0 or not _cells.has(e.horde_cell): return
		(_cells[e.horde_cell] as Cell).take(e.horde_slot)
		e.horde_slot = -1

	## Sube lo de este fotograma (una vez, después de todos los enemigos).
	func flush() -> void:
		for c: Vector2i in _cells: (_cells[c] as Cell).flush()

	func count() -> int:
		var n := 0
		for c: Vector2i in _cells: n += (_cells[c] as Cell).owners.size()
		return n

## Una celda: su MultiMesh, quién ocupa cada plaza y la copia del búfer (16 números por plaza:
## la transformación en tres filas y el dato propio). La copia se toca solo desde aquí dentro:
## un PackedFloat32Array cambiado desde fuera (`cell.buf[i] = x`) se copia entero cada vez.
class Cell:
	var mmi: MultiMeshInstance3D
	var owners: Array = []
	var buf := PackedFloat32Array()
	var _shown := -1

	func _init(p_mmi: MultiMeshInstance3D, box: AABB) -> void:
		mmi = p_mmi
		mmi.custom_aabb = box

	func add(e: Object) -> int:
		owners.append(e)
		if buf.size() < owners.size() * 16: buf.resize(maxi(8, nearest_po2(owners.size())) * 16)
		return owners.size() - 1

	func write(i: int, t: Transform3D, d: Color) -> void:
		var w := i * 16
		var b := t.basis
		buf[w] = b.x.x; buf[w + 1] = b.y.x; buf[w + 2] = b.z.x; buf[w + 3] = t.origin.x
		buf[w + 4] = b.x.y; buf[w + 5] = b.y.y; buf[w + 6] = b.z.y; buf[w + 7] = t.origin.y
		buf[w + 8] = b.x.z; buf[w + 9] = b.y.z; buf[w + 10] = b.z.z; buf[w + 11] = t.origin.z
		buf[w + 12] = d.r; buf[w + 13] = d.g; buf[w + 14] = d.b; buf[w + 15] = d.a

	## Deja la plaza `i`: el último pasa a ella.
	func take(i: int) -> void:
		var last := owners.size() - 1
		if i != last and last >= 0:
			var other: Object = owners[last]
			for k in 16: buf[i * 16 + k] = buf[last * 16 + k]
			owners[i] = other
			if is_instance_valid(other): other.horde_slot = i
		owners.pop_back()

	func flush() -> void:
		var mm := mmi.multimesh
		var n := owners.size()
		if n == 0:
			if _shown != 0:
				mm.visible_instance_count = 0
				_shown = 0
			return
		if mm.instance_count * 16 != buf.size(): mm.instance_count = buf.size() / 16
		mm.buffer = buf
		if _shown != n:
			mm.visible_instance_count = n
			_shown = n
