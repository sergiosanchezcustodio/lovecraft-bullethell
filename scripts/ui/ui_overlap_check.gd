extends Node
## Revisión de los menús (`ui_check=true`): busca textos que pisan los filetes de latón de las
## ventanas (MenuKit.dress), sus esquinas de filigrana o el borde de los recuadros de dentro
## (StyleBoxFlat con borde), y los apunta en la salida con «UICHK». Mira la pantalla cada
## segundo, así que sirve con cualquier menú que se abra solo (open=, sheet_at=, debug_menu=…).
## Lo añade MenuRepeat al arrancar; no hace nada sin la opción.
## Desde el 05-11-2026 mira también el contenido descentrado en su ventana: lo que se ve dentro
## del marco (textos, botones, imágenes, recuadros y lo que se dibuja a mano) deja a un lado
## bastante más hueco que al otro, o una fila ancha no deja el mismo hueco a cada lado.

const BAND := 20.0              ## px del borde de una ventana que ocupan el filete ancho, el fino (15-17) y un respiro
const BOX_GAP := 3.0            ## px de respiro dentro del borde de un recuadro
const CORNER_ALPHA := 0.3       ## opacidad de la filigrana a partir de la cual se ve pisada
const OFF_X := 22.0             ## px de diferencia entre el hueco izquierdo y el derecho del contenido
const OFF_Y := 40.0             ## y entre el de arriba y el de abajo (los títulos y botones lo igualan casi siempre)
const EDGE := 6.0               ## px de diferencia entre los huecos de una fila ancha a cada lado del marco
const WIDE := 0.6               ## parte del ancho de la ventana a partir de la cual una fila es «ancha»

var _seen := {}
var _t := 0.0
var _off_before := {}                       ## ventanas fuera de la pantalla en la revisión anterior
var _corner_img: Image

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_corner_img = MenuKit.CORNER.get_image()
	if _corner_img.is_compressed(): _corner_img.decompress()

func _process(delta: float) -> void:
	_t += delta
	if _t < 1.0: return
	_t = 0.0
	scan()

## Revisa lo que hay en pantalla y apunta lo nuevo. Devuelve los avisos de esta pasada.
func scan() -> Array:
	var labels: Array = []
	var frames: Array = []
	_collect(get_tree().root, labels, frames)
	var out: Array = []
	var screen := get_viewport().get_visible_rect()
	var off := {}
	for f: Array in frames:
		if f[1] != "marco": continue
		out.append(_centering(f[0]))
		var r: Rect2 = (f[0] as Control).get_global_rect()
		if not screen.grow(1.0).encloses(r):           # no cabe en la pantalla (interfaz grande, 16:10…)
			var key := "pantalla|%s" % (f[0] as Control).get_path()
			off[key] = true
			if _off_before.has(key) and not _seen.has(key):   # en dos revisiones seguidas: no a mitad de colocarse
				_seen[key] = true
				var line := "UICHK %s se sale de la pantalla (%.0f×%.0f en %.0f, %.0f; la pantalla, %.0f×%.0f)" % [_short(f[0]), r.size.x, r.size.y, r.position.x, r.position.y, screen.size.x, screen.size.y]
				print(line)
				out.append(line)
	_off_before = off
	for l: Control in labels:
		var box := _text_box(l)
		if box.size.x <= 1.0 or box.size.y <= 1.0: continue
		var clip := _clip_of(l)
		if clip.size.x > 0.0:
			box = box.intersection(clip)
			if box.size.x <= 1.0 or box.size.y <= 1.0: continue
		var group := _window_of(l)
		var best: Array = []             # [área, frame]: el más pequeño que la contiene casi entera
		for f: Array in frames:
			var fr: Control = f[0]
			if fr == l or not (group == null or group.is_ancestor_of(fr)): continue
			if _layer(fr) != _layer(l): continue                     # el marcador, detrás de una ventana
			if l.is_ancestor_of(fr) or fr.is_ancestor_of(l) == false and not _same_branch(fr, l, group): continue
			if _z(fr) != _z(l) and not fr.is_ancestor_of(l): continue   # a otra altura (burbujas de ayuda): uno tapa al otro
			var r := fr.get_global_rect()
			var inter := r.intersection(box)
			var share := inter.get_area() / maxf(box.get_area(), 1.0)
			if share >= 0.5:
				if best.is_empty() or r.get_area() < best[0]: best = [r.get_area(), f]
			elif share > 0.02 and fr.is_ancestor_of(l):
				out.append(_report(l, "se sale de", fr, -1.0))
		if best.is_empty(): continue
		var f: Array = best[1]
		var fr: Control = f[0]
		var r := fr.get_global_rect()
		var d := minf(minf(box.position.x - r.position.x, r.end.x - box.end.x), minf(box.position.y - r.position.y, r.end.y - box.end.y))
		d /= maxf(fr.get_global_transform().get_scale().x, 0.01)   # en px del marco: el filete escala con él
		var band: float = f[2]
		if d < band:
			out.append(_report(l, "pisa el borde de" if f[1] == "recuadro" else "pisa el filete de", fr, d))
		elif f[1] == "marco" and _on_corner(fr, box):
			out.append(_report(l, "pisa la esquina de", fr, d))
	return out.filter(func(x: String) -> bool: return x != "")

func _report(l: Control, what: String, fr: Control, d: float) -> String:
	var text := _text_of(l).replace("\n", " ").left(48)
	var key := "%s|%s|%s" % [text, what, fr.get_path()]
	if _seen.has(key): return ""
	_seen[key] = true
	var line := "UICHK «%s» %s %s%s  [%s]" % [text, what, _short(fr), (" (a %.0f px)" % d) if d >= 0.0 else "", _short(l)]
	print(line)
	return line

static func _short(n: Node) -> String:
	var p := str(n.get_path()).split("/")
	var keep: Array = []
	for i in range(p.size() - 1, -1, -1):
		keep.push_front(p[i])
		if keep.size() >= 4: break
	var s := "/".join(keep)
	if n.get_script() != null: s += " (%s)" % n.get_script().resource_path.get_file()
	elif n.get_parent() != null and n.get_parent().get_script() != null: s += " (en %s)" % n.get_parent().get_script().resource_path.get_file()
	return s

## Textos visibles y marcos (ventanas vestidas y recuadros con borde).
func _collect(n: Node, labels: Array, frames: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible: return
	if n is CanvasLayer and not (n as CanvasLayer).visible: return
	if n is Control:
		var c := n as Control
		if _alpha(c) > 0.3:
			if (c is Label or c is Button) and _text_of(c) != "": labels.append(c)
			if c.has_meta("gothic"): frames.append([c, "marco", BAND])
			elif c is Panel or c is PanelContainer:
				var sb := c.get_theme_stylebox("panel")
				var bw := _border(sb)
				if bw > 0.0: frames.append([c, "recuadro", bw + BOX_GAP])
	for k in n.get_children(): _collect(k, labels, frames)

static func _border(sb: StyleBox) -> float:
	if not sb is StyleBoxFlat: return 0.0
	var f := sb as StyleBoxFlat
	if f.border_color.a < 0.2: return 0.0
	return float(maxi(maxi(f.border_width_left, f.border_width_right), maxi(f.border_width_top, f.border_width_bottom)))

static func _z(c: CanvasItem) -> int:
	var z := 0
	var n: Node = c
	while n != null and n is CanvasItem:
		z += (n as CanvasItem).z_index
		if not (n as CanvasItem).z_as_relative: break
		n = n.get_parent()
	return z

static func _alpha(c: CanvasItem) -> float:
	var a := 1.0
	var n: Node = c
	while n != null and n is CanvasItem:
		a *= (n as CanvasItem).modulate.a
		n = n.get_parent()
	return a * c.self_modulate.a

static func _text_of(c: Control) -> String:
	var t := ""
	if c is Label: t = (c as Label).text
	elif c is Button: t = (c as Button).text
	return t.strip_edges()

## Caja aproximada de la tinta del texto, en coordenadas globales.
static func _text_box(c: Control) -> Rect2:
	var font: Font = c.get_theme_font("font")
	var fs: int = c.get_theme_font_size("font_size")
	var text := _text_of(c)
	var rect := Rect2(Vector2.ZERO, c.size)
	var halign := HORIZONTAL_ALIGNMENT_LEFT
	var valign := VERTICAL_ALIGNMENT_CENTER
	var w := 0.0
	var h := 0.0
	if c is Label:
		var l := c as Label
		if l.uppercase: text = text.to_upper()
		halign = l.horizontal_alignment
		valign = l.vertical_alignment
		var sb := l.get_theme_stylebox("normal")
		if sb != null:
			rect = rect.grow_individual(-sb.get_margin(SIDE_LEFT), -sb.get_margin(SIDE_TOP), -sb.get_margin(SIDE_RIGHT), -sb.get_margin(SIDE_BOTTOM))
		var lines := l.get_visible_line_count()
		var lh := font.get_height(fs) + l.get_theme_constant("line_spacing")
		h = lines * lh - l.get_theme_constant("line_spacing")
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			w = font.get_multiline_string_size(text, halign, rect.size.x, fs).x
		else:
			w = font.get_multiline_string_size(text, halign, -1, fs).x
		if l.clip_text: w = minf(w, rect.size.x)
	else:
		var b := c as Button
		halign = b.alignment
		var sb := b.get_theme_stylebox("normal")
		if sb != null:
			rect = rect.grow_individual(-sb.get_margin(SIDE_LEFT), -sb.get_margin(SIDE_TOP), -sb.get_margin(SIDE_RIGHT), -sb.get_margin(SIDE_BOTTOM))
		if b.autowrap_mode != TextServer.AUTOWRAP_OFF:
			var ms := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, fs)
			w = ms.x
			h = ms.y
		else:
			w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			h = font.get_height(fs)
		if b.icon != null:
			rect.position.x += b.icon.get_width() + b.get_theme_constant("h_separation")
			rect.size.x -= b.icon.get_width() + b.get_theme_constant("h_separation")
		if b.clip_text: w = minf(w, rect.size.x)
	var x := rect.position.x
	if halign == HORIZONTAL_ALIGNMENT_CENTER: x += (rect.size.x - w) * 0.5
	elif halign == HORIZONTAL_ALIGNMENT_RIGHT: x += rect.size.x - w
	var y := rect.position.y
	if valign == VERTICAL_ALIGNMENT_CENTER: y += (rect.size.y - h) * 0.5
	elif valign == VERTICAL_ALIGNMENT_BOTTOM: y += rect.size.y - h
	# la tinta: sin el hueco de encima de las mayúsculas ni todo el de los rasgos de abajo
	var asc := font.get_ascent(fs)
	var desc := font.get_descent(fs)
	var local := Rect2(x, y + asc * 0.12, w, maxf(h - asc * 0.12 - desc * 0.45, 1.0))
	var xf := c.get_global_transform()
	return Rect2(xf * local.position, xf.basis_xform(local.size))

## Lo que deja ver el ScrollContainer (o el control que recorta) más cercano, si lo hay.
static func _clip_of(c: Control) -> Rect2:
	var n := c.get_parent()
	while n != null:
		if n is ScrollContainer or (n is Control and (n as Control).clip_contents):
			return (n as Control).get_global_rect()
		n = n.get_parent()
	return Rect2()

## La ventana a la que pertenece: el control que lleva el velo de MenuKit.window, si lo hay.
static func _window_of(c: Control) -> Node:
	var n := c.get_parent()
	while n != null:
		if n.get_child_count() > 0 and n.get_child(0) is ColorRect:
			var m := (n.get_child(0) as ColorRect).material
			if m is ShaderMaterial and (m as ShaderMaterial).shader == MenuKit.DIM_SHADER: return n
		n = n.get_parent()
	return null

## Fuera de las ventanas con velo, un marco que no es antepasado del texto solo cuenta si
## comparten padre cercano (los textos colocados encima de un panel hermano, como en la selección).
static func _same_branch(fr: Node, l: Node, group: Node) -> bool:
	if group != null: return true
	var p := fr.get_parent()
	for i in 2:
		if p == null: return false
		if p.is_ancestor_of(l): return true
		p = p.get_parent()
	return false

func _on_corner(fr: Control, box: Rect2) -> bool:
	var g: Array = fr.get_meta("gothic", [])
	if g.size() < 2: return false
	var corners: Control = g[1]
	var iw := _corner_img.get_width()
	var ih := _corner_img.get_height()
	for c: TextureRect in corners.get_children():
		var r := c.get_global_rect()
		var inter := r.intersection(box)
		if inter.size.x <= 0.0 or inter.size.y <= 0.0: continue
		var step := 2.0
		var y := inter.position.y
		while y < inter.end.y:
			var x := inter.position.x
			while x < inter.end.x:
				var u := (x - r.position.x) / r.size.x
				var v := (y - r.position.y) / r.size.y
				if c.flip_h: u = 1.0 - u
				if c.flip_v: v = 1.0 - v
				var px := clampi(int(u * iw), 0, iw - 1)
				var py := clampi(int(v * ih), 0, ih - 1)
				if _corner_img.get_pixel(px, py).a > CORNER_ALPHA: return true
				x += step
			y += step
	return false

## Contenido de una ventana vestida: si deja mucho más hueco a un lado que al otro, lo apunta.
func _centering(fr: Control) -> String:
	if fr.get_child_count() < 2: return ""
	var g: Array = fr.get_meta("gothic", [])
	var skip: Array = [fr.get_child(0)]                  # la madera
	if g.size() >= 2: skip.append(g[1])                   # las esquinas
	var area := Rect2()
	for k in fr.get_children():
		if k in skip or not k is Control: continue
		area = _content_of(k as Control, area)
	if area.size.x <= 1.0: return ""
	var r := fr.get_global_rect()
	var s := maxf(fr.get_global_transform().get_scale().x, 0.01)
	var lft := (area.position.x - r.position.x) / s
	var rgt := (r.end.x - area.end.x) / s
	var top := (area.position.y - r.position.y) / s
	var bot := (r.end.y - area.end.y) / s
	var what := ""
	if absf(lft - rgt) > OFF_X: what = "descentrado a lo ancho (hueco: izq. %.0f, der. %.0f px)" % [lft, rgt]
	elif absf(top - bot) > OFF_Y: what = "descentrado a lo alto (hueco: arriba %.0f, abajo %.0f px)" % [top, bot]
	if what == "": what = _wide_rows(fr, skip, r, s)
	if what == "": return ""
	var key := "centro|%s|%s" % [fr.get_path(), what.get_slice(" (", 0)]
	if _seen.has(key): return ""
	_seen[key] = true
	var line := "UICHK %s %s" % [_short(fr), what]
	print(line)
	return line

## Lo que se ve dentro de `c` (textos, botones, imágenes, recuadros), unido a `acc`.
func _content_of(c: Control, acc: Rect2) -> Rect2:
	if not c.visible or _alpha(c) < 0.3: return acc
	var add := Rect2()
	if (c is Label or c is Button) and _text_of(c) != "": add = _text_box(c)
	if c is Button and not (c as Button).flat: add = c.get_global_rect()
	elif c is TextureRect and (c as TextureRect).texture != null: add = c.get_global_rect()
	elif (c is Panel or c is PanelContainer) and _visible_box(c.get_theme_stylebox("panel")): add = c.get_global_rect()
	elif c is ScrollContainer or c is ItemList or c is TextEdit or c is LineEdit or c is Range: add = c.get_global_rect()
	elif not c.get_signal_connection_list(&"draw").is_empty() or (c.get_script() != null and c.has_method("_draw")):
		add = c.get_global_rect()                       # lo que se dibuja a mano (la gráfica del informe)
	if add.size.x > 0.0:
		var clip := _clip_of(c)
		if clip.size.x > 0.0: add = add.intersection(clip)
		if add.size.x > 0.0: acc = add if acc.size.x <= 0.0 else acc.merge(add)
	if c is ScrollContainer: return acc                # lo de dentro puede estar desplazado
	for k in c.get_children():
		if k is Control: acc = _content_of(k as Control, acc)
	return acc

static func _visible_box(sb: StyleBox) -> bool:
	if not sb is StyleBoxFlat: return sb is StyleBoxTexture
	var f := sb as StyleBoxFlat
	return f.bg_color.a > 0.15 or (f.border_color.a > 0.2 and f.border_width_left > 0)

## Filas anchas (botones, recuadros, imágenes, listas de más del WIDE del ancho) que dejan más
## hueco a un lado del marco que al otro: la primera que se encuentre, y cuántas son.
func _wide_rows(fr: Control, skip: Array, r: Rect2, s: float) -> String:
	var rows: Array = []
	for k in fr.get_children():
		if k in skip or not k is Control: continue
		_wide_of(k as Control, r, rows)
	var bad: Array = []
	for c: Control in rows:
		var g := c.get_global_rect()
		var lft := (g.position.x - r.position.x) / s
		var rgt := (r.end.x - g.end.x) / s
		if absf(lft - rgt) > EDGE: bad.append([c, lft, rgt])
	if bad.is_empty(): return ""
	return "con filas desplazadas: %d de %d (la primera, %s: izq. %.0f, der. %.0f px)" % [bad.size(), rows.size(), _short(bad[0][0]), bad[0][1], bad[0][2]]

func _wide_of(c: Control, r: Rect2, rows: Array) -> void:
	if not c.visible or _alpha(c) < 0.3: return
	var clip := _clip_of(c)
	var g := c.get_global_rect()
	if clip.size.x > 0.0 and clip.intersection(g).size.y < g.size.y * 0.5: return   # fuera de la vista
	var drawn := (c is Button and not (c as Button).flat) or (c is TextureRect and (c as TextureRect).texture != null) 		or ((c is Panel or c is PanelContainer) and _visible_box(c.get_theme_stylebox("panel"))) 		or (c is ColorRect and (c as ColorRect).color.a > 0.3)
	if drawn and g.size.x >= r.size.x * WIDE:
		rows.append(c)
		return                                         # lo de dentro va con él
	for k in c.get_children():
		if k is Control: _wide_of(k as Control, r, rows)

## La capa de dibujo (CanvasLayer) en la que está `n`; 0 si ninguna.
static func _layer(n: Node) -> int:
	var p := n
	while p != null:
		if p is CanvasLayer: return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0
