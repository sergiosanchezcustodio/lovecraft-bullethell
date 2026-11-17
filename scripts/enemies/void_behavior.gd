class_name VoidBehavior
extends EnemyBehavior
## Lo que hay tras la ventana (hito 22.6), jefe de la noche suelta «La música de Erich Zann». Sale por la
## ventana de la buhardilla de Zann (ZannViola.window, o `from`): `rise_time` s sin cuerpo mientras se
## abre paso, y después flota a `keep` m de su presa. La viola lo aparta y le hace daño en cada compás,
## como a todo lo de fuera (`outer`).
##   - Las estrellas (`attack`) cada `stars_every` s.
##   - El viento de la ventana cada `wind_every` s: avisa `wind_tell` s y tira de todos hacia él
##     `wind_time` s (ZannViola.pull).
##   - Por debajo del 60 % (fase 2), anillos con huecos (`ring`, la ruta de otro patrón) cada `ring_every` s
##     y `spawn_count` jirones (`spawn`, un EnemyData) cada `spawn_every` s.
##   - Por debajo del 25 % (fase 3), la viola calla a ratos (`hush_every`, `hush_time`) y él va más deprisa.
## Al morir se cierra la ventana.

enum Form { RISING, OUT }

const NIGHT := Color(0.62, 0.56, 0.95)

var phase := 1
var form: int = Form.RISING
var _t := 0.0
var _stars := 2.5
var _wind := 6.0
var _ring := 3.0
var _spawn := 4.0
var _hush := 5.0
var _blowing := 0.0
var _ring_pattern: BulletPattern

func start(e: Enemy) -> void:
	var at := Vector3.ZERO
	var zv := ZannViola.current
	if zv != null and zv.window != Vector3.INF: at = Vector3(zv.ground.x, 0.0, zv.ground.y + 2.5)
	else:
		var from: Variant = e.data.param("from", null)
		if from is Vector2: at = Vector3((from as Vector2).x, 0.0, (from as Vector2).y)
	e.position = at + Vector3(0, float(e.data.param("fly", 1.0)), 0)
	set_hidden(e, true)
	form = Form.RISING
	_t = float(e.data.param("rise_time", 2.5))
	_wind = float(e.data.param("wind_every", 10.0)) * 0.6
	var rp := String(e.data.param("ring", ""))
	if rp != "" and ResourceLoader.exists(rp): _ring_pattern = load(rp)
	e.died.connect(func(x: Enemy) -> void: _on_death(x))
	if e.world != null:
		e.world.sfx("void_howl", at)
		e.world.shake(0.6)
		if zv != null and zv.window != Vector3.INF and e.world.fx != null:
			VoxelFx.puff(e.world.fx, zv.window, "sparkle", 1.2, NIGHT, 1.6)

static func set_hidden(e: Enemy, hidden: bool) -> void:
	e.buried = hidden
	if e.visual != null: e.visual.visible = not hidden

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.6 else (2 if k > 0.25 else 3)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var fly := float(e.data.param("fly", 1.0))
	e.position.y = lerpf(e.position.y, fly + sin(e._spawn_t * 1.1) * 0.3, minf(1.0, delta * 3.0))
	if form == Form.RISING:
		_t -= delta
		e.anim = "idle"
		if _t <= 0.0:
			form = Form.OUT
			set_hidden(e, false)
			e.world.sfx("void_howl", e.global_position)
			e.world.shake(0.4)
		return Vector3.ZERO
	var p := phase_for(e)
	if p != phase:
		phase = p
		e.world.sfx("void_howl", e.global_position)
		e.world.shake(0.4)
		e.world.shout(String(e.data.param("phase_text_%d" % p, "…")), e.global_position + Vector3(0, 5.0, 0), NIGHT, 90, 1.5, 2.2)
	var k: float = [1.0, 1.0, 1.15, 1.4][phase]
	if _blowing > 0.0:
		_blowing -= delta
		e.anim = "burst"
		return Vector3.ZERO
	_stars -= delta * k
	_wind -= delta * k
	if _stars <= 0.0 and target != null:
		_stars = float(e.data.param("stars_every", 4.5))
		_fire(e, target, e.data.attack)
	if phase >= 2:
		_ring -= delta * k
		_spawn -= delta * k
		if _ring <= 0.0 and target != null and _ring_pattern != null:
			_ring = float(e.data.param("ring_every", 6.0))
			_fire(e, target, _ring_pattern)
		if _spawn <= 0.0:
			_spawn = float(e.data.param("spawn_every", 11.0))
			_call_shreds(e)
	if phase >= 3:
		_hush -= delta
		if _hush <= 0.0:
			_hush = float(e.data.param("hush_every", 9.0))
			var ht := float(e.data.param("hush_time", 3.5))
			if ZannViola.current != null: ZannViola.current.hush(ht)
			e.world.shout(String(e.data.param("hush_text", L.t("La viola calla…"))), e.global_position + Vector3(0, 5.0, 0), NIGHT, 70, 1.2, 1.8)
	if _wind <= 0.0:
		_wind = float(e.data.param("wind_every", 10.0))
		_blow(e)
		return Vector3.ZERO
	e.anim = "burst" if e.runner != null and e.runner.busy else "walk"
	if target == null: return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	var keep := float(e.data.param("keep", 7.0))
	var side := Vector3(-to.z, 0.0, to.x).normalized() * 0.5
	if d < keep - 1.0: return (-to / maxf(d, 0.01) + side).normalized() * e.data.move_speed * k * 0.7
	if d < keep + 1.5: return side * e.data.move_speed * k
	return to / d * e.data.move_speed * k

## El viento de la ventana: avisa y tira de todos hacia él.
func _blow(e: Enemy) -> void:
	var tell := float(e.data.param("wind_tell", 1.0))
	var t := float(e.data.param("wind_time", 2.5))
	_blowing = tell + t
	e.windup(tell)
	e.world.sfx("void_wind", e.global_position)
	e.world.shout(String(e.data.param("wind_text", L.t("Sopla el viento de la ventana…"))), e.global_position + Vector3(0, 4.6, 0), NIGHT, 60, 1.0, 1.3)
	var eid := e.get_instance_id()
	e.get_tree().create_timer(tell, false, true).timeout.connect(func() -> void:
		var e2 := instance_from_id(eid) as Enemy
		if e2 == null or not e2.is_alive() or ZannViola.current == null: return
		ZannViola.current.pull(e2.global_position, t, float(e2.data.param("wind_force", 2.4))))

## Se cuelan jirones de la noche junto a él.
func _call_shreds(e: Enemy) -> void:
	var game := e.get_tree().current_scene
	var ed: EnemyData = e.data.param("spawn", null)
	if ed == null or game == null or game.get("director") == null: return
	for i in int(e.data.param("spawn_count", 2)):
		var a := randf() * TAU
		game.director.spawn(ed, Vector3(e.global_position.x, 0.0, e.global_position.z) + Vector3(cos(a), 0, sin(a)) * 2.0)

func _fire(e: Enemy, target: Player, pat: BulletPattern) -> void:
	if pat == null or e.runner == null: return
	e.runner.busy = false
	e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)

## Al morir: se ve, aúlla y la ventana se cierra.
func _on_death(e: Enemy) -> void:
	set_hidden(e, false)
	if e.world == null or e.world.fx == null: return
	var at := Vector3(e.global_position.x, 0.0, e.global_position.z)
	e.world.sfx("void_howl", at)
	e.world.shake(0.7)
	e.world.shout(String(e.data.param("death_text", L.t("La ventana se cierra de golpe. Silencio."))), at + Vector3(0, 5.5, 0), NIGHT, 100, 1.8, 2.8)
	if ZannViola.current != null: ZannViola.current.hush(999.0)

func can_shoot(_e: Enemy) -> bool:
	return false                                   # dispara por su cuenta (_fire)

func touches(_e: Enemy) -> bool:
	return form == Form.OUT

func has_body() -> bool:
	return form == Form.OUT
