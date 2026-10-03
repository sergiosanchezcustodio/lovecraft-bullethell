extends GutTest
## Biblioteca Lovecraft: lo visto se guarda y solo lo conocido muestra su ficha.

func test_seen_survives_save_and_load() -> void:
	var s := SaveData.create()
	assert_true(s.mark_seen("enemies", "pinguino"))
	assert_false(s.mark_seen("enemies", "pinguino"), "la segunda vez no es nuevo")
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_true(back.has_seen("enemies", "pinguino"))
	assert_false(back.has_seen("enemies", "acechador"))

func test_only_known_entries_are_known() -> void:
	var s := SaveData.create()
	s.mark_seen("weapons", "webly")
	var known := Library.entries(s, "weapons").filter(func(e: Dictionary) -> bool: return e.known)
	assert_eq(known.size(), 1)
	assert_eq(known[0].id, "webly")
	assert_ne(String(known[0].text), "", "tiene su nota")

func test_unlock_all_knows_everything() -> void:
	var s := SaveData.create_test()
	for t in Library.TOMES:
		var n := Library.count_known(s, t.id)
		if t.id != "achievements": assert_eq(n.x, n.y, "%s: todo conocido" % t.id)

func test_every_entry_has_a_text() -> void:
	var s := SaveData.create()
	for t in Library.TOMES:
		if t.id == "achievements": continue
		for e in Library.entries(s, t.id):
			assert_ne(String(e.text), "", "%s/%s sin texto" % [t.id, e.id])
