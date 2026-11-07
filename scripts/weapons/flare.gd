class_name Flare
extends Node3D
## Bengala encendida en el suelo: una luz roja intensa que atrae a los enemigos cercanos
## (van hacia ella en lugar de hacia el jugador) mientras arde. Las élites no se dejan
## engañar. Con la cordura completa (hito 2.11), su luz también recuperará cordura.

var world: CombatWorld
var life := 4.0
var radius := 7.0
var _t := 0.0
var _pulse := 0.0
var _light: OmniLight3D
var _core: MeshInstance3D
var _parts: GPUParticles3D
var _smoke: GPUParticles3D

func setup(p_world: CombatWorld, pos: Vector3, p_life: float, p_radius: float) -> Flare:
	world = p_world; life = p_life; radius = p_radius
	position = Vector3(pos.x, 0.0, pos.z)
	return self

## Núcleo y chispas, compartidos por todas las bengalas (06-11-2026: antes, nuevos en cada una).
static var _core_mat: StandardMaterial3D
static var _spark_pm: ParticleProcessMaterial
static var _spark_box: BoxMesh

static func _shared() -> void:
	_core_mat = StandardMaterial3D.new()
	_core_mat.albedo_color = Color(0.7, 0.12, 0.1)
	_core_mat.emission_enabled = true
	_core_mat.emission = Color(1.0, 0.35, 0.2)
	_core_mat.emission_energy_multiplier = 1.5
	_spark_pm = ParticleProcessMaterial.new()
	_spark_pm.direction = Vector3.UP
	_spark_pm.spread = 40.0
	_spark_pm.initial_velocity_min = 1.0
	_spark_pm.initial_velocity_max = 2.5
	_spark_pm.gravity = Vector3(0, -3.0, 0)
	_spark_pm.scale_min = 0.03
	_spark_pm.scale_max = 0.06
	_spark_pm.color = Color(1.0, 0.7, 0.4)
	_spark_box = BoxMesh.new()                      # propia: lleva el material de las chispas
	_spark_box.size = Vector3.ONE
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.vertex_color_use_as_albedo = true
	_spark_box.material = pmat

func _ready() -> void:
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.32, 0.22)
	_light.light_energy = 3.0
	_light.omni_range = 6.0
	_light.position.y = 0.5
	add_child(_light)
	if _core_mat == null: _shared()
	_core = MeshInstance3D.new()
	_core.mesh = VoxelFx.box(Vector3(0.12, 0.12, 0.3))
	_core.material_override = _core_mat
	_core.position.y = 0.06
	_core.rotation.y = randf() * TAU
	add_child(_core)
	_parts = GPUParticles3D.new()                     # chispas que saltan
	_parts.amount = 18
	_parts.lifetime = 0.5
	_parts.process_material = _spark_pm
	_parts.draw_pass_1 = _spark_box
	_parts.position.y = 0.12
	add_child(_parts)
	# columna de humo rojizo que sube de la bengala (11-10-2026)
	_smoke = VoxelFx.emitter("smoke", 0.4, false, false, Color(1.0, 0.55, 0.5))
	_smoke.position.y = 0.2
	add_child(_smoke)

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	_pulse -= delta
	if _pulse <= 0.0:                                 # atraer cada 1/6 s basta
		_pulse = 0.16
		for e in world.enemies_in_circle(global_position, radius):
			if e.has_method("lure"): e.lure(global_position, 0.4)

func _process(_delta: float) -> void:
	var k := 1.0 - smoothstep(life - 0.6, life, _t)
	_light.light_energy = (2.4 + 0.8 * sin(_t * 31.0) * sin(_t * 13.0)) * k
