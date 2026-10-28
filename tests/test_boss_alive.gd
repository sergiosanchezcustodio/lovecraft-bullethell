extends GutTest
## Jefes vivos (hito 12.8): la cabeza gira lo que se pide encima de la pose, el pecho respira y
## al parpadear los ojos se tapan con el párpado y luego vuelven a brillar.

func test_mira_respira_y_parpadea() -> void:
	var m := VoxelBuilder.load_model("res://models/cthulhu.json")
	add_child_autofree(m)
	Anims.pose("cthulhu", "idle", m, 0.0)
	var yaw := Anims.part(m, "head").rotation.y
	Anims.alive(m, 1.0, 0.4, false)
	assert_almost_eq(Anims.part(m, "head").rotation.y, yaw + 0.4, 0.001, "la cabeza mira hacia el jugador")
	assert_ne(Anims.part(m, "torso").scale, Vector3.ONE, "el pecho respira")
	var eyes: Array = m.get_meta("eyes")
	assert_gt(eyes.size(), 0, "tiene ojos (capa de luz en la cabeza)")
	var lit: Material = eyes[0].material_override
	Anims.alive(m, 1.0, 0.0, true)
	assert_ne(eyes[0].material_override, lit, "parpadea: párpado")
	Anims.alive(m, 1.2, 0.0, false)
	assert_eq(eyes[0].material_override, lit, "y vuelve a abrirlos")
