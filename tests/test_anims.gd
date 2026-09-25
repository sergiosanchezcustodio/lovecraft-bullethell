extends GutTest

const CASES := {
	"dyer": ["idle", "walk", "dodge", "throw"],
	"pinguino": ["idle", "walk", "charge"],
	"fragmento": ["idle", "walk", "burst"],
	"acechador": ["idle", "walk", "pounce"],
}

func _load(name: String) -> Node3D:
	return autofree(VoxelBuilder.load_model("res://models/%s.json" % name))

func test_todas_las_animaciones_existen_y_tienen_duracion() -> void:
	for model: String in CASES:
		for anim: String in CASES[model]:
			assert_true(Anims.has_anim(model, anim), "%s sin %s" % [model, anim])
			assert_gt(Anims.duration(model, anim), 0.0)

func test_cada_pose_mueve_algo_y_reset_vuelve_al_reposo() -> void:
	for model: String in CASES:
		var m := _load(model)
		var rest := _snapshot(m)
		for anim: String in CASES[model]:
			var moved := false
			for t in [0.1, 0.3, 0.5, 0.7]:
				Anims.pose(model, anim, m, t)
				if _snapshot(m) != rest: moved = true
			assert_true(moved, "%s.%s no mueve ninguna parte" % [model, anim])
			Anims.reset(m)
			assert_eq(_snapshot(m), rest, "%s: reset tras %s no vuelve al reposo" % [model, anim])

func test_modelo_sin_animacion_queda_en_reposo() -> void:
	var m := _load("dyer")
	var rest := _snapshot(m)
	Anims.pose("dyer", "no_existe", m, 0.5)
	assert_eq(_snapshot(m), rest)

func test_escala_real_de_los_modelos() -> void:
	# Alturas aproximadas en metros: la escala de voxel_size tiene que respetarse
	for pair in [["dyer", 1.72], ["pinguino", 1.5], ["acechador", 1.47]]:
		var m := _load(pair[0])
		var top := 0.0
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			var aabb: AABB = (mi as MeshInstance3D).get_aabb()
			top = maxf(top, aabb.end.y + (mi.get_parent() as Node3D).position.y)
		assert_almost_eq(top, float(pair[1]), 0.12, "altura de " + str(pair[0]))

func _snapshot(m: Node3D) -> Array:
	var out := [m.position, m.rotation]
	for c: Node in m.get_children():
		var n := c as Node3D
		out.append_array([n.position.snapped(Vector3.ONE * 0.0001), n.rotation.snapped(Vector3.ONE * 0.0001), n.scale.snapped(Vector3.ONE * 0.0001)])
	return out
