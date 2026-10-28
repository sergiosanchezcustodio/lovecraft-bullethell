extends GutTest
## Heridas (hito 12.6): las grietas van en una segunda pasada que comparten todos los enemigos
## con el mismo material; lo de cada uno (vida perdida, color) son parámetros de instancia.

func test_grietas_en_las_mallas_sin_luz() -> void:
	var a := VoxelBuilder.load_model("res://models/sacerdote.json")
	var b := VoxelBuilder.load_model("res://models/sacerdote.json")
	add_child_autofree(a)
	add_child_autofree(b)
	var ma := Enemy.wound_dress(a, "sacerdote")
	var mb := Enemy.wound_dress(b, "sacerdote")
	assert_gt(ma.size(), 0, "lleva grietas")
	for mi: MeshInstance3D in ma:
		assert_eq(int(mi.get_meta("kind", 0)), 0, "solo en la capa con luz (no en ojos ni brillos)")
		assert_not_null((mi.material_override as StandardMaterial3D).next_pass, "con la segunda pasada")
	assert_same(ma[0].material_override, mb[0].material_override, "un material para todos")
	(ma[0] as MeshInstance3D).set_instance_shader_parameter("hurt", 0.6)
	assert_almost_eq(float(ma[0].get_instance_shader_parameter("hurt")), 0.6, 0.001)
	assert_almost_eq(float(mb[0].get_instance_shader_parameter("hurt")), 0.0, 0.001, "cada uno, su herida")
