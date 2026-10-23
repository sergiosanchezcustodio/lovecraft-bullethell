extends GutTest
## Sesión de red (hito 9.1): anfitrión y clientes en el mismo proceso, por la máquina local.

const PORT := 24697                          ## fuera de los del código, para no chocar con una copia abierta

var host: NetSession
var clients: Array[NetSession] = []

func _session(p_name: String) -> NetSession:
	var s := NetSession.new()
	s.player_name = p_name
	add_child_autofree(s)
	return s

func _client(p_name: String) -> NetSession:
	var c := _session(p_name)
	clients.append(c)
	return c

## Espera (hasta `timeout` s) a que se cumpla `cond`.
func _until(cond: Callable, timeout: float = 3.0) -> bool:
	var t := 0.0
	while not cond.call() and t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time()
	return cond.call()

func before_each() -> void:
	clients.clear()
	host = _session("Anfitrión")
	assert_eq(host.host(PORT, false), OK)

func after_each() -> void:
	for c in clients: c.close()
	host.close()

func test_un_cliente_entra_y_los_dos_ven_la_lista() -> void:
	var c := _client("Invitada")
	c.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return c.state == NetSession.State.CONNECTED), "conectada")
	assert_true(await _until(func() -> bool: return c.peers.size() == 2), "la lista llega al cliente")
	assert_eq(host.peers.size(), 2)
	assert_eq(String(host.peers[c.my_id].name), "Invitada")
	assert_eq(String(c.peers[1].name), "Anfitrión")
	assert_eq(host.player_count(), 2)

func test_mensajes_de_la_partida_en_los_dos_sentidos() -> void:
	var c := _client("Invitada")
	c.join("127.0.0.1", host.port)
	await _until(func() -> bool: return c.state == NetSession.State.CONNECTED)
	var got := []
	c.message.connect(func(from: int, type: int, data: Variant) -> void: got.append([from, type, data]))
	host.message.connect(func(from: int, type: int, data: Variant) -> void: got.append([from, type, data]))
	host.send(c.my_id, NetSession.USER, {"nivel": "p1_n1"})
	c.send(1, NetSession.USER + 1, [1, 2, 3], false)
	assert_true(await _until(func() -> bool: return got.size() == 2))
	assert_has(got, [1, NetSession.USER, {"nivel": "p1_n1"}])
	assert_has(got, [c.my_id, NetSession.USER + 1, [1, 2, 3]])

func test_otra_version_se_rechaza_con_motivo() -> void:
	var c := _client("Antigua")
	c.protocol = NetSession.PROTOCOL + 1
	var why := []
	c.failed.connect(func(r: String) -> void: why.append(r))
	c.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return not why.is_empty()), "rechazada")
	assert_string_contains(why[0], "Versión")
	assert_eq(c.state, NetSession.State.OFF)
	assert_eq(host.peers.size(), 1, "no entra en la lista")

func test_sala_llena_con_cuatro_jugadores() -> void:
	host.locals = 2                                  # dos en el PC del anfitrión
	host.peers[1].locals = 2
	var a := _client("Tercera")
	a.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return a.state == NetSession.State.CONNECTED))
	host.set_locals(a.my_id, 2)                      # se le une otro jugador en la selección
	assert_true(await _until(func() -> bool: return int(a.peers.get(a.my_id, {}).get("locals", 0)) == 2), "la lista lo cuenta")
	var b := _client("Sobra")
	var why := []
	b.failed.connect(func(r: String) -> void: why.append(r))
	b.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return not why.is_empty()))
	assert_string_contains(why[0], "llena")
	assert_eq(host.player_count(), 4)

func test_con_la_partida_empezada_no_entra_nadie() -> void:
	host.accepting = false
	var c := _client("Tarde")
	var why := []
	c.failed.connect(func(r: String) -> void: why.append(r))
	c.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return not why.is_empty()))
	assert_string_contains(why[0], "empezado")
	assert_eq(host.peers.size(), 1)

func test_con_la_partida_empezada_entra_quien_vuelve() -> void:
	host.accepting = false
	host.admit = func(_id: int, who: String) -> int: return 2 if who == "Vuelve" else 0
	var c := _client("Vuelve")
	c.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return c.state == NetSession.State.CONNECTED), "entra")
	assert_true(c.late, "y sabe que espera al siguiente nivel")
	assert_eq(int(host.peers[c.my_id].locals), 2, "con los puestos que recupera")
	var d := _client("Otra")
	var why := []
	d.failed.connect(func(r: String) -> void: why.append(r))
	d.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return not why.is_empty()), "los demás, no")
	assert_string_contains(why[0], "empezado")

func test_si_se_va_un_cliente_sale_de_la_lista() -> void:
	var c := _client("Invitada")
	c.join("127.0.0.1", host.port)
	await _until(func() -> bool: return c.state == NetSession.State.CONNECTED)
	assert_eq(host.peers.size(), 2)
	c.close()
	assert_true(await _until(func() -> bool: return host.peers.size() == 1), "el anfitrión se entera")

func test_si_cierra_el_anfitrion_el_cliente_se_entera() -> void:
	var c := _client("Invitada")
	c.join("127.0.0.1", host.port)
	await _until(func() -> bool: return c.state == NetSession.State.CONNECTED)
	var why := []
	c.closed.connect(func(r: String) -> void: why.append(r))
	host.close()
	assert_true(await _until(func() -> bool: return not why.is_empty()))
	assert_string_contains(why[0], "anfitrión")

func test_latencia_simulada_sube_el_ping() -> void:
	var c := _client("Lejana")
	c.lag_ms = 200
	c.join("127.0.0.1", host.port)
	await _until(func() -> bool: return c.state == NetSession.State.CONNECTED)
	assert_true(await _until(func() -> bool: return int(host.peers.get(c.my_id, {}).get("ping", 0)) > 0, 4.0), "ping medido")
	assert_gte(int(host.peers[c.my_id].ping), 200)

func test_nadie_en_la_direccion_falla_sin_colgarse() -> void:
	var c := _client("Perdida")
	var why := []
	c.failed.connect(func(r: String) -> void: why.append(r))
	c.join("127.0.0.1", PORT + 1)                     # ahí no escucha nadie
	assert_true(await _until(func() -> bool: return not why.is_empty(), NetSession.CONNECT_TIMEOUT + 2.0))
	assert_eq(c.state, NetSession.State.OFF)

func test_registro_de_red_en_un_fichero() -> void:
	var lg := NetLog.new()
	lg.dir = "user://logs/red_prueba_registro"
	for f in DirAccess.get_files_at(lg.dir): DirAccess.remove_absolute(lg.dir + "/" + f)
	lg.open("Anfitrión", "Ana, puerto 24680")
	lg.roster({1: {"name": "Ana"}, 7: {"name": "Luis"}}, 1)
	lg.roster({1: {"name": "Ana"}}, 1)
	lg.close("prueba")
	var text := FileAccess.get_file_as_string(lg.path)
	assert_string_contains(text, "Anfitrión · Ana, puerto 24680")
	assert_string_contains(text, "Entra Luis (PC 7)")
	assert_string_contains(text, "Se va Luis (PC 7)")
	assert_string_contains(text, "Fin de la sesión: prueba")
	for k in NetLog.KEEP + 3:                        # se quedan los últimos
		lg.open("Invitado", str(k))
		lg.close()
	assert_eq(DirAccess.get_files_at(lg.dir).size(), NetLog.KEEP)
	for f in DirAccess.get_files_at(lg.dir): DirAccess.remove_absolute(lg.dir + "/" + f)

func test_dos_registros_a_la_vez_no_se_pisan() -> void:
	var a := NetLog.new()
	var b := NetLog.new()
	a.dir = "user://logs/red_prueba_dos"
	b.dir = a.dir
	a.open("Anfitrión", "A")
	b.open("Invitado", "B")
	assert_ne(a.path, b.path)
	a.close()
	b.close()
	assert_false(FileAccess.get_file_as_string(a.path).contains("Invitado"))
	for f in DirAccess.get_files_at(a.dir): DirAccess.remove_absolute(a.dir + "/" + f)
