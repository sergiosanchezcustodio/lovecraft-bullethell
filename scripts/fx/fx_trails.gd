class_name FxTrails
extends Node3D
## Estelas de las armas (hito 18.1, D-50): una cinta que sigue a lo que se mueve (bumerán, lo que se
## lanza, las páginas, los drones), con el degradado de su receta de la cabeza a la cola en tramos y
## el ancho que se estrecha a saltos de píxel grande (voxel). Todas las del nivel van en una sola
## tira de triángulos que se rehace cada fotograma (una para las aditivas y otra para las de humo):
## dos llamadas de dibujo y ningún nodo por estela. Dos vértices por punto; las franjas de los bordes,
## más tenues, las pinta el sombreador (`fx_trail.gdshaderinc`). Con ImmediateMesh y seis vértices por
## punto costaba 2 ms con cuatro armas. Cuando lo que sigue desaparece, la cola se apaga sola.
## Recetas en `data/weapon_fx.json` (`trails`). Por calidad: `weapon_fx` 0 (Baja), sin estelas;
## 1 (Media), más cortas. `trails=false` para comparar.

const MAX_POINTS := 18
const MAX_TOTAL := 900                     ## puntos de todas las estelas por fotograma, como mucho
const MIN_STEP := 0.12                     ## m entre puntos (la cabeza va siempre con lo que sigue)
const STEP := 0.0625                       ## el ancho va a saltos de dos voxels
const CORE := 0.4                          ## parte del ancho que es el centro brillante
const EDGE_ALPHA := 0.35                   ## los bordes, con este tanto de su opacidad

static var enabled := true
static var _inst: FxTrails
static var _recipes := {}
static var _add_mat: ShaderMaterial
static var _mix_mat: ShaderMaterial

var _trails: Array[Dictionary] = []
var _add_mesh := ArrayMesh.new()
var _mix_mesh := ArrayMesh.new()
var _vs := PackedVector3Array()
var _cs := PackedColorArray()
var _uv := PackedVector2Array()

## Sigue a `target` con la receta `recipe`. `tint` multiplica sus colores y `width` su ancho.
static func attach(target: Node3D, recipe: String, tint := Color.WHITE, width := 1.0) -> void:
	if not enabled or not is_instance_valid(target) or not target.is_inside_tree(): return
	var lv := int(Quality.value("weapon_fx", 2))
	if lv <= 0: return
	var r := recipe_of(recipe)
	if r.is_empty(): return
	var t := of(target.get_tree())
	if t == null: return
	var acc := FxAccent.of(Damage.ctx)                 # evoluciones (hito 18.14): más anchas y teñidas
	if not acc.is_empty():
		tint = tint * (acc["tint"] as Color)
		width *= float(acc["width"])
	t._trails.append(_new_trail(weakref(target), r, tint, float(r.get("width", 0.2)) * width,
		float(r.get("life", 0.25)) * (0.6 if lv == 1 else 1.0)))

## Una estela: sus colores y medios anchos por tramo, ya calculados (el último, el de la cola).
static func _new_trail(node: Variant, r: Dictionary, tint: Color, w0: float, life: float) -> Dictionary:
	var bands := maxi(int(r.get("bands", 4)), 1)
	var cols := PackedColorArray()
	var hws := PackedFloat32Array()
	for b in bands + 1:
		var f := minf(float(b) / bands, 1.0)
		cols.append(Flashes.color(_sample(r._ramp, f) * tint))   # alto contraste (19.5): hacia el gris
		hws.append(maxf(snappedf(w0 * (1.0 - f * 0.85), STEP), STEP) * 0.5)
	var st := float(r.get("min_step", MIN_STEP))
	return {"node": node, "life": life, "add": bool(r.get("add", true)), "cols": cols, "hws": hws,
		"step2": st * st, "pts": PackedVector3Array(), "ts": PackedFloat64Array()}

## La de este nivel (cuelga de la escena: se va con ella).
static func of(tree: SceneTree) -> FxTrails:
	if is_instance_valid(_inst) and _inst.is_inside_tree(): return _inst
	if tree == null or tree.current_scene == null: return null
	_inst = FxTrails.new()
	_inst.name = "FxTrails"
	tree.current_scene.add_child(_inst)
	return _inst

static func recipe_of(id: String) -> Dictionary:
	if _recipes.is_empty():
		var f := FileAccess.open("res://data/weapon_fx.json", FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary: _recipes = (d as Dictionary).get("trails", {})
	var r: Dictionary = _recipes.get(id, {})
	if r.is_empty(): return r
	if not r.has("_ramp"):                           # los colores, ya leídos
		var cs: Array[Color] = []
		for c in r.get("colors", ["#ffffffff", "#ffffff00"]): cs.append(Color.html(String(c)))
		r["_ramp"] = cs
	return r

## Calentamiento (LevelWarmup): una estela casi transparente de cada tipo de mezcla en `at`, un momento
## (en la vista, como lo demás del calentamiento: bajo el suelo le faltan pasadas).
static func prime(tree: SceneTree, at: Vector3) -> void:
	var t := of(tree)
	if t == null: return
	var now := Time.get_ticks_msec() / 1000.0
	for id in ["spin", "smoke"]:
		var r := recipe_of(id)
		if r.is_empty(): continue
		var tr := _new_trail(null, r, Color(1, 1, 1, 1.0 / 255.0), 0.2, 0.3)
		tr.pts = PackedVector3Array([at, at + Vector3(0.5, 0, 0)])
		tr.ts = PackedFloat64Array([now, now])
		t._trails.append(tr)

func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true

func _ready() -> void:
	if _add_mat == null:
		_add_mat = _make_mat(true)
		_mix_mat = _make_mat(false)
	for mesh in [_add_mesh, _mix_mesh]:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(-500, -50, -500), Vector3(1000, 100, 1000))   # se rehace: que no la recorte
		mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(mi)

static func _make_mat(add: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/fx/fx_trail_add.gdshader" if add else "res://scripts/fx/fx_trail_mix.gdshader")
	m.set_shader_parameter("core", CORE)
	m.set_shader_parameter("edge_alpha", EDGE_ALPHA)
	return m

func _process(_delta: float) -> void:
	var t0 := Prof.start()
	var now := Time.get_ticks_msec() / 1000.0
	var cam := get_viewport().get_camera_3d()
	var fwd := -cam.global_basis.z if cam != null else Vector3(0, -1, 0)
	var draw_add: Array[Dictionary] = []
	var draw_mix: Array[Dictionary] = []
	var budget := MAX_TOTAL
	var i := 0
	while i < _trails.size():
		var tr: Dictionary = _trails[i]
		var life: float = tr.life
		var pts: PackedVector3Array = tr.pts
		var ts: PackedFloat64Array = tr.ts
		var n: Node3D = (tr.node as WeakRef).get_ref() if tr.node != null else null
		if n == null: tr.node = null                      # se fue: la cola se apaga sola
		elif n.is_inside_tree() and n.is_visible_in_tree():   # la cabeza, donde se dibuja (escondido, espera)
			var p := n.get_global_transform_interpolated().origin
			if pts.size() < 2 or pts[1].distance_squared_to(p) >= tr.step2:
				pts.insert(0, p)                          # un punto nuevo
				ts.insert(0, now)
				if pts.size() > MAX_POINTS:
					pts.resize(MAX_POINTS)
					ts.resize(MAX_POINTS)
			else:
				pts[0] = p                                # se mueve poco: la cabeza va con él
				ts[0] = now
		while ts.size() > 0 and now - ts[ts.size() - 1] > life:   # la cola, que se apaga
			pts.resize(pts.size() - 1)
			ts.resize(ts.size() - 1)
		tr.pts = pts
		tr.ts = ts
		if pts.size() < 2:
			if tr.node == null:
				_trails.remove_at(i)
				continue
			i += 1
			continue
		if budget >= pts.size():
			budget -= pts.size()
			(draw_add if tr.add else draw_mix).append(tr)
		i += 1
	_build(_add_mesh, draw_add, _add_mat, now, fwd)
	_build(_mix_mesh, draw_mix, _mix_mat, now, fwd)
	Prof.stop("estelas", t0)

## Todas las estelas de una mezcla en una tira de triángulos: dos vértices por punto y, entre una
## estela y la siguiente, dos vértices repetidos (triángulos vacíos, que no se ven).
func _build(mesh: ArrayMesh, list: Array[Dictionary], mat: Material, now: float, fwd: Vector3) -> void:
	mesh.clear_surfaces()
	if list.is_empty(): return
	_vs.clear(); _cs.clear(); _uv.clear()
	for tr in list: _strip(tr, now, fwd)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _vs
	arr[Mesh.ARRAY_COLOR] = _cs
	arr[Mesh.ARRAY_TEX_UV] = _uv
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr)
	mesh.surface_set_material(0, mat)

## El color y el ancho de cada punto van a escalones según su edad (`bands`, tabla hecha al crear la
## estela): el degradado a lo largo también es escalonado.
func _strip(tr: Dictionary, now: float, fwd: Vector3) -> void:
	var pts: PackedVector3Array = tr.pts
	var ts: PackedFloat64Array = tr.ts
	var cols: PackedColorArray = tr.cols
	var hws: PackedFloat32Array = tr.hws
	var bands: int = cols.size() - 1
	var k_age: float = bands / float(tr.life)
	var m := pts.size()
	var seam := not _vs.is_empty()
	for k in m:
		var d := (pts[k + 1] - pts[k]) if k < m - 1 else (pts[k] - pts[k - 1])
		var side := d.cross(fwd).normalized()
		var b := mini(int((now - ts[k]) * k_age), bands)
		var so := side * hws[b]
		var p := pts[k]
		if seam:                                      # costura con la anterior: dos vértices repetidos
			_vs.append(_vs[_vs.size() - 1]); _cs.append(Color(0, 0, 0, 0)); _uv.append(Vector2.ZERO)
			_vs.append(p - so); _cs.append(Color(0, 0, 0, 0)); _uv.append(Vector2.ZERO)
			seam = false
		_vs.append(p - so); _vs.append(p + so)
		_cs.append(cols[b]); _cs.append(cols[b])
		_uv.append(Vector2(0, 0)); _uv.append(Vector2(0, 1))

static func _sample(ramp: Array, x: float) -> Color:
	if ramp.size() == 1: return ramp[0]
	var f := x * (ramp.size() - 1)
	var i := mini(int(f), ramp.size() - 2)
	return (ramp[i] as Color).lerp(ramp[i + 1], f - i)
