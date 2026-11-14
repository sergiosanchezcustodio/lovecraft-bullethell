class_name MaskBehavior
extends KeepBehavior
## El sumo sacerdote que no debe describirse (hito 21.10, jefe intermedio del nivel 3 de la parte 4): se
## mueve y ataca como `KeepBehavior` (flautas y tambores) y cada `unmask_every` s se levanta la máscara de
## seda amarilla: avisa (`unmask_warn` s, un aro amarillo y «¡Aparta la vista!») y la deja levantada
## `unmask_time` s. Mientras, quien esté a menos de `gaze_r` m **mirándolo** (de cara a él: el cuerpo
## mira hacia donde se anda) pierde `gaze_drain` de cordura por segundo. Para no verle la cara, hay que
## darle la espalda. La máscara es la parte `hat` del modelo.
## En red, el anfitrión decide cuándo (la animación "unmask" viaja en la foto) y cada PC lo aplica a sus
## jugadores, en `puppet_step`.

enum State { MASKED, WARN, BARE }

var state := State.MASKED
var _ut := 0.0
var _st := 0.0

func start(e: Enemy) -> void:
	super.start(e)
	_ut = float(e.data.param("unmask_every", 9.0)) * 0.6

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var p := e.data.params
	_st += delta
	match state:
		State.MASKED:
			_ut -= delta
			if _ut <= 0.0:
				_enter(State.WARN)
				var tg := Telegraph.enemy(float(p.get("gaze_r", 13.0)), float(p.get("unmask_warn", 1.2)), Color(1.0, 0.85, 0.25, 0.35), false)
				tg.position = Vector3(e.global_position.x, 0.0, e.global_position.z)
				e.world.fx.add_child(tg)
				e.world.shout("¡Aparta la vista!", e.global_position + Vector3(0, 2.6, 0), Color(1.0, 0.85, 0.3))
				e.world.sfx("chant", e.global_position)
		State.WARN:
			e.anim = "idle"
			if _st >= float(p.get("unmask_warn", 1.2)): _enter(State.BARE)
			return Vector3.ZERO
		State.BARE:
			e.anim = "unmask"
			_mask(e, false)
			_gaze(e, delta)
			if _st >= float(p.get("unmask_time", 3.0)):
				_mask(e, true)
				_ut = float(p.get("unmask_every", 9.0))
				_enter(State.MASKED)
			return Vector3.ZERO
	return super.update(e, target, delta)

func puppet_step(e: Enemy, delta: float) -> void:
	var bare := e.anim == "unmask"
	_mask(e, not bare)
	if bare: _gaze(e, delta)

func _enter(s: State) -> void:
	state = s
	_st = 0.0

func _gaze(e: Enemy, delta: float) -> void:
	var r := float(e.data.param("gaze_r", 13.0))
	var dot := float(e.data.param("gaze_dot", 0.3))
	for q in e.world.players:
		if q.remote or q.health <= 0.0: continue
		if gazing(q, e.global_position, r, dot):
			q.drain_sanity(float(e.data.param("gaze_drain", 7.0)) * delta, String(e.data.display_name), &"aura")

## ¿Mira `q` hacia `at` (a menos de `r` m, con el coseno del ángulo de su cuerpo al menos `dot`)?
static func gazing(q: Player, at: Vector3, r: float, dot: float) -> bool:
	var to := at - q.global_position
	to.y = 0.0
	var d := to.length()
	if d > r: return false
	if d < 0.5: return true
	var y := q.visual.rotation.y if q.visual != null else q.rotation.y
	return Vector3(sin(y), 0.0, cos(y)).dot(to / d) >= dot

func _mask(e: Enemy, on: bool) -> void:
	var m: Node3D = e.get("model")
	if m == null: return
	var parts: Variant = m.get_meta("part_nodes", {})
	var h: Node3D = (parts as Dictionary).get("hat") if parts is Dictionary else null
	if h != null and h.visible != on: h.visible = on

func can_shoot(e: Enemy) -> bool:
	return state == State.MASKED and super.can_shoot(e)
