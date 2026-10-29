class_name Debris
extends MultiMeshInstance3D
## Restos que se quedan en el suelo (hito 12.11, 29-10-2026): al romperse una vasija o una caja de
## suministros quedan astillas y tiestos de sus colores tirados alrededor, que a los LIFE s se
## hunden y desaparecen. Un solo MultiMesh con tope (`limit`, de la calidad gráfica: el de las
## manchas por PER_MARK): la más vieja deja sitio a la nueva.

const LIFE := 22.0
const SINK := 2.5                              ## s del final en los que se encoge
const APPEAR := 0.35                           ## s hasta que caen (antes saltan los trozos del DeathBurst)
const PER_MARK := 8
static var limit := 24 * PER_MARK

var _age := PackedFloat32Array()
var _xf: Array[Transform3D] = []
var _live := 0
var _next := 0
var _max := 0

## `n` restos alrededor de `pos` (en un radio `r`), de los colores `palette`.
static func scatter(parent: Node, pos: Vector3, palette: Array, n := 10, r := 0.45) -> void:
	if parent == null or limit <= 0 or palette.is_empty(): return
	var d: Debris = parent.get_meta("debris") if parent.has_meta("debris") else null
	if d == null or not is_instance_valid(d):
		d = Debris.new()
		d.name = "Debris"
		parent.add_child(d)
		parent.set_meta("debris", d)
	for i in n:
		var a := randf() * TAU
		var dist := sqrt(randf()) * r
		var p := Vector3(pos.x + cos(a) * dist, 0.0, pos.z + sin(a) * dist)
		var c: Color = palette[randi() % palette.size()]
		d._add(p, c.darkened(randf() * 0.25))

func _ready() -> void:
	_setup()

func _setup() -> void:
	if multimesh != null: return
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	_max = maxi(limit, 1)
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	m.roughness = 0.9
	bm.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = bm
	mm.instance_count = _max
	for i in _max: mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	multimesh = mm
	_age.resize(_max)
	_age.fill(-1.0)
	_xf.resize(_max)

func _add(pos: Vector3, c: Color) -> void:
	_setup()
	var i := _next
	_next = (_next + 1) % _max
	if _age[i] < 0.0: _live += 1
	_age[i] = 0.0
	# astilla o tiesto: plano, alargado y algo ladeado, a ras de suelo
	var size := Vector3(randf_range(0.04, 0.08), randf_range(0.015, 0.03), randf_range(0.06, 0.13))
	var b := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(-0.25, 0.25))
	_xf[i] = Transform3D(b * Basis.from_scale(size), Vector3(pos.x, pos.y + 0.045 + size.y * 0.5, pos.z))
	multimesh.set_instance_color(i, c)
	multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))

func _process(delta: float) -> void:
	if _live == 0: return
	for i in _max:
		if _age[i] < 0.0: continue
		var was := _age[i]
		_age[i] += delta
		var t := _age[i]
		if t >= LIFE:
			_age[i] = -1.0
			_live -= 1
			multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		elif was < APPEAR and t >= APPEAR:
			multimesh.set_instance_transform(i, _xf[i])
		elif t > LIFE - SINK:
			var k := (LIFE - t) / SINK
			var x := _xf[i]
			multimesh.set_instance_transform(i, Transform3D(x.basis.scaled(Vector3(k, k, k)), x.origin))

func count() -> int:
	return _live
