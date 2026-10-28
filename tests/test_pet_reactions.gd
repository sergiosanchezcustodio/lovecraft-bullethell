extends GutTest
## Compañeros que reaccionan (hito 12.9): las familias tienen sus gestos y se suman a la pose sin
## romperla (al quitarlos, vuelve la de siempre).

func _pose_points(m: Node3D) -> Array:
	var out := []
	for n: Node3D in m.get_meta("parts"): out.append(n.global_transform.origin)
	return out

func test_cuadrupedo_reacciona() -> void:
	var m := VoxelBuilder.load_model("res://models/perro.json")
	add_child_autofree(m)
	var s := Anims.script_for("perro")
	for fn in ["cower", "cheer", "whine", "hiss"]: assert_true(s.has_method(fn), fn)
	Anims.pose("perro", "idle", m, 0.0)
	var base := _pose_points(m)
	s.call("whine", m, 1.0, 0.0)
	assert_lt(Anims.part(m, "body").position.y, Anims.rest(m, "body").y, "tumbado")
	Anims.pose("perro", "idle", m, 0.0)
	s.call("cower", m, 0.0, 0.0)
	assert_eq(_pose_points(m), base, "con k = 0 no cambia nada")

func test_volador_se_posa() -> void:
	var m := VoxelBuilder.load_model("res://models/cuervo.json")
	add_child_autofree(m)
	var s := Anims.script_for("cuervo")
	for fn in ["cower", "cheer", "whine", "perch"]: assert_true(s.has_method(fn), fn)
	Anims.pose("cuervo", "idle", m, 0.25)
	s.call("perch", m, 1.0, 0.0)
	assert_almost_eq(Anims.part(m, "wing_r").rotation.z, 0.08, 0.001, "alas plegadas")
	assert_almost_eq(m.position.y, 0.0, 0.001, "sin el vaivén del vuelo")
