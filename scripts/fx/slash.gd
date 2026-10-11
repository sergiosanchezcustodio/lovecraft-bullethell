class_name Slash
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Tajo circular del machete (rehecho el 11-10-2026): una corona de celdas que barre una
## vuelta alrededor del personaje con la cabeza casi blanca y una estela que se apaga, y
## chispas de acero. Solo visual: el daño lo aplica el arma.

var radius := 2.2
var color := Color(0.88, 0.93, 1.0, 0.9)
var _t := 0.0
var _mat: ShaderMaterial
var _disc: MeshInstance3D

const LIFE := 0.26

func _ready() -> void:
	Damage.ctx = _wtag
	_disc = VoxelFx.ground(8, radius)
	_disc.position.y = 0.35                       # a la altura del filo, por encima de la nieve
	_mat = _disc.material_override
	_mat.set_shader_parameter("tint", Color(color.r, color.g, color.b))
	_mat.set_shader_parameter("seed", randf() * 100.0)
	add_child(_disc)
	var sparks := VoxelFx.emitter("zap", radius, true, false, Color(0.85, 0.9, 1.0))
	sparks.position.y = 0.4
	add_child(sparks)
	_process(0.0)

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	_mat.set_shader_parameter("age", 1.0 - pow(1.0 - u, 2.0))
	_mat.set_shader_parameter("fade", 1.0 - smoothstep(0.7, 1.0, u))
	_disc.visible = _t < LIFE
	if _t >= LIFE + 0.4: queue_free()              # deja acabar las chispas
