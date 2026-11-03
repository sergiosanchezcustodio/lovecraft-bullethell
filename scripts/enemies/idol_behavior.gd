class_name IdolBehavior
extends EnemyBehavior
## Ídolo vivo (hito 16.18): una estatuilla de Cthulhu del tamaño de un hombre que no se mueve
## (vuelve a su sitio si la empujan) y dispara su `attack` (una espiral) cuando hay alguien a tiro.
## Cada 0,5 s ampara a las criaturas a menos de `guard_radius` m: mientras dure (`Enemy.idol_t`)
## reciben un 40 % menos de daño (`Enemy.IDOL_GUARD`). El corro se ve en el suelo (Enemy._ready,
## también en los invitados). Una torreta: hay que ir a por ella o sacar a los demás del corro.
var _anchor := Vector3.INF
var _guard := 0.0

const GUARD_EVERY := 0.5

func start(e: Enemy) -> void:
	_anchor = e.position

func update(e: Enemy, _target: Player, delta: float) -> Vector3:
	if e.anim != "burst": e.anim = "idle"
	if _anchor == Vector3.INF: _anchor = e.position
	_guard -= delta
	if _guard <= 0.0:
		_guard = GUARD_EVERY
		guard(e)
	var back := _anchor - e.position
	back.y = 0.0
	return back * 8.0 if back.length() > 0.02 else Vector3.ZERO

## Ampara a los cercanos; devuelve cuántos.
func guard(e: Enemy) -> int:
	var r2 := pow(float(e.data.param("guard_radius", 5.0)), 2.0)
	var n := 0
	for o in e.world.enemies:
		var x := o as Enemy
		if x == null or x == e or not x.is_alive() or x.global_position.distance_squared_to(e.global_position) > r2: continue
		x.idol_t = GUARD_EVERY + 0.25
		n += 1
	return n

func touches(_e: Enemy) -> bool:
	return true
