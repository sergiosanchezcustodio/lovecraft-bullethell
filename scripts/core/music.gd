extends Node
## Música de fondo (autoload `Music`): sobrevive a los cambios de escena y pasa de una pista
## a otra con un fundido cruzado. Si se pide la pista que ya suena, sigue sin cortarse (al
## reiniciar la partida, por ejemplo). Las pistas se repiten en bucle.
## `mute=true` (o `--mute`) detrás de `--` la silencia (bots, capturas).
## Capas (hito 13.13): cada pista puede llevar una de percusión y otra de coros (`capas` en
## data/musica.json, de tools/gen_capas_musica.py), en bucle aparte y en silencio hasta que la
## partida pide más intensidad (`set_intensity`); con «Música que crece con el combate» quitada,
## no suenan.

const VOLUME_DB := -4.0
const SILENT_DB := -60.0

var _players: Array[AudioStreamPlayer] = []
var _current := 0                          ## índice del reproductor que suena
var _path := ""
var _tweens: Array[Tween] = [null, null]
var _muted := false
const LAYERS := ["percusion", "coros"]
const LAYER_DB := {"percusion": -5.0, "coros": -7.0}   ## a tope; las capas están a -24 dB RMS
const LAYER_UP := 0.35                     ## volumen lineal por segundo al subir
const LAYER_DOWN := 0.2                    ## y al bajar
var _layer_cfg := {}                       ## pista -> {percusion, coros}
var _layer := {}                           ## capa -> AudioStreamPlayer que suena
var _layer_target := {"percusion": 0.0, "coros": 0.0}
var _layer_level := {"percusion": 0.0, "coros": 0.0}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS          # sigue sonando en pausa
	_muted = LaunchArgs.from_cmdline().get_bool("mute")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = SILENT_DB
		add_child(p)
		_players.append(p)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/musica.json"))
	if d is Dictionary: _layer_cfg = (d as Dictionary).get("capas", {})

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
	_swap_layers(path, fade)

## [percusión, coros] de 0 a 1 para una partida: la percusión entra con un tercio del tope de
## vivos y los coros cuando está casi lleno; con un jefe (o minijefe) vivo, solo los coros.
func intensity_for(alive: int, cap: int, boss: bool) -> Vector2:
	if boss: return Vector2(0.0, 1.0)
	var k := float(alive) / maxf(cap * 0.7, 6.0)
	return Vector2(smoothstep(0.2, 0.7, k), smoothstep(0.65, 1.0, k))

## Intensidad de las capas (0..1 cada una): la pide la partida según los enemigos vivos y el jefe.
func set_intensity(percusion: float, coros: float) -> void:
	_layer_target["percusion"] = clampf(percusion, 0.0, 1.0)
	_layer_target["coros"] = clampf(coros, 0.0, 1.0)

func layer_level(kind: String) -> float:
	return float(_layer_level.get(kind, 0.0))

## Cambia las capas a las de la pista nueva: las de antes se funden y las nuevas empiezan en
## silencio (suben con la intensidad). Si es la misma capa, sigue sonando.
func _swap_layers(path: String, fade: float) -> void:
	var cfg: Dictionary = _layer_cfg.get(path, {})
	for kind: String in LAYERS:
		var want := String(cfg.get(kind, ""))
		var old: AudioStreamPlayer = _layer.get(kind)
		if old != null and old.stream != null and old.stream.resource_path == want: continue
		if old != null:
			var tw := create_tween()
			tw.tween_property(old, "volume_db", SILENT_DB, maxf(fade, 0.3))
			tw.tween_callback(old.queue_free)
		_layer.erase(kind)
		_layer_level[kind] = 0.0
		if want == "" or not ResourceLoader.exists(want): continue
		var stream := load(want) as AudioStream
		if "loop" in stream: stream.set("loop", true)
		var p := AudioStreamPlayer.new()
		p.bus = Settings.BUS_MUSIC
		p.stream = stream
		p.volume_db = SILENT_DB
		add_child(p)
		p.play()
		_layer[kind] = p

func _process(delta: float) -> void:
	var on := bool(Auto.setting("music_layers", true)) and not _muted and _path != ""
	for kind: String in LAYERS:
		var want: float = _layer_target[kind] if on else 0.0
		var lv: float = _layer_level[kind]
		lv = move_toward(lv, want, delta * (LAYER_UP if want > lv else LAYER_DOWN))
		_layer_level[kind] = lv
		var p: AudioStreamPlayer = _layer.get(kind)
		if p != null: p.volume_db = SILENT_DB if lv < 0.002 else linear_to_db(lv) + float(LAYER_DB[kind])

## Funde y para la música.
func stop(fade := 1.0) -> void:
	_path = ""
	_fade_to(_current, SILENT_DB, fade, true)
	_swap_layers("", fade)
	set_intensity(0.0, 0.0)

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
	for kind: String in _layer:
		(_layer[kind] as AudioStreamPlayer).stop()
		(_layer[kind] as AudioStreamPlayer).stream = null
	_layer.clear()
