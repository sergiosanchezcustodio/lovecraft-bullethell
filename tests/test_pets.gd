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
