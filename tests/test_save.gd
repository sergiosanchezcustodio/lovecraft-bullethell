extends GutTest
## Huecos de partida: guardar, leer, borrar y migrar versiones antiguas.

var saves: Node

func before_each() -> void:
	saves = load("res://scripts/save/save_manager.gd").new()
	saves.dir = "user://test_saves"
	add_child_autofree(saves)
	for i in 3: saves.delete(i)

func after_each() -> void:
	for i in 3: saves.delete(i)

func test_un_hueco_vacio_empieza_una_partida_nueva() -> void:
	assert_null(saves.peek(1))
	var d: SaveData = saves.use(1)
	assert_eq(d.money, 0)
	assert_true(saves.exists(1), "se guarda al crearla")
	assert_false(saves.exists(0))

func test_guardar_y_leer_conserva_todo() -> void:
	var d: SaveData = saves.use(0)
	d.money = 1250
	d.play_time = 3725.0
	d.purchases = {"vida": 3, "velocidad": 1}
	d.pets = ["perro"]
	d.stats["kills"] = 42
	assert_true(saves.save())
	var r: SaveData = saves.peek(0)
	assert_eq(r.money, 1250)
	assert_almost_eq(r.play_time, 3725.0, 0.01)
	assert_eq(r.purchases["vida"], 3)
	assert_eq(typeof(r.purchases["vida"]), TYPE_INT, "los niveles vuelven como enteros")
	assert_eq(r.items_bought(), 4)
	assert_eq(r.pets, ["perro"])
	assert_eq(r.stats["kills"], 42)

func test_borrar_deja_el_hueco_como_nuevo() -> void:
	var d: SaveData = saves.use(2)
	d.money = 99
	saves.save()
	saves.delete(2)
	assert_false(saves.exists(2))
	assert_eq(saves.slot, -1)
	assert_eq((saves.use(2) as SaveData).money, 0)

func test_migra_una_version_sin_numero() -> void:
	var old := {"time": 120.0, "money": 5}
	var d := SaveData.from_dict(old)
	assert_almost_eq(d.play_time, 120.0, 0.01)
	assert_eq(d.money, 5)
	assert_eq(d.to_dict()["version"], SaveData.VERSION)

func test_un_fichero_roto_no_rompe_el_juego() -> void:
	DirAccess.make_dir_recursive_absolute(saves.dir)
	var f := FileAccess.open(saves.path(0), FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	assert_null(saves.peek(0))

func test_tiempo_jugado_como_texto() -> void:
	assert_eq(SaveData.format_time(30), "menos de 1 min")
	assert_eq(SaveData.format_time(12 * 60 + 5), "12 min")
	assert_eq(SaveData.format_time(3 * 3600 + 5 * 60), "3 h 05 min")

func test_la_partida_de_pruebas_lo_tiene_todo() -> void:
	saves.make_test_save(2)
	var d: SaveData = saves.peek(2)
	assert_true(d.unlock_all)
	assert_gt(d.money, 100000)
	assert_true(d.has_character("malone"))
	assert_true(d.has_character("un_personaje_futuro"), "lo que se añada, también")
	assert_true(d.has_pet("cualquiera"))
	assert_true(d.has_level("p3_n5"))
	var normal := SaveData.create()
	assert_false(normal.has_level("p1_n2"))
