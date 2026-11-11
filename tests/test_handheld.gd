extends GutTest
## Hito 19.7: preajuste «Portátil» y 1280×800 en las resoluciones.

func _settings(data: Dictionary):
	var s = load("res://scripts/save/settings.gd").new()
	s.path = "user://test_settings_portatil.json"
	var f := FileAccess.open(s.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	s.load_file()
	return s

func after_each() -> void:
	DirAccess.remove_absolute("user://test_settings_portatil.json")

func test_las_resoluciones_guardadas_antes_siguen_siendo_las_mismas() -> void:
	var s = _settings({"resolution": 2})          # 1920×1080 antes del hito 19.7
	assert_eq(Settings.RESOLUTIONS[int(s.values.resolution)], Vector2i(1920, 1080))
	s.free()
	s = _settings({"resolution": 0})
	assert_eq(Settings.RESOLUTIONS[int(s.values.resolution)], Vector2i(1280, 720))
	s.free()
	s = _settings({"version": 2, "resolution": 1})
	assert_eq(Settings.RESOLUTIONS[int(s.values.resolution)], Vector2i(1280, 800), "ya nuevo, igual")
	s.free()

func test_el_preajuste_portatil() -> void:
	var s = _settings({"quality": 3, "fps_limit": 0, "vol_music": 0.3})
	s.apply_handheld_values()
	assert_eq(Settings.RESOLUTIONS[int(s.values.resolution)], Vector2i(1280, 800))
	assert_eq(int(s.values.fps_limit), 40)
	assert_true(int(s.values.fps_limit) in Settings.FPS_LIMITS, "el límite está en la lista del menú")
	assert_eq(int(s.values.quality), 0)
	assert_eq(int(s.values.ui_scale), 2, "interfaz Grande")
	assert_almost_eq(float(s.values.vol_music), 0.3, 0.001, "lo demás no se toca")
	s.free()
