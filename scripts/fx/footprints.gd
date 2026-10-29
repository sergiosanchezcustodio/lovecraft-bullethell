class_name Footprints
extends MultiMeshInstance3D
## Huellas en el suelo (hito 11.8, 28-10-2026): de los jugadores y de los enemigos, en la nieve,
## en el barro y, al salir del agua, mojadas sobre la piedra o las tablas, que se secan. Un solo
## MultiMesh con tope (MAX): la más vieja deja sitio a la nueva. Cada huella se desvanece al
## final de su vida. Las pone Ambient.

const MAX := 192
const FADE := 3.0                              ## s del final en los que se desvanece
## clase: [color, opacidad, vida en s]
const KINDS := {
	"snow": [Color(0.42, 0.48, 0.58), 0.45, 10.0],
	"mud": [Color(0.05, 0.04, 0.03), 0.62, 14.0],
	"wet": [Color(0.03, 0.035, 0.05), 0.5, 4.0],
}

var _age := PackedFloat32Array()
var _life := PackedFloat32Array()              ## 0: hueco libre
var _alpha := PackedFloat32Array()
var _col: Array[Color] = []
var _next := 0
var _live := 0

## Huella en `pos` (el suelo), girada `yaw`, de `size` m (ancho, largo). `strength` escala la
## opacidad (las mojadas, según lo que se han secado).
static func add(parent: Node, pos: Vector3, yaw: float, size: Vector2, kind: String, strength := 1.0) -> void:
	if parent == null or not KINDS.has(kind) or strength <= 0.0: return
	var fp: Footprints = parent.get_meta("footprints") if parent.has_meta("footprints") else null
	if fp == null or not is_instance_valid(fp):
		fp = Footprints.new()
		fp.name = "Footprints"
		parent.add_child(fp)
		parent.set_meta("footprints", fp)
	fp._add(pos, yaw, size, kind, strength)

func _ready() -> void:
	_setup()

func _setup() -> void:
	if multimesh != null: return
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.008, 1.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	bm.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = bm
	mm.instance_count = MAX
	for i in MAX: mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	multimesh = mm
	_age.resize(MAX); _life.resize(MAX); _alpha.resize(MAX)
	_col.resize(MAX)

func _add(pos: Vector3, yaw: float, size: Vector2, kind: String, strength: float) -> void:
	_setup()
	var k: Array = KINDS[kind]
	var i := _next
	_next = (_next + 1) % MAX
	if _life[i] <= 0.0: _live += 1
	_age[i] = 0.0
	_life[i] = float(k[2])
	_alpha[i] = float(k[1]) * clampf(strength, 0.0, 1.0)
	_col[i] = k[0]
	var b := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(size.x, 1.0, size.y))   # escala en la huella, no en el mundo (con scaled se torcían)
	multimesh.set_instance_transform(i, Transform3D(b, Vector3(pos.x, pos.y + 0.04, pos.z)))   # como las manchas (VoxelFx.ground): el suelo de algunas arenas pasa de 0
	multimesh.set_instance_color(i, Color(_col[i], _alpha[i]))

func _process(delta: float) -> void:
	if _live == 0: return
	for i in MAX:
		if _life[i] <= 0.0: continue
		_age[i] += delta
		var left := _life[i] - _age[i]
		if left <= 0.0:
			_life[i] = 0.0
			_live -= 1
			multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		elif left < FADE:
			multimesh.set_instance_color(i, Color(_col[i], _alpha[i] * left / FADE))

func count() -> int:
	return _live
