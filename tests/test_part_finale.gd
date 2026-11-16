extends GutTest
## Hito 21.17: el final ilustrado de cada parte.

func test_un_final_por_parte_tras_su_ultimo_nivel() -> void:
	for pi in Campaign.parts().size():
		var last := ""
		for l in Campaign.levels(): if int(l.part) == pi: last = String(l.id)
		var d := PartFinale.data_for(last)
		assert_false(d.is_empty(), "final de la parte %d (%s)" % [pi + 1, last])
		assert_true(ResourceLoader.exists(String(d.get("image", ""))), "%s: su ilustración" % last)
		assert_eq(String(d.title), String(Campaign.parts()[pi].title), "con el título de la parte")
		assert_gt(String(d.text).length(), 40)
		assert_true(PartFinale.applies(last, null))

func test_solo_en_la_campana() -> void:
	assert_false(PartFinale.applies("p1_n3", null), "un nivel del medio")
	assert_false(PartFinale.applies("desafio:p1_n5", null), "un desafío")
	assert_false(PartFinale.applies("desfile:6", null), "el desfile")
	assert_false(PartFinale.applies("p1_n5", LaunchArgs.parse(PackedStringArray(["finale=false"]))), "finale=false")

func test_se_pasa_sola_con_bots() -> void:
	var fin := PartFinale.new(PartFinale.data_for("p1_n5"), true)
	var got := [false]
	fin.done.connect(func() -> void: got[0] = true)
	add_child(fin)
	await wait_seconds(PartFinale.AUTO_TIME + 0.8)
	assert_true(got[0], "avisa al acabar")
	assert_false(is_instance_valid(fin), "y se va")

func test_la_frase_sale_palabra_a_palabra() -> void:
	assert_eq(PartFinale.word_ends("Lo que vivía"), [2, 6, 12] as Array[int])
	assert_eq(PartFinale.word_ends("una"), [3] as Array[int])

func test_suena_su_acorde() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
	assert_true((d.eventos as Dictionary).has("part_finale"))
	assert_true(FileAccess.file_exists("res://resources/sfx/part_finale.wav"))

func test_los_finales_en_la_biblioteca() -> void:
	var s := SaveData.new()
	s.levels_won.append("p2_n5")
	var fins := Library.entries(s, "stories").filter(func(e: Dictionary) -> bool: return e.has("finale"))
	assert_eq(fins.size(), Campaign.parts().size(), "uno por parte")
	for e: Dictionary in fins: assert_eq(bool(e.known), String(e.finale) == "p2_n5", "abierto al vencer a su jefe")
