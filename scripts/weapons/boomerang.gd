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
	for side in [-1, 1]:
		var arm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.1, 0.05, 0.42)
		arm.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = WOOD
		m.roughness = 0.8
		arm.material_override = m
		arm.rotation.y = side * 0.55
		arm.position = Vector3(side * 0.1, 0, 0.1)
		_spin.add_child(arm)
		var band := MeshInstance3D.new()             # franja pintada en cada brazo
		var bb := BoxMesh.new()
		bb.size = Vector3(0.11, 0.06, 0.07)
		band.mesh = bb
		var pm := StandardMaterial3D.new()
		pm.albedo_color = PAINT
		band.material_override = pm
		band.position = Vector3(0, 0, 0.12)
		arm.add_child(band)
	reset_physics_interpolation.call_deferred()

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
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
		hits += 1

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_spin.rotation.y += 22.0 * delta
