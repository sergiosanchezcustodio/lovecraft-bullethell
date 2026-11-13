extends GutTest
## Hito 21.3: vínculos entre investigadores (Bonds, data/bonds.json).

var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(id: String, at: Vector3) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.world = world
	p.global_position = at
	return p

func _bonds(players: Array, speak := false) -> Bonds:
	var b := Bonds.new().setup(world, players, speak)
	add_child_autofree(b)
	b.set_physics_process(false)
	b.step(Bonds.SCAN)
	return b

func test_los_datos_estan_bien() -> void:
	var known := ["stat", "tag", "dream_heal", "revive_heal"]
	var seen := {}
	for b: Dictionary in Bonds.all():
		assert_false(seen.has(b.id), "id repetido: %s" % b.id)
		seen[b.id] = true
		for id in [b.a, b.b]:
			assert_true(ResourceLoader.exists("res://data/characters/%s.tres" % id), "%s: %s" % [b.id, id])
		assert_ne(String(b.get("titulo", "")), "", b.id)
		assert_ne(String(b.get("texto", "")), "", b.id)
		var lines: Array = b.get("dialogo", [])
		assert_eq(lines.size(), 2, "%s: frase y respuesta" % b.id)
		for l: Array in lines: assert_true(String(l[0]) == String(b.a) or String(l[0]) == String(b.b), "%s: habla uno de los dos" % b.id)
		for e: Dictionary in b.get("efectos", []):
			assert_true(String(e.tipo) in known, "%s: %s" % [b.id, e.tipo])
			var who := String(e.get("quien", "ambos"))
			assert_true(who == "ambos" or who == String(b.a) or who == String(b.b), "%s: quien" % b.id)
			if String(e.tipo) == "stat": assert_true(String(e.stat) in Player.ITEM_STATS or String(e.stat) == "xp_mult", "%s: %s" % [b.id, e.stat])
			var v := float(e.valor)
			assert_true(absf(v - 1.0) <= 0.31 if String(e.tipo) in ["stat", "tag"] else v <= 0.2, "%s: una ventaja pequeña" % b.id)

func test_entre_quienes_hay_vinculo() -> void:
	var found := Bonds.between(["carter", "kuranes", "dyer"])
	assert_eq(found.size(), 1)
	assert_eq(String(found[0].id), "sonadores")
	assert_eq(Bonds.between(["carter", "pickman", "kuranes"]).size(), 2, "Carter con los dos")
	assert_true(Bonds.between(["dyer", "olmstead"]).is_empty())

func test_cerca_tienen_la_ventaja_y_lejos_la_pierden() -> void:
	var a := _player("legrasse", Vector3.ZERO)
	var b := _player("johansen", Vector3(3, 0, 0))
	var base := float(a.data.bonus_tags.get(&"humana", 1.0))
	var bonds := _bonds([a, b])
	assert_eq(bonds.friends_near(a), [b] as Array[Player])
	assert_almost_eq(float(a.data.bonus_tags.get(&"humana", 1.0)), base * 1.1, 0.001, "Legrasse, un 10 % más")
	assert_almost_eq(float(b.data.bonus_tags.get(&"humana", 1.0)), 1.1, 0.001, "y Johansen")
	b.global_position = Vector3(Bonds.radius() + 0.5, 0, 0)       # en el borde: aún cerca (no parpadea)
	bonds.step(Bonds.SCAN)
	assert_false(bonds.friends_near(a).is_empty())
	b.global_position = Vector3(Bonds.radius() + Bonds.LEAVE + 0.5, 0, 0)
	bonds.step(Bonds.SCAN)
	assert_true(bonds.friends_near(a).is_empty())
	assert_almost_eq(float(a.data.bonus_tags.get(&"humana", 1.0)), base, 0.001, "lejos, como siempre")
	assert_false(b.data.bonus_tags.has(&"humana"))

func test_las_estadisticas_se_multiplican_y_vuelven() -> void:
	var d := _player("dyer", Vector3.ZERO)
	var p := _player("peaslee", Vector3(2, 0, 2))
	var xp := 1.0
	var bonds := Bonds.new().setup(world, [d, p], false)
	add_child_autofree(bonds)
	bonds.set_physics_process(false)
	p.global_position = Vector3(30, 0, 0)
	bonds.step(Bonds.SCAN)
	xp = d.data.xp_mult
	p.global_position = Vector3(2, 0, 2)
	bonds.step(Bonds.SCAN)
	assert_almost_eq(d.data.xp_mult, xp * 1.1, 0.001)
	d.rebuild_stats()                                    # otra subida de nivel no lo acumula
	assert_almost_eq(d.data.xp_mult, xp * 1.1, 0.001)
	p.global_position = Vector3(30, 0, 0)
	bonds.step(Bonds.SCAN)
	assert_almost_eq(d.data.xp_mult, xp, 0.001)

func test_solo_al_que_le_toca() -> void:
	var c := _player("carter", Vector3.ZERO)
	var k := _player("pickman", Vector3(1, 0, 0))
	var g := _player("gilman", Vector3(0, 0, 1))
	var i := _player("iwanicki", Vector3(1, 0, 1))
	_bonds([c, k, g, i])
	assert_almost_eq(k.data.ally_mult, 1.3, 0.001, "los necrófagos de Pickman, con Carter cerca")
	assert_almost_eq(c.data.ally_mult, 1.0, 0.001, "Carter, no")
	assert_true(g.bond.has("stat:mental_mult"), "Gilman, con el crucifijo")
	assert_false(i.bond.has("stat:mental_mult"), "el padre, no")

func test_los_suenos_de_kuranes_curan_a_carter() -> void:
	var c := _player("carter", Vector3.ZERO)
	var k := _player("kuranes", Vector3(2, 0, 0))
	_bonds([c, k])
	c.health = c.data.max_health * 0.5
	k.health = k.data.max_health * 0.5
	var z := DreamZone.new().setup(world, Vector3.ZERO, 4.0, 10.0, 0.0, 0.5, 1.0, 1.0, 1.0, {})
	world.add_child(z)
	for n in 30: z._physics_process(1.0 / 30.0)
	assert_gt(c.health, c.data.max_health * 0.5 + 0.5, "Carter se cura en el sueño")
	assert_eq(k.health, k.data.max_health * 0.5, "Kuranes, no (el vínculo es para Carter)")

func test_los_medicos_levantan_con_mas_vida() -> void:
	var w := _player("west", Vector3.ZERO)
	var h := _player("whipple", Vector3(0.5, 0, 0))
	_bonds([w, h])
	h.revivable = true
	h.health = 0.0
	h.down_left = 10.0
	h._downed_step(0.01)                                 # West, al lado: él la levanta
	h.revive()
	assert_almost_eq(h.health, h.data.max_health * (h.rules.revive_health + 0.15), 0.01)

func test_el_dialogo_solo_al_empezar_la_parte() -> void:
	var c := _player("carter", Vector3.ZERO)
	var k := _player("kuranes", Vector3(2, 0, 0))
	var quiet := _bonds([c, k], false)
	quiet.step(20.0)
	assert_eq(quiet._bubbles.size(), 0, "sin diálogo al pasar de nivel")
	var talk := _bonds([c, k], true)
	talk.step(Bonds.TALK_AT)
	assert_eq(talk._bubbles.size(), 1, "habla Carter")
	assert_eq(talk._bubbles[0].who, c)
	talk.step(Bonds.TALK_GAP)
	assert_eq(talk._bubbles.size(), 2, "y responde Kuranes")
	assert_eq(talk._bubbles[1].who, k)

func test_al_subir_se_saludan() -> void:
	assert_true(Anims.has_anim("carter", "bond_wave"))
	var c := _player("carter", Vector3.ZERO)
	var k := _player("kuranes", Vector3(2, 0, 0))
	var bonds := _bonds([c, k])
	assert_eq(bonds.friends_near(c), [k] as Array[Player])
	c.look_at_friend(k, 1.0)
	assert_eq(c._friend, k)
