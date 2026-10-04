class_name ChainBolt
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Rayo de la Bobina Tesla: tramos en zigzag, blancos azulados, entre los puntos por los que
## ha saltado; parpadean y se apagan en un instante. Solo visual: el daño lo aplica el arma.

var _points: Array[Vector3] = []
var _t := 0.0
var _mat: StandardMaterial3D
var _segs: Array[MeshInstance3D] = []
var _light: OmniLight3D

const LIFE := 0.22
const KINKS := 4                             ## quiebros por tramo

func setup(points: Array[Vector3]) -> ChainBolt:
	_points = points
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(0.75, 0.9, 1.0, 1.0)
	_rebuild()
	_light = OmniLight3D.new()
	_light.light_color = Color(0.6, 0.8, 1.0)
	_light.light_energy = 2.5
	_light.omni_range = 4.0
	add_child(_light)
	_light.global_position = _points[_points.size() - 1] + Vector3(0, 0.8, 0) if not _points.is_empty() else Vector3.ZERO

## Vuelve a trazar el zigzag (cada vez con otros quiebros: el rayo "vibra").
func _rebuild() -> void:
	for s in _segs: s.queue_free()
	_segs.clear()
	for i in range(_points.size() - 1):
		var a := _points[i] + Vector3(0, 0.9, 0)
		var b := _points[i + 1] + Vector3(0, 0.8, 0)
		var prev := a
		for k in range(1, KINKS + 1):
			var p := a.lerp(b, float(k) / KINKS)
			if k < KINKS: p += Vector3(randf_range(-0.25, 0.25), randf_range(-0.2, 0.2), randf_range(-0.25, 0.25))
			_seg(prev, p)
			prev = p

func _seg(a: Vector3, b: Vector3) -> void:
	var len := a.distance_to(b)
	if len < 0.01: return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.07, len)
	mi.mesh = bm
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	_segs.append(mi)

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if fmod(_t, 0.07) < delta: _rebuild()
	var k := 1.0 - _t / LIFE
	_mat.albedo_color.a = clampf(k, 0.0, 1.0) * (0.7 + 0.3 * randf())
	_light.light_energy = 2.5 * maxf(k, 0.0)
	if _t >= LIFE: queue_free()
