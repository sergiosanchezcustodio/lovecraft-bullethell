class_name MimicBehavior
extends EnemyBehavior
## Shoggoth mimético (hito 4.3): anda despacio con la forma de un Antiguo (`EnemyData.model`)
## y no ataca; cuando un jugador se acerca a `reveal_range` m (o le hacen daño), chilla
## "¡Tekeli-li!", se transforma en `true_model` (a `true_scale`) y persigue a `speed_mult`
## veces su velocidad, disparando su patrón.
var revealed := false
var _hp0 := -1.0

func update(e: Enemy, target: Player, _delta: float) -> Vector3:
	if _hp0 < 0.0: _hp0 = e.health
	if not revealed:
		e.anim = "walk"
		if target == null: return Vector3.ZERO
		var to := target.global_position - e.global_position
		to.y = 0.0
		if to.length() < float(e.data.param("reveal_range", 5.0)) or e.health < _hp0: _reveal(e)
		else: return to.normalized() * e.data.move_speed * 0.6
	e.anim = "crawl"
	if target == null: return Vector3.ZERO
	var t := target.global_position - e.global_position
	t.y = 0.0
	return t.normalized() * e.data.move_speed * float(e.data.param("speed_mult", 1.6))

func _reveal(e: Enemy) -> void:
	revealed = true
	e.swap_model(String(e.data.param("true_model", "shoggoth_grande")), float(e.data.param("true_scale", 2.0)))
	var pat: BulletPattern = e.data.param("reveal_pattern", null)
	if pat != null:
		e.runner.busy = false
		e.runner.fire(pat, func() -> Vector3: return e.global_position + e.facing)
	var l := Label3D.new()                                   # el chillido, que sube y se apaga
	l.text = "¡Tekeli-li!"
	l.font_size = 72
	l.outline_size = 14
	l.modulate = Color(0.75, 1.0, 0.6)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = e.global_position + Vector3(0, 2.4, 0)
	e.world.fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.2, 1.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(l.queue_free)

func touches(_e: Enemy) -> bool:
	return revealed

func can_shoot(_e: Enemy) -> bool:
	return revealed
