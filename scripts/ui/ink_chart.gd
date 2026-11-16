class_name InkChart
extends Control
## Gráficas en tinta para la Biblioteca (hito 21.20, estadísticas de la cuenta): barras
## horizontales con los bordes algo irregulares, como trazos de pluma, y una línea con un punto
## por partida. Al aparecer, la tinta corre: cada barra crece una detrás de otra y la línea se
## dibuja de izquierda a derecha.
##   bars:  rows = [{label, value, text}]  (text: lo que se lee al final de la barra)
##   line:  points = [[valor, marcado]]    (marcado: punto rojo, p. ej. nivel superado)

const INK := Color(0.2, 0.13, 0.08)
const INK_DIM := Color(0.42, 0.34, 0.25)
const RED_INK := Color(0.5, 0.12, 0.08)
const ROW_H := 40.0
const LABEL_W := 230.0
const TEXT_W := 150.0
const GROW := 0.7                                 ## s que tarda en crecer una barra
const STAGGER := 0.09                             ## s entre una barra y la siguiente
const LINE_H := 230.0
const FONT_SIZE := 19

var kind := "bars"
var rows: Array = []
var points: Array = []
var y_label := ""                                 ## en la línea: qué se mide (arriba a la izquierda)
var _t := 0.0
var _seed := 0

static func bars(list: Array, seed := 0) -> InkChart:
	var c := InkChart.new()
	c.kind = "bars"
	c.rows = list
	c._seed = seed
	c.custom_minimum_size = Vector2(0, ROW_H * maxi(list.size(), 1))
	return c

static func line(list: Array, label := "", seed := 0) -> InkChart:
	var c := InkChart.new()
	c.kind = "line"
	c.points = list
	c.y_label = label
	c._seed = seed
	c.custom_minimum_size = Vector2(0, LINE_H)
	return c

## Tiempo que tarda en dibujarse entera.
func duration() -> float:
	if kind == "line": return 0.4 + 0.06 * points.size()
	return GROW + STAGGER * maxi(rows.size() - 1, 0)

func finish() -> void:
	_t = duration()
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _t >= duration(): return
	_t += delta
	queue_redraw()

func _font() -> Font:
	return get_theme_default_font()

func _draw() -> void:
	if kind == "line": _draw_line()
	else: _draw_bars()

## Lo que ha crecido una barra (0..1) a los `_t` s.
func grown(i: int) -> float:
	var k := clampf((_t - STAGGER * i) / GROW, 0.0, 1.0)
	return 1.0 - pow(1.0 - k, 3.0)

func _draw_bars() -> void:
	var f := _font()
	var top := 0.0
	for r: Dictionary in rows: top = maxf(top, float(r.get("value", 0.0)))
	var span := size.x - LABEL_W - TEXT_W - 16.0
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y := i * ROW_H
		var mid := y + ROW_H * 0.5
		var lab := String(r.get("label", ""))
		draw_string(f, Vector2(0, mid + FONT_SIZE * 0.35), lab, HORIZONTAL_ALIGNMENT_LEFT, LABEL_W - 10.0, FONT_SIZE, INK)
		var k := grown(i)
		var w := span * (float(r.get("value", 0.0)) / maxf(top, 0.001)) * k
		_stroke(Vector2(LABEL_W, mid), w, 15.0, RED_INK if i == 0 else INK, _seed * 31 + i)
		if k > 0.6:
			var a := clampf((k - 0.6) / 0.4, 0.0, 1.0)
			draw_string(f, Vector2(LABEL_W + w + 10.0, mid + FONT_SIZE * 0.35), String(r.get("text", "")),
				HORIZONTAL_ALIGNMENT_LEFT, TEXT_W + span - w, FONT_SIZE - 1, Color(INK_DIM, a))

## Un trazo de pluma de `w` px de largo y `h` de grueso con los bordes temblorosos y una gota al final.
func _stroke(at: Vector2, w: float, h: float, col: Color, seed: int) -> void:
	if w < 1.0: return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := maxi(int(w / 9.0), 2)
	var up := PackedVector2Array()
	var down := PackedVector2Array()
	for j in n + 1:
		var x := at.x + w * j / n
		var thin := 1.0 - 0.18 * float(j) / n            # la pluma se va quedando sin tinta
		up.append(Vector2(x, at.y - h * 0.5 * thin + rng.randf_range(-1.2, 1.2)))
		down.append(Vector2(x, at.y + h * 0.5 * thin + rng.randf_range(-1.2, 1.2)))
	down.reverse()
	var poly := up + down
	draw_colored_polygon(poly, Color(col, 0.86))
	draw_circle(Vector2(at.x + w, at.y + 0.5), h * 0.46, Color(col, 0.9))     # la gota al levantar la pluma
	draw_circle(at + Vector2(1.5, 0), h * 0.5, Color(col, 0.9))

func _draw_line() -> void:
	var f := _font()
	var left := 44.0
	var bottom := size.y - 26.0
	var topy := 26.0
	draw_line(Vector2(left, bottom), Vector2(size.x, bottom), Color(INK, 0.5), 2.0)
	draw_line(Vector2(left, topy), Vector2(left, bottom), Color(INK, 0.5), 2.0)
	if y_label != "": draw_string(f, Vector2(left + 8.0, topy - 6.0), y_label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2, INK_DIM)
	if points.is_empty(): return
	var top := 1.0
	for p: Array in points: top = maxf(top, float(p[0]))
	top = ceilf(top / 5.0) * 5.0
	draw_string(f, Vector2(0, topy + 6.0), str(int(top)), HORIZONTAL_ALIGNMENT_RIGHT, left - 8.0, FONT_SIZE - 2, INK_DIM)
	draw_string(f, Vector2(0, bottom + 6.0), "0", HORIZONTAL_ALIGNMENT_RIGHT, left - 8.0, FONT_SIZE - 2, INK_DIM)
	var step := (size.x - left - 20.0) / maxf(points.size() - 1, 1)
	var pts := PackedVector2Array()
	for i in points.size():
		var v := float(points[i][0])
		pts.append(Vector2(left + 10.0 + step * i if points.size() > 1 else left + (size.x - left) * 0.5, bottom - (bottom - topy) * v / top))
	var shown := clampf((_t - 0.1) / maxf(duration() - 0.1, 0.01), 0.0, 1.0) * (pts.size() - 1)
	for i in pts.size() - 1:
		if i >= shown: break
		var b := pts[i].lerp(pts[i + 1], clampf(shown - i, 0.0, 1.0))
		draw_line(pts[i], b, Color(INK, 0.85), 3.0, true)
	for i in pts.size():
		if i > shown + 0.001: break
		var won: bool = points[i][1]
		draw_circle(pts[i], 6.0 if won else 4.5, RED_INK if won else INK)
