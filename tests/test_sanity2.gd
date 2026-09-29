extends GutTest
## Cordura completa (hito 2.11): las cinco crisis, calmar, recuperación junto a luces y
## compañeros, auras de presencia, locura acumulada y paranoia.

const DT := 1.0 / 60.0
var world: CombatWorld
var rules: ProgressionData

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	rules = load("res://data/progression/default.tres")

func _player(id: String, pos: Vector3, i: int = 0) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Devices.COLORS[i])
	p.index = i
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.global_position = pos
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _crisis(p: Player, kind: StringName) -> void:
	p.sanity_state.forced_kind = kind
	p.sanity = 0.0
	p._physics_process(DT)
	assert_true(p.sanity_state.is_kind(kind), String(kind))

func test_en_solitario_nunca_sale_la_paranoia() -> void:
	var s := SanityState.new(rules)
	var seen := {}
	for i in 400: seen[s.pick_kind()] = true
	assert_false(seen.has(&"paranoia"))
	assert_eq(seen.size(), 4, "las otras cuatro")
	s.coop = true
	for i in 400: seen[s.pick_kind()] = true
	assert_true(seen.has(&"paranoia"))

func test_los_pesos_del_personaje_mandan() -> void:
	var s := SanityState.new(rules)
	s.weights = {&"delirio": 1.0}
	for i in 50: assert_eq(s.pick_kind(), &"delirio")

func test_la_huida_aleja_del_horror() -> void:
	var p := _player("dyer", Vector3.ZERO)
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	var e := Enemy.new().setup(d, world, null)
	e.position = Vector3(3, 0, 0)
	world.add_child(e)
	world.rebuild_grid()
	_crisis(p, &"huida")
	for i in 30: p._physics_process(DT)
	assert_lt(p.global_position.x, -0.5, "corre en dirección contraria")

func test_el_delirio_invierte_los_controles() -> void:
	var p := _player("dyer", Vector3.ZERO)
	_crisis(p, &"delirio")
	assert_eq(p._crisis_move(DT, Vector2(1, 0)), Vector2(-1, 0))

func test_un_companero_al_lado_acorta_la_crisis() -> void:
	var a := _player("dyer", Vector3.ZERO, 0)
	_crisis(a, &"delirio")
	var solo_left := a.sanity_state.crisis_duration
	_player("olmstead", Vector3(1, 0, 0), 1)
	var t := 0.0
	while a.sanity_state.in_crisis and t < 10.0:
		a._physics_process(DT)
		t += DT
	assert_lt(t, solo_left * 0.75, "acaba antes")

func test_junto_a_una_luz_recupera_mas_deprisa() -> void:
	var p := _player("dyer", Vector3.ZERO)
	var lamp := Node3D.new()
	add_child_autofree(lamp)
	lamp.global_position = Vector3(1, 0, 0)
	p.sanity = 50.0
	p.sanity_state.since_mental_hit = 99.0
	for i in 60: p._physics_process(DT)
	var dark := p.sanity - 50.0
	p.lights = [lamp] as Array[Node3D]
	p.sanity = 50.0
	for i in 60: p._physics_process(DT)
	assert_almost_eq(p.sanity - 50.0, dark * rules.regen_near_light, 0.05)

func test_el_aura_de_la_elite_drena_cordura() -> void:
	var p := _player("dyer", Vector3.ZERO)
	var d: EnemyData = (load("res://data/enemies/acechador.tres") as EnemyData).duplicate()
	assert_gt(d.aura_drain, 0.0, "el Acechador tiene presencia")
	var e := Enemy.new().setup(d, world, null)
	e.position = Vector3(2, 0, 0)
	world.add_child(e)
	var s0 := p.sanity
	for i in 60: e._physics_process(DT)
	assert_almost_eq(s0 - p.sanity, d.aura_drain, 0.2)

func test_la_locura_acumulada_baja_la_cordura_maxima() -> void:
	var p := _player("dyer", Vector3.ZERO)
	var full := p.data.max_sanity
	_crisis(p, &"delirio")
	assert_almost_eq(p.data.max_sanity, full * (1.0 - rules.madness_step), 0.01)
	p.madness = false
	p.rebuild_stats()
	assert_almost_eq(p.data.max_sanity, full, 0.01, "desactivada, no baja")

func test_la_paranoia_apunta_al_companero_y_solo_quita_cordura() -> void:
	var a := _player("dyer", Vector3.ZERO, 0)
	var b := _player("olmstead", Vector3(3, 0, 0), 1)
	a.sanity_state.coop = true
	_crisis(a, &"paranoia")
	var w := a.weapons.add_weapon(load("res://data/weapons/webly.tres"))
	a.weapons._fire(w)
	assert_gt(world.bullets.count, 0)
	assert_gt(world.bullets._vel[0].x, 0.0, "hacia el compañero")
	var hp := b.health
	var san := b.sanity
	for i in 20: world.bullets._physics_process(DT)
	assert_eq(b.health, hp, "sin fuego amigo en la vida")
	assert_lt(b.sanity, san, "le quita cordura")

func test_su_propia_bala_no_le_da_al_paranoico() -> void:
	var a := _player("dyer", Vector3.ZERO, 0)
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.PLAYER, Vector3.ZERO, Vector3(0.1, 0, 0), 0.3,
		0.2, Damage.new(1, 0), 1.0, 0, 1.0, -1, 0, 0.0, BulletManager.Effect.PARANOIA, 5.0, 0)
	var san := a.sanity
	for i in 5: world.bullets._physics_process(DT)
	assert_eq(a.sanity, san)
