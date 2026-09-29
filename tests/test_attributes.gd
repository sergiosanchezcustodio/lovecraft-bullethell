extends GutTest
## Atributos (D-27): reparto de 20 puntos, estadísticas derivadas, +1 ponderado por nivel.

func _player(id: String) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	autofree(p)
	return p

func test_todos_reparten_veinte_puntos_en_tres_atributos() -> void:
	for r in DebugOptions.list_resources("res://data/characters"):
		var c := r as CharacterData
		var total := 0
		for k in c.attr_bonus:
			assert_true(Attributes.NAMES.has(k), "%s: atributo desconocido %s" % [c.id, k])
			total += int(c.attr_bonus[k])
		assert_eq(total, 20, String(c.id))
		assert_eq(c.attr_bonus.size(), 3, String(c.id))
		assert_eq(c.starting_weapons.size(), 1, "%s empieza con un solo arma (D-28)" % c.id)

func test_cuatro_de_inicio_dos_hombres_y_dos_mujeres() -> void:
	var start: Array = []
	for r in DebugOptions.list_resources("res://data/characters"):
		if not (r as CharacterData).in_shop: start.append(String((r as CharacterData).id))
	start.sort()
	assert_eq(start, ["dyer", "olmstead", "peaslee", "whipple"])

func test_las_estadisticas_salen_de_los_atributos() -> void:
	var a := {"POD": 10, "INT": 10, "FUE": 10, "CON": 10, "TEN": 10, "DES": 10, "CUL": 10}
	assert_eq(Attributes.mult(a, "health"), 1.0, "20 puntos = la base")
	a["CON"] = 20
	assert_almost_eq(Attributes.mult(a, "health"), 1.25, 0.0001)
	assert_almost_eq(Attributes.mult(a, "dodge"), 1.25, 0.0001)
	assert_eq(Attributes.mult(a, "sanity"), 1.0, "la cordura no depende de CON")
	a["DES"] = 20
	assert_almost_eq(Attributes.mult(a, "speed"), 1.125, 0.0001, "la velocidad escala a la mitad")

func test_la_subida_es_proporcional_al_nivel_1() -> void:
	var l1 := {"POD": 10, "INT": 20, "FUE": 10, "CON": 10, "TEN": 10, "DES": 10, "CUL": 10}
	var rng := RandomNumberGenerator.new(); rng.seed = 9
	var n := {}
	for i in 16000:
		var k := Attributes.roll_point(l1, rng)
		n[k] = int(n.get(k, 0)) + 1
	assert_almost_eq(float(n["INT"]) / float(n["DES"]), 2.0, 0.15)

func test_subir_de_nivel_suma_un_atributo_y_rehace_la_vida() -> void:
	var p := _player("johansen")
	var h := p.data.max_health
	var before := 0
	for k in p.attrs: before += int(p.attrs[k])
	p.progress.add_xp(p.progress.xp_to_next())
	var after := 0
	for k in p.attrs: after += int(p.attrs[k])
	assert_eq(after, before + 1)
	assert_eq(p.progress.attr_gains.size(), 1)
	assert_true(p.attrs_level1 != p.attrs, "el nivel 1 no cambia")
	assert_gte(p.data.max_health, h)

func test_el_daño_depende_del_tipo_de_arma() -> void:
	var p := _player("varga")                         # POD +12
	assert_gt(p.damage_mult(WeaponData.Category.MAGIC), p.damage_mult(WeaponData.Category.PHYSICAL))

func test_cuatro_armas_como_mucho() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := _player("dyer")
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	for id in ["granada", "webly", "palanca", "corredera"]: p.weapons.add_weapon(load("res://data/weapons/%s.tres" % id))
	for w in DebugOptions.list_resources("res://data/weapons"): p.progress.weapon_pool.append(w)
	var rng := RandomNumberGenerator.new(); rng.seed = 1
	for i in 50:
		for o in p.progress.roll_options(p.weapons, rng):
			assert_ne(o.kind, PlayerProgress.Option.Kind.NEW_WEAPON, "con 4 armas no se ofrecen nuevas")
