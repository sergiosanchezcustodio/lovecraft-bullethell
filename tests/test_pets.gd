extends GutTest
## Compañeros (hito 2.13c, D-20): el perro muerde a los enemigos cercanos y el gato quita
## daño mental; los dos suben de nivel con su jugador.

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

func _pet(id: String, p: Player) -> Pet:
	var pet := Pet.new().setup(load("res://data/pets/%s.tres" % id), p, world)
	world.add_child(pet)
	return pet

func test_los_dos_companeros_tienen_modelo_y_animaciones() -> void:
	for id in ["perro", "gato"]:
		var pd: PetData = load("res://data/pets/%s.tres" % id)
		assert_ne(pd.model, "", id)
		assert_true(FileAccess.file_exists("res://models/%s.json" % pd.model), id)
		for a in ["idle", "walk", "run", "bite"]: assert_true(Anims.has_anim(pd.model, a), "%s %s" % [id, a])

func test_el_perro_corre_a_morder_al_enemigo_cercano() -> void:
	var p := _player()
	var pet := _pet("perro", p)
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	d.max_health = 1000.0
	d.move_speed = 0.0
	var e := Enemy.new().setup(d, world, null)
	e.position = Vector3(3.5, 0, 0)
	world.add_child(e)
	for i in int(3.0 / DT):
		world.rebuild_grid()
		pet._physics_process(DT)
	assert_gt(pet.bites, 0)
	assert_lt(e.health, 1000.0)

func test_el_perro_muerde_mas_con_el_nivel() -> void:
	var p := _player()
	var pet := _pet("perro", p)
	var d1 := pet.bite_damage()
	p.progress.level = 5
	assert_gt(pet.bite_damage(), d1)

func test_el_gato_quita_dano_mental_y_mas_con_el_nivel() -> void:
	var p := _player()
	var pet := _pet("gato", p)
	assert_almost_eq(p.mental_resist, 0.8, 0.001)
	var s := p.sanity
	p.take_damage(Damage.new(0.0, 10.0))
	assert_almost_eq(s - p.sanity, 8.0, 0.01)
	p.progress.gain_level()
	assert_lt(p.mental_resist, 0.8)
	p.progress.level = 99
	assert_almost_eq(pet.ward_factor(), 0.65, 0.001, "tope del 35 %")

func test_el_companero_sigue_a_su_jugador() -> void:
	var p := _player()
	var pet := _pet("gato", p)
	p.global_position = Vector3(6, 0, 0)
	for i in int(4.0 / DT): pet._physics_process(DT)
	assert_lt(pet.global_position.distance_to(p.global_position), 3.0)
