class_name TitleGust
extends ColorRect
## Ráfaga de aire en la portada (18-10-2026): cada 25-50 s entra una corriente que levanta el
## borde del pergamino del escritorio y lo hace temblar, tumba y hace temblar todas las velas a la
## vez (uniforme `gust` de background.gdshader) y aparta un momento a las polillas de la llama.
## Este nodo es el rectángulo del pergamino (title_pages.gdshader) y lleva el ritmo de la ráfaga.

const RECT := Rect2(320, 820, 318, 100)        ## pergamino y algo de aire por encima (1920×1080); sin tocar el libro de la derecha
const RISE := 0.45                              ## s que tarda en llegar a lo más fuerte
const HOLD := 0.9
const FALL := 1.8
const LIFT := 9.0                               ## px que sube el borde del papel

var first := 14.0
var gap_min := 25.0
var gap_max := 50.0
var bg_mat: ShaderMaterial                      ## velas
var moths: TitleMoths
var pages := true                               ## el papel se levanta (si no, solo velas y polillas)
var strength := 0.0                             ## 0..1 en este momento
var _t := 0.0
var _next := 0.0
var _g := -1.0                                  ## s desde que empezó la ráfaga
var _rng := RandomNumberGenerator.new()

func _init(art: Texture2D, first_time := 14.0) -> void:
	first = first_time
	_rng.randomize()
	position = RECT.position
	size = RECT.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/title/title_pages.gdshader")
	m.set_shader_parameter("art", art)
	m.set_shader_parameter("rect", Vector4(RECT.position.x, RECT.position.y, RECT.size.x, RECT.size.y))
	material = m

func _ready() -> void:
	_next = first

## Lanza una ráfaga ya (pruebas).
func blow() -> void:
	_g = 0.0

func _process(delta: float) -> void:
	_t += delta
	if _g < 0.0 and _t >= _next:
		blow()
	if _g >= 0.0:
		_g += delta
		var up := smoothstep(0.0, RISE, _g)
		var down := 1.0 - smoothstep(RISE + HOLD, RISE + HOLD + FALL, _g)
		# racheada: no sopla igual todo el rato
		strength = up * down * (0.8 + 0.2 * sin(_g * 9.0) * sin(_g * 4.3 + 1.0))
		if _g > RISE + HOLD + FALL:
			_g = -1.0
			strength = 0.0
			_next = _t + _rng.randf_range(gap_min, gap_max)
	var m := material as ShaderMaterial
	m.set_shader_parameter("lift", LIFT * strength if pages else 0.0)
	m.set_shader_parameter("time", _t)
	if bg_mat: bg_mat.set_shader_parameter("gust", strength)
	if moths: moths.gust = strength
