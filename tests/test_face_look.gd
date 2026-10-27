extends GutTest
## Parpadeo y mueca de dolor (FaceLook): todos los personajes tienen datos de cara, parpadean
## solos y ponen la mueca al recibir un golpe, salvo en las crisis.

func _face(model_name: String) -> Array:
	var m := VoxelBuilder.load_model("res://models/%s.json" % model_name)
	add_child_autofree(m)
	var f := FaceLook.new().setup(m, "res://models/%s.json" % model_name)
	add_child_autofree(f)
	return [m, f]

func test_todos_los_personajes_tienen_cara() -> void:
	for file in DirAccess.get_files_at("res://data/characters"):
		if not file.ends_with(".tres"): continue
		var cd := load("res://data/characters/" + file) as CharacterData
		var f: Dictionary = FaceLook.faces().get(cd.model, {})
		assert_eq((f.get("eyes", []) as Array).size(), 16, "%s: dos ojos de 4×2" % cd.model)

func test_parpadea_y_pone_mueca() -> void:
	var mf := _face("dyer")
	var f: FaceLook = mf[1]
	var closed := 0
	for i in 60 * 14:                               # 14 s: al menos dos parpadeos
		f._process(1.0 / 60.0)
		if f._blink.visible: closed += 1
	assert_gt(closed, 0, "parpadea")
	assert_lt(closed, 60 * 14 / 10, "casi siempre con los ojos abiertos")
	f.hurt()
	f._process(1.0 / 60.0)
	assert_true(f._hurt.visible, "mueca al recibir un golpe")
	assert_false(f._blink.visible, "sin parpadeo durante la mueca")
	for i in 60: f._process(1.0 / 60.0)
	assert_false(f._hurt.visible, "la mueca dura un momento")

func test_sin_mueca_en_las_crisis() -> void:
	var f: FaceLook = _face("whipple")[1]
	f.suppressed = true
	f.hurt()
	f._process(1.0 / 60.0)
	assert_false(f._hurt.visible)

func test_sin_cara_dibujada_no_hace_nada() -> void:
	var f: FaceLook = _face("profundo")[1]
	f.hurt()
	f._process(1.0 / 60.0)
	assert_null(f._blink)
