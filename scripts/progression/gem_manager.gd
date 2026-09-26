class_name GemManager
extends Node3D
## Gemas de experiencia: saltan del enemigo al morir, flotan girando y, cuando un jugador
## entra en su radio de recogida, vuelan hacia él y suman experiencia al tocarlo.
## Como las balas: arrays compactos y un único MultiMesh.

const MAX_GEMS := 2048
## Gema dorada tallada: facetas superiores claras, inferiores ámbar oscuro (contrasta con
## la nieve) y un destello blanco. Proyecta una pequeña sombra que la asienta en el suelo.
const TOP_A := Color(1.0, 0.9, 0.5)
const TOP_B := Color(1.0, 0.76, 0.24)
const LOW_A := Color(0.9, 0.52, 0.1)
const LOW_B := Color(0.62, 0.32, 0.05)
const GLINT := Color(1.0, 1.0, 0.92)

var world: CombatWorld
var rules: ProgressionData
var count := 0
var _pos := PackedVector3Array()
var _prev := PackedVector3Array()
var _vel := PackedVector3Array()
var _value := PackedFloat32Array()
var _age := PackedFloat32Array()
var _homing := PackedByteArray()
var _mm: MultiMesh
var _buffer := PackedFloat32Array()

func _init() -> void:
	name = "Gems"
	_pos.resize(MAX_GEMS); _prev.resize(MAX_GEMS); _vel.resize(MAX_GEMS); _value.resize(MAX_GEMS)
	_age.resize(MAX_GEMS); _homing.resize(MAX_GEMS)

func _ready() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = _gem_mesh()
	_mm.instance_count = MAX_GEMS
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # se interpola a mano
	mmi.multimesh = _mm
	# Material iluminado (las facetas brillan con la luna y los faroles) con un leve brillo
	# propio para verse de noche. Sin iluminar, el tonemapper dejaba el dorado casi blanco
	# (invisible sobre la nieve) o naranja rojizo.
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	mat.metallic = 0.4
	mat.roughness = 0.5          # brillo repartido (con 0,25 los reflejos parecían ojos)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.22)
	mat.emission_energy_multiplier = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED      # la gema es pequeña y se ve desde cualquier lado
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mmi.custom_aabb = AABB(Vector3(-200, -10, -200), Vector3(400, 20, 400))
	add_child(mmi)
	_buffer.resize(MAX_GEMS * 12)

## Gema tallada: mesa plana arriba, corona de seis facetas, cintura y pabellón en punta.
## Cada faceta lleva su color (se ve el tallado aunque el material no se ilumine).
func _gem_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const N := 6
	var s := Vector3(0.165, 0.165, 0.165)
	var table: Array[Vector3] = []
	var girdle: Array[Vector3] = []
	for i in N:
		var a := TAU * i / N
		table.append(Vector3(cos(a) * 0.45, 0.55, sin(a) * 0.45))
		girdle.append(Vector3(cos(a + PI / N) * 0.85, 0.12, sin(a + PI / N) * 0.85))
	var tip := Vector3(0, -1.05, 0)
	var center := Vector3(0, 0.55, 0)
	var tri := func(p0: Vector3, p1: Vector3, p2: Vector3, c: Color) -> void:
		for p in [p0, p1, p2]:
			st.set_color(c)
			st.add_vertex(p * s)
	for i in N:
		var j := (i + 1) % N
		tri.call(center, table[j], table[i], GLINT if i == 1 else TOP_A)          # mesa (una faceta brilla)
		tri.call(table[i], table[j], girdle[i], TOP_A if i % 2 == 0 else TOP_B)   # corona
		tri.call(table[j], girdle[j], girdle[i], TOP_B if i % 2 == 0 else TOP_A)
		tri.call(girdle[i], girdle[j], tip, LOW_A if i % 2 == 0 else LOW_B)       # pabellón
	st.generate_normals()            # vértices sin compartir: una normal por faceta (tallado plano)
	return st.commit()

## Suelta experiencia en una posición, repartida en gemas que saltan un poco.
func drop(pos: Vector3, value: float) -> void:
	var n := clampi(int(ceil(value / 5.0)), 1, 6)
	for k in n:
		if count >= MAX_GEMS: return
		var a := randf() * TAU
		_pos[count] = Vector3(pos.x, 0.5, pos.z)
		_prev[count] = _pos[count]
		_vel[count] = Vector3(cos(a) * randf_range(0.8, 2.2), randf_range(2.5, 4.0), sin(a) * randf_range(0.8, 2.2))
		_value[count] = value / n
		_age[count] = 0.0
		_homing[count] = 0
		count += 1

func _physics_process(delta: float) -> void:
	var t0 := Prof.start()
	var i := 0
	while i < count:
		_age[i] += delta
		_prev[i] = _pos[i]
		var p := _pos[i]
		var target: Player = null
		var best := INF
		for pl in world.players:
			if pl.health <= 0.0: continue
			var d := Vector2(pl.global_position.x - p.x, pl.global_position.z - p.z).length()
			var reach := pl.data.pickup_radius if _homing[i] == 0 else 99.0
			if d < reach and d < best and _age[i] > 0.35:
				best = d
				target = pl
		if target != null:
			_homing[i] = 1
			var to := target.global_position + Vector3(0, 0.8, 0) - p
			if to.length() < 0.45:
				target.progress.add_xp(_value[i] * target.data.xp_mult)
				_remove(i)
				continue
			_vel[i] = _vel[i].lerp(to.normalized() * rules.magnet_speed, 1.0 - exp(-10.0 * delta))
		else:
			_vel[i].y -= 12.0 * delta                      # cae
			_vel[i].x *= exp(-3.0 * delta); _vel[i].z *= exp(-3.0 * delta)
		p += _vel[i] * delta
		if _homing[i] == 0 and p.y < 0.3:
			p.y = 0.3
			_vel[i] = Vector3.ZERO
		_pos[i] = p
		i += 1
	Prof.stop("gemas", t0)

func _remove(i: int) -> void:
	var last := count - 1
	_pos[i] = _pos[last]; _prev[i] = _prev[last]; _vel[i] = _vel[last]; _value[i] = _value[last]
	_age[i] = _age[last]; _homing[i] = _homing[last]
	count = last

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var frac := Engine.get_physics_interpolation_fraction()
	for i in count:
		var o := i * 12
		var a := t * 2.5 + i * 0.7
		var s := 1.0 + clampf(_value[i] / 10.0, 0.0, 1.5)
		var c := cos(a) * s; var sn := sin(a) * s
		var bob := sin(t * 3.0 + i) * 0.05 if _homing[i] == 0 else 0.0
		var p := _prev[i].lerp(_pos[i], frac)
		_buffer[o] = c; _buffer[o + 1] = 0.0; _buffer[o + 2] = sn; _buffer[o + 3] = p.x
		_buffer[o + 4] = 0.0; _buffer[o + 5] = s; _buffer[o + 6] = 0.0; _buffer[o + 7] = p.y + bob
		_buffer[o + 8] = -sn; _buffer[o + 9] = 0.0; _buffer[o + 10] = c; _buffer[o + 11] = p.z
	RenderingServer.multimesh_set_buffer(_mm.get_rid(), _buffer)
	_mm.visible_instance_count = count
