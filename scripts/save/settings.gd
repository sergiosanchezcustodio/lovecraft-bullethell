extends Node
## Configuración del juego (autoload `Settings`), común a los tres huecos de partida:
## vídeo, audio, controles y juego. Se guarda en `user://settings.json` (con versión) y se
## aplica al arrancar y cada vez que se cambia algo en el menú de configuración.

const VERSION := 1
const PATH := "user://settings.json"

const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const FPS_LIMITS: Array[int] = [0, 60, 120, 144, 240]          ## 0 = sin límite
const SCALES_3D: Array[float] = [0.5, 0.67, 0.75, 1.0]
## Brillo (17-10-2026): gamma que multiplica la de cada arena (Atmosphere.set_lift); índice 3 = 1
const BRIGHTNESS: Array[float] = [0.8, 0.87, 0.93, 1.0, 1.08, 1.16, 1.25, 1.35]
const BUS_MUSIC := &"Musica"
const BUS_SFX := &"Efectos"
const BUS_AMBIENT := &"Ambiente"               ## sonido de los escenarios (16-10-2026), dentro de Efectos

## Acciones que se pueden reasignar, con su nombre en el menú.
const REMAP_ACTIONS := [
	[&"up", "Moverse arriba"], [&"down", "Moverse abajo"], [&"left", "Moverse a la izquierda"],
	[&"right", "Moverse a la derecha"], [InputBindings.DODGE, "Esquivar"], [InputBindings.PAUSE, "Pausa"],
	[InputBindings.SHEET, "Ficha del jugador"], [InputBindings.MAP, "Mapa"],
	[InputBindings.PAGE_PREV, "Página anterior de la ficha"], [InputBindings.PAGE_NEXT, "Página siguiente de la ficha"]]

var defaults := {
	"fullscreen": true, "resolution": 2, "vsync": true, "fps_limit": 0, "scale_3d": 1.0,
	"brightness": 3,                        ## índice en BRIGHTNESS
	"vol_master": 1.0, "vol_music": 0.8, "vol_sfx": 0.9, "vol_weapons": 0.7, "vol_ambient": 0.8,
	"distortion": 1.0, "vibration": true, "show_fps": false,
	"weather": 2,                           ## clima: 0 apagado, 1 reducido, 2 completo
	"ui_scale": 1,                          ## accesibilidad (hito 8.3): tamaño de la interfaz (UI_SCALES)
	"bullet_palette": 0,                    ## 0 normal, 1 alto contraste (daltonismo)
	"flashes": 1,                           ## destellos (golpes, rayos): 0 reducidos, 1 normales
	"shake": 1.0,                           ## temblor de cámara (0..1)
	"damage_numbers": 2,                    ## cifras de daño: 0 no, 1 solo los golpes fuertes, 2 todas (hito 11.2)
	"quality": 2,                           ## calidad gráfica: 0 baja, 1 media, 2 alta, 3 ultra (Quality, hito 11.5)
	"dif_levels": {},                       ## dificultad (D-42, temporal): característica -> 1..10; sin ella, 3 (Difficulty)
	"madness": true,                        ## locura acumulada (GDD 4.5)
	"intro": 1,                             ## ficha e intro al arrancar: 0 siempre, 1 solo la primera vez (hito 5.2)
	"intro_seen": false,
	"keys": {}, "joy": {},                  ## reasignaciones: acción -> tecla / botón
	"controls_rev": 0, "controls_base": 0,  ## copia de los controles en la nube (como SaveData.rev y cloud_base)
}
signal controls_changed                     ## se reasignó algo (la nube lo sube: `Cloud`)

var values := {}
var path := PATH                            ## los tests usan otro fichero
var dev_window := false                     ## ejecución de pruebas: siempre en ventana (main.gd)
var force_fullscreen := false               ## `fullscreen=true`: pantalla completa solo en esta ejecución
var _fps_label: Label
var _overrides := {}                        ## `cfg_<clave>=valor` al lanzar: solo esta ejecución (capturas)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	load_file()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("cfg_") and "=" in a:
			var kv := a.substr(4).split("=", true, 1)
			_overrides[kv[0]] = str_to_var(kv[1]) if str_to_var(kv[1]) != null else kv[1]
	apply_audio()

func get_value(key: String) -> Variant:
	if _overrides.has(key): return _overrides[key]
	return values.get(key, defaults.get(key))

## Gamma del brillo elegido (1 = el de fábrica).
func brightness_gamma() -> float:
	return BRIGHTNESS[clampi(int(get_value("brightness")), 0, BRIGHTNESS.size() - 1)]

func set_value(key: String, v: Variant) -> void:
	values[key] = v
	save_file()

func load_file() -> void:
	values = defaults.duplicate(true)
	if not FileAccess.file_exists(path): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary: return
	for k in parsed:
		if k != "version" and defaults.has(k): values[k] = parsed[k]
	if parsed.has("difficulty") and not parsed.has("dif_levels"):   # la de tres (hasta el 29-10-2026): 1, 3 o 6
		var lv: int = [1, 3, 6][clampi(int(parsed.difficulty), 0, 2)]      # (Pesadilla, el 6 desde el reparto del 13.2)
		var d := {}
		for c in Difficulty.CATS: d[c] = lv
		values["dif_levels"] = d

func save_file() -> void:
	var d := values.duplicate(true)
	d["version"] = VERSION
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d, "\t"))

func reset_all() -> void:
	values = defaults.duplicate(true)
	save_file()
	apply_all()

const UI_SCALES := [0.85, 1.0, 1.15, 1.3]

func apply_all() -> void:
	apply_ui()
	apply_video()
	apply_audio()

## Tamaño de la interfaz (hito 8.3): escala todo lo 2D (menús y HUD) sobre la base 1920x1080.
func apply_ui() -> void:
	if not is_inside_tree(): return
	get_window().content_scale_factor = UI_SCALES[clampi(int(get_value("ui_scale")), 0, UI_SCALES.size() - 1)]

# ---------------------------------------------------------------- vídeo

func apply_video() -> void:
	if DisplayServer.get_name() == "headless": return
	var full: bool = (get_value("fullscreen") or force_fullscreen) and not dev_window
	if full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)   # la normal deja 1 px de borde
	else:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if not dev_window:
			var r: Vector2i = RESOLUTIONS[clampi(int(get_value("resolution")), 0, RESOLUTIONS.size() - 1)]
			var screen := DisplayServer.screen_get_usable_rect()
			r = Vector2i(mini(r.x, screen.size.x), mini(r.y, screen.size.y))
			DisplayServer.window_set_size(r)
			DisplayServer.window_set_position(screen.position + (screen.size - r) / 2)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if get_value("vsync") else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(get_value("fps_limit"))
	get_viewport().scaling_3d_scale = float(get_value("scale_3d"))
	Quality.apply_viewport(get_viewport())
	_update_fps_label()

# ---------------------------------------------------------------- audio

func _make_buses() -> void:
	for pair in [[BUS_MUSIC, &"Master"], [BUS_SFX, &"Master"], [BUS_AMBIENT, BUS_SFX]]:
		if AudioServer.get_bus_index(pair[0]) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, pair[0])
			AudioServer.set_bus_send(i, pair[1])

func apply_audio() -> void:
	for pair in [[&"Master", "vol_master"], [BUS_MUSIC, "vol_music"], [BUS_SFX, "vol_sfx"], [BUS_AMBIENT, "vol_ambient"]]:
		var i := AudioServer.get_bus_index(pair[0])
		var v := float(get_value(pair[1]))
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)

# ---------------------------------------------------------------- controles

## Asignación de controles: la de fábrica más las reasignaciones guardadas.
func bindings() -> InputBindings:
	var b: InputBindings = (load("res://data/input/bindings_default.tres") as InputBindings).duplicate(true)
	b.keys = b.keys.duplicate(true)
	b.joy_buttons = b.joy_buttons.duplicate(true)
	var keys: Dictionary = get_value("keys")
	for a in keys:
		var k := int(keys[a])
		match String(a):
			"up": b.key_up = [k as Key, KEY_UP]
			"down": b.key_down = [k as Key, KEY_DOWN]
			"left": b.key_left = [k as Key, KEY_LEFT]
			"right": b.key_right = [k as Key, KEY_RIGHT]
			_: b.keys[StringName(a)] = [k]
	var joy: Dictionary = get_value("joy")
	for a in joy: b.joy_buttons[StringName(a)] = [int(joy[a])]
	return b

## Tecla principal de una acción (la que se muestra y se reasigna).
func key_for(action: StringName) -> int:
	var keys: Dictionary = get_value("keys")
	if keys.has(String(action)): return int(keys[String(action)])
	var b: InputBindings = load("res://data/input/bindings_default.tres")
	match String(action):
		"up": return b.key_up[0]
		"down": return b.key_down[0]
		"left": return b.key_left[0]
		"right": return b.key_right[0]
	return (b.keys.get(action, [KEY_NONE]) as Array)[0]

func joy_for(action: StringName) -> int:
	var joy: Dictionary = get_value("joy")
	if joy.has(String(action)): return int(joy[String(action)])
	var b: InputBindings = load("res://data/input/bindings_default.tres")
	return (b.joy_buttons.get(action, [JOY_BUTTON_INVALID]) as Array)[0]

## Asigna una tecla a una acción. Si otra acción la usaba, se intercambian.
func set_key(action: StringName, key: int) -> void:
	var keys: Dictionary = (get_value("keys") as Dictionary).duplicate()
	var old := key_for(action)
	for pair in REMAP_ACTIONS:
		var other: StringName = pair[0]
		if other != action and key_for(other) == key: keys[String(other)] = old
	keys[String(action)] = key
	values["keys"] = keys
	_controls_saved()

func set_joy(action: StringName, button: int) -> void:
	var joy: Dictionary = (get_value("joy") as Dictionary).duplicate()
	var old := joy_for(action)
	for pair in REMAP_ACTIONS:
		var other: StringName = pair[0]
		if other in [&"up", &"down", &"left", &"right"]: continue     # el mando se mueve con el stick
		if other != action and joy_for(other) == button: joy[String(other)] = old
	joy[String(action)] = button
	values["joy"] = joy
	_controls_saved()

func reset_controls() -> void:
	values["keys"] = {}
	values["joy"] = {}
	_controls_saved()

func _controls_saved() -> void:
	values["controls_rev"] = int(get_value("controls_rev")) + 1
	save_file()
	controls_changed.emit()

## Controles para la nube: {"rev", "cloud_base", "keys", "joy"}.
func controls_dict() -> Dictionary:
	return {"rev": int(get_value("controls_rev")), "cloud_base": int(get_value("controls_base")),
		"keys": (get_value("keys") as Dictionary).duplicate(), "joy": (get_value("joy") as Dictionary).duplicate()}

## Pone los controles que bajan de la nube (o marca los de aquí como subidos, con los mismos).
func store_controls(d: Dictionary) -> void:
	values["keys"] = (d.get("keys", {}) as Dictionary).duplicate()
	values["joy"] = (d.get("joy", {}) as Dictionary).duplicate()
	values["controls_rev"] = int(d.get("rev", 0))
	values["controls_base"] = int(d.get("rev", 0))
	save_file()

const JOY_NAMES := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Select", JOY_BUTTON_GUIDE: "Guía", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "Stick izquierdo", JOY_BUTTON_RIGHT_STICK: "Stick derecho",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Cruceta arriba", JOY_BUTTON_DPAD_DOWN: "Cruceta abajo",
	JOY_BUTTON_DPAD_LEFT: "Cruceta izquierda", JOY_BUTTON_DPAD_RIGHT: "Cruceta derecha"}

static func joy_name(b: int) -> String:
	return JOY_NAMES.get(b, "Botón %d" % b)

static func key_name(k: int) -> String:
	var names := {KEY_SPACE: "Espacio", KEY_ESCAPE: "Esc", KEY_ENTER: "Intro", KEY_TAB: "Tab",
		KEY_UP: "Flecha arriba", KEY_DOWN: "Flecha abajo", KEY_LEFT: "Flecha izquierda", KEY_RIGHT: "Flecha derecha",
		KEY_SHIFT: "Mayús", KEY_CTRL: "Ctrl", KEY_ALT: "Alt", KEY_BACKSPACE: "Retroceso"}
	return names.get(k, OS.get_keycode_string(k))

# ---------------------------------------------------------------- juego

func _update_fps_label() -> void:
	var on: bool = get_value("show_fps")
	if on and _fps_label == null:
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		_fps_label = UiKit.label("", 16, UiKit.XP)
		_fps_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		_fps_label.offset_left = 10
		_fps_label.offset_top = -30
		layer.add_child(_fps_label)
	if _fps_label: _fps_label.visible = on

func _process(_delta: float) -> void:
	if _fps_label and _fps_label.visible: _fps_label.text = "%d FPS" % Engine.get_frames_per_second()
