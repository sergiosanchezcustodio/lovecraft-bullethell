class_name CandleOut
extends CanvasLayer
## La vela se apaga (hito 20.3): al salir del juego y al volver a la portada desde la partida, la
## oscuridad se cierra hacia una llama que tiembla, se apaga y deja un hilo de humo; después,
## `then` (salir o cambiar de escena). Suena `candle_out`. Cualquier botón lo acaba antes.
## Capturas: `probar_vela.gd` (tools).

const SHADER := preload("res://scripts/ui/candle_out.gdshader")
const TIME := 0.7

var _then: Callable
var _mat: ShaderMaterial
var _t := 0.0
var _done := false

static func play(parent: Node, then: Callable) -> CandleOut:
	var c := CandleOut.new()
	c._then = then
	c.layer = 128
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(c)
	return c

## El rectángulo con el sombreador, a pantalla completa (también para la hoja de prueba).
static func make_rect(view: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("aspect", Vector2(view.x / maxf(view.y, 1.0), 1.0))
	m.set_shader_parameter("black", LevelCard.BLACK)
	r.material = m
	return r

func _ready() -> void:
	var r := make_rect(get_viewport().get_visible_rect().size)
	_mat = r.material
	add_child(r)
	Auto.sfx("candle_out")

func _process(delta: float) -> void:
	_t += delta
	_mat.set_shader_parameter("time_s", _t)
	_mat.set_shader_parameter("t", clampf(_t / TIME, 0.0, 1.0))
	if _t >= TIME + 0.05: _finish()

func _input(event: InputEvent) -> void:
	if _done or _t < 0.15: return
	if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_finish()

func _finish() -> void:
	if _done: return
	_done = true
	_mat.set_shader_parameter("t", 1.0)
	_then.call()
