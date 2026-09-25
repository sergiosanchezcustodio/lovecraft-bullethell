class_name ThrownExplosive
extends Node3D
## Cartucho de dinamita: vuela en arco hasta el punto elegido, cae, arde la mecha
## (con un anillo en el suelo que muestra el radio) y explota dañando a todo lo que
## haya dentro, más en el centro que en el borde.

var world: CombatWorld
var start := Vector3.ZERO
var end := Vector3.ZERO
var flight := 0.7
var fuse := 0.4
var radius := 2.2
var damage := 30.0
var tint := Color(1.0, 0.82, 0.3)
var _t := 0.0
var _stick: MeshInstance3D
var _spark: OmniLight3D
var _ring: Telegraph

func setup(p_world: CombatWorld, p_start: Vector3, p_end: Vector3, p_flight: float, p_fuse: float,
		p_radius: float, p_damage: float, p_tint: Color) -> void:
	world = p_world; start = p_start; end = p_end
	flight = maxf(p_flight, 0.05); fuse = p_fuse; radius = p_radius; damage = p_damage; tint = p_tint

func _ready() -> void:
	position = start
	_stick = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.07, 0.07, 0.24)
	_stick.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.16, 0.11)
	mat.roughness = 0.8
	_stick.material_override = mat
	add_child(_stick)
	_spark = OmniLight3D.new()                       # chispa de la mecha
	_spark.light_color = Color(1.0, 0.7, 0.3)
	_spark.light_energy = 1.2
	_spark.omni_range = 1.6
	_spark.position = Vector3(0, 0.1, 0.12)
	add_child(_spark)

func _physics_process(delta: float) -> void:
	_t += delta
	if _t < flight:
		var u := _t / flight
		position = start.lerp(end, u) + Vector3(0, sin(u * PI) * 2.2 * (1.0 - u * 0.3), 0)
		position.y = maxf(position.y, 0.05)
		_stick.rotation = Vector3(_t * 11.0, _t * 7.0, 0)
	elif _ring == null:
		position = end + Vector3(0, 0.05, 0)
		_stick.rotation = Vector3(0, randf() * TAU, PI * 0.5)
		_ring = Telegraph.new()
		_ring.setup(radius, fuse, Color(tint, 0.55), false)
		_ring.position = end
		world.fx.add_child(_ring)
	else:
		_spark.light_energy = 0.8 + randf() * 1.2           # chisporroteo
		if _t >= flight + fuse:
			_explode()

func _explode() -> void:
	for e in world.enemies_in_circle(end, radius):
		var d := end.distance_to(Vector3(e.global_position.x, 0, e.global_position.z))
		var k := lerpf(1.0, 0.5, clampf(d / radius, 0.0, 1.0))
		var dmg := Damage.new(damage * k, 0.0)
		dmg.knockback = (e.global_position - end).normalized() * 1.5
		e.take_damage(dmg)
	var fx := Explosion.new()
	fx.radius = radius
	fx.position = end
	world.fx.add_child(fx)
	if is_instance_valid(_ring): _ring.queue_free()
	queue_free()
