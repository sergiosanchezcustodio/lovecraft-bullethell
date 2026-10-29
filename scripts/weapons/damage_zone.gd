class_name DamageZone
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Zona en el suelo que daña a los enemigos que están dentro (fuego del Molotov y del
## lanzallamas, charco del lanzaquímicos). Aplica el daño por tics y, si es ácido, deja a
## los enemigos vulnerables. Visual: una mancha en el suelo y cubitos que brotan (llamas o
## burbujas), a juego con el estilo voxel. Se apaga al final de su vida.

var world: CombatWorld
var kind := WeaponData.Zone.FIRE
var radius := 1.6
var life := 3.0
var dps := 8.0
var vulnerable := 0.0
var slow_k := 1.0                            ## polvo: velocidad de los enemigos de dentro
var weak_k := 1.0                            ## polvo: daño que hacen los de dentro
var bonus := {}
var drift := Vector3.ZERO                    ## gas: se desplaza (m/s)
var _t := 0.0
var _tick := 0.0
var _parts: GPUParticles3D
var _light: OmniLight3D

const TICK := 0.3
const FADE := 0.5

func setup(p_world: CombatWorld, p_kind: int, pos: Vector3, p_radius: float, p_life: float, p_dps: float,
		p_vulnerable: float = 0.0, p_bonus: Dictionary = {}) -> DamageZone:
	world = p_world; kind = p_kind; radius = p_radius; life = p_life; dps = p_dps
	vulnerable = p_vulnerable; bonus = p_bonus
	position = Vector3(pos.x, 0.0, pos.z)
	return self

var _ground_mat: ShaderMaterial               ## mancha animada (ground_fx)
var _extra: Array[GPUParticles3D] = []

func _ready() -> void:
	Damage.ctx = _wtag
	_ready_voxel()
	add_to_group(&"combo_zones")
	Combos.zone(self)                            # sobre lo que dejó otro jugador (hito 13.7)
	Damage.ctx = _wtag

## Zonas en cubitos (11-10-2026): mancha animada en el suelo (`ground_fx`) y partículas.
## Fuego: llamas que acaban en humo y chispas. Ácido: burbujas que revientan y vapor.
## Gas: bocanadas turbias que derivan. Polvo: motas doradas que flotan y destellan.
## `lite` (las que siembran el lanzallamas y la bola de fuego, varias por segundo): sin luz
## y solo el emisor principal, con la mitad de partículas.
var lite := false

func _ready_voxel() -> void:
	var recipes: Array = {WeaponData.Zone.FIRE: ["flames", "smoke", "embers"],
		WeaponData.Zone.ACID: ["bubbles", "vapor"], WeaponData.Zone.GAS: ["gas"],
		WeaponData.Zone.DUST: ["dust", "motes"]}.get(kind, ["flames"])
	var mode: int = {WeaponData.Zone.FIRE: 0, WeaponData.Zone.ACID: 1, WeaponData.Zone.GAS: 4,
		WeaponData.Zone.DUST: 5}.get(kind, 0)
	var g := VoxelFx.ground(mode, radius)
	add_child(g)
	_ground_mat = g.material_override
	var fx := Node3D.new()
	fx.position.y = 0.08
	add_child(fx)
	if lite: recipes = [recipes[0]]
	for r in recipes:
		var e := VoxelFx.emitter(r, radius)
		if lite: e.amount = maxi(4, e.amount / 2)
		e.local_coords = kind == WeaponData.Zone.GAS          # el gas se lleva su nube al derivar
		fx.add_child(e)
		_extra.append(e)
	_parts = _extra[0]
	if kind == WeaponData.Zone.FIRE and not lite:
		_light = OmniLight3D.new()
		_light.light_color = Color(1.0, 0.5, 0.15)
		_light.omni_range = radius * 2.4
		_light.position.y = 0.6
		add_child(_light)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= life:
		_parts.emitting = false
		for e in _extra: e.emitting = false
		if _t >= life + FADE: queue_free()
		return
	if drift != Vector3.ZERO: global_position += drift * delta
	_tick -= delta
	if _tick > 0.0: return
	_tick = TICK
	for e in world.enemies_in_circle(global_position, radius):
		var d := Damage.new(dps * TICK, 0.0)
		d.bonus = bonus
		e.take_damage(d)
		if vulnerable > 0.0 and e.has_method("make_vulnerable") and e.is_alive(): e.make_vulnerable(vulnerable)
		if slow_k < 1.0 and e.has_method("slow") and e.is_alive(): e.slow(TICK + 0.25, slow_k)
		if weak_k < 1.0 and e.has_method("weaken") and e.is_alive(): e.weaken(TICK + 0.25, weak_k)

func _process(_delta: float) -> void:
	Damage.ctx = _wtag
	var fade := 1.0 - smoothstep(life, life + FADE, _t)
	_ground_mat.set_shader_parameter("fade", fade * smoothstep(0.0, 0.15, _t))
	if _light: _light.light_energy = (1.1 + 0.5 * sin(_t * 23.0) * sin(_t * 7.0)) * fade
