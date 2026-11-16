extends GutTest
## Hito 21.20: estadísticas de la cuenta (AccountStats y el tomo XIII de la Biblioteca).

func _table(rows: Array) -> Array:
	return rows.map(func(r: Array) -> Dictionary: return {"id": r[0], "damage": r[1], "kills": r[2]})

func test_se_suman_partida_a_partida() -> void:
	var s := SaveData.new()
	AccountStats.add_player(s, "dyer", 300.0, _table([["granada", 1000.4, 20], ["webly", 500.0, 10]]))
	AccountStats.add_player(s, "dyer", 120.0, _table([["granada", 250.0, 5]]))
	AccountStats.add_player(s, "malone", 200.0, _table([["thompson", 4000.0, 80]]))
	var w := AccountStats.rows(s, "weapons")
	assert_eq(w.map(func(r: Dictionary) -> String: return String(r.id)), ["thompson", "granada", "webly"], "de más a menos daño")
	assert_eq(int(w[1].value), 1250)
	assert_eq(int(w[1].extra), 25, "y sus bajas")
	var c := AccountStats.rows(s, "characters")
	assert_eq(String(c[0].id), "dyer")
	assert_eq(float(c[0].value), 420.0)
	assert_eq(int(c[0].extra), 2, "dos partidas")
	assert_eq(AccountStats.favorite(s), "dyer", "el de más tiempo")

func test_crisis_y_niveles() -> void:
	var s := SaveData.new()
	AccountStats.add_crisis(s, 4.5)
	AccountStats.add_crisis(s, 5.0)
	AccountStats.add_crisis(s, 0.0)
	assert_almost_eq(AccountStats.crisis_time(s), 9.5, 0.01)
	AccountStats.add_level(s, "p1_n1", false)
	AccountStats.add_level(s, "p1_n1", true)
	var l := AccountStats.rows(s, "levels")
	assert_eq(int(l[0].value), 2)
	assert_eq(int(l[0].extra), 1, "una superada")

func test_sobrevive_al_guardar() -> void:
	var s := SaveData.new()
	AccountStats.add_player(s, "varga", 60.0, _table([["necronomicon", 300.0, 7]]))
	AccountStats.add_crisis(s, 3.0)
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(AccountStats.favorite(back), "varga")
	assert_eq(int(AccountStats.rows(back, "weapons")[0].value), 300)
	assert_almost_eq(AccountStats.crisis_time(back), 3.0, 0.01)

func test_bajas_por_criatura_del_bestiario() -> void:
	var s := SaveData.new()
	for i in 3: Library.add_kill(s, "profundo", "dyer")
	Library.add_kill(s, "pinguino", "dyer")
	var k := AccountStats.rows(s, "kills")
	assert_eq(String(k[0].id), "profundo")
	assert_eq(int(k[0].value), 3)

func test_las_ultimas_partidas_de_la_mas_antigua_a_la_ultima() -> void:
	var s := SaveData.new()
	RunArchive.add(s, {"level": "p1_n1", "result": "lost", "t": 120.0, "players": []})
	RunArchive.add(s, {"level": "p1_n2", "result": "won", "t": 600.0, "players": []})
	assert_eq(AccountStats.recent(s), [[2.0, false], [10.0, true]])

func test_el_tomo_de_estadisticas() -> void:
	var ids := Library.TOMES.map(func(t: Dictionary) -> String: return String(t.id))
	assert_true(ids.has("stats"))
	var s := SaveData.new()
	AccountStats.add_player(s, "dyer", 300.0, _table([["granada", 1000.0, 20]]))
	var es := Library.entries(s, "stats")
	assert_eq(es.size(), 7)
	for e: Dictionary in es:
		assert_true(bool(e.known), "%s: abierta" % e.id)
		assert_ne(String(e.text), "", "%s: con texto" % e.id)
	var armas: Dictionary = es.filter(func(e: Dictionary) -> bool: return e.id == "armas")[0]
	assert_eq(String(armas.chart.kind), "bars")
	assert_eq((armas.chart.rows as Array).size(), 1)
	assert_eq(String(armas.chart.rows[0].label), RunArchive.source_name("granada"))
	var resumen: Dictionary = es[0]
	assert_true((resumen.facts as Array).any(func(f: String) -> bool: return f.contains("William Dyer") or f.contains("Dyer")), "el favorito")
	assert_eq(Library.entries(null, "stats").size(), 7, "también sin partida")

func test_la_grafica_crece_y_acaba() -> void:
	var c := InkChart.bars([{"label": "a", "value": 10.0, "text": "10"}, {"label": "b", "value": 5.0, "text": "5"}])
	add_child_autofree(c)
	assert_eq(c.grown(0), 0.0, "empieza sin tinta")
	c.finish()
	assert_eq(c.grown(1), 1.0, "y acaba entera")
	assert_almost_eq(c.custom_minimum_size.y, InkChart.ROW_H * 2, 0.1)

func test_la_pagina_dibuja_su_grafica() -> void:
	var m := LibraryMenu.new()
	var s := SaveData.new()
	AccountStats.add_player(s, "dyer", 300.0, _table([["granada", 1000.0, 20]]))
	m.save = s
	add_child_autofree(m)
	await wait_process_frames(2)
	m.open_at(Library.TOMES.map(func(t: Dictionary) -> String: return String(t.id)).find("stats"), 2)
	await wait_process_frames(4)
	assert_eq(m.find_children("*", "InkChart", true, false).size(), 1)

func test_crisis_de_cada_tipo_en_el_resumen() -> void:
	var s := SaveData.new()
	AccountStats.add_crisis(s, 5.0, {"vagar": 2, "paralisis": 1})
	AccountStats.add_crisis(s, 4.0, {"vagar": 1})
	var r := AccountStats.rows(s, "crisis")
	assert_eq(String(r[0].id), "vagar")
	assert_eq(int(r[0].value), 3)
	var resumen: Dictionary = Library.entries(s, "stats")[0]
	assert_eq(String(resumen.chart.rows[0].label), "Vagar sin rumbo")
	assert_false(Library.entries(SaveData.new(), "stats")[0].has("chart"), "sin crisis, sin gráfica")
