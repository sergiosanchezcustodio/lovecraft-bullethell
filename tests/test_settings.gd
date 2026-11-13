extends GutTest
## Configuración: se guarda y se lee, y las reasignaciones de controles se intercambian
## cuando la tecla o el botón ya estaba en uso.

var settings: Node

func before_each() -> void:
	settings = load("res://scripts/save/settings.gd").new()
	settings.path = "user://test_settings.json"
	if FileAccess.file_exists(settings.path): DirAccess.remove_absolute(settings.path)
	settings.load_file()

func after_each() -> void:
	if FileAccess.file_exists(settings.path): DirAccess.remove_absolute(settings.path)
	settings.free()

func test_valores_por_defecto_y_guardado() -> void:
	assert_true(settings.get_value("fullscreen"))
	settings.set_value("vol_music", 0.3)
	settings.set_value("fullscreen", false)
	settings.load_file()
	assert_almost_eq(float(settings.get_value("vol_music")), 0.3, 0.001)
	assert_false(settings.get_value("fullscreen"))

func test_reasignar_una_tecla_la_cambia_en_los_controles() -> void:
	settings.set_key(InputBindings.DODGE, KEY_J)
	var b: InputBindings = settings.bindings()
	assert_eq(b.keys[InputBindings.DODGE], [KEY_J])
	settings.set_key(&"up", KEY_I)
	b = settings.bindings()
	assert_eq(b.key_up[0], KEY_I)
	assert_true(KEY_UP in b.key_up, "las flechas siguen moviendo")

func test_una_tecla_ocupada_se_intercambia() -> void:
	settings.set_key(InputBindings.DODGE, KEY_M)          # M era el mapa
	assert_eq(settings.key_for(InputBindings.DODGE), KEY_M)
	assert_eq(settings.key_for(InputBindings.MAP), KEY_SPACE, "el mapa se queda con el antiguo del esquive")

func test_un_boton_ocupado_se_intercambia() -> void:
	settings.set_joy(InputBindings.DODGE, JOY_BUTTON_START)
	assert_eq(settings.joy_for(InputBindings.DODGE), JOY_BUTTON_START)
	assert_eq(settings.joy_for(InputBindings.PAUSE), JOY_BUTTON_A)

func test_restablecer_los_controles() -> void:
	settings.set_key(InputBindings.DODGE, KEY_J)
	settings.reset_controls()
	assert_eq(settings.key_for(InputBindings.DODGE), KEY_SPACE)

## Hito 20.15: restablecer una pestaña deja las demás como estaban.
func test_restablecer_una_pestana() -> void:
	settings.set_value("vol_music", 0.2)
	settings.set_value("quality", 0)
	settings.set_value("shake", 0.25)
	settings.reset_group("audio")
	assert_almost_eq(float(settings.get_value("vol_music")), float(settings.defaults["vol_music"]), 0.001, "el audio, de fábrica")
	assert_eq(int(settings.get_value("quality")), 0, "el vídeo, como estaba")
	assert_almost_eq(float(settings.get_value("shake")), 0.25, 0.001, "el juego, como estaba")
	settings.reset_group("video")
	assert_eq(int(settings.get_value("quality")), int(settings.defaults["quality"]))

## Toda clave de fábrica está en una pestaña (o es de los controles, la intro o la dificultad).
func test_cada_clave_tiene_su_pestana() -> void:
	var grouped := {}
	for g: String in settings.GROUPS:
		for k: String in settings.GROUPS[g]:
			assert_true(settings.defaults.has(k), "%s existe" % k)
			grouped[k] = true
	for k: String in settings.defaults:
		if k in ["keys", "joy", "controls_rev", "controls_base", "intro_seen", "dif_levels", "profile", "profiles"]: continue
		assert_true(grouped.has(k), "%s está en alguna pestaña" % k)

## Hito 20.16: el contador detallado y el «Sí» de antes.
func test_rendimiento_detallado() -> void:
	var f := PackedInt64Array()
	for i in 99: f.append(16000)
	f.append(40000)
	var t: String = settings.perf_text(f, 60)
	assert_string_contains(t, "60 FPS")
	assert_string_contains(t, "media 16,2 ms")
	assert_string_contains(t, "1 % peor 40,0 ms")
	settings.set_value("show_fps", true)
	assert_eq(settings.fps_mode(), 1, "el «Sí» de antes es el contador de siempre")

## Hito 20.14: dos perfiles; cada uno recuerda lo suyo.
func test_perfiles() -> void:
	settings.set_value("quality", 3)
	settings.set_value("ui_scale", 1)
	settings.switch_profile(1)
	assert_eq(int(settings.get_value("profile")), 1)
	assert_eq(int(settings.get_value("quality")), int(settings.HANDHELD["quality"]), "el portátil empieza con el preajuste")
	assert_eq(int(settings.get_value("ui_scale")), int(settings.HANDHELD["ui_scale"]))
	settings.set_value("quality", 1)
	settings.set_value("vol_music", 0.4)
	settings.switch_profile(0)
	assert_eq(int(settings.get_value("quality")), 3, "el de sobremesa, como se dejó")
	assert_eq(int(settings.get_value("ui_scale")), 1)
	assert_almost_eq(float(settings.get_value("vol_music")), 0.4, 0.001, "el audio no va en el perfil")
	settings.switch_profile(1)
	assert_eq(int(settings.get_value("quality")), 1, "el portátil, como se dejó")
	settings.load_file()
	assert_eq(int(settings.get_value("profile")), 1, "se guarda")

## El botón de la Steam Deck pasa al perfil Portátil sin perder el de sobremesa.
func test_ajustes_de_portatil_guardan_el_de_sobremesa() -> void:
	settings.set_value("quality", 3)
	settings.apply_handheld()
	assert_eq(int(settings.get_value("profile")), settings.PROFILE_HANDHELD)
	assert_eq(int(settings.get_value("quality")), int(settings.HANDHELD["quality"]))
	settings.switch_profile(0)
	assert_eq(int(settings.get_value("quality")), 3)
