class_name BookTransition
extends CanvasLayer
## De la portada a la selección de personaje se abre el libro de la Biblioteca (hito 12.14, D-41):
## fundido a negro, aparece la ilustración (libro.png, la misma de la Biblioteca) alejándose un
## poco, pasan dos páginas (la derecha gira sobre el lomo y cae a la izquierda; su dorso es la
## misma página en espejo, que se parece a la izquierda) y la vista se acerca a la página nueva
## mientras funde a negro. La selección aparece desde negro (`arrive`). Cualquier botón la salta.
## Capturas: `title saves=demo_saves open=menu_libro shots=… tag=…`.

const ART := preload("res://resources/PantallasMenus/libro.png")
const RIGHT_PAGE := Rect2(0.5125, 0.035, 0.3675, 0.885)   ## la página derecha entera (con sus bordes)
const TO_BLACK := 0.35
const SHOW := 0.5
const FLIP := 0.6                              ## s que tarda en pasar una página
const FLIP_GAP := 0.32                         ## s entre una y la siguiente
const FLIPS := 2
const ZOOM := 0.65

static var pending := false                    ## la siguiente escena llega desde negro

var _scene := ""
var _black: ColorRect
var _veil: ColorRect                           ## el negro final, encima del libro
var _stage: Node2D
var _t := 0.0
var _leaving := false

static func play(parent: Node, scene: String) -> BookTransition:
	var b := BookTransition.new()
	b._scene = scene
	b.layer = 120
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(b)
	return b

## La escena que llega (la selección) aparece desde negro si venía del libro.
static func arrive(parent: Node) -> void:
	if not pending: return
	pending = false
	var c := CanvasLayer.new()
	c.layer = 120
	parent.add_child(c)
	var r := _rect(c, 1.0)
	var tw := c.create_tween()
	tw.tween_property(r, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(c.queue_free)

static func _rect(parent: Node, a: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, a)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _ready() -> void:
	_black = _rect(self, 0.0)
	var view := get_viewport().get_visible_rect().size
	var size := Vector2(ART.get_size())
	var s := maxf(view.x / size.x, view.y / size.y)          # cubre la pantalla, como en la Biblioteca
	_stage = Node2D.new()
	_stage.position = view * 0.5
	_stage.scale = Vector2.ONE * s * 1.05
	_stage.modulate.a = 0.0
	add_child(_stage)
	var book := Sprite2D.new()                                 # centrada en el escenario
	book.texture = ART
	_stage.add_child(book)
	_veil = _rect(self, 0.0)
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 1.0, TO_BLACK).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_stage, "modulate:a", 1.0, SHOW)
	tw.parallel().tween_property(_stage, "scale", Vector2.ONE * s, SHOW * 0.6 + (FLIPS - 1) * FLIP_GAP + FLIP + 0.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for i in FLIPS:
		tw.parallel().tween_callback(_flip).set_delay(SHOW * 0.6 + i * FLIP_GAP)
	var page_center := (RIGHT_PAGE.get_center() - Vector2(0.5, 0.5)) * size     # hacia la página nueva
	tw.tween_property(_stage, "scale", Vector2.ONE * s * 1.7, ZOOM).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_stage, "position", view * 0.5 - page_center * s * 0.7, ZOOM) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_veil, "color:a", 1.0, ZOOM).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_go)

func _process(delta: float) -> void:
	_t += delta

## Una página: la derecha gira sobre el lomo hasta caer a la izquierda. Al ponerse de canto se
## oscurece y se levanta un poco hacia la vista.
func _flip() -> void:
	var size := Vector2(ART.get_size())
	var p := Sprite2D.new()
	p.texture = ART
	p.centered = false
	p.region_enabled = true
	p.region_rect = Rect2(RIGHT_PAGE.position * size, RIGHT_PAGE.size * size)
	p.position = RIGHT_PAGE.position * size - size * 0.5      # el borde izquierdo del recorte, en el lomo
	_stage.add_child(p)
	Auto.sfx("page")
	var tw := create_tween()
	tw.tween_method(_turn.bind(p), 0.0, 1.0, FLIP).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _turn(u: float, p: Sprite2D) -> void:
	var a := u * PI
	var edge := sin(a)                                          # 1 de canto
	p.scale = Vector2(cos(a), 1.0 + 0.05 * edge)
	p.position.y = RIGHT_PAGE.position.y * ART.get_size().y - ART.get_size().y * 0.5 - RIGHT_PAGE.size.y * ART.get_size().y * 0.025 * edge
	var lit := lerpf(1.0, 0.45, edge) if u < 0.5 else lerpf(0.75, 1.0, 1.0 - edge)   # el dorso, algo en sombra
	p.modulate = Color(lit, lit * 0.97, lit * 0.92)

func _input(event: InputEvent) -> void:
	if _leaving or _t < 0.25: return
	if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_go()

func _go() -> void:
	if _leaving: return
	_leaving = true
	pending = true
	get_tree().change_scene_to_file(_scene)
