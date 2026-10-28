class_name HitStop
## Micro-pausa al impactar (hito 11.1, 27-10-2026): el juego casi se para unos milisegundos de
## tiempo real en los golpes que importan (muertes de élites y únicos, golpes fuertes a ellos y
## al jugador), para que pesen. Solo con una partida en marcha (`enabled`, lo pone Game) y nunca
## en red (cada PC iría a su ritmo), con el juego acelerado o a cámara lenta (simulaciones, la
## caída), en pausa ni con la opción de pruebas `hitstop=false`.

const SCALE := 0.03                        ## ritmo durante la pausa (casi parado)
const GAP_MS := 250                        ## entre dos pausas pequeñas (las grandes se saltan esto)
static var enabled := false
static var count := 0                      ## pausas hechas (tests y registro)
static var _end_ms := 0
static var _last_ms := -100000
static var _base := 1.0

## Pausa de `ms` milisegundos de tiempo real; `big` (muertes de élites) no espera al hueco.
static func hit(ms: int, big := false) -> void:
	if not enabled or GameSession.online: return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.paused: return
	var now := Time.get_ticks_msec()
	var active := now < _end_ms and Engine.time_scale == SCALE
	if not active:
		if Engine.time_scale != 1.0: return          # acelerado, cámara lenta o depuración
		if not big and now - _last_ms < GAP_MS: return
		_base = Engine.time_scale
	_last_ms = now
	_end_ms = maxi(_end_ms, now + ms)
	count += 1
	Engine.time_scale = SCALE
	if not active: _arm(tree)

static func _arm(tree: SceneTree) -> void:
	var left := maxi(_end_ms - Time.get_ticks_msec(), 1) / 1000.0
	tree.create_timer(left, true, false, true).timeout.connect(func() -> void:
		if Time.get_ticks_msec() < _end_ms - 1: _arm(tree)          # se alargó mientras tanto
		elif Engine.time_scale == SCALE: Engine.time_scale = _base) # nadie lo cambió: se devuelve

## Al salir de la partida: que no se quede el juego parado.
static func stop() -> void:
	if Engine.time_scale == SCALE: Engine.time_scale = _base
	_end_ms = 0
	enabled = false
