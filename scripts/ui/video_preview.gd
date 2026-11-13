class_name VideoPreview
extends CenterContainer
## Vista previa (hito 20.12): una miniatura de la partida (el muelle de Innsmouth con cuatro
## investigadores, `tools/gen_vista_previa.py`) que cambia al tocar la calidad gráfica, los
## efectos de las armas, el brillo o el clima. Las miniaturas son capturas de verdad, una por
## combinación que se distingue (la calidad pone tope a los efectos); el brillo se aplica encima
## con la misma curva que la partida. `mode`: "video" (calidad y efectos, con el clima completo) o
## "weather" (el clima, con la calidad Alta y los efectos enteros).

const DIR := "res://resources/vista_previa/"
const SIZE := Vector2(480, 270)

var mode := "video"
var _tex: TextureRect
var _caption: Label
var _mat: ShaderMaterial

func _init(p_mode := "video") -> void:
	mode = p_mode

func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", MenuKit.box(Color(0.01, 0.01, 0.015), Color(MenuKit.BRASS, 0.7), 2))
	v.add_child(frame)
	_tex = TextureRect.new()
	_tex.custom_minimum_size = SIZE
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/ui/video_preview.gdshader")
	_tex.material = _mat
	frame.add_child(_tex)
	_caption = UiKit.label("", 15, UiKit.TEXT_DIM)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_caption)
	refresh(false)

## Efectos que de verdad se ven con esta calidad y esta opción (0 mínimos, 1 rebajados, 2 enteros),
## como `Quality.value("weapon_fx")` con un jugador.
static func effective_fx(quality: int, wfx_setting: int) -> int:
	var all := Quality.presets()
	var cap := int((all[clampi(quality, 0, all.size() - 1)] as Dictionary).get("weapon_fx", 2)) if not all.is_empty() else 2
	var s := 2 if wfx_setting >= Quality.WFX_AUTO else clampi(wfx_setting, 0, 2)
	return mini(s, cap)

static func video_file(quality: int, wfx_setting: int) -> String:
	return DIR + "vp_q%d_w%d.jpg" % [clampi(quality, 0, 3), effective_fx(quality, wfx_setting)]

static func weather_file(weather: int) -> String:
	return DIR + ("vp_q2_w2.jpg" if weather >= 2 else "vp_clima%d.jpg" % clampi(weather, 0, 1))

const FX_NAMES: Array[String] = ["efectos mínimos", "efectos rebajados", "efectos enteros"]
const WEATHER_NAMES: Array[String] = ["sin clima", "clima reducido", "clima completo"]

## Vuelve a elegir la miniatura y el brillo; `fade`: un fundido corto al cambiar.
func refresh(fade := true) -> void:
	if _tex == null: return
	var q := int(Settings.get_value("quality"))
	var path := video_file(q, int(Settings.get_value("weapon_fx")))
	var text := "Vista previa · %s · %s" % [Quality.names()[clampi(q, 0, Quality.names().size() - 1)] if not Quality.names().is_empty() else "",
		FX_NAMES[effective_fx(q, int(Settings.get_value("weapon_fx")))]]
	if mode == "weather":
		var w := clampi(int(Settings.get_value("weather")), 0, 2)
		path = weather_file(w)
		text = "Vista previa · %s (con la calidad Alta)" % WEATHER_NAMES[w]
	_caption.text = text
	_mat.set_shader_parameter("gamma", Settings.brightness_gamma())
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if tex == _tex.texture: return
	_tex.texture = tex
	if fade:
		_tex.modulate.a = 0.55
		create_tween().tween_property(_tex, "modulate:a", 1.0, 0.18)
