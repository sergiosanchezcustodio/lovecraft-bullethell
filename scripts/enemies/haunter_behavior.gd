class_name HaunterBehavior
extends EnemyBehavior
## El Morador de las Tinieblas (hito 23.8), jefe de la noche suelta «El que acecha en la oscuridad». Baja
## del campanario de la iglesia (`steeple` en el JSON de la arena, que lee Blackout; o `from`): `rise_time` s
## sin cuerpo y después vuela a `keep` m de su presa, siempre a oscuras. No entra en la luz de las farolas
## ni en la del farol de los jugadores (`light_k`); si queda dentro, la luz lo quema (`burn` × su vida por
## segundo), chilla y retrocede sin atacar. El destello de un rayo lo deslumbra `flash_stun` s.
##   - Los ojos (`attack`, el ojo de tres lóbulos) cada `eyes_every` s.
##   - A oscuras (apagón), se lanza en picado sobre su presa cada `swoop_every` s: aviso `swoop_tell` s y un
##     vuelo de `swoop_time` s que golpea al pasar.
##   - Por debajo del 60 % (fase 2), revienta la farola encendida más cerca (`break_range` m) cada
##     `break_every` s, que queda a oscuras `break_off` s, y llama a `spawn_count` sombras (`spawn`) cada
##     `spawn_every` s.
##   - Por debajo del 25 % (fase 3), corta la corriente `cut_time` s cada `cut_every` s y va más deprisa.

enum Form { RISING, OUT }

const DARK := Color(0.85, 0.25, 0.22)            ## el ojo que arde
const BURN_TICK := 0.25

var phase := 1
var form: int = Form.RISING
var burned := 0.0                                ## daño de luz (tests)
var swoops := 0                                  ## picados (tests)
var _t := 0.0
var _eyes := 3.0
var _swoop := 3.0
var _swoop_t := 0.0                              ## >0: en picado
var _swoop_dir := Vector3.ZERO
var _break := 4.0
var _spawn := 5.0
var _cut := 6.0
var _burn := 0.0
var _dazed := 0.0
var _was_flash := false

func start(e: Enemy) -> void:
	var at := Vector3.ZERO
	var b := Blackout.current
	if b != null and b.steeple != Vector3.INF: at = Vector3(b.steeple.x, 0.0, b.steeple.z + 2.5)
	else:
		var from: Variant = e.data.param("from", null)
		if from is Vector2: at = Vector3((from as Vector2).x, 0.0, (from as Vector2).y)
	e.position = at + Vector3(0, float(e.data.param("fly", 1.6)), 0)
	VoidBehavior.set_hidden(e, true)
	form = Form.RISING
	_t = float(e.data.param("rise_time", 2.5))
	e.died.connect(func(x: Enemy) -> void: _on_death(x))
	if e.world != null:
		e.world.sfx("haunter_screech", at)
		e.world.shake(0.6)
		if b != null and b.steeple != Vector3.INF and e.world.fx != null:
			VoxelFx.puff(e.world.fx, b.steeple, "smoke", 1.4, Color(0.05, 0.04, 0.06), 1.6)

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.6 else (2 if k > 0.25 else 3)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var fly := float(e.data.param("fly", 1.6))
	var low := _swoop_t > 0.0
	e.position.y = lerpf(e.position.y, (0.5 if low else fly) + sin(e._spawn_t * 1.3) * 0.25, minf(1.0, delta * 4.0))
	if form == Form.RISING:
		_t -= delta
		e.anim = "idle"
		if _t <= 0.0:
			form = Form.OUT
			VoidBehavior.set_hidden(e, false)
			e.world.sfx("haunter_screech", e.global_position)
			e.world.shake(0.4)
		return Vector3.ZERO
	var b := Blackout.current
	var p := phase_for(e)
	if p != phase:
		phase = p
		e.world.sfx("haunter_screech", e.global_position)
		e.world.shake(0.4)
		e.world.shout(String(e.data.param("phase_text_%d" % p, "…")), e.global_position + Vector3(0, 5.0, 0), DARK, 90, 1.5, 2.2)
	var k: float = [1.0, 1.0, 1.15, 1.4][phase]
	# el rayo lo deslumbra
	var fl := b != null and b.flash_lit
	if fl and not _was_flash:
		_dazed = float(e.data.param("flash_stun", 0.8))
		_swoop_t = 0.0
	_was_flash = fl
	if _dazed > 0.0:
		_dazed -= delta
		e.anim = "idle"
		return Vector3.ZERO
	var lk := float(e.data.param("light_k", 0.55))
	var lit := DarkBehavior.light_for(e.world, e.global_position, lk) if not fl else Vector3.INF
	if _swoop_t > 0.0:                                         # en picado: atraviesa lo que haga falta
		_swoop_t -= delta
		e.anim = "burst"
		if lit != Vector3.INF: _scorch(e, delta)
		return _swoop_dir * e.data.move_speed * float(e.data.param("swoop_speed", 3.2))
	if lit != Vector3.INF:                                     # dentro de la luz: se quema y sale
		_scorch(e, delta)
		e.anim = "walk"
		var out := (e.global_position - lit) * Vector3(1, 0, 1)
		return out.normalized() * e.data.move_speed * 1.4 * k if out.length() > 0.01 else Vector3.RIGHT * e.data.move_speed
	_eyes -= delta * k
	if _eyes <= 0.0 and target != null:
		_eyes = float(e.data.param("eyes_every", 3.5))
		_fire(e, target, e.data.attack)
	var dark := b != null and not b.power
	if dark and target != null:
		_swoop -= delta * k
		if _swoop <= 0.0:
			_swoop = float(e.data.param("swoop_every", 4.0))
			_start_swoop(e, target)
			return Vector3.ZERO
	if phase >= 2:
		_break -= delta * k
		_spawn -= delta * k
		if _break <= 0.0 and b != null:
			_break = float(e.data.param("break_every", 9.0))
			var i := b.nearest_lit(e.global_position, float(e.data.param("break_range", 14.0)))
			if i >= 0:
				b.douse(i, float(e.data.param("break_off", 25.0)))
				e.world.sfx("haunter_screech", e.global_position)
				e.world.shout(String(e.data.param("break_text", L.t("Revienta una farola…"))), e.global_position + Vector3(0, 4.6, 0), DARK, 60, 1.0, 1.3)
		if _spawn <= 0.0:
			_spawn = float(e.data.param("spawn_every", 12.0))
			_call_shadows(e)
	if phase >= 3 and b != null and b.power:
		_cut -= delta
		if _cut <= 0.0:
			_cut = float(e.data.param("cut_every", 14.0))
			b.cut(float(e.data.param("cut_time", 6.0)))
			e.world.shout(String(e.data.param("cut_text", L.t("Se va la luz en toda la colina…"))), e.global_position + Vector3(0, 5.0, 0), DARK, 80, 1.2, 1.8)
	e.anim = "burst" if e.runner != null and e.runner.busy else "walk"
	if target == null: return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	var keep := float(e.data.param("keep", 6.5))
	var side := Vector3(-to.z, 0.0, to.x).normalized() * 0.5
	var v: Vector3
	if d < keep - 1.0: v = (-to / maxf(d, 0.01) + side).normalized() * e.data.move_speed * k * 0.7
	elif d < keep + 1.5: v = side * e.data.move_speed * k
	else: v = to / d * e.data.move_speed * k
	# no da el paso que le meta en una luz
	if v.length() > 0.01 and DarkBehavior.light_for(e.world, e.global_position + v.normalized() * 0.8, lk) != Vector3.INF:
		v = Vector3(-v.z, 0, v.x)
	return v

func _start_swoop(e: Enemy, target: Player) -> void:
	var tell := float(e.data.param("swoop_tell", 0.7))
	e.windup(tell)
	e.world.sfx("shadow_wing", e.global_position)
	var to := (target.global_position - e.global_position) * Vector3(1, 0, 1)
	_swoop_dir = to.normalized() if to.length() > 0.01 else Vector3.FORWARD
	var eid := e.get_instance_id()
	e.get_tree().create_timer(tell, false, true).timeout.connect(func() -> void:
		var e2 := instance_from_id(eid) as Enemy
		if e2 == null or not e2.is_alive(): return
		swoops += 1
		_swoop_t = float(e2.data.param("swoop_time", 0.9)))

## Se cuelan sombras del campanario junto a él.
func _call_shadows(e: Enemy) -> void:
	var game := e.get_tree().current_scene
	var ed: EnemyData = e.data.param("spawn", null)
	if ed == null or game == null or game.get("director") == null: return
	for i in int(e.data.param("spawn_count", 3)):
		var a := randf() * TAU
		game.director.spawn(ed, Vector3(e.global_position.x, 0.0, e.global_position.z) + Vector3(cos(a), 0, sin(a)) * 2.0)

func _fire(e: Enemy, target: Player, pat: BulletPattern) -> void:
	if pat == null or e.runner == null: return
	e.runner.busy = false
	e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)

## La luz lo quema (a tics).
func _scorch(e: Enemy, delta: float) -> void:
	_burn -= delta
	if _burn > 0.0: return
	_burn = BURN_TICK
	var dmg := e.data.max_health * e.health_scale * float(e.data.param("burn", 0.012)) * BURN_TICK
	burned += dmg
	var dm := Damage.new(dmg, 0.0)
	dm.tag = Blackout.TAG
	e.take_damage(dm)
	if FxShade.on(): HitSparks.burst("glint_ember", e.global_position + Vector3(0, 1.2, 0))
	if randf() < 0.15: e.world.sfx("haunter_screech", e.global_position)

## Al morir: chilla y se deshace; vuelve la luz.
func _on_death(e: Enemy) -> void:
	VoidBehavior.set_hidden(e, false)
	if e.world == null or e.world.fx == null: return
	var at := Vector3(e.global_position.x, 0.0, e.global_position.z)
	e.world.sfx("haunter_screech", at)
	e.world.shake(0.7)
	e.world.shout(String(e.data.param("death_text", L.t("La cosa se deshace en la luz."))), at + Vector3(0, 5.5, 0), DARK, 100, 1.8, 2.8)
	VoxelFx.puff(e.world.fx, at + Vector3(0, 1.5, 0), "smoke", 1.6, Color(0.05, 0.04, 0.06), 1.8)
	var b := Blackout.current
	if b != null and b.host and not b.power: b.restore()

func can_shoot(_e: Enemy) -> bool:
	return false

func touches(_e: Enemy) -> bool:
	return form == Form.OUT and (_swoop_t > 0.0 or (Blackout.current != null and not Blackout.current.power))

func has_body() -> bool:
	return form == Form.OUT
