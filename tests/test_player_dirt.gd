extends GutTest
## Ropa que se ensucia (hito 12.4): cada parte tiene su mancha y la arena puede tener la suya.

func test_configuracion_por_parte() -> void:
	var p1 := Player.dirt_config("p1", "campamento")
	var p2 := Player.dirt_config("p2", "calles")
	assert_gt(float(p1.get("top", 0.0)), 0.0, "en la Antártida la nieve se posa también arriba")
	assert_gt(float(p2.get("wet", 0.0)), float(p1.get("wet", 0.0)), "el barro, más mojado que la nieve")
	for k in ["color", "reach", "time"]: assert_true(p2.has(k), k)
	assert_eq(Player.dirt_config("p9", "nada"), {}, "sin configuración, nada")

func test_shader_compila() -> void:
	var sh: Shader = load("res://scripts/fx/dirt.gdshader")
	assert_not_null(sh)
	assert_true(sh.get_code().contains("instance uniform float dirt"))
