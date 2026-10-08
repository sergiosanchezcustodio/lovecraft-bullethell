extends Node
## Efectos de sonido (hito 8.1), autoload `Sfx`. Lo que suena en cada evento está en
## data/sfx.json: {evento: {files: [...], db, pitch: [min, max], voices, gap}}. Los archivos van
## en resources/sfx/ (tools/gen_sfx.py: sintetizados y CC0 de Kenney).
## - `Sfx.play(evento)`: suena una de sus variaciones al azar, con algo de tono al azar.
## - Límite de voces por evento (`voices`) y separación mínima entre dos del mismo (`gap`, s):
##   con 150 enemigos no se apilan cientos de impactos.
## - Bus "Efectos" (Settings). `mute=true` silencia también los efectos.
## - Los botones de los menús suenan solos al recibir el foco y al pulsarse (node_added).

const POOL := 24
var _defs := {}
var _streams := {}                         ## evento -> Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _playing := {}                         ## evento -> Array[AudioStreamPlayer] (sus voces)
var _last := {}                            ## evento -> ms del último
var muted := false
var counts := {}                           ## evento -> veces que ha sonado (log=true lo imprime al salir)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	muted = OS.get_cmdline_user_args().has("mute=true")
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
	if d is Dictionary: _defs = d.get("eventos", {})
	for ev in _defs:
		var list: Array[AudioStream] = []
		for f in _defs[ev].get("files", []):
			var path := "res://resources/sfx/%s" % f
			if ResourceLoader.exists(path): list.append(load(path))
		_streams[ev] = list
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Efectos" if AudioServer.get_bus_index("Efectos") >= 0 else "Master"
		add_child(p)
		_players.append(p)
	get_tree().node_added.connect(_on_node_added)

func has_event(ev: String) -> bool:
	return _streams.has(ev) and not (_streams[ev] as Array).is_empty()

## Suena `ev`. vol_db se suma al de la tabla.
func play(ev: String, vol_db := 0.0) -> void:
	if muted or not has_event(ev): return
	var def: Dictionary = _defs[ev]
	var now := Time.get_ticks_msec()
	if now - int(_last.get(ev, -100000)) < int(float(def.get("gap", 0.03)) * 1000.0): return
	var voices: Array = _playing.get(ev, [])
	voices = voices.filter(func(p: AudioStreamPlayer) -> bool: return p.playing and p.get_meta("ev", "") == ev)
	if voices.size() >= int(def.get("voices", 4)): return
	_last[ev] = now
	var p := _free_player()
	var list: Array = _streams[ev]
	p.stream = list[randi() % list.size()]
	p.volume_db = float(def.get("db", 0.0)) + vol_db
	var pr: Array = def.get("pitch", [0.95, 1.05])
	p.pitch_scale = randf_range(float(pr[0]), float(pr[1]))
	p.set_meta("ev", ev)
	p.play()
	counts[ev] = int(counts.get(ev, 0)) + 1
	voices.append(p)
	_playing[ev] = voices

func _free_player() -> AudioStreamPlayer:
	for k in POOL:
		var p := _players[(_next + k) % POOL]
		if not p.playing:
			_next = (_next + k + 1) % POOL
			return p
	var p := _players[_next]                       # todas ocupadas: la más antigua
	_next = (_next + 1) % POOL
	return p

func _exit_tree() -> void:
	if OS.get_cmdline_user_args().has("log=true") and not counts.is_empty(): print("SONIDOS ", counts)

func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		var b := n as BaseButton
		b.focus_entered.connect(func() -> void: play("ui_move"))
		b.pressed.connect(func() -> void: play("ui_accept"))
