class_name PolypBossBehavior
extends EnemyBehavior
## El pólipo antiguo (hito 21.15), jefe de la noche suelta «La sombra fuera del tiempo». Sube por la gran
## trampilla del archivo (PolypWinds.great, o `from`), que se abre y sopla mientras vive. Es a medias
## material, y lo es a ratos:
##   con cuerpo (`solid_time` s): se ve a medias, se le puede dar y toca; escupe el vendaval (`attack`)
##     cada `gale_every` s y cada `breath_every` s toma aliento: silba `breath_tell` s y tira de todos
##     hacia él `breath_time` s (PolypWinds.pull).
##   sin cuerpo (`void_time` s): oculto (Enemy.buried: no se le apunta ni se le da) y sin modelo; solo
##     se ve su remolino de arena, enorme, y se mueve deprisa hacia su presa (`void_speed`). Al acabar,
##     un aviso en el suelo (`return_tell` s) y vuelve a tener cuerpo de golpe (`return_damage` en
##     `return_radius` m).
## Lo que revela (la Máquina del más allá de Tillinghast, las ondas que sacan a los ocultos) lo obliga a
## tener cuerpo mientras dura. Desde la mitad de la vida abre todas las trampillas (fase 2); por debajo
## del 20 %, todo más deprisa y con menos cuerpo (fase 3). Al morir se cierra la gran trampilla.

enum Form { RISING, SOLID, VOID, RETURNING }

const DUST := Color(0.80, 0.62, 0.42)
const WIND := Color(0.85, 0.80, 0.95)

var phase := 1
var form: int = Form.RISING
var _t := 0.0
var _gale := 3.0
var _breath := 6.0
var _breathing := 0.0
var _goal := Vector3.ZERO

func start(e: Enemy) -> void:
	var at := Vector3.ZERO
	var pw := PolypWinds.current
	if pw != null and pw.great != Vector2.INF: at = Vector3(pw.great.x, 0.0, pw.great.y)
	else:
		var from: Variant = e.data.param("from", null)
		if from is Vector2: at = Vector3((from as Vector2).x, 0.0, (from as Vector2).y)
	e.position = at + Vector3(0, float(e.data.param("fly", 0.4)), 0)
	set_hidden(e, true)
	form = Form.RISING
	_t = float(e.data.param("rise_time", 2.5))
	_gale = 3.0
	_breath = float(e.data.param("breath_every", 9.0)) * 0.6
	e.died.connect(func(x: Enemy) -> void: _on_death(x))
	if pw != null: pw.open_great(true)
	if e.world != null:
		e.world.sfx("polyp_cry", at)
		e.world.shake(0.6)

static func set_hidden(e: Enemy, hidden: bool) -> void:
	e.buried = hidden
	if e.visual != null: e.visual.visible = not hidden

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.5 else (2 if k > 0.2 else 3)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var p := phase_for(e)
	if p != phase:
		phase = p
		e.world.sfx("polyp_cry", e.global_position)
		e.world.shake(0.4)
		e.world.shout(String(e.data.param("phase_text_%d" % p, "…")), e.global_position + Vector3(0, 5.0, 0), WIND, 90, 1.5, 2.2)
		if p == 2 and PolypWinds.current != null: PolypWinds.current.open_all()
	var k: float = [1.0, 1.0, 1.2, 1.5][phase]
	var fly := float(e.data.param("fly", 0.4))
	e.position.y = lerpf(e.position.y, fly + sin(e._spawn_t * 1.4) * 0.2, minf(1.0, delta * 3.0))
	match form:
		Form.RISING:
			_t -= delta
			e.anim = "idle"
			if _t <= 0.0: _materialize(e, false)
			return Vector3.ZERO
		Form.VOID:
			_t -= delta * k
			e.anim = "walk"
			if e.is_revealed():                          # lo que revela lo obliga a tener cuerpo
				_materialize(e, false)
				return Vector3.ZERO
			if target != null: _goal = target.global_position
			if _t <= 0.0:
				form = Form.RETURNING
				_t = float(e.data.param("return_tell", 1.0))
				var tg := Telegraph.enemy(float(e.data.param("return_radius", 3.5)), _t, Color(WIND, 0.8))
				tg.position = Vector3(e.global_position.x, 0.0, e.global_position.z)
				e.world.fx.add_child(tg)
				e.world.sfx("polyp_rush", e.global_position)
				return Vector3.ZERO
			var to := _goal - e.global_position
			to.y = 0.0
			if to.length() < 1.0: return Vector3.ZERO
			return to.normalized() * e.data.move_speed * float(e.data.param("void_speed", 2.4))
		Form.RETURNING:
			_t -= delta
			e.anim = "idle"
			if _t <= 0.0: _materialize(e, true)
			return Vector3.ZERO
	# con cuerpo
	if _breathing > 0.0:
		_breathing -= delta
		e.anim = "burst"
		return Vector3.ZERO
	_t -= delta * k
	_gale -= delta * k
	_breath -= delta * k
	if _gale <= 0.0 and target != null:
		_gale = float(e.data.param("gale_every", 4.0))
		_fire(e, target)
	if _breath <= 0.0:
		_breath = float(e.data.param("breath_every", 9.0))
		_breathe(e)
		return Vector3.ZERO
	if _t <= 0.0 and not e.is_revealed():
		form = Form.VOID
		_t = float(e.data.param("void_time", 4.0)) * (0.8 if phase == 3 else 1.0)
		set_hidden(e, true)
		e.world.sfx("polyp_vanish", e.global_position)
		e.world.shout(String(e.data.param("void_text", "Se deshace en el viento…")), e.global_position + Vector3(0, 4.0, 0), WIND, 64, 1.0, 1.4)
		return Vector3.ZERO
	e.anim = "burst" if e.runner != null and e.runner.busy else "walk"
	if target == null: return Vector3.ZERO
	var to2 := target.global_position - e.global_position
	to2.y = 0.0
	var d := to2.length()
	if d < 2.5: return Vector3.ZERO
	return to2 / d * e.data.move_speed * (1.0 + 0.15 * (phase - 1))

## Vuelve a tener cuerpo: se ve, se le puede dar y, si venía de fuera, golpea donde aparece.
func _materialize(e: Enemy, strike: bool) -> void:
	set_hidden(e, false)
	form = Form.SOLID
	_t = float(e.data.param("solid_time", 8.0)) * [1.0, 1.0, 0.9, 0.7][phase]
	var at := Vector3(e.global_position.x, 0.0, e.global_position.z)
	e.world.sfx("polyp_cry", at)
	e.world.shake(0.35)
	if strike:
		var r := float(e.data.param("return_radius", 3.5))
		var dm := Damage.new(float(e.data.param("return_damage", 16.0)), 4.0)
		dm.source = e
		e.world.strike(at, r, dm)
		e.world.ground_hit(at, r, DUST)
		DecorBreak.blast(at, r)

## Toma aliento: silba y tira de todos hacia él.
func _breathe(e: Enemy) -> void:
	var tell := float(e.data.param("breath_tell", 1.0))
	var t := float(e.data.param("breath_time", 2.5))
	_breathing = tell + t
	e.windup(tell)
	e.world.sfx("polyp_breath", e.global_position)
	e.world.shout(String(e.data.param("breath_text", "Toma aliento…")), e.global_position + Vector3(0, 4.6, 0), WIND, 60, 1.0, 1.3)
	var eid := e.get_instance_id()
	e.get_tree().create_timer(tell, false, true).timeout.connect(func() -> void:
		var e2 := instance_from_id(eid) as Enemy
		if e2 == null or not e2.is_alive() or PolypWinds.current == null: return
		PolypWinds.current.pull(e2.global_position, t, float(e2.data.param("breath_force", 2.6))))

func _fire(e: Enemy, target: Player) -> void:
	if e.data.attack == null or e.runner == null: return
	e.runner.busy = false
	e.runner.fire(e.data.attack, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)

## Al morir: se ve, grita y la gran trampilla se cierra.
func _on_death(e: Enemy) -> void:
	set_hidden(e, false)
	if PolypWinds.current != null: PolypWinds.current.open_great(false)
	if e.world == null or e.world.fx == null: return
	var at := Vector3(e.global_position.x, 0.0, e.global_position.z)
	e.world.sfx("polyp_cry", at)
	e.world.shake(0.7)
	e.world.shout(String(e.data.param("death_text", "El silbido se apaga bajo la arena…")), at + Vector3(0, 5.5, 0), WIND, 100, 1.8, 2.8)

func can_shoot(_e: Enemy) -> bool:
	return false                                   # dispara por su cuenta (_fire)

func touches(_e: Enemy) -> bool:
	return form == Form.SOLID

func has_body() -> bool:
	return form == Form.SOLID
