extends GutTest
## Partida en red (hito 9.3a): interpolación, formato de las fotos y una partida mínima con
## anfitrión e invitada en el mismo proceso (cada una con su mundo y sus jugadores).

const PORT := 24712

## Lo que NetGame usa de la partida (game.gd).
class FakeGame extends Node3D:
	var players: Array[Player] = []
	var director: WaveDirector
	var world: CombatWorld
	var gems: GemManager
	var kills := 0
	var won := false
	var ng: NetGame                                  ## la suya (paradas del anfitrión)
	var halts: Array = []
	var resumes: Array = []
	var picks: Array = []
	func net_halt(d: Dictionary) -> void: halts.append(d)
	func net_resume(d: Dictionary) -> void: resumes.append(d)
	func net_picked(i: int, d: Dictionary) -> void: picks.append([i, d])
	func net_pause_asked(peer: int, on: bool) -> void:
		if on: ng.halt_all({"k": "pause", "peer": peer})
		else: ng.resume_all()
	func _init() -> void:
		world = CombatWorld.new()
		add_child(world)
		gems = GemManager.new()
		gems.world = world
		gems.rules = load("res://data/progression/default.tres")
		world.add_child(gems)
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
	q.revive_progress = q.rules.revive_time * 0.5
	var s := StreamPeerBuffer.new()
	NetGame.write_player(s, q)
	assert_eq(s.data_array.size(), 17)
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
	assert_almost_eq(v[9], 0.5, 0.005, "reanimación a medias")

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
	e.set_guard_ring(true)
	var s := StreamPeerBuffer.new()
	NetGame.write_enemy(s, 513, e, 7)
	assert_eq(s.data_array.size(), 15)
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
	assert_eq(v[8], 50, "daña al tocar, lo normal")
	assert_eq(int(v[9]) & 2, 2, "con el anillo de los guardianes")
	var m := Enemy.new().setup(load("res://data/enemies/pinguino.tres"), world, null)
	autofree(m)
	m.net_apply_flags2(int(v[9]))
	assert_not_null(m.guard_ring, "la marioneta lo pone")
	m.net_apply_flags2(0)
	assert_null(m.guard_ring, "y lo quita")

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
	# una bala enemiga nace en el anfitrión: la invitada la tiene, ya adelantada lo que haya volado
	hg.world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, Vector3(20, 0, 20), Vector3(1, 0, 0),
		0.15, 0.3, Damage.new(7, 2), 5.0)
	assert_true(await _until(func() -> bool: return gg.world.bullets.count == 1), "llega la bala")
	assert_almost_eq(gg.world.bullets._phys[0], 7.0, 0.01)
	assert_almost_eq(gg.world.bullets._ment[0], 2.0, 0.01)
	assert_almost_eq(gg.world.bullets._pos[0].z, 20.0, 0.01)
	assert_gt(gg.world.bullets._pos[0].x, 20.0, "sale adelantada")
	# gemas: las suelta el anfitrión y la invitada las ve con el mismo id y en el mismo sitio
	hg.gems.drop(Vector3(30, 0, 30), 12.0, 2)
	assert_true(await _until(func() -> bool: return gg.gems.count == hg.gems.count), "las mismas gemas")
	assert_eq(gg.gems._id[0], hg.gems._id[0])
	for k in 90: await get_tree().physics_frame          # que caigan
	var land := func(gm: GemManager, id: int) -> Vector3:
		for i in gm.count: if gm._id[i] == id: return gm._pos[i]
		return Vector3.INF
	var id1: int = hg.gems._id[1]
	assert_lt(land.call(gg.gems, id1).distance_to(land.call(hg.gems, id1)), 0.01, "misma semilla, mismos saltos")
	hg.gems._remove(0)
	hg.gems.collected.emit(gg.gems._id[0])
	assert_true(await _until(func() -> bool: return gg.gems.count == hg.gems.count), "la recogida llega")
	# un golpe en un círculo del anfitrión: daña a la J2 en su PC (y el anfitrión no la toca)
	g2.god = false
	var before := g2.health
	var hit := Damage.new(10.0, 0.0)
	hg.world.strike(Vector3(2, 0, -9), 1.5, hit)
	assert_true(await _until(func() -> bool: return g2.health < before), "el golpe llega a la invitada")
	assert_true(await _until(func() -> bool: return absf(h2.health - g2.health) < 0.05), "y el anfitrión ve su vida")
	# un aviso de enemigo se repite; uno de un arma no
	hg.world.fx.add_child(Telegraph.enemy(2.0, 1.5, Color.RED))
	var tgs := func() -> int: return gg.world.fx.get_children().filter(func(n: Node) -> bool: return n is Telegraph).size()
	assert_true(await _until(func() -> bool: return tgs.call() == 1), "llega el aviso")
	hg.world.fx.add_child(Telegraph.new().setup(2.0, 1.5, Color.RED))
	for k in 20: await get_tree().physics_frame
	assert_eq(tgs.call(), 1, "el de un arma no viaja")
	# un rompible: aparece en los dos y, al romperlo el anfitrión, se rompe en la invitada
	var b := Breakable.new().setup(hg.world, Vector3(10, 0, 10))
	hg.world.fx.add_child(b)
	var gb := func() -> Array: return gg.world.fx.get_children().filter(func(n: Node) -> bool: return n is Breakable and not n.is_queued_for_deletion())
	assert_true(await _until(func() -> bool: return gb.call().size() == 1), "llega el rompible")
	var mb: Breakable = gb.call()[0]
	assert_true(mb.mirror)
	assert_eq(mb.model_index, b.model_index)
	mb.take_damage(Damage.new(1000.0, 0.0))
	assert_true(mb.is_alive(), "en la invitada no se rompe solo")
	b.take_damage(Damage.new(1000.0, 0.0))
	assert_true(await _until(func() -> bool: return gb.call().is_empty()), "se rompe en la invitada")
	# comida: la recoge la J2 (lo decide el anfitrión) y la cura su PC
	for n in hg.world.fx.get_children(): if n is Pickup: n.queue_free()      # la del rompible, fuera
	await get_tree().physics_frame
	var food := Pickup.new().setup(hg.world, Vector3(12, 0, 12), Pickup.Kind.FOOD)
	hg.world.fx.add_child(food)
	var gp := func() -> Array: return gg.world.fx.get_children().filter(func(n: Node) -> bool: return n is Pickup and not n.is_queued_for_deletion())
	assert_true(await _until(func() -> bool: return gp.call().size() >= 1), "llega la comida")
	var hp := g2.health
	g2.global_position = Vector3(12, 0, 12)
	assert_true(await _until(func() -> bool: return g2.health > hp), "la J2 la recoge y se cura")
	# el nivel se supera en el anfitrión: también en la invitada
	hg.director.level_completed.emit()
	assert_true(await _until(func() -> bool: return gg.director.completed), "nivel superado en los dos")

func test_el_progreso_viaja_entero() -> void:
	var g := FakeGame.new()
	add_child_autofree(g)
	var a := g.add_player(0, false)
	var b := g.add_player(1, true)
	for q in [a, b]:
		q.weapons = WeaponSystem.new().setup(q, g.world)
		q.add_child(q.weapons)
	a.weapons.add_weapon(load("res://data/weapons/webly.tres")).level = 3
	a.weapons.add_weapon(load("res://data/weapons/granada.tres"))
	a.progress.level = 6
	a.progress.passives = {"iman": 2}
	a.attrs["speed"] = 17
	a.shop = Shop.DEFAULTS.duplicate()
	a.shop["health"] = 1.3
	b.weapons.add_weapon(load("res://data/weapons/machete.tres"))
	var d := NetGame.progress_of(a)
	var copy: Dictionary = bytes_to_var(var_to_bytes(d))      # como llega por la red
	assert_true(NetGame.apply_progress(b, copy), "ha subido de nivel")
	assert_eq(b.progress.level, 6)
	assert_eq(b.weapons.weapons.map(func(w: WeaponSystem.Weapon) -> String: return String(w.data.id)), ["webly", "granada"])
	assert_eq(b.weapons.get_weapon(&"webly").level, 3)
	assert_eq(b.progress.passives, {"iman": 2})
	assert_eq(int(b.attrs["speed"]), 17)
	assert_almost_eq(float(b.shop["health"]), 1.3, 0.001)
	assert_false(NetGame.apply_progress(b, copy), "lo mismo otra vez: sin subida")

func test_paradas_para_todos() -> void:
	host = NetSession.new()
	add_child_autofree(host)
	assert_eq(host.host(PORT + 1, false), OK)
	guest = NetSession.new()
	add_child_autofree(guest)
	guest.join("127.0.0.1", host.port)
	assert_true(await _until(func() -> bool: return guest.state == NetSession.State.CONNECTED))
	for k in 3:                                       # J1 del anfitrión; J2 y J3 de la invitada (J3, un bot)
		var seat := GameSession.Seat.new()
		seat.slot = k
		seat.peer = 1 if k == 0 else guest.my_id
		GameSession.seats.append(seat)
	GameSession.online = true
	var hg := FakeGame.new()
	var gg := FakeGame.new()
	add_child_autofree(hg)
	add_child_autofree(gg)
	hg.add_player(0, false)
	var h2 := hg.add_player(1, true)
	var h3 := hg.add_player(2, true)
	gg.add_player(0, true)
	var g2 := gg.add_player(1, false)
	var g3 := gg.add_player(2, false)
	g3.input = BotInput.new("circle")
	for q in [h2, g2]:
		q.weapons = WeaponSystem.new().setup(q, q.world)
		q.add_child(q.weapons)
		q.weapons.add_weapon(load("res://data/weapons/webly.tres"))
	var hn := NetGame.new(hg, host)
	hn.pause_tree = false
	hg.ng = hn
	hg.add_child(hn)
	var gn := NetGame.new(gg, guest)
	gn.pause_tree = false
	gg.add_child(gn)
	assert_true(await _until(func() -> bool: return hn.started and gn.started), "los dos arrancan")
	assert_true(hn.is_remote_bot(h3), "el anfitrión sabe que al J3 lo lleva un bot")
	assert_false(hn.is_remote_bot(h2))
	# la invitada pide la pausa: se para en los dos, puesta por ella
	gn.ask_pause(true)
	assert_true(await _until(func() -> bool: return gg.halts.size() == 1 and hg.halts.size() == 1), "parada en los dos")
	assert_eq(String(gg.halts[0].k), "pause")
	assert_eq(int(gg.halts[0].peer), guest.my_id)
	gn.ask_pause(false)
	assert_true(await _until(func() -> bool: return gg.resumes.size() == 1), "y la quita")
	assert_true(hn.halt.is_empty() and gn.halt.is_empty())
	# lo elegido fuera de una subida no cuenta
	gn.send_pick(g2, g2.progress.option_for("w:webly", g2.weapons))
	for k in 20: await get_tree().physics_frame
	assert_eq(hg.picks.size(), 0)
	# le toca subir a la J2: su PC elige y el anfitrión lo recibe
	hn.halt_all({"k": "lvup", "peer": guest.my_id, "i": 1, "title": "Turno de J2", "attr": "speed"})
	assert_true(await _until(func() -> bool: return gg.halts.size() == 2), "llega la subida")
	assert_eq(int(gg.halts[1].i), 1)
	g2.rerolls_used = 1
	g2.progress.banished["u:iman"] = true
	gn.send_pick(g2, g2.progress.option_for("w:webly", g2.weapons))
	assert_true(await _until(func() -> bool: return hg.picks.size() == 1), "llega lo elegido")
	var d: Dictionary = hg.picks[0][1]
	assert_eq(String(d.key), "w:webly")
	assert_eq(int(d.rerolls), 1)
	assert_eq(Array(d.banished), ["u:iman"])
	hn.resume_all("J2 · Dyer: Webley 2")
	assert_true(await _until(func() -> bool: return gg.resumes.size() == 2), "sigue en los dos")
	assert_eq(String(gg.resumes[1].text), "J2 · Dyer: Webley 2")
	assert_eq(int(gg.resumes[1].peer), guest.my_id, "quien eligió no lo vuelve a anunciar")
	assert_false(bool(gg.resumes[1].all))
	# lo elegido para una subida anterior (llega tarde) no vale para la siguiente
	var old_n := int(gg.halts[1].n)
	hn.halt_all({"k": "lvup", "peer": guest.my_id, "i": 1, "title": "Turno de J2", "attr": ""})
	assert_true(await _until(func() -> bool: return gg.halts.size() == 3), "otra subida")
	assert_ne(int(gg.halts[2].n), old_n)
	guest.send(1, NetGame.PICK, {"n": old_n, "i": 1, "key": "w:webly"})
	for k in 20: await get_tree().physics_frame
	assert_eq(hg.picks.size(), 1, "la tardía no cuenta")
	# el anfitrión elige por ella: el anuncio sale también en su PC
	hn.resume_all("J2 · Dyer: Webley 3 (elegida por el anfitrión)", true)
	assert_true(await _until(func() -> bool: return gg.resumes.size() == 3))
	assert_true(bool(gg.resumes[2].all))

func test_opcion_a_partir_de_su_clave() -> void:
	var g := FakeGame.new()
	add_child_autofree(g)
	var q := g.add_player(0, false)
	q.weapons = WeaponSystem.new().setup(q, g.world)
	q.add_child(q.weapons)
	q.weapons.add_weapon(load("res://data/weapons/webly.tres")).level = 2
	q.progress.weapon_pool.append(load("res://data/weapons/granada.tres"))
	q.progress.upgrade_pool.append(load("res://data/upgrades/iman.tres"))
	var o := q.progress.option_for("w:webly", q.weapons)
	assert_eq(o.kind, PlayerProgress.Option.Kind.WEAPON_LEVEL)
	assert_eq(o.to_level, 3)
	o = q.progress.option_for("w:granada", q.weapons)
	assert_eq(o.kind, PlayerProgress.Option.Kind.NEW_WEAPON)
	q.progress.passives["iman"] = 1
	o = q.progress.option_for("u:iman", q.weapons)
	assert_eq(o.kind, PlayerProgress.Option.Kind.PASSIVE)
	assert_eq(o.to_level, 2)
	assert_eq(PlayerProgress.key_of(o), "u:iman")
	q.weapons.get_weapon(&"webly").level = q.weapons.get_weapon(&"webly").data.max_level
	assert_null(q.progress.option_for("w:webly", q.weapons), "al máximo ya no vale")
	assert_null(q.progress.option_for("w:nada", q.weapons))

func test_flecha_hacia_los_que_no_se_ven() -> void:
	var view := Vector2(1920, 1080)
	assert_null(OffscreenArrows.place(Vector2(900, 500), view), "se ve: sin flecha")
	var at: Array = OffscreenArrows.place(Vector2(3000, 600), view)
	var pos: Vector2 = at[0]
	assert_almost_eq(pos.x, 1920.0 - OffscreenArrows.EDGE, 0.5, "a la derecha, en el borde")
	assert_gt((at[1] as Vector2).x, 0.9, "apunta a la derecha")
	at = OffscreenArrows.place(Vector2(960, -900), view)
	assert_almost_eq((at[0] as Vector2).y, OffscreenArrows.TOP_EDGE, 0.5, "arriba, por debajo de los paneles")
	at = OffscreenArrows.place(Vector2(-500, 2000), view)
	var p: Vector2 = at[0]
	assert_true(p.x >= OffscreenArrows.EDGE - 0.5 and p.y <= 1080.0 - OffscreenArrows.EDGE + 0.5, "esquina: dentro del margen")

func test_color_del_ping() -> void:
	assert_eq(Hud.PlayerPanel.ping_color(40), Hud.PlayerPanel.PING_OK)
	assert_eq(Hud.PlayerPanel.ping_color(180), Hud.PlayerPanel.PING_MID)
	assert_eq(Hud.PlayerPanel.ping_color(400), Hud.PlayerPanel.PING_BAD)
	assert_eq(Hud.PlayerPanel.ping_color(-1), UiKit.TEXT_DIM, "sin conexión")

func test_quien_vuelve_recupera_los_puestos_de_su_pc() -> void:
	GameSession.clear()
	for k in 4:
		var s := GameSession.Seat.new()
		s.slot = k
		s.peer = [1, 50, 50, 60][k]
		s.name = ["Anfitrion", "Ana", "Ana", "Luis"][k]
		GameSession.seats.append(s)
	var connected := {1: {"name": "Anfitrion"}}         # se han ido los dos invitados
	assert_eq(GameSession.departed(connected), {50: "Ana", 60: "Luis"})
	assert_eq(GameSession.claim(70, "Luis", connected), 1, "el del mismo nombre")
	assert_eq(GameSession.claim(71, "Otro", connected), 2, "si no, el primero que quede")
	assert_eq(GameSession.claim(72, "Más", connected), 0, "y no hay más")
	connected[70] = {"name": "Luis"}
	assert_eq(GameSession.apply_returns(connected), [70], "el 71 se fue antes de entrar")
	assert_eq(NetGame.seat_peers(), [1, 50, 50, 70])
	assert_true(GameSession.returning.is_empty())
	var wire := GameSession.seats_to_wire()
	assert_eq(int(wire[3].peer), 70)
	NetGame.apply_seat_peers([1, 80, 80, 70])
	assert_eq(GameSession.seats[1].peer, 80)
	GameSession.clear()
