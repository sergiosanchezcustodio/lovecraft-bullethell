class_name Difficulty
extends RefCounted
## Dificultad (10-10-2026, Configuración > Juego). "Investigador" es la de antes de este
## cambio; "Normal" busca más agobio: más enemigos a la vez, que llegan antes, y los de
## cuerpo a cuerpo más rápidos. Se aplica en WaveDirector (ritmo, tope y vida) y en Enemy
## (velocidad de los que no disparan). Para probar sin guardarlo: cfg_difficulty=N.

const NAMES: Array[String] = ["Investigador", "Normal", "Pesadilla"]
const RATE := [1.0, 1.5, 2.0]           ## ritmo de aparición
const CAP := [1.0, 1.45, 1.9]           ## enemigos vivos a la vez
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
