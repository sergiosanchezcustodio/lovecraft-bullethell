class_name Rumble
extends RefCounted
## Vibración del mando (hito 16.30; antes, solo al recibir daño, Player._rumble). La fuerza sale
## de Configuración > Juego > Vibración del mando (`Settings.vibration`: 0 no, 0,5 suave, 1 normal,
## 1,5 fuerte; las configuraciones de antes guardaban true o false). Cada jugador vibra en su mando;
## el teclado, los bots y los jugadores de otros PC, no. Lo que hace vibrar:
##   golpe recibido (según lo fuerte), explosión cercana (según la distancia; las de tus armas,
##   menos), entrada de un jefe, el jefe que cae (todos), subida de nivel y crisis de cordura
##   (dos latidos).
## `log_rumble=true` escribe cada una («VIBRA J1 golpe 0,35 0,20 0,18 s»), haya mando o no.

const LEVELS: Array[float] = [0.0, 0.5, 1.0, 1.5]
const NAMES: Array[String] = ["No", "Suave", "Normal", "Fuerte"]
const GAP_MS := 120                        ## entre dos pulsos del mismo mando

static var trace := false
static var _players: Array = []            ## WeakRef de los jugadores en la partida
static var _last := {}                     ## dispositivo -> ms del último pulso

## Fuerza elegida (true/false de las configuraciones de antes: 1 y 0).
static func strength() -> float:
	var v: Variant = Auto.setting("vibration", 1.0)
	if v is bool: return 1.0 if v else 0.0
	return clampf(float(v), 0.0, 2.0)

static func level_index(v: Variant) -> int:
	var f := (1.0 if v else 0.0) if v is bool else float(v)
	var best := 2
	for i in LEVELS.size():
		if absf(LEVELS[i] - f) < absf(LEVELS[best] - f): best = i
	return best

static func add(q: Node) -> void:
	_players = _players.filter(func(w: WeakRef) -> bool: return w.get_ref() != null and w.get_ref() != q)
	_players.append(weakref(q))

static func players() -> Array:
	var out: Array = []
	for w: WeakRef in _players:
		var q: Variant = w.get_ref()
		if q != null and is_instance_valid(q) and (q as Node).is_inside_tree(): out.append(q)
	return out

## Un pulso en el mando de un jugador: motor débil (zumbido) y fuerte (golpe), de 0 a 1, y segundos.
static func pulse(q: Node, weak: float, strong: float, dur: float, why := "", gap_ms := GAP_MS) -> void:
	if q == null or not is_instance_valid(q) or bool(q.get("remote")): return
	var inp: PlayerInput = q.get("input")
	if inp == null: return
	var dev := inp.joy_device()
	var k := strength()
	if k <= 0.0 or (dev < 0 and not trace): return
	var key: Variant = dev if dev >= 0 else "j%d" % int(q.get("index"))
	var now := Time.get_ticks_msec()
	if now - int(_last.get(key, -100000)) < gap_ms: return
	_last[key] = now
	var w := clampf(weak * k, 0.0, 1.0)
	var s := clampf(strong * k, 0.0, 1.0)
	if trace: print("VIBRA J%d %s %.2f %.2f %.2f s" % [int(q.get("index")) + 1, why, w, s, dur])
	if dev >= 0: Input.start_joy_vibration(dev, w, s, dur)

## A todos los jugadores.
static func all(weak: float, strong: float, dur: float, why := "") -> void:
	for q in players(): pulse(q, weak, strong, dur, why, 0)

## Explosión en `pos`: a los que estén cerca, más cuanto más cerca. `own`: de un arma de jugador.
static func blast(pos: Vector3, radius: float, own: bool) -> void:
	var reach := radius * (1.6 if own else 2.6)
	for q in players():
		var d := Vector2((q as Node3D).global_position.x - pos.x, (q as Node3D).global_position.z - pos.z).length()
		if d > reach: continue
		var f := (1.0 - d / reach) * (0.45 if own else 1.0)
		pulse(q, 0.3 * f, 0.55 * f, 0.12 + 0.12 * f, "explosión", 250 if own else GAP_MS)

## Crisis de cordura: dos latidos.
static func heartbeat(q: Node) -> void:
	pulse(q, 0.55, 0.45, 0.22, "crisis", 0)
	if q != null and q.is_inside_tree():
		q.get_tree().create_timer(0.32, true).timeout.connect(func() -> void:
			if is_instance_valid(q): pulse(q, 0.4, 0.3, 0.2, "crisis", 0))
