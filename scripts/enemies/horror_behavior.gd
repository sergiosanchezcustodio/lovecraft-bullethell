class_name HorrorBehavior
extends EnemyBehavior
## El hermano de Wilbur (hito 21.14), jefe de la noche suelta «El horror de Dunwich». No se ve: va oculto
## (`Enemy.buried`: fuera de la rejilla, no se le puede apuntar ni dar) y con el modelo escondido; solo
## se ven sus huellas (Unseen), lo que rompe al pasar, sus golpes y las balas que salen de donde está.
## Lo descubre lo que revela (Enemy.reveal: el polvo de Ibn Ghazi, la Máquina del más allá de
## Tillinghast, las ondas que sacan a los ocultos): mientras dura se ve, se le puede dar y va más
## despacio (`reveal_slow`).
## Sale de la granja de los Whateley (`from`) rompiendo lo que tiene delante y va a por el jugador más
## cercano. Ataques:
##   pisotón: con un jugador a menos de `stomp_range` m, un aviso en el suelo bajo él y el golpe.
##   bocas: cada `mouth_every` s, las trompas escupen (`attack`).
##   Desde la mitad de la vida (fase 2) llama a los chotacabras (`minion`); por debajo del 20 % (fase 3),
##   todo más deprisa. Gritos de cada fase en `phase_text_2` y `phase_text_3`.
## Al morir, el rayo y «¡Padre! ¡Yog-Sothoth!» (`death_text`).

const STOMP_WARN := 0.9
const BOLT := Color(0.85, 0.9, 1.0)

var phase := 1
var _t := 0.0
var _stomp := 0.0
var _mouth := 0.0
var _call := 0.0
var _shown := false

func start(e: Enemy) -> void:
	var from: Variant = e.data.param("from", null)
	if from is Vector2: e.position = Vector3((from as Vector2).x, 0.0, (from as Vector2).y)
	set_hidden(e, true)
	_stomp = 3.0
	_mouth = 2.5
	_call = 4.0
	e.died.connect(func(x: Enemy) -> void: _thunder(x))
	if e.world != null:
		e.world.sfx("horror_cry", e.position)
		e.world.shake(0.5)
		DecorBreak.blast(e.position, 3.0)

## Escondido: fuera de la rejilla y sin modelo (las huellas las pone Unseen).
static func set_hidden(e: Enemy, hidden: bool) -> void:
	e.buried = hidden
	if e.visual != null: e.visual.visible = not hidden

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.5 else (2 if k > 0.2 else 3)

func is_shown() -> bool:
	return _shown

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_t += delta
	var shown := e.is_revealed()
	if shown != _shown:                                # el polvo lo descubre (o se le acaba)
		_shown = shown
		set_hidden(e, not shown)
		if shown: e.world.sfx("horror_cry", e.global_position)
	var p := phase_for(e)
	if p != phase:
		phase = p
		e.world.sfx("horror_cry", e.global_position)
		e.world.shake(0.4)
		e.world.shout(String(e.data.param("phase_text_%d" % p, "…")), e.global_position + Vector3(0, 5.5, 0), BOLT, 90, 1.5, 2.2)
	if target == null: return Vector3.ZERO
	var k: float = [1.0, 1.0, 1.25, 1.6][phase]
	_stomp -= delta * k
	_mouth -= delta * k
	if phase >= 2: _call -= delta
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	if _stomp <= 0.0 and d < float(e.data.param("stomp_range", 5.0)):
		_stomp = float(e.data.param("stomp_every", 3.5))
		_stomp_at(e, Vector3(target.global_position.x, 0.0, target.global_position.z))
	if _mouth <= 0.0:
		_mouth = float(e.data.param("mouth_every", 5.0))
		_fire(e, target)
	if _call <= 0.0:
		_call = float(e.data.param("minion_every", 9.0))
		_spawn_minions(e)
	e.anim = "burst" if e.runner != null and e.runner.busy else "walk"
	if d < 0.6: return Vector3.ZERO
	var v := to / d * e.data.move_speed * (1.0 + 0.2 * (phase - 1))
	if shown: v *= float(e.data.param("reveal_slow", 0.6))
	return v

## El pisotón: aviso en el suelo donde está el jugador y, al acabar, el golpe.
func _stomp_at(e: Enemy, at: Vector3) -> void:
	var r := float(e.data.param("stomp_radius", 3.0))
	var tg := Telegraph.enemy(r, STOMP_WARN, Color(Damage.COLOR_PHYSICAL, 0.85))
	tg.position = at
	e.world.fx.add_child(tg)
	var eid := e.get_instance_id()
	tg.finished.connect(func() -> void:
		var e2 := instance_from_id(eid) as Enemy
		if e2 == null or not e2.is_alive(): return
		e2.world.sfx("horror_step", at)
		e2.world.ground_hit(at, r, Color(0.3, 0.28, 0.22))
		e2.world.shake(0.3)
		var dm := Damage.new(float(e2.data.param("stomp_damage", 20.0)), 0.0)
		dm.source = e2
		e2.world.strike(at, r, dm)
		DecorBreak.blast(at, r)
		if Unseen.current != null: Unseen.current.add_print(Vector2(at.x, at.z), float(e2.data.param("print_size", 0.6)) * 1.3))

func _fire(e: Enemy, target: Player) -> void:
	if e.data.attack == null or e.runner == null: return
	e.runner.busy = false
	e.runner.fire(e.data.attack, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)

func _spawn_minions(e: Enemy) -> void:
	var game := e.get_tree().current_scene
	var d: EnemyData = e.data.param("minion", null)
	if d == null or game == null or game.get("director") == null: return
	for i in int(e.data.param("minion_count", 3)):
		var a := randf() * TAU
		game.director.spawn(d, Vector3(e.global_position.x, 0.0, e.global_position.z) + Vector3(cos(a), 0, sin(a)) * 3.0)

## El final del relato: el rayo cae sobre él y grita llamando a su padre (el rayo, en todos los PC).
func _thunder(e: Enemy) -> void:
	set_hidden(e, false)
	if e.world == null or e.world.fx == null: return
	var at := Vector3(e.global_position.x, 0.0, e.global_position.z)
	if Unseen.current != null: Unseen.current.bolt(at)
	e.world.sfx("thunder", at)
	e.world.shake(0.8)
	e.world.shout(String(e.data.param("death_text", "¡Padre! ¡Padre! ¡Yog-Sothoth!")), at + Vector3(0, 6.0, 0), BOLT, 110, 1.8, 2.8)

func can_shoot(_e: Enemy) -> bool:
	return false                                   # dispara por su cuenta (_fire)

func touches(_e: Enemy) -> bool:
	return true                                    # aunque no se vea, pisa
