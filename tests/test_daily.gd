extends GutTest
## Partida del día (hito 13.9): lo del día sale de la fecha, un intento que cuenta, racha y códigos.

func test_lo_del_dia_sale_de_la_fecha() -> void:
	var a := Daily.pick("2026-10-30")
	assert_eq(Daily.pick("2026-10-30"), a, "igual para todos")
	assert_true(Campaign.exists(String(a.level)))
	assert_has(Daily.characters(), String(a.character))
	assert_lte((a.pacts as Array).size(), 2)
	var other := 0
	for k in 10:
		if Daily.pick("2026-11-%02d" % (k + 1)) != a: other += 1
	assert_gt(other, 7, "cambia de un día a otro")
	assert_eq(Daily.seed_of("2026-10-30"), Daily.seed_of("2026-10-30"))
	assert_ne(Daily.seed_of("2026-10-30"), Daily.seed_of("2026-10-31"))

func test_nivel_del_dia() -> void:
	var id := Daily.id_for("2026-10-30")
	assert_true(Daily.is_daily(id))
	var lv := Daily.make_level(id)
	assert_eq(String(lv.id), id)
	assert_eq(lv.daily, "2026-10-30")
	assert_true(lv.endless)
	var src: LevelData = load("res://data/levels/%s.tres" % Daily.pick("2026-10-30").level)
	assert_eq(lv.arena, src.arena)
	assert_eq(Endless.base_of(id), String(Daily.pick("2026-10-30").level))

func test_un_intento_cuenta_y_racha() -> void:
	var s := SaveData.new()
	assert_eq(Daily.streak(s, "2026-10-30"), 0)
	assert_true(Daily.record(s, "2026-10-28", 100.0, 50, "dyer", 1))
	assert_true(Daily.record(s, "2026-10-29", 200.0, 80, "dyer", 1))
	assert_eq(Daily.streak(s, "2026-10-30"), 2, "aún vale hasta medianoche")
	assert_true(Daily.record(s, "2026-10-30", 300.0, 90, "varga", 1))
	assert_false(Daily.record(s, "2026-10-30", 999.0, 900, "varga", 1), "el segundo es de práctica")
	assert_eq(float(Daily.result(s, "2026-10-30").t), 300.0)
	assert_eq(Daily.streak(s, "2026-10-30"), 3)
	assert_eq(Daily.streak(s, "2026-11-01"), 0, "un día sin jugar la corta")
	assert_eq(Daily.best_streak(s), 3)
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(Daily.streak(back, "2026-10-30"), 3, "se guarda")

func test_codigo() -> void:
	var code := Daily.encode("2026-10-30", 754.6, 1234, "peaslee", 2)
	assert_eq(code.length(), 14)
	var d := Daily.decode(code)
	assert_eq(d.date, "2026-10-30")
	assert_eq(d.t, 754.0)
	assert_eq(d.kills, 1234)
	assert_eq(d.character, "peaslee")
	assert_eq(d.players, 2)
	assert_eq(Daily.decode(code.to_lower().replace("-", "")), d, "sin guiones y en minúsculas")
	var bad := code.substr(0, 13) + ("0" if code[13] != "0" else "1")
	assert_eq(Daily.decode(bad), {}, "una errata no pasa")
	assert_eq(Daily.decode("hola"), {})

func test_amigos() -> void:
	var s := SaveData.new()
	var d := Daily.decode(Daily.encode("2026-10-30", 100.0, 10, "dyer", 1))
	Daily.add_friend(s, d)
	Daily.add_friend(s, d)
	assert_eq(Daily.friends(s, "2026-10-30").size(), 1, "sin repetir")
	assert_eq(Daily.friends(s, "2026-10-29").size(), 0)
