class_name ThrownExplosive
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Objeto lanzado en arco (dinamita, granada de palo, Molotov, frasco de ácido, bengala).
## Al caer, según su configuración (`configure`):
## - con radio de explosión: arde la mecha (con un anillo en el suelo que muestra el radio)
##   y explota; con mecha 0, explota al impactar;
## - con zona: deja fuego o ácido en el suelo (DamageZone);
## - con bengala: se enciende y atrae a los enemigos cercanos (Flare).

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
var look := "dinamita"
var arc := 2.2
var zone := {}                                   ## {kind, radius, time, dps, vulnerable}
var lure := 0.0
var net := 0.0                                   ## red de pesca: s que inmoviliza a los de dentro
var bonus := {}
var _landed := false

func setup(p_world: CombatWorld, p_start: Vector3, p_end: Vector3, p_flight: float, p_fuse: float,
		p_radius: float, p_damage: float, p_tint: Color) -> void:
	world = p_world; start = p_start; end = p_end
	flight = maxf(p_flight, 0.05); fuse = p_fuse; radius = p_radius; damage = p_damage; tint = p_tint

## Opciones del lanzado: aspecto, altura del arco, zona al caer, bengala y rasgos de daño.
func configure(p_look: String, p_arc: float, p_zone: Dictionary, p_lure: float, p_bonus: Dictionary) -> ThrownExplosive:
	look = p_look; arc = p_arc; zone = p_zone; lure = p_lure; bonus = p_bonus
	return self

## Piezas del objeto según su aspecto: [tamaño, color, desplazamiento] por bloque.
const LOOKS := {
	"dinamita": [[Vector3(0.07, 0.07, 0.24), Color(0.78, 0.16, 0.11), Vector3.ZERO]],
	"granada": [[Vector3(0.13, 0.13, 0.13), Color(0.26, 0.30, 0.22), Vector3(0, 0, 0.1)],
		[Vector3(0.05, 0.05, 0.28), Color(0.52, 0.38, 0.22), Vector3(0, 0, -0.08)]],
	"molotov": [[Vector3(0.1, 0.1, 0.18), Color(0.22, 0.42, 0.24), Vector3.ZERO],
		[Vector3(0.05, 0.05, 0.08), Color(0.85, 0.82, 0.72), Vector3(0, 0, 0.13)]],
	"frasco": [[Vector3(0.11, 0.11, 0.14), Color(0.42, 0.75, 0.25), Vector3.ZERO],
		[Vector3(0.05, 0.05, 0.06), Color(0.55, 0.40, 0.25), Vector3(0, 0, 0.1)]],
	"bengala": [[Vector3(0.07, 0.07, 0.2), Color(0.85, 0.18, 0.12), Vector3.ZERO]],
	"baba": [[Vector3(0.12, 0.1, 0.12), Color(0.45, 0.78, 0.22), Vector3.ZERO],
		[Vector3(0.07, 0.07, 0.07), Color(0.62, 0.9, 0.35), Vector3(0.05, 0.05, -0.08)]],
	"red": [[Vector3(0.26, 0.1, 0.26), Color(0.62, 0.55, 0.38), Vector3.ZERO],
		[Vector3(0.06, 0.06, 0.06), Color(0.3, 0.3, 0.32), Vector3(0.12, 0, 0.12)],
		[Vector3(0.06, 0.06, 0.06), Color(0.3, 0.3, 0.32), Vector3(-0.12, 0, -0.12)]],
}

func _ready() -> void:
	Damage.ctx = _wtag
	position = start
	_stick = MeshInstance3D.new()                    # contenedor de las piezas (gira en vuelo)
	add_child(_stick)
	for piece: Array in LOOKS.get(look, LOOKS["dinamita"]):
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = piece[0]
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = piece[1]
		mat.roughness = 0.8
		mi.material_override = mat
		mi.position = piece[2]
		_stick.add_child(mi)
	_spark = OmniLight3D.new()                       # chispa de la mecha
	_spark.light_color = tint if look == "baba" else Color(1.0, 0.7, 0.3)
	_spark.light_energy = 1.2
	_spark.omni_range = 1.6
	_spark.position = Vector3(0, 0.1, 0.12)
	add_child(_spark)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t < flight:
		var u := _t / flight
		position = start.lerp(end, u) + Vector3(0, sin(u * PI) * arc * (1.0 - u * 0.3), 0)
		position.y = maxf(position.y, 0.05)
		_stick.rotation = Vector3(_t * 11.0, _t * 7.0, 0)
	elif not _landed:
		_landed = true
		position = end + Vector3(0, 0.05, 0)
		if not zone.is_empty() or lure > 0.0 or net > 0.0 or fuse <= 0.0:
			_land()
			return
		_stick.rotation = Vector3(0, randf() * TAU, PI * 0.5)
		_ring = Telegraph.new()
		_ring.setup(radius, fuse, Color(tint, 0.55), false)
		_ring.position = end
		world.fx.add_child(_ring)
	else:
		_spark.light_energy = 0.8 + randf() * 1.2           # chisporroteo
		if _t >= flight + fuse:
			_explode()

## Efecto al caer que no espera a la mecha: zona, bengala o explosión al impacto.
func _land() -> void:
	if net > 0.0:                                # red: inmoviliza y hace poco daño, sin explosión
		for e in world.enemies_in_circle(end, radius):
			var d := Damage.new(damage, 0.0)
			d.bonus = bonus
			e.take_damage(d)
			if e.is_alive() and e.has_method("root"): e.root(net)
		world.fx.add_child(NetFx.new().setup(end, radius, net))
		queue_free()
		return
	if not zone.is_empty():
		world.fx.add_child(DamageZone.new().setup(world, int(zone.kind), end, float(zone.radius), float(zone.time),
			float(zone.dps), float(zone.get("vulnerable", 0.0)), bonus))
	if lure > 0.0:
		world.fx.add_child(Flare.new().setup(world, end, lure, 7.0))
	if radius > 0.0 and fuse <= 0.0:
		_explode()
		return
	queue_free()

func _explode() -> void:
	world.bullets.clear_enemy_bullets(end, radius * 0.7)       # protege algo: deshace balas enemigas
	for e in world.enemies_in_circle(end, radius):
		var d := end.distance_to(Vector3(e.global_position.x, 0, e.global_position.z))
		var k := lerpf(1.0, 0.5, clampf(d / radius, 0.0, 1.0))
		var dmg := Damage.new(damage * k, 0.0)
		dmg.knockback = (e.global_position - end).normalized() * 1.5
		dmg.bonus = bonus
		e.take_damage(dmg)
	var fx := Explosion.new()
	fx.radius = radius
	fx.position = end
	world.fx.add_child(fx)
	if is_instance_valid(_ring): _ring.queue_free()
	queue_free()
