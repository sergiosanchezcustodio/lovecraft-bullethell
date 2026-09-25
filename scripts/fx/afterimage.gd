class_name Afterimage
extends Node3D
## Imagen fantasma de un modelo en un instante (la estela del destello): copia de sus
## mallas en la pose de ese momento, translúcida y del color indicado, que se desvanece.

const LIFE := 0.16

var _mat: StandardMaterial3D
var _t := 0.0
var _alpha := 0.5

## Copia las mallas de `model` con sus transformaciones globales de este fotograma.
func setup(model: Node3D, color: Color, alpha: float = 0.5) -> Afterimage:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_alpha = alpha
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(color, alpha)
	_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	for src: MeshInstance3D in model.get_meta("meshes"):
		var mi := MeshInstance3D.new()
		mi.mesh = src.mesh
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(mi)
		mi.set_meta("xf", src.global_transform)
	return self

func _ready() -> void:
	for mi in get_children():
		(mi as Node3D).global_transform = mi.get_meta("xf")

func _process(delta: float) -> void:
	_t += delta
	_mat.albedo_color.a = _alpha * (1.0 - _t / LIFE)
	if _t >= LIFE: queue_free()
