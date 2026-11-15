extends GutTest
## Hito 21.11: Nyarlathotep, el Caos reptante, jefe de la parte 4 (NyarlaBehavior): tres formas, una por fase.

const DT := 1.0 / 60.0
var world: CombatWorld

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(at := Vector3.ZERO) -> Player:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	p.position = at
	world.add_child(p)
	world.add_player(p)
	return p

func _boss(at := Vector3(6, 0, 0)) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/nyarlathotep.tres") as EnemyData).duplicate()
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _hurt_to(e: Enemy, k: float) -> void:
	e.health = e.data.max_health * e.health_scale * k

func test_es_el_jefe_de_la_parte() -> void:
	var lv: LevelData = load("res://data/levels/p4_n5.tres")
	assert_eq(String(lv.final_enemy.id), "nyarlathotep")
	assert_false(lv.is_survival(), "ya no es la horda provisional")
	var d := lv.final_enemy
	assert_true(d.unique)
	for k in [1, 2, 3]:
		var m := String(d.param("form_%d" % k, ""))
		assert_true(ResourceLoader.exists("res://models/%s.json" % m) or FileAccess.file_exists("res://models/%s.json" % m), "existe %s" % m)
		assert_true(Anims.script_for(m) != null, "%s se anima" % m)
	assert_true(Anims.script_for("nyarla_forma") != null)
	for m in ["nyarla_faraon", "nyarla_sin_rostro"]:               # anim_humano necesita las piernas (las espinillas las crean)
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://models/%s.json" % m))
		var parts := {}
		for v: Array in j.voxels: parts[String(v[3])] = true
		assert_true(parts.has("shin_l") and parts.has("shin_r"), "%s tiene piernas" % m)

func test_cambia_de_forma_por_fases() -> void:
	var p := _player()
	var e := _boss()
	var b := e.behavior as NyarlaBehavior
	assert_eq(e.model_name, "nyarla_faraon", "empieza de faraón")
	_hurt_to(e, 0.6)
	b.update(e, p, DT)
	assert_eq(b.phase, 2)
	assert_eq(e.model_name, "nyarla_nucleo", "se deshace en el enjambre")
	assert_gt(e.shield_t, 0.0, "invulnerable al cambiar")
	_hurt_to(e, 0.3)
	b.update(e, p, DT)
	assert_eq(b.phase, 3)
	assert_eq(e.model_name, "nyarla_sin_rostro", "el ser sin rostro")
	assert_almost_eq(e.model_scale, 3.0, 0.01, "enorme")

func test_el_faraon_habla_y_dispara() -> void:
	var p := _player()
	var e := _boss()
	var b := e.behavior as NyarlaBehavior
	b._words = 0.0
	b._fan = 0.0
	b.update(e, p, DT)
	assert_eq(b._line, 1, "dice una frase")
	assert_true(e.runner.busy, "lanza el abanico")

func test_el_enjambre_se_recompone_junto_al_mas_alejado() -> void:
	var near := _player(Vector3(4, 0, 0))
	var far := _player(Vector3(-10, 0, 3))
	var e := _boss(Vector3(6, 0, 0))
	var b := e.behavior as NyarlaBehavior
	_hurt_to(e, 0.6)
	b.update(e, near, DT)
	e.shield_t = 0.0
	b._recompose = 0.0
	b.update(e, near, DT)
	assert_true(e.buried, "se esfuma")
	assert_false(b.touches(e), "esfumado no toca")
	var hp0 := far.health
	for i in int(1.5 / DT):
		world.rebuild_grid()
		b.update(e, near, DT)
	assert_eq(b.recomposed, 1)
	assert_false(e.buried, "vuelve a tener cuerpo")
	assert_lt(Vector2(e.global_position.x - far.global_position.x, e.global_position.z - far.global_position.z).length(), 0.5, "junto al más alejado")
	assert_lt(far.health, hp0, "y le golpea al llegar")

func test_el_ser_sin_rostro_quita_cordura_y_lanza_llamas() -> void:
	var p := _player()
	var e := _boss()
	var b := e.behavior as NyarlaBehavior
	_hurt_to(e, 0.3)
	b.update(e, p, DT)
	var s0 := p.sanity
	b._flame = 0.0
	for i in int(1.0 / DT): b.update(e, p, DT)
	assert_lt(p.sanity, s0, "la cordura baja todo el rato")
	assert_gte(b.flames, 4, "llamas negras bajo los jugadores y alrededor")

func test_en_el_invitado_cambia_de_forma_por_la_vida() -> void:
	var p := _player()
	var e := _boss()
	var b := e.behavior as NyarlaBehavior
	_hurt_to(e, 0.3)
	var s0 := p.sanity
	for i in 30: b.puppet_step(e, DT)
	assert_eq(e.model_name, "nyarla_sin_rostro", "la marioneta enseña la forma de su vida")
	assert_lt(p.sanity, s0, "y quita la cordura a los de su PC")
