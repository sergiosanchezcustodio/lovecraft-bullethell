extends GutTest
## Giro de los enemigos y las mascotas hacia donde van (Enemy.turn_flat, 06-11-2026).

func test_gira_la_parte_del_angulo() -> void:
	var f := Enemy.turn_flat(Vector3.FORWARD, Vector3.RIGHT, 0.5)
	assert_almost_eq(f.length(), 1.0, 1e-5)
	assert_almost_eq(rad_to_deg(Vector3.FORWARD.angle_to(f)), 45.0, 0.01)
	assert_almost_eq(Enemy.turn_flat(Vector3.FORWARD, Vector3.RIGHT, 1.0).distance_to(Vector3.RIGHT), 0.0, 1e-5)

func test_casi_iguales_sin_avisos() -> void:
	var a := Vector3(0.6, 0.0, 0.8)
	var b := Vector3(0.6000001, 0.0, 0.7999999)
	var f := Enemy.turn_flat(a, b, 0.3)
	assert_almost_eq(f.distance_to(a), 0.0, 1e-4)
	assert_eq(f.y, 0.0, "en horizontal")

func test_sin_direccion() -> void:
	assert_eq(Enemy.turn_flat(Vector3.FORWARD, Vector3.ZERO, 0.5), Vector3.FORWARD, "sin velocidad, no gira")
	assert_almost_eq(Enemy.turn_flat(Vector3.ZERO, Vector3(0, 0, 3), 0.5).distance_to(Vector3.BACK), 0.0, 1e-5)
