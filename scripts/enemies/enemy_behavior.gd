class_name EnemyBehavior
extends RefCounted
## Comportamiento de movimiento de un enemigo. Cada subclase decide la velocidad deseada,
## la animación y cuándo puede disparar su patrón. El Enemy se encarga del resto.

static func create(kind: StringName) -> EnemyBehavior:
	match kind:
		&"crawl": return CrawlBehavior.new()
		&"blind": return BlindBehavior.new()
		&"stalk": return StalkBehavior.new()
	return EnemyBehavior.new()

func start(_e: Enemy) -> void:
	pass

## Persecución directa (comportamiento por defecto, "chase").
func update(e: Enemy, target: Player, _delta: float) -> Vector3:
	e.anim = "walk"
	if target == null: return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	return to.normalized() * e.data.move_speed if to.length() > 0.3 else Vector3.ZERO

func contact_damage(e: Enemy) -> Damage:
	var d := Damage.new(e.data.contact_physical, e.data.contact_mental)
	d.source = e
	return d

func can_shoot(_e: Enemy) -> bool:
	return true

func play_attack_anim(e: Enemy, anim: String) -> void:
	e.anim = anim
	e.anim_t = 0.0
