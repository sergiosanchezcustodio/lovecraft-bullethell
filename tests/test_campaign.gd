extends GutTest
## Mapa de niveles: 15 niveles en orden y apertura al superar el anterior.

func test_quince_niveles_en_tres_partes() -> void:
	assert_eq(Campaign.parts().size(), 3)
	var all := Campaign.levels()
	assert_eq(all.size(), 15)
	assert_eq(all[0].id, "p1_n1")
	assert_eq(all[5].id, "p2_n1")
	assert_eq(all[5].part, 1)
	assert_eq(all[5].number, 1)

func test_solo_el_primero_esta_abierto_al_empezar() -> void:
	assert_true(Campaign.is_unlocked("p1_n1", []))
	assert_false(Campaign.is_unlocked("p1_n2", []))
	assert_true(Campaign.is_playable("p1_n1", []))

func test_superar_un_nivel_abre_el_siguiente_aunque_sea_de_otra_parte() -> void:
	assert_true(Campaign.is_unlocked("p1_n2", ["p1_n1"]))
	assert_true(Campaign.is_unlocked("p2_n1", ["p1_n5"]))
	assert_true(Campaign.is_playable("p1_n2", ["p1_n1"]), "el nivel 2 ya existe (hito 4.2)")
	assert_true(Campaign.is_playable("p1_n3", ["p1_n2"]))
	assert_true(Campaign.is_playable("p1_n4", ["p1_n3"]))
	assert_true(Campaign.is_playable("p1_n5", ["p1_n4"]))
	assert_true(Campaign.is_playable("p2_n1", ["p1_n5"]), "el primero de la parte 2 ya existe (hito 6.1)")
	assert_true(Campaign.is_playable("p2_n2", ["p2_n1"]), "el nivel 2 de la parte 2 ya existe (hito 6.2)")
	assert_true(Campaign.is_playable("p2_n3", ["p2_n2"]), "el nivel 3 de la parte 2 ya existe (hito 6.3)")
	assert_true(Campaign.is_playable("p2_n4", ["p2_n3"]), "el nivel 4 de la parte 2 ya existe (hito 6.4)")
	assert_true(Campaign.is_playable("p2_n5", ["p2_n4"]), "el nivel 5 de la parte 2 ya existe (hito 6.5)")
	assert_true(Campaign.is_playable("p3_n1", ["p2_n5"]), "el nivel 1 de la parte 3 ya existe (hito 7.1)")
	assert_true(Campaign.is_playable("p3_n2", ["p3_n1"]), "el nivel 2 de la parte 3 ya existe (hito 7.2)")
	assert_false(Campaign.is_playable("p3_n3", ["p3_n2"]), "sin datos todavía: próximamente")

func test_siguiente_nivel_dentro_de_la_parte() -> void:
	assert_eq(Campaign.next_in_part("p1_n1"), "p1_n2")
	assert_eq(Campaign.next_in_part("p1_n5"), "", "el último de la parte no tiene siguiente")
	assert_eq(Campaign.number_of("p1_n3"), 3)
	assert_true(Campaign.part_unlocked(0, []))
	assert_false(Campaign.part_unlocked(1, ["p1_n1"]))
	assert_true(Campaign.part_unlocked(1, ["p1_n5"]))
