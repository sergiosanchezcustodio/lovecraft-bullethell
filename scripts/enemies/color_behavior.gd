class_name ColorBehavior
extends EnemyBehavior
## El color que sube del pozo (hito 21.13), jefe de la noche suelta «El color que cayó del cielo».
## Sale del pozo (`from`, la posición del pozo en la arena), subiendo despacio sin que le hagan daño,
## y luego flota: ronda a `keep` m del jugador más cercano, dispara su espiral (`attack` del dato) y
## siembra el color bajo los pies de los jugadores (ColorBlight.seed_at, con un aviso). En tres fases
## según su vida:
##   1 (100-60 %): ronda despacio; espiral cada `spiral_every` s y una mancha cada `seed_every` s.
##   2 (60-25 %): más deprisa; además, anillos con huecos (`ring_pattern`) y reses grises (`minion`).
##   3 (< 25 %): se acerca y lo suelta todo a la vez.
## Al morir, el color sube al cielo en una columna de luz.
const RISE := 2.6                      ## s que tarda en salir del pozo
const HOVER := 0.7                     ## m sobre el suelo

var phase := 1
var _t := 0.0
var _spiral := 0.0
var _ring := 0.0
var _seed := 0.0
var _minion := 0.0
var _side := 1.0

func start(e: Enemy) -> void:
	var from: Variant = e.data.param("from", null)
	if from is Vector2:
		e.position = Vector3((from as Vector2).x, -2.0, (from as Vector2).y)
	e.shield_t = RISE
	_spiral = 3.0
	_seed = 2.0
	_minion = 6.0
	_ring = 4.0
	_side = 1.0 if randf() < 0.5 else -1.0
	e.died.connect(func(x: Enemy) -> void: _to_the_sky(x))
	if e.world != null:
		e.world.sfx("color_rise", e.position)
		VoxelFx.puff(e.world.fx, e.position + Vector3(0, 2.0, 0), "sparkle", 2.2, ColorBlight.COLOR, 2.0)

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.6 else (2 if k > 0.25 else 3)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	if _t < RISE:                                   # sube del pozo
		e.anim = "burst"
		e.position.y = lerpf(-2.0, HOVER, Anims.ease(_t / RISE))
		return Vector3.ZERO
	e.position.y = HOVER + sin(_t * 1.6) * 0.25
	var p := phase_for(e)
	if p != phase:
		phase = p
		e.shield_t = 1.0
		e.world.sfx("color_rise", e.global_position)
		e.world.shout(String(e.data.param("phase_text", "…")), e.global_position + Vector3(0, 4.5, 0), ColorBlight.COLOR, 100, 1.5, 1.8)
	if target == null: return Vector3.ZERO
	var k: float = [1.0, 1.0, 1.45, 1.8][phase]
	_spiral -= delta * k
	_seed -= delta * k
	if phase >= 2:
		_ring -= delta * k
		_minion -= delta
	if _spiral <= 0.0:
		_spiral = float(e.data.param("spiral_every", 6.0))
		_fire(e, target, e.data.attack)
	if _ring <= 0.0:
		_ring = float(e.data.param("ring_every", 5.0))
		_fire(e, target, e.data.param("ring_pattern", null))
	if _seed <= 0.0:
		_seed = float(e.data.param("seed_every", 6.0))
		_sow(e)
	if _minion <= 0.0:
		_minion = float(e.data.param("minion_every", 10.0))
		_spawn_minions(e)
	e.anim = "burst" if e.runner != null and e.runner.busy else "walk"
	# ronda: a `keep` m del jugador, de lado; en la fase 3, encima
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	if d < 0.01: return Vector3.ZERO
	var dir := to / d
	var keep := float(e.data.param("keep", 6.5)) * (0.45 if phase == 3 else 1.0)
	var side := Vector3(-dir.z, 0, dir.x) * _side
	var v := side * 0.8 + dir * clampf((d - keep) * 0.5, -1.0, 1.0)
	return v.normalized() * e.data.move_speed * (1.0 + 0.3 * (phase - 1))

func _fire(e: Enemy, target: Player, pat: BulletPattern) -> void:
	if pat == null or e.runner == null: return
	e.runner.busy = false
	e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)

## Una mancha bajo los pies de un jugador al azar (crece desde pequeña: da tiempo a salir).
func _sow(e: Enemy) -> void:
	var cb := ColorBlight.current
	if cb == null: return
	var alive := e.world.players.filter(func(q: Player) -> bool: return q.health > 0.0)
	if alive.is_empty(): return
	var q: Player = alive[randi() % alive.size()]
	var at := Vector2(q.global_position.x, q.global_position.z) + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	cb.seed_at(at, float(e.data.param("seed_radius", 2.8)) * (1.0 + 0.2 * (phase - 1)), 24.0)

func _spawn_minions(e: Enemy) -> void:
	var game := e.get_tree().current_scene
	var d: EnemyData = e.data.param("minion", null)
	if d == null or game == null or game.get("director") == null: return
	for i in int(e.data.param("minion_count", 2)):
		var a := randf() * TAU
		game.director.spawn(d, Vector3(e.global_position.x, 0.0, e.global_position.z) + Vector3(cos(a), 0, sin(a)) * 2.5)

## El final del relato: el color sube al cielo en una columna de luz y se va.
func _to_the_sky(e: Enemy) -> void:
	if e.world == null or e.world.fx == null: return
	var at := Vector3(e.global_position.x, 0.0, e.global_position.z)
	var col := MeshInstance3D.new()
	col.mesh = VoxelFx.box(Vector3(1.6, 40.0, 1.6))
	var m := VoxelFx.std()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(ColorBlight.COLOR, 0.9)
	col.material_override = m
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	col.position = at + Vector3(0, 20.0, 0)
	col.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	e.world.fx.add_child(col)
	var tw := col.create_tween()
	tw.tween_property(col, "scale", Vector3(2.2, 1.0, 2.2), 0.5).from(Vector3(0.2, 1.0, 0.2))
	tw.tween_property(col, "scale", Vector3(0.05, 1.0, 0.05), 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(col.queue_free)
	for i in 5:
		VoxelFx.puff(e.world.fx, at + Vector3(0, 1.5 + i * 2.5, 0), "sparkle", 1.6, ColorBlight.COLOR, 2.5)
	e.world.sfx("color_rise", at)

func can_shoot(_e: Enemy) -> bool:
	return false                                   # dispara por su cuenta (_fire)

func touches(_e: Enemy) -> bool:
	return _t >= RISE
