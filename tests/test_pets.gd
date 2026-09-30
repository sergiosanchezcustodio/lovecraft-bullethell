extends GutTest
## Compañeros (hitos 2.13c y 2.15, D-20, D-36): cada uno con su modelo, sus animaciones y lo
## que hace; todos suben de nivel con su jugador.

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player() -> Player:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	return p

func _pet(id: String, p: Player, game: Node = null) -> Pet:
	var pet := Pet.new().setup(load("res://data/pets/%s.tres" % id), p, world, game)
	world.add_child(pet)
	return pet

func _dummy(at: Vector3) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	d.max_health = 1000.0
	d.move_speed = 0.0
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _run(pet: Pet, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		pet._physics_process(DT)

func test_todos_los_companeros_tienen_modelo_y_animaciones() -> void:
	for r in DebugOptions.list_resources("res://data/pets"):
		var pd := r as PetData
		assert_ne(pd.model, "", String(pd.id))
		assert_true(FileAccess.file_exists("res://models/%s.json" % pd.model), String(pd.id))
		for a in ["idle", "walk", "run", "bite"]: assert_true(Anims.has_anim(pd.model, a), "%s %s" % [pd.id, a])
		assert_ne(pd.description, "", String(pd.id))

func test_el_perro_corre_a_morder_al_enemigo_cercano() -> void:
	var pet := _pet("perro", _player())
	var e := _dummy(Vector3(3.5, 0, 0))
	_run(pet, 3.0)
	assert_gt(pet.hits, 0)
	assert_lt(e.health, 1000.0)

func test_el_ataque_crece_con_el_nivel() -> void:
	var pd: PetData = load("res://data/pets/perro.tres")
	assert_gt(pd.attack_at(5), pd.attack_at(1))

func test_el_gato_arana_y_se_enfada_si_hieren_a_su_jugador() -> void:
	var p := _player()
	var pet := _pet("gato", p)
	var e := _dummy(Vector3(3.0, 0, 0))
	_run(pet, 3.0)
	assert_gt(pet.hits, 0, "araña")
	assert_lt(e.health, 1000.0)
	var hunt := pet.behavior as PetHunt
	var calm := hunt.damage()
	assert_false(hunt.angry())
	p.take_damage(Damage.new(5.0, 0.0))
	assert_true(hunt.angry(), "se enfada")
	assert_almost_eq(hunt.damage(), calm * 1.5, 0.01)
	assert_eq(p.mental_resist, 1.0, "ya no protege del daño mental")

func test_el_sapo_escupe_un_charco_venenoso() -> void:
	var pet := _pet("sapo", _player())
	_dummy(Vector3(3.0, 0, 1.0))
	_run(pet, 1.0)
	assert_gt(pet.hits, 0)
	var spit := world.fx.get_children().filter(func(n: Node) -> bool: return n is ThrownExplosive)
	assert_eq(spit.size(), 1)
	assert_eq(int((spit[0] as ThrownExplosive).zone.kind), WeaponData.Zone.ACID)

func test_el_buho_da_mas_experiencia_y_mas_con_el_nivel() -> void:
	var p := _player()
	var pet := _pet("buho", p)
	assert_almost_eq(p.pet_xp_mult, 1.12, 0.001)
	p.progress.gain_level()
	assert_gt(p.pet_xp_mult, 1.12)
	p.progress.level = 99
	pet.behavior.leveled()
	assert_almost_eq(p.pet_xp_mult, 1.3, 0.001, "tope")

class FakeGame extends Node:
	var money := 0
	var director = null
	func earn(n: int) -> void: money += n

func test_la_rata_encuentra_dolares() -> void:
	var game := FakeGame.new()
	add_child_autofree(game)
	var pet := _pet("rata", _player(), game)
	pet.cooldown = 0.0
	_run(pet, 4.0)
	assert_gt(game.money, 0)
	assert_eq(pet.found_money, game.money)

func test_el_shoggoth_se_traga_balas_enemigas_cercanas() -> void:
	var p := _player()
	var pet := _pet("shoggoth", p)
	pet.position = Vector3(10, 0, 10)            # lejos del jugador: las balas no le dan
	for i in 6:
		world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, pet.global_position + Vector3(0.2 * i, 0.5, 0),
			Vector3.ZERO, 0.1, 0.2, Damage.new(1.0, 0.0), 10.0)
	world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, pet.global_position + Vector3(6, 0.5, 0),
		Vector3.ZERO, 0.1, 0.2, Damage.new(1.0, 0.0), 10.0)
	var before := world.bullets.count
	for i in int(1.0 / DT): pet.behavior.step(DT)
	assert_between(before - world.bullets.count, 1, 3, "unas pocas por segundo")
	assert_eq(world.bullets.count_enemy_bullets(pet.global_position + Vector3(6, 0, 0), 0.5), 1, "la lejana sigue")

func test_el_companero_sigue_a_su_jugador() -> void:
	var p := _player()
	var pet := _pet("buho", p)
	p.global_position = Vector3(6, 0, 0)
	for i in int(4.0 / DT): pet._physics_process(DT)
	assert_lt(pet.global_position.distance_to(p.global_position), 3.0)

# ---------------- hito 2.15b y 2.15c ----------------
func _near_dummies(n: int, at: Vector3) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for i in n: out.append(_dummy(at + Vector3(0.3 * i, 0, 0.2 * i)))
	return out

func test_el_byakhee_cae_en_picado_y_golpea_en_area() -> void:
	var pet := _pet("byakhee", _player())
	var es := _near_dummies(3, Vector3(3, 0, 0))
	_run(pet, 2.0)
	assert_gte(pet.hits, 2, "golpea a varios")
	assert_lt(es[0].health, 1000.0)

func test_el_mi_go_dispara_rayos() -> void:
	var pet := _pet("migo", _player())
	var e := _dummy(Vector3(3, 0, 0))
	_run(pet, 2.5)
	assert_gte(pet.hits, 2)
	assert_lt(e.health, 1000.0)

func test_la_arana_de_tindalos_aparece_detras_y_aturde() -> void:
	var pet := _pet("tindalos", _player())
	var e := _dummy(Vector3(4, 0, 0))
	world.rebuild_grid()
	pet._physics_process(DT)
	assert_eq(pet.hits, 1)
	assert_lt(pet.global_position.distance_to(e.global_position), 1.0, "se ha teletransportado junto a él")
	assert_gt(e._stun, 0.0, "aturdido")

func test_la_serpiente_envenena() -> void:
	var pet := _pet("yig", _player())
	var e := _dummy(Vector3(2.5, 0, 0))
	_run(pet, 2.0)
	assert_true(e.is_poisoned())
	var h := e.health
	for i in int(1.0 / DT): e._update_status(DT)
	assert_lt(e.health, h, "el veneno sigue haciendo daño")

func test_la_polilla_confunde_a_los_de_debajo() -> void:
	var pet := _pet("polilla", _player())
	var es := _near_dummies(3, Vector3(3, 0, 0))
	_run(pet, 3.0)
	assert_true(es[0].is_confused())

func test_la_cabra_embiste_y_aturde() -> void:
	var pet := _pet("cabra", _player())
	var e := _dummy(Vector3(3, 0, 0))
	_run(pet, 2.0)
	assert_gt(pet.hits, 0)
	assert_lt(e.health, 1000.0)

func test_el_dhole_sale_bajo_un_grupo() -> void:
	var pet := _pet("dhole", _player())
	var es := _near_dummies(3, Vector3(4, 0, 0))
	_run(pet, 2.5)
	assert_gte(pet.hits, 3)
	assert_false(pet.hidden, "ha vuelto a salir")

func test_la_gaviota_trae_pescado_al_herido() -> void:
	var p := _player()
	var pet := _pet("gaviota", p)
	p.health = p.data.max_health * 0.5
	pet.cooldown = 0.0
	for i in int(6.0 / DT):
		p.global_position = Vector3.ZERO
		pet._physics_process(DT)
	assert_gt(p.health, p.data.max_health * 0.5)

class FakeGems extends FakeGame:
	var gems: GemManager

func test_el_cuervo_trae_gemas_y_roba_monedas() -> void:
	var game := FakeGems.new()
	add_child_autofree(game)
	game.gems = GemManager.new()
	game.gems.world = world
	game.gems.rules = load("res://data/progression/default.tres")
	game.add_child(game.gems)
	var pet := _pet("cuervo", _player(), game)
	game.gems.drop(Vector3(7, 0, 0), 5.0)
	game.gems._homing[0] = 0
	game.gems._pos[0] = Vector3(7, 0.3, 0)
	_run(pet, 4.0)
	assert_eq(game.gems._homing[0], 1, "la gema vuela hacia el jugador")
	assert_gt(game.money, 0, "roba monedas")

func test_cada_modelo_tiene_las_piezas_de_sus_animaciones() -> void:
	for r in DebugOptions.list_resources("res://data/pets"):
		var pd := r as PetData
		var m := VoxelBuilder.load_model("res://models/%s.json" % pd.model)
		add_child_autofree(m)
		var parts: Dictionary = m.get_meta("part_nodes")
		var script: Script = Anims.BY_MODEL[pd.model]
		for part in _parts_used(script): assert_true(parts.has(part), "%s: falta la pieza %s" % [pd.id, part])

## Piezas que pide un script de animación (las cadenas de _p(m, "...") y la lista SEGS).
func _parts_used(script: Script) -> Array:
	var out := []
	var re := RegEx.create_from_string('_p[(]m, "([a-z_0-9]+)"[)]')
	for mt in re.search_all(script.source_code): if not out.has(mt.get_string(1)): out.append(mt.get_string(1))
	if script.source_code.contains("SEGS"): out.append_array(["s1", "s2", "s3", "s4"])
	return out
