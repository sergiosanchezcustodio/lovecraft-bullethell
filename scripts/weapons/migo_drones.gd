class_name MiGoDrones
extends Node3D
## Orbes Mi-Go: `count` esferas de cristal rosado con un núcleo que late, que vuelan despacio
## alrededor del personaje (a `orbit` m y 1,7 m de altura) durante `life` s. Cada una dispara
## por su cuenta al enemigo más cercano cada `interval` s (desfasadas entre sí). Como las
## páginas del Necronomicón, se reactivan al recargarse el arma.

var player: Player
var world: CombatWorld
var active := false
var shots := 0                               ## disparos hechos (tests)
var _orbs: Array[Node3D] = []
var _count := 1
var _orbit := 2.4
var _damage := 7.0
var _interval := 0.7
var _reach := 8.0
var _speed := 16.0
var _life := 7.0
var _left := 0.0
var _bonus_set := -1
var _timers: Array[float] = []
var _t := 0.0

const FADE := 0.3
const HEIGHT := 1.7
const SPIN := 0.9                            ## rad/s alrededor del personaje
const PINK := Color(0.95, 0.45, 0.7)

func setup(p_player: Player, p_world: CombatWorld) -> MiGoDrones:
	player = p_player
	world = p_world
	name = "MiGoDrones"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func start(count: int, orbit: float, damage: float, interval: float, reach: float, speed: float,
		life: float, bonus_set: int) -> void:
	_count = count; _orbit = orbit; _damage = damage; _interval = maxf(interval, 0.1); _reach = reach
	_speed = speed; _life = life; _left = life; _bonus_set = bonus_set
	active = true
	while _orbs.size() < _count: _orbs.append(_make_orb())
	_timers.resize(_count)
	for i in _count: _timers[i] = _interval * (0.3 + float(i) / _count)
	for i in _orbs.size(): _orbs[i].visible = i < _count

func _make_orb() -> Node3D:
	var orb := Node3D.new()
	orb.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var shell := MeshInstance3D.new()                # cáscara: cubo girado, de cristal
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.34
	shell.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(PINK.r * 0.6, PINK.g * 0.5, PINK.b * 0.6, 0.55)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.roughness = 0.2
	sm.metallic = 0.3
	shell.material_override = sm
	shell.rotation = Vector3(0.6, 0.0, 0.6)
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orb.add_child(shell)
	var core := MeshInstance3D.new()                 # núcleo que late
	var cm := BoxMesh.new()
	cm.size = Vector3.ONE * 0.16
	core.mesh = cm
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(PINK.r * 0.85, PINK.g * 0.85, PINK.b * 0.85)
	core.material_override = mm
	core.name = "Core"
	orb.add_child(core)
	var light := OmniLight3D.new()
	light.light_color = PINK
	light.light_energy = 0.6
	light.omni_range = 1.8
	orb.add_child(light)
	add_child(orb)
	return orb

func _orb_pos(i: int, center: Vector3) -> Vector3:
	var a := _t * SPIN + TAU * i / _count
	return center + Vector3(cos(a) * _orbit, HEIGHT + 0.15 * sin(_t * 2.3 + i), sin(a) * _orbit)

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(player): return
	_t += delta
	_left -= delta
	if _left <= 0.0:
		active = false
		return
	for i in _count:
		_timers[i] -= delta
		if _timers[i] > 0.0: continue
		var from := _orb_pos(i, player.global_position)
		var target := world.nearest_enemy(from, _reach)
		if target == null:
			_timers[i] = 0.2
			continue
		_timers[i] = _interval
		var dir := Vector3(target.global_position.x - from.x, 0, target.global_position.z - from.z).normalized()
		world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.WISP, from, dir * _speed, 0.22, 0.15,
			Damage.new(_damage, 0.0), _reach / _speed * 1.2, 0, 0.6, _bonus_set)
		shots += 1

func _process(delta: float) -> void:
	var on := active and is_instance_valid(player)
	visible = on or _left > -FADE
	if not visible: return
	if not active: _left -= delta
	var center := player.get_global_transform_interpolated().origin if is_instance_valid(player) else global_position
	var k := clampf(minf((_life - _left) / FADE, (_left + FADE) / FADE), 0.0, 1.0)
	for i in _count:
		var orb := _orbs[i]
		orb.global_position = _orb_pos(i, center)
		orb.scale = Vector3.ONE * maxf(k, 0.01)
		(orb.get_child(0) as Node3D).rotation.y = _t * 2.0 + i
		var core := orb.get_node("Core") as Node3D
		core.scale = Vector3.ONE * (0.8 + 0.35 * maxf(0.0, sin(_t * 5.0 + i * 1.7)))
