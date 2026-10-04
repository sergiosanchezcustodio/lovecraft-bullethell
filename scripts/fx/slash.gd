class_name Slash
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Tajo circular del machete: un anillo claro que se abre desde el personaje hasta el radio
## del golpe en una décima de segundo y se apaga. Solo visual: el daño lo aplica el arma.

var radius := 2.2
var color := Color(0.88, 0.93, 1.0, 0.9)
var _t := 0.0
var _mat: ShaderMaterial
var _disc: MeshInstance3D

const LIFE := 0.22

func _ready() -> void:
	Damage.ctx = _wtag
	_disc = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	_disc.mesh = pm
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	_mat.set_shader_parameter("color", color)
	_mat.set_shader_parameter("fill", false)
	_mat.set_shader_parameter("ring_width", 0.16)
	_disc.material_override = _mat
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position.y = 0.35                       # a la altura del filo, por encima de la nieve
	add_child(_disc)
	_process(0.0)

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	var grow := 1.0 - pow(1.0 - minf(u / 0.45, 1.0), 3.0)
	_disc.scale = Vector3.ONE * radius * lerpf(0.35, 1.0, grow)
	_mat.set_shader_parameter("color", Color(color, color.a * (1.0 - smoothstep(0.4, 1.0, u))))
	if _t >= LIFE: queue_free()
