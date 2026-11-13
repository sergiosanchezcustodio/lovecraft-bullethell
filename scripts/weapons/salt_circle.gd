class_name SaltCircle
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Sales esenciales de Charles Dexter Ward (hito 20.18). Ward esparce en un círculo las sales de
## los que han caído allí y recita la fórmula de la Cabeza del Dragón: el polvo azulado se levanta
## en una cortina, a los RISE s la fórmula daña (FORMULA × `damage`) a los de `radius` y los restos que quedan allí
## (CombatWorld.take_remains, como mucho `count`) se levantan como aliados de ceniza azul
## (`Reanimated` con look "ward") durante `ally_life` s. Con `blast`, al deshacerse revientan.

var world: CombatWorld
var radius := 2.8
var damage := 10.0
var count := 2
var ally_life := 4.0
var ally_tick := 0.4
var blast := 0.0
var power := 1.0                           ## daño de los aliados (Frasco de los Custodes)
var bonus := {}
var risen := 0                             ## aliados que ha levantado (tests)
var done := false
var _t := 0.0
var _wall: MeshInstance3D

const RISE := 0.35                         ## s entre esparcir las sales y la fórmula
const FORMULA := 3.0                       ## daño de la fórmula, en veces `damage` (el de cada golpe de los levantados)
const LIFE := 0.9
const TINT := Color(0.62, 0.74, 1.0)

func setup(p_world: CombatWorld, pos: Vector3, p_radius: float, p_damage: float, p_count: int,
		p_ally_life: float, p_ally_tick: float, p_blast: float, p_bonus: Dictionary) -> SaltCircle:
	world = p_world; radius = p_radius; damage = p_damage; count = p_count
	ally_life = p_ally_life; ally_tick = maxf(p_ally_tick, 0.05); blast = p_blast; bonus = p_bonus
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	VoxelFx.puff(world.fx, global_position, "salts_rise", radius * 0.8, Color.WHITE, 1.2)
	Auto.sfx_at("formula", global_position)           # la fórmula, susurrada (hito 21.1)
	if FxShade.on():                                   # la cortina de la fórmula, azul y baja
		_wall = MeshInstance3D.new()
		_wall.mesh = VoxelFx.ring_wall()
		_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if FxShade.apply(_wall, "wall"):
			FxShade.set_tint(_wall, TINT)
			add_child(_wall)
		else:
			_wall.free()
			_wall = null

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if not done and _t >= RISE: _formula()
	if _t >= LIFE: queue_free()

## La fórmula: daña a los del círculo y levanta a los caídos que quedan en él.
func _formula() -> void:
	done = true
	for e in world.enemies_in_circle(global_position, radius):
		var d := Damage.new(damage * FORMULA, 0.0)
		d.bonus = bonus
		var away := Vector3(e.global_position.x - global_position.x, 0, e.global_position.z - global_position.z)
		d.knockback = away.normalized() * 0.4 if away.length() > 0.01 else Vector3.ZERO
		e.take_damage(d)
	for a: Array in world.take_remains(global_position, radius, count):
		var data: EnemyData = a[0]
		var at: Vector3 = a[1]
		var face := Vector3(at.x - global_position.x, 0, at.z - global_position.z)
		var g := Reanimated.new().setup(world, data, at, face.normalized() if face.length() > 0.01 else Vector3.FORWARD,
			ally_life, bonus)
		g.look = "ward"
		g.dps = damage / ally_tick * power
		g.tick = ally_tick
		g.blast = blast * power
		world.fx.add_child(g)
		risen += 1
	Auto.sfx_at("salts", global_position)             # las sales que chisporrotean (hito 21.1)
	if FxShade.on(): HitSparks.burst("glint_ice", global_position + Vector3(0, 0.4, 0))

func _process(_delta: float) -> void:
	if _wall == null: return
	var w := clampf(_t / LIFE, 0.0, 1.0)
	_wall.scale = Vector3(radius, 0.9 * (1.0 - pow(1.0 - minf(w * 1.6, 1.0), 2.0)) + 0.05, radius)
	_wall.set_instance_shader_parameter("fade", 0.7 * (1.0 - smoothstep(0.35, 1.0, w)))
