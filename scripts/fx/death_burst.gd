class_name DeathBurst
extends Node3D
## Muerte de un enemigo: estallido de cubitos de sus colores y una mancha que se desvanece.

const PALETTES := {
	"pinguino": [Color(0.93, 0.93, 0.91), Color(0.56, 0.58, 0.62), Color(0.86, 0.62, 0.6)],
	"fragmento": [Color(0.03, 0.05, 0.05), Color(0.1, 0.25, 0.2), Color(0.72, 0.96, 0.4)],
	"acechador": [Color(0.06, 0.12, 0.11), Color(0.2, 0.33, 0.29), Color(0.92, 0.87, 0.68)],
}

var model := "pinguino"
var radius := 0.5
var _t := 0.0
var _stain_mat: ShaderMaterial

func setup(p_model: String, p_radius: float) -> void:
	model = p_model
	radius = p_radius

func _ready() -> void:
	var cols: Array = PALETTES.get(model, [Color.WHITE, Color.GRAY, Color.DARK_GRAY])
	var p := GPUParticles3D.new()
	p.amount = int(clampf(radius * 40.0, 14.0, 48.0))
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.8
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius * 0.6
	pm.direction = Vector3.UP
	pm.spread = 80.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 4.5
	pm.gravity = Vector3(0, -12, 0)
	pm.scale_min = 0.06
	pm.scale_max = 0.11
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([cols[0], cols[1], cols[2]])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_initial_ramp = gt
	p.process_material = pm
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	box.material = bm
	p.draw_pass_1 = box
	p.position.y = radius
	p.emitting = true
	add_child(p)
	var stain := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2, 2)
	stain.mesh = plane
	_stain_mat = ShaderMaterial.new()
	_stain_mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	_stain_mat.set_shader_parameter("soft", true)
	_stain_mat.set_shader_parameter("color", Color(cols[1], 0.5))
	stain.material_override = _stain_mat
	stain.scale = Vector3.ONE * radius * 1.2
	stain.position.y = 0.03
	stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stain)

func _process(delta: float) -> void:
	_t += delta
	var cols: Array = PALETTES.get(model, [Color.WHITE, Color.GRAY, Color.DARK_GRAY])
	_stain_mat.set_shader_parameter("color", Color(cols[1], 0.5 * clampf((3.0 - _t) / 1.5, 0.0, 1.0)))
	if _t > 3.0: queue_free()
