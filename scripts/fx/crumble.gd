class_name Crumble
extends Node3D
## Enemigo que se desmorona al morir (hito 11.1, 27-10-2026): en vez de desaparecer de golpe, el
## modelo se queda en su última pose y se deshace en cubos de arriba abajo (crumble.gdshader)
## mientras DeathBurst suelta los trozos. Con muchas muertes a la vez (MAX_ALIVE), los que
## sobran desaparecen como antes.

const LIFE := 0.55                             ## lo que tarda (las élites y los únicos, BIG_LIFE)
const BIG_LIFE := 1.1
const MAX_ALIVE := 16
static var alive := 0
static var enabled := true                     ## calidad baja o pruebas (crumble=false): desaparecen como antes
static var _mat: ShaderMaterial

var _model: Node3D
var _meshes: Array = []
var _life := LIFE
var _t := 0.0

## Se lleva `model` (lo saca de su enemigo conservando dónde está) y lo deshace. false si hay
## demasiados a la vez o el modelo no sirve: el enemigo lo libera como siempre.
static func start(fx_parent: Node, model: Node3D, ember: Color, big := false) -> bool:
	if not enabled or alive >= MAX_ALIVE or fx_parent == null or model == null or not model.has_meta("meshes"): return false
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = preload("res://scripts/fx/crumble.gdshader")
		_mat.set_shader_parameter("colors_srgb", VoxelBuilder.colors_are_srgb())
	var c := Crumble.new()
	c._life = BIG_LIFE if big else LIFE
	c.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fx_parent.add_child(c)
	model.reparent(c)
	c._model = model
	var vs := float(model.get_meta("voxel_size", VoxelBuilder.VOXEL)) * model.global_basis.get_scale().y
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in model.get_meta("meshes"):
		if not is_instance_valid(mi) or mi.mesh == null: continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	for mi: MeshInstance3D in model.get_meta("meshes"):
		if not is_instance_valid(mi): continue
		var base := mi.material_override as StandardMaterial3D
		mi.material_overlay = null
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # se ahorra la pasada de sombras
		mi.material_override = _mat
		mi.set_instance_shader_parameter("vox", vs)
		mi.set_instance_shader_parameter("height", box.size.y)
		mi.set_instance_shader_parameter("base_y", box.position.y)
		mi.set_instance_shader_parameter("glow", 1.0 if int(mi.get_meta("kind", 0)) > 0 else 0.0)
		mi.set_instance_shader_parameter("ember", ember)
		mi.set_instance_shader_parameter("roughness_v", base.roughness if base != null else 0.6)
		c._meshes.append(mi)
	alive += 1
	return true

func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / _life, 0.0, 1.0)
	var cut := k * k * (3.0 - 2.0 * k) * 1.02
	for mi: MeshInstance3D in _meshes:
		if is_instance_valid(mi): mi.set_instance_shader_parameter("cut", cut)
	if _t >= _life: queue_free()

func _exit_tree() -> void:
	alive -= 1
