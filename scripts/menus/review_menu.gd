class_name ReviewMenu
extends Control
## Revisión de arte (temporal, 12-10-2026), desde el menú principal. Una pestaña por tipo de
## imagen (Review.SECTIONS) con una cuadrícula de miniaturas y su nombre; al elegir una, a la
## derecha se ve en grande (los modelos giran), con un cuadro para pedir cambios a Claude y el
## estado de lo pedido. Cada POLL s relee las peticiones y mira si el archivo de la imagen ha
## cambiado en disco: si es así, la recarga sola en el mismo sitio.

signal closed

const POLL := 1.5
const THUMB := 150
const COLS := 6

var _section := 0
var _entries: Array[Dictionary] = []
var _cards: Array[Button] = []
var _thumbs: Array[TextureRect] = []
var _stamps: Array[int] = []
var _queue: Array[int] = []                  ## miniaturas por hacer (unas pocas por fotograma)
var _sel := -1
var _tabs: Array[Button] = []
var _sections: Array = []                   ## las pestañas que salen (Review.sections)
var _grid: GridContainer
var _scroll: ScrollContainer
var _big_img: TextureRect
var _big_vp: SubViewport
var _big_box: SubViewportContainer
var _big_pivot: Node3D
var _name: Label
var _info: Label
var _text: TextEdit
var _send: Button
var _log: RichTextLabel
var _poll_t := 0.0
var _host: Node                              ## padre de los SubViewport de las miniaturas

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.04, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_host = Node.new()
	add_child(_host)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 30; root.offset_right = -30; root.offset_top = 20; root.offset_bottom = -20
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	top.add_child(MenuKit.title("Revisión de arte (temporal)", 34))
	_sections = Review.sections()
	for i in _sections.size():
		var b := MenuKit.button(String(_sections[i].title), MenuKit.INK, 20)
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_show_section.bind(i))
		top.add_child(b)
		_tabs.append(b)
	var close := MenuKit.button("Cerrar", MenuKit.INK, 20)
	close.pressed.connect(_close)
	top.add_child(close)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_scroll.add_child(_grid)
	body.add_child(_detail_panel())
	_show_section(0)

func _detail_panel() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(640, 0)
	col.add_theme_constant_override("separation", 8)
	var view := Control.new()
	view.custom_minimum_size = Vector2(640, 440)
	col.add_child(view)
	_big_img = TextureRect.new()
	_big_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_big_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.add_child(_big_img)
	_big_box = SubViewportContainer.new()
	_big_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_big_box.stretch = true
	view.add_child(_big_box)
	_big_vp = SubViewport.new()
	_big_vp.transparent_bg = true
	_big_vp.own_world_3d = true
	_big_box.add_child(_big_vp)
	_name = UiKit.label("", 28, UiKit.TEXT)
	col.add_child(_name)
	_info = UiKit.label("", 16, UiKit.TEXT_DIM)
	col.add_child(_info)
	col.add_child(UiKit.label("¿Qué quieres cambiar?", 18, UiKit.TEXT))
	_text = TextEdit.new()
	_text.custom_minimum_size = Vector2(640, 110)
	_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text.placeholder_text = "Ej.: la cara más anciana, la gabardina más larga y de color gris piedra…"
	col.add_child(_text)
	_send = MenuKit.button("Enviar petición a Claude", MenuKit.INK, 22)
	_send.pressed.connect(_on_send)
	col.add_child(_send)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = false
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size = Vector2(640, 120)
	col.add_child(_log)
	return col

# ------------------------------------------------------------------ secciones

func _show_section(i: int) -> void:
	_section = i
	for k in _tabs.size(): _tabs[k].modulate = Color.WHITE if k == i else Color(1, 1, 1, 0.55)
	for c in _grid.get_children(): c.queue_free()
	for c in _host.get_children(): c.queue_free()
	_cards.clear(); _thumbs.clear(); _stamps.clear(); _queue.clear()
	_entries = Review.entries(String(_sections[i].id))
	for k in _entries.size():
		var e := _entries[k]
		var b := Button.new()
		b.custom_minimum_size = Vector2(THUMB + 20, THUMB + 54)
		b.toggle_mode = true
		b.add_theme_stylebox_override("normal", UiKit.panel(Color(0.08, 0.08, 0.1, 0.9), Color(1, 1, 1, 0.08)))
		b.add_theme_stylebox_override("pressed", UiKit.panel(Color(0.16, 0.13, 0.08, 0.95), Color(1.0, 0.8, 0.4, 0.8)))
		b.pressed.connect(_select.bind(k))
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var t := TextureRect.new()
		t.custom_minimum_size = Vector2(THUMB, THUMB)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		var l := UiKit.label(String(e.name), 14, UiKit.TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(THUMB + 16, 0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		_grid.add_child(b)
		_cards.append(b); _thumbs.append(t); _stamps.append(Review.stamp(e)); _queue.append(k)
	_sel = -1
	if not _entries.is_empty(): _select(0)

func _select(k: int) -> void:
	_sel = k
	for i in _cards.size(): _cards[i].button_pressed = i == k
	var e := _entries[k]
	_name.text = String(e.name)
	_info.text = "%s  ·  clave: %s" % [e.info, e.id]
	_show_big(e)
	_refresh_log()

func _show_big(e: Dictionary) -> void:
	for c in _big_vp.get_children(): c.queue_free()
	_big_pivot = null
	if String(e.model) == "":
		_big_box.visible = false
		_big_img.visible = true
		_big_img.texture = Review.load_png(String(e.image))
		return
	_big_img.visible = false
	_big_box.visible = true
	var m := VoxelBuilder.load_model("res://models/%s.json" % e.model)
	_big_pivot = Node3D.new()
	_big_vp.add_child(_big_pivot)
	_big_pivot.add_child(m)
	var b := _model_aabb(m, "head" if String(e.get("focus", "")) == "cabeza" else "")
	m.position = -b.get_center()                       # gira sobre su centro (o el de la cabeza)
	var radius := b.size.length() * 0.5
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = ModelIcon.FULL_ROT
	cam.size = radius * 2.1
	cam.position = cam.transform.basis.z * (radius * 3.0 + 4.0)
	_big_vp.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, 50, 0)
	key.light_energy = 1.35
	key.light_color = Color(1.0, 0.95, 0.88)
	_big_vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -60, 0)
	fill.light_energy = 0.4
	fill.light_color = Color(0.75, 0.82, 1.0)
	_big_vp.add_child(fill)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.14, 0.16)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	_big_vp.add_child(we)

## part: solo lo que cuelga de esa parte (la cabeza, con lo que lleva encima).
static func _model_aabb(m: Node3D, part := "") -> AABB:
	var out := AABB()
	var first := true
	for mi: MeshInstance3D in m.get_meta("meshes"):
		var xf := Transform3D()
		var n: Node = mi
		var inside := part == ""
		while n != m and n is Node3D:
			if n.name == part: inside = true
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		if not inside: continue
		var b: AABB = xf * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out

func _make_thumb(k: int) -> void:
	var e := _entries[k]
	if String(e.model) != "":
		var mode := "head" if String(e.get("focus", "")) == "cabeza" else "full"
		_thumbs[k].texture = ModelIcon.make(_host, String(e.model), mode, THUMB)
	else: _thumbs[k].texture = Review.load_png(String(e.image))

# ------------------------------------------------------------------ peticiones

func _on_send() -> void:
	var txt := _text.text.strip_edges()
	if txt == "" or _sel < 0: return
	Review.add_request(String(_sections[_section].id), _entries[_sel], txt)
	_text.text = ""
	Sfx.play("ui_accept")
	_refresh_log()

func _refresh_log() -> void:
	if _sel < 0: return
	var list := Review.requests_for(String(_sections[_section].id), String(_entries[_sel].id))
	if list.is_empty():
		_log.text = "[color=#888]Sin peticiones para esta imagen.[/color]"
		return
	var lines: Array[String] = []
	for r in list:
		var st := String(r.get("estado", "pendiente"))
		var col: String = {"pendiente": "#d9b45a", "en curso": "#6fb6ff", "hecho": "#7ddc7d"}.get(st, "#e07070")
		lines.append("[color=%s]● %s[/color]  [color=#aaa]%s[/color]\n%s" % [col, st.to_upper(), String(r.get("fecha", "")), String(r.get("texto", ""))])
		if String(r.get("respuesta", "")) != "": lines.append("[color=#9ad]Claude: %s[/color]" % r.respuesta)
	_log.text = "\n\n".join(lines)

# ------------------------------------------------------------------ bucle

func _process(delta: float) -> void:
	for i in 2:                                        # miniaturas: dos por fotograma
		if _queue.is_empty(): break
		_make_thumb(_queue.pop_front())
	if _big_pivot: _big_pivot.rotation.y += delta * 0.6
	_poll_t -= delta
	if _poll_t > 0.0: return
	_poll_t = POLL
	_refresh_log()
	for k in _entries.size():                           # ¿ha cambiado algún archivo? se recarga solo
		var s := Review.stamp(_entries[k])
		if s != _stamps[k]:
			_stamps[k] = s
			if String(_entries[k].model) != "": VoxelBuilder.forget("res://models/%s.json" % _entries[k].model)
			_make_thumb(k)
			if k == _sel: _show_big(_entries[k])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _text.has_focus():
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	closed.emit()
	queue_free()
