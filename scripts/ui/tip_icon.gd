class_name TipIcon
extends Control
## Icono con descripción emergente: al dejar el ratón encima, al tener el foco o al marcarlo
## como seleccionado (`selected`, para menús que se manejan con el mando sin el foco de Godot),
## muestra tras DELAY s un recuadro con su nombre y su descripción. Sirve para armas, objetos,
## atributos y estadísticas. Sin textura dibuja un hueco con `placeholder`.

const DELAY := 0.45

var tip_title := ""
var tip_text := ""
var selected := false:
	set(v):
		selected = v
		queue_redraw()
var placeholder := ""

var _tex: TextureRect
var _ph: Label
var _bubble: PanelContainer
var _bubble_title: Label
var _bubble_text: Label
var _hover := false
var _t := 0.0

func _init(icon_size: Vector2 = Vector2(32, 32)) -> void:
	custom_minimum_size = icon_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tex = TextureRect.new()
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_tex)
	_ph = UiKit.label("", 14, UiKit.TEXT)
	_ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_ph)
	mouse_entered.connect(func() -> void: _hover = true)
	mouse_exited.connect(func() -> void: _hover = false)

func set_icon(tex: Texture2D, title: String, text: String = "") -> void:
	_tex.texture = tex
	_ph.text = "" if tex else placeholder
	tip_title = title
	tip_text = text
	if _bubble and _bubble.visible: _fill()

func _ready() -> void:
	_bubble = PanelContainer.new()
	_bubble.visible = false
	_bubble.z_index = 100
	_bubble.z_as_relative = false
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_theme_stylebox_override("panel", UiKit.panel(Color(0.03, 0.03, 0.04, 0.96), Color(UiKit.GOLD, 0.7), 6))
	var v := VBoxContainer.new()
	_bubble.add_child(v)
	_bubble_title = UiKit.label("", 17, UiKit.GOLD)
	v.add_child(_bubble_title)
	_bubble_text = UiKit.label("", 15, UiKit.TEXT)
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text.custom_minimum_size.x = 240
	v.add_child(_bubble_text)
	add_child(_bubble)

func _fill() -> void:
	_bubble_title.text = tip_title
	_bubble_text.text = tip_text
	_bubble_text.visible = tip_text != ""
	_bubble.reset_size()

func _process(delta: float) -> void:
	var on := is_visible_in_tree() and (_hover or selected or has_focus()) and tip_title != ""
	_t = _t + delta if on else 0.0
	var want := on and _t >= DELAY
	if want and not _bubble.visible:
		_fill()
		_bubble.visible = true
		# a la derecha del icono; si no cabe en el marco de 1920x1080, a la izquierda
		var right := global_position.x + size.x * get_global_transform().get_scale().x
		_bubble.position = Vector2(size.x + 8, 0)
		if right + _bubble.size.x * get_global_transform().get_scale().x > get_viewport_rect().size.x - 8:
			_bubble.position.x = -_bubble.size.x - 8
		# si se sale por abajo, se sube lo que haga falta
		var k := get_global_transform().get_scale().y
		var over := global_position.y + _bubble.size.y * k - (get_viewport_rect().size.y - 8)
		if over > 0.0: _bubble.position.y = -over / k
	elif not want and _bubble.visible:
		_bubble.visible = false

func _draw() -> void:
	if selected:
		draw_rect(Rect2(Vector2(-3, -3), size + Vector2(6, 6)), Color(UiKit.GOLD, 0.9), false, 2.0)
