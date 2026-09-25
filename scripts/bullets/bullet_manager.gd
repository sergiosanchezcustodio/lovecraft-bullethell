class_name BulletManager
extends Node3D
## Todas las balas del juego, sin un nodo por bala: arrays compactos que se recorren
## en cada paso de física y un único MultiMesh que se rellena de una vez por fotograma.
## Colisiones: las balas de los jugadores contra la rejilla de enemigos de CombatWorld;
## las enemigas, por distancia contra los jugadores (como mucho cuatro).

enum Team { PLAYER, ENEMY }
## Estilo visual (lenguaje de daños, GDD 4.4): lo lee el shader por instancia.
enum Style { PLAYER, PHYSICAL, MENTAL, MIXED }

const MAX_BULLETS := 4096
const HEIGHT := 0.8                          ## altura de vuelo (a la altura del pecho)

var world: CombatWorld
var count := 0

var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _radius := PackedFloat32Array()          ## radio de colisión (m)
var _size := PackedFloat32Array()            ## radio visual (m), mayor que el de colisión
var _life := PackedFloat32Array()
var _age := PackedFloat32Array()
var _phys := PackedFloat32Array()
var _ment := PackedFloat32Array()
var _team := PackedByteArray()
var _style := PackedByteArray()
var _pierce := PackedInt32Array()
var _last_hit: Array[Object] = []            ## último objetivo tocado (para las que atraviesan)

var _mm: MultiMesh
var _buffer := PackedFloat32Array()

func _init() -> void:
	name = "Bullets"
	# Uno a uno: un Packed*Array metido en otro array es una copia y redimensionarla no sirve
	_pos.resize(MAX_BULLETS); _vel.resize(MAX_BULLETS)
	_radius.resize(MAX_BULLETS); _size.resize(MAX_BULLETS); _life.resize(MAX_BULLETS)
	_age.resize(MAX_BULLETS); _phys.resize(MAX_BULLETS); _ment.resize(MAX_BULLETS)
	_team.resize(MAX_BULLETS); _style.resize(MAX_BULLETS); _pierce.resize(MAX_BULLETS)
	_last_hit.resize(MAX_BULLETS)

func _ready() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)                 # el shader escala por el radio visual
	_mm.mesh = quad
	_mm.instance_count = MAX_BULLETS
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "BulletMesh"
	mmi.multimesh = _mm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/bullets/bullet.gdshader")
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-200, -10, -200), Vector3(400, 20, 400))   # nunca se descarta por visibilidad
	add_child(mmi)
	_buffer.resize(MAX_BULLETS * 16)

## Crea una bala. `pos` se proyecta a la altura de vuelo.
func spawn(team: Team, style: Style, pos: Vector3, vel: Vector3, radius: float, size: float,
		damage: Damage, life: float, pierce: int = 0) -> void:
	if count >= MAX_BULLETS: return
	var i := count
	_pos[i] = Vector3(pos.x, HEIGHT, pos.z)
	_vel[i] = Vector3(vel.x, 0.0, vel.z)
	_radius[i] = radius
	_size[i] = size
	_life[i] = life
	_age[i] = 0.0
	_phys[i] = damage.physical
	_ment[i] = damage.mental
	_team[i] = team
	_style[i] = style
	_pierce[i] = pierce
	_last_hit[i] = null
	count += 1

func clear() -> void:
	count = 0

func _physics_process(delta: float) -> void:
	var b := world.bounds if world != null else Rect2(-100, -100, 200, 200)
	var i := 0
	while i < count:
		_pos[i] += _vel[i] * delta
		_age[i] += delta
		var dead := _age[i] >= _life[i] or not b.has_point(Vector2(_pos[i].x, _pos[i].z))
		if not dead and world != null:
			dead = _collide_player_bullet(i) if _team[i] == Team.PLAYER else _collide_enemy_bullet(i)
		if dead:
			_remove(i)          # la última ocupa su hueco: no avanzar i
		else:
			i += 1

func _collide_enemy_bullet(i: int) -> bool:
	var p := Vector2(_pos[i].x, _pos[i].z)
	for pl in world.players:
		if not pl.is_hittable(): continue
		var r := _radius[i] + pl.data.hurt_radius
		if p.distance_squared_to(Vector2(pl.global_position.x, pl.global_position.z)) <= r * r:
			var d := Damage.new(_phys[i], _ment[i])
			d.knockback = _vel[i].normalized()
			pl.take_damage(d)
			return true
	return false

func _collide_player_bullet(i: int) -> bool:
	for id in world.grid.query_circle(Vector2(_pos[i].x, _pos[i].z), _radius[i]):
		var t := world.target_at(id)
		if t == _last_hit[i] or not t.is_alive(): continue
		var d := Damage.new(_phys[i], _ment[i])
		d.knockback = _vel[i].normalized()
		t.take_damage(d)
		_last_hit[i] = t
		_pierce[i] -= 1
		if _pierce[i] < 0: return true
	return false

func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_pos[i] = _pos[last]; _vel[i] = _vel[last]; _radius[i] = _radius[last]; _size[i] = _size[last]
		_life[i] = _life[last]; _age[i] = _age[last]; _phys[i] = _phys[last]; _ment[i] = _ment[last]
		_team[i] = _team[last]; _style[i] = _style[last]; _pierce[i] = _pierce[last]; _last_hit[i] = _last_hit[last]
	_last_hit[last] = null
	count = last

func _process(_delta: float) -> void:
	# Buffer del MultiMesh: por instancia, transformación 3x4 (fila a fila) y 4 datos propios:
	# estilo, fase de animación, edad y radio visual.
	for i in count:
		var o := i * 16
		var s := _size[i]
		var p := _pos[i]
		_buffer[o] = s; _buffer[o + 1] = 0.0; _buffer[o + 2] = 0.0; _buffer[o + 3] = p.x
		_buffer[o + 4] = 0.0; _buffer[o + 5] = s; _buffer[o + 6] = 0.0; _buffer[o + 7] = p.y
		_buffer[o + 8] = 0.0; _buffer[o + 9] = 0.0; _buffer[o + 10] = s; _buffer[o + 11] = p.z
		_buffer[o + 12] = float(_style[i])
		# fase: en las del jugador, el rumbo (para alargar la trazadora); en las demás, un desfase
		_buffer[o + 13] = atan2(_vel[i].x, _vel[i].z) if _style[i] == Style.PLAYER else float(i % 17) * 0.37
		_buffer[o + 14] = _age[i]; _buffer[o + 15] = s
	RenderingServer.multimesh_set_buffer(_mm.get_rid(), _buffer)
	_mm.visible_instance_count = count
