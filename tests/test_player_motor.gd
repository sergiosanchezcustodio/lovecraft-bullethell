extends GutTest

var data: CharacterData
var motor: PlayerMotor

func before_each() -> void:
	data = load("res://data/characters/dyer.tres")
	motor = PlayerMotor.new(data)

func test_arriba_en_pantalla_es_alejarse_de_la_camara() -> void:
	# La cámara mira desde +X+Z hacia -X-Z (rotación Y 45°)
	assert_almost_eq(PlayerMotor.screen_to_world(Vector2(0, 1)), Vector3(-0.7071, 0, -0.7071), Vector3.ONE * 0.001)
	assert_almost_eq(PlayerMotor.screen_to_world(Vector2(1, 0)), Vector3(0.7071, 0, -0.7071), Vector3.ONE * 0.001)

func test_andar_a_la_velocidad_del_personaje() -> void:
	var v := motor.step(0.016, Vector2(1, 0), false)
	assert_almost_eq(v.length(), data.move_speed, 0.001)
	assert_almost_eq(motor.facing, v.normalized(), Vector3.ONE * 0.001)

func test_quieto_conserva_la_orientacion() -> void:
	motor.step(0.016, Vector2(1, 0), false)
	var f := motor.facing
	var v := motor.step(0.016, Vector2.ZERO, false)
	assert_eq(v, Vector3.ZERO)
	assert_eq(motor.facing, f)

func test_esquive_impulso_invulnerabilidad_y_recarga() -> void:
	var dt := 1.0 / 60.0
	var v := motor.step(dt, Vector2(0, 1), true)
	assert_true(motor.is_dodging())
	assert_true(motor.is_invulnerable())
	assert_almost_eq(v.length(), data.dodge_speed, 0.001)
	# Durante la recarga no se puede repetir
	var t := 0.0
	while t < data.dodge_duration + 0.02:
		motor.step(dt, Vector2(0, 1), false); t += dt
	assert_false(motor.is_dodging(), "el impulso termina")
	assert_false(motor.can_dodge(), "aún en recarga")
	motor.step(dt, Vector2(0, 1), true)
	assert_false(motor.is_dodging(), "pulsar durante la recarga no esquiva")
	while t < data.dodge_cooldown + 0.02:
		motor.step(dt, Vector2.ZERO, false); t += dt
	assert_true(motor.can_dodge())
	assert_almost_eq(motor.dodge_ready_fraction(), 1.0, 0.001)

func test_la_invulnerabilidad_dura_lo_indicado() -> void:
	var dt := 1.0 / 60.0
	motor.step(dt, Vector2.ZERO, true)
	var t := 0.0
	while t < data.dodge_iframes - dt * 1.5:
		motor.step(dt, Vector2.ZERO, false); t += dt
	assert_true(motor.is_invulnerable())
	motor.step(dt, Vector2.ZERO, false); motor.step(dt, Vector2.ZERO, false)
	assert_false(motor.is_invulnerable())

func test_esquive_sin_direccion_usa_la_orientacion() -> void:
	motor.step(0.016, Vector2(-1, 0), false)
	var f := motor.facing
	var v := motor.step(0.016, Vector2.ZERO, true)
	assert_almost_eq(v.normalized(), f, Vector3.ONE * 0.001)

func test_bloqueado_no_se_mueve_ni_esquiva() -> void:
	motor.locked = true
	assert_eq(motor.step(0.016, Vector2(1, 0), true), Vector3.ZERO)
	assert_false(motor.is_dodging())
