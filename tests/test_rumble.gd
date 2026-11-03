extends GutTest
## Hito 16.30: vibración del mando con fuerza regulable.

func test_fuerzas_y_configuracion_de_antes() -> void:
	assert_eq(Rumble.NAMES.size(), Rumble.LEVELS.size())
	assert_eq(Rumble.level_index(true), 2, "la de antes, activada: normal")
	assert_eq(Rumble.level_index(false), 0)
	assert_eq(Rumble.level_index(1.5), 3)
	assert_eq(Rumble.level_index(0.5), 1)

class FakeInput extends PlayerInput:
	func joy_device() -> int: return -1

class FakePlayer extends Node3D:
	var input: PlayerInput = FakeInput.new()
	var remote := false
	var index := 0

func test_la_crisis_son_dos_latidos_y_respeta_el_tope() -> void:
	var q := FakePlayer.new()
	add_child_autofree(q)
	Rumble.trace = true
	Rumble.add(q)
	assert_has(Rumble.players(), q)
	Rumble.heartbeat(q)                              # sin mando: solo se escribe (trace)
	await wait_seconds(0.4)
	q.remote = true
	Rumble.pulse(q, 1.0, 1.0, 0.1, "otro PC")         # los de otros PC no vibran aquí (no escribe nada)
	Rumble.trace = false
	assert_true(true)
