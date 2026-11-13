class_name PictureFrame
extends Node3D
## El esquive de Pickman (hito 20.17): un marco dorado que se abre de pie en el suelo, con el
## cuadro oscuro dentro, por el que entra (al empezar el esquive) o sale (al volver a verse);
## se encoge y se va en `LIFE` s. Mira a la cámara (fija, a 45°).

const LIFE := 0.55
const W := 0.8
const H := 1.15
const BAR := 0.07
static var _gold: StandardMaterial3D
static var _dark: StandardMaterial3D
var _t := 0.0
var _inner: MeshInstance3D

func setup(pos: Vector3) -> PictureFrame:
	position = Vector3(pos.x, 0.0, pos.z)
	rotation.y = deg_to_rad(45.0)
	return self

func _ready() -> void:
	if _gold == null:
		_gold = VoxelFx.std()
		_gold.albedo_color = Color(0.78, 0.6, 0.25)
		_gold.metallic = 0.6
		_gold.roughness = 0.4
		_gold.emission_enabled = true
		_gold.emission = Color(0.45, 0.32, 0.1)
		_dark = VoxelFx.std()
		_dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_dark.albedo_color = Color(0.04, 0.02, 0.03)
	for b in [[Vector3(W + BAR * 2, BAR, BAR), Vector3(0, H + BAR * 0.5, 0)], [Vector3(W + BAR * 2, BAR, BAR), Vector3(0, BAR * 0.5, 0)],
			[Vector3(BAR, H, BAR), Vector3(-(W + BAR) * 0.5, H * 0.5 + BAR * 0.5, 0)], [Vector3(BAR, H, BAR), Vector3((W + BAR) * 0.5, H * 0.5 + BAR * 0.5, 0)]]:
		var m := MeshInstance3D.new()
		m.mesh = VoxelFx.box(b[0])
		m.material_override = _gold
		m.position = b[1]
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
	_inner = MeshInstance3D.new()
	_inner.mesh = VoxelFx.box(Vector3(W, H - BAR, 0.02))
	_inner.material_override = _dark
	_inner.position = Vector3(0, H * 0.5 + BAR * 0.5, -0.01)
	_inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_inner)
	scale = Vector3(1, 0.01, 1)

func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	var grow := 1.0 - pow(1.0 - clampf(_t / 0.09, 0.0, 1.0), 3.0)
	var shrink := smoothstep(LIFE - 0.25, LIFE, _t)
	scale = Vector3(1.0 - shrink * 0.6, maxf(grow * (1.0 - shrink), 0.01), 1.0)
