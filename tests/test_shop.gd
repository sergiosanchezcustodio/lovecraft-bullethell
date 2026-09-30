extends GutTest
## Tienda (hito 2.13b, D-31): catálogo, compras, niveles y efectos en la partida.

func _save(money: int) -> SaveData:
	var s := SaveData.create()
	s.money = money
	return s

func _entry(id: String) -> Shop.Entry:
	for e in Shop.catalog():
		if e.id == id: return e
	return null

func test_el_catalogo_tiene_las_cuatro_secciones() -> void:
	assert_eq(Shop.in_section(ShopItem.Section.POWERUP).size(), 5, "cinco potenciadores")
	assert_eq(Shop.in_section(ShopItem.Section.CHARACTER).size(), 7, "los siete que no son de inicio")
	assert_eq(Shop.in_section(ShopItem.Section.PET).size(), DebugOptions.list_resources("res://data/pets").size(), "todos los compañeros")
	assert_eq(Shop.in_section(ShopItem.Section.UPGRADE).size(), 2, "quinta arma y quinto objeto")
	for e in Shop.catalog():
		for p in e.prices: assert_gt(p, 0, e.id)

func test_la_tienda_entera_lleva_unas_diez_horas() -> void:
	var total := 0
	for e in Shop.catalog():
		for p in e.prices: total += p
	assert_between(total, 40000, 80000, "a unos 5.500 $ por hora")

func test_comprar_potenciador_sube_de_nivel_y_cobra() -> void:
	var s := _save(500)
	var e := _entry("vitalidad")
	assert_true(Shop.buy(s, e))
	assert_eq(s.money, 350)
	assert_eq(Shop.level_of(s, e), 1)
	assert_eq(Shop.next_price(s, e), 300)
	assert_true(Shop.buy(s, e))
	assert_eq(s.money, 50)
	assert_false(Shop.buy(s, e), "no llega")
	assert_eq(s.money, 50)

func test_no_se_pasa_del_maximo() -> void:
	var s := _save(999999)
	var e := _entry("codicia")
	for i in 5: assert_true(Shop.buy(s, e))
	assert_true(Shop.is_maxed(s, e))
	assert_false(Shop.buy(s, e))
	assert_eq(Shop.next_price(s, e), -1)

func test_comprar_un_personaje_lo_desbloquea() -> void:
	var s := _save(10000)
	var e := _entry("legrasse")
	assert_false(s.has_character("legrasse"))
	assert_true(Shop.buy(s, e))
	assert_true(s.has_character("legrasse"))
	assert_true(Shop.is_maxed(s, e))

func test_comprar_un_companero_lo_desbloquea() -> void:
	var s := _save(10000)
	assert_true(Shop.buy(s, _entry("perro")))
	assert_true(s.has_pet("perro"))

func test_los_efectos_de_lo_comprado() -> void:
	var s := _save(999999)
	for i in 2: Shop.buy(s, _entry("vitalidad"))
	Shop.buy(s, _entry("punteria"))
	Shop.buy(s, _entry("quinta_arma"))
	var b := Shop.bonuses(s)
	assert_almost_eq(float(b.health), 1.08, 0.001)
	assert_almost_eq(float(b.damage), 1.03, 0.001)
	assert_eq(int(b.weapon_slots), 1)
	assert_eq(int(b.item_slots), 0)
	assert_eq(float(b.speed), 1.0)

func test_el_jugador_aplica_los_potenciadores() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	add_child_autofree(p)
	var base := p.data.max_health
	var dmg := p.damage_mult(WeaponData.Category.FIREARM)
	p.shop = {"health": 1.2, "damage": 1.1}
	p.rebuild_stats()
	assert_almost_eq(p.data.max_health, base * 1.2, 0.01)
	assert_almost_eq(p.damage_mult(WeaponData.Category.FIREARM), dmg * 1.1, 0.001)

func test_la_tienda_de_antiguedades_tiene_su_ilustracion_y_sus_mascaras() -> void:
	assert_not_null(load(ShopBackdrop.ART))
	assert_not_null(load(ShopBackdrop.MASKS))
	var b := ShopBackdrop.new()
	add_child_autofree(b)
	assert_not_null(b._art.material)
	assert_true(FileAccess.file_exists("res://models/anciano.json"), "el diorama voxel sigue en el proyecto")
