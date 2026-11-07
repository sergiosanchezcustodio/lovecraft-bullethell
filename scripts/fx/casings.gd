class_name Casings
extends MultiMeshInstance3D
## Casquillos (hito 18.4, D-50): cada disparo de un arma de fuego suelta un casquillo de cubitos que
## salta a la derecha del cañón, gira, rebota en el suelo y se queda un momento antes de encogerse.
## Latón para las pistolas y los fusiles (más largo), rojo para los cartuchos de las escopetas;
## los dardos, arpones y demás no sueltan nada. Todos en un MultiMesh (una llamada de dibujo), con
## tope (`MAX`: el más viejo deja sitio). Con `weapon_fx` 0 (Baja), nada; en 1 (Media), la mitad
## de los casquillos y menos tiempo en el suelo. `casings=false` para comparar.

const MAX := 64
const LIFE := 2.4
const SHRINK := 0.5
const GRAVITY := 14.0
## Por aspecto de bala: [tamaño, color].
const LOOKS := {
	"": [Vector3(0.035, 0.035, 0.07), Color(0.82, 0.62, 0.25)],
	"smg": [Vector3(0.035, 0.035, 0.065), Color(0.82, 0.62, 0.25)],
	"rifle": [Vector3(0.035, 0.035, 0.11), Color(0.86, 0.66, 0.28)],
	"pellet": [Vector3(0.055, 0.055, 0.1), Color(0.7, 0.14, 0.1)],
}

static var enabled := true
static var _inst: Casings
static var _rng := RandomNumberGenerator.new()   ## propio: lo que se ve no cambia el azar de la partida

var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _rot := PackedVector3Array()
var _spin := PackedVector3Array()
var _age := PackedFloat32Array()
var _size := PackedVector3Array()
var _n := 0
var _next := 0
var _life := LIFE
var _every := 1
var _shots := 0

## Un casquillo del disparo en `at` hacia `dir`, con el aspecto `look` de la bala.
static func eject(at: Vector3, dir: Vector3, look: String) -> void:
	if not enabled or not LOOKS.has(look): return
	if not is_instance_valid(_inst) or not _inst.is_inside_tree(): return
	_inst._eject(at, dir, LOOKS[look])

static func setup(world: CombatWorld) -> void:
	if not enabled or world == null: return
	var lv := int(Quality.value("weapon_fx", 2))
	if lv <= 0: return
	var c := Casings.new()
	c.name = "Casings"
	if lv == 1:
		c._every = 2
		c._life = LIFE * 0.6
	world.fx.add_child(c)
	_inst = c

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = VoxelFx.box1()
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	multimesh = mm
	var m := VoxelFx.std()
	m.vertex_color_use_as_albedo = true
	m.metallic = 0.7
	m.roughness = 0.35
	material_override = m
	custom_aabb = AABB(Vector3(-500, -5, -500), Vector3(1000, 20, 1000))
	for a in [_pos, _vel, _rot, _spin, _size]: a.resize(MAX)
	_age.resize(MAX)

func _eject(at: Vector3, dir: Vector3, look: Array) -> void:
	_shots += 1
	if _every > 1 and _shots % _every != 0: return
	var i := _next
	_next = (_next + 1) % MAX
	if _n < MAX: _n += 1
	var d := Vector3(dir.x, 0, dir.z).normalized()
	var right := d.cross(Vector3.UP).normalized()
	_pos[i] = at + right * 0.12
	_vel[i] = right * _rng.randf_range(1.3, 2.2) + Vector3.UP * _rng.randf_range(1.8, 2.8) - d * _rng.randf_range(0.2, 0.6)
	_rot[i] = Vector3(_rng.randf() * TAU, atan2(d.x, d.z), 0)
	_spin[i] = Vector3(_rng.randf_range(14, 24), _rng.randf_range(-6, 6), _rng.randf_range(-10, 10))
	_age[i] = 0.0
	_size[i] = look[0]
	multimesh.set_instance_color(i, look[1])

func _process(delta: float) -> void:
	if _n == 0: return
	var t0 := Prof.start()
	var mm := multimesh
	for i in _n:
		var a := _age[i] + delta
		_age[i] = a
		var s := 1.0 - clampf((a - (_life - SHRINK)) / SHRINK, 0.0, 1.0)
		if s <= 0.0:
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -50, 0)))
			continue
		var v := _vel[i]
		var p := _pos[i]
		var sz := _size[i]
		var floor_y := sz.x * 0.5
		if v != Vector3.ZERO:
			v.y -= GRAVITY * delta
			p += v * delta
			_rot[i] += _spin[i] * delta
			if p.y <= floor_y:
				p.y = floor_y
				if v.y < -1.0:                                   # rebota, cada vez menos
					v = Vector3(v.x * 0.55, -v.y * 0.32, v.z * 0.55)
					_spin[i] *= 0.5
				else:                                            # se queda tumbado
					v = Vector3.ZERO
					var r := _rot[i]
					_rot[i] = Vector3(0, r.y, PI * 0.5 * roundf(r.z / (PI * 0.5)))
			_vel[i] = v
			_pos[i] = p
		var b := Basis.from_euler(_rot[i]) * Basis.from_scale(sz * s)
		mm.set_instance_transform(i, Transform3D(b, p))
	mm.visible_instance_count = _n
	Prof.stop("casquillos", t0)
