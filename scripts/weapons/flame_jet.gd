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
var frost := false                           ## Aliento de Ithaqua: frena y, si sigue dentro, congela
var _cold := {}                              ## id del enemigo -> s dentro del chorro helado
const FREEZE_AFTER := 0.9
const FREEZE_TIME := 1.2
var _t := 0.0
var _tick := 0.0
var _drop := 0.0
var _parts: GPUParticles3D
var _light: OmniLight3D
var _smoke: GPUParticles3D

func setup(p: Player, p_world: CombatWorld, p_dir: Vector3, p_length: float, spread_deg: float, p_dps: float,
		p_life: float, z_r: float, z_t: float, z_dps: float, p_bonus: Dictionary) -> FlameJet:
	player = p; world = p_world; dir = p_dir.normalized(); length = p_length
	half_angle = deg_to_rad(spread_deg) * 0.5; dps = p_dps; life = p_life
	zone_r = z_r; zone_t = z_t; zone_dps = z_dps; bonus = p_bonus
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	# chorro en cubitos (11-10-2026): núcleo que pasa de blanco a rojo y se ensancha, con
	# humo negro escapando por arriba; helado, en azules y cayendo
	_parts = VoxelFx.emitter("jet", length)
	_parts.process_material.spread = rad_to_deg(half_angle) * 0.8
	add_child(_parts)
	if frost:
		var pm: ParticleProcessMaterial = _parts.process_material
		pm.color_ramp = VoxelFx._ramp([[0.0, Color(0.6, 0.72, 0.8, 1.0)], [0.3, Color(0.3, 0.52, 0.75, 1.0)],
			[1.0, Color(0.15, 0.3, 0.55, 0.0)]])
		pm.gravity = Vector3(0, -0.6, 0)
	else:
		var smoke := VoxelFx.emitter("jet_smoke", length)
		add_child(smoke)
		_smoke = smoke
	_light = OmniLight3D.new()
	_light.light_color = Color(0.5, 0.8, 1.0) if frost else Color(1.0, 0.5, 0.2)
	_light.light_energy = 1.6
	_light.omni_range = length
	add_child(_light)
	_place()

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
		if _smoke: _smoke.emitting = false
		if _t >= life + _parts.lifetime * 2.6: queue_free()
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
			if frost and e.is_alive():
				e.slow(0.4, 0.45)
				var id := e.get_instance_id()
				_cold[id] = float(_cold.get(id, 0.0)) + 0.15
				if _cold[id] >= FREEZE_AFTER:
					_cold[id] = -FREEZE_TIME                      # congelado: tarda en volver a helarse
					e.stun(FREEZE_TIME)
	_drop -= delta
	if _drop <= 0.0 and zone_t > 0.0:
		_drop = 0.25
		var tip := origin + dir * length * randf_range(0.6, 0.95)
		var z := DamageZone.new().setup(world, WeaponData.Zone.FIRE, tip, zone_r, zone_t, zone_dps, 0.0, bonus)
		z.lite = true                                        # varias por segundo: sin luz propia
		world.fx.add_child(z)

func _process(_delta: float) -> void:
	Damage.ctx = _wtag
	_place()
	_light.light_energy = (1.3 + 0.5 * sin(_t * 29.0)) * (1.0 - smoothstep(life - 0.1, life, _t))
