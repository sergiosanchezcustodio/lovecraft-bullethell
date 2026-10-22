class_name NetSession
extends Node
## Sesión de red (hito 9.1, D-10): anfitrión con autoridad y hasta 3 clientes con ENet.
## Autoload `Net`; los tests crean las suyas (cada una lleva su propio SceneMultiplayer, así
## que caben un anfitrión y un cliente en el mismo proceso).
##
## Los mensajes son bytes propios (`send`), no RPC: no dependen de rutas de nodos que cambian
## al cambiar de escena, y son el canal de las instantáneas de la partida (9.3). Cada mensaje
## lleva su tipo y si es fiable; los tipos del sistema van por debajo de USER.
##
## Conexión: el cliente se presenta (HELLO, con la versión del protocolo); el anfitrión lo
## acepta (WELCOME) o lo rechaza con el motivo (REJECT) y reparte la lista de conectados
## (ROSTER) al cambiar y cada 2 s con el ping de cada uno, que mide él (PING / PONG).
##
## Pruebas: `net_lag=150` retrasa cada mensaje recibido esos ms (si lo llevan las dos copias,
## el ping sube el doble), `net_loss=0.05` pierde esa fracción de los no fiables y
## `net_name=Ana` da otro nombre (dos copias en el mismo PC).

signal hosted(port: int)                     ## sala abierta
signal joined                                ## cliente aceptado por el anfitrión
signal failed(reason: String)                ## no se pudo abrir o conectar
signal closed(reason: String)                ## la sesión ha terminado (vacío: la cerró este PC)
signal roster_changed
signal upnp_done(ok: bool, message: String)
signal message(from: int, type: int, data: Variant)   ## mensajes de la partida (type >= USER)

enum State { OFF, HOSTING, CONNECTING, CONNECTED }
enum Msg { HELLO = 1, WELCOME, REJECT, ROSTER, PING, PONG }
const USER := 16                             ## primer tipo libre para la partida
const PROTOCOL := 2                          ## súbelo al cambiar el formato de cualquier mensaje
const MAX_PLAYERS := 4                       ## jugadores en total, sumando los de cada PC
const HELLO_TIMEOUT := 5.0                   ## s para presentarse tras conectar
const CONNECT_TIMEOUT := 8.0                 ## s para conectar con el anfitrión
const PING_EVERY := 1.0
const ROSTER_EVERY := 2.0

var state := State.OFF
var my_id := 0
var port := 0
const DEFAULT_NAME := "Investigador"
var player_name := DEFAULT_NAME
var locals := 1                              ## jugadores de este PC
var accepting := true                        ## anfitrión: false con la partida empezada (D-10: no se entra a medias)
var protocol := PROTOCOL                     ## distinto solo en los tests (rechazo por versión)
## id -> {name, locals, ping}. El anfitrión es el 1.
var peers: Dictionary = {}
var local_ip := ""
var external_ip := ""
var upnp_ok := false
var upnp_status := ""
var lag_ms := 0
var loss := 0.0

var _api: SceneMultiplayer
var _enet: ENetMultiplayerPeer
var _upnp: UpnpHelper
var _pending: Dictionary = {}                ## id -> s esperando su HELLO (anfitrión)
var _inbox: Array = []                       ## [ms de entrega, de quién, bytes] (latencia simulada)
var _t_ping := 0.0
var _t_roster := 0.0
var _t_connect := 0.0

func _ready() -> void:
	var la := LaunchArgs.from_cmdline()
	lag_ms = la.get_int("net_lag", 0)
	loss = la.get_float("net_loss", 0.0)
	if la.has("net_name"): player_name = la.get_str("net_name").left(20)   # pruebas: dos copias en el mismo PC
	if player_name == DEFAULT_NAME:                  # nombre del usuario del PC, si no se ha dado otro
		var who := OS.get_environment("USERNAME")
		if who.is_empty(): who = OS.get_environment("USER")
		if not who.is_empty(): player_name = who.left(20)

func is_active() -> bool:
	return state != State.OFF

func is_host() -> bool:
	return state == State.HOSTING

## Abre la sala en el primer puerto libre desde `p_port` (los 8 del código de sala).
func host(p_port: int = RoomCode.BASE_PORT, use_upnp: bool = true) -> Error:
	close()
	var err := ERR_CANT_CREATE
	for k in RoomCode.PORTS:
		_enet = ENetMultiplayerPeer.new()
		err = _enet.create_server(p_port + k, MAX_PLAYERS + 2)   # sitio para poder rechazar con motivo
		if err == OK:
			port = p_port + k
			break
	if err != OK:
		_enet = null
		failed.emit("No se pudo abrir el puerto %d (¿otra copia del juego abierta?)" % p_port)
		return err
	_start_api()
	state = State.HOSTING
	my_id = 1
	accepting = true
	peers = {1: {"name": player_name, "locals": locals, "ping": 0}}
	local_ip = RoomCode.local_ip()
	external_ip = ""
	upnp_ok = false
	upnp_status = "Buscando el router…" if use_upnp else "Sin UPnP"
	if use_upnp:
		_upnp = UpnpHelper.new()
		_upnp.finished.connect(_on_upnp)
		_upnp.open(port)
	hosted.emit(port)
	roster_changed.emit()
	return OK

## Se conecta a una sala. `address` es una IP (v4 o v6) o un nombre de equipo.
func join(address: String, p_port: int = RoomCode.BASE_PORT) -> Error:
	close()
	_enet = ENetMultiplayerPeer.new()
	var err := _enet.create_client(address, p_port)
	if err != OK:
		_enet = null
		failed.emit("Dirección no válida: %s" % address)
		return err
	_start_api()
	var server := _enet.get_peer(1)
	if server != null: server.set_timeout(32, 4000, 8000)
	state = State.CONNECTING
	_t_connect = 0.0
	return OK

## Cierra la sesión (y el puerto del router). `reason` llega a `closed`.
func close(reason: String = "") -> void:
	if state == State.OFF and _enet == null: return
	if _api != null:
		for s in [_api.peer_connected, _api.peer_disconnected, _api.connected_to_server,
				_api.connection_failed, _api.server_disconnected, _api.peer_packet]:
			for c in s.get_connections(): s.disconnect(c.callable)
	if _enet != null: _enet.close()
	if _upnp != null:
		_upnp.close()
		_upnp = null
	_enet = null
	_api = null
	var was := state
	state = State.OFF
	my_id = 0
	peers = {}
	_pending.clear()
	_inbox.clear()
	if was != State.OFF: closed.emit(reason)

## Manda un mensaje de la partida (`type` >= USER) a `to` (0: a todos los demás).
func send(to: int, type: int, data: Variant = null, reliable: bool = true) -> void:
	_send(to, type, data, reliable)

## Códigos para dar a los demás: el de la red de casa y, si UPnP abrió el puerto, el de internet.
func codes() -> Dictionary:
	return {"lan": RoomCode.encode(local_ip, port) if local_ip != "" else "",
		"internet": RoomCode.encode(external_ip, port) if upnp_ok else ""}

## Anfitrión: cuántos jugadores lleva un PC (los puestos que ocupa en la selección). Cuenta
## para dejar entrar a otro PC y sale en la lista de conectados.
func set_locals(id: int, n: int) -> void:
	if state != State.HOSTING or not peers.has(id) or int(peers[id].locals) == n: return
	peers[id].locals = n
	if id == 1: locals = n
	_send_roster()
	roster_changed.emit()

func player_count() -> int:
	var n := 0
	for id in peers: n += int(peers[id].locals)
	return n

# ---------------------------------------------------------------- interno

func _start_api() -> void:
	_api = SceneMultiplayer.new()
	_api.server_relay = false                       # todo pasa por el anfitrión
	_api.root_path = get_path()                     # sin ella descarta los paquetes (no usamos RPC)
	_api.multiplayer_peer = _enet
	_api.peer_connected.connect(_on_peer_connected)
	_api.peer_disconnected.connect(_on_peer_disconnected)
	_api.connected_to_server.connect(_on_connected)
	_api.connection_failed.connect(_on_connection_failed)
	_api.server_disconnected.connect(func() -> void: _end_later("El anfitrión ha cerrado la sala", false))
	_api.peer_packet.connect(_on_packet)

func _process(delta: float) -> void:
	if _api == null: return
	_api.poll()
	if _api == null: return                          # una señal del poll pudo cerrar la sesión
	var now := Time.get_ticks_msec()
	while not _inbox.is_empty() and int(_inbox[0][0]) <= now:
		var m: Array = _inbox.pop_front()
		_handle(int(m[1]), m[2])
		if _api == null: return
	match state:
		State.CONNECTING:
			_t_connect += delta
			if _t_connect > CONNECT_TIMEOUT:
				var f := "No responde nadie en esa dirección"
				close()
				failed.emit(f)
		State.HOSTING:
			for id in _pending.keys():
				_pending[id] += delta
				if _pending[id] > HELLO_TIMEOUT:
					_pending.erase(id)
					_api.disconnect_peer(id)
			_t_ping += delta
			if _t_ping >= PING_EVERY:
				_t_ping = 0.0
				for id in peers:
					if id != 1: _send(id, Msg.PING, Time.get_ticks_msec(), false)
			_t_roster += delta
			if _t_roster >= ROSTER_EVERY:
				_t_roster = 0.0
				_send_roster()
				roster_changed.emit()                    # el anfitrión también enseña los pings nuevos

func _on_peer_connected(id: int) -> void:
	if state == State.HOSTING:
		_pending[id] = 0.0
		var p := _enet.get_peer(id)
		if p != null: p.set_timeout(32, 4000, 8000)

func _on_peer_disconnected(id: int) -> void:
	_pending.erase(id)
	if state == State.HOSTING and peers.has(id):
		peers.erase(id)
		_send_roster()
		roster_changed.emit()

func _on_connected() -> void:
	_send(1, Msg.HELLO, {"proto": protocol, "name": player_name, "locals": locals}, true)

func _on_connection_failed() -> void:
	_end_later("No se pudo conectar con el anfitrión", true)

## Cierra en el siguiente fotograma: las señales llegan dentro del poll de ENet, y cerrar la
## conexión ahí mismo no es seguro. `as_failure`: avisa con `failed` (no llegó a entrar).
func _end_later(reason: String, as_failure: bool) -> void:
	var go := func() -> void:
		close("" if as_failure else reason)
		if as_failure: failed.emit(reason)
	go.call_deferred()

func _on_upnp(ok: bool, ext: String, msg: String) -> void:
	upnp_ok = ok
	external_ip = ext
	upnp_status = msg
	upnp_done.emit(ok, msg)

func _on_packet(from: int, bytes: PackedByteArray) -> void:
	if bytes.size() < 2: return
	if lag_ms > 0 or loss > 0.0:
		if bytes[1] == 0 and randf() < loss: return      # no fiable: se pierde
		_inbox.append([Time.get_ticks_msec() + lag_ms, from, bytes])
		return
	_handle(from, bytes)

func _send(to: int, type: int, data: Variant, reliable: bool) -> void:
	if _api == null: return
	var b := PackedByteArray([type, 1 if reliable else 0])
	b.append_array(var_to_bytes(data))
	_api.send_bytes(b, to, MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)

func _handle(from: int, bytes: PackedByteArray) -> void:
	var type := bytes[0]
	var data: Variant = bytes_to_var(bytes.slice(2))          # sin objetos: no ejecuta nada ajeno
	if type >= USER:
		if state == State.HOSTING and not peers.has(from): return   # sin presentarse, nada
		message.emit(from, type, data)
		return
	match type:
		Msg.HELLO: if state == State.HOSTING: _on_hello(from, data)
		Msg.WELCOME:
			if state == State.CONNECTING and data is Dictionary:
				my_id = _api.get_unique_id()
				state = State.CONNECTED
				joined.emit()
		Msg.REJECT:
			_end_later(String(data) if data is String else "El anfitrión no te ha dejado entrar", true)
		Msg.ROSTER:
			if state == State.CONNECTED and data is Dictionary:
				peers = data
				roster_changed.emit()
		Msg.PING: _send(from, Msg.PONG, data, false)
		Msg.PONG:
			if state == State.HOSTING and peers.has(from) and data is int:
				var rtt := Time.get_ticks_msec() - int(data)
				var old := int(peers[from].ping)
				peers[from].ping = rtt if old <= 0 else roundi(lerpf(old, rtt, 0.3))

func _on_hello(from: int, data: Variant) -> void:
	if not _pending.has(from): return
	_pending.erase(from)
	var why := ""
	if not data is Dictionary or int(data.get("proto", -1)) != PROTOCOL:
		why = "Versión distinta del juego: actualizad los dos a la misma"
	elif not accepting:
		why = "La partida ya ha empezado: espera a que vuelvan a la sala"
	elif player_count() + 1 > MAX_PLAYERS:                       # con sitio para uno: los demás se unen en la selección
		why = "La sala está llena"
	if why != "":
		_send(from, Msg.REJECT, why, true)
		var kick := func() -> void:
			if _api != null and _api.get_peers().has(from): _api.disconnect_peer(from)
		get_tree().create_timer(0.3).timeout.connect(kick)   # que llegue el motivo antes de cortar
		return
	peers[from] = {"name": String(data.get("name", "Jugador")).left(20), "locals": 1, "ping": 0}
	_send(from, Msg.WELCOME, {"id": from}, true)
	_send_roster()
	roster_changed.emit()

func _send_roster() -> void:
	for id in peers:
		if id != 1: _send(id, Msg.ROSTER, peers, true)

func _exit_tree() -> void:
	close()
