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
## Muertes según el daño (hito 17.9, Damage.how). burn: se queda en pie, se ennegrece con brasas
## (CHAR_TIME) y se deshace en ceniza, despacio; blast: las piezas salen volando con su giro y se
## deshacen en el aire; shock: tiembla en pie echando humo (SHOCK_TIME), ennegrecido a medias, y
## luego cae a la manera de su familia.
const CHAR_TIME := 0.4
const SHOCK_TIME := 0.45
const BLAST_GRAVITY := 9.0
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
var _how := &""
var _parts: Array = []                         ## blast: [pieza, velocidad, eje de giro, giro]
var _puffed := false

## Lo que tarda en empezar a deshacerse (y a soltar los trozos) un modelo que cae así.
static func delay_for(model_name: String, how := &"") -> float:
	if how == &"burn": return CHAR_TIME
	if how == &"blast": return 0.0
	var fall := Anims.death_time(model_name) * CUT_AT if falls and model_name != "" else 0.0
	return fall + (SHOCK_TIME if how == &"shock" else 0.0)

## Se lleva `model` (lo saca de su enemigo conservando dónde está) y lo deshace. false si hay
## demasiados a la vez o el modelo no sirve: el enemigo lo libera como siempre. Un modelo fuera
## del árbol (el de un enemigo de la horda) entra directamente aquí, colocado como si colgara de
## `frame` (06-11-2026: antes entraba en el enemigo y se cambiaba de padre, dos veces en la escena).
static func start(fx_parent: Node, model: Node3D, ember: Color, big := false, model_name := "", how := &"",
		frame: Node3D = null) -> bool:
	if not falls or Anims.death_time(model_name) <= 0.0: model_name = ""
	if how == &"burn" and not enabled: how = &""                 # calidad Baja: sin el material, a su manera
	if how == &"burn" or how == &"blast": model_name = ""         # ni caen: arden en pie o revientan
	if (not enabled and model_name == "") or alive >= MAX_ALIVE or fx_parent == null or model == null or not model.has_meta("meshes"): return false
	var c := Crumble.new()
	c._life = BIG_LIFE if big else LIFE
	c._ember = ember
	c._how = how
	if how == &"burn":
		c._life *= 1.6                                     # la ceniza cae despacio
		c._ember = Color(1.0, 0.42, 0.1)
	elif how == &"shock": c._ember = Color(0.6, 0.8, 1.0)
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
	elif frame != null and frame.is_inside_tree(): holder.global_transform = frame.global_transform
	if model.get_parent() == null: holder.add_child(model)   # su transformación ya es la de dentro de `frame`
	else: model.reparent(holder)
	c._model = model
	if how == &"blast": c._launch()
	if c._anim == "" and (enabled or how != &"blast"): c._dress()
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
		mi.set_instance_shader_parameter("char_k", 0.0)
	return out

## Explosión: cada pieza de primer nivel sale hacia fuera y arriba, girando (las que cuelgan de
## otra van con ella).
func _launch() -> void:
	var parts: Dictionary = _model.get_meta("part_nodes", {})
	var i := 0
	for n: String in parts:
		var p: Node3D = parts[n]
		if not is_instance_valid(p) or p.get_parent() != _model: continue
		i += 1
		var h := fposmod(sin(float(i) * 12.9898 + float(get_instance_id() % 997)) * 43.5453, 1.0)   # argumento pequeño: no hace falta el hash del cielo
		var out := Vector3(p.position.x, 0.0, p.position.z)
		if out.length() < 0.05: out = Vector3(cos(h * TAU), 0.0, sin(h * TAU))
		var v := out.normalized() * (1.6 + 1.4 * h) + Vector3.UP * (2.6 + 1.8 * (1.0 - h))
		var axis := Vector3(h - 0.5, 0.4, 0.7 - h).normalized()
		_parts.append([p, v, axis, (6.0 + 8.0 * h) * (1.0 if i % 2 == 0 else -1.0)])

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
	var ft := _t                                   # reloj de la caída
	if _how == &"shock":                           # el rayo: tiembla en pie, humeando, y luego cae
		if not _puffed:
			_puffed = true
			_smoke(0.25)
		ft = _t - SHOCK_TIME
		start = SHOCK_TIME
		if ft < 0.0:
			_tremble()
			return
		if _dressed: Crumble.set_char(_meshes, 0.5)       # medio quemado
	if _how == &"blast":
		_fly(delta)
		start = 0.3                                # enteras un momento, luego se deshacen en el aire
		if _t < start: return
	if _how == &"burn":                            # arde en pie: se ennegrece con brasas y luego ceniza
		var ck := clampf(_t / CHAR_TIME, 0.0, 1.0)
		for mi: MeshInstance3D in _meshes:
			if is_instance_valid(mi): mi.set_instance_shader_parameter("char_k", ck)
		if not _puffed and _t >= CHAR_TIME * 0.5:
			_puffed = true
			_smoke(0.35)
		start = CHAR_TIME
		if _t < start: return
	if _anim != "":                                # cae, fundiendo desde la pose en que murió
		var fk := clampf(ft / _fall, 0.0, 1.0)
		Anims.reset(_model)
		Anims.death(_anim, _model, fk)
		Anims.blend_from(_model, _snap, Anims.ease(ft / 0.15))
		start += _fall * CUT_AT
		if _t < start: return
		if not enabled:                            # calidad Baja: cae y desaparece, sin deshacerse
			queue_free()
			return
		if not _dressed:                           # se mide ya caído: se deshace de arriba abajo de lo que queda
			_dress()
			if _how == &"shock": Crumble.set_char(_meshes, 0.5)
	var k := clampf((_t - start) / _life, 0.0, 1.0)
	var cut := k * k * (3.0 - 2.0 * k) * 1.02
	for mi: MeshInstance3D in _meshes:
		if is_instance_valid(mi): mi.set_instance_shader_parameter("cut", cut)
	if _how == &"blast" and not enabled and _t >= 0.7:   # calidad Baja: vuelan y desaparecen
		queue_free()
		return
	if _t - start >= _life: queue_free()

## Temblor del electrocutado: cada pieza vibra deprisa alrededor de la pose en que murió.
func _tremble() -> void:
	Anims.reset(_model)
	Anims.blend_from(_model, _snap, 1.0)
	var parts: Dictionary = _model.get_meta("part_nodes", {})
	var i := 0
	for n: String in parts:
		var p: Node3D = parts[n]
		if not is_instance_valid(p): continue
		i += 1
		p.rotation += Vector3(sin(_t * 71.0 + i), sin(_t * 83.0 + i * 2.1), sin(_t * 67.0 + i * 0.7)) * 0.09
	_model.position += Vector3(sin(_t * 97.0), 0.0, cos(_t * 89.0)) * 0.012

## Las piezas de la explosión: tiro parabólico con su giro.
func _fly(delta: float) -> void:
	for it: Array in _parts:
		var p: Node3D = it[0]
		if not is_instance_valid(p): continue
		it[1] = (it[1] as Vector3) + Vector3.DOWN * BLAST_GRAVITY * delta
		p.position += (it[1] as Vector3) * delta
		if p.position.y < 0.0:                     # rebota un poco en el suelo
			p.position.y = 0.0
			it[1] = Vector3((it[1] as Vector3).x * 0.5, absf((it[1] as Vector3).y) * 0.3, (it[1] as Vector3).z * 0.5)
		p.rotate(it[2], float(it[3]) * delta)

func _smoke(r: float) -> void:
	if _model == null or not is_inside_tree(): return
	VoxelFx.puff(get_parent(), _model.global_position + Vector3.UP * 0.9, "smoke", r, Color(0.35, 0.34, 0.33), 1.6)

static func set_char(dressed: Array, k: float) -> void:
	for mi in dressed:
		var m: MeshInstance3D = mi if mi is MeshInstance3D else (mi as Array)[0]
		if is_instance_valid(m): m.set_instance_shader_parameter("char_k", k)

func _exit_tree() -> void:
	alive -= 1
