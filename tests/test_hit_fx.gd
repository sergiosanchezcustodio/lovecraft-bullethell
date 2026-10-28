extends GutTest
## Hito 11.1: micro-pausa al impactar (HitStop), modelo que se desmorona (Crumble) y manchas
## que se quedan en el suelo con tope (GroundMarks).

func after_each() -> void:
	HitStop.stop()
	Engine.time_scale = 1.0
	GameSession.online = false

func _wait_real(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func test_micropausa_y_vuelta() -> void:
	HitStop.enabled = true
	HitStop.hit(40)
	assert_eq(Engine.time_scale, HitStop.SCALE, "casi parado")
	await _wait_real(0.12)
	assert_eq(Engine.time_scale, 1.0, "vuelve solo")

func test_sin_micropausa_si_no_toca() -> void:
	HitStop.hit(40)
	assert_eq(Engine.time_scale, 1.0, "sin partida en marcha, nada")
	HitStop.enabled = true
	GameSession.online = true
	HitStop.hit(40, true)
	assert_eq(Engine.time_scale, 1.0, "en red, nada")
	GameSession.online = false
	Engine.time_scale = 2.0
	HitStop.hit(40, true)
	assert_eq(Engine.time_scale, 2.0, "acelerado (simulaciones), nada")

func test_las_pequenas_esperan_hueco() -> void:
	HitStop.enabled = true
	HitStop.hit(20)
	await _wait_real(0.06)
	var before := HitStop.count
	HitStop.hit(20)
	assert_eq(HitStop.count, before, "otra pequeña enseguida no")
	HitStop.hit(20, true)
	assert_eq(HitStop.count, before + 1, "una grande sí")

func test_se_desmorona() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var m := VoxelBuilder.load_model("res://models/pinguino.json")
	fx.add_child(m)
	var n := Crumble.alive
	assert_true(Crumble.start(fx, m, Color.ORANGE), "empieza")
	assert_eq(Crumble.alive, n + 1)
	var c := m.get_parent() as Crumble
	assert_not_null(c, "el modelo pasa a Crumble")
	for mi: MeshInstance3D in m.get_meta("meshes"):
		assert_true(mi.material_override is ShaderMaterial, "con el material que lo deshace")
	c._process(Crumble.LIFE + 0.01)
	assert_true(c.is_queued_for_deletion(), "y se va al acabar")

func test_manchas_con_tope() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var keep := GroundMarks.limit
	GroundMarks.limit = 3
	for i in 5:
		var g := VoxelFx.ground(6, 1.0)
		fx.add_child(g)
		GroundMarks.keep(fx, g)
	var gm: GroundMarks = fx.get_meta("ground_marks")
	assert_eq(gm.count(), 5)
	gm._process(GroundMarks.FAST + 0.05)
	assert_eq(gm.count(), 3, "las más viejas se van deprisa")
	gm._process(GroundMarks.LINGER)
	assert_eq(gm.count(), 0, "y las demás, al acabar su rato")
	GroundMarks.limit = keep
