class_name SweepBeam
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Lámpara de Alhazred (hito 8.8): un haz de luz dorada que gira alrededor del personaje
## `life` s a `speed` grados por segundo. Daña a cada enemigo que barre, como mucho una vez
## cada `interval` s.

var player: Player
var world: CombatWorld
var length := 6.0
var half := 0.3
var speed := 140.0
var damage := 6.0
var interval := 0.35
var life := 3.0
var bonus := {}
var _angle := 0.0
var _t := 0.0
var _last := {}
var _beam: MeshInstance3D
var _mat: StandardMaterial3D
var _light: OmniLight3D

const FADE := 0.25

func setup(p: Player, p_world: CombatWorld, p_length: float, p_half: float, p_speed: float, p_damage: float,
		p_interval: float, p_life: float, p_bonus: Dictionary, offset := 0.0) -> SweepBeam:
	player = p; world = p_world; length = p_length; half = p_half; speed = p_speed; damage = p_damage
	interval = p_interval; life = p_life; bonus = p_bonus
	_angle = atan2(p.motor.facing.z, p.motor.facing.x) + offset   # varios haces: repartidos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	_beam = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1, 0.18, 1)
	_beam.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam.material_override = _mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.85, 0.45)
	_light.light_energy = 1.4
	_light.omni_range = 3.5
	add_child(_light)

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= life + FADE or not is_instance_valid(player):
		queue_free()
		return
	if _t >= life: return
	_angle += deg_to_rad(speed) * delta
	var origin := player.global_position
	var dir := Vector2(cos(_angle), sin(_angle))
	Damage.ctx = _wtag
	for e in world.enemies_in_circle(origin + Vector3(dir.x, 0, dir.y) * length * 0.5, length * 0.5 + half):
		var rel := Vector2(e.global_position.x - origin.x, e.global_position.z - origin.z)
		var along := rel.dot(dir)
		if along < 0.0 or along > length: continue
		if absf(rel.cross(dir)) > half + float(e.hit_radius): continue
		var id := e.get_instance_id()
		if _t - float(_last.get(id, -99.0)) < interval: continue
		_last[id] = _t
		var d := Damage.new(damage, 0.0)
		d.knockback = Vector3(dir.x, 0, dir.y) * 0.6
		d.bonus = bonus
		e.take_damage(d)

func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	var o := player.get_global_transform_interpolated().origin
	var dir := Vector3(cos(_angle), 0, sin(_angle))
	var k := clampf(minf(_t / FADE, (life + FADE - _t) / FADE), 0.0, 1.0)
	_beam.global_position = o + dir * length * 0.5 + Vector3(0, 0.9, 0)
	_beam.global_rotation = Vector3(0, -_angle, 0)
	_beam.scale = Vector3(length, 1, half * 2.0 * (0.85 + 0.15 * sin(_t * 30.0)))
	_mat.albedo_color = Color(1.0, 0.82, 0.4, 0.55 * k)
	_light.global_position = o + dir * length * 0.6 + Vector3(0, 1.0, 0)
	_light.light_energy = 1.4 * k
