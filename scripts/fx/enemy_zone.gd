class_name EnemyZone
extends Node3D
## Charco que daña a los jugadores que lo pisan (limo del Antiguo mutilado, hito 4.4): una
## mancha oscura en el suelo que hace `dps` de daño físico y `mental_dps` de daño mental por
## tics y se desvanece al final de su vida.

var world: CombatWorld
var radius := 1.0
var life := 6.0
var dps := 4.0
var mental_dps := 2.0
var color := Color(0.06, 0.14, 0.09)
var _t := 0.0
var _tick := 0.0
var _mat: ShaderMaterial

const TICK := 0.4
const FADE := 0.8

func setup(p_world: CombatWorld, pos: Vector3, p_radius: float, p_life: float, p_dps: float, p_mental: float) -> EnemyZone:
	world = p_world; radius = p_radius; life = p_life; dps = p_dps; mental_dps = p_mental
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	var disc := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	disc.mesh = pm
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	_mat.set_shader_parameter("color", Color(color, 0.85))
	_mat.set_shader_parameter("fill", true)
	_mat.set_shader_parameter("soft", true)
	disc.material_override = _mat
	disc.scale = Vector3.ONE * radius
	disc.position.y = 0.03
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	_mat.set_shader_parameter("color", Color(color, 0.85 * clampf((life - _t) / FADE, 0.0, 1.0)))
	_tick -= delta
	if _tick > 0.0: return
	_tick = TICK
	for p in world.players:
		var off := p.global_position - global_position
		off.y = 0.0
		if off.length() < radius + p.data.hurt_radius * 0.5 and not p.is_downed() and not p.is_eliminated:
			p.take_damage(Damage.new(dps * TICK, mental_dps * TICK))
