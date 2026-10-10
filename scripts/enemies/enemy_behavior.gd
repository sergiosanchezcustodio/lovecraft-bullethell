class_name EnemyBehavior
extends RefCounted
## Comportamiento de movimiento de un enemigo. Cada subclase decide la velocidad deseada,
## la animación y cuándo puede disparar su patrón. El Enemy se encarga del resto.

## Por convención: EnemyData.movement = "blind" usa scripts/enemies/blind_behavior.gd. Un
## comportamiento nuevo es un script nuevo con ese nombre; "chase" (o uno que no exista)
## usa esta clase, que persigue al jugador.
const DIR := "res://scripts/enemies/%s_behavior.gd"

static func create(kind: StringName) -> EnemyBehavior:
	var path := DIR % kind
	if kind != &"chase" and ResourceLoader.exists(path): return (load(path) as GDScript).new()
	if kind != &"chase": push_warning("Comportamiento '%s' sin script: persigue" % kind)
	return EnemyBehavior.new()

func start(_e: Enemy) -> void:
	pass

## Persecución directa (comportamiento por defecto, "chase").
func update(e: Enemy, target: Player, _delta: float) -> Vector3:
	e.anim = "walk"
	if target == null: return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	return shape_path(e, toward(e, target), e.data.move_speed) if to.length() > 0.3 else Vector3.ZERO

## Da forma a la trayectoria según EnemyData.path. `dir` es la dirección hacia el jugador
## (unitaria); devuelve la velocidad. Cada enemigo tiene su fase (no van todos a la par).
static func shape_path(e: Enemy, dir: Vector3, speed: float) -> Vector3:
	if dir == Vector3.ZERO: return Vector3.ZERO
	var t := e._spawn_t + e.get_instance_id() % 97 * 0.13
	var side := Vector3(-dir.z, 0, dir.x)
	match e.data.path:
		&"zigzag":
			return (dir + side * sign(sin(t * 3.2)) * 0.9).normalized() * speed * 1.15
		&"hop":
			var ph := fmod(t * 1.4, 1.0)                     # salto rápido y pausa
			var k := 2.2 if ph < 0.45 else 0.1
			if ph < 0.45: e.position.y = sin(ph / 0.45 * PI) * 0.35
			else: e.position.y = 0.0
			return dir * speed * k
		&"flutter":
			e.position.y = 0.25 + sin(t * 9.0) * 0.18
			return (dir + side * sin(t * 2.3) * 1.2).normalized() * speed
		&"circle":
			return (dir * 0.75 + side * 0.65 * (1.0 if e.get_instance_id() % 2 == 0 else -1.0)).normalized() * speed
	return dir * speed

## Hacia dónde ir para llegar al jugador (04-10-2026): en línea recta si hay un pasillo libre
## del ancho del cuerpo; si no, por el mapa de flujo, que rodea el decorado. La comprobación
## del pasillo (lo caro) se hace cada 0,3 s por enemigo; entre medias se reutiliza la decisión.
## Atascos (10-10-2026): si en STUCK_EVERY s apenas se ha movido estando lejos, va por el
## flujo DETOUR s pase lo que pase, y el primer tramo con un empujón de lado para soltarse.
const STUCK_EVERY := 0.8
const STUCK_MIN := 0.3
const DETOUR := 2.5
static func toward(e: Enemy, target: Node3D) -> Vector3:
	var to := target.global_position - e.global_position
	to.y = 0.0
	var f: FlowField = e.world.flow if e.world != null else null
	if f == null or to.length() < 2.0: return to.normalized()
	var dt := e.get_physics_process_delta_time()
	var a := Vector2(e.global_position.x, e.global_position.z)
	e._stuck_t += dt
	if e._stuck_t >= STUCK_EVERY:
		e._stuck_t = 0.0
		if e._stuck_ref != Vector2.INF and a.distance_to(e._stuck_ref) < STUCK_MIN and to.length() > 2.5:
			e._detour_t = DETOUR
		e._stuck_ref = a
	e._path_t -= dt
	if e._path_t <= 0.0:
		e._path_t = 0.3 + randf() * 0.1
		e._path_clear = f.clear_line(a, Vector2(target.global_position.x, target.global_position.z), e.data.body_radius)
	var d := Vector2.ZERO
	if e._path_clear and e._detour_t <= 0.0:
		return to.normalized()
	d = f.direction(a)
	var dir := Vector3(d.x, 0, d.y) if d != Vector2.ZERO else to.normalized()
	if e._detour_t > 0.0:
		e._detour_t -= dt
		if e._detour_t > DETOUR - 0.6:                     # soltarse de la esquina: de lado
			var side := Vector3(-dir.z, 0, dir.x) * (1.0 if e.get_instance_id() % 2 == 0 else -1.0)
			dir = (dir + side * 0.8).normalized()
	return dir

func contact_damage(e: Enemy) -> Damage:
	var d := Damage.new(e.data.contact_physical, e.data.contact_mental)
	d.source = e
	return d

## ¿Puede dañar por contacto ahora? (los voladores, solo cuando están abajo)
func touches(_e: Enemy) -> bool:
	return true

func can_shoot(_e: Enemy) -> bool:
	return true

func play_attack_anim(e: Enemy, anim: String) -> void:
	e.anim = anim
	e.anim_t = 0.0
