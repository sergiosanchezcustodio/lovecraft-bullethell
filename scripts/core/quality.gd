class_name Quality
extends RefCounted
## Calidad gráfica (hito 11.5, 28-10-2026): cuatro preajustes (Baja, Media, Alta, Ultra) en
## data/quality.json. Alta es como se veía el juego hasta ahora. Lo del visor (suavizado y
## sombras) lo pone Settings.apply_video; lo de la partida (SSAO, niebla de los faroles,
## distancia de las sombras, desmoronarse, manchas y luces de las explosiones), Game al montarla.

const DEFAULT := 2
static var _presets: Array = []

static func presets() -> Array:
	if _presets.is_empty():
		var f := FileAccess.open("res://data/quality.json", FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		_presets = (d as Dictionary).get("presets", []) if d is Dictionary else []
	return _presets

static func names() -> Array[String]:
	var out: Array[String] = []
	for p: Dictionary in presets(): out.append(String(p.get("name", "")))
	return out

## Preajuste elegido en la configuración (`quality`; `cfg_quality=N` para una ejecución).
static func current() -> Dictionary:
	var all := presets()
	if all.is_empty(): return {}
	return all[clampi(int(Auto.setting("quality", DEFAULT)), 0, all.size() - 1)]

static func value(key: String, default: Variant) -> Variant:
	return current().get(key, default)

## Suavizado y sombras de la luna: del visor y del servidor de dibujo, valen para todas las escenas.
static func apply_viewport(vp: Viewport) -> void:
	var q := current()
	if q.is_empty(): return
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X][clampi(int(q.get("msaa", 2)), 0, 3)]
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if bool(q.get("fxaa", false)) else Viewport.SCREEN_SPACE_AA_DISABLED
	vp.use_taa = bool(q.get("taa", false))
	RenderingServer.directional_shadow_atlas_set_size(int(q.get("shadow", 4096)), true)
	RenderingServer.directional_soft_shadow_filter_set_quality(clampi(int(q.get("shadow_soft", 2)), 0, 5) as RenderingServer.ShadowQuality)

## Lo de la partida. `env`, el entorno; `moon`, la luz de la luna.
static func apply_game(env: Environment, moon: DirectionalLight3D) -> void:
	var q := current()
	if q.is_empty(): return
	if bool(q.get("ssao", false)) and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		env.ssao_enabled = true
		env.ssao_radius = 0.6                  # corto: los huecos entre voxels y el pie de las piezas
		env.ssao_intensity = 1.4
		env.ssao_power = 1.3
		env.ssao_light_affect = 0.15
	if moon != null: moon.directional_shadow_max_distance = float(q.get("shadow_dist", 60.0))
	Crumble.enabled = bool(q.get("crumble", true))
	GroundMarks.limit = int(q.get("marks", 24))
	Explosion.max_lit = int(q.get("lights", 8))
