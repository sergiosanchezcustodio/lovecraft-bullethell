class_name Beam
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Rayo del Trapezoedro Resplandeciente: una columna de luz concentrada, rojiza y dorada,
## que se enciende en un instante y se apaga. Solo visual: el daño lo aplica el arma.

var _life := 0.3
var _t := 0.0
var _core: MeshInstance3D
var _glow: MeshInstance3D
var _mat_core: StandardMaterial3D
var _mat_glow: StandardMaterial3D
var _light: OmniLight3D

## `core` y `glow` cambian los colores (rayo del Mini-Mi-Go); por defecto, los del Trapezoedro.
func setup(origin: Vector3, dir: Vector3, length: float, half_width: float, life: float,
		core := Color(1.0, 0.72, 0.40, 0.95), glow := Color(0.95, 0.30, 0.18, 0.45)) -> void:
	_life = maxf(life, 0.1)
	position = origin + dir * length * 0.5
	rotation.y = atan2(dir.x, dir.z)
	# núcleo opaco (sobre la nieve, un rayo aditivo casi no se ve) y halo rojizo aditivo
	# (el núcleo, sin atenuar y saturado: con el brillo de la nieve no se distinguía de ella)
	_core = _bar(Vector3(half_width * 0.8, half_width * 0.8, length), core, false, 1.0)
	_mat_core = _core.material_override
	_glow = _bar(Vector3(half_width * 2.2, half_width * 2.2, length), glow, true, 0.6)
	_mat_glow = _glow.material_override
	_light = OmniLight3D.new()
	_light.light_color = Color(glow.r, glow.g, glow.b)
	_light.light_energy = 2.0
	_light.omni_range = 4.0
	add_child(_light)

func _bar(size: Vector3, c: Color, additive: bool, k: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive: m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(c.r * k, c.g * k, c.b * k, c.a)     # k < 1: el tonemapper quemaría el halo
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	var u := clampf(_t / _life, 0.0, 1.0)
	var k := 1.0 - u * u
	_core.scale = Vector3(k, k, 1.0)
	_glow.scale = Vector3(0.6 + 0.6 * u, 0.6 + 0.6 * u, 1.0)
	_mat_glow.albedo_color.a = 0.45 * k
	_mat_core.albedo_color.a = 0.95 * k
	_light.light_energy = 2.0 * k
	if _t >= _life: queue_free()
