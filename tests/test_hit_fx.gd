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
	var c := m.get_parent().get_parent() as Crumble
	assert_not_null(c, "el modelo pasa a Crumble (en un soporte)")
	for mi: MeshInstance3D in m.get_meta("meshes"):
		assert_true(mi.material_override is ShaderMaterial, "con el material que lo deshace")
	c._process(Crumble.LIFE + 0.01)
	assert_true(c.is_queued_for_deletion(), "y se va al acabar")

## Hito 12.7: cae a la manera de su familia y se deshace al final de la caída, sin moverse de donde
## murió; en calidad Baja (sin deshacerse) también cae, y luego desaparece.
func test_cae_y_luego_se_deshace() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var at := Node3D.new()
	at.position = Vector3(5, 0, 3)
	at.rotation.y = 0.7
	fx.add_child(at)
	var m := VoxelBuilder.load_model("res://models/pinguino.json")
	at.add_child(m)
	assert_gt(Anims.death_time("pinguino"), 0.0, "el pingüino tiene su caída")
	assert_true(Crumble.start(fx, m, Color.ORANGE, false, "pinguino"))
	var c := m.get_parent().get_parent() as Crumble
	c._process(0.05)
	assert_almost_eq(m.global_position.x, 5.0, 0.3, "sigue donde murió")
	assert_almost_eq(m.global_position.z, 3.0, 0.3)
	for mi: MeshInstance3D in m.get_meta("meshes"):
		assert_false(mi.material_override is ShaderMaterial, "mientras cae, con su material")
	c._process(Anims.death_time("pinguino"))
	assert_gt(absf(m.rotation.z), 1.0, "caído de lado")
	for mi: MeshInstance3D in m.get_meta("meshes"):
		assert_true(mi.material_override is ShaderMaterial, "y luego se deshace")
	c._process(Crumble.LIFE + 0.01)
	assert_true(c.is_queued_for_deletion())

func test_cae_en_calidad_baja() -> void:
	Crumble.enabled = false
	var fx := Node3D.new()
	add_child_autofree(fx)
	var m := VoxelBuilder.load_model("res://models/cultista.json")
	fx.add_child(m)
	var other := VoxelBuilder.load_model("res://models/acechador.json")
	fx.add_child(other)
	assert_false(Crumble.start(fx, other, Color.ORANGE, false, ""), "sin caída, como antes")
	assert_true(Crumble.start(fx, m, Color.ORANGE, false, "cultista"), "con caída, cae")
	var c := m.get_parent().get_parent() as Crumble
	c._process(Crumble.delay_for("cultista") + 0.01)
	assert_true(c.is_queued_for_deletion(), "y desaparece sin deshacerse")
	Crumble.enabled = true

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
