class_name WhipFx
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Latigazo (Látigo, hito 8.8): una tralla de cubos de cuero que barre el sector de un lado a
## otro en una décima de segundo y se apaga. Solo visual: el daño lo aplica el arma.

var dir := Vector3.FORWARD
var length := 4.5
var half := 0.6                              ## medio sector (rad)
var _t := 0.0
var _bits: Array[MeshInstance3D] = []

const LIFE := 0.24
const SEGMENTS := 14

## Se anima en _process con la raíz quieta: sin interpolación de la física, que avisaba
## («Interpolated instance triggered from outside physics process», 06-11-2026).
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func setup(origin: Vector3, p_dir: Vector3, p_length: float, spread_deg: float) -> WhipFx:
	position = Vector3(origin.x, 0.9, origin.z)
	dir = Vector3(p_dir.x, 0, p_dir.z).normalized()
	length = p_length
	half = deg_to_rad(spread_deg) * 0.5
	return self

## Malla de los trozos del látigo, con su material, compartida (06-11-2026: antes, nueva en cada latigazo).
static var _bm: BoxMesh

func _ready() -> void:
	if _bm == null:
		_bm = BoxMesh.new()
		_bm.size = Vector3.ONE * 0.11
		var mat := VoxelFx.std()
		mat.albedo_color = Color(0.32, 0.2, 0.12)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.75, 0.5)
		mat.emission_energy_multiplier = 0.25
		_bm.material = mat
	var bm := _bm
	for i in SEGMENTS:
		var mi := MeshInstance3D.new()
		mi.mesh = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_bits.append(mi)
	_process(0.0)

func _process(delta: float) -> void:
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	var sweep := lerpf(-half, half, smoothstep(0.0, 0.8, u))        # barre de un lado a otro
	for i in SEGMENTS:
		var k := float(i + 1) / SEGMENTS
		var a := sweep * (0.4 + 0.6 * k) - sweep * 0.25 * (1.0 - k)  # la punta va por detrás: curva
		var d := dir.rotated(Vector3.UP, a)
		_bits[i].position = d * length * k + Vector3(0, -0.35 * k * k, 0)
		_bits[i].scale = Vector3.ONE * lerpf(1.3, 0.6, k) * (1.0 - smoothstep(0.75, 1.0, u))
	if _t >= LIFE: queue_free()
