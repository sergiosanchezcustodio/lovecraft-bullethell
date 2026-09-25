class_name CrawlBehavior
extends EnemyBehavior
## Fragmento protoplásmico: persigue a tirones, al ritmo de su animación de reptar.
var _burst_t := -1.0

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	if _burst_t >= 0.0:
		_burst_t += delta
		if _burst_t < Anims.duration(e.data.model, "burst"):
			return Vector3.ZERO                        # quieta mientras escupe
		_burst_t = -1.0
		e.anim = "walk"
	e.anim = "walk"
	if target == null: return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	var pulse := 0.2 + 1.3 * maxf(0.0, sin(e.anim_t * TAU))    # empuja en la fase de estirarse
	return to.normalized() * e.data.move_speed * pulse

func play_attack_anim(e: Enemy, anim: String) -> void:
	super.play_attack_anim(e, anim)
	_burst_t = 0.0

func can_shoot(_e: Enemy) -> bool:
	return _burst_t < 0.0
