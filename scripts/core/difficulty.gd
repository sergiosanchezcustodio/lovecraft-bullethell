class_name Difficulty
extends RefCounted
## Dificultad (10-10-2026, Configuración > Juego). "Investigador" es la de antes de este
## cambio; "Normal" busca más agobio: más enemigos a la vez, que llegan antes, y los de
## cuerpo a cuerpo más rápidos. Se aplica en WaveDirector (ritmo, tope y vida) y en Enemy
## (velocidad de los que no disparan). Para probar sin guardarlo: cfg_difficulty=N.
## 12-10-2026 (el autor la vio "muy muy fácil"): más enemigos aún, daño recibido mayor (el
## mental más) y presencia: los enemigos cercanos drenan cordura (Player._presence_step).

const NAMES: Array[String] = ["Investigador", "Normal", "Pesadilla"]
const RATE := [1.0, 2.6, 4.0]           ## ritmo de aparición (15-10-2026, simulado: con 8,5 el bot no pasaba el nivel 1 con ningún personaje de inicio)
const CAP := [1.0, 1.5, 1.8]            ## enemigos vivos a la vez (ver WaveDirector.HARD_CAP)
const DAMAGE := [1.0, 1.4, 1.8]         ## daño físico que reciben los jugadores
const MENTAL := [1.0, 1.7, 2.2]         ## daño mental que reciben los jugadores
const HORROR := [0.4, 1.0, 1.5]         ## cordura que drena la presencia de los enemigos
const MELEE_SPEED := [1.0, 1.18, 1.32]  ## velocidad de los de cuerpo a cuerpo
const HEALTH := [1.0, 1.0, 1.2]         ## vida de los enemigos

static var forced := -1                 ## los tests la fijan (sus topes no dependen del ajuste guardado)
static var net := -1                    ## en red, invitado: la del anfitrión (la pone NetGame; la partida la borra al empezar)

static func level() -> int:
	if forced >= 0: return forced
	if net >= 0: return net
	if Engine.get_main_loop() == null or not (Engine.get_main_loop() as SceneTree).root.has_node("Settings"): return 1
	return clampi(int(Auto.setting("difficulty", 1)), 0, NAMES.size() - 1)

static func rate(t := INF) -> float: return _o("rate", RATE[level()]) * ramp(t)
static func cap(t := INF) -> float: return _o("cap", CAP[level()]) * lerpf(ramp(t), 1.0, 0.5)

## Rampa al empezar cada nivel (15-10-2026, simulaciones con tools/simular.py): el ritmo de la
## dificultad empieza en RAMP_START de su valor y llega al completo a los RAMP_TIME s. Sin ella, en
## Normal salían 2,5 enemigos por segundo desde el segundo 0 y el bot caía a los 30-60 s con un
## arma a nivel 1; la presión de después del minuto 2 no cambia.
const RAMP_START := [1.0, 0.4, 0.5]
const RAMP_TIME := 120.0
## Solo al empezar desde cero (game._apply_carry): llegando con el progreso del nivel anterior, la
## rampa hacía fáciles los niveles 2 a 5 (el bot que pasaba el 1 pasaba la parte entera).
static var ramp_on := true
static func ramp(t: float) -> float:
	if not ramp_on: return 1.0
	var s := _o("ramp", RAMP_START[level()])
	return lerpf(s, 1.0, clampf(t / RAMP_TIME, 0.0, 1.0))
static func melee_speed() -> float: return _o("melee", MELEE_SPEED[level()])
static func health() -> float: return _o("health", HEALTH[level()])
static func damage() -> float: return _o("damage", DAMAGE[level()])
static func mental() -> float: return _o("mental", MENTAL[level()])
static func horror() -> float: return _o("horror", HORROR[level()])

## Simulaciones (tools/simular.py --extra "dif_rate=4"): cambiar un valor sin tocar la tabla.
static var _over = null
static func _o(key: String, v: float) -> float:
	if _over == null:
		_over = {}
		for a in OS.get_cmdline_user_args():
			if a.begins_with("dif_") and "=" in a: _over[a.substr(4, a.find("=") - 4)] = float(a.substr(a.find("=") + 1))
	return float(_over.get(key, v))
