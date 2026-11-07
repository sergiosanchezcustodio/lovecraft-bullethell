class_name Boomerang
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Bumerán: sale hacia `dir`, frena al llegar a su alcance y vuelve a las manos del personaje
## (le sigue aunque se mueva). Golpea una vez a cada enemigo a la ida y otra a la vuelta.
## Voxel: dos brazos de madera en V que giran.

var player: Player
var world: CombatWorld
var dir := Vector3.FORWARD
var reach := 7.0
var speed := 12.0
var hit_r := 0.45
var damage := 10.0
var push := 0.8
var bonus := {}
var returning := false
var stun_s := 0.0                            ## s que deja aturdido a lo que toca (Llave de los sueños, hito 16.25)
var look := ""                               ## "llave": la llave de plata de Carter (hito 16.25); "": de madera
var hits := 0                                ## golpes (tests)
var _hit := {}                               ## ids ya golpeados en este tramo
var _out := 0.0                              ## m recorridos a la ida
var _t := 0.0
var _spin: Node3D

const WOOD := Color(0.58, 0.38, 0.2)
const PAINT := Color(0.75, 0.3, 0.16)
const MAX_LIFE := 6.0

func setup(p_player: Player, p_world: CombatWorld, p_dir: Vector3, p_reach: float, p_speed: float,
		p_hit_r: float, p_damage: float, p_push: float, p_bonus: Dictionary) -> Boomerang:
	player = p_player; world = p_world; dir = Vector3(p_dir.x, 0, p_dir.z).normalized(); reach = p_reach
	speed = p_speed; hit_r = p_hit_r; damage = p_damage; push = p_push; bonus = p_bonus
	position = Vector3(player.global_position.x, 0.9, player.global_position.z)
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	_spin = Node3D.new()
	add_child(_spin)
	if look == "llave":
		_key()
		reset_physics_interpolation.call_deferred()
		return
	if _wood_mat == null:                            # materiales compartidos (06-11-2026)
		_wood_mat = VoxelFx.std()
		_wood_mat.albedo_color = WOOD
		_wood_mat.roughness = 0.8
		_paint_mat = VoxelFx.std()
		_paint_mat.albedo_color = PAINT
	for side in [-1, 1]:
		var arm := MeshInstance3D.new()
		arm.mesh = VoxelFx.box(Vector3(0.1, 0.05, 0.42))
		arm.material_override = _wood_mat
		arm.rotation.y = side * 0.55
		arm.position = Vector3(side * 0.1, 0, 0.1)
		_spin.add_child(arm)
		var band := MeshInstance3D.new()             # franja pintada en cada brazo
		band.mesh = VoxelFx.box(Vector3(0.11, 0.06, 0.07))
		band.material_override = _paint_mat
		band.position = Vector3(0, 0, 0.12)
		arm.add_child(band)
	add_child(VoxelFx.emitter("streak", 0.35, false, false, Color(0.75, 0.6, 0.4)))   # rastro al girar (11-10-2026)
	reset_physics_interpolation.call_deferred()

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_spin.rotation.y += 22.0 * delta                # en la física, con la raíz: así se interpola (06-11-2026)
	_t += delta
	if not is_instance_valid(player) or _t > MAX_LIFE:
		queue_free()
		return
	if not returning:
		var k := clampf(1.0 - _out / reach, 0.25, 1.0)          # frena al final de la ida
		var step := speed * k * delta
		position += dir * step
		_out += step
		if _out >= reach:
			returning = true
			_hit.clear()
	else:
		var home := Vector3(player.global_position.x, 0.9, player.global_position.z)
		var to := home - position
		if to.length() < 0.5:
			queue_free()
			return
		position += to.normalized() * minf(speed * 1.1 * delta, to.length())
	for e in world.enemies_in_circle(position, hit_r):
		var id := e.get_instance_id()
		if _hit.has(id): continue
		_hit[id] = true
		var d := Damage.new(damage, 0.0)
		var away := e.global_position - position
		d.knockback = Vector3(away.x, 0, away.z).normalized() * push
		d.bonus = bonus
		e.take_damage(d)
		if stun_s > 0.0 and e.is_alive() and e.has_method("stun"): e.stun(stun_s)
		hits += 1

## La llave de plata de Randolph Carter: ojo, caña y paletón de plata que brilla, girando.
static var _wood_mat: StandardMaterial3D
static var _paint_mat: StandardMaterial3D
static var _key_mat: StandardMaterial3D

func _key() -> void:
	if _key_mat == null:
		_key_mat = VoxelFx.std()
		_key_mat.albedo_color = Color(0.82, 0.88, 0.98)
		_key_mat.metallic = 0.6
		_key_mat.roughness = 0.3
		_key_mat.emission_enabled = true
		_key_mat.emission = Color(0.55, 0.70, 1.0)
		_key_mat.emission_energy_multiplier = 1.4
	var m := _key_mat
	for b: Array in [[Vector3(0.05, 0.04, 0.18), Vector3(0, 0, 0.12)], [Vector3(0.05, 0.04, 0.18), Vector3(0, 0, -0.04)],   # el ojo
			[Vector3(0.16, 0.04, 0.05), Vector3(-0.07, 0, 0.04)], [Vector3(0.16, 0.04, 0.05), Vector3(0.07, 0, 0.04)],
			[Vector3(0.05, 0.04, 0.34), Vector3(0, 0, -0.27)],                                                         # la caña
			[Vector3(0.10, 0.04, 0.05), Vector3(0.06, 0, -0.38)], [Vector3(0.07, 0.04, 0.05), Vector3(0.05, 0, -0.30)]]:   # el paletón
		var mi := MeshInstance3D.new()
		mi.mesh = VoxelFx.box(b[0])
		mi.position = b[1] + Vector3(0, 0, 0.12)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_spin.add_child(mi)
	add_child(VoxelFx.emitter("streak", 0.35, false, false, Color(0.65, 0.78, 1.0)))
