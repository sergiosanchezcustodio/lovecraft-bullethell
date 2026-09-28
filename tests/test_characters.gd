extends GutTest
## Personajes jugables de la fase 2 (D-23): datos completos, esquive propio, rasgos y las
## armas nuevas (escopeta y machete).

const IDS := ["dyer", "olmstead", "legrasse", "johansen"]
var world: CombatWorld
var root: Node3D
var obstacles: ObstacleMap

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)

func _player(id: String) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _enemy(tags: Array[StringName], pos: Vector3) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	d.tags = tags
	d.max_health = 1000.0
	var e := Enemy.new().setup(d, world, obstacles)
	e.position = pos
	root.add_child(e)
	return e

func test_cuatro_personajes_completos_y_distintos() -> void:
	var dodges := {}
	for id in IDS:
		var c: CharacterData = load("res://data/characters/%s.tres" % id)
		assert_eq(String(c.id), id)
		assert_true(FileAccess.file_exists("res://models/%s.json" % c.model), "modelo de " + id)
		assert_true(Anims.has_anim(c.model, "walk"), "animaciones de " + id)
		assert_ne(c.passive_text, "", "rasgo de " + id)
		assert_not_null(c.dodge_style)
		dodges[c.dodge_style.id] = true
		for w in c.starting_weapons: assert_true(ResourceLoader.exists("res://data/weapons/%s.tres" % w))
	assert_eq(dodges.size(), 4, "un esquive distinto cada uno")

func test_olmstead_esquiva_mas_largo() -> void:
	var p := _player("olmstead")
	assert_almost_eq(p.data.dodge_duration, p.data.dodge_style.duration * 1.3, 0.001)

func test_la_resistencia_por_etiquetas_solo_vale_contra_ellas() -> void:
	var p := _player("olmstead")
	p.data.resist_tags = {&"marina": 0.7}          # rasgo como dato (hoy no lo lleva nadie)
	var marine := _enemy([&"marina"] as Array[StringName], Vector3(5, 0, 0))
	var d := Damage.new(10.0, 0.0)
	d.source = marine
	p.take_damage(d)
	assert_almost_eq(p.health, p.data.max_health - 7.0, 0.01)
	p._hurt_time = -1.0
	var other := _enemy([] as Array[StringName], Vector3(-5, 0, 0))
	var d2 := Damage.new(10.0, 0.0)
	d2.source = other
	p.take_damage(d2)
	assert_almost_eq(p.health, p.data.max_health - 17.0, 0.01, "las demás, daño normal")

func test_legrasse_hace_mas_daño_a_los_humanos() -> void:
	var p := _player("legrasse")
	var human := _enemy([&"humana"] as Array[StringName], Vector3(5, 0, 0))
	var d := Damage.new(20.0, 0.0)
	d.bonus = p.data.bonus_tags
	human.take_damage(d)
	assert_almost_eq(human.health, 1000.0 - 25.0, 0.01)

func test_el_machete_golpea_alrededor_y_espera_si_no_hay_nadie() -> void:
	var p := _player("johansen")
	var w := p.weapons.add_weapon(load("res://data/weapons/machete.tres"))
	var near := _enemy([] as Array[StringName], Vector3(1.5, 0, 0))
	var far := _enemy([] as Array[StringName], Vector3(6, 0, 0))
	world.rebuild_grid()
	assert_true(p.weapons._fire(w))
	assert_lt(near.health, 1000.0)
	assert_eq(far.health, 1000.0)
	near.position = Vector3(8, 0, 0)
	world.rebuild_grid()
	assert_false(p.weapons._fire(w), "sin nadie cerca no da tajos al aire")

func test_la_escopeta_dispara_en_anillo() -> void:
	var shotgun: WeaponData = load("res://data/weapons/corredera.tres")
	assert_gt(shotgun.stat("count", 1), 6.0)
	assert_gt(shotgun.stat("spread_deg", 1), 270.0, "los perdigones se abren en anillo")

# ---------------- primera tanda de la tienda (D-26) ----------------
const SHOP_IDS := ["peaslee", "varga", "whipple", "blake"]

func test_los_de_la_tienda_estan_completos() -> void:
	for id in SHOP_IDS:
		var c: CharacterData = load("res://data/characters/%s.tres" % id)
		assert_true(FileAccess.file_exists("res://models/%s.json" % c.model), "modelo de " + id)
		assert_true(Anims.has_anim(c.model, "walk"))
		for w in c.starting_weapons: assert_true(ResourceLoader.exists("res://data/weapons/%s.tres" % w))
		assert_eq(c.in_shop, not ["peaslee", "whipple"].has(id), "Peaslee y Whipple son de inicio (D-30)")

func test_la_orbita_golpea_y_espera_su_intervalo() -> void:
	var p := _player("varga")
	var w := p.weapons.add_weapon(load("res://data/weapons/necronomicon.tres"))
	var e := _enemy([] as Array[StringName], Vector3(w.stat("aoe_radius"), 0, 0))
	world.rebuild_grid()
	assert_true(p.weapons._fire(w))
	var ring: OrbitRing = p.weapons._rings[w]
	ring._angle = 0.0
	ring._physics_process(1.0 / 60.0)
	var after_one := e.health
	assert_lt(after_one, 1000.0, "la página que pasa por encima le hace daño")
	ring._physics_process(1.0 / 60.0)
	assert_eq(e.health, after_one, "no vuelve a golpearle antes del intervalo")
	assert_false(p.weapons._fire(w), "mientras giran, no se vuelve a activar")

func test_el_rayo_dana_lo_que_esta_en_su_linea() -> void:
	var p := _player("blake")
	var w := p.weapons.add_weapon(load("res://data/weapons/trapezoedro.tres"))
	var inline := _enemy([] as Array[StringName], Vector3(6, 0, 0))
	var aside := _enemy([] as Array[StringName], Vector3(6, 0, 4))
	world.rebuild_grid()
	p.weapons._beam(w, Vector3(10, 0, 0))
	assert_lt(inline.health, 1000.0)
	assert_eq(aside.health, 1000.0)

func test_varga_paga_la_mitad_de_cordura() -> void:
	var p := _player("varga")
	var w := p.weapons.add_weapon(load("res://data/weapons/necronomicon.tres"))
	var before := p.sanity
	p.weapons._pay_sanity(w)
	assert_almost_eq(before - p.sanity, w.stat("sanity_cost") * 0.5, 0.001)

func test_la_suerte_da_a_veces_una_opcion_mas() -> void:
	var p := _player("peaslee")
	for f in ["velocidad", "vida", "cordura", "reflejos", "iman"]:
		p.progress.upgrade_pool.append(load("res://data/upgrades/%s.tres" % f))
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var four := 0
	for i in 400:
		if p.progress.roll_options(p.weapons, rng).size() == 4: four += 1
	assert_almost_eq(four / 400.0, 0.3, 0.08)

# ---------------- segunda tanda (D-26) ----------------
func test_la_segunda_tanda_esta_completa() -> void:
	for id in ["iwanicki", "elwood", "malone"]:
		var c: CharacterData = load("res://data/characters/%s.tres" % id)
		assert_true(c.in_shop)
		assert_true(FileAccess.file_exists("res://models/%s.json" % c.model), "modelo de " + id)
		assert_true(Anims.has_anim(c.model, "walk"))
		for w in c.starting_weapons: assert_true(ResourceLoader.exists("res://data/weapons/%s.tres" % w))

func test_la_onda_empuja_aturde_y_golpea_una_vez() -> void:
	var p := _player("iwanicki")
	var w := p.weapons.add_weapon(load("res://data/weapons/formula.tres"))
	var near := _enemy([] as Array[StringName], Vector3(2, 0, 0))
	var far := _enemy([] as Array[StringName], Vector3(12, 0, 0))
	world.rebuild_grid()
	assert_true(p.weapons._fire(w))
	var wave: Shockwave = world.fx.get_child(world.fx.get_child_count() - 1)
	for i in 60: wave._physics_process(1.0 / 60.0)
	assert_almost_eq(near.health, 1000.0 - p.weapons.dmg(w), 0.01, "una sola vez")
	assert_gt(near._stun, 0.0)
	assert_eq(far.health, 1000.0)

func test_elwood_aguanta_el_daño_fisico() -> void:
	var p := _player("elwood")
	p.take_damage(Damage.new(20.0, 10.0))
	assert_almost_eq(p.health, p.data.max_health - 17.0, 0.01)
	assert_almost_eq(p.sanity, p.data.max_sanity - 10.0, 0.01, "el mental, igual")

func test_malone_hace_mas_daño_a_quemarropa() -> void:
	var p := _player("malone")
	var w := p.weapons.add_weapon(load("res://data/weapons/thompson.tres"))
	_enemy([] as Array[StringName], Vector3(0.5, 0, 0))
	world.rebuild_grid()
	p.weapons._fire(w)
	var first: float = world.bullets._phys[0]
	assert_gt(first, w.stat("damage") * 1.4)

func test_dyer_hace_explosiones_mas_grandes() -> void:
	var p := _player("dyer")
	var w := p.weapons.add_weapon(load("res://data/weapons/granada.tres"))
	p.weapons._throw(w, Vector3(3, 0, 0))
	var e: ThrownExplosive = world.fx.get_child(world.fx.get_child_count() - 1)
	assert_almost_eq(e.radius, w.stat("aoe_radius") * 1.25, 0.001)

func test_johansen_pega_mas_cuerpo_a_cuerpo() -> void:
	var p := _player("johansen")
	var w := p.weapons.add_weapon(load("res://data/weapons/machete.tres"))
	assert_almost_eq(p.weapons.dmg(w), w.stat("damage") * p.damage_mult(w.data.category) * 1.25, 0.001)

func test_iwanicki_se_calma_a_si_mismo() -> void:
	var p := _player("iwanicki")
	p.sanity = 50.0
	p.world = world
	p.sanity_state.since_mental_hit = 0.0          # sin la recuperación normal
	p._physics_process(1.0)
	assert_gt(p.sanity, 50.0)

func test_un_solo_rasgo_por_personaje() -> void:
	var neutral := CharacterData.new()
	var fields := ["resist_tags", "bonus_tags", "knockback_immune", "dodge_length", "arcane_cost_mult", "xp_mult",
		"heal_on_level", "revive_speed", "calm_aura", "physical_resist", "dodge_cooldown_mult", "close_bonus",
		"explosion_radius_mult", "melee_mult", "luck", "pickup_radius"]
	for r in DebugOptions.list_resources("res://data/characters"):
		var c := r as CharacterData
		var n := 0
		for f in fields:
			if c.get(f) != neutral.get(f): n += 1
		assert_eq(n, 1, "rasgos de " + String(c.id))
