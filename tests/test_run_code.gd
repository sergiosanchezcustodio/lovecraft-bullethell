extends GutTest
## Hito 23.9: códigos de partida.

func _code(level := "p1_n2", s := 123456789, ch := "carter", pet := "", pacts: Array = [], mad := 0) -> String:
	return RunCode.encode(level, s, ch, pet, pacts, mad)

func test_ida_y_vuelta() -> void:
	var pets := RunCode.pet_ids()
	var pacts := RunCode.pact_ids()
	var c := _code("p3_n4", 2000000000, "whateley", pets[0], [pacts[0], pacts[2]], 3)
	assert_eq(c.length(), 24, "20 letras y cuatro guiones")
	var d := RunCode.decode(c)
	assert_false(d.has("error"), str(d))
	assert_eq(String(d.level), "p3_n4")
	assert_eq(int(d.seed), 2000000000)
	assert_eq(String(d.character), "whateley")
	assert_eq(String(d.pet), pets[0])
	assert_eq(d.pacts, [pacts[0], pacts[2]])
	assert_eq(int(d.madness), 3)
	assert_eq(String(d.code), c)

func test_sin_compañero_ni_pactos() -> void:
	var d := RunCode.decode(_code())
	assert_eq(String(d.pet), "")
	assert_eq((d.pacts as Array).size(), 0)

func test_modos_y_noches() -> void:
	for id in ["noche_acecha", "desafio:p1_n1", "sin_fin:p2_n3", "desafio:noche_color"]:
		assert_eq(String(RunCode.decode(_code(id)).level), id)
	assert_eq(_code("dia:2026-11-20"), "", "la del día tiene su propio código")
	assert_eq(_code("p1_n1", 0), "", "sin semilla, no")

func test_se_lee_con_erratas_de_forma() -> void:
	var c := _code()
	var loose := c.replace("-", " ").to_lower().replace("0", "o").replace("1", "l")
	assert_eq(String(RunCode.decode(loose).code), c)

func test_una_letra_cambiada_no_vale() -> void:
	var c := _code("p2_n1", 987654, "dyer").replace("-", "")
	var bad := 0
	for i in c.length():
		var k := RunCode.ALPHABET.find(c[i])
		var wrong := c.substr(0, i) + RunCode.ALPHABET[(k + 1) % 32] + c.substr(i + 1)
		if RunCode.decode(wrong).has("error"): bad += 1
	assert_eq(bad, c.length(), "cada letra cambiada se nota")
	assert_eq(String(RunCode.decode("7K2M-QX4A").get("error", "")), "letras")

func test_sin_huellas_repetidas() -> void:
	for pair: Array in [[RunCode.level_ids(), 18], [Daily.characters(), 12], [[""] + RunCode.pet_ids(), 10]]:
		var seen := {}
		for id in pair[0]:
			var h := RunCode._hash(String(id), int(pair[1]))
			assert_false(seen.has(h), "%s y %s comparten huella" % [id, seen.get(h, "")])
			seen[h] = id
	assert_true(RunCode.pact_ids().size() <= 8, "caben los pactos")

func test_abierto_segun_el_hueco() -> void:
	var s := SaveData.new()
	assert_true(RunCode.open_for(s, "p1_n1"))
	assert_false(RunCode.open_for(s, "p1_n3"))
	assert_false(RunCode.open_for(s, "noche_acecha"))
	assert_false(RunCode.open_for(s, "sin_fin:p1_n1"))
	s.levels_won = ["p1_n1", "p1_n2"]
	assert_true(RunCode.open_for(s, "p1_n3"))
	assert_true(RunCode.open_for(s, "desafio:p1_n2"))
	s.unlock_all = true
	assert_true(RunCode.open_for(s, "noche_acecha"))

func test_prepara_la_sesion() -> void:
	var d := RunCode.decode(_code("p1_n2", 4242, "carter", "", [RunCode.pact_ids()[1]], 2))
	RunCode.prepare(d, Devices.KEYBOARD)
	assert_eq(GameSession.seats[0].character, &"carter")
	assert_eq(String(GameSession.level), "p1_n2")
	assert_eq(GameSession.replay_seed, 4242)
	assert_eq(GameSession.pacts, [RunCode.pact_ids()[1]])
	assert_eq(GameSession.madness, 2)
	GameSession.clear()
	GameSession.replay_seed = 0
	GameSession.pacts = []
	GameSession.madness = 0

func test_archivo() -> void:
	var run := {"level": "p1_n2", "seed": 77, "pacts": [], "madness": 0, "players": [{"character": "dyer", "pet": ""}]}
	assert_eq(String(RunCode.decode(RunCode.of_run(run)).character), "dyer")
	var s := SaveData.new()
	run.merge({"result": "lost", "t": 60.0})
	(run.players[0] as Dictionary).merge({"name": "Dyer", "weapons": [], "items": [], "table": [], "cause": ""})
	RunArchive.add(s, run)
	var facts: Array = Library.entries(s, "archive")[0].facts
	assert_true(facts.any(func(f: String) -> bool: return f.contains(RunCode.of_run(run))), "el código, en la página")

func test_describe() -> void:
	var t := RunCode.describe(RunCode.decode(_code("p1_n1", 5, "dyer", "", [], 1)))
	assert_string_contains(t, "Dyer")
