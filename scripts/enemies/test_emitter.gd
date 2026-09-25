class_name TestEmitter
extends Node3D
## Emisor de prueba: una criatura quieta que dispara un patrón al jugador cada cierto
## tiempo. Sirve para comprobar el lenguaje visual de los daños y los impactos hasta que
## los enemigos reales (hito 1.5) tengan sus propios ataques.

var world: CombatWorld
var kind := "fragmento"
var pattern: BulletPattern
var interval := 3.0
var model: Node3D
var runner: PatternRunner
var _timer := 1.0
var _t := 0.0

func setup(p_world: CombatWorld, p_kind: String, p_pattern: BulletPattern, p_interval: float) -> TestEmitter:
	world = p_world; kind = p_kind; pattern = p_pattern; interval = p_interval
	return self

func _ready() -> void:
	model = VoxelBuilder.load_model("res://models/%s.json" % kind)
	add_child(model)
	runner = PatternRunner.new().setup(world)
	runner.position.y = 0.6
	add_child(runner)

func _target() -> Vector3:
	return world.players[0].global_position if not world.players.is_empty() else global_position + Vector3.FORWARD

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0 and not runner.busy:
		runner.fire(pattern, _target)
		_timer = interval

func _process(delta: float) -> void:
	_t += delta
	var to := _target() - global_position
	rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 1.0 - exp(-4.0 * delta))
	Anims.pose(kind, "idle", model, fposmod(_t / Anims.duration(kind, "idle"), 1.0))
