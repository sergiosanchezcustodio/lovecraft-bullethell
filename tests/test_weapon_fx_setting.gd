extends GutTest
## Hito 19.6: «Efectos de las armas» pone un tope a lo que da la calidad gráfica.

func after_each() -> void:
	Settings._overrides.erase("weapon_fx")
	Settings._overrides.erase("quality")

func test_la_opcion_baja_los_efectos_sin_pasar_de_la_calidad() -> void:
	Settings._overrides["quality"] = 2
	assert_eq(int(Quality.value("weapon_fx", 2)), 2, "por defecto, enteros en Alta")
	Settings._overrides["weapon_fx"] = 1
	assert_eq(int(Quality.value("weapon_fx", 2)), 1, "rebajados")
	Settings._overrides["weapon_fx"] = 0
	assert_eq(int(Quality.value("weapon_fx", 2)), 0, "mínimos")
	assert_false(FxShade.on(), "sin el sombreador de efectos")
	Settings._overrides["weapon_fx"] = 2
	Settings._overrides["quality"] = 0
	assert_eq(int(Quality.value("weapon_fx", 2)), 0, "en Baja no sube aunque se pidan enteros")
	assert_eq(int(Quality.value("traces", true) == true), 0, "lo demás de la calidad, igual")
