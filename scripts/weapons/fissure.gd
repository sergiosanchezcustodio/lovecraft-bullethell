class_name Fissure
extends Node3D
## Martillo de geólogo: el golpe abre en el suelo una grieta que avanza en línea recta a
## `speed` m/s hasta `length` m. A su paso, cada enemigo a menos de `half_width` recibe el
## daño una vez y queda aturdido `stun_s` s. Visual: la raja oscura se va dibujando y brotan
## esquirlas de hielo que suben y vuelven a hundirse.

var world: CombatWorld
var dir := Vector3.FORWARD
var length := 7.0
var speed := 14.0
var half_width := 0.7
var damage := 16.0
var stun_s := 0.5
var bonus := {}
var hits := 0                                ## golpes (tests)
var _hit := {}
var _t := 0.0
var _crack_mat: StandardMaterial3D
var _shard_mat: StandardMaterial3D
var _shards: Array[Dictionary] = []          ## {node, born}
var _next := 0.0                             ## m donde va la próxima esquirla

const SHARD_EVERY := 0.4
const SHARD_LIFE := 0.7
const FADE := 0.6

func setup(p_world: CombatWorld, origin: Vector3, p_dir: Vector3, p_length: float, p_speed: float,
		p_half_width: float, p_damage: float, p_stun: float, p_bonus: Dictionary) -> Fissure:
	world = p_world; dir = Vector3(p_dir.x, 0, p_dir.z).normalized(); length = p_length; speed = p_speed
	half_width = p_half_width; damage = p_damage; stun_s = p_stun; bonus = p_bonus
	position = Vector3(origin.x, 0.0, origin.z)
	return self

func _ready() -> void:
	_crack_mat = StandardMaterial3D.new()
	_crack_mat.albedo_color = Color(0.08, 0.1, 0.14)
	_crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shard_mat = StandardMaterial3D.new()
	_shard_mat.albedo_color = Color(0.72, 0.86, 0.95)
	_shard_mat.roughness = 0.2
	_shard_mat.metallic = 0.2
	_shard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func tip() -> float:
	return minf(_t * speed, length)

func _physics_process(delta: float) -> void:
	_t += delta
	var reach := tip()
	if _t * speed <= length + 0.01:
		for e in world.enemies_in_circle(position + dir * reach * 0.5, reach * 0.5 + half_width):
			var id := e.get_instance_id()
			if _hit.has(id): continue
			var rel := Vector2(e.global_position.x - position.x, e.global_position.z - position.z)
			var along := rel.dot(Vector2(dir.x, dir.z))
			if along < 0.0 or along > reach: continue
			if absf(rel.cross(Vector2(dir.x, dir.z))) > half_width + float(e.hit_radius): continue
			_hit[id] = true
			var d := Damage.new(damage, 0.0)
			d.knockback = dir * 0.4
			d.bonus = bonus
			e.take_damage(d)
			if e.is_alive() and e.has_method("stun"): e.stun(stun_s)
			hits += 1
	if _t > length / speed + SHARD_LIFE + FADE: queue_free()

func _process(_delta: float) -> void:
	var reach := tip()
	while _next <= reach and _next <= length:           # la raja y sus esquirlas, según avanza
		var side := randf_range(-0.25, 0.25)
		var crack := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.14, 0.03, SHARD_EVERY * 1.1)
		crack.mesh = cb
		crack.material_override = _crack_mat
		crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(crack)
		crack.position = dir * (_next + SHARD_EVERY * 0.5) + Vector3(0, 0.03, 0) + dir.cross(Vector3.UP) * side * 0.3
		crack.rotation.y = atan2(dir.x, dir.z) + randf_range(-0.3, 0.3)
		for k in 2:
			var shard := MeshInstance3D.new()
			var sb := BoxMesh.new()
			var h := randf_range(0.3, 0.6)
			sb.size = Vector3(randf_range(0.12, 0.2), h, randf_range(0.12, 0.2))
			shard.mesh = sb
			shard.material_override = _shard_mat
			add_child(shard)
			shard.position = dir * _next + dir.cross(Vector3.UP) * randf_range(-half_width, half_width) * 0.8
			shard.rotation = Vector3(randf_range(-0.4, 0.4), randf(), randf_range(-0.4, 0.4))
			_shards.append({"node": shard, "born": _t, "h": h})
		_next += SHARD_EVERY
	for s in _shards:                                   # suben rápido y se hunden despacio
		var age: float = _t - float(s.born)
		var up := clampf(age / 0.1, 0.0, 1.0) * (1.0 - smoothstep(0.25, SHARD_LIFE, age))
		(s.node as Node3D).position.y = -float(s.h) * 0.5 + up * float(s.h) * 0.8
	var fade := 1.0 - smoothstep(length / speed + SHARD_LIFE, length / speed + SHARD_LIFE + FADE, _t)
	_crack_mat.albedo_color.a = 0.85 * fade
	_shard_mat.albedo_color.a = fade
