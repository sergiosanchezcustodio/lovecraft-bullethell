class_name CurseJump
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Maldición de la Daga ritual que salta de un enemigo muerto a otro: un arco violeta que
## vuela del uno al otro y se apaga. Solo visual: la maldición ya se ha aplicado.

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _bits: Array[MeshInstance3D] = []

const LIFE := 0.35
const N := 6

func setup(from: Vector3, to: Vector3) -> CurseJump:
	_from = from + Vector3(0, 0.8, 0)
	_to = to + Vector3(0, 0.8, 0)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.5, 0.15, 0.7, 0.9)
	for i in N:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE * 0.12
		mi.mesh = bm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_bits.append(mi)
	_process(0.0)

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	for i in N:
		var s := clampf(u * 1.6 - float(i) / N * 0.6, 0.0, 1.0)      # un reguero que avanza
		var p := _from.lerp(_to, s)
		p.y += sin(s * PI) * 0.9
		_bits[i].global_position = p
		_bits[i].scale = Vector3.ONE * (1.0 - u) * (1.0 - float(i) / N * 0.5)
	if _t >= LIFE: queue_free()
