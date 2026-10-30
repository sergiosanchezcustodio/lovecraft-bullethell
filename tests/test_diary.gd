extends GutTest
## Diario del investigador (hito 13.10): la entrada con lo que pasó, guardada por personaje.

func _facts(over := {}) -> Dictionary:
	var f := {"character": "dyer", "name": "William Dyer", "level": "p1_n2", "place": "El campamento destruido de Lake",
		"part": 1, "result": "won", "t": 300.0, "kills": 412, "weapon": "Dinamita", "creature": "Shoggoth esclavo",
		"worst_min": 4, "worst": 0.3, "downs": 1, "reviver": "Amelia Peaslee", "sanity": 0.2, "date": "2026-10-30"}
	f.merge(over, true)
	return f

func test_lo_que_paso_esta_en_la_entrada() -> void:
	var e := Diary.compose(_facts(), 7)
	assert_eq(e.title, "30 de octubre de 1931 — El campamento destruido de Lake")
	assert_string_contains(e.text, "minuto 4")
	assert_string_contains(e.text, "«Shoggoth esclavo»")
	assert_string_contains(e.text, "Amelia Peaslee")
	assert_string_contains(e.text, "Dinamita")
	assert_string_contains(e.text, "— William Dyer")
	assert_false("{" in e.text, "sin huecos por rellenar")

func test_misma_semilla_misma_entrada() -> void:
	assert_eq(Diary.compose(_facts(), 3), Diary.compose(_facts(), 3))
	var all := {}
	for k in 20: all[Diary.compose(_facts(), k).text] = true
	assert_gt(all.size(), 3, "con variantes")

func test_sin_heridas_ni_caidas() -> void:
	var e := Diary.compose(_facts({"worst": 0.0, "downs": 0, "reviver": "", "creature": "", "kills": 0}), 1)
	assert_false("minuto" in e.text)
	assert_false("Peaslee" in e.text)
	assert_false("0 criaturas" in e.text and "0 de esas" in e.text)
	assert_false("{" in e.text)

func test_investigadora_y_sin_fin() -> void:
	for k in 30:
		var e := Diary.compose(_facts({"character": "varga", "name": "Ludmila Varga", "result": "endless", "t": 754.0}), k)
		assert_false("quieto" in e.text, "en femenino")
		assert_false("{" in e.text)
	assert_string_contains(Diary.compose(_facts({"result": "endless", "t": 754.0, "worst": 0.0}), 0).text, "12:34")

func test_se_guarda_por_personaje() -> void:
	var s := SaveData.new()
	for k in Diary.MAX + 5: Diary.add(s, "dyer", _facts(), Diary.compose(_facts(), k))
	assert_eq(Diary.entries(s, "dyer").size(), Diary.MAX, "con tope")
	assert_eq(Diary.entries(s, "varga").size(), 0)
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(Diary.entries(back, "dyer").size(), Diary.MAX, "se guarda")
	var lib := Library.entries(back, "diary")
	assert_eq(lib.size(), Diary.MAX, "en la Biblioteca")
	assert_eq(lib[0].section, "William Dyer")
	assert_eq(lib[0].name, "30 oct. · El campamento destruido de Lake · superado")

func test_si_cayo_no_dice_que_salio_ileso() -> void:
	for k in 20:
		var e := Diary.compose(_facts({"result": "lost", "worst": 0.05, "downs": 1, "reviver": ""}), k)
		assert_false("rasguño" in e.text or "Apenas me rozaron" in e.text)
