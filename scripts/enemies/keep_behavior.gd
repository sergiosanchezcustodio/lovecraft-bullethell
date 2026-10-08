class_name KeepBehavior
extends EnemyBehavior
## A distancia (hito 6.1: acólitos y diácono de la Orden de Dagon): se acerca hasta `keep` m
## del jugador, retrocede si se le echa encima y, entre medias, rodea despacio de lado.
## Dispara su `attack` como siempre (Enemy). Parámetros opcionales:
##   keep (6.0), strafe (0.45: parte de la velocidad al rodear)
##   extra_pattern + extra_every: un segundo patrón propio cada tantos s (espiral del diácono)
##   minion + minion_every + minion_count: llama a otros a su alrededor (con aviso "¡Ïa!")
##   shield_at + shield_minion + shield_count (hito 6.2, sumo sacerdote): al bajar de esa parte
##     de su vida (una vez), llama a un círculo de protectores cerca y es invulnerable mientras
##     viva alguno, con un aro dorado alrededor
##   dive_at + dive_time + dive_pattern (hito 6.4, Barnabas Marsh): al bajar de cada parte de
##     su vida (lista), se zambulle: desaparece invulnerable dive_time s y sale en otra poza
##     (a 6-10 m de su objetivo; sin agua, en cualquier sitio libre) con un estallido de agua
##     y dive_pattern; avisa con un aro en el suelo antes de salir
##   slam_every + slam_radius + slam_damage + slam_warn + slam_count (hito 6.5, Madre Hydra):
##     golpe de zarpa: marca con un aviso grande donde está el jugador (y slam_count - 1
##     sitios más a su alrededor) y al cumplirse daña a los que sigan dentro, con un
##     estallido de agua
var _extra := 2.0
var _minion := 3.0
var _side := 1.0
var _shield_done := false
var _guards: Array[int] = []                ## instance_id de los protectores vivos
var _ring: MeshInstance3D
var _dives := 0                             ## zambullidas hechas
var _dive_t := 0.0                          ## > 0: bajo el agua
var _rise: Vector3                          ## por dónde saldrá
var _rng := RandomNumberGenerator.new()
var _slam := 3.0

func start(e: Enemy) -> void:
	_side = 1.0 if e.get_instance_id() % 2 == 0 else -1.0

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	e.anim = "walk"
	_shield(e)
	if _dive(e, target, delta): return Vector3.ZERO
	if target == null: return Vector3.ZERO
	_extra -= delta
	_minion -= delta
	var pat: BulletPattern = e.data.param("extra_pattern", null)
	if pat != null and _extra <= 0.0 and not e.runner.busy:
		_extra = float(e.data.param("extra_every", 6.0))
		e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)
		super.play_attack_anim(e, "throw")
	_slam -= delta
	if float(e.data.param("slam_every", 0.0)) > 0.0 and _slam <= 0.0:
		_slam = float(e.data.param("slam_every", 5.0))
		_slam_at(e, target)
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
		if d.emerge and game.director._emerge(d): continue      # los que salen del agua, de las pozas
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

func _shield(e: Enemy) -> void:
	var at := float(e.data.param("shield_at", 0.0))
	if at <= 0.0: return
	if not _shield_done and e.health <= e.data.max_health * e.health_scale * at:
		_shield_done = true
		if OS.get_cmdline_user_args().has("log=true"): print("ESCUDO t=%.1f" % e._spawn_t)
		var game := e.get_tree().current_scene
		var d: EnemyData = e.data.param("shield_minion", null)
		if d != null and game != null and game.get("director") != null:
			var n := int(e.data.param("shield_count", 4))
			for i in n:
				var a := TAU * i / n
				var g: Enemy = game.director.spawn(d, e.global_position + Vector3(cos(a), 0, sin(a)) * 3.0)
				if g != null: _guards.append(g.get_instance_id())
		_ring = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.1; tm.outer_radius = 1.3
		_ring.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.85, 0.70, 0.30) * 0.8
		_ring.material_override = m
		_ring.position.y = 1.2
		e.add_child(_ring)
	if _guards.is_empty(): return
	_guards.assign(_guards.filter(func(id: int) -> bool:
		var o := instance_from_id(id)
		return o != null and is_instance_valid(o) and (o as Enemy).is_alive()))
	if _guards.is_empty():
		if _ring != null and OS.get_cmdline_user_args().has("log=true"): print("ESCUDO roto")
		if _ring != null:
			_ring.queue_free()
			_ring = null
		return
	e.shield_t = 0.25                                           # invulnerable mientras viva alguno
	if _ring != null: _ring.rotation.y += 0.05

func touches(_e: Enemy) -> bool:
	return _dive_t <= 0.0

func can_shoot(_e: Enemy) -> bool:
	return _dive_t <= 0.0

## Zambullida: true mientras está bajo el agua (ni se mueve, ni toca, ni dispara).
func _dive(e: Enemy, target: Player, delta: float) -> bool:
	var at: Array = e.data.param("dive_at", [])
	if _dive_t <= 0.0:
		if _dives >= at.size() or e.health > e.data.max_health * e.health_scale * float(at[_dives]): return false
		_dives += 1
		_dive_t = float(e.data.param("dive_time", 2.5))
		WadeSplash.burst(e.world.fx, e.global_position, 1.6)
		e.visual.visible = false
		var c := target.global_position if target != null else e.global_position
		var w := Vector2.INF
		if e.obstacles != null:
			w = e.obstacles.random_water(_rng, Vector2(c.x, c.z), 6.0, 10.0, e.data.body_radius)
			if w == Vector2.INF:                   # sin agua: cualquier sitio libre
				for i in 30:
					var a := _rng.randf() * TAU
					var p := Vector2(c.x, c.z) + Vector2(cos(a), sin(a)) * _rng.randf_range(6.0, 10.0)
					if not e.obstacles.is_blocked(p, e.data.body_radius):
						w = p
						break
		_rise = Vector3(w.x, 0, w.y) if w != Vector2.INF else e.global_position
		var warn := minf(1.0, _dive_t * 0.5)
		var tg := Telegraph.new().setup(e.data.body_radius * e.model_scale + 0.8, warn, Color(0.35, 0.75, 0.85, 0.7), false)
		tg.position = _rise
		var eid := e.get_instance_id()
		e.get_tree().create_timer(_dive_t - warn, false).timeout.connect(func() -> void:
			var e2 := instance_from_id(eid) as Enemy
			if e2 != null and e2.is_alive(): e2.world.fx.add_child(tg)
			else: tg.free())
		if OS.get_cmdline_user_args().has("log=true"): print("ZAMBULLIDA %d t=%.1f" % [_dives, e._spawn_t])
	_dive_t -= delta
	e.shield_t = 0.25
	if _dive_t > 0.0: return true
	e.position = _rise
	e.reset_physics_interpolation()
	e.visual.visible = true
	WadeSplash.burst(e.world.fx, _rise, 1.6)
	var pat: BulletPattern = e.data.param("dive_pattern", null)
	if pat != null and target != null:
		e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)
		super.play_attack_anim(e, "throw")
	return false

## Golpe de zarpa con aviso grande en el suelo (Madre Hydra).
func _slam_at(e: Enemy, target: Player) -> void:
	var r := float(e.data.param("slam_radius", 2.5))
	var warn := float(e.data.param("slam_warn", 1.1))
	var spots: Array[Vector3] = [Vector3(target.global_position.x, 0, target.global_position.z)]
	for i in int(e.data.param("slam_count", 1)) - 1:
		var a := _rng.randf() * TAU
		spots.append(spots[0] + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(r * 1.6, r * 2.6))
	super.play_attack_anim(e, "pounce")
	for at in spots:
		var tg := Telegraph.new().setup(r, warn, Color(Damage.COLOR_PHYSICAL, 0.8))
		tg.position = at
		e.world.fx.add_child(tg)
		var eid := e.get_instance_id()
		tg.finished.connect(func() -> void:
			var e2 := instance_from_id(eid) as Enemy
			if e2 == null or not e2.is_alive(): return
			WadeSplash.burst(e2.world.fx, at, r * 0.8)
			for p in e2.world.players:
				if p.health > 0.0 and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < r + p.data.hurt_radius:
					var d := Damage.new(float(e2.data.param("slam_damage", 20.0)), 0.0)
					d.knockback = (p.global_position - at).normalized()
					p.take_damage(d))
