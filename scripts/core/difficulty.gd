class_name Difficulty
extends RefCounted
## Dificultad (10-10-2026, Configuración > Juego). "Investigador" es la de antes de este
## cambio; "Normal" busca más agobio: más enemigos a la vez, que llegan antes, y los de
## cuerpo a cuerpo más rápidos. Se aplica en WaveDirector (ritmo, tope y vida) y en Enemy
## (velocidad de los que no disparan). Para probar sin guardarlo: cfg_difficulty=N.
## 12-10-2026 (el autor la vio "muy muy fácil"): más enemigos aún, daño recibido mayor (el
## mental más) y presencia: los enemigos cercanos drenan cordura (Player._presence_step).

const NAMES: Array[String] = ["Investigador", "Normal", "Pesadilla"]
const RATE := [1.0, 8.5, 12.6]          ## ritmo de aparición (12-10-2026: ×3, ×1,5 y luego −10 %, "un pelín difícil")
const CAP := [1.0, 2.9, 3.2]            ## enemigos vivos a la vez (ver WaveDirector.HARD_CAP)
const DAMAGE := [1.0, 1.4, 1.8]         ## daño físico que reciben los jugadores
const MENTAL := [1.0, 1.7, 2.2]         ## daño mental que reciben los jugadores
const HORROR := [0.4, 1.0, 1.5]         ## cordura que drena la presencia de los enemigos
const MELEE_SPEED := [1.0, 1.18, 1.32]  ## velocidad de los de cuerpo a cuerpo
const HEALTH := [1.0, 1.0, 1.2]         ## vida de los enemigos

static var forced := -1                 ## los tests la fijan (sus topes no dependen del ajuste guardado)

static func level() -> int:
	if forced >= 0: return forced
	if Engine.get_main_loop() == null or not (Engine.get_main_loop() as SceneTree).root.has_node("Settings"): return 1
	return clampi(int(Settings.get_value("difficulty")), 0, NAMES.size() - 1)

static func rate() -> float: return RATE[level()]
static func cap() -> float: return CAP[level()]
static func melee_speed() -> float: return MELEE_SPEED[level()]
static func health() -> float: return HEALTH[level()]
static func damage() -> float: return DAMAGE[level()]
static func mental() -> float: return MENTAL[level()]
static func horror() -> float: return HORROR[level()]
