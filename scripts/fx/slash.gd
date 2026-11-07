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

const LIFE := 0.3
var _arc: MeshInstance3D                  ## el arco a la altura de la hoja (hito 18.5)

func _ready() -> void:
	Damage.ctx = _wtag
	_disc = VoxelFx.ground(8, radius)
	_disc.position.y = 0.35                       # a la altura del filo, por encima de la nieve
	_mat = _disc.material_override
	_mat.set_shader_parameter("tint", Color(color.r, color.g, color.b))
	_mat.set_shader_parameter("seed", randf() * 100.0)
	add_child(_disc)
	_arc = MeshInstance3D.new()
	_arc.mesh = VoxelFx.arc_ring()
	_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arc.position.y = 0.8
	_arc.scale = Vector3(radius * 0.92, 1.0, radius * 0.92)
	add_child(_arc)
	if not FxShade.apply(_arc, "slash"): _arc.queue_free()
	else: FxTrails.attach.call_deferred(_tip(), "steel", Color(0.8, 0.9, 1.0), 1.3)
	var sparks := VoxelFx.emitter("zap", radius, true, false, Color(0.85, 0.9, 1.0))
	sparks.position.y = 0.4
	add_child(sparks)
	_process(0.0)

var _tip_node: Node3D
func _tip() -> Node3D:
	_tip_node = Node3D.new()
	_tip_node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_tip_node)
	_tip_node.position = Vector3(radius * 0.9, 0.88, 0)
	return _tip_node

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	_mat.set_shader_parameter("age", 1.0 - pow(1.0 - u, 2.0))
	_mat.set_shader_parameter("fade", 1.0 - smoothstep(0.7, 1.0, u))
	_disc.visible = _t < LIFE
	if is_instance_valid(_arc):
		var a := 1.0 - pow(1.0 - u, 2.0)
		_arc.set_instance_shader_parameter("age", a)
		_arc.set_instance_shader_parameter("fade", 1.0 - smoothstep(0.75, 1.0, u))
		_arc.visible = _t < LIFE
		if is_instance_valid(_tip_node):            # la punta de la hoja, con su estela
			var ang := a * TAU * 1.15
			_tip_node.position = Vector3(cos(ang), 0.0, sin(ang)) * radius * 0.9 + Vector3(0, 0.88, 0)
			_tip_node.visible = _t < LIFE
	if _t >= LIFE + 0.4: queue_free()              # deja acabar las chispas
