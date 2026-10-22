class_name NetGame
extends Node
## Partida en red (hito 9.3a, D-10). Cada PC manda en sus jugadores y el anfitrión, en el mundo.
##
## - Los invitados juegan una partida espejo: la misma escena, sin director de oleadas ni
##   enemigos que piensen. Mandan el estado de sus jugadores 30 veces por segundo (PSTATE).
## - El anfitrión simula el mundo con los jugadores de los demás PC como "remotos" (se mueven con
##   lo que llega y no reciben daño aquí) y manda 20 fotos por segundo (SNAP) con todos los
##   jugadores y los enemigos. Las apariciones y muertes van aparte y fiables (SPAWN, DIE).
## - Lo que llega se dibuja `NetInterp.DELAY_MS` en el pasado, interpolando entre dos fotos.
## - El evento final, los minijefes, el jefe, el fin del nivel y la derrota los decide el
##   anfitrión (EVENT). El siguiente nivel y el reintento, también (NEXT, RESTART).
## - Al empezar, todos esperan a todos: los invitados avisan (READY, repetido hasta que llega
##   GO) y el anfitrión arranca cuando han avisado todos los de la sala.
##
## Formato de las fotos (bytes): ver `write_player` y `write_enemy`.

const READY := NetSession.USER + 10          ## invitado -> anfitrión: partida montada
const GO := NetSession.USER + 11             ## anfitrión -> invitado: empieza
const PSTATE := NetSession.USER + 12         ## invitado -> anfitrión: [ms, jugadores] (no fiable)
const SNAP := NetSession.USER + 13           ## anfitrión -> invitados: foto del mundo (no fiable)
const SPAWN := NetSession.USER + 14          ## anfitrión -> invitados: [nid, enemigo, x, y, z]
const DIE := NetSession.USER + 15            ## anfitrión -> invitados: nid
const ANIM := NetSession.USER + 16           ## anfitrión -> invitados: [índice, nombre de animación]
const EVENT := NetSession.USER + 17          ## anfitrión -> invitados: {k: final|mid|boss|won|lost, id, text}
const NEXT := NetSession.USER + 18           ## anfitrión -> invitados: {level, carry, team_xp, team_turn}
const RESTART := NetSession.USER + 19        ## anfitrión -> invitados: reintentar el nivel

const SNAP_EVERY := 3                        ## pasos de física entre fotos del anfitrión (20 Hz)
const PSTATE_EVERY := 2                      ## y entre estados de un invitado (30 Hz)
const READY_EVERY := 0.5                     ## s entre avisos de READY
const POS_K := 100.0                         ## posiciones y velocidades en cm (int16: ±327 m)
const STAT_K := 10.0                         ## vida y cordura en décimas (uint16)

var game: Node                               ## la partida (game.gd)
var net: NetSession
var host := false
var started := false
var bytes_out := 0                           ## bytes de fotos y estados mandados (medir el ancho de banda)
var pause_tree := true                       ## pausa la partida mientras espera a los demás (los tests no)
var _ready_peers := {}                       ## anfitrión: PC -> true cuando ha avisado
var _interp: NetInterp                       ## invitado: lo que llega del anfitrión
var _peer_interp := {}                       ## anfitrión: PC -> NetInterp
var _enemies := {}                           ## nid -> Enemy (en el invitado, marionetas)
var _next_nid := 1
var _anim_ids := {}                          ## anfitrión: nombre de animación -> índice
var _anim_names := {}                        ## invitado: índice -> nombre
var _tick := 0
var _ready_t := 0.0
var _overlay: CanvasLayer
var _enemies_root: Node3D

func _init(p_game: Node, p_net: NetSession) -> void:
	game = p_game
	net = p_net
	host = net.is_host()
	name = "NetGame"
	process_mode = Node.PROCESS_MODE_ALWAYS          # sigue mandando y recibiendo con la partida en pausa
	process_physics_priority = -20                   # antes que la rejilla del combate y los jugadores

func _ready() -> void:
	net.message.connect(_on_message)
	net.roster_changed.connect(_on_roster)
	net.closed.connect(_on_closed)
	if host:
		var d: WaveDirector = game.director
		if d != null:
			d.enemy_spawned.connect(_on_spawned)
			d.final_event.connect(func(e: Enemy) -> void: _event({"k": "final", "id": _nid(e)}))
			d.mid_event.connect(func(e: Enemy, text: String) -> void: _event({"k": "mid", "id": _nid(e), "text": text}))
			d.boss_event.connect(func(e: Enemy, text: String) -> void: _event({"k": "boss", "id": _nid(e), "text": text}))
			d.level_completed.connect(func() -> void: _event({"k": "won"}))
	else:
		_interp = NetInterp.new()
		_enemies_root = game.get_node_or_null("Enemies")
	_wait_overlay("Esperando a los demás jugadores…" if host else "Esperando al anfitrión…")
	if pause_tree: get_tree().paused = true
	if host: _check_all_ready()
	else: _send_ready()

## Lo que el anfitrión puede haber cambiado del nivel (pruebas: final_at, mid_at) y el HUD enseña.
func _timing() -> Dictionary:
	var lv: LevelData = game.director.level if game.director != null else null
	if lv == null: return {}
	return {"final_time": lv.final_time, "mid_times": Array(lv.mid_times)}

## ¿Es de este PC el jugador?
func is_mine(q: Player) -> bool:
	return not q.remote

# ---------------------------------------------------------------- arranque

func _send_ready() -> void:
	_ready_t = READY_EVERY
	net.send(1, READY, true)

func _check_all_ready() -> void:
	if started: return
	for id in net.peers:
		if id != 1 and not _ready_peers.has(id): return
	_go()

func _go() -> void:
	started = true
	if host:
		for id in net.peers:
			if id != 1: net.send(id, GO, _timing())
	if pause_tree: get_tree().paused = false
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null

func _wait_overlay(text: String) -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 40
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)
	var l := UiKit.label(text, 30, UiKit.TEXT)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	_overlay.add_child(l)
	add_child(_overlay)

# ---------------------------------------------------------------- bucle

func _process(delta: float) -> void:
	if not host and not started:
		_ready_t -= delta
		if _ready_t <= 0.0: _send_ready()
	if started and not get_tree().paused and game.args.get_bool("log"): _log(delta)

## Registro (log=true): cada 5 s, lo que ve este PC, para comparar las dos ventanas.
var _log_t := 0.0
var _log_bytes := 0
func _log(delta: float) -> void:
	_log_t += delta
	if _log_t < 5.0: return
	var pos := PackedStringArray()
	for q: Player in game.players:
		pos.append("J%d%s(%.1f,%.1f) v%d" % [q.index + 1, "r" if q.remote else "", q.global_position.x, q.global_position.z, roundi(q.health)])
	var n := 0
	for nid in _enemies: if is_instance_valid(_enemies[nid]): n += 1
	print("RED %s t=%.1f enemigos=%d abatidos=%d %s  sale=%.1f kB/s  ping=%d" % ["anfitrion" if host else "invitado",
		game.director.time if game.director != null else 0.0, n, game.kills, " ".join(pos),
		(bytes_out - _log_bytes) / _log_t / 1024.0, int(net.peers.get(net.my_id, {}).get("ping", 0)) if not host else 0])
	_log_bytes = bytes_out
	_log_t = 0.0

func _physics_process(_delta: float) -> void:
	_tick += 1
	var now := float(Time.get_ticks_msec())
	if host:
		if started and _tick % SNAP_EVERY == 0: _send_snap()
		for peer in _peer_interp:
			var ip: NetInterp = _peer_interp[peer]
			var t := ip.render_ms(now)
			for q: Player in game.players:
				if q.remote and _peer_of(q) == peer: _apply_player(q, ip.sample(q.index, t))
	else:
		if started and _tick % PSTATE_EVERY == 0: _send_pstate()
		var t := _interp.render_ms(now)
		for q: Player in game.players:
			if q.remote: _apply_player(q, _interp.sample("p%d" % q.index, t))
		for nid in _enemies:
			var e: Enemy = _enemies[nid]
			if is_instance_valid(e): _apply_enemy(e, _interp.sample(nid, t))
		var h := _interp.sample("h", t)
		if not h.is_empty() and game.director != null:
			game.director.time = lerpf(float(h[0][0]), float(h[1][0]), float(h[2]))
			game.kills = int(h[1][1])
		if _tick % 60 == 0: _interp.prune(now + _interp.offset)

func _peer_of(q: Player) -> int:
	return GameSession.seats[q.index].peer if q.index < GameSession.seats.size() else 1

# ---------------------------------------------------------------- fotos

## Jugador (16 bytes): índice, x, z, rumbo, vx, vz, esquives, vida, cordura, estado.
static func write_player(s: StreamPeerBuffer, q: Player) -> void:
	s.put_u8(q.index)
	s.put_16(_cm(q.global_position.x))
	s.put_16(_cm(q.global_position.z))
	s.put_u8(_angle8(atan2(q.motor.facing.x, q.motor.facing.z)))
	s.put_16(_cm(q.motor.velocity.x))
	s.put_16(_cm(q.motor.velocity.z))
	s.put_u8(q.dodge_count & 255)
	s.put_u16(clampi(roundi(q.health * STAT_K), 0, 65535))
	s.put_u16(clampi(roundi(q.sanity * STAT_K), 0, 65535))
	s.put_u8(q.net_flags())

## [índice, valores]: valores = [x, z, rumbo, vx, vz, esquives, vida, cordura, estado].
static func read_player(s: StreamPeerBuffer) -> Array:
	var i := s.get_u8()
	return [i, [s.get_16() / POS_K, s.get_16() / POS_K, s.get_u8() / 256.0 * TAU, s.get_16() / POS_K, s.get_16() / POS_K,
		s.get_u8(), s.get_u16() / STAT_K, s.get_u16() / STAT_K, s.get_u8()]]

## Enemigo (13 bytes): nid, x, y, z, rumbo, animación, fase, vida (fracción), estado.
static func write_enemy(s: StreamPeerBuffer, nid: int, e: Enemy, anim_id: int) -> void:
	s.put_u16(nid)
	s.put_16(_cm(e.position.x))
	s.put_16(_cm(e.position.y))
	s.put_16(_cm(e.position.z))
	s.put_u8(_angle8(atan2(e.facing.x, e.facing.z)))
	s.put_u8(anim_id)
	s.put_u8(int(fposmod(e.anim_t, 1.0) * 256.0) & 255)
	s.put_u8(clampi(ceili(e.health / maxf(e.data.max_health * e.health_scale, 0.001) * 255.0), 0, 255))
	s.put_u8(e.net_flags())

## [nid, valores]: valores = [x, y, z, rumbo, animación, fase, vida 0..1, estado].
static func read_enemy(s: StreamPeerBuffer) -> Array:
	var nid := s.get_u16()
	return [nid, [s.get_16() / POS_K, s.get_16() / POS_K, s.get_16() / POS_K, s.get_u8() / 256.0 * TAU,
		s.get_u8(), s.get_u8() / 256.0, s.get_u8() / 255.0, s.get_u8()]]

static func _cm(v: float) -> int:
	return clampi(roundi(v * POS_K), -32768, 32767)

static func _angle8(a: float) -> int:
	return int(roundf(fposmod(a, TAU) / TAU * 256.0)) & 255

func _send_snap() -> void:
	var s := StreamPeerBuffer.new()
	s.put_u32(Time.get_ticks_msec())
	s.put_float(game.director.time if game.director != null else 0.0)
	s.put_u16(clampi(game.kills, 0, 65535))
	s.put_u8(game.players.size())
	for q: Player in game.players: write_player(s, q)
	var live := []
	for nid in _enemies:
		var e: Enemy = _enemies[nid]
		if is_instance_valid(e) and e.is_alive(): live.append(nid)
	s.put_u16(live.size())
	for nid: int in live:
		var e: Enemy = _enemies[nid]
		write_enemy(s, nid, e, _anim_id(e.anim))
	for id in net.peers:
		if id != 1 and _ready_peers.has(id):
			net.send(id, SNAP, s.data_array, false)
			bytes_out += s.data_array.size()

func _send_pstate() -> void:
	var s := StreamPeerBuffer.new()
	s.put_u32(Time.get_ticks_msec())
	var mine: Array[Player] = []
	for q: Player in game.players:
		if not q.remote: mine.append(q)
	s.put_u8(mine.size())
	for q in mine: write_player(s, q)
	net.send(1, PSTATE, s.data_array, false)
	bytes_out += s.data_array.size()

func _anim_id(anim: String) -> int:
	if not _anim_ids.has(anim):
		var i := _anim_ids.size() % 256
		_anim_ids[anim] = i
		net.send(0, ANIM, [i, anim])
	return int(_anim_ids[anim])

## Aplica una muestra ([antes, después, peso]) a un jugador remoto.
func _apply_player(q: Player, smp: Array) -> void:
	if smp.is_empty(): return
	var a: Array = smp[0]
	var b: Array = smp[1]
	var w: float = smp[2]
	var pos := Vector3(lerpf(a[0], b[0], w), 0.0, lerpf(a[1], b[1], w))
	var vel := Vector3(lerpf(a[3], b[3], w), 0.0, lerpf(a[4], b[4], w))
	q.net_apply(pos, lerp_angle(a[2], b[2], w), vel, int(b[5]), float(b[6]), float(b[7]), int(b[8]))

func _apply_enemy(e: Enemy, smp: Array) -> void:
	if smp.is_empty(): return
	var a: Array = smp[0]
	var b: Array = smp[1]
	var w: float = smp[2]
	e.position = Vector3(lerpf(a[0], b[0], w), lerpf(a[1], b[1], w), lerpf(a[2], b[2], w))
	var yaw := lerp_angle(a[3], b[3], w)
	e.facing = Vector3(sin(yaw), 0.0, cos(yaw))
	var name_b: String = _anim_names.get(int(b[4]), e.anim)
	if a[4] == b[4]:                                 # la fase avanza hacia delante, dando la vuelta en 1
		e.anim = name_b
		e.anim_t = fposmod(float(a[5]) + fposmod(float(b[5]) - float(a[5]), 1.0) * w, 1.0)
	else:
		e.anim = name_b
		e.anim_t = float(b[5])
	e.health = maxf(float(b[6]) * e.data.max_health * e.health_scale, 0.001)
	e.net_apply_flags(int(b[7]))

# ---------------------------------------------------------------- enemigos (anfitrión)

func _on_spawned(e: Enemy) -> void:
	var nid := _next_nid
	_next_nid = _next_nid % 65535 + 1
	_enemies[nid] = e
	e.set_meta("nid", nid)
	e.died.connect(func(_x: Enemy) -> void:
		_enemies.erase(nid)
		net.send(0, DIE, nid))
	var id := e.data.resource_path.get_file().get_basename() if e.data.resource_path != "" else String(e.data.id)
	net.send(0, SPAWN, [nid, id, e.position.x, e.position.y, e.position.z])

func _nid(e: Enemy) -> int:
	return int(e.get_meta("nid", 0)) if e != null and is_instance_valid(e) else 0

func _event(d: Dictionary) -> void:
	net.send(0, EVENT, d)

## Anfitrión: derrota (la decide él, con la vida que le llega de cada PC).
func send_lost() -> void:
	_event({"k": "lost"})

func send_next(level_id: String) -> void:
	net.send(0, NEXT, {"level": level_id, "carry": GameSession.carry.duplicate(true),
		"team_xp": GameSession.team_xp, "team_turn": GameSession.team_turn})

func send_restart() -> void:
	net.send(0, RESTART, true)

# ---------------------------------------------------------------- mensajes

func _on_message(from: int, type: int, data: Variant) -> void:
	if host:
		match type:
			READY:
				_ready_peers[from] = true
				if started: net.send(from, GO, _timing())   # llegó tarde o se perdió el GO
				else: _check_all_ready()
			PSTATE:
				if data is PackedByteArray: _on_pstate(from, data)
		return
	if from != 1: return
	match type:
		GO:
			if started: return
			var lv: LevelData = game.director.level if game.director != null else null
			if data is Dictionary and lv != null:         # los horarios del nivel, como los tiene el anfitrión
				lv.final_time = float(data.get("final_time", lv.final_time))
				var mids: Variant = data.get("mid_times")
				if mids is Array:                            # arreglo nuevo: el del recurso en caché no se toca
					var mt: Array[float] = []
					for x: Variant in mids: mt.append(float(x))
					lv.mid_times = mt
			_go()
		SNAP: if data is PackedByteArray: _on_snap(data)
		SPAWN: if data is Array and (data as Array).size() == 5: _puppet_spawn(data)
		DIE:
			if data is int and _enemies.has(data):
				var e: Enemy = _enemies[data]
				_enemies.erase(data)
				_interp.tracks.erase(data)
				if is_instance_valid(e): e.puppet_die()
		ANIM: if data is Array and (data as Array).size() == 2: _anim_names[int(data[0])] = String(data[1])
		EVENT: if data is Dictionary: _on_event(data)
		NEXT: if data is Dictionary and game.has_method("net_next"): game.net_next(data)
		RESTART: if game.has_method("net_restart"): game.net_restart()

func _on_pstate(from: int, bytes: PackedByteArray) -> void:
	var s := StreamPeerBuffer.new()
	s.data_array = bytes
	if bytes.size() < 5: return
	var t := float(s.get_u32())
	if not _peer_interp.has(from): _peer_interp[from] = NetInterp.new()
	var ip: NetInterp = _peer_interp[from]
	ip.observe(t, Time.get_ticks_msec())
	var n := s.get_u8()
	for k in n:
		if s.get_available_bytes() < 16: return
		var r := read_player(s)
		var i: int = r[0]
		if i < game.players.size() and (game.players[i] as Player).remote and _peer_of(game.players[i]) == from:
			ip.push(i, t, r[1])

func _on_snap(bytes: PackedByteArray) -> void:
	if bytes.size() < 11: return
	var s := StreamPeerBuffer.new()
	s.data_array = bytes
	var t := float(s.get_u32())
	_interp.observe(t, Time.get_ticks_msec())
	var dtime := s.get_float()
	var kills := s.get_u16()
	_interp.push("h", t, [dtime, kills])
	var n := s.get_u8()
	for k in n:
		if s.get_available_bytes() < 16: return
		var r := read_player(s)
		_interp.push("p%d" % int(r[0]), t, r[1])
	if s.get_available_bytes() < 2: return
	var m := s.get_u16()
	for k in m:
		if s.get_available_bytes() < 13: return
		var r := read_enemy(s)
		if _enemies.has(r[0]): _interp.push(r[0], t, r[1])

func _puppet_spawn(d: Array) -> void:
	var path := "res://data/enemies/%s.tres" % String(d[1])
	if not ResourceLoader.exists(path): return
	var e := Enemy.new().setup(load(path), game.world, game.world.obstacles)
	e.puppet = true
	e.position = Vector3(float(d[2]), float(d[3]), float(d[4]))
	var root: Node = _enemies_root if _enemies_root != null else game
	root.add_child(e)
	_enemies[int(d[0])] = e

func _on_event(d: Dictionary) -> void:
	var dir: WaveDirector = game.director
	var e: Enemy = _enemies.get(int(d.get("id", 0)))
	match String(d.get("k", "")):
		"final":
			if dir == null: return
			dir._final_done = true
			dir._final = e
			dir.final_event.emit(e)
		"mid":
			if dir == null or e == null: return
			dir.mid_alive.append(e)
			e.died.connect(func(x: Enemy) -> void: dir.mid_alive.erase(x))
			dir.mid_event.emit(e, String(d.get("text", "")))
		"boss":
			if dir == null or e == null: return
			dir._final = e
			dir._boss_on = true
			dir.boss_event.emit(e, String(d.get("text", "")))
		"won":
			if dir == null or dir.completed: return
			dir.completed = true
			dir.level_completed.emit()
		"lost":
			if game.has_method("net_lost"): game.net_lost()

# ---------------------------------------------------------------- conexiones

## Anfitrión: los jugadores de un PC que se ha ido pasan a un bot hasta el final del nivel (D-10).
func _on_roster() -> void:
	if not host: return
	for q: Player in game.players:
		if q.remote and not net.peers.has(_peer_of(q)):
			var bot := BotInput.new("follow", 3.0 + q.index * 0.7)
			bot.phase = TAU * (q.index + 1) / 4.0
			bot.body = q
			for r: Player in game.players:
				if not r.remote and r != q:
					bot.leader = r
					break
			q.net_release(bot)
			if game.has_method("announce"): game.announce("J%d se ha desconectado: lo lleva la máquina" % (q.index + 1), 2.5)
	for id in _ready_peers.keys():
		if not net.peers.has(id): _ready_peers.erase(id)
	if not started: _check_all_ready()

## La sesión se ha cerrado (se fue el anfitrión, o este PC salió): de vuelta al menú online.
func _on_closed(reason: String) -> void:
	if not is_inside_tree() or reason == "": return
	if game.has_method("net_closed"): game.net_closed(reason)
