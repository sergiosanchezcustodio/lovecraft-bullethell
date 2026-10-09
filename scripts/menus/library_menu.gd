class_name LibraryMenu
extends Control
## Biblioteca Lovecraft (03-10-2026), desde el menú principal: un libro abierto. En la
## estantería, la página izquierda lista los tomos y la derecha dice cuánto se ha descubierto;
## dentro de un tomo, la izquierda es el índice y la derecha la ficha de la entrada con el
## foco (imagen, datos y la nota del diario). Lo no descubierto sale como "???" y su imagen,
## en silueta. El tomo de logros abre la lista de logros encima. Datos: Library.
## A abre, arriba y abajo recorren, B / Esc vuelve (del tomo a la estantería, de ahí cierra).
## Capturas: `title saves=… open=menu_biblioteca tome=N cursor=N`.
##
## El libro es una ilustración (09-10-2026, tools/generar_libro_biblioteca.py): cubre la pantalla
## y cada página es un recuadro en fracciones de la imagen (LEFT_PAGE, RIGHT_PAGE, dentro del
## marco dorado y sin pisar sus esquinas). El contenido se maqueta a un tamaño fijo (PAGE) y se
## escala al recuadro, así que no cambia con la resolución. Si se cambia la ilustración, hay que
## volver a medir los recuadros.

signal closed

const LEATHER := Color(0.2, 0.11, 0.06)
const LEATHER_EDGE := Color(0.1, 0.05, 0.03)
const PAPER := Color(0.86, 0.79, 0.64)
const PAPER_SHADE := Color(0.74, 0.66, 0.5)
const INK := Color(0.2, 0.13, 0.08)
const INK_DIM := Color(0.42, 0.34, 0.25)
const RED_INK := Color(0.5, 0.12, 0.08)
const PAGE := Vector2(680, 930)                ## tamaño de maqueta de cada página (se escala)
const ART := preload("res://resources/PantallasMenus/libro.png")
const LEFT_PAGE := Rect2(0.218, 0.143, 0.265, 0.664)    ## en fracciones de la ilustración
const RIGHT_PAGE := Rect2(0.549, 0.143, 0.280, 0.664)
const IMAGE_PX := 300

var save: SaveData
var _left: VBoxContainer
var _right: VBoxContainer
var _tome := ""                                ## "" = estantería
var _rows: Array[Button] = []
var _entries: Array[Dictionary] = []
var _icons := {}
var _shelf_focus := 0
var _sub: Control                              ## logros abiertos encima

func _ready() -> void:
	if save == null: save = Saves.current
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()                    # por si la pantalla no es 16:9
	bg.color = Color(0.02, 0.015, 0.01)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var fit := AspectRatioContainer.new()       # la ilustración cubre la pantalla sin deformarse
	fit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fit.ratio = float(ART.get_width()) / ART.get_height()
	fit.stretch_mode = AspectRatioContainer.STRETCH_COVER
	add_child(fit)
	var art := Control.new()
	fit.add_child(art)
	var tex := TextureRect.new()
	tex.texture = ART
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.add_child(tex)
	_left = _page(art, LEFT_PAGE)
	_right = _page(art, RIGHT_PAGE)
	_show_shelf()

## Página: un recuadro de la ilustración con una maqueta de PAGE escalada dentro. Devuelve su
## columna de contenido.
func _page(art: Control, r: Rect2) -> VBoxContainer:
	var holder := Control.new()
	holder.anchor_left = r.position.x; holder.anchor_right = r.end.x
	holder.anchor_top = r.position.y; holder.anchor_bottom = r.end.y
	art.add_child(holder)
	var sheet := MarginContainer.new()
	sheet.size = PAGE
	for k in ["margin_left", "margin_right"]: sheet.add_theme_constant_override(k, 18)
	sheet.add_theme_constant_override("margin_top", 6)
	sheet.add_theme_constant_override("margin_bottom", 6)
	holder.add_child(sheet)
	var fit_sheet := func() -> void:              # la maqueta, escalada al recuadro y centrada
		var k := minf(holder.size.x / PAGE.x, holder.size.y / PAGE.y)
		sheet.scale = Vector2.ONE * k
		sheet.position = (holder.size - PAGE * k) * 0.5
	holder.resized.connect(fit_sheet)
	fit_sheet.call_deferred()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	sheet.add_child(v)
	return v

static func _ink(text: String, size: int, color := INK, title_font := false) -> Label:
	var l := UiKit.label(text, size, color, false)
	if title_font: l.add_theme_font_override("font", MenuKit.font())
	return l

func _clear() -> void:
	for c in _left.get_children(): c.queue_free()
	for c in _right.get_children(): c.queue_free()
	_rows.clear()

func _row(text: String, size := 26) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", MenuKit.font())
	b.add_theme_font_size_override("font_size", size)
	for k in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, INK)
	var none := StyleBoxEmpty.new()
	var on := UiKit.panel(Color(0.55, 0.42, 0.24, 0.32), Color(RED_INK, 0.6), 4)
	on.content_margin_left = 10
	none.content_margin_left = 10
	b.add_theme_stylebox_override("normal", none)
	for k in ["focus", "hover", "pressed"]: b.add_theme_stylebox_override(k, on)
	_rows.append(b)
	return b

# ------------------------------------------------------------------ estantería

func _show_shelf() -> void:
	_clear()
	_tome = ""
	var t := _ink("Biblioteca Lovecraft", 54, INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_left.add_child(t)
	var s := _ink("Notas y fichas reunidas por los investigadores", 20, INK_DIM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_left.add_child(s)
	_left.add_child(_rule())
	for i in Library.TOMES.size():
		var tome: Dictionary = Library.TOMES[i]
		var n := Library.count_known(save, tome.id)
		var b := _row("Tomo %s  ·  %s" % [tome.roman, tome.title], 30)
		b.custom_minimum_size.y = 62
		var c := _ink("%d / %d" % [n.x, n.y], 22, INK_DIM)
		c.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		c.offset_left = -110; c.offset_right = -14
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.add_child(c)
		b.focus_entered.connect(func() -> void:
			_shelf_focus = i
			_show_tome_cover(i))
		b.pressed.connect(func() -> void: _open_tome(i))
		_left.add_child(b)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left.add_child(fill)
	_left.add_child(_hint("A: abrir  ·  B o Esc: cerrar"))
	MenuKit.chain_focus(_rows)
	_rows[_shelf_focus].grab_focus.call_deferred()

func _show_tome_cover(i: int) -> void:
	for c in _right.get_children(): c.queue_free()
	var tome: Dictionary = Library.TOMES[i]
	var n := Library.count_known(save, tome.id)
	var fill := Control.new()
	fill.custom_minimum_size.y = 150
	_right.add_child(fill)
	var r := _ink("Tomo %s" % tome.roman, 40, RED_INK, true)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_right.add_child(r)
	var t := _ink(tome.title, 58, INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(t)
	_right.add_child(_rule())
	var c := _ink("%s de %s" % [n.x, n.y] + (" conseguidos" if tome.id == "achievements" else " descubiertos"), 28, INK_DIM)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_right.add_child(c)
	var bar := UiKit.Bar.new(RED_INK, 420, 10)
	bar.value = float(n.x) / maxf(n.y, 1)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_right.add_child(bar)

# ------------------------------------------------------------------ tomo

func _open_tome(i: int) -> void:
	var tome: Dictionary = Library.TOMES[i]
	if tome.id == "achievements":
		_sub = AchievementsMenu.new()
		add_child(_sub)
		MenuKit.trap_focus(_sub)
		_sub.tree_exited.connect(func() -> void:
			_sub = null
			if is_inside_tree(): _rows[i].grab_focus.call_deferred())
		return
	_clear()
	_tome = tome.id
	_entries = Library.entries(save, tome.id)
	var t := _ink("Tomo %s  ·  %s" % [tome.roman, tome.title], 38, INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_left.add_child(t)
	_left.add_child(_rule())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_left.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)
	var section := ""
	for k in _entries.size():
		var e: Dictionary = _entries[k]
		if String(e.section) != section and String(e.section) != "":
			section = e.section
			var h := _ink(section, 20, RED_INK, true)
			if list.get_child_count() > 0: h.custom_minimum_size.y = 40
			h.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			list.add_child(h)
		var b := _row(String(e.name) if e.known else "???", 24)
		b.custom_minimum_size.x = PAGE.x - 130
		if not e.known: b.add_theme_color_override("font_color", INK_DIM)
		b.focus_entered.connect(func() -> void: _show_entry(k))
		list.add_child(b)
	_left.add_child(_hint("Arriba/abajo: recorrer  ·  B o Esc: volver a los tomos"))
	MenuKit.chain_focus(_rows)
	if not _rows.is_empty(): _rows[0].grab_focus.call_deferred()

func _show_entry(k: int) -> void:
	for c in _right.get_children(): c.queue_free()
	var e: Dictionary = _entries[k]
	var known: bool = e.known
	var tex := _image(e)
	if _tome == "places":                          # el mapa, a lo ancho de la página
		if tex != null and known:
			var map := TextureRect.new()
			map.texture = tex
			var h := 360.0                         # lo que deja libre el texto sin que crezca la página
			map.custom_minimum_size = Vector2(h * tex.get_width() / tex.get_height(), h)
			map.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_right.add_child(map)
		tex = null
	elif tex != null:
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UiKit.panel(Color(0.3, 0.22, 0.12, 0.12), Color(INK, 0.35), 4))
		frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var img := TextureRect.new()
		img.texture = tex
		img.custom_minimum_size = Vector2(IMAGE_PX, IMAGE_PX)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not known: img.modulate = Color(0.12, 0.08, 0.05, 0.85)     # silueta
		frame.add_child(img)
		_right.add_child(frame)
	else:
		var gap := Control.new()
		gap.custom_minimum_size.y = 40
		_right.add_child(gap)
	var n := _ink(String(e.name) if known else "???", 40, INK, true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(n)
	_right.add_child(_rule())
	if not known:
		var u := _ink(_unknown_text(), 22, INK_DIM)
		u.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		u.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_right.add_child(u)
		return
	for f in e.facts:
		var l := _ink(String(f), 19, RED_INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_right.add_child(l)
	if String(e.text) != "":
		var txt := _ink(String(e.text), 22, INK)
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_right.add_child(txt)

func _unknown_text() -> String:
	match _tome:
		"enemies": return "Aún no se ha visto. Las páginas están en blanco."
		"weapons": return "Nadie la ha empuñado todavía."
		"items": return "Nadie lo ha llevado todavía."
		"places": return "Ningún investigador ha estado allí."
	return "Aún no se ha unido a la expedición."

func _image(e: Dictionary) -> Texture2D:
	if e.icon != null: return e.icon
	if String(e.model) == "": return null
	var key := "%s:%s" % [e.model, e.mode]
	if not _icons.has(key):
		var fixed := 0.0
		if _tome == "enemies" and String(e.model) != "":   # a escala, salvo los colosos: a la suya
			fixed = maxf(_bestiary_scale(), ModelIcon.frame_size(String(e.model)) * ModelIcon.MARGIN)
		_icons[key] = ModelIcon.make(self, String(e.model), String(e.mode), IMAGE_PX, fixed)
	return _icons[key]

## Bestiario a escala: el encuadre lo marca el enemigo más grande.
var _scale := 0.0
## Encuadre común del bestiario: el de las criaturas de tamaño normal (percentil SCALE_PCT). Con
## el más grande, desde que hay colosos (Dagon, Cthulhu), todos los demás salían diminutos.
const SCALE_PCT := 0.8
func _bestiary_scale() -> float:
	if _scale <= 0.0:
		var sizes: Array[float] = []
		for e in _entries:
			if String(e.model) != "": sizes.append(ModelIcon.frame_size(String(e.model)))
		if sizes.is_empty(): return 0.0
		sizes.sort()
		_scale = sizes[mini(int(sizes.size() * SCALE_PCT), sizes.size() - 1)] * ModelIcon.MARGIN
	return _scale

func _rule() -> Control:
	var r := ColorRect.new()
	r.color = Color(INK, 0.35)
	r.custom_minimum_size = Vector2(0, 2)
	return r

func _hint(text: String) -> Label:
	var l := _ink(text, 19, Color(INK, 0.8))        # sobre el pergamino claro, INK_DIM no se leía
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

## Capturas: abre un tomo con el cursor en una entrada.
func open_at(tome: int, cursor := 0) -> void:
	_shelf_focus = tome
	_open_tome(tome)
	if cursor > 0 and cursor < _rows.size(): _rows[cursor].grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _sub != null or not event.is_action_pressed("ui_cancel"): return
	get_viewport().set_input_as_handled()
	if _tome != "":
		_show_shelf()
		return
	closed.emit()
	queue_free()
