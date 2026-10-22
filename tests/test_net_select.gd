extends GutTest
## Selección de personaje en red (hito 9.2): anfitrión y cliente en el mismo proceso, cada
## uno con su SelectState; el anfitrión manda y el cliente copia.

const PORT := 24698                          ## fuera de los del código, para no chocar con una copia abierta

var host: NetSession
var guest: NetSession
var hs: SelectState                           ## estado del anfitrión
var gs: SelectState                           ## copia del invitado
var hsel: NetSelect
var gsel: NetSelect
var pets: Array

func _chars() -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	for id in ["dyer", "olmstead", "legrasse", "johansen"]: out.append(load("res://data/characters/%s.tres" % id))
	return out

func _until(cond: Callable, timeout: float = 3.0) -> bool:
	var t := 0.0
	while not cond.call() and t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time()
	return cond.call()

func before_each() -> void:
	pets = DebugOptions.list_resources("res://data/pets")
	host = NetSession.new()
	host.player_name = "Anfitrión"
	add_child_autofree(host)
	assert_eq(host.host(PORT, false), OK)
	guest = NetSession.new()
	guest.player_name = "Invitada"
	add_child_autofree(guest)
	hs = SelectState.new().setup(_chars(), [], [] as Array[PetData])
	gs = SelectState.new().setup(_chars(), [], [] as Array[PetData])
	hsel = NetSelect.new(host, hs, pets)
	hsel.apply_action = func(peer: int, dev: int, act: String) -> void: hs.act(peer, dev, act)
	add_child_autofree(hsel)
	gsel = NetSelect.new(guest, gs, pets)
	add_child_autofree(gsel)
	hs.join(-1)                                      # el teclado del anfitrión
	guest.join("127.0.0.1", host.port)
	await _until(func() -> bool: return guest.state == NetSession.State.CONNECTED)
	var mine := SelectState.Profile.new()
	mine.unlocked = ["johansen"]
	mine.pets.append(load("res://data/pets/gato.tres"))
	gsel.enter(mine, 0)                              # el mando 0 de la invitada

func after_each() -> void:
	guest.close()
	host.close()

func test_la_invitada_entra_con_su_perfil_y_lo_ven_los_dos() -> void:
	assert_true(await _until(func() -> bool: return hs.seat_of(0, guest.my_id) == 1), "el anfitrión le da el J2")
	assert_true(await _until(func() -> bool: return gs.joined().size() == 2), "la copia tiene a los dos")
	assert_eq(gs.seat_of(0, guest.my_id), 1)
	assert_eq(gs.profile_of(1).name, "Invitada")
	assert_eq(gs.profile_of(0).name, "Anfitrión")
	assert_eq(int(host.peers[guest.my_id].locals), 1, "cuenta sus jugadores")

func test_sus_acciones_llegan_y_vuelven() -> void:
	await _until(func() -> bool: return gs.joined().size() == 2)
	hs.seats[1].character = 3                        # johansen: solo lo tiene ella
	hs.changed.emit()
	assert_true(await _until(func() -> bool: return gs.seats[1] != null and gs.seats[1].character == 3), "la copia lo ve")
	assert_true(gs.can_confirm(1), "en la copia también es suyo")
	gsel.predict(0, "confirm")
	gsel.predict(0, "spin-1")
	assert_true(await _until(func() -> bool: return gs.seats[1].stage == SelectState.Stage.PET and gs.seats[1].spin == -1))
	gsel.predict(0, "right")
	assert_true(await _until(func() -> bool: return gs.seats[1].pet == 1), "su gato")
	gsel.predict(0, "confirm")
	assert_true(await _until(func() -> bool: return gs.seats[1].stage == SelectState.Stage.READY))
	hs.seats[0].character = 3
	assert_false(hs.confirm(0), "D-23 entre PCs (y además no lo tiene)")

func test_el_mapa_abierto_lo_ve_la_invitada() -> void:
	await _until(func() -> bool: return gs.joined().size() == 2)
	hsel.map_open = true
	assert_true(await _until(func() -> bool: return gsel.map_open))
	hsel.map_open = false
	assert_true(await _until(func() -> bool: return not gsel.map_open))

func test_al_empezar_los_dos_preparan_la_misma_partida() -> void:
	await _until(func() -> bool: return gs.joined().size() == 2)
	hs.seats[1].character = 3
	hs.confirm(1)
	var got := []
	gsel.started.connect(func(level: String, players: Array) -> void: got.append([level, players]))
	var players := NetSelect.players_of(hs)
	hsel.start("p1_n2", players)
	assert_false(host.accepting, "ya no entra nadie")
	assert_true(await _until(func() -> bool: return not got.is_empty()))
	assert_eq(got[0][0], "p1_n2")
	assert_eq(got[0][1], players)
	NetSelect.fill_session(got[0][0], got[0][1], guest.my_id, true)
	assert_eq(GameSession.seats.size(), 2)
	assert_false(GameSession.seats[0].is_local(), "el J1 es del anfitrión")
	assert_true(GameSession.seats[1].is_local())
	assert_eq(GameSession.seats[1].character, &"johansen")
	assert_eq(GameSession.seats[1].name, "Invitada")
	assert_eq(GameSession.remote_worn("dyer"), {}, "el vestuario del otro PC viene en la sesión")
	assert_eq(GameSession.remote_worn("johansen"), null, "el suyo está en su partida")
	GameSession.clear()

func test_si_se_va_la_invitada_queda_libre_su_puesto() -> void:
	await _until(func() -> bool: return hs.joined().size() == 2)
	guest.close()
	assert_true(await _until(func() -> bool: return hs.joined().size() == 1), "solo queda el anfitrión")
	assert_eq(hs.profiles.size(), 1)

## Con mucho ping, la invitada ve su acción al momento y no salta hacia atrás cuando llega un
## reparto del anfitrión que aún no la tenía.
func test_la_invitada_ve_lo_suyo_al_momento_aunque_haya_ping() -> void:
	await _until(func() -> bool: return gs.joined().size() == 2 and hs.seat_of(0, guest.my_id) == 1)
	guest.lag_ms = 400                                 # lo que recibe cada uno tarda 0,4 s
	host.lag_ms = 400
	var before: int = gs.seats[1].character
	gsel.predict(0, "right")
	var predicted: int = gs.seats[1].character
	assert_ne(predicted, before, "cambia sin esperar al anfitrión")
	hs.move(0, 1)                                      # el anfitrión cambia lo suyo: reparto sin la acción
	var t := 0.0
	var steady := true
	var stale := false
	while t < 1.6:                                     # llegan repartos viejos y el bueno
		if not gsel._pending.is_empty() and gs.seats[0].character == hs.seats[0].character: stale = true
		await get_tree().process_frame
		t += get_process_delta_time()
		if gs.seats[1].character != predicted: steady = false
	assert_true(stale, "ha llegado un reparto que aún no tenía la acción")
	assert_true(steady, "no ha saltado hacia atrás")
	assert_eq(hs.seats[1].character, predicted, "el anfitrión la ha aplicado")
	assert_eq(gs.seats[0].character, hs.seats[0].character, "y la copia tiene lo del anfitrión")
	assert_true(gsel._pending.is_empty(), "confirmada")
