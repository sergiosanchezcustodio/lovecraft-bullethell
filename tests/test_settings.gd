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
