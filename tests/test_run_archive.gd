extends GutTest
## Hito 16.26: archivo de expediciones.

func _run(level := "p1_n2", seed_n := 1234) -> Dictionary:
	return {"level": level, "result": "lost", "t": 135.0, "seed": seed_n, "pacts": [], "madness": 0,
		"players": [{"character": "carter", "name": "Randolph Carter", "lvl": 9, "worn": {}, "pet": "",
			"weapons": [["llave_suenos", 5]], "items": [["mapa_sueno", 2]], "cause": "Pingüino (contacto)",
			"table": [{"id": "llave_suenos", "damage": 1555, "share": 0.8, "dps": 25.3, "kills": 32}]}]}

func test_guarda_las_ultimas() -> void:
	var s := SaveData.new()
	for i in RunArchive.MAX + 5: RunArchive.add(s, _run("p1_n1", i + 1))
	assert_eq(RunArchive.runs(s).size(), RunArchive.MAX)
	assert_eq(int(RunArchive.runs(s)[0].seed), RunArchive.MAX + 5, "la más reciente, primero")
	assert_true(RunArchive.runs(s)[0].has("date"))

func test_que_se_puede_repetir() -> void:
	assert_true(RunArchive.replayable(_run()))
	assert_true(RunArchive.replayable(_run("desafio:p1_n1")))
	assert_false(RunArchive.replayable(_run("dia:2026-11-03")), "la del día, no")
	assert_false(RunArchive.replayable(_run("p1_n1", 0)), "sin semilla, no")

func test_prepara_la_sesion() -> void:
	RunArchive.prepare(_run(), Devices.KEYBOARD)
	assert_eq(GameSession.seats.size(), 1)
	assert_eq(GameSession.seats[0].character, &"carter")
	assert_eq(String(GameSession.level), "p1_n2")
	assert_eq(GameSession.replay_seed, 1234)
	GameSession.clear()
	GameSession.replay_seed = 0

func test_sale_en_la_biblioteca() -> void:
	var s := SaveData.new()
	RunArchive.add(s, _run())
	var es := Library.entries(s, "archive")
	assert_eq(es.size(), 1)
	assert_string_contains(String(es[0].name), "Caído")
	assert_string_contains(String(es[0].text), "Llave de los sueños")
	assert_eq(String(es[0].model), "carter")
