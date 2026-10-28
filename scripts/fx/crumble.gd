class_name Crumble
extends Node3D
## Enemigo que se desmorona al morir (hito 11.1, 27-10-2026): en vez de desaparecer de golpe, el
## modelo se queda en su última pose y se deshace en cubos de arriba abajo (crumble.gdshader)
## mientras DeathBurst suelta los trozos. Con muchas muertes a la vez (MAX_ALIVE), los que
## sobran desaparecen como antes.
## Muertes por familia (hito 12.7): si su script de animación tiene `death(m, k)` (DEATH_KIND,
## DEATH_TIME), antes de deshacerse cae de rodillas, se derrumba, se derrite o cae de lado
## desde la pose en que murió, y se deshace al final de la caída. La caída cuesta poco y va en
## todas las calidades: sin deshacerse (calidad Baja), al acabar de caer desaparece.

const LIFE := 0.55                             ## lo que tarda (las élites y los únicos, BIG_LIFE)
const BIG_LIFE := 1.1
const MAX_ALIVE := 16
const CUT_AT := 0.75                           ## en qué punto de la caída empieza a deshacerse
static var alive := 0
static var enabled := true                     ## calidad baja o pruebas (crumble=false): desaparecen como antes
static var falls := true                       ## caídas por familia (hito 12.7); falls=false para comparar
static var _mat: ShaderMaterial

var _model: Node3D
var _meshes: Array = []
var _life := LIFE
var _t := 0.0
var _ember := Color.WHITE
var _anim := ""                                ## modelo cuya caída se anima ("": se deshace ya)
var _fall := 0.0                               ## lo que dura la caída (s)
var _snap: Array = []                          ## pose en que murió, para fundir la caída con ella
var _dressed := false

## Lo que tarda en empezar a deshacerse (y a soltar los trozos) un modelo que cae así.
static func delay_for(model_name: String) -> float:
	return Anims.death_time(model_name) * CUT_AT if falls and model_name != "" else 0.0

## Se lleva `model` (lo saca de su enemigo conservando dónde está) y lo deshace. false si hay
## demasiados a la vez o el modelo no sirve: el enemigo lo libera como siempre.
static func start(fx_parent: Node, model: Node3D, ember: Color, big := false, model_name := "") -> bool:
	if not falls or Anims.death_time(model_name) <= 0.0: model_name = ""
	if (not enabled and model_name == "") or alive >= MAX_ALIVE or fx_parent == null or model == null or not model.has_meta("meshes"): return false
	var c := Crumble.new()
	c._life = BIG_LIFE if big else LIFE
	c._ember = ember
	if model_name != "":
		c._anim = model_name
		c._fall = Anims.death_time(model_name)
		c._snap = Anims.snapshot(model)
	c.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fx_parent.add_child(c)
	model.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # al cambiarlo de padre no siempre se entera de que el nuevo no interpola
	# un soporte donde estaba su padre (posición, giro y escala del enemigo): así la pose del
	# modelo sigue en su espacio y la caída puede ponerla
	var holder := Node3D.new()
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	c.add_child(holder)
	if model.get_parent() is Node3D: holder.global_transform = (model.get_parent() as Node3D).global_transform
	model.reparent(holder)
	c._model = model
	if c._anim == "": c._dress()
	else:
		for mi: MeshInstance3D in model.get_meta("meshes"):
			if not is_instance_valid(mi): continue
			mi.material_overlay = null                               # sin el destello del último golpe
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # se ahorra la pasada de sombras, como al deshacerse
	alive += 1
	return true

func _dress() -> void:
	_dressed = true
	for it: Array in dress(_model, _ember): _meshes.append(it[0])

## Pone el material de deshacerse a las mallas de `model`, entero (cut 0). Devuelve
## [[malla, material de antes, sombra de antes], …] para devolverlo con `undress` (aparecer en
## la niebla, hito 11.6: el mismo efecto al revés).
static func dress(model: Node3D, ember: Color) -> Array:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = preload("res://scripts/fx/crumble.gdshader")
		_mat.set_shader_parameter("colors_srgb", VoxelBuilder.colors_are_srgb())
	var out := []
	if model == null or not model.has_meta("meshes"): return out
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
		out.append([mi, mi.material_override, mi.cast_shadow])
		mi.material_overlay = null
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # se ahorra la pasada de sombras
		mi.material_override = _mat
		mi.set_instance_shader_parameter("vox", vs)
		mi.set_instance_shader_parameter("height", box.size.y)
		mi.set_instance_shader_parameter("base_y", box.position.y)
		mi.set_instance_shader_parameter("glow", 1.0 if int(mi.get_meta("kind", 0)) > 0 else 0.0)
		mi.set_instance_shader_parameter("ember", ember)
		mi.set_instance_shader_parameter("roughness_v", base.roughness if base != null else 0.6)
		mi.set_instance_shader_parameter("cut", 0.0)
	return out

static func set_cut(dressed: Array, cut: float) -> void:
	for it: Array in dressed:
		if is_instance_valid(it[0]): (it[0] as MeshInstance3D).set_instance_shader_parameter("cut", cut)

static func undress(dressed: Array) -> void:
	for it: Array in dressed:
		if not is_instance_valid(it[0]): continue
		var mi: MeshInstance3D = it[0]
		mi.material_override = it[1]
		mi.cast_shadow = it[2]
		mi.set_instance_shader_parameter("cut", 0.0)

func _process(delta: float) -> void:
	_t += delta
	var start := 0.0
	if _anim != "":                                # cae, fundiendo desde la pose en que murió
		var fk := clampf(_t / _fall, 0.0, 1.0)
		Anims.reset(_model)
		Anims.death(_anim, _model, fk)
		Anims.blend_from(_model, _snap, Anims.ease(_t / 0.15))
		start = _fall * CUT_AT
		if _t < start: return
		if not enabled:                            # calidad Baja: cae y desaparece, sin deshacerse
			queue_free()
			return
		if not _dressed: _dress()                  # se mide ya caído: se deshace de arriba abajo de lo que queda
	var k := clampf((_t - start) / _life, 0.0, 1.0)
	var cut := k * k * (3.0 - 2.0 * k) * 1.02
	for mi: MeshInstance3D in _meshes:
		if is_instance_valid(mi): mi.set_instance_shader_parameter("cut", cut)
	if _t - start >= _life: queue_free()

func _exit_tree() -> void:
	alive -= 1
