extends GutTest
## Cordura baja y crisis (hito 12.2): la crisis lleva las manos a la cabeza, con los codos
## fuera; la cordura baja encorva sin mover las piernas.

var m: Node3D

func before_all() -> void:
	m = VoxelBuilder.load_model("res://models/dyer.json")
	add_child(m)

func after_all() -> void:
	m.free()

## Punta de una pieza: su pivote más 13 voxels hacia abajo, girados con ella.
func _tip(pname: String) -> Vector3:
	var n := Anims.part(m, pname)
	return n.global_transform * Vector3(0, -13.0 * VoxelBuilder.VOXEL, 0)

func test_crisis_manos_a_la_cabeza() -> void:
	Anims.pose("dyer", "idle", m, 0.0)
	var anim := Anims.script_for("dyer")
	anim.call("crisis", m, 1.0, 0.0)
	var head := Anims.part(m, "head").global_position + Vector3(0, 8.0 * VoxelBuilder.VOXEL, 0)
	for side in ["l", "r"]:
		assert_lt(_tip("fore_" + side).distance_to(head), 0.15, "mano %s junto a la cabeza" % side)
		var shoulder := absf(Anims.part(m, "arm_" + side).global_position.x)
		assert_gt(absf(Anims.part(m, "fore_" + side).global_position.x), shoulder * 1.25, "codo %s fuera" % side)

func test_cordura_baja_no_toca_las_piernas() -> void:
	Anims.pose("dyer", "idle", m, 0.0)
	var legs := Anims.part(m, "leg_l").rotation
	var torso := Anims.part(m, "torso").rotation.x
	Anims.script_for("dyer").call("unease", m, 1.0, 2.0)
	assert_eq(Anims.part(m, "leg_l").rotation, legs)
	assert_gt(Anims.part(m, "torso").rotation.x, torso + 0.1, "encorvado")
