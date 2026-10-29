class_name Explosion
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Explosión (rehecha el 11-10-2026, en cubitos como el resto del juego): destello breve,
## bola de fuego que estalla hacia fuera y se apaga en humo, chispas, cascotes que rebotan
## en el suelo, onda expansiva y una mancha de quemado con brasas que se enfrían.
## Solo visual: el daño lo aplica quien explota.

var radius := 2.2
var _t := 0.0
var _light: OmniLight3D
var _ball: MeshInstance3D
var _ball_mat: StandardMaterial3D
var _wave: MeshInstance3D
var _wave_mat: ShaderMaterial
var _scorch_mat: ShaderMaterial
var _scorch: MeshInstance3D

const LIFE := 4.0
const MAX_LIT := 8                         ## explosiones con luz a la vez (hito 11.3): las demás, sin ella
static var max_lit := MAX_LIT              ## el de la calidad gráfica (Quality, hito 11.5)
static var lit := 0

func _ready() -> void:
	Auto.sfx_at("explosion", global_position)
	Gusts.push(get_parent(), global_position, 0.1 + radius * 0.05, radius * 3.0)   # mueve telas y plantas (hito 11.4)
	Damage.ctx = _wtag
	if lit < max_lit:
		lit += 1
		_light = OmniLight3D.new()
		_light.light_color = Color(1.0, 0.62, 0.28)
		_light.omni_range = radius * 3.0
		_light.position.y = 0.8
		add_child(_light)
	# destello del centro: solo los primeros fotogramas, debajo de la bola de cubos
	_ball = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	_ball.mesh = bm
	_ball_mat = StandardMaterial3D.new()
	_ball_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ball_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ball_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ball_mat.albedo_color = Color(1.0, 0.95, 0.8, 1.0)
	_ball.material_override = _ball_mat
	_ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ball.position.y = 0.5
	_ball.rotation = Vector3(0.6, randf() * TAU, 0.3)
	add_child(_ball)
	_wave = _flat_disc(Color(1.0, 0.75, 0.45, 0.8))
	_wave_mat = _wave.material_override
	var scorch := VoxelFx.ground(2, radius * 0.8)
	scorch.position.y = 0.03
	add_child(scorch)
	_scorch_mat = scorch.material_override
	_scorch = scorch
	var fx := Node3D.new()
	fx.position.y = 0.5
	add_child(fx)
	for r in ["fireball", "blast_smoke", "sparks", "debris"]:
		fx.add_child(VoxelFx.emitter(r, radius, true))
	VoxelFx.ensure_floor(get_parent())                 # suelo para que reboten los cascotes
	WallScorch.at(get_parent(), global_position, radius * 1.1)   # hollín en la pared de al lado (hito 12.11)
	if Ambient.step_now == "snow": _snow_blast()

## En la nieve, la aparta: centro barrido y reborde amontonado (hito 12.11), que se queda como
## las manchas (GroundMarks); en el agua somera, no.
func _snow_blast() -> void:
	var w := get_parent().get_parent() as CombatWorld
	if w != null and w.obstacles != null and w.obstacles.water_at(Vector2(global_position.x, global_position.z)) > 0.3: return
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/snow_blast.gdshader")
	m.set_shader_parameter("seed", randf() * 100.0)
	m.render_priority = -1                             # debajo del quemado
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3(radius * 1.3, 1.0, radius * 1.3)
	add_child(mi)
	mi.global_position = Vector3(global_position.x, 0.035, global_position.z)
	GroundMarks.keep(get_parent(), mi, GroundMarks.LINGER + 10.0)

func _flat_disc(c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/telegraph.gdshader")
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("fill", false)
	m.set_shader_parameter("ring_width", 0.08)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.05
	add_child(mi)
	return mi

func _drop_light() -> void:
	_light.queue_free()
	_light = null
	lit -= 1

func _exit_tree() -> void:
	if _light != null: _drop_light()

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _light != null:
		_light.light_energy = 9.0 * maxf(0.0, 1.0 - _t / 0.3)
		if _t > 0.3: _drop_light()                 # apagada, fuera (antes seguía 4 s con energía 0)
	var grow := clampf(_t / 0.06, 0.0, 1.0)
	_ball.scale = Vector3.ONE * radius * lerpf(0.3, 0.9, grow)
	_ball_mat.albedo_color.a = maxf(0.0, 1.0 - _t / 0.12)
	_ball.visible = _t < 0.12
	var w := clampf(_t / 0.3, 0.0, 1.0)
	_wave.scale = Vector3.ONE * radius * lerpf(0.3, 1.25, 1.0 - pow(1.0 - w, 2.0))
	_wave_mat.set_shader_parameter("color", Color(1.0, 0.8, 0.5, 0.85 * (1.0 - w)))
	_wave.visible = _t < 0.3
	_scorch_mat.set_shader_parameter("age", clampf(_t / LIFE, 0.0, 1.0))
	if _t >= LIFE:                                  # el quemado se queda un rato (hito 11.1)
		GroundMarks.keep(get_parent(), _scorch, GroundMarks.LINGER + 2.0)
		queue_free()
