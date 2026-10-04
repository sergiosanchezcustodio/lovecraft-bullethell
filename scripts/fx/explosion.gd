class_name Explosion
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Explosión: fogonazo de luz, esfera de fuego, onda expansiva en el suelo, cascotes
## y una mancha de quemado que se desvanece. Solo visual: el daño lo aplica quien explota.

var radius := 2.2
var _t := 0.0
var _light: OmniLight3D
var _ball: MeshInstance3D
var _ball_mat: StandardMaterial3D
var _wave: MeshInstance3D
var _wave_mat: ShaderMaterial
var _scorch_mat: ShaderMaterial

const LIFE := 4.0

func _ready() -> void:
	Damage.ctx = _wtag
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.65, 0.3)
	_light.omni_range = radius * 3.0
	_light.position.y = 0.8
	add_child(_light)
	_ball = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0; sm.height = 2.0; sm.radial_segments = 16; sm.rings = 8
	_ball.mesh = sm
	_ball_mat = StandardMaterial3D.new()
	_ball_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ball_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ball_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ball_mat.albedo_color = Color(1.0, 0.7, 0.3, 1.0)
	_ball.material_override = _ball_mat
	_ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ball.position.y = 0.5
	add_child(_ball)
	_wave = _flat_disc(Color(1.0, 0.75, 0.45, 0.8), false)
	_wave_mat = _wave.material_override
	var scorch := _flat_disc(Color(0.03, 0.025, 0.02, 0.6), true)
	scorch.scale = Vector3.ONE * radius * 0.75
	scorch.position.y = 0.03
	_scorch_mat = scorch.material_override
	_scorch_mat.set_shader_parameter("soft", true)
	add_child(_debris())

func _flat_disc(c: Color, filled: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/telegraph.gdshader")
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("fill", filled)
	m.set_shader_parameter("ring_width", 0.1)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.05
	add_child(mi)
	return mi

func _debris() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 28
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 65.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 7.5
	pm.gravity = Vector3(0, -14, 0)
	pm.scale_min = 0.05
	pm.scale_max = 0.12
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.8, 0.4))
	ramp.set_color(1, Color(0.15, 0.1, 0.08))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	pm.color_ramp = tex
	p.process_material = pm
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = bm
	p.draw_pass_1 = box
	p.position.y = 0.4
	p.emitting = true
	return p

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	_light.light_energy = 8.0 * maxf(0.0, 1.0 - _t / 0.35)
	var grow := clampf(_t / 0.12, 0.0, 1.0)
	_ball.scale = Vector3.ONE * radius * lerpf(0.25, 0.8, grow)
	_ball_mat.albedo_color.a = maxf(0.0, 1.0 - _t / 0.3)
	_ball.visible = _t < 0.3
	var w := clampf(_t / 0.35, 0.0, 1.0)
	_wave.scale = Vector3.ONE * radius * lerpf(0.3, 1.15, w)
	_wave_mat.set_shader_parameter("color", Color(1.0, 0.75, 0.45, 0.8 * (1.0 - w)))
	_wave.visible = _t < 0.35
	_scorch_mat.set_shader_parameter("color", Color(0.03, 0.025, 0.02, 0.6 * clampf((LIFE - _t) / 2.0, 0.0, 1.0)))
	if _t >= LIFE: queue_free()
