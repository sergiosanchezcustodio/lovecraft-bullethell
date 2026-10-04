class_name Sigil
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Signo Arcano: un círculo violeta trazado en el suelo donde estaba el personaje. Mientras
## dura, cada `interval` s daña a los enemigos de dentro y los empuja hacia fuera, y las balas
## enemigas que entran pasan a ir a `bullet_slow` de su velocidad (una de las dos únicas armas
## que tocan balas, D-29). Visual: disco tenue, anillo y cinco runas de voxel que giran.

var world: CombatWorld
var radius := 2.6
var life := 4.5
var damage := 4.0
var interval := 0.4
var push := 1.2
var bullet_slow := 0.5
var bonus := {}
var slowed := 0                              ## balas frenadas (tests)
var _t := 0.0
var _tick := 0.0
var _mat_fill: ShaderMaterial
var _mat_ring: ShaderMaterial
var _runes: Array[MeshInstance3D] = []
var _light: OmniLight3D

const FADE := 0.4
const COLOR := Color(0.62, 0.32, 1.0)

func setup(p_world: CombatWorld, pos: Vector3, p_radius: float, p_life: float, p_damage: float,
		p_interval: float, p_push: float, p_bullet_slow: float, p_bonus: Dictionary) -> Sigil:
	world = p_world; radius = p_radius; life = p_life; damage = p_damage; interval = maxf(p_interval, 0.1)
	push = p_push; bullet_slow = p_bullet_slow; bonus = p_bonus
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	_mat_fill = _disc(true, 0.05)
	_mat_ring = _disc(false, 0.07)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(COLOR.r * 0.8, COLOR.g * 0.8, COLOR.b * 0.8)
	for i in 5:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.16, 0.05, 0.3)
		mi.mesh = bm
		mi.material_override = rm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_runes.append(mi)
	_light = OmniLight3D.new()
	_light.light_color = COLOR
	_light.omni_range = radius * 1.8
	_light.position.y = 0.5
	add_child(_light)
	_process(0.0)

func _disc(fill: bool, y: float) -> ShaderMaterial:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/telegraph.gdshader")
	m.set_shader_parameter("fill", fill)
	m.set_shader_parameter("soft", fill)
	m.set_shader_parameter("ring_width", 0.06)
	mi.material_override = m
	mi.scale = Vector3.ONE * radius
	mi.position.y = y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return m

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= life:
		if _t >= life + FADE: queue_free()
		return
	slowed += world.bullets.slow_enemy_bullets(global_position, radius, bullet_slow)
	_tick -= delta
	if _tick > 0.0: return
	_tick = interval
	for e in world.enemies_in_circle(global_position, radius):
		var d := Damage.new(damage, 0.0)
		var away := e.global_position - global_position
		d.knockback = Vector3(away.x, 0, away.z).normalized() * push
		d.bonus = bonus
		e.take_damage(d)

func _process(_delta: float) -> void:
	Damage.ctx = _wtag
	var k := clampf(_t / 0.25, 0.0, 1.0) * (1.0 - smoothstep(life, life + FADE, _t))
	_mat_fill.set_shader_parameter("color", Color(COLOR * 0.5, 0.22 * k))
	_mat_ring.set_shader_parameter("color", Color(COLOR, 0.9 * k))
	for i in _runes.size():
		var a := _t * 0.8 + TAU * i / _runes.size()
		var r := _runes[i]
		r.position = Vector3(cos(a) * radius * 0.72, 0.08, sin(a) * radius * 0.72)
		r.rotation.y = -a
		r.scale = Vector3.ONE * maxf(k, 0.01)
	_light.light_energy = 0.9 * k
