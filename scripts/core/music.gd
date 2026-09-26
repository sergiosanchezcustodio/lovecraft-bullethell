extends Node
## Música de fondo (autoload `Music`): sobrevive a los cambios de escena y pasa de una pista
## a otra con un fundido cruzado. Si se pide la pista que ya suena, sigue sin cortarse (al
## reiniciar la partida, por ejemplo). Las pistas se repiten en bucle.
## `mute=true` (o `--mute`) detrás de `--` la silencia (bots, capturas).

const VOLUME_DB := -4.0
const SILENT_DB := -60.0

var _players: Array[AudioStreamPlayer] = []
var _current := 0                          ## índice del reproductor que suena
var _path := ""
var _tweens: Array[Tween] = [null, null]
var _muted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS          # sigue sonando en pausa
	_muted = LaunchArgs.from_cmdline().get_bool("mute")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = SILENT_DB
		add_child(p)
		_players.append(p)

## Pone la pista de `path` con un fundido de `fade` s (la anterior se funde a la vez).
func play(path: String, fade := 1.5) -> void:
	if _muted or path == "": return
	if path == _path and _players[_current].playing: return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("Música no encontrada: " + path)
		return
	if "loop" in stream: stream.set("loop", true)
	_fade_to(_current, SILENT_DB, fade, true)        # la que sonaba
	_current = 1 - _current
	var p := _players[_current]
	p.bus = Settings.BUS_MUSIC                        # su volumen, en la configuración
	p.stream = stream
	p.volume_db = SILENT_DB
	p.play()
	_fade_to(_current, VOLUME_DB, fade, false)
	_path = path

## Funde y para la música.
func stop(fade := 1.0) -> void:
	_path = ""
	_fade_to(_current, SILENT_DB, fade, true)

func current() -> String:
	return _path

func is_muted() -> bool:
	return _muted

## Silencia o vuelve a poner la música (menú de depuración). Recuerda la pista que sonaba.
var _muted_path := ""
func set_muted(on: bool) -> void:
	if on == _muted: return
	if on:
		_muted_path = _path
		stop(0.3)
		_muted = true
	else:
		_muted = false
		play(_muted_path, 0.5)

func _fade_to(i: int, db: float, time: float, stop_after: bool) -> void:
	var p := _players[i]
	if _tweens[i]: _tweens[i].kill()
	if not p.playing: return
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	# en dB la subida sería brusca al principio: se funde en volumen lineal
	tw.tween_method(func(v: float) -> void: p.volume_db = linear_to_db(maxf(v, 0.001)),
		db_to_linear(p.volume_db), db_to_linear(db), maxf(time, 0.01))
	if stop_after: tw.tween_callback(p.stop)
	_tweens[i] = tw

## Al cerrar el juego, suelta las pistas (si no, Godot avisa de recursos sin liberar).
func _exit_tree() -> void:
	for i in 2:
		if _tweens[i]: _tweens[i].kill()
		_tweens[i] = null
		_players[i].stop()
		_players[i].stream = null
