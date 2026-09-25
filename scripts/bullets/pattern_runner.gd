class_name PatternRunner
extends Node3D
## Ejecuta un BulletPattern desde la posición de su nodo padre: aviso en el suelo si
## el patrón lo pide y, después, sus ráfagas espaciadas en el tiempo.

signal started_firing
signal done

var world: CombatWorld
var pattern: BulletPattern
var aim_provider: Callable            ## () -> Vector3 posición a la que apuntar
var busy := false
var _burst := 0
var _timer := 0.0
var _firing := false

func setup(p_world: CombatWorld) -> PatternRunner:
	world = p_world
	name = "PatternRunner"
	return self

func fire(p: BulletPattern, p_aim: Callable) -> void:
	if busy: return
	pattern = p
	aim_provider = p_aim
	busy = true
	_burst = 0
	_timer = 0.0
	if p.telegraph_time > 0.0:
		var t := Telegraph.new().setup(p.telegraph_radius, p.telegraph_time,
			Color(Damage.color_for(p.damage().kind()), 0.75))
		t.position = Vector3(global_position.x, 0, global_position.z)
		t.finished.connect(_begin)
		world.fx.add_child(t)
	else:
		_begin()

func _begin() -> void:
	_firing = true
	started_firing.emit()

func _physics_process(delta: float) -> void:
	if not _firing: return
	_timer -= delta
	if _timer > 0.0: return
	var origin := global_position
	var target: Vector3 = aim_provider.call() if aim_provider.is_valid() else origin + Vector3.FORWARD
	var aim := Vector3(target.x - origin.x, 0, target.z - origin.z)
	var dmg := pattern.damage()
	for dir in pattern.directions(aim, _burst):
		world.bullets.spawn(BulletManager.Team.ENEMY, pattern.style(), origin + dir * 0.5,
			dir * pattern.speed, pattern.radius, pattern.size, dmg, pattern.lifetime)
	_burst += 1
	_timer = pattern.burst_interval
	if _burst >= pattern.bursts:
		_firing = false
		busy = false
		done.emit()
