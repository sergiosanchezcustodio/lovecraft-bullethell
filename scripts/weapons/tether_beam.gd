class_name TetherBeam
extends Node3D
## Lente del Éter: un rayo fino que une al personaje con un enemigo durante `life` s. Cada
## `interval` s le hace daño; mientras sigue sobre el mismo enemigo, el daño crece `ramp` por
## golpe hasta `ramp_max` veces. Si el enemigo muere o se aleja, salta al más cercano y el
## aumento vuelve a empezar. El rayo se ensancha y se aclara según crece el daño.

var player: Player
var world: CombatWorld
var damage := 5.0
var interval := 0.25
var ramp := 0.2
var ramp_max := 3.0
var reach := 8.0
var life := 3.0
var bonus := {}
var mult := 1.0                              ## multiplicador actual (tests)
var _target_id := 0
var _target: Node3D = null
var _t := 0.0
var _tick := 0.0
var _core: MeshInstance3D
var _glow: MeshInstance3D
var _mat_core: StandardMaterial3D
var _mat_glow: StandardMaterial3D
var _light: OmniLight3D

const FADE := 0.2
const COLD := Color(0.55, 0.8, 1.0)          # frío al empezar
const HOT := Color(0.95, 0.97, 1.0)          # casi blanco al tope

func setup(p_player: Player, p_world: CombatWorld, p_damage: float, p_interval: float, p_ramp: float,
		p_ramp_max: float, p_reach: float, p_life: float, p_bonus: Dictionary) -> TetherBeam:
	player = p_player; world = p_world; damage = p_damage; interval = maxf(p_interval, 0.05)
	ramp = p_ramp; ramp_max = maxf(p_ramp_max, 1.0); reach = p_reach; life = p_life; bonus = p_bonus
	name = "TetherBeam"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # se coloca en _process
	return self

func _ready() -> void:
	_core = _bar(0.06, false)
	_mat_core = _core.material_override
	_glow = _bar(0.2, true)
	_mat_glow = _glow.material_override
	_light = OmniLight3D.new()
	_light.light_color = COLD
	_light.omni_range = 2.5
	add_child(_light)
	visible = false

func _bar(w: float, additive: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, w, 1.0)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive: m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _valid_target() -> bool:
	if _target == null or not is_instance_valid(_target) or _target.get_instance_id() != _target_id: return false
	if not _target.is_alive(): return false
	return _target.global_position.distance_to(player.global_position) <= reach * 1.15

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= life or not is_instance_valid(player):
		if _t >= life + FADE or not is_instance_valid(player): queue_free()
		return
	if not _valid_target():
		_target = world.nearest_enemy(player.global_position, reach)
		_target_id = _target.get_instance_id() if _target != null else 0
		mult = 1.0
	_tick -= delta
	if _tick > 0.0 or _target == null: return
	_tick = interval
	var d := Damage.new(damage * mult, 0.0)
	d.bonus = bonus
	_target.take_damage(d)
	mult = minf(mult + ramp, ramp_max)

func _process(_delta: float) -> void:
	var on := is_instance_valid(player) and _target != null and is_instance_valid(_target) and _t < life + FADE
	visible = on
	if not on: return
	var a := player.get_global_transform_interpolated().origin + Vector3(0, 1.1, 0)
	var b := _target.global_position + Vector3(0, 0.7, 0)
	var len := a.distance_to(b)
	if len < 0.05: return
	global_position = (a + b) * 0.5
	look_at(b, Vector3.UP)
	var u := (mult - 1.0) / maxf(ramp_max - 1.0, 0.01)            # 0 al empezar, 1 al tope
	var fade := 1.0 - smoothstep(life, life + FADE, _t)
	var flick := 0.85 + 0.15 * sin(_t * 40.0)
	_core.scale = Vector3(1.0 + u * 1.5, 1.0 + u * 1.5, len)
	_glow.scale = Vector3((1.0 + u * 2.0) * flick, (1.0 + u * 2.0) * flick, len)
	var c := COLD.lerp(HOT, u)
	_mat_core.albedo_color = Color(c.r * 0.9, c.g * 0.9, c.b * 0.9, 0.95 * fade)
	_mat_glow.albedo_color = Color(c.r * 0.35, c.g * 0.5, c.b * 0.7, 0.5 * fade)
	_light.position = Vector3(0, 0, -len * 0.5)                     # en el extremo del enemigo (look_at mira por -Z)
	_light.light_color = c
	_light.light_energy = (0.8 + u * 1.4) * fade
