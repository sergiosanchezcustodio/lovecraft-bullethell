extends Node
## Efectos de sonido (hito 8.1), autoload `Sfx`. Lo que suena en cada evento está en
## data/sfx.json: {evento: {files: [...], db, pitch: [min, max], voices, gap}}. Los archivos van
## en resources/sfx/ (tools/gen_sfx.py: sintetizados y CC0 de Kenney).
## - `Sfx.play(evento)`: suena una de sus variaciones al azar, con algo de tono al azar.
## - Límite de voces por evento (`voices`) y separación mínima entre dos del mismo (`gap`, s):
##   con 150 enemigos no se apilan cientos de impactos.
## - Bus "Efectos" (Settings), o el de la tabla (`bus`: "Ambiente" para el sonido de los
##   escenarios, con su volumen propio). `mute=true` silencia también los efectos.
## - Los botones de los menús suenan solos al recibir el foco y al pulsarse (node_added).
## - `Sfx.play_at(evento, posición)` (16-10-2026): suena a la izquierda o a la derecha según
##   dónde está en pantalla (AudioStreamPlayer3D sin atenuación; el oído lo lleva GameCamera).

## - Grupos (12-10-2026): las armas disparan sin parar, varias a la vez y con varios jugadores.
##   Los eventos de un grupo comparten un tope de voces y cada voz baja `duck` dB por cada otra
##   que ya suena del grupo, así la mezcla no crece con las armas ni con los jugadores. Las del
##   grupo "armas" y "golpes" siguen además el volumen de armas de la configuración (`vol_weapons`).

## Cada evento que se pide, suene o no (silenciado incluido): el ambiente reacciona a los ruidos
## fuertes (murciélagos que se espantan). `pos` es null si no tiene sitio.
signal played(ev: String, pos: Variant)

const POOL := 24
const POOL_3D := 16
const GROUPS := {"armas": {"voices": 4, "duck": 2.5}, "golpes": {"voices": 5, "duck": 2.0}}
var _defs := {}
var _streams := {}                         ## evento -> Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _players_3d: Array[AudioStreamPlayer3D] = []
var _next_3d := 0
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
	for i in POOL_3D:
		var q := AudioStreamPlayer3D.new()
		q.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED   # solo el lado: el volumen, el de la tabla
		q.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		q.max_db = 6.0
		add_child(q)
		_players_3d.append(q)
	get_tree().node_added.connect(_on_node_added)

func has_event(ev: String) -> bool:
	return _streams.has(ev) and not (_streams[ev] as Array).is_empty()

## Suena `ev`. vol_db se suma al de la tabla.
func play(ev: String, vol_db := 0.0) -> void:
	_play(ev, vol_db, null)

## Suena `ev` en `pos` (en el mundo): a la izquierda o a la derecha según dónde se ve.
func play_at(ev: String, pos: Vector3, vol_db := 0.0) -> void:
	_play(ev, vol_db, pos)

func _play(ev: String, vol_db: float, pos: Variant) -> void:
	played.emit(ev, pos)
	if muted or not has_event(ev): return
	var def: Dictionary = _defs[ev]
	var now := Time.get_ticks_msec()
	if now - int(_last.get(ev, -100000)) < int(float(def.get("gap", 0.03)) * 1000.0): return
	var voices: Array = _playing.get(ev, [])
	voices = voices.filter(func(p: Node) -> bool: return p.get("playing") and p.get_meta("ev", "") == ev)
	if voices.size() >= int(def.get("voices", 4)): return
	var group: String = def.get("group", "")
	var busy := 0
	if group != "":
		for q in _players:
			if q.playing and q.get_meta("group", "") == group: busy += 1
		for q in _players_3d:
			if q.playing and q.get_meta("group", "") == group: busy += 1
		if busy >= int(GROUPS[group].voices): return
		vol_db += -float(GROUPS[group].duck) * busy + _weapons_db()
	_last[ev] = now
	var p = _free_player() if pos == null else _free_player_3d()           # 2D o 3D: mismas propiedades
	if pos != null: (p as AudioStreamPlayer3D).global_position = pos
	var list: Array = _streams[ev]
	p.stream = list[randi() % list.size()]
	p.volume_db = float(def.get("db", 0.0)) + vol_db
	var pr: Array = def.get("pitch", [0.95, 1.05])
	p.pitch_scale = randf_range(float(pr[0]), float(pr[1]))
	var bus := String(def.get("bus", "Efectos"))
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	p.set_meta("ev", ev)
	p.set_meta("group", group)
	p.call("play")
	counts[ev] = int(counts.get(ev, 0)) + 1
	voices.append(p)
	_playing[ev] = voices

## dB del volumen de las armas de la configuración (0 = silencio).
func _weapons_db() -> float:
	var v := float(Settings.get_value("vol_weapons")) if Settings.has_method("get_value") else 0.7
	return -80.0 if v <= 0.01 else linear_to_db(v)

func _free_player() -> AudioStreamPlayer:
	for k in POOL:
		var p := _players[(_next + k) % POOL]
		if not p.playing:
			_next = (_next + k + 1) % POOL
			return p
	var p := _players[_next]                       # todas ocupadas: la más antigua
	_next = (_next + 1) % POOL
	return p

func _free_player_3d() -> AudioStreamPlayer3D:
	for k in POOL_3D:
		var p := _players_3d[(_next_3d + k) % POOL_3D]
		if not p.playing:
			_next_3d = (_next_3d + k + 1) % POOL_3D
			return p
	var p := _players_3d[_next_3d]
	_next_3d = (_next_3d + 1) % POOL_3D
	return p

func _exit_tree() -> void:
	if OS.get_cmdline_user_args().has("log=true") and not counts.is_empty(): print("SONIDOS ", counts)

func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		var b := n as BaseButton
		b.focus_entered.connect(func() -> void: play("ui_move"))
		b.pressed.connect(func() -> void: play("ui_accept"))
