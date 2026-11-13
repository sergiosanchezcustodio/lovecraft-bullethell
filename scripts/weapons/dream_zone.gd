class_name DreamZone
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Zona de sueño de Kuranes (hito 20.22): un trozo del cielo de Celephaïs en el suelo. Los
## enemigos de dentro sueñan y van cada vez más despacio (de su paso a `slow_k` en DROWSE s), las
## balas enemigas que entran se frenan a `bullet_slow` y los jugadores de dentro recuperan `rest`
## de cordura por segundo. Daña poco, a tics de `interval` s. Con `sleep` (Ooth-Nargai), los que
## llevan SLEEP_AFTER s dentro se duermen `sleep` s (una vez cada uno). Con `follow`
## (Serannian), va con el jugador. Visual: suelo de nubes pastel con estrellas (ground_fx, modo
## 12), cortina que sube del borde al aparecer y cubitos de colores que flotan.

var world: CombatWorld
var radius := 2.6
var life := 4.0
var damage := 3.0                            ## por tic
var interval := 0.5
var slow_k := 0.45                           ## velocidad de los de dentro cuando ya sueñan del todo
var bullet_slow := 0.6
var rest := 0.0                              ## cordura por segundo para los jugadores de dentro
var sleep := 0.0                             ## Ooth-Nargai: s que duermen
var follow: Node3D = null                    ## Serannian: va con él
var bonus := {}
var slept := 0                               ## dormidos (tests)
var slowed := 0                              ## balas frenadas (tests)
var _t := 0.0
var _tick := 0.0
var _inside := {}                            ## id del enemigo -> s soñando dentro
var _asleep := {}                            ## ids que ya se han dormido
var _mat: ShaderMaterial
var _wall: MeshInstance3D
var _motes: GPUParticles3D
var _light: OmniLight3D

const DROWSE := 1.2                          ## s hasta que el freno es entero
const SLEEP_AFTER := 1.5                     ## s dentro hasta dormirse (Ooth-Nargai)
const FADE := 0.5
const COLOR := Color(0.55, 0.82, 0.95)
const ROSE := Color(0.95, 0.66, 0.82)

func setup(p_world: CombatWorld, pos: Vector3, p_radius: float, p_life: float, p_damage: float,
		p_interval: float, p_slow: float, p_bullet_slow: float, p_rest: float, p_bonus: Dictionary) -> DreamZone:
	world = p_world; radius = p_radius; life = p_life; damage = p_damage; interval = maxf(p_interval, 0.1)
	slow_k = p_slow; bullet_slow = p_bullet_slow; rest = p_rest; bonus = p_bonus
	position = Vector3(pos.x, 0.0, pos.z)
	return self

## ¿Se está apagando? (Serannian no saca otra hasta entonces.)
func ending() -> bool:
	return _t >= life

func _ready() -> void:
	Damage.ctx = _wtag
	add_to_group(&"combo_dreams")                     # rayos y la Máquina (Combos, hito 21.6)
	var g := VoxelFx.ground(12, radius)
	g.position.y = 0.05
	_mat = g.material_override
	add_child(g)
	_wall = MeshInstance3D.new()                 # cortina que sube del borde al aparecer (como el signo)
	_wall.mesh = VoxelFx.ring_wall()
	_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if FxShade.apply(_wall, "wall"):
		FxShade.set_tint(_wall, ROSE.lerp(COLOR, 0.5).lightened(0.25))
		add_child(_wall)
	else:
		_wall.free()
		_wall = null
	_motes = VoxelFx.emitter("dream", radius, false, false)
	add_child(_motes)
	_light = OmniLight3D.new()
	_light.light_color = COLOR
	_light.omni_range = radius * 1.7
	_light.position.y = 0.6
	add_child(_light)
	_process(0.0)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	if follow != null and is_instance_valid(follow):
		global_position = Vector3(follow.global_position.x, 0.0, follow.global_position.z)
	_t += delta
	if _t >= life:
		if _t >= life + FADE: queue_free()
		return
	if bullet_slow < 1.0:
		slowed += world.bullets.slow_enemy_bullets(global_position, radius, bullet_slow, BulletManager.SLOW_DREAM)
	if rest > 0.0:                               # los soñadores descansan
		for p in world.players:
			if p.remote or p.health <= 0.0: continue
			var dp := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z)
			if dp.length() <= radius:
				p.sanity = minf(p.data.max_sanity, p.sanity + rest * delta)
				var heal := float(p.bond.get("dream_heal", 0.0))   # los soñadores (vínculo, 21.3): Carter
				if heal > 0.0: p.health = minf(p.data.max_health, p.health + p.data.max_health * heal * delta)
	_tick -= delta
	if _tick > 0.0: return
	_tick = interval
	for e in world.enemies_in_circle(global_position, radius):
		if not e.is_alive(): continue
		var id := e.get_instance_id()
		var t: float = _inside.get(id, 0.0) + interval
		_inside[id] = t
		if e.has_method("slow"): e.slow(interval + 0.25, lerpf(1.0, slow_k, clampf(t / DROWSE, 0.0, 1.0)))
		if e.has_method("dream"): e.dream(interval + 0.3)
		if sleep > 0.0 and t >= SLEEP_AFTER and not _asleep.has(id) and e.has_method("stun"):
			_asleep[id] = true
			slept += 1
			e.stun(sleep)
			if e.has_method("dream"): e.dream(sleep)
			VoxelFx.puff(world.fx, e.global_position + Vector3(0, 1.0, 0), "dream_z", 0.3, Color.WHITE, 1.4)
			Auto.sfx_at("dream_sleep", e.global_position)
		if damage > 0.0:
			var d := Damage.new(damage, 0.0)
			d.bonus = bonus
			d.dot = true
			e.take_damage(d)

func _process(_delta: float) -> void:
	Damage.ctx = _wtag
	var k := clampf(_t / 0.35, 0.0, 1.0) * (1.0 - smoothstep(life, life + FADE, _t))
	_mat.set_shader_parameter("age", _t)
	_mat.set_shader_parameter("fade", k)
	if _t >= life: _motes.emitting = false
	_light.light_energy = 0.7 * k
	if _wall:
		var w := clampf(_t / 0.7, 0.0, 1.0)
		_wall.visible = w < 1.0
		_wall.scale = Vector3(radius * 0.98, 1.3 * (1.0 - pow(1.0 - w, 2.0)) + 0.05, radius * 0.98)
		_wall.set_instance_shader_parameter("fade", 1.0 - smoothstep(0.3, 1.0, w))
