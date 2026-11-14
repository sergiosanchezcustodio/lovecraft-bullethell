extends GutTest
## Hito 21.10: las criaturas y lo propio de cada nivel de la parte 4, *La búsqueda onírica de la
## desconocida Kadath* (DreamLands). Nivel 1: los zoogs, los gatos de Ulthar y los hongos.

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(id := "dyer", at := Vector3.ZERO) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	p.position = at
	world.add_child(p)
	world.add_player(p)
	return p

func _enemy(id: String, at: Vector3, still := true) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/%s.tres" % id) as EnemyData).duplicate()
	if still:
		d.max_health = 1000.0
		d.move_speed = 0.0
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _dream(level := "p4_n1", host := true) -> DreamLands:
	var dl := DreamLands.new().setup(world, load("res://data/levels/%s.tres" % level), host)
	dl._next = 999.0
	add_child_autofree(dl)
	return dl

func _step(dl: DreamLands, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		dl._physics_process(DT)

# ------------------------------------------------------------------ el nivel

func test_el_nivel_del_bosque() -> void:
	var lv: LevelData = load("res://data/levels/p4_n1.tres")
	var ids := lv.pool.map(func(d: EnemyData) -> String: return String(d.id))
	assert_true(ids.has("zoog") and ids.has("zoog_copas"))
	assert_eq(String(lv.final_enemy.id), "zoog_anciano")
	assert_true(lv.final_enemy.unique)
	assert_gt(lv.cats_every, 0.0)
	assert_gt(lv.mushroom_sanity, 0.0)
	for d: EnemyData in lv.pool:
		assert_true(Anims.script_for(d.model) != null, "%s se anima" % d.model)

# ------------------------------------------------------------------ los zoogs

func test_un_zoog_solo_no_se_atreve() -> void:
	var p := _player("dyer", Vector3.ZERO)
	var e := _enemy("zoog", Vector3(3, 0, 0), false)
	var b := e.behavior as ZoogBehavior
	world.rebuild_grid()
	var v := b.update(e, p, DT)
	assert_false(b.bold, "solo, no")
	assert_gt(v.x, 0.0, "huye: se aparta del jugador")

func test_en_grupo_atacan() -> void:
	var p := _player("dyer", Vector3.ZERO)
	var e := _enemy("zoog", Vector3(5, 0, 0), false)
	for k in 3: _enemy("zoog", Vector3(5.5 + k * 0.6, 0, 1.0), false)
	world.rebuild_grid()
	var b := e.behavior as ZoogBehavior
	b._count_t = 0.0
	var v := b.update(e, p, DT)
	assert_true(b.bold, "con tres más, se atreven")
	assert_eq(b.pack, 4)
	assert_lt(v.x, 0.0, "van a por él")
	assert_gt(v.length(), e.data.move_speed * 1.2, "y deprisa")

func test_el_de_las_copas_cae_con_aviso() -> void:
	var p := _player("dyer", Vector3(2, 0, 2))
	var e := _enemy("zoog_copas", Vector3(10, 0, 10), false)
	var b := e.behavior as ZoogBehavior
	assert_eq(b.state, ZoogBehavior.State.HIDDEN)
	assert_true(e.buried, "escondido arriba: no se le da")
	assert_false(b.touches(e))
	for k in 200:
		b.update(e, p, DT)
		if b.state == ZoogBehavior.State.WARN: break
	assert_eq(b.state, ZoogBehavior.State.WARN, "marca dónde va a caer")
	assert_almost_eq(e.position.x, 2.0, 0.01, "encima del jugador")
	var hp := p.health
	for k in int((float(e.data.param("warn", 1.0)) + ZoogBehavior.FALL_TIME) / DT) + 4: b.update(e, p, DT)
	assert_eq(b.state, ZoogBehavior.State.GROUND)
	assert_false(e.buried)
	assert_lt(p.health, hp, "le cae encima")

func test_lo_que_revela_lo_hace_caer() -> void:
	var e := _enemy("zoog_copas", Vector3(10, 0, 10), false)
	var b := e.behavior as ZoogBehavior
	b.reveal(e)
	assert_eq(b.state, ZoogBehavior.State.GROUND)
	assert_false(e.buried)

# ------------------------------------------------------------------ los gatos de Ulthar

func test_bajan_los_gatos_y_cazan_zoogs() -> void:
	_player("dyer", Vector3(0, 0, 10))
	var dl := _dream()
	assert_eq(dl.cats_from, Vector3(4.5, 0, -31.0), "de la puerta del camino de Ulthar")
	var z := _enemy("zoog", dl.cats_from + Vector3(0, 0, 6), true)
	dl.release_cats(7)
	assert_eq(dl.packs, 1)
	assert_eq(dl.cats.size(), dl.level.cats_count)
	_step(dl, 2.0)
	assert_false(z.is_alive(), "lo atrapan")
	assert_eq(dl.caught, 1)

func test_al_anciano_solo_le_aranan() -> void:
	_player("dyer", Vector3(0, 0, 10))
	var dl := _dream()
	var a := _enemy("zoog_anciano", dl.cats_from + Vector3(0, 0, 4), true)
	var hp := a.health
	dl.release_cats(3)
	_step(dl, 1.5)
	assert_true(a.is_alive())
	assert_lt(a.health, hp, "zarpazos")

func test_vuelven_al_pueblo() -> void:
	var dl := _dream()
	dl.release_cats(5)
	_step(dl, dl.level.cats_life * 1.15 + 1.0)
	assert_eq(dl.cats.size(), 0, "sin zoogs, vuelven y se van")

func test_con_el_gato_de_companero_llegan_antes() -> void:
	var dl := _dream()
	assert_eq(dl.cats_every(), dl.level.cats_every)
	var p := _player("dyer", Vector3.ZERO)
	var pet := Pet.new()
	pet.data = load("res://data/pets/gato.tres")
	p.pet = pet
	assert_almost_eq(dl.cats_every(), dl.level.cats_every * DreamLands.PET_HASTE, 0.01)
	pet.free()

func test_en_el_invitado_los_gatos_llegan_del_anfitrion() -> void:
	var dl := _dream("p4_n1", false)
	dl._next = 0.0
	_step(dl, 0.2)
	assert_eq(dl.packs, 0, "el invitado no decide")
	dl.remote({"a": "cats", "s": 11})
	assert_eq(dl.packs, 1)

# ------------------------------------------------------------------ los hongos

func test_los_hongos_devuelven_cordura() -> void:
	var dl := _dream()
	assert_gt(dl.mushrooms.size(), 0, "los corros de la arena")
	var m: Vector2 = dl.mushrooms[0]
	var p := _player("dyer", Vector3(m.x + 0.5, 0, m.y))
	var far := _player("dyer", Vector3(m.x + 12, 0, m.y))
	p.sanity = 10.0
	far.sanity = 10.0
	assert_true(dl.near_mushroom(p.global_position))
	_step(dl, 1.0)
	assert_almost_eq(p.sanity, 10.0 + dl.level.mushroom_sanity, 0.3)
	assert_almost_eq(far.sanity, 10.0, 0.01, "lejos, nada")

# ------------------------------------------------------------------ nivel 2: la galera negra

func test_el_nivel_del_puerto() -> void:
	var lv: LevelData = load("res://data/levels/p4_n2.tres")
	var ids := lv.pool.map(func(d: EnemyData) -> String: return String(d.id))
	assert_true(ids.has("mercader_leng") and ids.has("remero_lunar"))
	assert_eq(String(lv.final_enemy.id), "bestia_lunar_mayor")
	assert_true(lv.final_enemy.unique)
	assert_gt(lv.galley_every, 0.0)
	assert_eq(String(lv.galley_enemy.id), "remero_lunar")
	assert_eq(String(lv.hatch_enemy.id), "escotilla")
	assert_gt(lv.ruby_chance, 0.0)
	for d: EnemyData in lv.pool + [lv.final_enemy]:
		assert_true(Anims.script_for(d.model) != null, "%s se anima" % d.model)
	for m in ["escotilla", "recompensa_rubi"]:
		assert_true(FileAccess.file_exists("res://models/%s.json" % m), m)

func _puerto() -> Array:
	var made: Array[Enemy] = []
	var dl := _dream("p4_n2")
	dl.spawner = func(d: EnemyData, pos: Vector3) -> Enemy:
		var e := _enemy(String(d.id), pos, false)
		made.append(e)
		return e
	return [dl, made]

func test_la_galera_desembarca_remeros() -> void:
	_player("dyer", Vector3(0, 0, 0))
	var r := _puerto()
	var dl: DreamLands = r[0]
	var made: Array[Enemy] = r[1]
	assert_eq(dl.galley_at, Vector3(2.2, 0, -30.5), "el pie de la pasarela")
	dl._galley_next = 0.0
	_step(dl, 0.1)
	assert_eq(dl.landings, 1)
	assert_true(dl.hatch != null, "la escotilla, en la cubierta")
	assert_almost_eq(dl.hatch.position.y, 0.825, 0.01)
	assert_eq(made.size(), 1, "aún no ha bajado nadie: el aviso")
	_step(dl, dl.level.galley_warn + dl.level.galley_count * 0.55 + 0.2)
	var rowers := made.filter(func(e: Enemy) -> bool: return String(e.data.id) == "remero_lunar")
	assert_eq(rowers.size(), dl.level.galley_count)
	for e: Enemy in rowers:
		assert_lt(e.position.distance_to(dl.galley_at), 2.5, "bajan por la pasarela")

func test_reventar_la_escotilla_para_la_galera() -> void:
	_player("dyer", Vector3(0, 0, 0))
	var r := _puerto()
	var dl: DreamLands = r[0]
	var made: Array[Enemy] = r[1]
	dl._galley_next = 0.0
	_step(dl, 0.1)
	assert_eq(dl.landings, 1)
	dl.hatch.take_damage(Damage.new(99999.0, 0.0))
	assert_true(dl.hatch_broken)
	var n := made.size()
	dl._galley_next = 0.0
	_step(dl, 6.0)
	assert_eq(dl.landings, 1, "ya no atraca")
	assert_eq(made.size(), n, "y no baja nadie más (tampoco los que esperaban)")

func test_la_escotilla_no_se_mueve_ni_toca() -> void:
	var p := _player("dyer", Vector3(-4.5, 0, -33.5))
	var r := _puerto()
	var dl: DreamLands = r[0]
	dl.place_hatch()
	var h := dl.hatch
	var hit := Damage.new(5.0, 0.0)
	hit.knockback = Vector3(0, 0, -30)
	h.take_damage(hit)
	await wait_physics_frames(20)
	assert_almost_eq(h.position.x, dl.hatch_at.x, 0.001)
	assert_almost_eq(h.position.z, dl.hatch_at.z, 0.001, "anclada: ni el empujón ni el borde la mueven")
	assert_false(h.behavior.touches(h))
	assert_false(h.behavior.can_shoot(h))
	assert_eq(p.health, p.data.max_health)

func test_los_mercaderes_sueltan_rubies() -> void:
	var dl := _dream("p4_n2")
	dl.level = dl.level.duplicate()
	dl.level.ruby_chance = 1.0
	var m := _enemy("mercader_leng", Vector3(3, 0, 3), false)
	var z := _enemy("remero_lunar", Vector3(-3, 0, 3), false)
	dl.watch_ruby(m)
	dl.watch_ruby(z)
	m.take_damage(Damage.new(99999.0, 0.0))
	z.take_damage(Damage.new(99999.0, 0.0))
	assert_eq(dl.rubies, 1, "solo el mercader")
	var found := world.fx.get_children().filter(func(n: Node) -> bool: return n is Pickup and (n as Pickup).kind == Pickup.Kind.RUBY)
	assert_eq(found.size(), 1)

func test_el_rubi_vale_el_doble_y_quita_cordura() -> void:
	for i in 20:
		var n := Pickup.money_roll(Pickup.Kind.RUBY)
		assert_true(n >= Pickup.MONEY_RANGE.x * 2 and n <= Pickup.MONEY_RANGE.y * 2)
	assert_eq(Pickup.money_roll(Pickup.Kind.FOOD), 0)
	var p := _player("dyer", Vector3.ZERO)
	var s := p.sanity
	var rb := Pickup.new().setup(world, Vector3.ZERO, Pickup.Kind.RUBY)
	world.fx.add_child(rb)
	rb.take(p, 60)
	assert_lt(p.sanity, s, "un escalofrío")
	for k in 6: assert_ne(Pickup.roll(), Pickup.Kind.RUBY, "no sale de los rompibles")
