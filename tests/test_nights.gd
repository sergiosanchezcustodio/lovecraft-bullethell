extends GutTest
## Fase 21, bloque D: noches sueltas (Nights, data/nights.json) y la primera, «El color que cayó del
## cielo» (hito 21.13): el color en el suelo (ColorBlight) y su jefe (ColorBehavior).

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(id := "dyer") -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	return p

func _enemy(id: String, at: Vector3, still := true) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/%s.tres" % id) as EnemyData).duplicate()
	if still:
		d.max_health = 1000.0
		d.move_speed = 0.0
		d.movement = &"chase"
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _blight(host := true) -> ColorBlight:
	var lv: LevelData = load("res://data/levels/noche_color.tres")
	var cb := ColorBlight.new().setup(world, lv, host)
	cb._every = 0.0                                   # sin manchas sueltas: solo las de la prueba
	add_child_autofree(cb)
	return cb

func _step(cb: ColorBlight, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		cb._physics_process(DT)

# ------------------------------------------------------------------ noches sueltas

func test_cada_noche_tiene_nivel_relato_arena_y_textos() -> void:
	var rel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
	assert_false(Nights.all().is_empty())
	for n: Dictionary in Nights.all():
		var id := String(n.id)
		for k in ["titulo", "lugar", "criaturas", "texto"]: assert_ne(String(n.get(k, "")), "", "%s: %s" % [id, k])
		assert_true(Campaign.levels().any(func(l: Dictionary) -> bool: return String(l.id) == String(n.abre)), "%s: abre con un nivel de la campaña" % id)
		var lv: LevelData = load("res://data/levels/%s.tres" % id)
		assert_not_null(lv, id)
		assert_eq(String(lv.id), id)
		assert_true(FileAccess.file_exists(lv.arena), "%s: arena" % id)
		assert_not_null(lv.final_enemy, "%s: con su jefe" % id)
		assert_eq(lv.pool.size(), 2, "%s: dos criaturas" % id)
		assert_true(rel.has(id), "%s: relato" % id)
		assert_ne(Library.text("places", id), "", "%s: texto del lugar" % id)
		assert_true(ResourceLoader.exists("res://resources/maps/%s.png" % id), "%s: mapa (tools/render_mapa.gd)" % id)
		for e: EnemyData in lv.pool + [lv.final_enemy]:
			assert_ne(Library.text("enemies", e.id), "", "%s: texto del bestiario" % e.id)
		assert_true(Nights.is_night(id))
		assert_eq(Nights.label(id), "Noche suelta · " + String(n.titulo))
	assert_false(Nights.is_night("p1_n1"))

func test_se_abren_al_superar_su_nivel_y_cuentan_las_victorias() -> void:
	var s := SaveData.new()
	assert_false(Nights.unlocked(s, "noche_color"))
	assert_false(Nights.any_unlocked(s))
	s.levels_won.append(String(Nights.find("noche_color").abre))
	assert_true(Nights.unlocked(s, "noche_color"))
	assert_eq(Nights.wins(s, "noche_color"), 0)
	Nights.record_win(s, "noche_color")
	Nights.record_win(s, "noche_color")
	assert_eq(Nights.wins(s, "noche_color"), 2)
	assert_eq(Nights.won_count(s), 1)
	Nights.record_win(s, "p1_n1")
	assert_eq(Nights.won_count(s), 1, "lo que no es una noche no cuenta")
	assert_false(s.levels_won.has("noche_color"), "no es un nivel de la campaña")

func test_en_la_biblioteca_salen_su_lugar_y_su_relato() -> void:
	var s := SaveData.new()
	s.unlock_all = true
	var places := Library.entries(s, "places").filter(func(e: Dictionary) -> bool: return String(e.id) == "noche_color")
	assert_eq(places.size(), 1)
	var stories := Library.entries(s, "stories").filter(func(e: Dictionary) -> bool: return String(e.id) == "noche_color")
	assert_eq(stories.size(), 1)
	assert_string_contains(String(stories[0].get("text", "")), "Gardner")

# ------------------------------------------------------------------ el color

func test_la_mancha_crece_dura_y_se_apaga() -> void:
	var p := {"r_max": 3.0, "grow": 0.5, "age": 0.0, "life": 20.0}
	assert_almost_eq(ColorBlight.radius_of(p), ColorBlight.START, 0.01, "nace pequeña: da tiempo a salir")
	p.age = 2.0
	assert_almost_eq(ColorBlight.radius_of(p), ColorBlight.START + 1.0, 0.01)
	p.age = 10.0
	assert_almost_eq(ColorBlight.radius_of(p), 3.0, 0.01, "hasta su tope")
	p.age = 18.0
	assert_almost_eq(ColorBlight.radius_of(p), 1.5, 0.01, "se apaga al final")
	var cb := _blight()
	cb.seed_at(Vector2.ZERO, 2.0, 1.0)
	assert_eq(cb.patches.size(), 1)
	_step(cb, 1.1)
	assert_eq(cb.patches.size(), 0, "se va al acabar su vida")

func test_los_enemigos_dentro_se_vuelven_grises_y_quebradizos() -> void:
	var cb := _blight()
	var inside := _enemy("pinguino", Vector3(1, 0, 0))
	var out := _enemy("pinguino", Vector3(9, 0, 0))
	cb.seed_at(Vector2.ZERO, 3.0)
	cb.patches[0].age = 20.0                          # ya ha crecido
	_step(cb, 0.3)
	assert_true(inside.is_blighted())
	assert_false(out.is_blighted())
	var h := inside.health
	inside.take_damage(Damage.new(10.0, 0.0))
	assert_almost_eq(h - inside.health, 10.0 * (1.0 + cb.level.blight_enemy), 0.01, "reciben más daño")
	assert_ne(inside._status_color().a, 0.0, "y se ven grises")

func test_el_jugador_dentro_pierde_cordura_y_los_golpes_le_hacen_mas() -> void:
	var cb := _blight()
	var p := _player()
	var q := _player("legrasse")
	q.position = Vector3(12, 0, 0)
	cb.seed_at(Vector2.ZERO, 3.0)
	cb.patches[0].age = 20.0
	var san := p.sanity
	_step(cb, 1.0)
	assert_gt(p.blight_t, 0.0, "gris y quebradizo")
	assert_lt(p.sanity, san, "pierde cordura")
	assert_eq(q.blight_t, 0.0, "el de fuera, no")
	var h := p.health
	p.take_damage(Damage.new(10.0, 0.0))
	var hurt := h - p.health
	p.blight_t = 0.0
	p._hurt_time = 99.0
	h = p.health
	p.take_damage(Damage.new(10.0, 0.0))
	assert_almost_eq(hurt, (h - p.health) * (1.0 + Player.BLIGHT_HURT), 0.05, "un 30 % más")

func test_lo_que_nace_del_color_no_se_agrisa() -> void:
	var cb := _blight()
	var boss := _enemy("color_pozo", Vector3(1, 0, 0))
	cb.seed_at(Vector2(1, 0), 3.0)
	cb.patches[0].age = 20.0
	_step(cb, 0.3)
	assert_false(boss.is_blighted())

func test_las_reses_dejan_su_mancha_al_morir() -> void:
	var cb := _blight()
	var e := _enemy("res_gris", Vector3(4, 0, 2))
	assert_gt(float(e.data.param("blight_on_death", 0.0)), 0.0)
	cb.on_enemy_died(e)
	assert_eq(cb.patches.size(), 1)
	assert_eq(cb.patches[0].pos, Vector2(4, 2))

func test_en_el_invitado_las_manchas_llegan_del_anfitrion() -> void:
	var cb := _blight(false)
	var p := _player()
	var e := _enemy("pinguino", Vector3(1, 0, 0))
	cb.seed_at(Vector2.ZERO, 3.0)
	assert_true(cb.patches.is_empty(), "no las decide")
	cb.remote({"x": 0.0, "z": 0.0, "r": 3.0, "l": 30.0, "s": 5})
	assert_eq(cb.patches.size(), 1)
	cb.patches[0].age = 20.0
	_step(cb, 0.5)
	assert_gt(p.blight_t, 0.0, "a sus jugadores, sí")
	assert_false(e.is_blighted(), "los enemigos los lleva el anfitrión")

# ------------------------------------------------------------------ el jefe

func test_el_color_sube_del_pozo_y_siembra() -> void:
	var cb := _blight()
	var p := _player()
	p.position = Vector3(4, 0, 4)
	var boss := _enemy("color_pozo", Vector3(20, 0, 20), false)
	var from: Vector2 = boss.data.param("from", Vector2.ZERO)
	assert_almost_eq(boss.position.x, from.x, 0.01, "sale del pozo")
	assert_almost_eq(boss.position.z, from.y, 0.01)
	assert_lt(boss.position.y, 0.0, "desde abajo")
	assert_gt(boss.shield_t, 0.0, "sin que le hagan daño mientras sube")
	var b := boss.behavior as ColorBehavior
	assert_not_null(b)
	assert_false(b.touches(boss))
	for i in int((ColorBehavior.RISE + 0.1) / DT): b.update(boss, p, DT)
	assert_gt(boss.position.y, 0.2, "flota")
	assert_true(b.touches(boss))
	b._sow(boss)
	assert_eq(cb.patches.size(), 1, "siembra el color")
	assert_lt(cb.patches[0].pos.distance_to(Vector2(4, 4)), 1.6, "bajo los pies de un jugador")
	assert_eq(b.phase_for(boss), 1)
	boss.health = boss.data.max_health * 0.5
	assert_eq(b.phase_for(boss), 2)
	boss.health = boss.data.max_health * 0.2
	assert_eq(b.phase_for(boss), 3)

# ------------------------------------------------------------------ mejoras (consejo, logro)

func test_pisar_el_color_quita_el_logro_salvo_a_los_bots() -> void:
	var cb := _blight()
	var bot := _player()
	cb.seed_at(Vector2.ZERO, 3.0)
	cb.patches[0].age = 20.0
	_step(cb, 0.3)
	assert_gt(bot.blight_t, 0.0)
	assert_false(cb.touched, "un bot no cuenta")
	var me := Player.new().setup(load("res://data/characters/legrasse.tres"), KeyboardInput.new(), Color.RED)
	me.world = world
	world.add_child(me)
	world.add_player(me)
	_step(cb, 0.3)
	assert_true(cb.touched, "quien juega en este PC, sí")

func test_el_logro_sin_tocar_el_color() -> void:
	var a: AchievementData = load("res://data/achievements/31_sin_tocar_el_color.tres")
	assert_eq(a.stat, "color_untouched")
	assert_eq(a.icon_model, "color_pozo")
	var s := SaveData.new()
	assert_eq(Achievements.value(s, a), 0)
	Achievements.add(s, "color_untouched")
	assert_true(Achievements.check(s).has(a))
	var tips: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial.json"))
	assert_true((tips.tips as Array).any(func(t: Dictionary) -> bool: return String(t.when) == "blight"), "consejo al pisarlo")
