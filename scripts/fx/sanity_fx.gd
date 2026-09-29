class_name SanityFx
extends CanvasLayer
## Distorsiones de cordura baja (GDD 4.4): borde violeta que palpita y, en solitario, algo
## de desaturación, por debajo del HUD. Empiezan por debajo del 35 % de cordura y llegan al
## máximo en una crisis. Solo ambientación; la intensidad la limita la configuración
## (Juego > Distorsiones) y a 0 no se dibuja nada.

var players: Array[Player] = []
var _rect: ColorRect
var _mat: ShaderMaterial

const START := 0.35                           ## fracción de cordura a la que empiezan

func setup(p_players: Array[Player]) -> SanityFx:
	players = p_players
	layer = 4
	return self

func _ready() -> void:
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://scripts/fx/sanity_fx.gdshader")
	_rect.material = _mat
	add_child(_rect)

## Intensidad para un jugador: 0 con la cordura por encima del 35 %, 1 en crisis.
static func level_for(p: Player) -> float:
	if p.health <= 0.0: return 0.0
	if p.sanity_state.in_crisis: return 1.0
	var f := p.sanity / maxf(p.data.max_sanity, 1.0)
	return clampf((START - f) / START, 0.0, 1.0) * 0.8

func _process(_delta: float) -> void:
	var strength := float(Settings.get_value("distortion"))
	var lv := Vector4.ZERO
	for p in players:
		if p.index < 4: lv[p.index] = level_for(p)
	var on := strength > 0.0 and (lv.x > 0.0 or lv.y > 0.0 or lv.z > 0.0 or lv.w > 0.0)
	_rect.visible = on                         # sin nada que mostrar no cuesta nada
	if not on: return
	_mat.set_shader_parameter("levels", lv)
	_mat.set_shader_parameter("solo", players.size() == 1)
	_mat.set_shader_parameter("strength", strength)
