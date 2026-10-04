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
var _t := 0.0
var _tick := 0.0
var _mat: ShaderMaterial
var _parts: GPUParticles3D
var _light: OmniLight3D

const TICK := 0.3
const FADE := 0.5
const COLORS := {WeaponData.Zone.FIRE: [Color(1.0, 0.45, 0.12), Color(1.0, 0.78, 0.3)],
	WeaponData.Zone.ACID: [Color(0.45, 0.85, 0.2), Color(0.75, 1.0, 0.45)],
	# polvo: mancha sepia oscura y motas doradas (un tono pálido desaparecía sobre la nieve)
	WeaponData.Zone.DUST: [Color(0.55, 0.36, 0.14), Color(1.0, 0.82, 0.4)]}

func setup(p_world: CombatWorld, p_kind: int, pos: Vector3, p_radius: float, p_life: float, p_dps: float,
		p_vulnerable: float = 0.0, p_bonus: Dictionary = {}) -> DamageZone:
	world = p_world; kind = p_kind; radius = p_radius; life = p_life; dps = p_dps
	vulnerable = p_vulnerable; bonus = p_bonus
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	var cols: Array = COLORS.get(kind, COLORS[WeaponData.Zone.FIRE])
	var disc := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	disc.mesh = pm
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	_mat.set_shader_parameter("color", Color(cols[0] * 0.55, _alpha()))
	_mat.set_shader_parameter("fill", true)
	_mat.set_shader_parameter("soft", true)
	disc.material_override = _mat
	disc.scale = Vector3.ONE * radius
	disc.position.y = 0.04
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	_parts = GPUParticles3D.new()
	_parts.amount = int(clampf(radius * 10.0, 8.0, 24.0))
	_parts.lifetime = 0.7
	_parts.local_coords = true
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ppm.emission_sphere_radius = radius * 0.8
	ppm.direction = Vector3.UP
	ppm.spread = 12.0
	ppm.initial_velocity_min = 0.6
	ppm.initial_velocity_max = 1.6
	ppm.gravity = Vector3(0, 0.6 if kind == WeaponData.Zone.FIRE else (0.05 if kind == WeaponData.Zone.DUST else -0.5), 0)
	if kind == WeaponData.Zone.DUST:                # polvo: motas que flotan despacio y duran más
		_parts.lifetime = 1.6
		_parts.amount = int(clampf(radius * 18.0, 16.0, 48.0))
		ppm.scale_min = 0.08
		ppm.scale_max = 0.18
		ppm.initial_velocity_min = 0.1
		ppm.initial_velocity_max = 0.4
		ppm.spread = 80.0
	ppm.scale_min = 0.06
	ppm.scale_max = 0.14
	var g := Gradient.new()
	g.set_color(0, Color(cols[1], 1.0))
	g.set_color(1, Color(cols[0], 0.0))
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
	_parts.position.y = 0.1
	add_child(_parts)
	if kind == WeaponData.Zone.FIRE:
		_light = OmniLight3D.new()
		_light.light_color = cols[0]
		_light.light_energy = 1.0
		_light.omni_range = radius * 2.2
		_light.position.y = 0.6
		add_child(_light)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= life:
		_parts.emitting = false
		if _t >= life + FADE: queue_free()
		return
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
	var cols: Array = COLORS.get(kind, COLORS[WeaponData.Zone.FIRE])
	_mat.set_shader_parameter("color", Color(cols[0] * 0.55, _alpha() * fade))
	if _light: _light.light_energy = (0.8 + 0.4 * sin(_t * 23.0) * sin(_t * 7.0)) * fade

## Opacidad de la mancha: el polvo, más densa para que se lea sobre la nieve.
func _alpha() -> float:
	return 0.75 if kind == WeaponData.Zone.DUST else 0.5
