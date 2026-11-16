extends GutTest
## Hito 21.19: el manual del investigador en la Biblioteca.

const TOPICS := ["nivel", "cordura", "esquive", "evolucion", "elite", "objetivo"]

func test_un_tomo_con_las_cinco_paginas() -> void:
	var ids := Library.TOMES.map(func(t: Dictionary) -> String: return String(t.id))
	assert_true(ids.has("manual"))
	var es := Library.entries(SaveData.new(), "manual")
	assert_eq(es.map(func(e: Dictionary) -> String: return String(e.id)), TOPICS)
	for e: Dictionary in es:
		assert_true(bool(e.known), "%s: abierto desde el principio" % e.id)
		assert_gt(String(e.text).length(), 120, "%s: con su explicación" % e.id)
		assert_gt((e.facts as Array).size(), 1, "%s: con lo esencial" % e.id)

func test_cada_pagina_con_su_clip() -> void:
	for e: Dictionary in Library.entries(null, "manual"):
		assert_true(e.has("video"), "%s: su clip" % e.id)
		var v: Variant = load(String(e.get("video", "")))
		assert_true(v is VideoStream, "%s: se carga como vídeo" % e.id)

func test_cuenta_entera_en_la_estanteria() -> void:
	assert_eq(Library.count_known(null, "manual"), Vector2i(TOPICS.size(), TOPICS.size()))

func test_la_pagina_reproduce_el_clip() -> void:
	var m := LibraryMenu.new()
	m.save = SaveData.new()
	add_child_autofree(m)
	await wait_process_frames(2)
	m.open_at(Library.TOMES.map(func(t: Dictionary) -> String: return String(t.id)).find("manual"))
	await wait_process_frames(3)
	var players := m.find_children("*", "VideoStreamPlayer", true, false)
	assert_eq(players.size(), 1, "la página, con su clip")
	if players.size() == 1:
		var vp := players[0] as VideoStreamPlayer
		assert_true(vp.loop, "en bucle")
		assert_true(vp.is_playing(), "y se reproduce")
