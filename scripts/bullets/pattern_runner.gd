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
var over_walls := false               ## sus balas pasan por encima del decorado (los grandes, 10-10-2026)
var damage_mult := 1.0                ## lo baja el Polvo de Ibn-Ghazi (enemigo debilitado)
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
	if damage_mult != 1.0: dmg = dmg.scaled(damage_mult)
	for dir in pattern.directions(aim, _burst):
		world.bullets.spawn(BulletManager.Team.ENEMY, pattern.style(), origin + dir * 0.5,
			dir * pattern.speed, pattern.radius, pattern.size, dmg, pattern.lifetime,
			0, 1.0, -1, 0, 0.0, BulletManager.Effect.NONE, 0.0, BulletManager.OVER_WALLS if over_walls else -1)
	_burst += 1
	_timer = pattern.burst_interval
	if _burst >= pattern.bursts:
		_firing = false
		busy = false
		done.emit()
