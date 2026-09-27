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

func setup(p_world: CombatWorld, pos: Vector3, p_life: float, p_radius: float) -> Flare:
	world = p_world; life = p_life; radius = p_radius
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.32, 0.22)
	_light.light_energy = 3.0
	_light.omni_range = 6.0
	_light.position.y = 0.5
	add_child(_light)
	_core = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 0.3)
	_core.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.12, 0.1)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.35, 0.2)
	m.emission_energy_multiplier = 1.5
	_core.material_override = m
	_core.position.y = 0.06
	_core.rotation.y = randf() * TAU
	add_child(_core)
	_parts = GPUParticles3D.new()                     # chispas que saltan
	_parts.amount = 18
	_parts.lifetime = 0.5
	var ppm := ParticleProcessMaterial.new()
	ppm.direction = Vector3.UP
	ppm.spread = 40.0
	ppm.initial_velocity_min = 1.0
	ppm.initial_velocity_max = 2.5
	ppm.gravity = Vector3(0, -3.0, 0)
	ppm.scale_min = 0.03
	ppm.scale_max = 0.06
	ppm.color = Color(1.0, 0.7, 0.4)
	_parts.process_material = ppm
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.vertex_color_use_as_albedo = true
	box.material = pmat
	_parts.draw_pass_1 = box
	_parts.position.y = 0.12
	add_child(_parts)

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
