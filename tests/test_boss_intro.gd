extends GutTest
## Entrada de los jefes (28-10-2026): cámara lenta que vuelve al ritmo normal y no pisa a quien
## cambie el ritmo, y encuadre de la cámara que va al jefe y vuelve.

func after_each() -> void:
	Engine.time_scale = 1.0

func test_camara_lenta_y_vuelta() -> void:
	var b := BossIntro.new()
	add_child_autofree(b)
	b._slow = true
	b._time_scale(0.0)
	assert_almost_eq(Engine.time_scale, 1.0, 0.01, "empieza a ritmo normal")
	b._time_scale(BossIntro.SLOW_IN + 0.5)
	assert_almost_eq(Engine.time_scale, BossIntro.SLOW, 0.01, "a cámara lenta")
	b._time_scale(BossIntro.SLOW_IN + BossIntro.SLOW_HOLD + BossIntro.SLOW_OUT + 0.1)
	assert_almost_eq(Engine.time_scale, 1.0, 0.01, "y vuelve")
	assert_false(b._slow, "terminada")

func test_no_pisa_otro_ritmo() -> void:
	var b := BossIntro.new()
	add_child_autofree(b)
	b._slow = true
	b._time_scale(BossIntro.SLOW_IN + 0.2)
	Engine.time_scale = 4.0                        # alguien lo cambia (depuración, simulación)
	b._time_scale(BossIntro.SLOW_IN + BossIntro.SLOW_HOLD + 0.3)
	assert_eq(Engine.time_scale, 4.0, "no lo toca")
	assert_false(b._slow)

func test_encuadre_del_jefe() -> void:
	var cam := GameCamera.new()
	add_child_autofree(cam)
	var p := Node3D.new()
	add_child_autofree(p)
	cam.targets.append(p)
	var boss := Node3D.new()
	add_child_autofree(boss)
	boss.position = PlayerMotor.screen_to_world(Vector2(1, 0)) * 30.0      # lejos, a un lado
	var normal := cam._framed_size(cam.needed_size())
	cam.focus(boss, 2.0, 6.0)
	for i in 10: cam._process(0.1)
	assert_almost_eq(cam._focus_w, 1.0, 0.01, "encuadrado")
	assert_gt(cam._framed_size(cam.needed_size()), normal + 1.0, "se abre para que quepa")
	assert_gt(cam._framed_center().distance_to(cam.center()), 5.0, "va hacia el jefe")
	for i in 20: cam._process(0.1)
	assert_eq(cam._focus_w, 0.0, "y vuelve")
	assert_null(cam._focus)
