class_name FlameJet
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Chorro del Flammenwerfer: un cono de fuego delante del personaje durante `duration` s.
## Sigue al jugador y a la dirección elegida al disparar. Daña a lo que está dentro del
## cono cada 0,15 s y va dejando fuego en el suelo (DamageZone) en la punta del chorro.

var player: Player
var world: CombatWorld
var dir := Vector3.FORWARD
var length := 4.5
var half_angle := 0.3                        ## rad
var dps := 24.0
var life := 0.8
var zone_r := 1.0
var zone_t := 2.0
var zone_dps := 6.0
var bonus := {}
var _t := 0.0
var _tick := 0.0
var _drop := 0.0
var _parts: GPUParticles3D
var _light: OmniLight3D

func setup(p: Player, p_world: CombatWorld, p_dir: Vector3, p_length: float, spread_deg: float, p_dps: float,
		p_life: float, z_r: float, z_t: float, z_dps: float, p_bonus: Dictionary) -> FlameJet:
	player = p; world = p_world; dir = p_dir.normalized(); length = p_length
	half_angle = deg_to_rad(spread_deg) * 0.5; dps = p_dps; life = p_life
	zone_r = z_r; zone_t = z_t; zone_dps = z_dps; bonus = p_bonus
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	_parts = GPUParticles3D.new()
	_parts.amount = 90
	_parts.lifetime = length / 9.0
	_parts.local_coords = false
	var ppm := ParticleProcessMaterial.new()
	ppm.direction = Vector3(0, 0, 1)
	ppm.spread = rad_to_deg(half_angle)
	ppm.initial_velocity_min = 8.0
	ppm.initial_velocity_max = 10.0
	ppm.gravity = Vector3(0, 1.2, 0)
	ppm.scale_min = 0.08
	ppm.scale_max = 0.2
	ppm.scale_curve = _grow_curve()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.9, 0.55), Color(1.0, 0.45, 0.1), Color(0.35, 0.1, 0.05, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	ppm.color_ramp = gt
	_parts.process_material = ppm
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = bm
	_parts.draw_pass_1 = box
	add_child(_parts)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.5, 0.2)
	_light.light_energy = 1.6
	_light.omni_range = length
	add_child(_light)
	_place()

func _grow_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0, 0.4))
	c.add_point(Vector2(1, 1.6))
	var ct := CurveTexture.new()
	ct.curve = c
	return ct

func _place() -> void:
	if not is_instance_valid(player): return
	var o := player.get_global_transform_interpolated().origin
	global_position = o + Vector3(0, 0.9, 0) + dir * 0.4
	look_at(global_position + dir, Vector3.UP)
	rotate_object_local(Vector3.UP, PI)            # look_at apunta -Z; las partículas salen por +Z
	_light.position = Vector3(0, 0, length * 0.5)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= life:
		_parts.emitting = false
		if _t >= life + _parts.lifetime: queue_free()
		return
	var origin := player.global_position if is_instance_valid(player) else global_position
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.15
		world.bullets.clear_enemy_bullets(origin + dir * length * 0.35, length * 0.3)   # el chorro quema balas
		for e in world.enemies_in_circle(origin + dir * length * 0.5, length * 0.5 + 0.5):
			var rel := Vector3(e.global_position.x - origin.x, 0, e.global_position.z - origin.z)
			if rel.length() > length or rel.length() < 0.01: continue
			if absf(Vector2(dir.x, dir.z).angle_to(Vector2(rel.x, rel.z))) > half_angle + 0.12: continue
			var d := Damage.new(dps * 0.15, 0.0)
			d.bonus = bonus
			e.take_damage(d)
	_drop -= delta
	if _drop <= 0.0 and zone_t > 0.0:
		_drop = 0.25
		var tip := origin + dir * length * randf_range(0.6, 0.95)
		world.fx.add_child(DamageZone.new().setup(world, WeaponData.Zone.FIRE, tip, zone_r, zone_t, zone_dps, 0.0, bonus))

func _process(_delta: float) -> void:
	Damage.ctx = _wtag
	_place()
	_light.light_energy = (1.3 + 0.5 * sin(_t * 29.0)) * (1.0 - smoothstep(life - 0.1, life, _t))
