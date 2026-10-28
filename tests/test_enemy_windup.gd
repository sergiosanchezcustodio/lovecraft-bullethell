extends GutTest
## Preparación antes de un ataque con aviso (hito 12.5): sube mientras dura el aviso, aguanta, y al
## terminar suelta el golpe y vuelve a reposo.

func test_tiempos() -> void:
	var e := Enemy.new()
	e.windup(1.0)
	assert_eq(e.windup_amount(), Vector2.ZERO, "empieza en reposo")
	e._wu_t = 0.3
	assert_between(e.windup_amount().x, 0.2, 0.8, "se va preparando")
	e._wu_t = 0.8
	assert_almost_eq(e.windup_amount().x, 1.0, 0.001, "preparado y aguanta")
	assert_eq(e.windup_amount().y, 0.0, "sin golpe aún")
	e._wu_t = 1.0 + Enemy.WINDUP_RELEASE * 0.3
	assert_almost_eq(e.windup_amount().y, 1.0, 0.001, "suelta el golpe")
	e._wu_t = 1.0 + Enemy.WINDUP_RELEASE
	assert_eq(e.windup_amount(), Vector2.ZERO, "y vuelve")
	e.free()

func test_avisos_muy_cortos_no() -> void:
	var e := Enemy.new()
	e.windup(0.05)
	assert_eq(e._wu_t, -1.0)
	e.free()

func test_familias_con_gesto() -> void:
	for m in ["sacerdote", "cultista", "acechador", "engendro", "hydra", "dagon", "cthulhu", "polipo_madre"]:
		assert_true(Anims.has_windup(m), m)
