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
## - Combate (hito 9.3b): las balas enemigas viajan al nacer (BULLETS) y cada PC las mueve igual,
##   con el retraso de las marionetas; lo que golpean a los jugadores de un PC lo decide ese PC,
##   igual que el contacto de las marionetas (la foto dice cuánto daña cada enemigo al tocar).
##   Las armas de los jugadores funcionan en todos los PC, pero el daño a los enemigos solo
##   cuenta en el anfitrión. Las gemas se sueltan igual en todos (GEMS: id y semilla) y la
##   experiencia la cuenta el anfitrión (TAKEN, la barra común en cada foto). El progreso de
##   cada jugador (nivel, armas, objetos, atributos y tienda) lo reparte el anfitrión (PROG).
## - Mundo (hito 9.3c): lo que hacen los enemigos y solo se ve o golpea en un círculo
##   (`CombatWorld.strike`, `sfx`, `splash`…), sus avisos en el suelo (`Telegraph.enemy`), los
##   rompibles, las recompensas, los baúles y los peligros del escenario viajan como sucesos
##   (WORLD, fiables, con el ms del anfitrión) y el invitado los repite cuando su reloj llega a
##   ese ms; los golpes dañan a los jugadores de cada PC. Recoger y abrir lo decide el anfitrión.
## - Paradas (hito 9.4a, D-10): las subidas por turnos y la pausa paran la partida en todos los
##   PC. Las decide el anfitrión (HALT y RESUME). Cuando le toca subir a un jugador de otro PC,
##   ese PC abre la ventana con sus opciones y manda lo elegido (PICK); los bots eligen sin
##   parar. La pausa la pide cualquier PC (PAUSE) y la quita quien la puso o el anfitrión. El
##   reloj de las marionetas sigue corriendo durante la parada (el anfitrión manda fotos
##   quietas), así que lo que estaba en cola sale a su hora y nada da saltos al seguir.
## - Conexión (hito 9.4b): si al invitado no le llegan fotos en más de QUIET s, un aviso
##   arriba («Sin noticias del anfitrión…») con los segundos que lleva; se quita solo al volver.
##   A los QUIET_LEAVE s sale también el botón «Salir al menú principal».
## - Vuelta (hito 9.5a, D-10): los jugadores de un PC que se va los lleva la máquina hasta el
##   final del nivel (y desde el principio en los siguientes, si no vuelve). Un PC que entra con
##   la partida empezada recupera esos puestos (`GameSession.claim`) y espera en su selección;
##   al pasar de nivel o reintentar, NEXT y RESTART llevan el PC de cada puesto y él recibe
##   START con los jugadores y el progreso de cada uno.
##
## Formato de las fotos (bytes): ver `write_player`, `write_enemy` y `_on_enemy_bullet`.

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
const BULLETS := NetSession.USER + 20        ## anfitrión -> invitados: balas enemigas nuevas (no fiable)
const GEMS := NetSession.USER + 21           ## anfitrión -> invitados: [primer id, x, z, valor, escalón, semilla]
const TAKEN := NetSession.USER + 22          ## anfitrión -> invitados: ids de gemas recogidas
const PROG := NetSession.USER + 23           ## anfitrión -> invitados: [jugador, progreso]
const WORLD := NetSession.USER + 24          ## anfitrión -> invitados: [[ms, suceso, datos], ...]
const HALT := NetSession.USER + 25           ## anfitrión -> invitados: se para {k: lvup|pause, peer, n, i, title, attr}
const RESUME := NetSession.USER + 26         ## anfitrión -> invitados: sigue {peer, text, all}
const PICK := NetSession.USER + 27           ## invitado -> anfitrión: mejora elegida {n, i, key, banished, rerolls, banishes}
const PAUSE := NetSession.USER + 28          ## invitado -> anfitrión: pide (true) o quita (false) la pausa
const MARK := NetSession.USER + 29           ## marca de un jugador (F9, LB+RB) [PC, n, dónde]: el anfitrión la reparte

const SNAP_EVERY := 3                        ## pasos de física entre fotos del anfitrión (20 Hz)
const PSTATE_EVERY := 2                      ## y entre estados de un invitado (30 Hz)
const READY_EVERY := 0.5                     ## s entre avisos de READY
const LATE_EVERY := 60                       ## pasos entre avisos a quien vuelve (1 s)
const POS_K := 100.0                         ## posiciones y velocidades en cm (int16: ±327 m)
const STAT_K := 10.0                         ## vida y cordura en décimas (uint16)
const PLAYER_BYTES := 17
const ENEMY_BYTES := 15
const BULLET_BYTES := 18
const BULLETS_PER_MSG := 55                  ## unos 1000 bytes: cabe en un paquete sin trocear
const PROG_EVERY := 15                       ## pasos entre comprobaciones del progreso (anfitrión)

var game: Node                               ## la partida (game.gd)
var net: NetSession
var host := false
var started := false
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
var _bul := StreamPeerBuffer.new()           ## anfitrión: balas enemigas de este paso
var _bul_n := 0
var _bul_t := 0
var _bul_queue: Array = []                   ## invitado: [ms del anfitrión, datos de la bala] por soltar
var _taken := []                             ## anfitrión: gemas recogidas en este paso
var _prog_sig := {}                          ## anfitrión: jugador -> firma del último progreso mandado
var _world_out := []                         ## anfitrión: sucesos del mundo de este paso
var _ev_queue: Array = []                    ## invitado: sucesos del mundo por repetir [ms, suceso, datos]
var _objs := {}                              ## id -> rompible, recompensa o baúl (los dos lados)
var _next_oid := 1
var halt := {}                               ## parada en curso (los dos lados); vacía, la partida corre
var _halt_n := 0                             ## anfitrión: número de la última parada (n)
var _remote_bots := {}                       ## anfitrión: índice de jugador -> true si en su PC lo lleva un bot
var _snap_at := 0                            ## invitado: ms (de este PC) de la última foto
var _quiet: CanvasLayer                      ## invitado: aviso de que no llegan fotos
var _quiet_lbl: Label
var _gap := PackedFloat32Array()             ## anfitrión, pruebas (snap_gap=t,dur): sin fotos de t a t+dur s de juego
const QUIET := 2.0                           ## s sin fotos hasta el aviso
const QUIET_LEAVE := 10.0                    ## y hasta el botón de salir
var _quiet_btn: Button
var _closed := false                         ## la sesión se ha cerrado (sale la pantalla final)

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
		if game.world != null: game.world.bullets.on_enemy_spawn = _on_enemy_bullet
		var gm: GemManager = game.get("gems")
		if gm != null:
			gm.dropped.connect(func(first: int, pos: Vector3, value: float, tier: int, seed: int) -> void:
				if started: net.send(0, GEMS, [first, pos.x, pos.z, value, tier, seed]))
			gm.collected.connect(func(id: int) -> void: _taken.append(id))
		if game.world != null:
			game.world.on_net = _on_world
			game.world.fx.child_entered_tree.connect(_on_fx_child)
			for c in game.world.fx.get_children(): _on_fx_child(c)    # los rompibles del principio
		var hz: Hazards = game.get("hazards")
		if hz != null: hz.spawned.connect(func(kind: String, at: Vector3) -> void: _world_event("haz", [kind, at]))
	else:
		_interp = NetInterp.new()
		_enemies_root = game.get_node_or_null("Enemies")
	var la: Variant = game.get("args")
	_log_on = la is LaunchArgs and (la as LaunchArgs).get_bool("log")
	_log_sent = net.sent_to.duplicate()               # los contadores son de toda la sesión: desde aquí
	_log_wire = net.wire_sent
	_type_start = net.sent_type.duplicate()
	var seats := PackedStringArray()
	for q: Player in game.players: seats.append("J%d %s (%s)" % [q.index + 1, q.data.id, _seat_name(q.index)])
	var lv: Variant = game.get("level")
	_say("partida: %s · %s" % [String((lv as LevelData).id) if lv is LevelData else "?", ", ".join(seats)])
	if host:
		net.admit = _admit
		_release_gone(false)                           # los de un PC que no ha vuelto: la máquina, desde el principio
	if host and la is LaunchArgs and (la as LaunchArgs).has("snap_gap"): _gap = (la as LaunchArgs).get_floats("snap_gap")
	_wait_overlay("Esperando a los demás jugadores…" if host else "Esperando al anfitrión…")
	if pause_tree: get_tree().paused = true
	if host: _check_all_ready()
	else: _send_ready()

## Lo que el anfitrión puede haber cambiado del nivel (pruebas: final_at, mid_at) y el HUD enseña.
func _timing() -> Dictionary:
	var lv: LevelData = game.director.level if game.director != null else null
	if lv == null: return {"difficulty": Difficulty.levels()}
	return {"final_time": lv.final_time, "mid_times": Array(lv.mid_times), "difficulty": Difficulty.levels()}

## ¿Es de este PC el jugador?
func is_mine(q: Player) -> bool:
	return not q.remote

# ---------------------------------------------------------------- arranque

func _send_ready() -> void:
	_ready_t = READY_EVERY
	net.send(1, READY, {"bots": my_bots()})

## Jugadores de este PC que lleva la máquina: eligen sus mejoras sin parar la partida. Con
## bots_pause=true (pruebas) cuentan como personas: paran la partida y abren la ventana.
func my_bots() -> Array:
	var out := []
	var la: Variant = game.get("args")
	if la is LaunchArgs and (la as LaunchArgs).get_bool("bots_pause"): return out
	for q: Player in game.players:
		if not q.remote and q.input is BotInput: out.append(q.index)
	return out

## Anfitrión: ¿al jugador (de otro PC) lo lleva un bot en su PC?
func is_remote_bot(q: Player) -> bool:
	return q.remote and _remote_bots.has(q.index)

func _check_all_ready() -> void:
	if started: return
	for id in net.peers:
		if id != 1 and not _ready_peers.has(id) and not GameSession.returning.has(id): return   # quien vuelve, al siguiente
	_go()

func _go() -> void:
	started = true
	if host:
		for id in net.peers:
			if id != 1:
				net.send(id, GO, _timing())
				_send_objects(id)
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
	var t0 := Prof.start()
	_process_step(delta)
	Prof.stop("red", t0)

func _process_step(delta: float) -> void:
	if not host and not started:
		_ready_t -= delta
		if _ready_t <= 0.0: _send_ready()
	if started and not get_tree().paused: _log(delta)   # al fichero siempre; a la consola con log=true
	if not host and started and not _closed: _show_quiet(silence())

## Invitado: s desde la última foto del anfitrión (0 antes de la primera).
func silence() -> float:
	if host or _snap_at == 0: return 0.0
	return (Time.get_ticks_msec() - _snap_at) / 1000.0

func _show_quiet(s: float) -> void:
	if s <= QUIET:
		if _quiet != null:
			_quiet.queue_free()
			_quiet = null
			_say("vuelven las fotos")
		return
	if _quiet == null:
		_quiet = CanvasLayer.new()
		_quiet.layer = 35
		_quiet.process_mode = Node.PROCESS_MODE_ALWAYS
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.03, 0.03, 0.05, 0.85), Color(0.95, 0.3, 0.25, 0.8), 8))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		panel.add_child(col)
		_quiet_lbl = UiKit.label("", 24, UiKit.TEXT)
		_quiet_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(_quiet_lbl)
		_quiet_btn = UiKit.button("Salir al menú principal")
		_quiet_btn.custom_minimum_size = Vector2(320, 50)
		_quiet_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_quiet_btn.visible = false
		_quiet_btn.pressed.connect(func() -> void: if game.has_method("_quit"): game.call("_quit"))
		col.add_child(_quiet_btn)
		_quiet.add_child(panel)
		panel.resized.connect(func() -> void: panel.position = Vector2((panel.get_viewport_rect().size.x - panel.size.x) * 0.5, 215.0))   # bajo los anuncios
		add_child(_quiet)
		_say("sin noticias del anfitrión")
	_quiet_lbl.text = "  Sin noticias del anfitrión… %d s  " % int(s)
	if s > QUIET_LEAVE and not _quiet_btn.visible:   # la partida está parada: ofrece salir (con el foco, para el mando)
		_quiet_btn.visible = true
		_quiet_btn.grab_focus()
		_say("botón de salir")

## Apunta algo en el registro de red (y en la consola, con log=true, con "RED" delante).
func _say(text: String) -> void:
	if _log_on: print("RED " + text)
	net.netlog.line(text)

## Registro: cada 5 s, lo que ve este PC (para comparar las ventanas, y en el fichero de red).
var _log_t := 0.0
var _log_sent := {}                          ## PC -> bytes mandados hasta el último registro
var _type_start := {}                        ## bytes por tipo al empezar el nivel
var _log_wire := 0                           ## bytes reales (comprimidos) hasta el último registro
var _wire_bw := [0.0, 0, 0.0]                ## lo mismo que _bw, con los bytes reales del PC
var _bw := {}                                ## PC -> [suma de kB/s, registros, pico] (resumen al salir)
var _log_on := false
const TYPE_NAMES := {READY: "READY", GO: "GO", PSTATE: "PSTATE", SNAP: "SNAP", SPAWN: "SPAWN", DIE: "DIE",
	ANIM: "ANIM", EVENT: "EVENT", NEXT: "NEXT", RESTART: "RESTART", BULLETS: "BULLETS", GEMS: "GEMS",
	TAKEN: "TAKEN", PROG: "PROG", WORLD: "WORLD", HALT: "HALT", RESUME: "RESUME", PICK: "PICK", PAUSE: "PAUSE", MARK: "MARK",
	NetSelect.PROFILE: "PROFILE", NetSelect.ACTION: "ACTION", NetSelect.PROFILES: "PROFILES", NetSelect.SEATS: "SEATS",
	NetSelect.START: "START", NetSelect.LATE: "LATE"}
func _log(delta: float) -> void:
	_log_t += delta
	if _log_t < 5.0: return
	var pos := PackedStringArray()
	for q: Player in game.players:
		pos.append("J%d%s(%.1f,%.1f) v%d c%d n%d a%d" % [q.index + 1, "r" if q.remote else "", q.global_position.x, q.global_position.z,
			roundi(q.health), roundi(q.sanity), q.progress.level, q.weapons.weapons.size() if q.weapons else 0])
	var n := 0
	for nid in _enemies: if is_instance_valid(_enemies[nid]): n += 1
	var team: TeamXp = game.get("team")
	var total := 0.0
	var per := PackedStringArray()
	for id: int in net.sent_to:                      # lo mandado a cada PC (con cabeceras)
		var r := (int(net.sent_to[id]) - int(_log_sent.get(id, 0))) / _log_t / 1024.0
		total += r
		if net.peers.has(id):
			per.append("%s %.1f%s" % [net.peers[id].get("name", id), r, (" %d ms" % int(net.peers[id].get("ping", 0))) if host else ""])
			var b: Array = _bw.get(id, [0.0, 0, 0.0, ""])
			_bw[id] = [b[0] + r, b[1] + 1, maxf(b[2], r), String(net.peers[id].get("name", id))]
	_log_sent = net.sent_to.duplicate()
	var wire := (net.wire_sent - _log_wire) / _log_t / 1024.0   # lo que sale de verdad (comprimido)
	_log_wire = net.wire_sent
	_wire_bw = [_wire_bw[0] + wire, _wire_bw[1] + 1, maxf(_wire_bw[2], wire)]
	_say("%s t=%.1f enemigos=%d abatidos=%d xp=%.0f balas=%d gemas=%d %s  sale=%.1f kB/s%s real=%.1f  ping=%d" % ["anfitrion" if host else "invitado",
		game.director.time if game.director != null else 0.0, n, game.kills, team.xp if team != null else 0.0,
		game.world.bullets.count, game.gems.count, " ".join(pos), total,
		" (" + ", ".join(per) + ")" if per.size() > 1 else "", wire, int(net.peers.get(net.my_id, {}).get("ping", 0)) if not host else 0])
	_log_t = 0.0

## Al salir: media y pico de lo mandado a cada PC y reparto por tipo de mensaje.
func _exit_tree() -> void:
	if _bw.is_empty(): return
	var per := PackedStringArray()
	for id: int in _bw:
		var b: Array = _bw[id]
		per.append("%s media %.1f pico %.1f" % [b[3], b[0] / maxf(b[1], 1), b[2]])
	var by_type := {}                                  # en este nivel
	var all := 0
	for t: int in net.sent_type:
		by_type[t] = int(net.sent_type[t]) - int(_type_start.get(t, 0))
		all += by_type[t]
	var types := by_type.keys().filter(func(t: int) -> bool: return int(by_type[t]) > 0)
	types.sort_custom(func(a: int, b: int) -> bool: return int(by_type[a]) > int(by_type[b]))
	var share := PackedStringArray()
	for t: int in types.slice(0, 6):
		var tn: Variant = TYPE_NAMES.get(t, NetSession.Msg.find_key(t))
		share.append("%s %d %%" % [tn if tn != null else str(t), roundi(100.0 * int(by_type[t]) / maxf(all, 1))])
	_say("ancho de banda (kB/s por PC, sin comprimir): %s | comprimido, en total: media %.1f pico %.1f | por tipo: %s%s" % [
		", ".join(per), _wire_bw[0] / maxf(_wire_bw[1], 1), _wire_bw[2], ", ".join(share),
		(" | MARCAS en este nivel: %d" % level_marks) if level_marks > 0 else ""])

func _physics_process(_delta: float) -> void:
	var t0 := Prof.start()
	_physics_step()
	Prof.stop("red_envia", t0)

func _physics_step() -> void:
	_tick += 1
	var now := float(Time.get_ticks_msec())
	if host:
		_flush_bullets()
		_flush_world()
		if not _taken.is_empty():
			net.send(0, TAKEN, _taken.duplicate())
			_taken.clear()
		if started and _tick % PROG_EVERY == 0: _send_progress()
		if _tick % LATE_EVERY == 0 and not GameSession.returning.is_empty(): _send_late()
		if started and _tick % SNAP_EVERY == 0 and not _in_gap():
			var t1 := Prof.start()
			_send_snap()
			Prof.stop("red_foto", t1)
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
			var team: TeamXp = game.get("team")
			if team != null:
				team.xp = float(h[1][2])
				team.turn = int(h[1][3]) % maxi(team.members.size(), 1)
		if _interp.has_clock:
			_release_bullets(t)
			_release_world(t)
		if _tick % 60 == 0: _interp.prune(now + _interp.offset)

func _in_gap() -> bool:
	if _gap.size() < 2 or game.director == null: return false
	var t: float = game.director.time
	return t >= _gap[0] and t < _gap[0] + _gap[1]

func _peer_of(q: Player) -> int:
	return GameSession.seats[q.index].peer if q.index < GameSession.seats.size() else 1

# ---------------------------------------------------------------- fotos

## Jugador (17 bytes): índice, x, z, rumbo, vx, vz, esquives, vida, cordura, estado, reanimación.
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
	s.put_u8(clampi(roundi(q.revive_progress / maxf(q.rules.revive_time, 0.01) * 255.0), 0, 255) if q.rules != null else 0)

## [índice, valores]: valores = [x, z, rumbo, vx, vz, esquives, vida, cordura, estado, reanimación 0..1].
static func read_player(s: StreamPeerBuffer) -> Array:
	var i := s.get_u8()
	return [i, [s.get_16() / POS_K, s.get_16() / POS_K, s.get_u8() / 256.0 * TAU, s.get_16() / POS_K, s.get_16() / POS_K,
		s.get_u8(), s.get_u16() / STAT_K, s.get_u16() / STAT_K, s.get_u8(), s.get_u8() / 255.0]]

## Enemigo (15 bytes): nid, x, y, z, rumbo, animación, fase, vida (fracción), estado, contacto, más estado.
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
	s.put_u8(e.net_contact_byte())
	s.put_u8(e.net_flags2())

## [nid, valores]: valores = [x, y, z, rumbo, animación, fase, vida 0..1, estado, contacto, más estado].
static func read_enemy(s: StreamPeerBuffer) -> Array:
	var nid := s.get_u16()
	return [nid, [s.get_16() / POS_K, s.get_16() / POS_K, s.get_16() / POS_K, s.get_u8() / 256.0 * TAU,
		s.get_u8(), s.get_u8() / 256.0, s.get_u8() / 255.0, s.get_u8(), s.get_u8(), s.get_u8()]]

static func _cm(v: float) -> int:
	return clampi(roundi(v * POS_K), -32768, 32767)

static func _angle8(a: float) -> int:
	return int(roundf(fposmod(a, TAU) / TAU * 256.0)) & 255

## Anfitrión: los invitados con la partida montada (a los que se mandan fotos y eventos).
func _guests_ready() -> Array:
	var out := []
	for id: int in net.peers:
		if id != 1 and _ready_peers.has(id): out.append(id)
	return out

func _send_snap() -> void:
	var s := StreamPeerBuffer.new()
	s.put_u32(Time.get_ticks_msec())
	s.put_float(game.director.time if game.director != null else 0.0)
	s.put_u16(clampi(game.kills, 0, 65535))
	var team: TeamXp = game.get("team")
	s.put_float(team.xp if team != null else 0.0)
	s.put_u8(team.turn if team != null else 0)
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
	net.send_many(_guests_ready(), SNAP, s.data_array, false)

func _send_pstate() -> void:
	var s := StreamPeerBuffer.new()
	s.put_u32(Time.get_ticks_msec())
	var mine: Array[Player] = []
	for q: Player in game.players:
		if not q.remote: mine.append(q)
	s.put_u8(mine.size())
	for q in mine: write_player(s, q)
	net.send(1, PSTATE, s.data_array, false)

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
	q.net_apply(pos, lerp_angle(a[2], b[2], w), vel, int(b[5]), float(b[6]), float(b[7]), int(b[8]), float(b[9]))

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
	e.net_contact = int(b[8])
	e.net_apply_flags2(int(b[9]))

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
	_say_event(d)
	net.send(0, EVENT, d)

const EVENT_TEXT := {"won": "nivel superado", "lost": "derrota", "final": "aparece el enemigo final", "boss": "jefe", "mid": "enemigo especial"}

## Los sucesos que cambian el nivel, con el reloj y las bajas (para comparar los registros de cada PC).
func _say_event(d: Dictionary) -> void:
	var k := String(d.get("k", ""))
	if EVENT_TEXT.has(k):
		_say("%s · t=%.1f abatidos=%d" % [EVENT_TEXT[k], game.director.time if game.director != null else 0.0, game.kills])

## Anfitrión: derrota (la decide él, con la vida que le llega de cada PC).
func send_lost() -> void:
	_event({"k": "lost"})

func send_next(level_id: String) -> void:
	_say("siguiente nivel: %s" % level_id)
	var back := GameSession.apply_returns(net.peers)
	net.send(0, NEXT, {"level": level_id, "carry": GameSession.carry.duplicate(true),
		"team_xp": GameSession.team_xp, "team_turn": GameSession.team_turn, "peers": seat_peers()})
	_send_start(back)

func send_restart() -> void:
	_say("reintento")
	var back := GameSession.apply_returns(net.peers)
	net.send(0, RESTART, {"peers": seat_peers()})
	_send_start(back)

## El PC de cada puesto (cambia cuando alguien vuelve).
static func seat_peers() -> Array:
	return GameSession.seats.map(func(s: GameSession.Seat) -> int: return s.peer)

## Invitados: el PC de cada puesto, como lo lleva el anfitrión.
static func apply_seat_peers(p: Variant) -> void:
	if not p is Array or (p as Array).size() != GameSession.seats.size(): return
	for i in GameSession.seats.size(): GameSession.seats[i].peer = int(p[i])

## Anfitrión: a los PC que vuelven, lo que necesitan para entrar (el START de la selección, con
## el progreso de cada jugador).
func _send_start(back: Array) -> void:
	for id: int in back:
		net.send(id, NetSelect.START, {"level": String(GameSession.level), "players": GameSession.seats_to_wire(),
			"carry": GameSession.carry.duplicate(true), "team_xp": GameSession.team_xp, "team_turn": GameSession.team_turn})
		_say("vuelve el PC %d" % id)

# ---------------------------------------------------------------- mensajes

func _on_message(from: int, type: int, data: Variant) -> void:
	if host:
		match type:
			READY:
				_ready_peers[from] = true
				if data is Dictionary and data.get("bots") is Array:
					for i: Variant in data.bots:
						if int(i) < game.players.size() and _peer_of(game.players[int(i)]) == from: _remote_bots[int(i)] = true
				if started:                                  # llegó tarde o se perdió el GO
					net.send(from, GO, _timing())
					_send_objects(from)
				else: _check_all_ready()
			PSTATE:
				if data is PackedByteArray: _on_pstate(from, data)
			PICK:
				if data is Dictionary and halt.get("k") == "lvup" and int(halt.get("peer", 0)) == from \
						and int(data.get("i", -1)) == int(halt.get("i", -2)) and int(data.get("n", -1)) == int(halt.get("n", -2)) \
					and game.has_method("net_picked"):
					game.net_picked(int(data.i), data)
			PAUSE:
				if game.has_method("net_pause_asked"): game.net_pause_asked(from, bool(data))
			MARK:
				if data is Array and (data as Array).size() == 3:
					_say_mark(data)
					var others: Array = net.peers.keys().filter(func(id: int) -> bool: return id != 1 and id != from)
					net.send_many(others, MARK, data)     # y a los demás invitados
		return
	if from != 1: return
	match type:
		GO:
			if started: return
			var lv: LevelData = game.director.level if game.director != null else null
			if data is Dictionary and data.get("difficulty") is Dictionary: Difficulty.set_net(data.difficulty)
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
				if is_instance_valid(e):
					if game.has_method("net_enemy_died"): game.net_enemy_died(e)   # cada PC cobra y cuenta en su partida (D-10)
					e.puppet_die()
		ANIM: if data is Array and (data as Array).size() == 2: _anim_names[int(data[0])] = String(data[1])
		EVENT: if data is Dictionary: _on_event(data)
		NEXT:
			if data is Dictionary and game.has_method("net_next"):
				apply_seat_peers(data.get("peers"))
				game.net_next(data)
		RESTART:
			if data is Dictionary: apply_seat_peers(data.get("peers"))
			if game.has_method("net_restart"): game.net_restart()
		BULLETS: if data is PackedByteArray: _on_bullets(data)
		GEMS:
			var gm: GemManager = game.get("gems")
			if gm != null and data is Array and (data as Array).size() == 6:
				gm.drop(Vector3(float(data[1]), 0.0, float(data[2])), float(data[3]), int(data[4]), int(data[0]), int(data[5]))
		TAKEN:
			var gm: GemManager = game.get("gems")
			if gm != null and data is Array:
				for id: Variant in data: gm.remove_id(int(id))
		WORLD:
			if data is Array:
				for ev: Variant in data:
					if ev is Array and (ev as Array).size() == 3 and ev[2] is Array: _ev_queue.append(ev)
		MARK:
			if data is Array and (data as Array).size() == 3: _say_mark(data)
		HALT:
			if data is Dictionary:
				halt = data
				_say("parada: %s" % _halt_text(halt))
				if pause_tree: get_tree().paused = true
				if game.has_method("net_halt"): game.net_halt(halt)
		RESUME:
			if halt.is_empty(): return
			halt = {}
			_say("sigue" + (": " + String(data.get("text", "")) if data is Dictionary and String(data.get("text", "")) != "" else ""))
			if data is Dictionary and data.get("difficulty") is Dictionary: Difficulty.set_net(data.difficulty)   # la pudo cambiar en la pausa
			if game.has_method("net_resume"): game.net_resume(data if data is Dictionary else {})
		PROG:
			if data is Array and (data as Array).size() == 2 and data[1] is Dictionary:
				var i := int(data[0])
				if i >= 0 and i < game.players.size():
					var q: Player = game.players[i]
					if apply_progress(q, data[1]) and game.has_method("level_fx"): game.level_fx(q)

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
		if s.get_available_bytes() < PLAYER_BYTES: return
		var r := read_player(s)
		var i: int = r[0]
		if i < game.players.size() and (game.players[i] as Player).remote and _peer_of(game.players[i]) == from:
			ip.push(i, t, r[1])

func _on_snap(bytes: PackedByteArray) -> void:
	if bytes.size() < 16: return
	var s := StreamPeerBuffer.new()
	s.data_array = bytes
	var t := float(s.get_u32())
	_interp.observe(t, Time.get_ticks_msec())
	_snap_at = Time.get_ticks_msec()
	var dtime := s.get_float()
	var kills := s.get_u16()
	var txp := s.get_float()
	var turn := s.get_u8()
	_interp.push("h", t, [dtime, kills, txp, turn])
	var n := s.get_u8()
	for k in n:
		if s.get_available_bytes() < PLAYER_BYTES: return
		var r := read_player(s)
		_interp.push("p%d" % int(r[0]), t, r[1])
	if s.get_available_bytes() < 2: return
	var m := s.get_u16()
	for k in m:
		if s.get_available_bytes() < ENEMY_BYTES: return
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
	_say_event(d)
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
		"say":
			if game.has_method("announce"): game.announce(String(d.get("text", "")), 1.6)

# ---------------------------------------------------------------- combate (hito 9.3b)

## Anfitrión: una bala enemiga nueva (BulletManager.on_enemy_spawn). Van en tandas de cada paso
## con el ms en que nacieron; por bala (18 bytes): x, z, vx, vz (cm), estilo, radio y tamaño (cm),
## daño físico y mental (décimas), vida (centésimas de s) y si atraviesa el decorado.
func _on_enemy_bullet(pos: Vector3, vel: Vector3, radius: float, size: float, phys: float, ment: float,
		life: float, style: int, over_walls: bool) -> void:
	if not started: return
	if _bul_n == 0: _bul_t = Time.get_ticks_msec()
	_bul.put_16(_cm(pos.x)); _bul.put_16(_cm(pos.z))
	_bul.put_16(_cm(vel.x)); _bul.put_16(_cm(vel.z))
	_bul.put_u8(style)
	_bul.put_u8(clampi(roundi(radius * 100.0), 1, 255))
	_bul.put_u8(clampi(roundi(size * 100.0), 1, 255))
	_bul.put_u16(clampi(roundi(phys * STAT_K), 0, 65535))
	_bul.put_u16(clampi(roundi(ment * STAT_K), 0, 65535))
	_bul.put_u16(clampi(roundi(life * 100.0), 0, 65535))
	_bul.put_u8(1 if over_walls else 0)
	_bul_n += 1
	if _bul_n >= BULLETS_PER_MSG: _flush_bullets()

func _flush_bullets() -> void:
	if _bul_n == 0: return
	var s := StreamPeerBuffer.new()
	s.put_u32(_bul_t)
	s.put_u16(_bul_n)
	s.put_data(_bul.data_array)
	net.send_many(_guests_ready(), BULLETS, s.data_array, false)
	_bul = StreamPeerBuffer.new()
	_bul_n = 0

## Invitado: las balas que llegan esperan a que el reloj de las marionetas llegue a su ms de
## nacimiento (así salen de donde se ve al enemigo) y, si llegan tarde, salen adelantadas.
func _on_bullets(bytes: PackedByteArray) -> void:
	if bytes.size() < 6: return
	var s := StreamPeerBuffer.new()
	s.data_array = bytes
	var t := float(s.get_u32())
	var n := s.get_u16()
	for k in n:
		if s.get_available_bytes() < BULLET_BYTES: return
		var b := [t, s.get_16() / POS_K, s.get_16() / POS_K, s.get_16() / POS_K, s.get_16() / POS_K, s.get_u8(),
			s.get_u8() / 100.0, s.get_u8() / 100.0, s.get_u16() / STAT_K, s.get_u16() / STAT_K, s.get_u16() / 100.0, s.get_u8() == 1]
		_bul_queue.append(b)

func _release_bullets(render_t: float) -> void:
	if _bul_queue.is_empty() or game.world == null: return
	var left := []
	for b: Array in _bul_queue:
		if float(b[0]) > render_t:
			left.append(b)
			continue
		var ahead := minf((render_t - float(b[0])) / 1000.0, 1.0)
		game.world.bullets.spawn_remote(int(b[5]), Vector3(b[1], 0.0, b[2]), Vector3(b[3], 0.0, b[4]), b[6], b[7], b[8], b[9], b[10], b[11], ahead)
	_bul_queue = left

## Lo que el anfitrión reparte del progreso de un jugador: lo de `GameSession.snapshot` más lo
## comprado en su tienda.
static func progress_of(q: Player) -> Dictionary:
	var d := GameSession.snapshot(q)
	d["shop"] = q.shop.duplicate()
	return d

## Aplica el progreso que manda el anfitrión (sin tocar vida ni cordura, salvo lo que suba el
## máximo). Devuelve true si el jugador ha subido de nivel.
static func apply_progress(q: Player, d: Dictionary) -> bool:
	var before := q.progress.level
	q.progress.level = int(d.get("level", before))
	q.progress.xp = float(d.get("xp", 0.0))
	q.progress.pending = 0
	if d.get("passives") is Dictionary: q.progress.passives = (d.passives as Dictionary).duplicate()
	if d.get("attrs") is Dictionary: q.attrs = (d.attrs as Dictionary).duplicate()
	if d.get("attrs_level1") is Dictionary: q.attrs_level1 = (d.attrs_level1 as Dictionary).duplicate()
	if d.get("weapons") is Array:
		var want := {}
		for e: Variant in d.weapons:
			if e is Array and (e as Array).size() == 2: want[String(e[0])] = int(e[1])
		for w in q.weapons.weapons.duplicate():
			if not want.has(String(w.data.id)): q.weapons.remove_weapon(w.data.id)
		for id: String in want:
			var w := q.weapons.get_weapon(StringName(id))
			if w == null:
				var path := "res://data/weapons/%s.tres" % id
				if not ResourceLoader.exists(path): continue
				w = q.weapons.add_weapon(load(path))
			if w != null: w.level = clampi(want[id], 1, w.data.max_level)
	var shop := SelectState.Profile.clean_shop(d.get("shop", {}))
	if not shop.is_empty(): q.shop = shop
	q.rebuild_stats()
	return q.progress.level > before

## Anfitrión: manda el progreso de los jugadores que ha cambiado desde la última vez.
func _send_progress() -> void:
	for q: Player in game.players:
		if q.weapons == null: continue
		var d := progress_of(q)
		var sig := var_to_str(d).hash()
		if _prog_sig.get(q.index, 0) == sig: continue
		_prog_sig[q.index] = sig
		net.send(0, PROG, [q.index, d])

# ---------------------------------------------------------------- mundo (hito 9.3c)

## Anfitrión: algo que ha hecho un enemigo (CombatWorld.on_net). El enemigo que golpea viaja
## como su id de red.
func _on_world(kind: String, a: Array) -> void:
	if kind == "strike":
		a = a.duplicate()
		a[4] = _nid(a[4] as Enemy) if a[4] is Enemy else 0
	elif kind == "windup":                               # preparación de un ataque (hito 12.5)
		a = [_nid(a[0] as Enemy), a[1]]
	_world_event(kind, a)

func _world_event(kind: String, a: Array) -> void:
	if started: _world_out.append([Time.get_ticks_msec(), kind, a])

func _flush_world() -> void:
	if _world_out.is_empty(): return
	net.send_many(_guests_ready(), WORLD, _world_out)
	_world_out = []

## Anfitrión: lo que aparece entre los efectos y hay que repetir en los invitados.
func _on_fx_child(n: Node) -> void:
	if n is Telegraph:
		var tg := n as Telegraph
		if tg.net: _world_event("tg", [tg.position, tg.radius, tg.duration, tg.color, tg.fill, tg.rotation.y, tg.scale])
	elif n is Breakable:
		var b := n as Breakable
		var oid := _add_obj(b)
		_world_event("brk+", _obj_args(b))
		b.broken.connect(func(_x: Breakable) -> void:
			_objs.erase(oid)
			_world_event("brk-", [oid]))
	elif n is Pickup:
		var p := n as Pickup
		var oid := _add_obj(p)
		_world_event("pk+", _obj_args(p))
		p.picked.connect(func(_x: Pickup, by: Player, money: int) -> void:
			_objs.erase(oid)
			_world_event("pk-", [oid, by.index, money]))
		p.tree_exiting.connect(func() -> void: _objs.erase(oid))
	elif n is ArcaneChest:
		var c := n as ArcaneChest
		var oid := _add_obj(c)
		_world_event("ch+", _obj_args(c))
		c.opened.connect(func(_x: ArcaneChest, by: Player) -> void:
			_objs.erase(oid)
			_world_event("ch!", [oid, by.index]))

func _add_obj(n: Node) -> int:
	var oid := _next_oid
	_next_oid += 1
	_objs[oid] = n
	n.set_meta("oid", oid)
	return oid

func _obj_args(n: Node) -> Array:
	var oid := int(n.get_meta("oid", 0))
	if n is Breakable: return [oid, (n as Breakable).position, (n as Breakable).model_index, (n as Breakable).yaw]
	if n is Pickup: return [oid, (n as Pickup).position, int((n as Pickup).kind)]
	if n is ArcaneChest: return [oid, (n as ArcaneChest).position, (n as ArcaneChest).money, (n as ArcaneChest).heal]
	return [oid]

## Anfitrión: a un invitado que acaba de empezar, lo que ya hay (rompibles, recompensas, baúles).
func _send_objects(peer: int) -> void:
	var evs := []
	for oid in _objs:
		var n: Node = _objs[oid]
		if not is_instance_valid(n) or n.is_queued_for_deletion(): continue
		if n is ArcaneChest and (n as ArcaneChest).is_open: continue
		var kind := "brk+" if n is Breakable else ("pk+" if n is Pickup else "ch+")
		evs.append([0, kind, _obj_args(n)])
	if not evs.is_empty(): net.send(peer, WORLD, evs)

## Invitado: repite los sucesos cuyo ms ya ha llegado al reloj de las marionetas.
func _release_world(render_t: float) -> void:
	if _ev_queue.is_empty(): return
	var left := []
	for ev: Array in _ev_queue:
		if float(ev[0]) > render_t:
			left.append(ev)
			continue
		_apply_world(String(ev[1]), ev[2], maxf((render_t - float(ev[0])) / 1000.0, 0.0))
	_ev_queue = left

func _apply_world(kind: String, a: Array, ahead: float) -> void:
	var w: CombatWorld = game.world
	if w == null: return
	match kind:
		"tg":
			if ahead >= float(a[2]): return
			var tg := Telegraph.new().setup(float(a[1]), float(a[2]) - ahead, a[3], bool(a[4]))
			tg.position = a[0]
			tg.rotation.y = float(a[5])
			tg.scale = a[6]
			w.fx.add_child(tg)
		"brk+":
			var b := Breakable.new().setup(w, a[1])
			b.model_index = int(a[2])
			b.yaw = float(a[3])
			b.mirror = true
			_objs[int(a[0])] = b
			w.fx.add_child(b)
		"brk-":
			var b: Variant = _objs.get(int(a[0]))
			_objs.erase(int(a[0]))
			if b is Breakable and is_instance_valid(b): (b as Breakable).shatter()
		"pk+":
			var p := Pickup.new().setup(w, a[1], int(a[2]) as Pickup.Kind)
			p.mirror = true
			_objs[int(a[0])] = p
			w.fx.add_child(p)
		"pk-":
			var p: Variant = _objs.get(int(a[0]))
			_objs.erase(int(a[0]))
			var i := int(a[1])
			if p is Pickup and is_instance_valid(p) and i < game.players.size(): (p as Pickup).take(game.players[i], int(a[2]))
		"ch+":
			var c := ArcaneChest.new().setup(w, a[1], int(a[2]), float(a[3]))
			c.mirror = true
			_objs[int(a[0])] = c
			w.fx.add_child(c)
			if game.director != null: game.director.chest_spawned.emit(c)   # la partida lo anuncia y atiende
		"ch!":
			var c: Variant = _objs.get(int(a[0]))
			_objs.erase(int(a[0]))
			var i := int(a[1])
			if c is ArcaneChest and is_instance_valid(c) and i < game.players.size(): (c as ArcaneChest).open(game.players[i])
		"haz":
			var hz: Hazards = game.get("hazards")
			if hz == null: return
			if String(a[0]) == "angle": hz.spawn_angle_at(a[1])
			else: hz.spawn_wave_at((a[1] as Vector3).z)
		"strike":
			w.apply_net(kind, a, _enemies.get(int(a[4])))
		"windup":
			var e: Variant = _enemies.get(int(a[0]))
			if e != null and is_instance_valid(e) and ahead < float(a[1]): (e as Enemy).windup(float(a[1]) - ahead, false)
		_:
			w.apply_net(kind, a)

# ---------------------------------------------------------------- paradas (hito 9.4a)

## Anfitrión: para la partida en todos los PC. d = {k: "lvup", peer, i, title, attr} (le toca
## subir al jugador i, de ese PC) o {k: "pause", peer} (pausa puesta por ese PC). Antes de una
## subida manda el progreso del jugador, para que su PC tire las opciones con lo que lleva.
## Cada parada lleva su número (n): lo elegido para una subida anterior (si el anfitrión eligió
## por él y el PICK llegó tarde) no vale para la siguiente.
func halt_all(d: Dictionary) -> void:
	_halt_n += 1
	d["n"] = _halt_n
	if d.get("k") == "lvup":
		_prog_sig.erase(int(d.get("i", -1)))
		_send_progress()
	halt = d
	_say("parada: %s" % _halt_text(d))
	net.send(0, HALT, d)
	if pause_tree: get_tree().paused = true
	if game.has_method("net_halt"): game.net_halt(d)

## Anfitrión: la partida sigue en todos los PC. `text` (lo que ha elegido quien subía) lo
## anuncian los PC que no son el suyo; con `all`, todos (el anfitrión ha elegido por él).
func resume_all(text := "", all := false) -> void:
	if halt.is_empty(): return
	var d := {"peer": int(halt.get("peer", 1)), "text": text, "all": all, "difficulty": Difficulty.levels()}   # se pudo cambiar en la pausa (D-42)
	halt = {}
	_say("sigue" + (": " + text if text != "" else ""))
	net.send(0, RESUME, d)
	if game.has_method("net_resume"): game.net_resume(d)

## Invitado: lo que ha elegido su jugador en la subida (la aplica el anfitrión y la devuelve
## con el progreso). Van también los descartes y cambios gastados (Cartas del tarot, Llave).
func send_pick(q: Player, o: PlayerProgress.Option) -> void:
	net.send(1, PICK, {"n": int(halt.get("n", 0)), "i": q.index, "key": PlayerProgress.key_of(o), "banished": q.progress.banished.keys(),
		"rerolls": q.rerolls_used, "banishes": q.banishes_used})

## Invitado: pide la pausa para todos (o quitarla, si la puso él).
func ask_pause(on: bool) -> void:
	net.send(1, PAUSE, on)

## Anuncio en todos los PC (lo que elige un bot de otro PC, por ejemplo).
func say(text: String) -> void:
	_event({"k": "say", "text": text})

# ---------------------------------------------------------------- conexiones

## Anfitrión: los jugadores de un PC que se ha ido pasan a un bot hasta el final del nivel (D-10).
## Anfitrión: un PC se fue a mitad de este nivel (la pantalla final ofrece la carpeta de registros).
var guest_lost := false
var gone_notes := PackedStringArray()        ## "Ana se desconectó en el 0:14" (pantalla final)

func _on_roster() -> void:
	if not host: return
	_release_gone(true)
	for id in GameSession.returning.keys():           # volvió y se ha vuelto a ir antes de entrar
		if not net.peers.has(id): GameSession.returning.erase(id)
	for id in _ready_peers.keys():
		if not net.peers.has(id): _ready_peers.erase(id)
	if not halt.is_empty() and not net.peers.has(int(halt.get("peer", 1))) and game.has_method("net_halt_gone"):
		game.net_halt_gone(halt)                       # se fue quien elegía o quien puso la pausa
	if not started: _check_all_ready()

## Anfitrión: a quien espera para volver, en qué nivel va la partida y el objetivo del HUD.
func _send_late() -> void:
	var where := "Parte %d · Nivel %d" % [game.level.part, game.level.number] if game.level != null else ""
	var goal: String = game.hud.objective_text() if game.hud != null else ""
	for id in GameSession.returning:
		if net.peers.has(id): net.send(id, NetSelect.LATE, [where, goal])

## Anfitrión: un PC entra con la partida empezada (NetSession.admit). Recupera los puestos de un
## PC que se fue y entra al empezar el siguiente nivel.
## Nombre del PC de un puesto (para el registro).
func _seat_name(i: int) -> String:
	return GameSession.seats[i].name if i < GameSession.seats.size() else "?"

## Qué ha parado la partida, en pocas palabras (registro).
func _halt_text(d: Dictionary) -> String:
	if d.get("k") == "lvup": return "subida de J%d · %s" % [int(d.get("i", 0)) + 1, where()]
	return "pausa de %s · %s" % [_seat_name_of_peer(int(d.get("peer", 1))), where()]

## Marca de un jugador de este PC (F9 o LB+RB): en el registro de este PC y en el de los demás,
## para que coincidan al revisarlos.
func mark(n: int) -> void:
	level_marks += 1
	var d := [net.player_name, n, where()]
	_say("marca %d del jugador · %s" % [n, d[2]])
	net.send(0 if host else 1, MARK, d)

var level_marks := 0                        ## marcas de todos los PC en este nivel (resumen)

func _say_mark(d: Array) -> void:
	level_marks += 1
	if game.has_method("announce"): game.announce("%s ha puesto una marca" % String(d[0]).left(20), 1.5)
	if game.has_method("mark_shot"): game.mark_shot(int(d[1]), String(d[0]).left(20))   # lo que se veía aquí
	_say("marca %d de %s · %s (aquí: %s)" % [int(d[1]), String(d[0]).left(20), String(d[2]).left(24), where()])

## Nivel y minuto de partida ("p1_n3 2:14"): para encontrar en el registro lo que cuenta un jugador.
func where() -> String:
	var lv: Variant = game.get("level")
	var t := int(game.director.time) if game.director != null else 0
	return "%s %d:%02d" % [String((lv as LevelData).id) if lv is LevelData else "?", t / 60, t % 60]

func _seat_name_of_peer(peer: int) -> String:
	return String(net.peers.get(peer, {}).get("name", "PC %d" % peer))

func _admit(id: int, pc_name: String) -> int:
	var n := GameSession.claim(id, pc_name, net.peers)
	if n > 0:
		if game.has_method("announce"): game.announce("%s ha vuelto: entrará en el siguiente nivel" % pc_name, 2.5)
		_say("vuelve %s (PC %d) a %d puestos" % [pc_name, id, n])
	return n

## Anfitrión: los jugadores de un PC que no está los lleva la máquina (un bot que sigue a otro).
func _release_gone(say: bool) -> void:
	for q: Player in game.players:
		if q.remote and not net.peers.has(_peer_of(q)):
			if say:
				guest_lost = true
				var note := "%s se desconectó en el %s" % [_seat_name(q.index), where().get_slice(" ", 1)]
				if not gone_notes.has(note): gone_notes.append(note)
			var bot := BotInput.new("follow", 3.0 + q.index * 0.7)
			bot.phase = TAU * (q.index + 1) / 4.0
			bot.body = q
			for r: Player in game.players:
				if not r.remote and r != q:
					bot.leader = r
					break
			q.net_release(bot)
			_say("J%d lo lleva la máquina (se fue su PC)" % (q.index + 1))
			if say and game.has_method("announce"): game.announce("J%d se ha desconectado: lo lleva la máquina" % (q.index + 1), 2.5)

## La sesión se ha cerrado (se fue el anfitrión, o este PC salió): de vuelta al menú online.
func _on_closed(reason: String) -> void:
	if not is_inside_tree() or reason == "": return
	_closed = true
	if game.has_method("net_closed"): game.net_closed(reason)   # mira antes cuánto llevaba sin noticias
	if _quiet != null:                                 # la pantalla final ya lo dice
		_quiet.queue_free()
		_quiet = null
