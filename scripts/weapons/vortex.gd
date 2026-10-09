class_name Vortex
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Esfera de Yog-Sothoth (hito 8.8): un orbe de esferas iridiscentes que avanza despacio hacia
## un punto y se queda allí `life` s. Atrae hacia su centro a los enemigos de su radio (las
## élites, menos) y los daña cada `interval` s.

var world: CombatWorld
var goal := Vector3.ZERO
var speed := 2.5
var radius := 3.0
var damage := 6.0
var interval := 0.4
var pull := 6.0
var life := 4.0
var bonus := {}
var _t := 0.0
var _tick := 0.0
var _spheres: Array[MeshInstance3D] = []
var _disc_mat: ShaderMaterial
var _light: OmniLight3D

const FADE := 0.4
const SPHERES := 7

func setup(p_world: CombatWorld, origin: Vector3, p_goal: Vector3, p_speed: float, p_radius: float, p_damage: float,
		p_interval: float, p_pull: float, p_life: float, p_bonus: Dictionary) -> Vortex:
	world = p_world; goal = Vector3(p_goal.x, 0, p_goal.z); speed = p_speed; radius = p_radius
	damage = p_damage; interval = p_interval; pull = p_pull; life = p_life; bonus = p_bonus
	position = Vector3(origin.x, 0, origin.z)
	return self

func _ready() -> void:
	var disc := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	disc.mesh = pm
	_disc_mat = ShaderMaterial.new()
	_disc_mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	_disc_mat.set_shader_parameter("fill", true)
	_disc_mat.set_shader_parameter("soft", true)
	disc.material_override = _disc_mat
	disc.scale = Vector3.ONE * radius
	disc.position.y = 0.05
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	var cols := [Color(0.95, 0.75, 0.25), Color(0.55, 0.35, 0.95), Color(0.3, 0.85, 0.85)]
	for i in SPHERES:                             # las esferas de Yog-Sothoth, que se entrecruzan
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22; sm.height = 0.44; sm.radial_segments = 10; sm.rings = 5
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = cols[i % cols.size()] * 0.75
		sm.material = m
		mi.mesh = sm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_spheres.append(mi)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.7, 0.55, 1.0)
	_light.light_energy = 1.5
	_light.omni_range = radius * 1.6
	_light.position.y = 1.0
	add_child(_light)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= life + FADE:
		queue_free()
		return
	if _t >= life: return
	var to := goal - global_position
	if to.length() > 0.1: global_position += to.normalized() * minf(speed * delta, to.length())
	_tick -= delta
	var hit := _tick <= 0.0
	if hit: _tick = interval
	for e in world.enemies_in_circle(global_position, radius):
		var rel := global_position - e.global_position
		rel.y = 0.0
		if e.has_method("nudge") and rel.length() > 0.4: e.nudge(rel.normalized() * pull * delta * 8.0)
		if hit:
			var d := Damage.new(damage, 0.0)
			d.bonus = bonus
			e.take_damage(d)

func _process(_delta: float) -> void:
	var k := clampf(minf(_t / FADE, (life + FADE - _t) / FADE), 0.0, 1.0)
	_disc_mat.set_shader_parameter("color", Color(0.35, 0.2, 0.6, 0.35 * k))
	for i in _spheres.size():
		var a := _t * (2.0 + 0.4 * i) + TAU * i / _spheres.size()
		var r := 0.45 + 0.25 * sin(_t * 3.0 + i)
		_spheres[i].position = Vector3(cos(a) * r, 1.0 + 0.35 * sin(a * 1.3 + i), sin(a) * r)
		_spheres[i].scale = Vector3.ONE * k * (0.8 + 0.3 * sin(_t * 5.0 + i * 2.0))
	_light.light_energy = 1.5 * k
