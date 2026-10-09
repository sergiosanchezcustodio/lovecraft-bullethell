class_name Fireball
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Llama de Cthugha (hito 8.8): bola de fuego vivo que avanza en línea recta `length` m,
## atraviesa (golpea una vez a cada enemigo) y deja fuego en el suelo cada DROP_EVERY m.

var world: CombatWorld
var dir := Vector3.FORWARD
var speed := 8.0
var length := 10.0
var radius := 0.5
var damage := 12.0
var zone_r := 0.9
var zone_t := 2.0
var zone_dps := 6.0
var bonus := {}
var _done := {}
var _run := 0.0
var _drop := 0.0
var _core: MeshInstance3D
var _light: OmniLight3D
var _parts: GPUParticles3D

const DROP_EVERY := 1.4

func setup(p_world: CombatWorld, origin: Vector3, p_dir: Vector3, p_speed: float, p_length: float, p_radius: float,
		p_damage: float, z_r: float, z_t: float, z_dps: float, p_bonus: Dictionary) -> Fireball:
	world = p_world; dir = Vector3(p_dir.x, 0, p_dir.z).normalized(); speed = p_speed; length = p_length
	radius = p_radius; damage = p_damage; zone_r = z_r; zone_t = z_t; zone_dps = z_dps; bonus = p_bonus
	position = Vector3(origin.x, 0.8, origin.z) + dir * 0.5
	return self

func _ready() -> void:
	_core = MeshInstance3D.new()
	var bm := BoxMesh.new()                      # bola de cubos, al estilo voxel
	bm.size = Vector3.ONE * radius * 1.1
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.62, 0.18) * 0.8
	bm.material = mat
	_core.mesh = bm
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_core)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.5, 0.15)
	_light.light_energy = 2.0
	_light.omni_range = 4.0
	add_child(_light)
	_parts = GPUParticles3D.new()
	_parts.amount = 40
	_parts.lifetime = 0.5
	_parts.local_coords = false
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ppm.emission_sphere_radius = radius * 0.6
	ppm.gravity = Vector3(0, 1.5, 0)
	ppm.initial_velocity_min = 0.2
	ppm.initial_velocity_max = 0.8
	ppm.scale_min = 0.07
	ppm.scale_max = 0.16
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.92, 0.5), Color(1.0, 0.4, 0.08), Color(0.3, 0.08, 0.05, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	ppm.color_ramp = gt
	_parts.process_material = ppm
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var pm := StandardMaterial3D.new()
	pm.vertex_color_use_as_albedo = true
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = pm
	_parts.draw_pass_1 = box
	add_child(_parts)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	var step := speed * delta
	global_position += dir * step
	_run += step
	_drop -= step
	if _drop <= 0.0 and zone_t > 0.0:
		_drop = DROP_EVERY
		world.fx.add_child(DamageZone.new().setup(world, WeaponData.Zone.FIRE, global_position, zone_r, zone_t,
			zone_dps, 0.0, bonus))
	world.bullets.clear_enemy_bullets(global_position, radius)
	for e in world.enemies_in_circle(global_position, radius):
		var id := e.get_instance_id()
		if _done.has(id) or not e.is_alive(): continue
		_done[id] = true
		var d := Damage.new(damage, 0.0)
		d.knockback = dir * 1.2
		d.bonus = bonus
		e.take_damage(d)
	var obs := world.obstacles
	if _run >= length or (obs != null and obs.has_mask() and obs.stops_bullet(Vector2(global_position.x, global_position.z))):
		queue_free()

func _process(_delta: float) -> void:
	_core.rotation += Vector3(0.21, 0.33, 0.17)
	_light.light_energy = 1.8 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
