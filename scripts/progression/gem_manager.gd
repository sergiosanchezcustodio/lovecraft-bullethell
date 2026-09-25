class_name GemManager
extends Node3D
## Gemas de experiencia: saltan del enemigo al morir, flotan girando y, cuando un jugador
## entra en su radio de recogida, vuelan hacia él y suman experiencia al tocarlo.
## Como las balas: arrays compactos y un único MultiMesh.

const MAX_GEMS := 2048
const COLOR := Color(0.35, 0.95, 0.9)      ## cian: distinto de todos los colores de daño

var world: CombatWorld
var rules: ProgressionData
var count := 0
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _value := PackedFloat32Array()
var _age := PackedFloat32Array()
var _homing := PackedByteArray()
var _mm: MultiMesh
var _buffer := PackedFloat32Array()

func _init() -> void:
	name = "Gems"
	_pos.resize(MAX_GEMS); _vel.resize(MAX_GEMS); _value.resize(MAX_GEMS)
	_age.resize(MAX_GEMS); _homing.resize(MAX_GEMS)

func _ready() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = _gem_mesh()
	_mm.instance_count = MAX_GEMS
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = COLOR * 0.75                  # compensa el tonemapper (ver bullet.gdshader)
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-200, -10, -200), Vector3(400, 20, 400))
	add_child(mmi)
	_buffer.resize(MAX_GEMS * 12)

## Octaedro pequeño: un cristal.
func _gem_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, 1, 0); var bot := Vector3(0, -1, 0)
	var ring := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]
	for i in 4:
		var a: Vector3 = ring[i]; var b: Vector3 = ring[(i + 1) % 4]
		for tri in [[top, b, a], [bot, a, b]]:
			for v: Vector3 in tri: st.add_vertex(v * Vector3(0.09, 0.14, 0.09))
	return st.commit()

## Suelta experiencia en una posición, repartida en gemas que saltan un poco.
func drop(pos: Vector3, value: float) -> void:
	var n := clampi(int(ceil(value / 5.0)), 1, 6)
	for k in n:
		if count >= MAX_GEMS: return
		var a := randf() * TAU
		_pos[count] = Vector3(pos.x, 0.5, pos.z)
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
				target.progress.add_xp(_value[i])
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
	_pos[i] = _pos[last]; _vel[i] = _vel[last]; _value[i] = _value[last]
	_age[i] = _age[last]; _homing[i] = _homing[last]
	count = last

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in count:
		var o := i * 12
		var a := t * 2.5 + i * 0.7
		var s := 1.0 + clampf(_value[i] / 10.0, 0.0, 1.5)
		var c := cos(a) * s; var sn := sin(a) * s
		var bob := sin(t * 3.0 + i) * 0.05 if _homing[i] == 0 else 0.0
		var p := _pos[i]
		_buffer[o] = c; _buffer[o + 1] = 0.0; _buffer[o + 2] = sn; _buffer[o + 3] = p.x
		_buffer[o + 4] = 0.0; _buffer[o + 5] = s; _buffer[o + 6] = 0.0; _buffer[o + 7] = p.y + bob
		_buffer[o + 8] = -sn; _buffer[o + 9] = 0.0; _buffer[o + 10] = c; _buffer[o + 11] = p.z
	RenderingServer.multimesh_set_buffer(_mm.get_rid(), _buffer)
	_mm.visible_instance_count = count
