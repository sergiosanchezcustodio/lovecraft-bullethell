class_name Telegraph
extends MeshInstance3D
## Aviso en el suelo antes de un ataque fuerte (GDD 4.1: proporcional a su daño).
## Emite `finished` al cumplirse el tiempo y se elimina solo.

signal finished

var radius := 1.0
var duration := 1.0
var color := Color(1.0, 0.36, 0.18, 0.7)
var fill := true
var _t := 0.0
var _mat: ShaderMaterial

func setup(p_radius: float, p_duration: float, p_color: Color, p_fill: bool = true) -> Telegraph:
	radius = p_radius; duration = maxf(p_duration, 0.01); color = p_color; fill = p_fill
	return self

func _ready() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	mesh = pm
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	_mat.set_shader_parameter("color", color)
	_mat.set_shader_parameter("fill", fill)
	_mat.set_shader_parameter("ring_width", clampf(0.12 / radius, 0.03, 0.12))
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position.y = 0.04

func progress() -> float:
	return clampf(_t / duration, 0.0, 1.0)

func _process(delta: float) -> void:
	_t += delta
	_mat.set_shader_parameter("progress", progress())
	if _t >= duration:
		finished.emit()
		queue_free()
