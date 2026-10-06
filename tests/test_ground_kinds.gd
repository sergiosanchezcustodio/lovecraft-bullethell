extends GutTest
## Suelos (hito 6.0): sin `kind` la arena sigue con la nieve de la parte 1; los de la parte 2
## usan town_ground.gdshader con su número.

func _ground(kind: String) -> MeshInstance3D:
	var g := {"seed": 1, "tile": 0.5, "margin_back": 2.0, "margin_front": 2.0, "camp_radius": 0.0}
	if kind != "": g["kind"] = kind
	return ArenaBuilder._ground({"ground": g}, Vector2(8, 8))

func test_snow_by_default() -> void:
	var mi := _ground("")
	assert_eq((mi.material_override as ShaderMaterial).shader.resource_path, "res://scripts/level/snow_ground.gdshader")
	mi.free()

func test_town_kinds() -> void:
	for k in ArenaBuilder.TOWN_KINDS:
		var mi := _ground(k)
		var m := mi.material_override as ShaderMaterial
		assert_eq(m.shader.resource_path, "res://scripts/level/town_ground.gdshader")
		assert_eq(m.get_shader_parameter("kind"), ArenaBuilder.TOWN_KINDS[k])
		mi.free()
