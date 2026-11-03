extends GutTest
## Enemigos nuevos de la fase 15 (hito 15.3): el expedicionario se levanta si no lo rematan y el
## tambor del tamborilero acelera a los cercanos.

const DT := 1.0 / 60.0
var world: CombatWorld
var root: Node3D
var obstacles: ObstacleMap

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)

func _enemy(id: String, pos: Vector3) -> Enemy:
	var e := Enemy.new().setup(load("res://data/enemies/%s.tres" % id), world, obstacles)
	e.position = pos
	root.add_child(e)
	e._rise_wait = 0.0                              # ya ha aparecido
	return e

func _step(e: Enemy, seconds: float) -> void:
	for i in int(seconds / DT): e._physics_process(DT)

func test_los_tres_existen_y_salen_en_su_nivel() -> void:
	for pair in [["expedicionario", "p1_n2"], ["nadador", "p2_n4"], ["nadador", "p2_n5"], ["tamborilero", "p3_n2"]]:
		var d: EnemyData = load("res://data/enemies/%s.tres" % pair[0])
		assert_true(FileAccess.file_exists("res://models/%s.json" % d.model), d.model)
		assert_ne(Library.text("enemies", String(d.id)), "", "texto del bestiario de " + pair[0])
		var lv: LevelData = load("res://data/levels/%s.tres" % pair[1])
		assert_true(lv.pool.any(func(x: EnemyData) -> bool: return x.id == d.id), "%s en %s" % pair)

func test_el_expedicionario_se_levanta_si_no_lo_rematan() -> void:
	var e := _enemy("expedicionario", Vector3.ZERO)
	e.take_damage(Damage.new(1e4, 0.0))
	assert_true(e.is_alive(), "cae, pero no muere")
	assert_eq(e.anim, "down")
	_step(e, e.data.revive_time + 0.1)
	assert_almost_eq(e.health, e.data.max_health * e.health_scale * e.data.revive, 0.01, "se levanta con media vida")
	_step(e, 1.0)
	assert_eq(e.anim, "walk")
	e.take_damage(Damage.new(1e4, 0.0))
	assert_false(e.is_alive(), "la segunda vez, muere")

func test_caido_un_golpe_lo_remata() -> void:
	var e := _enemy("expedicionario", Vector3.ZERO)
	e.take_damage(Damage.new(1e4, 0.0))
	_step(e, 0.5)
	e.take_damage(Damage.new(1.0, 0.0))
	assert_false(e.is_alive())

func test_el_tambor_acelera_a_los_cercanos() -> void:
	var drum := _enemy("tamborilero", Vector3.ZERO)
	var near := _enemy("cultista", Vector3(3, 0, 0))
	var far := _enemy("cultista", Vector3(20, 0, 0))
	for e in [drum, near, far]: world.enemies.append(e)
	_step(drum, 0.1)
	assert_gt(near.drum_t, 0.0, "el cercano, al ritmo")
	assert_eq(far.drum_t, 0.0, "el lejano, no")

func test_el_bestiario_cuenta_bajas_y_quien_mas() -> void:
	var s := SaveData.new()
	assert_eq(Library.kill_facts(s, "pinguino"), [], "sin bajas, nada")
	for i in 3: Library.add_kill(s, "pinguino", "dyer")
	Library.add_kill(s, "pinguino", "peaslee")
	Library.add_kill(s, "pinguino", "")
	var f := Library.kill_facts(s, "pinguino")
	assert_eq(f[0], "Abatidos: 5")
	assert_true(String(f[1]).begins_with("Quien más: William Dyer (3)"), String(f[1]))
	var back := SaveData.from_dict(s.to_dict())
	assert_eq(Library.kill_facts(back, "pinguino")[0], "Abatidos: 5", "se guarda")

## Fase 16, hito 16.16: el shoggoth excavador y el Antiguo sembrador.
func test_los_de_la_parte_1_existen_y_salen_en_su_nivel() -> void:
	for pair in [["shoggoth_excavador", "p1_n3"], ["shoggoth_excavador", "p1_n5"], ["antiguo_sembrador", "p1_n4"], ["antiguo_sembrador", "p1_n5"]]:
		var d: EnemyData = load("res://data/enemies/%s.tres" % pair[0])
		assert_true(FileAccess.file_exists("res://models/%s.json" % d.model), d.model)
		assert_ne(Library.text("enemies", String(d.id)), "", "texto del bestiario de " + pair[0])
		var lv: LevelData = load("res://data/levels/%s.tres" % pair[1])
		assert_true(lv.pool.any(func(x: EnemyData) -> bool: return x.id == d.id), "%s en %s" % pair)

func test_el_excavador_se_entierra_y_sale_bajo_el_jugador() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.position = Vector3(6, 0, 0)
	var e := _enemy("shoggoth_excavador", Vector3.ZERO)
	world.enemies.append(e)
	var b := e.behavior as BurrowBehavior
	b._t = 10.0                                      # se entierra ya
	_step(e, 0.6)
	assert_true(e.buried, "bajo tierra")
	assert_false(e.visual.visible)
	world.rebuild_grid()
	assert_null(world.nearest_enemy(Vector3.ZERO, 20.0), "no se le puede apuntar")
	assert_ne(e.net_flags2() & 16, 0, "viaja en la foto")
	var hp := e.health
	e.take_damage(Damage.new(50.0, 0.0))
	_step(e, 4.0)
	assert_false(e.buried, "ha salido")
	assert_lt(Vector2(e.position.x - 6.0, e.position.z).length(), 1.3, "debajo del jugador")

func test_el_sembrador_planta_vainas_que_revientan() -> void:
	var e := _enemy("antiguo_sembrador", Vector3.ZERO)
	(e.behavior as SowBehavior)._sow = 0.0
	_step(e, 0.05)
	var pods := e.get_tree().get_nodes_in_group(&"spore_pods")
	assert_eq(pods.size(), 1, "una vaina")
	var pod := pods[0] as SporePod
	pod._t = pod.life                                # nadie la pisa: revienta sola
	pod._physics_process(DT)
	assert_true(pod._fuse > 0.0, "se enciende")
	for i in 40: if is_instance_valid(pod): pod._physics_process(DT)
	assert_true(not is_instance_valid(pod) or pod.is_queued_for_deletion(), "reventada")

## Fase 16, hito 16.17: el guardián de la Orden y la hija de los Marsh.
func test_los_de_la_parte_2_existen_y_salen_en_su_nivel() -> void:
	for pair in [["guardian_orden", "p2_n2"], ["guardian_orden", "p2_n3"], ["hija_marsh", "p2_n3"], ["hija_marsh", "p2_n4"]]:
		var d: EnemyData = load("res://data/enemies/%s.tres" % pair[0])
		assert_true(FileAccess.file_exists("res://models/%s.json" % d.model), d.model)
		assert_ne(Library.text("enemies", String(d.id)), "", "texto del bestiario de " + pair[0])
		var lv: LevelData = load("res://data/levels/%s.tres" % pair[1])
		assert_true(lv.pool.any(func(x: EnemyData) -> bool: return x.id == d.id), "%s en %s" % pair)

func test_el_escudo_del_guardian_para_lo_de_frente() -> void:
	var e := _enemy("guardian_orden", Vector3.ZERO)
	e.facing = Vector3(0, 0, 1)
	var hp := e.health
	var front := Damage.new(20.0, 0.0)
	front.dir = Vector3(0, 0, -1)                   # le llega de frente
	e.take_damage(front)
	assert_eq(e.health, hp, "de frente, nada")
	var back := Damage.new(20.0, 0.0)
	back.dir = Vector3(0, 0, 1)                     # por la espalda
	e.take_damage(back)
	assert_lt(e.health, hp, "por detrás, sí")
	var hp2 := e.health
	var side := Damage.new(20.0, 0.0)
	side.dir = Vector3(1, 0, 0)                     # de lado
	e.take_damage(side)
	assert_lt(e.health, hp2, "de lado, también")
	var zone := Damage.new(5.0, 0.0)                # sin dirección (zonas): pasa
	var hp3 := e.health
	e.take_damage(zone)
	assert_lt(e.health, hp3)

func test_la_hija_de_los_marsh_cura_a_los_marinos() -> void:
	var singer := _enemy("hija_marsh", Vector3.ZERO)
	var deep := _enemy("profundo", Vector3(3, 0, 0))
	var cult := _enemy("acolito", Vector3(-3, 0, 0))
	var far := _enemy("profundo", Vector3(20, 0, 0))
	for e in [singer, deep, cult, far]: e.health *= 0.5    # (se apuntan solos en world.enemies)
	world.rebuild_grid()
	var hd := deep.health
	var hc := cult.health
	var hf := far.health
	assert_eq((singer.behavior as SingBehavior).sing(singer), 1)
	assert_gt(deep.health, hd, "el Profundo cercano se cura")
	assert_eq(cult.health, hc, "el acólito, no (no es marino)")
	assert_eq(far.health, hf, "el lejano, no")

## Fase 16, hito 16.18: el sonámbulo de Providence y el ídolo vivo.
func test_los_de_la_parte_3_existen_y_salen_en_su_nivel() -> void:
	for pair in [["sonambulo", "p3_n1"], ["sonambulo", "p3_n4"], ["idolo_vivo", "p3_n2"], ["idolo_vivo", "p3_n3"]]:
		var d: EnemyData = load("res://data/enemies/%s.tres" % pair[0])
		assert_true(FileAccess.file_exists("res://models/%s.json" % d.model), d.model)
		assert_ne(Library.text("enemies", String(d.id)), "", "texto del bestiario de " + pair[0])
		var lv: LevelData = load("res://data/levels/%s.tres" % pair[1])
		assert_true(lv.pool.any(func(x: EnemyData) -> bool: return x.id == d.id), "%s en %s" % pair)

func test_el_sonambulo_aparece_al_lado() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.position = Vector3(10, 0, 0)
	var e := _enemy("sonambulo", Vector3.ZERO)
	(e.behavior as DreamBehavior)._blink = 0.0
	_step(e, 0.05)
	assert_true(e.buried, "desvanecido")
	assert_false(e.visual.visible)
	_step(e, 1.0)
	assert_false(e.buried, "ha vuelto")
	assert_lt(Vector2(e.position.x - 10.0, e.position.z).length(), 2.5, "al lado del jugador")

func test_el_idolo_no_se_mueve_y_ampara_a_los_cercanos() -> void:
	var idol := _enemy("idolo_vivo", Vector3.ZERO)
	var near := _enemy("cultista", Vector3(3, 0, 0))
	var far := _enemy("cultista", Vector3(15, 0, 0))
	assert_eq((idol.behavior as IdolBehavior).guard(idol), 1)
	assert_gt(near.idol_t, 0.0)
	assert_eq(far.idol_t, 0.0)
	var a := near.health
	near.take_damage(Damage.new(10.0, 0.0))
	var b := far.health
	far.take_damage(Damage.new(10.0, 0.0))
	assert_almost_eq(a - near.health, (b - far.health) * Enemy.IDOL_GUARD, 0.01, "el amparado recibe menos")
	idol.position = Vector3(1, 0, 0)                 # lo empujan: vuelve a su sitio
	_step(idol, 1.0)
	assert_lt(idol.position.length(), 0.1)

## Fase 16, hito 16.19: un jefe intermedio en el nivel 3 de cada parte.
func test_los_jefes_intermedios_salen_en_su_nivel() -> void:
	for pair in [["gedney", "p1_n3"], ["obed_marsh", "p2_n3"], ["castro", "p3_n2"]]:
		var d: EnemyData = load("res://data/enemies/%s.tres" % pair[0])
		assert_true(d.unique and d.elite, pair[0] + " es único")
		assert_true(FileAccess.file_exists("res://models/%s.json" % d.model), d.model)
		assert_ne(Library.text("enemies", String(d.id)), "", "texto del bestiario de " + pair[0])
		var lv: LevelData = load("res://data/levels/%s.tres" % pair[1])
		assert_true(lv.mid_enemies.any(func(x: EnemyData) -> bool: return x.id == d.id), "%s en %s" % pair)
		assert_lt(lv.mid_times[0], lv.final_time, "antes del final")
		assert_eq(lv.mid_texts.size(), lv.mid_enemies.size())
