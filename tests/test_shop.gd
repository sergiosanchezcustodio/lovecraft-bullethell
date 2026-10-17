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
	assert_eq(Shop.in_section(ShopItem.Section.POWERUP).size(), 17, "diecisiete potenciadores (cuatro más en el hito 5.4 y ocho el 17-10-2026)")
	assert_eq(Shop.in_section(ShopItem.Section.CHARACTER).size(), 9, "los nueve que no son de inicio (Armitage y West, hito 5.5)")
	assert_eq(Shop.in_section(ShopItem.Section.PET).size(), DebugOptions.list_resources("res://data/pets").size(), "todos los compañeros")
	assert_eq(Shop.in_section(ShopItem.Section.UPGRADE).size(), 11, "quinta y sexta funda, quinto y sexto bolsillo y siete mejoras del 17-10-2026")
	for e in Shop.catalog():
		for p in e.prices: assert_gt(p, 0, e.id)

func test_la_tienda_entera_lleva_unas_veinte_horas() -> void:
	var total := 0
	var outfits := 0
	for e in Shop.catalog():
		for p in e.prices:
			if e.section == ShopItem.Section.OUTFIT: outfits += p      # estético: aparte
			else: total += p
	assert_between(total, 180000, 260000, "a unos 5.500 $ por hora: de 33 a 47 h entre tienda y compañeros (D-36; el 5.4 y el 17-10-2026 la amplían)")
	assert_between(outfits, 30000, 70000, "el vestuario (D-34), de 5 a 13 h más")

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

## Tienda ampliada (17-10-2026)

func test_cada_efecto_de_la_tienda_tiene_su_valor_sin_comprar() -> void:
	var b := Shop.bonuses(_save(0))
	for it: ShopItem in DebugOptions.list_resources("res://data/shop"):
		assert_true(Shop.DEFAULTS.has(it.stat), "%s: su efecto (%s) existe" % [it.id, it.stat])
		assert_true(it.icon != null or it.icon_model != "", "%s tiene imagen" % it.id)
	assert_eq(float(b.guard), 0.0)
	assert_eq(float(b.area), 1.0)

func test_los_efectos_nuevos_se_suman_por_nivel() -> void:
	var s := _save(0)
	s.purchases = {"coraza_pabodie": 2, "lente_wilmarth": 3, "tarot": 2, "pacto": 1}
	var b := Shop.bonuses(s)
	assert_almost_eq(float(b.guard), 0.06, 0.001)
	assert_almost_eq(float(b.area), 1.15, 0.001)
	assert_eq(int(b.banish), 2)
	assert_almost_eq(float(b.pact), 0.1, 0.001)

func test_el_pacto_se_puede_romper() -> void:
	var s := _save(0)
	s.purchases = {"pacto": 3}
	assert_true(Shop.is_active(s, "pacto"))
	s.toggles["pacto"] = false
	assert_eq(float(Shop.bonuses(s).pact), 0.0, "roto: no cuenta")
	var again := SaveData.from_dict(s.to_dict())
	assert_false(Shop.is_active(again, "pacto"), "se guarda")

func test_el_jugador_aplica_los_potenciadores_nuevos() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	add_child_autofree(p)
	p.shop = {"ward": 0.2, "haste": 0.1, "area": 1.25, "duration": 1.1, "reach": 1.2, "regen": 0.3, "crit": 0.04, "lantern": 1.0, "banish": 2.0}
	p.rebuild_stats()
	assert_almost_eq(p.data.mental_mult, 0.8, 0.001)
	assert_almost_eq(p.data.weapon_cooldown_mult, 0.9, 0.001)
	assert_almost_eq(p.data.area_mult, 1.25, 0.001)
	assert_almost_eq(p.data.duration_mult, 1.1, 0.001)
	assert_almost_eq(p.data.range_mult, 1.2, 0.001)
	assert_almost_eq(p.data.health_regen, 0.3, 0.001)
	assert_almost_eq(p.data.crit_chance, 0.04, 0.001)
	assert_almost_eq((p.get_node("CarryLight") as OmniLight3D).omni_range, 4.5 * Player.LANTERN_RANGE, 0.01)
	assert_eq(p.banishes_left(), 2)

func test_la_coraza_quita_parte_del_dano_fisico() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	add_child_autofree(p)
	p.shop = {"guard": 0.15}
	p.rebuild_stats()
	p.health = 100.0
	var old := Difficulty.forced
	Difficulty.forced = 0
	p.take_damage(Damage.new(10.0, 0.0))
	var want := 100.0 - 10.0 * p.data.physical_resist * 0.85 * Difficulty.damage()
	Difficulty.forced = old
	assert_almost_eq(p.health, want, 0.01)

func test_la_medalla_levanta_una_vez_por_nivel_comprado() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	add_child_autofree(p)
	p.shop = {"second_life": 1.0}
	p.rebuild_stats()
	p.health = 1.0
	p.take_damage(Damage.new(999.0, 0.0))
	assert_almost_eq(p.health, p.data.max_health * Player.SECOND_LIFE_HEALTH, 0.01, "se levanta")
	p._hurt_time = -1.0
	p.motor.dodge_time = 999.0
	p.health = 1.0
	p.take_damage(Damage.new(999.0, 0.0))
	assert_eq(p.health, 0.0, "la segunda vez, no")

func test_lo_descartado_no_vuelve_a_salir() -> void:
	var rules: ProgressionData = load("res://data/progression/default.tres")
	var pr := PlayerProgress.new(rules)
	for up: UpgradeData in DebugOptions.list_resources("res://data/upgrades"): pr.upgrade_pool.append(up)
	var gone: UpgradeData = pr.upgrade_pool[0]
	pr.banished["u:" + String(gone.id)] = true
	var rng := RandomNumberGenerator.new()
	for k in 30:
		rng.seed = k
		for o in pr.roll_options(null, rng, 6):
			assert_ne(String(o.upgrade.id), String(gone.id))

func test_la_tienda_muestra_el_boton_del_pacto_y_lo_rompe() -> void:
	var s := _save(0)
	s.purchases = {"pacto": 2}
	var old := Saves.current
	Saves.current = null                                   # sin hueco: Saves.save no escribe
	var m := ShopMenu.new()
	m.save = s
	add_child_autofree(m)
	m._show_tab(ShopItem.Section.UPGRADE)
	var toggle: Button = null
	for c in m._list.get_children():
		if c is Button and (c as Button).text.begins_with("Activo:"): toggle = c
	assert_not_null(toggle, "hay botón para romper el pacto")
	toggle.pressed.emit()
	assert_false(Shop.is_active(s, "pacto"), "roto")
	Saves.current = old
