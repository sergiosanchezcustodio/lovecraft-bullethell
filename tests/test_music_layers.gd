extends GutTest
## Música por capas y avisos de fuera de cámara (hito 13.13).

func test_intensidad() -> void:
	assert_eq(Music.intensity_for(0, 100, false), Vector2.ZERO, "sin enemigos, sin capas")
	var mid := Music.intensity_for(35, 100, false)
	assert_gt(mid.x, 0.3, "con un tercio del tope, percusión")
	assert_eq(mid.y, 0.0, "pero aún sin coros")
	var full := Music.intensity_for(70, 100, false)
	assert_eq(full, Vector2(1, 1), "casi lleno: las dos")
	assert_eq(Music.intensity_for(80, 100, true), Vector2(0, 1), "con el jefe, solo los coros")
	assert_eq(Music.intensity_for(1, 0, false), Vector2.ZERO, "sin tope, uno suelto no la dispara")

func test_cada_pista_tiene_sus_capas() -> void:
	var capas: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/musica.json")) as Dictionary).capas
	for f in DirAccess.get_files_at("res://data/levels"):
		if not f.ends_with(".tres"): continue
		var lv := load("res://data/levels/" + f) as LevelData
		for path in [lv.music, lv.boss_music]:
			if path == "": continue
			assert_true(capas.has(path), "%s: sin capas" % path)
			if capas.has(path):
				for kind in Music.LAYERS: assert_true(ResourceLoader.exists(String(capas[path][kind])), "%s: falta %s" % [path, kind])

func test_avisos_solo_de_lo_que_no_se_ve() -> void:
	var cam := GameCamera.new()
	add_child_autofree(cam)
	cam.make_current()
	var cues := OffscreenCues.new().setup(cam)
	add_child_autofree(cues)
	await get_tree().process_frame
	assert_false(cues.cue("attack", Vector3.ZERO), "se ve: nada")
	assert_true(cues.cue("attack", Vector3(60, 0, 0)), "fuera de cámara: aviso")
	assert_false(cues.cue("attack", Vector3(-60, 0, 0)), "dos del mismo tipo seguidos: no")
	assert_true(cues.cue("elite", Vector3(-60, 0, 0)), "de otro tipo, sí")
	assert_eq(Enemy.on_appear.is_valid(), true, "escucha a los enemigos")
	cues.free()
	assert_false(Enemy.on_appear.is_valid(), "y deja de escucharlos")
	assert_false(Telegraph.on_warning.is_valid())
