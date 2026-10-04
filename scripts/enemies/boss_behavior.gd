class_name BossBehavior
extends ChargeBehavior
## Shoggoth primigenio (hito 4.5), jefe de la parte 1, en tres fases según su vida:
##   1 (100-66 %): persecución y embestidas por el túnel (ChargeBehavior);
##   2 (66-33 %): se detiene, abre ojos y dispara ráfagas (`phase2_pattern`) y escupe
##      fragmentos (`minion`) cada `minion_every` s;
##   3 (< 33 %): furia: embiste más rápido, sin descanso, y dispara la espiral (`phase3_pattern`).
## Al cambiar de fase chilla "¡Tekeli-li!" y queda invulnerable `phase_shield` s.
var phase := 1
var _fire := 0.0
var _minion := 0.0

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.66 else (2 if k > 0.33 else 3)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var p := phase_for(e)
	if p != phase:
		phase = p
		_announce(e)
		if OS.get_cmdline_user_args().has("log=true"): print("JEFE fase %d" % phase)
		e.shield_t = float(e.data.param("phase_shield", 1.2))
		_enter(State.CRAWL)
	_fire -= delta
	_minion -= delta
	match phase:
		2:
			e.anim = "burst" if _fire > 0.6 else "idle"
			if _fire <= 0.0 and target != null:
				_fire = float(e.data.param("phase2_every", 1.6))
				_shoot(e, target, e.data.param("phase2_pattern", null))
			if _minion <= 0.0:
				_minion = float(e.data.param("minion_every", 4.0))
				_spawn_minions(e)
			if target == null: return Vector3.ZERO
			var to := target.global_position - e.global_position
			to.y = 0.0
			return toward(e, target) * e.data.move_speed * 0.35       # avanza despacio
		3:
			if _fire <= 0.0 and target != null:
				_fire = float(e.data.param("phase3_every", 2.2))
				_shoot(e, target, e.data.param("phase3_pattern", null))
			var v := super.update(e, target, delta)
			if state == State.REST: _enter(State.CRAWL)            # sin descanso
			return v * 1.25
	return super.update(e, target, delta)

func _shoot(e: Enemy, target: Player, pat: BulletPattern) -> void:
	if pat == null: return
	e.runner.busy = false
	e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)

func _spawn_minions(e: Enemy) -> void:
	var game := e.get_tree().current_scene
	var d: EnemyData = e.data.param("minion", null)
	if d == null or game == null or game.get("director") == null: return
	for i in int(e.data.param("minion_count", 3)):
		var a := randf() * TAU
		game.director.spawn(d, e.global_position + Vector3(cos(a), 0, sin(a)) * 2.5)

func _announce(e: Enemy) -> void:
	var l := Label3D.new()
	l.text = "¡TEKELI-LI!"
	l.font_size = 110
	l.outline_size = 18
	l.modulate = Color(0.75, 1.0, 0.55)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = e.global_position + Vector3(0, 4.0, 0)
	e.world.fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.5, 1.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.8).set_ease(Tween.EASE_IN)
	tw.tween_callback(l.queue_free)

func can_shoot(_e: Enemy) -> bool:
	return phase == 1 and state == State.CRAWL
