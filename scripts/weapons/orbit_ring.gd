class_name OrbitRing
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Páginas del Necronomicón: proyectiles que giran alrededor del jugador mientras dura el
## arma (WeaponData.duration) y dañan a lo que tocan, con un intervalo por enemigo para no
## golpear al mismo en cada paso. Las páginas son bloques de pergamino con un brillo dorado
## que aletean al girar. Vive en world.fx (sigue la posición interpolada del jugador).

var player: Player
var world: CombatWorld
var active := false
var _pages: Array[Node3D] = []
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
var look := ""                             ## "" páginas; "ancla": el ancla del Alert con su cadena (hito 8.8)
var _chain: Array[MeshInstance3D] = []

const FADE := 0.25
const CHAIN_LINKS := 7

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

func _make_page() -> Node3D:
	if look == "ancla":
		var holder := Node3D.new()
		holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var m := VoxelBuilder.load_model("res://models/proj_ancla.json")
		m.position = Vector3(0, -0.3, 0)
		holder.add_child(m)
		add_child(holder)
		var bm := BoxMesh.new()                       # cadena: eslabones hasta el personaje
		bm.size = Vector3.ONE * 0.08
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.36, 0.38)
		mat.metallic = 0.6
		mat.roughness = 0.5
		bm.material = mat
		for i in CHAIN_LINKS:
			var link := MeshInstance3D.new()
			link.mesh = bm
			link.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			link.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			add_child(link)
			_chain.append(link)
		return holder
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
	Damage.ctx = _wtag
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
		world.bullets.clear_enemy_bullets(p, _hit_r)              # las páginas paran balas
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
	Damage.ctx = _wtag
	var on := active and is_instance_valid(player)
	visible = on or _left > -FADE
	if not visible: return
	_angle = fmod(_angle + _speed * delta, 360.0)
	var center := player.get_global_transform_interpolated().origin if is_instance_valid(player) else global_position
	var k := clampf(minf((_life - _left) / FADE, (_left + FADE) / FADE), 0.0, 1.0)   # aparecen y se apagan
	for i in _count:
		var a := deg_to_rad(_angle) + TAU * i / _count
		var pg := _pages[i]
		if look == "ancla":
			pg.global_position = center + Vector3(cos(a) * _radius, 0.7, sin(a) * _radius)
			pg.rotation = Vector3(0, -a, PI * 0.5)                                         # tumbada, la caña hacia el personaje
			pg.scale = Vector3.ONE * k * 1.4
			for j in _chain.size():
				var f := float(j + 1) / (_chain.size() + 1)
				_chain[j].global_position = center + Vector3(cos(a) * _radius * f, 0.9 - 0.2 * f, sin(a) * _radius * f)
				_chain[j].visible = k > 0.05
			continue
		pg.global_position = center + Vector3(cos(a) * _radius, 1.0 + 0.12 * sin(_t * 6.0 + i), sin(a) * _radius)
		pg.rotation = Vector3(0.35 * sin(_t * 9.0 + i * 2.0), -a, 0.2)                   # aletean al girar
		pg.scale = Vector3.ONE * k
	if not active: _left -= delta
