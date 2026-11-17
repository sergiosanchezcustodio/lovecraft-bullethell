extends GutTest
## Hito 22.4: textos traducibles. La tabla (`locale/en.po`) la saca `tools/textos.py`; esta prueba
## avisa si se ha quedado atrás o si una traducción pierde un marcador, y cuenta lo que falta.

var _t: Translation

func before_each() -> void:
	_t = Translation.new()
	_t.locale = "en"
	_t.add_message("Pingüino albino ciego", "Blind albino penguin")
	_t.add_message("Resiste · %d:%02d para el final", "Hold out · %d:%02d to go")
	_t.add_message("Cada 25 criaturas que abates, un viento empuja y aturde a las de alrededor.", "Every 25 kills, a gust pushes and stuns those around.")
	TranslationServer.add_translation(_t)
	L.apply("en")

func after_each() -> void:
	L.apply("es")
	TranslationServer.remove_translation(_t)

func test_frases_del_codigo() -> void:
	assert_eq(L.t("Resiste · %d:%02d para el final") % [3, 5], "Hold out · 3:05 to go")
	assert_eq(L.t("Algo que no está"), "Algo que no está", "lo que no está, tal cual")

func test_en_espanol_no_traduce() -> void:
	L.apply("es")
	assert_eq(L.t("Pingüino albino ciego"), "Pingüino albino ciego")

func test_datos_al_cargarlos() -> void:
	var d: Dictionary = L.data({"id": "Pingüino albino ciego", "name": "Pingüino albino ciego",
		"_doc": "Pingüino albino ciego", "list": [{"text": "Pingüino albino ciego"}]})
	assert_eq(d.name, "Blind albino penguin")
	assert_eq(d.list[0].text, "Blind albino penguin", "también dentro de listas")
	assert_eq(d.id, "Pingüino albino ciego", "los ids no")
	assert_eq(d._doc, "Pingüino albino ciego", "los comentarios no")

func test_propiedades_de_los_recursos() -> void:
	var e := EnemyData.new()                       # su nombre por defecto es el del pingüino
	assert_eq(e.display_name, "Blind albino penguin", "también el valor por defecto, que los .tres no guardan")
	L.apply("es")
	assert_eq(e.display_name, "Pingüino albino ciego", "el valor guardado sigue en español")

func test_que_es_texto() -> void:
	for s in ["Jugar", "Pingüino albino ciego", "¿Seguro?", "Vida %d", "Daño"]: assert_true(L.human(s), s)
	for s in ["idle", "res://data/x.json", "zoog_copas", "%d / %d", "x", "Node3D"]: assert_false(L.human(s), s)

func test_la_tabla_esta_al_dia() -> void:
	var out := []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/textos.py"), "comprobar"], out, true)
	if code == -1 or out.is_empty():
		pending("sin python")
		return
	var text := String(out[0])
	assert_true(text.strip_edges().ends_with("OK"), "tools/textos.py comprobar:\n" + text)

func test_la_tabla_se_carga() -> void:
	var t := load(L.PO["en"]) as Translation
	assert_not_null(t, "locale/en.po")
	if t == null: return
	var pot := FileAccess.get_file_as_string("res://locale/textos.pot")
	var total := pot.count("\nmsgid ")
	var done := 0
	for m in t.get_message_list(): if t.get_message(m) != &"": done += 1
	gut.p("Traducidos al inglés: %d de %d" % [done, total])
	assert_gt(total, 1000, "la tabla tiene los textos")
