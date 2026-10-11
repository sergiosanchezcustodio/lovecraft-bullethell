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
var _core: Node3D
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
	# bola de cubos (11-10-2026): tres cubos girando unos dentro de otros, del amarillo
	# casi blanco del centro al rojo de fuera, con estela de llamas y chispas
	_core = Node3D.new()
	add_child(_core)
	for k in 3:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE * radius * [1.15, 0.85, 0.5][k]
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if k == 0 else BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color = [Color(0.8, 0.22, 0.04, 0.55), Color(0.85, 0.5, 0.1), Color(0.9, 0.85, 0.55)][k]
		bm.material = mat
		mi.mesh = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.rotation = Vector3(randf(), randf(), randf()) * TAU
		_core.add_child(mi)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.5, 0.15)
	_light.light_energy = 2.0
	_light.omni_range = 4.0
	add_child(_light)
	_parts = VoxelFx.emitter("trail", radius)
	add_child(_parts)
	var sparks := VoxelFx.emitter("embers", radius * 2.0)
	add_child(sparks)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	var step := speed * delta
	global_position += dir * step
	_run += step
	_drop -= step
	if _drop <= 0.0 and zone_t > 0.0:
		_drop = DROP_EVERY
		var z := DamageZone.new().setup(world, WeaponData.Zone.FIRE, global_position, zone_r, zone_t,
			zone_dps, 0.0, bonus)
		z.lite = true
		world.fx.add_child(z)
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
	var k := 0
	for c in _core.get_children():
		c.rotation += Vector3(0.21, 0.33, 0.17) * (1.0 + k * 0.6) * (1 if k % 2 == 0 else -1)
		k += 1
	_light.light_energy = 1.8 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
