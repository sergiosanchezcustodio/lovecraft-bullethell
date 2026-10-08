extends GutTest
## Relatos (hito 5.3) y ficha (5.1): todo nivel jugable tiene su relato, y la ficha del
## proyecto tiene autor, aviso de IA y licencia.

func test_todo_nivel_jugable_tiene_relato() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
	for lv in Campaign.levels():
		var id := String(lv.id)
		if not Campaign.exists(id): continue
		assert_true(d.has(id), "%s: falta su relato" % id)
		if d.has(id): assert_gt((d[id] as Array).size(), 2, "%s: relato demasiado corto" % id)

func test_la_ficha_tiene_autor_ia_y_licencia() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	for k in ["titulo", "autor", "ia", "licencia"]:
		assert_true(String(d.get(k, "")) != "", "falta '%s'" % k)
