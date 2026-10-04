class_name BreakableSpawner
extends Node
## Reparte objetos rompibles por la arena (04-10-2026): COUNT al empezar y uno nuevo cada
## RESPAWN s hasta volver a COUNT, en sitios libres del mapa de obstáculos, dentro de la arena
## y a más de MIN_DIST m de los jugadores.

const COUNT := 8
const RESPAWN := 20.0
const MIN_DIST := 5.0

var world: CombatWorld
var size := Vector2(64, 64)
var _t := 0.0

func setup(p_world: CombatWorld, arena_size: Vector2) -> BreakableSpawner:
	world = p_world
	size = arena_size
	name = "Breakables"
	return self

func _ready() -> void:
	for i in COUNT: _spawn()

func _physics_process(delta: float) -> void:
	_t += delta
	if _t < RESPAWN: return
	_t = 0.0
	if world.breakables.size() < COUNT: _spawn()

func _spawn() -> void:
	var half := size * 0.5 - Vector2(3, 3)
	for tries in 40:
		var p := Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))
		if world.obstacles != null and world.obstacles.is_blocked(p, 0.7): continue
		var far := true
		for q in world.players:
			if Vector2(q.global_position.x, q.global_position.z).distance_to(p) < MIN_DIST: far = false
		if not far: continue
		world.fx.add_child(Breakable.new().setup(world, Vector3(p.x, 0, p.y)))
		return
