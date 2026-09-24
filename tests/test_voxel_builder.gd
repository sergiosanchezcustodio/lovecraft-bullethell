extends GutTest

const MODEL := "res://models/acechador.json"
const PARTS := ["torso", "head", "arm_l", "arm_r", "leg_l", "leg_r"]

func before_each() -> void:
	VoxelBuilder.clear_cache()

func test_crea_un_nodo_por_parte_con_su_pivote() -> void:
	var m: Node3D = autofree(VoxelBuilder.load_model(MODEL))
	for p: String in PARTS:
		assert_not_null(m.get_node_or_null(p), "falta la parte " + p)
	var pv: Array = m.get_meta("pivots")["head"]
	assert_almost_eq(m.get_node("head").position, Vector3(pv[0], pv[1], pv[2]) * VoxelBuilder.VOXEL, Vector3.ONE * 0.0001)

func test_las_instancias_comparten_malla() -> void:
	assert_false(VoxelBuilder.is_cached(MODEL))
	var a: Node3D = autofree(VoxelBuilder.load_model(MODEL))
	assert_true(VoxelBuilder.is_cached(MODEL))
	var b: Node3D = autofree(VoxelBuilder.load_model(MODEL))
	var mesh_a: Mesh = (a.get_node("torso").get_child(0) as MeshInstance3D).mesh
	var mesh_b: Mesh = (b.get_node("torso").get_child(0) as MeshInstance3D).mesh
	assert_same(mesh_a, mesh_b)

func test_la_capa_glow_va_aparte_y_sin_sombreado() -> void:
	var m: Node3D = autofree(VoxelBuilder.load_model(MODEL))
	var head := m.get_node("head")
	assert_eq(head.get_child_count(), 2, "la cabeza tiene capa base y capa glow (brillo de los ojos)")
	var glow := head.get_child(1) as MeshInstance3D
	var mat := glow.material_override as StandardMaterial3D
	assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
