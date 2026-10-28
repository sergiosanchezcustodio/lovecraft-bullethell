extends GutTest
## Hito 11.2: números de daño (DamageNumbers), temblor de cámara con ruido suave (GameCamera) y
## gemas que arrancan despacio, aceleran y hacen latir el anillo al llegar (GemManager).

func after_each() -> void:
	DamageNumbers.set_mode(2)

func test_los_golpes_seguidos_se_suman() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var a := Node3D.new(); var b := Node3D.new()
	add_child_autofree(a); add_child_autofree(b)
	DamageNumbers.add(fx, a, 10.0, Vector3.ZERO)
	DamageNumbers.add(fx, a, 5.0, Vector3.ZERO)
	DamageNumbers.add(fx, b, 7.0, Vector3.ZERO)
	var dn: DamageNumbers = fx.get_meta("damage_numbers")
	assert_eq(dn.count(), 2, "una cifra por enemigo")
	dn._process(0.0)
	assert_eq((dn._items[0][0] as Label3D).text, "15", "sumadas")
	dn._process(DamageNumbers.MERGE + 0.05)
	DamageNumbers.add(fx, a, 3.0, Vector3.ZERO)
	assert_eq(dn.count(), 3, "pasado el rato, otra cifra")
	dn._process(DamageNumbers.LIFE - DamageNumbers.MERGE)     # las dos primeras acaban; la nueva, no
	assert_eq(dn.count(), 1, "las viejas se van")
	assert_eq(dn._spare.size(), 2, "y sus etiquetas se guardan para reutilizarlas")

func test_tope_de_cifras() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	for i in DamageNumbers.MAX + 10:
		var n := Node3D.new()
		add_child_autofree(n)
		DamageNumbers.add(fx, n, 1.0, Vector3.ZERO)
	var dn: DamageNumbers = fx.get_meta("damage_numbers")
	assert_eq(dn.count(), DamageNumbers.MAX)
	assert_eq(dn.get_child_count(), DamageNumbers.MAX, "no se crean más etiquetas")

func test_sin_cifras_si_estan_quitadas() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	DamageNumbers.enabled = false
	DamageNumbers.add(fx, fx, 10.0, Vector3.ZERO)
	assert_false(fx.has_meta("damage_numbers"))

func test_ruido_del_temblor_suave_y_acotado() -> void:
	var prev := GameCamera._noise(0.0, 0)
	var worst := 0.0
	for i in range(1, 2000):
		var v := GameCamera._noise(i * 0.01, 0)
		assert_between(v, -1.0, 1.0)
		worst = maxf(worst, absf(v - prev))
		prev = v
	assert_lt(worst, 0.05, "sin saltos entre pasos seguidos")
	assert_ne(GameCamera._noise(3.5, 0), GameCamera._noise(3.5, 101), "cada eje, su ruido")

func test_las_gemas_aceleran_y_llegan() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	var gems := GemManager.new()
	gems.world = world
	gems.rules = load("res://data/progression/default.tres")
	world.add_child(gems)
	gems.drop(Vector3(1.0, 0.0, 0.0), 5.0)
	gems._pos[0] = Vector3(1.0, 0.3, 0.0)
	gems._age[0] = 1.0
	gems._physics_process(1.0 / 60.0)
	assert_gt(gems._vel[0].x, 0.0, "primero, un saltito hacia atrás")
	var t := 0.0
	while gems.count > 0 and t < 2.0:
		gems._physics_process(1.0 / 60.0)
		t += 1.0 / 60.0
	assert_eq(gems.count, 0, "llega")
	assert_lt(t, 0.8, "en poco rato")
	assert_gt(p._gem_pulse, 0.0, "el anillo late")

func test_solo_los_golpes_fuertes() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	DamageNumbers.set_mode(1)
	DamageNumbers.add(fx, fx, 10.0, Vector3.ZERO)
	assert_false(fx.has_meta("damage_numbers"), "los normales no salen")
	DamageNumbers.add(fx, fx, 10.0, Vector3.ZERO, true)
	assert_eq((fx.get_meta("damage_numbers") as DamageNumbers).count(), 1, "los fuertes sí")

func test_modo_de_las_configuraciones_de_antes() -> void:
	assert_eq(DamageNumbers.mode_of(true), 2)
	assert_eq(DamageNumbers.mode_of(false), 0)
	assert_eq(DamageNumbers.mode_of(1), 1)

func test_las_llamas_se_agitan_con_las_rafagas() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	assert_eq(Gusts.gutter_at(Vector3(2, 0, 0)), 0.0, "sin ráfagas, quietas")
	Gusts.push(fx, Vector3.ZERO, 0.2, 6.0)
	assert_eq(Gusts.gutter_at(Vector3(1, 0, 0)), 1.0, "una explosión al lado casi la apaga")
	assert_eq(Gusts.gutter_at(Vector3(20, 0, 0)), 0.0, "lejos, nada")
	assert_lt(Gusts.gutter_k(1.0, 0.0, 0.0), 0.6)
	assert_eq(Gusts.gutter_k(0.0, 0.0, 0.0), 1.0)
