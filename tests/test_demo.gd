extends GutTest
## Demo de la parte 1 (hito 13.17): solo la Antártida, los cuatro de inicio y la tienda sin los
## demás personajes. Se fuerza con Demo.force(1) y se deja como estaba al acabar.

func after_each() -> void:
	Demo.force(-1)

func _entry(id: String) -> Shop.Entry:
	for e in Shop.catalog():
		if e.id == id: return e
	return null

func test_sin_la_etiqueta_es_el_juego_completo() -> void:
	Demo.force(-1)
	assert_false(Demo.on(), "los tests no corren con la etiqueta demo")
	assert_true(Campaign.is_unlocked("p2_n1", ["p1_n5"]))
	assert_eq(Demo.last_level(), Campaign.last_id())

func test_la_demo_solo_abre_la_parte_1() -> void:
	Demo.force(1)
	assert_true(Campaign.is_unlocked("p1_n1", []))
	assert_true(Campaign.is_unlocked("p1_n5", ["p1_n4"]))
	assert_false(Campaign.is_unlocked("p2_n1", ["p1_n5"]), "tras el shoggoth no se abre Innsmouth")
	assert_true(Campaign.part_unlocked(0, []))
	assert_false(Campaign.part_unlocked(1, ["p1_n5"]))
	assert_false(Campaign.part_unlocked(2, ["p2_n5"]))
	assert_eq(Campaign.next_in_part("p1_n5"), "", "el shoggoth es el último")
	assert_eq(Demo.last_level(), "p1_n5")

func test_ni_con_todo_desbloqueado_se_pasa_de_la_parte_1() -> void:
	Demo.force(1)
	var s := SaveData.create()
	s.unlock_all = true
	assert_true(s.has_level("p1_n3"))
	assert_false(s.has_level("p2_n1"))
	assert_false(s.has_level("p3_n5"))

func test_ni_sin_fin_ni_partida_del_dia() -> void:
	Demo.force(1)
	assert_false(Demo.level_ok("sin_fin:p1_n1"))
	assert_false(Demo.level_ok("dia:2026-10-30"))

func test_solo_los_cuatro_de_inicio() -> void:
	Demo.force(1)
	var free := 0
	for c: CharacterData in DebugOptions.list_resources("res://data/characters"):
		if Demo.character_ok(c): free += 1
	assert_eq(free, 4, "Dyer, Olmstead, Peaslee y Whipple")
	var legrasse: CharacterData = load("res://data/characters/legrasse.tres")
	var st := SelectState.new().setup([legrasse] as Array[CharacterData], ["legrasse"], [] as Array[PetData])
	assert_true(st.is_locked(0, 0), "aunque lo comprara en el juego completo")

func test_la_tienda_no_vende_los_demas_personajes() -> void:
	Demo.force(1)
	var s := SaveData.create()
	s.money = 100000
	assert_true(Demo.shop_locked(_entry("legrasse")))
	assert_false(Shop.can_buy(s, _entry("legrasse")))
	assert_false(Demo.shop_locked(_entry("perro")), "los compañeros sí")
	assert_true(Shop.can_buy(s, _entry("perro")))

func test_hay_relato_del_fin_de_la_demo() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
	assert_true(d.has(Demo.END_RELATO))
	assert_true(ResourceLoader.exists("res://resources/maps/p2_n1.png"))
