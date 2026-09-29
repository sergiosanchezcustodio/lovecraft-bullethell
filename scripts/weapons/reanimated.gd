class_name Reanimated
extends Node3D
## Enemigo levantado por el suero de Herbert West: su propio modelo, con un tinte verde
## enfermizo, que durante `life` s persigue al enemigo más cercano y le hace daño al tocarlo.
## No recibe daño ni lo buscan los enemigos (no está en CombatWorld). Al acabar se desmorona.

var world: CombatWorld
var data: EnemyData
var life := 6.0
var dps := 12.0
var bonus := {}
var hits := 0                                ## golpes dados (tests)
var _t := 0.0
var _tick := 0.0
var _facing := Vector3.FORWARD
var _visual: Node3D
var _model: Node3D
var _anim_t := 0.0

const SPEED := 3.4
const TICK := 0.4
const FADE := 0.5
const TINT := Color(0.3, 0.95, 0.25, 0.5)

func setup(p_world: CombatWorld, p_data: EnemyData, pos: Vector3, facing: Vector3, p_life: float,
		p_bonus: Dictionary) -> Reanimated:
	world = p_world; data = p_data; life = p_life; bonus = p_bonus
	dps = 10.0 + data.max_health * 0.2
	position = Vector3(pos.x, 0.0, pos.z)
	_facing = facing
	return self

func _ready() -> void:
	_visual = Node3D.new()
	_visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_visual.top_level = true
	add_child(_visual)
	_model = VoxelBuilder.load_model("res://models/%s.json" % data.model)
	_visual.add_child(_model)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = TINT
	for mi: MeshInstance3D in _model.get_meta("meshes"): mi.material_overlay = m

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= life:
		if _t >= life + FADE: queue_free()
		return
	var target := world.nearest_enemy(global_position, 12.0)
	if target != null:
		var to := Vector3(target.global_position.x - position.x, 0, target.global_position.z - position.z)
		if to.length() > 0.6:
			_facing = to.normalized()
			position += _facing * SPEED * delta
	_tick -= delta
	if _tick > 0.0: return
	_tick = TICK
	for e in world.enemies_in_circle(global_position, data.body_radius + 0.35):
		var d := Damage.new(dps * TICK, 0.0)
		d.knockback = _facing * 0.6
		d.bonus = bonus
		e.take_damage(d)
		hits += 1

func _process(delta: float) -> void:
	_visual.global_position = get_global_transform_interpolated().origin
	_visual.rotation.y = atan2(_facing.x, _facing.z)
	var sink := smoothstep(life, life + FADE, _t)                       # se desmorona hundiéndose
	_visual.global_position.y -= sink * 0.8
	_visual.scale = Vector3.ONE * clampf(_t / 0.3, 0.3, 1.0) * (1.0 - sink * 0.4)
	_anim_t = fposmod(_anim_t + delta / Anims.duration(data.model, "walk"), 1.0)
	Anims.pose(data.model, "walk", _model, _anim_t)
