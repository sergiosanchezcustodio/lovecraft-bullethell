class_name Stab
extends Node3D
## Puñalada de la Daga ritual (hoja violeta) o estocada del bastón estoque (hoja de acero
## más larga): sale del personaje hacia el enemigo, entra y se desvanece. Solo visual: el
## daño lo aplica el arma.

var _from := Vector3.ZERO
var _dir := Vector3.FORWARD
var _reach := 1.0
var _t := 0.0
var _blade: MeshInstance3D
var _mat: StandardMaterial3D
var color := Color(0.55, 0.25, 0.75, 0.95)
var blade := 0.6

const LIFE := 0.2

func setup(from: Vector3, to: Vector3) -> Stab:
	_from = Vector3(from.x, 0.9, from.z)
	var d := Vector3(to.x - from.x, 0, to.z - from.z)
	_reach = maxf(d.length() - 0.2, 0.3)
	_dir = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	_blade = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.05, blade)
	_blade.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = color
	_blade.material_override = _mat
	_blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blade)
	_process(0.0)

func _process(delta: float) -> void:
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	var go := 1.0 - pow(1.0 - minf(u * 1.8, 1.0), 3.0)               # sale rápida y se clava
	global_position = _from + _dir * (0.3 + _reach * go)
	look_at(global_position + _dir, Vector3.UP)
	_mat.albedo_color.a = color.a * (1.0 - smoothstep(0.55, 1.0, u))
	if _t >= LIFE: queue_free()
