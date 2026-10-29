class_name OozeBehavior
extends EnemyBehavior
## Antiguo mutilado (hito 4.4): persigue despacio y cada `drop_every` s deja un charco del
## limo de los shoggoths (EnemyZone) que daña a quien lo pisa.
var _drop := 0.0

func start(e: Enemy) -> void:
	_drop = randf() * float(e.data.param("drop_every", 1.6))

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_slime(e, delta)
	return super.update(e, target, delta)

## En red, la marioneta del invitado deja sus propios charcos (dañan a los jugadores de su PC).
func puppet_step(e: Enemy, delta: float) -> void:
	_slime(e, delta)

func _slime(e: Enemy, delta: float) -> void:
	_drop -= delta
	if _drop <= 0.0:
		_drop = float(e.data.param("drop_every", 1.6))
		var z := EnemyZone.new().setup(e.world, e.global_position, float(e.data.param("slime_radius", 1.0)),
			float(e.data.param("slime_life", 6.0)), float(e.data.param("slime_dps", 4.0)), float(e.data.param("slime_mental", 2.0)))
		z.who = e.data.id
		e.world.fx.add_child(z)
