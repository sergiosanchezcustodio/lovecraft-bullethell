class_name Ripples
extends MultiMeshInstance3D
## Ondas en el agua somera (hito 11.4, 28-10-2026): al andar por ella jugadores y enemigos, y al
## caer un cuerpo. Todas en un MultiMesh con water_rings.gdshader (un solo dibujo); como mucho
## MAX a la vez (si no hay sitio, se reutiliza la más vieja).

const MAX := 64
const LIFE := 1.1                              ## s que tarda en abrirse y apagarse una onda
const Y := 0.02                                ## altura del agua somera

var _pos := PackedVector3Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _radius := PackedFloat32Array()
var _alpha := PackedFloat32Array()
var _n := 0

## Onda de `radius` m en `pos` (en el suelo); `alpha`, su opacidad. La crea al primer uso.
static func add(fx_parent: Node, pos: Vector3, radius: float, alpha := 0.6, life := LIFE) -> void:
	if fx_parent == null: return
	var r: Ripples = fx_parent.get_meta("ripples") if fx_parent.has_meta("ripples") else null
	if r == null or not is_instance_valid(r):
		r = Ripples.new()
		r.name = "Ripples"
		fx_parent.add_child(r)
		fx_parent.set_meta("ripples", r)
	r._add(pos, radius, alpha, life)

func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pos.resize(MAX); _age.resize(MAX); _life.resize(MAX); _radius.resize(MAX); _alpha.resize(MAX)
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.2, 2.2)                # de radio 1,1: se escala con el radio de cada onda
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = pm
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	multimesh = mm
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/water_rings.gdshader")
	material_override = m
	custom_aabb = AABB(Vector3(-500, -1, -500), Vector3(1000, 2, 1000))   # se dibujan por todo el mundo

func _add(pos: Vector3, radius: float, alpha: float, life: float) -> void:
	var i := _n
	if _n >= MAX:                              # la más vieja deja su sitio
		i = 0
		for k in MAX:
			if _age[k] / _life[k] > _age[i] / _life[i]: i = k
	else:
		_n += 1
	_pos[i] = Vector3(pos.x, Y, pos.z)
	_age[i] = 0.0
	_life[i] = life
	_radius[i] = radius
	_alpha[i] = alpha

func _process(delta: float) -> void:
	var i := 0
	while i < _n:
		_age[i] += delta
		if _age[i] >= _life[i]:
			var last := _n - 1
			_pos[i] = _pos[last]; _age[i] = _age[last]; _life[i] = _life[last]
			_radius[i] = _radius[last]; _alpha[i] = _alpha[last]
			_n = last
			continue
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * _radius[i]), _pos[i]))
		multimesh.set_instance_custom_data(i, Color(_age[i] / _life[i], _radius[i], _alpha[i], 0.0))
		i += 1
	multimesh.visible_instance_count = _n

func count() -> int:
	return _n
