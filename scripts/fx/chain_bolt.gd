class_name ChainBolt
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Rayo de la Bobina Tesla: tramos en zigzag, blancos azulados, entre los puntos por los que
## ha saltado; parpadean y se apagan en un instante. Solo visual: el daño lo aplica el arma.

var _points: Array[Vector3] = []
var _t := 0.0
var _mat: StandardMaterial3D
var _glow_mat: StandardMaterial3D
var _segs: Array[MeshInstance3D] = []
var _halos: Array[MeshInstance3D] = []
var _used := 0
var _light: OmniLight3D

const LIFE := 0.22
const KINKS := 4                             ## quiebros por tramo
static var _rng := RandomNumberGenerator.new()   ## ramas (hito 18.12): su azar, no el de la partida
var _shaded := false

func setup(points: Array[Vector3]) -> ChainBolt:
	_points = points
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	_mat = VoxelFx.std()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(0.75, 0.9, 1.0, 1.0)
	_glow_mat = VoxelFx.std()                 # halo aditivo alrededor del zigzag (11-10-2026)
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glow_mat.albedo_color = Color(0.25, 0.4, 0.7, 0.6)
	_rebuild()
	for i in range(1, _points.size()):                    # chispas donde salta
		var zap := VoxelFx.emitter("zap", 1.0, true, false, Color(0.6, 0.8, 1.0))
		zap.position = _points[i] + Vector3(0, 0.8, 0)
		add_child(zap)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.6, 0.8, 1.0)
	_light.light_energy = 2.5
	_light.omni_range = 4.0
	add_child(_light)
	_light.global_position = _points[_points.size() - 1] + Vector3(0, 0.8, 0) if not _points.is_empty() else Vector3.ZERO

## Vuelve a trazar el zigzag (cada vez con otros quiebros: el rayo "vibra").
func _rebuild() -> void:
	_used = 0
	for i in range(_points.size() - 1):
		var a := _points[i] + Vector3(0, 0.9, 0)
		var b := _points[i + 1] + Vector3(0, 0.8, 0)
		var prev := a
		for k in range(1, KINKS + 1):
			var p := a.lerp(b, float(k) / KINKS)
			if k < KINKS: p += Vector3(randf_range(-0.25, 0.25), randf_range(-0.2, 0.2), randf_range(-0.25, 0.25))
			_seg(prev, p)
			if k < KINKS and FxShade.on() and _rng.randf() < 0.45:   # una rama que se abre del quiebro (hito 18.12)
				var side := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.6, 0.2), _rng.randf_range(-1, 1)).normalized()
				var q := p + side * _rng.randf_range(0.25, 0.55)
				_seg(p, q, 0.6)
			prev = p
	for n in range(_used, _segs.size()): _segs[n].visible = false

## Un tramo del zigzag. Los tramos se reciclan de un trazado al siguiente (07-11-2026): el zigzag se
## rehace cada 0,07 s, y crear sus nodos cada vez (con las ramas y el halo de FxShade, que reserva
## sus uniformes por instancia) costaba 0,6 ms con la bobina a nivel 6.
func _seg(a: Vector3, b: Vector3, thick := 1.0) -> void:
	var len := a.distance_to(b)
	if len < 0.01: return
	var mi: MeshInstance3D
	var halo: MeshInstance3D
	if _used < _segs.size():
		mi = _segs[_used]
		halo = _halos[_used]
		mi.visible = true
	else:
		mi = MeshInstance3D.new()
		mi.mesh = VoxelFx.box1()                       # caja de 1 m compartida, con el tamaño en la escala
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		halo = MeshInstance3D.new()
		halo.mesh = VoxelFx.box1()
		halo.scale = Vector3(0.22 / 0.07, 0.22 / 0.07, 1.0)          # dentro del tramo, que ya lleva su escala
		halo.material_override = _glow_mat
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(halo)
		if FxShade.apply(halo, "bolt"):                 # hito 18.12: el halo, con chispas que corren
			halo.scale = Vector3(0.34 / 0.07, 0.34 / 0.07, 1.0)
			_shaded = true
		_segs.append(mi)
		_halos.append(halo)
	_used += 1
	var dir := (b - a) / len
	var basis := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT)
	mi.global_transform = Transform3D(basis * Basis.from_scale(Vector3(0.07 * thick, 0.07 * thick, len)), (a + b) * 0.5)
	if _shaded: halo.set_instance_shader_parameter("fade", clampf(1.0 - _t / LIFE, 0.0, 1.0))

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= LIFE:                                    # el rayo ya se apagó: dejamos acabar las chispas
		for sg in _segs: sg.visible = false
		_light.light_energy = 0.0
		if _t >= LIFE + 0.42: queue_free()
		return
	if fmod(_t, 0.07) < delta: _rebuild()
	var k := 1.0 - _t / LIFE
	_mat.albedo_color.a = clampf(k, 0.0, 1.0) * (0.7 + 0.3 * randf())
	_glow_mat.albedo_color.a = clampf(k, 0.0, 1.0) * 0.6
	_light.light_energy = 2.5 * maxf(k, 0.0)
