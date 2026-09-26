class_name OrbitRing
extends Node3D
## Páginas del Necronomicón: proyectiles que giran alrededor del jugador mientras dura el
## arma (WeaponData.duration) y dañan a lo que tocan, con un intervalo por enemigo para no
## golpear al mismo en cada paso. Las páginas son bloques de pergamino con un brillo dorado
## que aletean al girar. Vive en world.fx (sigue la posición interpolada del jugador).

var player: Player
var world: CombatWorld
var active := false
var _pages: Array[MeshInstance3D] = []
var _count := 3
var _radius := 1.8
var _speed := 160.0                        ## grados por segundo
var _hit_r := 0.35
var _damage := 8.0
var _left := 0.0
var _life := 0.0
var _interval := 0.45
var _push := 1.0
var _bonus := {}
var _angle := 0.0
var _last_hit := {}                        ## id del enemigo -> momento del último golpe
var _t := 0.0

const FADE := 0.25

func setup(p_player: Player, p_world: CombatWorld) -> OrbitRing:
	player = p_player
	world = p_world
	name = "OrbitRing"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # se mueve en _process
	return self

func start(count: int, radius: float, speed: float, hit_r: float, damage: float, life: float,
		interval: float, push: float, bonus: Dictionary) -> void:
	_count = count; _radius = radius; _speed = speed; _hit_r = hit_r; _damage = damage
	_life = life; _left = life; _interval = interval; _push = push; _bonus = bonus
	active = true
	while _pages.size() < _count: _pages.append(_make_page())
	for i in _pages.size(): _pages[i].visible = i < _count

func _make_page() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.26, 0.34, 0.04)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.78, 0.60)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.72, 0.35)
	mat.emission_energy_multiplier = 0.55
	mat.roughness = 0.8
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mi

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(player): return
	_left -= delta
	_t += delta
	if _left <= 0.0:
		active = false
		return
	var center := player.global_position
	for i in _count:
		var a := deg_to_rad(_angle) + TAU * i / _count
		var p := center + Vector3(cos(a), 0, sin(a)) * _radius
		for t in world.enemies_in_circle(p, _hit_r):
			var id := t.get_instance_id()
			if _t - float(_last_hit.get(id, -99.0)) < _interval: continue
			_last_hit[id] = _t
			var d := Damage.new(_damage, 0.0)
			var away := t.global_position - center
			d.knockback = Vector3(away.x, 0, away.z).normalized() * _push
			d.bonus = _bonus
			t.take_damage(d)

func _process(delta: float) -> void:
	var on := active and is_instance_valid(player)
	visible = on or _left > -FADE
	if not visible: return
	_angle = fmod(_angle + _speed * delta, 360.0)
	var center := player.get_global_transform_interpolated().origin if is_instance_valid(player) else global_position
	var k := clampf(minf((_life - _left) / FADE, (_left + FADE) / FADE), 0.0, 1.0)   # aparecen y se apagan
	for i in _count:
		var a := deg_to_rad(_angle) + TAU * i / _count
		var pg := _pages[i]
		pg.global_position = center + Vector3(cos(a) * _radius, 1.0 + 0.12 * sin(_t * 6.0 + i), sin(a) * _radius)
		pg.rotation = Vector3(0.35 * sin(_t * 9.0 + i * 2.0), -a, 0.2)                   # aletean al girar
		pg.scale = Vector3.ONE * k
	if not active: _left -= delta
