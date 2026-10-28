class_name NetSelect
extends Node
## Selección de personaje en red (hito 9.2, D-10). El anfitrión lleva el único `SelectState`:
## los invitados le mandan su perfil (lo desbloqueado en su partida) y sus acciones (dispositivo
## y "left", "confirm", "spin1"…), él las aplica con `apply_action` y reparte perfiles y puestos
## cada vez que cambian (como mucho una vez por fotograma).
##
## Los invitados no esperan al viaje de ida y vuelta: aplican su acción en su copia al pulsar
## (`predict`) y la numeran. El anfitrión devuelve en cada reparto el número de la última que
## ha aplicado de cada PC (`acks`); al llegar, el invitado copia el reparto y vuelve a aplicar
## encima las suyas que aún no estaban (así nada salta hacia atrás con mucho ping).
## Cuando se va un PC, sus puestos quedan libres. Al elegir nivel, el anfitrión manda START
## con los jugadores y cada PC llena su `GameSession` con `fill_session`. Un PC que vuelve con
## la partida empezada (hito 9.5a) espera aquí sin entrar en la sala; su START llega al pasar
## de nivel y trae además el progreso de cada jugador (carry, team_xp, team_turn).

signal map_changed(open: bool)               ## el anfitrión abre o cierra el mapa de niveles
signal started(level: String, players: Array)
signal late_info(where: String, goal: String)  ## quien vuelve (hito 9.5a): nivel y objetivo de la partida

const PROFILE := NetSession.USER             ## invitado -> anfitrión: su perfil
const ACTION := NetSession.USER + 1          ## invitado -> anfitrión: [dispositivo, acción, número]
const PROFILES := NetSession.USER + 2        ## anfitrión -> todos: perfiles de cada PC
const SEATS := NetSession.USER + 3           ## anfitrión -> todos: {seats, map, acks}
## Acciones que no cambian nada (solo se ven en el PC que las pulsa): no se mandan.
const LOCAL_ONLY := ["cursor-1", "cursor1", "shake", "exit"]
const START := NetSession.USER + 4           ## anfitrión -> todos: {level, players}
const LATE := NetSession.USER + 5            ## anfitrión -> quien vuelve, cada segundo: [nivel, objetivo]

var net: NetSession
var state: SelectState
var all_pets: Array = []
## Anfitrión: aplica una acción de un invitado, (peer, dispositivo, acción) -> void.
var apply_action: Callable
var map_open := false:
	set(v):
		if v == map_open: return
		map_open = v
		_seats_dirty = true
		map_changed.emit(v)
var _profiles_dirty := false
var _seats_dirty := false
var _acks := {}                              ## anfitrión: PC -> número de su última acción aplicada
var _seq := 0                                ## invitado: número de la última acción mandada
var _pending: Array = []                     ## invitado: [número, dispositivo, acción] sin confirmar

func _init(p_net: NetSession, p_state: SelectState, p_all_pets: Array) -> void:
	net = p_net
	state = p_state
	all_pets = p_all_pets

func _ready() -> void:
	net.message.connect(_on_message)
	net.roster_changed.connect(_on_roster)
	if is_host():
		state.changed.connect(func() -> void: _seats_dirty = true)
		(state.profiles[SelectState.LOCAL] as SelectState.Profile).name = net.player_name

func is_host() -> bool:
	return net.is_host()

func my_peer() -> int:
	return net.my_id

## Invitado: se presenta con su perfil y une su primer dispositivo.
func enter(profile: SelectState.Profile, device: int) -> void:
	profile.name = net.player_name
	net.send(1, PROFILE, profile.to_wire())
	predict(device, "join")

## Invitado: aplica la acción en su copia y la manda al anfitrión. Devuelve lo que solo se
## ve aquí (como `SelectState.act`); eso no se manda, porque no cambia nada.
func predict(device: int, act: String) -> String:
	var fb := state.act(net.my_id, device, act)
	if fb in LOCAL_ONLY: return fb
	_seq += 1
	_pending.append([_seq, device, act])
	net.send(1, ACTION, [device, act, _seq])
	return fb

## Anfitrión: empieza el nivel. Ya no entra nadie más (D-10).
func start(level: String, players: Array) -> void:
	net.accepting = false
	_flush()
	net.send(0, START, {"level": level, "players": players})

func _process(_delta: float) -> void:
	_flush()

func _flush() -> void:
	if not is_host(): return
	if _profiles_dirty:
		_profiles_dirty = false
		net.send(0, PROFILES, state.profiles_to_wire())
		_seats_dirty = true                         # los puestos dependen de los perfiles
	if _seats_dirty:
		_seats_dirty = false
		net.send(0, SEATS, {"seats": state.seats_to_wire(), "map": map_open, "acks": _acks.duplicate()})
		for id in net.peers: net.set_locals(id, state.seats_of(id).size())

func _on_message(from: int, type: int, data: Variant) -> void:
	if is_host():
		match type:
			PROFILE:
				var pr := SelectState.Profile.from_wire(data, all_pets)
				pr.name = String(net.peers.get(from, {}).get("name", pr.name))
				state.add_profile(from, pr)
				_profiles_dirty = true
			ACTION:
				if not state.profiles.has(from) or not data is Array or (data as Array).size() != 3: return
				if not (data[0] is int and data[1] is String and data[2] is int): return
				_acks[from] = int(data[2])                # contada aunque no se aplique (mapa abierto)
				_seats_dirty = true
				apply_action.call(from, int(data[0]), String(data[1]))
		return
	if from != 1: return
	match type:
		LATE: if data is Array and (data as Array).size() == 2: late_info.emit(String(data[0]), String(data[1]))
		PROFILES: state.profiles_from_wire(data, all_pets)
		SEATS:
			if not data is Dictionary: return
			var acks: Variant = data.get("acks", {})
			var done := int((acks as Dictionary).get(net.my_id, 0)) if acks is Dictionary else 0
			while not _pending.is_empty() and int(_pending[0][0]) <= done: _pending.pop_front()
			map_open = bool(data.get("map", false))
			state.seats_from_wire(data.get("seats"))
			for p: Array in _pending: state.act(net.my_id, int(p[1]), String(p[2]))   # las que aún no estaban
		START:
			if not data is Dictionary: return
			var carry: Variant = data.get("carry")
			started.emit(String(data.get("level", "")), data.get("players", []) as Array)   # llena GameSession
			if carry is Array:                         # vuelve a una partida empezada: con su progreso
				GameSession.carry = (carry as Array).duplicate(true)
				GameSession.team_xp = float(data.get("team_xp", 0.0))
				GameSession.team_turn = int(data.get("team_turn", 0))
			net.late = false

## Anfitrión: quien ya no está en la sala deja sus puestos.
func _on_roster() -> void:
	if not is_host(): return
	for peer in state.profiles.keys():
		if peer != SelectState.LOCAL and not net.peers.has(peer):
			state.remove_peer(peer)
			_acks.erase(peer)
			_profiles_dirty = true

## Jugadores para la partida: lo que manda START (y lo que usa la partida en local).
static func players_of(st: SelectState) -> Array:
	var out := []
	for i in st.joined():
		var s: SelectState.Seat = st.seats[i]
		var pet: PetData = st.pets_of(i)[s.pet] if s.pet < st.pets_of(i).size() else null
		out.append({"slot": i, "peer": s.peer, "device": s.device, "character": String(st.characters[s.character].id),
			"pet": String(pet.id) if pet else "", "worn": s.worn.duplicate(), "name": st.profile_of(i).name,
			"shop": st.profile_of(i).shop.duplicate()})
	return out

## Llena `GameSession` con los jugadores (de `players_of` o de START). `me`: el PC que juega
## (el GUID del mando solo se sabe de los de este PC).
static func fill_session(level: String, players: Array, me: int, online: bool) -> void:
	GameSession.clear()
	GameSession.level = StringName(level)
	GameSession.online = online
	GameSession.my_peer = me
	for d: Variant in players:
		if not d is Dictionary: continue
		var seat := GameSession.Seat.new()
		seat.slot = int(d.get("slot", 0))
		seat.peer = int(d.get("peer", 1))
		seat.device = int(d.get("device", -1))
		seat.character = StringName(String(d.get("character", "dyer")))
		seat.pet = StringName(String(d.get("pet", "")))
		seat.worn = (d.get("worn", {}) as Dictionary).duplicate() if d.get("worn", {}) is Dictionary else {}
		seat.name = String(d.get("name", ""))
		seat.shop = SelectState.Profile.clean_shop(d.get("shop", {}))
		if seat.is_local() and (seat.device == Devices.KEYBOARD or JoypadInput.pads().has(seat.device)):
			seat.guid = Devices.guid(seat.device)
		GameSession.seats.append(seat)
