class_name KeepBehavior
extends EnemyBehavior
## A distancia (hito 6.1: acólitos y diácono de la Orden de Dagon): se acerca hasta `keep` m
## del jugador, retrocede si se le echa encima y, entre medias, rodea despacio de lado.
## Dispara su `attack` como siempre (Enemy). Parámetros opcionales:
##   keep (6.0), strafe (0.45: parte de la velocidad al rodear)
##   extra_pattern + extra_every: un segundo patrón propio cada tantos s (espiral del diácono)
##   minion + minion_every + minion_count: llama a otros a su alrededor (con aviso "¡Ïa!")
var _extra := 2.0
var _minion := 3.0
var _side := 1.0

func start(e: Enemy) -> void:
	_side = 1.0 if e.get_instance_id() % 2 == 0 else -1.0

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	e.anim = "walk"
	if target == null: return Vector3.ZERO
	_extra -= delta
	_minion -= delta
	var pat: BulletPattern = e.data.param("extra_pattern", null)
	if pat != null and _extra <= 0.0 and not e.runner.busy:
		_extra = float(e.data.param("extra_every", 6.0))
		e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)
		super.play_attack_anim(e, "throw")
	if e.data.param("minion", null) != null and _minion <= 0.0:
		_minion = float(e.data.param("minion_every", 8.0))
		_summon(e)
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	var keep := float(e.data.param("keep", 6.0))
	var dir := toward(e, target)
	var side := Vector3(-dir.z, 0, dir.x) * _side
	var speed := e.data.move_speed
	if d > keep + 1.0: return shape_path(e, dir, speed)
	if d < keep - 1.5: return (-dir * 0.9 + side * 0.3).normalized() * speed * 0.8
	if randf() < delta * 0.15: _side = -_side                  # cambia de lado de vez en cuando
	return side * speed * float(e.data.param("strafe", 0.45))

func _summon(e: Enemy) -> void:
	var game := e.get_tree().current_scene
	var d: EnemyData = e.data.param("minion", null)
	if d == null or game == null or game.get("director") == null: return
	for i in int(e.data.param("minion_count", 3)):
		var a := randf() * TAU
		game.director.spawn(d, e.global_position + Vector3(cos(a), 0, sin(a)) * 2.5)
	var l := Label3D.new()
	l.text = String(e.data.param("minion_text", "¡Ïa! ¡Dagon!"))
	l.font_size = 90
	l.outline_size = 16
	l.modulate = Color(0.55, 0.95, 0.75)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = e.global_position + Vector3(0, 3.2, 0)
	e.world.fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.2, 1.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(l.queue_free)
