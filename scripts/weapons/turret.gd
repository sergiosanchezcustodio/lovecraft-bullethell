class_name Turret
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Ametralladora Lewis en trípode: se queda en el suelo donde la deja el personaje y durante
## `life` s dispara sola al enemigo más cercano cada `interval` s, girando hacia él. Voxel a
## bloques: tres patas, cajón del mecanismo, cañón con camisa de refrigeración y el cargador
## de tambor encima. Fogonazo con una luz breve en cada disparo.

var world: CombatWorld
var life := 8.0
var interval := 0.16
var damage := 6.0
var reach := 10.0
var speed := 26.0
var bonus_set := -1
var shots := 0                               ## disparos (tests)
var _t := 0.0
var _timer := 0.0
var _head: Node3D
var _flash: OmniLight3D
var _flash_t := 0.0
var _aim := 0.0

const FADE := 0.4
const METAL := Color(0.2, 0.21, 0.2)
const DARK := Color(0.12, 0.12, 0.12)
const WOOD := Color(0.42, 0.28, 0.16)

func setup(p_world: CombatWorld, pos: Vector3, p_life: float, p_interval: float, p_damage: float,
		p_reach: float, p_speed: float, p_bonus_set: int) -> Turret:
	world = p_world; life = p_life; interval = maxf(p_interval, 0.05); damage = p_damage; reach = p_reach
	speed = p_speed; bonus_set = p_bonus_set
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	for k in 3:                                      # trípode
		var a := TAU * k / 3.0
		var leg := _box(Vector3(0.05, 0.62, 0.05), WOOD, self)
		leg.position = Vector3(cos(a) * 0.2, 0.28, sin(a) * 0.2)
		leg.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)
	_head = Node3D.new()
	_head.position.y = 0.62
	add_child(_head)
	_box(Vector3(0.16, 0.16, 0.34), METAL, _head)                               # cajón
	var jacket := _box(Vector3(0.12, 0.12, 0.5), DARK, _head)                  # camisa del cañón
	jacket.position.z = 0.4
	var muzzle := _box(Vector3(0.06, 0.06, 0.12), METAL, _head)
	muzzle.position.z = 0.7
	var drum := _box(Vector3(0.3, 0.06, 0.3), DARK, _head)                     # cargador de tambor
	drum.position = Vector3(0, 0.12, 0.02)
	var stock := _box(Vector3(0.08, 0.12, 0.26), WOOD, _head)                  # culata
	stock.position = Vector3(0, -0.02, -0.28)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1.0, 0.75, 0.35)
	_flash.omni_range = 3.0
	_flash.light_energy = 0.0
	_flash.position = Vector3(0, 0, 0.8)
	_head.add_child(_flash)
	scale = Vector3.ONE * 0.01

func _box(size: Vector3, c: Color, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	m.metallic = 0.3 if c != WOOD else 0.0
	mi.material_override = m
	parent.add_child(mi)
	return mi

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= life:
		if _t >= life + FADE: queue_free()
		return
	_timer -= delta
	if _timer > 0.0: return
	var target := world.nearest_enemy(global_position, reach)
	if target == null:
		_timer = 0.15
		return
	_timer = interval
	var dir := Vector3(target.global_position.x - position.x, 0, target.global_position.z - position.z).normalized()
	_aim = atan2(dir.x, dir.z)
	dir = dir.rotated(Vector3.UP, deg_to_rad(randf_range(-3.0, 3.0)))          # algo de dispersión
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.PLAYER, global_position + dir * 0.8, dir * speed,
		0.18, 0.13, Damage.new(damage, 0.0), reach / speed * 1.15, 0, 0.6, bonus_set)
	shots += 1
	_flash_t = 0.05

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	var grow := clampf(_t / 0.2, 0.01, 1.0) * (1.0 - smoothstep(life, life + FADE, _t))
	scale = Vector3.ONE * maxf(grow, 0.01)
	_head.rotation.y = lerp_angle(_head.rotation.y, _aim, 1.0 - exp(-18.0 * delta))
	_flash_t -= delta
	_flash.light_energy = 2.2 if _flash_t > 0.0 else 0.0
	_head.position.z = -0.03 if _flash_t > 0.0 else 0.0                       # retroceso
