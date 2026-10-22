extends GutTest
## Partida en red (hito 9.3a): interpolación, formato de las fotos y una partida mínima con
## anfitrión e invitada en el mismo proceso (cada una con su mundo y sus jugadores).

const PORT := 24712

## Lo que NetGame usa de la partida (game.gd).
class FakeGame extends Node3D:
	var players: Array[Player] = []
	var director: WaveDirector
	var world: CombatWorld
	var kills := 0
	var won := false
	func _init() -> void:
		world = CombatWorld.new()
		add_child(world)
		var roots := Node3D.new()
		roots.name = "Enemies"
		add_child(roots)
		director = WaveDirector.new()
		director.mirror = true                       # en el test no aparece nadie solo
		director.world = world
		add_child(director)
	func add_player(index: int, remote: bool) -> Player:
		var q := Player.new().setup(load("res://data/characters/dyer.tres"), PlayerInput.new(), Color.WHITE)
		q.index = index
		q.remote = remote
		q.world = world
		q.god = true
		add_child(q)
		world.add_player(q)
		players.append(q)
		return q

# ---------------------------------------------------------------- NetInterp

func test_interpola_entre_dos_fotos() -> void:
	var ip := NetInterp.new()
	ip.push("a", 1000.0, [0.0])
	ip.push("a", 1050.0, [10.0])
	var s := ip.sample("a", 1025.0)
	assert_eq(s.size(), 3)
	assert_almost_eq(lerpf(s[0][0], s[1][0], s[2]), 5.0, 0.001)
	s = ip.sample("a", 2000.0)                       # pasada la última, la última
	assert_eq(s[1][0], 10.0)
	assert_eq(s[2], 0.0)
	s = ip.sample("a", 0.0)                          # antes de la primera, la primera
	assert_eq(s[0][0], 0.0)
	assert_eq(ip.sample("b", 1000.0), [])

func test_fotos_fuera_de_orden_y_repetidas() -> void:
	var ip := NetInterp.new()
	ip.push("a", 1100.0, [2.0])
	ip.push("a", 1000.0, [0.0])                      # llega después, pero es anterior
	ip.push("a", 1050.0, [1.0])
	ip.push("a", 1050.0, [99.0])                     # repetida: se ignora
	var t: Array = ip.tracks["a"]
	assert_eq(t.map(func(x: Array) -> float: return x[0]), [1000.0, 1050.0, 1100.0])
	assert_eq(ip.sample("a", 1075.0)[0][0], 1.0)

func test_el_reloj_se_queda_con_el_retraso_mas_corto() -> void:
	var ip := NetInterp.new()
	# el otro PC va 5000 ms por delante; sus paquetes tardan 40 ms y a veces 90
	for k in 200:
		var sent := 5000.0 + k * 50.0
		var delay := 90.0 if k % 4 == 0 else 40.0
		ip.observe(sent, sent - 5000.0 + delay)
	assert_almost_eq(ip.offset, 5000.0 - 40.0, 12.0)
	assert_almost_eq(ip.render_ms(1000.0), 1000.0 + ip.offset - NetInterp.DELAY_MS, 0.001)

func test_quita_las_pistas_viejas() -> void:
	var ip := NetInterp.new()
	ip.push("viejo", 1000.0, [0.0])
	ip.push("nuevo", 4000.0, [0.0])
	ip.prune(4100.0)
	assert_false(ip.tracks.has("viejo"))
	assert_true(ip.tracks.has("nuevo"))

# ---------------------------------------------------------------- formato

func test_jugador_ida_y_vuelta() -> void:
	var g := FakeGame.new()
	add_child_autofree(g)
	var q := g.add_player(2, false)
	q.global_position = Vector3(12.34, 0, -7.5)
	q.motor.facing = Vector3(1, 0, 0)
	q.motor.velocity = Vector3(-3.2, 0, 1.5)
	q.dodge_count = 300
	q.health = 87.25
	q.sanity = 41.0
	var s := StreamPeerBuffer.new()
	NetGame.write_player(s, q)
	assert_eq(s.data_array.size(), 16)
	s.seek(0)
	var r := NetGame.read_player(s)
	assert_eq(r[0], 2)
	var v: Array = r[1]
	assert_almost_eq(v[0], 12.34, 0.006)
	assert_almost_eq(v[1], -7.5, 0.006)
	assert_almost_eq(angle_difference(v[2], PI / 2.0), 0.0, 0.03)
	assert_almost_eq(v[3], -3.2, 0.006)
	assert_almost_eq(v[4], 1.5, 0.006)
	assert_eq(v[5], 300 & 255)
	assert_almost_eq(v[6], 87.3, 0.051)
	assert_almost_eq(v[7], 41.0, 0.051)

func test_enemigo_ida_y_vuelta() -> void:
	var world := CombatWorld.new()
	autofree(world)
	var e := Enemy.new().setup(load("res://data/enemies/pinguino.tres"), world, null)
	autofree(e)
	e.position = Vector3(-30.5, 1.25, 44.0)
	e.facing = Vector3(0, 0, -1)
	e.anim_t = 0.75
	e.health = e.data.max_health * 0.5
	e._burn_t = 2.0
	var s := StreamPeerBuffer.new()
	NetGame.write_enemy(s, 513, e, 7)
	assert_eq(s.data_array.size(), 13)
	s.seek(0)
	var r := NetGame.read_enemy(s)
	assert_eq(r[0], 513)
	var v: Array = r[1]
	assert_almost_eq(v[0], -30.5, 0.006)
	assert_almost_eq(v[1], 1.25, 0.006)
	assert_almost_eq(v[2], 44.0, 0.006)
	assert_almost_eq(absf(angle_difference(v[3], PI)), 0.0, 0.03)
	assert_eq(v[4], 7)
	assert_almost_eq(v[5], 0.75, 0.005)
	assert_almost_eq(v[6], 0.5, 0.005)
	assert_eq(int(v[7]) & 8, 8, "arde")

# ---------------------------------------------------------------- partida mínima

var host: NetSession
var guest: NetSession

func _until(cond: Callable, timeout: float = 4.0) -> bool:
	var t := 0.0
	while not cond.call() and t < timeout:
		await get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	return cond.call()

func after_each() -> void:
	if guest != null: guest.close()
	if host != null: host.close()
	GameSession.clear()

func test_el_invitado_ve_los_enemigos_y_el_anfitrion_al_invitado() -> void:
	host = NetSession.new()
	add_child_autofree(host)
	assert_eq(host.host(PORT, false), OK)
	guest = NetSession.new()
	add_child_autofree(guest)
	guest.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return guest.state == NetSession.State.CONNECTED))
	for k in 2:                                       # J1 del anfitrión, J2 de la invitada
		var seat := GameSession.Seat.new()
		seat.slot = k
		seat.peer = 1 if k == 0 else guest.my_id
		GameSession.seats.append(seat)
	GameSession.online = true
	var hg := FakeGame.new()
	var gg := FakeGame.new()
	add_child_autofree(hg)
	add_child_autofree(gg)
	var h1 := hg.add_player(0, false)
	var h2 := hg.add_player(1, true)
	var g1 := gg.add_player(0, true)
	var g2 := gg.add_player(1, false)
	var hn := NetGame.new(hg, host)
	hn.pause_tree = false
	hg.add_child(hn)
	var gn := NetGame.new(gg, guest)
	gn.pause_tree = false
	gg.add_child(gn)
	assert_true(await _until(func() -> bool: return hn.started and gn.started), "los dos arrancan")
	# un enemigo aparece en el anfitrión: la invitada tiene su marioneta
	hg.world.freeze_t = 1e6                           # quieto: lo mueve el test
	var e := Enemy.new().setup(load("res://data/enemies/pinguino.tres"), hg.world, null)
	e.position = Vector3(3, 0, 4)
	hg.get_node("Enemies").add_child(e)
	hg.director.enemy_spawned.emit(e)
	assert_true(await _until(func() -> bool: return gn._enemies.size() == 1), "llega la marioneta")
	var p: Enemy = gn._enemies.values()[0]
	assert_true(p.puppet)
	# se mueve en el anfitrión y la marioneta lo sigue (con el retraso de la interpolación)
	e.position = Vector3(8, 0, -2)
	assert_true(await _until(func() -> bool: return p.position.distance_to(Vector3(8, 0, -2)) < 0.02), "la marioneta lo sigue")
	# los jugadores: cada uno ve al del otro donde está
	h1.global_position = Vector3(-5, 0, 6)
	g2.global_position = Vector3(2, 0, -9)
	g2.health = 33.0
	assert_true(await _until(func() -> bool: return g1.global_position.distance_to(Vector3(-5, 0, 6)) < 0.02), "la invitada ve al J1")
	assert_true(await _until(func() -> bool: return h2.global_position.distance_to(Vector3(2, 0, -9)) < 0.02), "el anfitrión ve al J2")
	assert_almost_eq(h2.health, 33.0, 0.05, "la vida del J2 la manda su PC")
	# muere en el anfitrión: la marioneta muere también
	e.take_damage(Damage.new(1e6, 0.0))
	var pw := weakref(p)
	p = null
	assert_true(await _until(func() -> bool: return gn._enemies.is_empty() and pw.get_ref() == null), "la marioneta muere")
	# el nivel se supera en el anfitrión: también en la invitada
	hg.director.level_completed.emit()
	assert_true(await _until(func() -> bool: return gg.director.completed), "nivel superado en los dos")
