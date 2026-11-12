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

func test_automatico_rebaja_con_tres_o_cuatro_jugadores() -> void:
	Settings._overrides["quality"] = 2
	Settings._overrides["weapon_fx"] = Quality.WFX_AUTO
	Quality.players = 2
	assert_eq(int(Quality.value("weapon_fx", 2)), 2, "dos jugadores: enteros")
	Quality.players = 3
	assert_eq(int(Quality.value("weapon_fx", 2)), 1, "tres: rebajados")
	Settings._overrides["quality"] = 0
	assert_eq(int(Quality.value("weapon_fx", 2)), 0, "en Baja, lo de Baja")
	Quality.players = 1

func test_el_enteros_de_fabrica_pasa_a_automatico() -> void:
	var s = load("res://scripts/save/settings.gd").new()
	s.path = "user://test_settings_wfx.json"
	for pair in [[{"version": 2, "weapon_fx": 2}, 3], [{"version": 2, "weapon_fx": 1}, 1], [{"version": 3, "weapon_fx": 2}, 2]]:
		var f := FileAccess.open(s.path, FileAccess.WRITE)
		f.store_string(JSON.stringify(pair[0]))
		f.close()
		s.load_file()
		assert_eq(int(s.values.weapon_fx), pair[1], str(pair[0]))
	DirAccess.remove_absolute(s.path)
	s.free()
