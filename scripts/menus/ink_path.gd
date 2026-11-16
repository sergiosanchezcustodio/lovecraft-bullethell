class_name InkPath
extends Control
## El camino de una parte en el mapa de niveles (hito 21.18): una línea de tinta a la izquierda de
## los niveles que los une hasta el último abierto, un punto por nivel y, en los superados, un sello
## de lacre. Lo nuevo desde la última vez que se miró el mapa se dibuja delante del jugador: la
## tinta avanza tramo a tramo y los sellos se estampan (`SaveData.records["map_ink"]`, `Seen`).
## Se pone encima de la lista de niveles (`rows`), en el mismo contenedor, sin coger el ratón.

const X := -15.0                                  ## del borde izquierdo de las filas (el margen las aparta)
const INK := Color(0.78, 0.62, 0.38, 0.85)        ## tinta sepia: el panel es oscuro
const INK_OFF := Color(0.78, 0.62, 0.38, 0.22)
const WAX := Color(0.56, 0.08, 0.07)
const WAX_DARK := Color(0.33, 0.04, 0.04)
const WAX_LIT := Color(0.80, 0.24, 0.18)
const SEG_TIME := 0.45                            ## s por tramo nuevo
const STAMP_TIME := 0.28

var rows: Control                                  ## la lista de niveles (sus hijos, en orden)
var open: Array[bool] = []                         ## por nivel: abierto
var won: Array[bool] = []                          ## por nivel: superado
var ink_from := 0.0                                ## tramos ya vistos (la tinta empieza aquí)
var ink := 0.0                                     ## tramos dibujados ahora (0..n-1, con fracción)
var stamps: Array[float] = []                      ## por nivel: 0 sin sello, 1 estampado del todo
var new_seals: Array[int] = []
var _seed := 0

## `seen_open` y `seen_won`: lo que ya estaba la última vez (se dibuja sin animar).
func setup(list: Control, opened: Array[bool], beaten: Array[bool], seen_open: Array[bool], seen_won: Array[bool], seed := 0) -> void:
	rows = list
	open = opened
	won = beaten
	_seed = seed
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var last := _last_open(open)
	var seen_last := mini(_last_open(seen_open), last)
	ink_from = maxf(float(seen_last), 0.0)
	ink = ink_from
	stamps.clear()
	new_seals.clear()
	for i in won.size():
		var was := i < seen_won.size() and seen_won[i]
		stamps.append(1.0 if won[i] and was else 0.0)
		if won[i] and not was: new_seals.append(i)
	list.resized.connect(queue_redraw)
	list.sort_children.connect(queue_redraw)

## Anima lo nuevo: primero la tinta, luego los sellos. `instant`: todo de golpe (capturas, pruebas).
func play(instant := false) -> void:
	var last := float(maxi(_last_open(open), 0))
	if instant:
		ink = last
		for i in new_seals: stamps[i] = 1.0
		queue_redraw()
		return
	var tw := create_tween()
	tw.tween_interval(0.35)                        # que se vea la ventana antes
	for i in new_seals:                            # el sello del nivel recién superado, antes que el camino nuevo
		if float(i) <= ink_from: _stamp(tw, i)
	if last > ink_from:
		tw.tween_method(func(v: float) -> void:
			ink = v
			queue_redraw(), ink_from, last, SEG_TIME * (last - ink_from)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in new_seals:
		if float(i) > ink_from: _stamp(tw, i)

func _stamp(tw: Tween, i: int) -> void:
	tw.tween_callback(func() -> void: Auto.sfx("seal"))
	tw.tween_method(func(v: float) -> void:
		stamps[i] = v
		queue_redraw(), 0.0, 1.0, STAMP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.08)

static func _last_open(a: Array[bool]) -> int:
	var last := -1
	for i in a.size(): if a[i]: last = i
	return last

## Centro del punto del nivel `i`, en coordenadas de este nodo.
func point(i: int) -> Vector2:
	if rows == null or i >= rows.get_child_count(): return Vector2.ZERO
	var c := rows.get_child(i) as Control
	var r := Rect2(c.global_position - global_position, c.size)
	return Vector2(r.position.x + X, r.get_center().y)

func _draw() -> void:
	if rows == null: return
	var n := mini(rows.get_child_count(), open.size())
	if n == 0: return
	var pts: Array[Vector2] = []
	for i in n: pts.append(point(i))
	for i in n - 1:                                # tramos: los cerrados, a puntos tenues; los abiertos, con tinta hasta `ink`
		var a := pts[i]
		var b := pts[i + 1]
		if not open[i + 1]:
			_dotted(a, b)
			continue
		var f := clampf(ink - float(i), 0.0, 1.0)
		if f > 0.0: _stroke(a, a.lerp(b, f), i)
	for i in n:
		if stamps[i] > 0.0: _seal(pts[i], stamps[i], i)
		elif open[i]: _dot(pts[i], float(i) <= ink + 0.001)
		else: draw_arc(pts[i], 3.5, 0.0, TAU, 12, INK_OFF, 1.5, true)

## Trazo de pluma: algo ondulado y más grueso en el medio, siempre igual para el mismo tramo.
func _stroke(a: Vector2, b: Vector2, k: int) -> void:
	var len := a.distance_to(b)
	if len < 0.5: return
	var steps := maxi(int(len / 4.0), 2)
	var line := PackedVector2Array()
	var side := Vector2(1, 0)
	for s in steps + 1:
		var t := float(s) / float(steps)
		var p := a.lerp(b, t)
		var w := sin(float(s) * 0.45 + float(k * 7 + _seed) * 1.3) * 0.55 + sin(float(s) * 0.17 + float(k)) * 0.7
		line.append(p + side * w)
	draw_polyline(line, INK, 2.6, true)
	draw_polyline(line, Color(INK, 0.25), 4.5, true)   # la tinta que se corre un poco

func _dotted(a: Vector2, b: Vector2) -> void:
	var len := a.distance_to(b)
	var d := 0.0
	while d < len:
		draw_circle(a.lerp(b, d / len), 1.2, INK_OFF)
		d += 7.0

func _dot(p: Vector2, inked: bool) -> void:
	draw_circle(p, 5.0, INK if inked else INK_OFF)
	draw_circle(p, 2.2, Color(0.1, 0.07, 0.05))

## Sello de lacre: un charco de borde irregular, el anillo del cuño y el signo en relieve.
## `k` 0..1 al estamparse: llega grande y transparente y se asienta.
func _seal(p: Vector2, k: float, i: int) -> void:
	var s := lerpf(2.0, 1.0, clampf(k, 0.0, 1.0))
	var a := clampf(k * 1.6, 0.0, 1.0)
	var r := 11.0 * s
	var blob := PackedVector2Array()
	for j in 20:
		var ang := TAU * float(j) / 20.0
		var rr := r * (1.0 + 0.1 * sin(float(j) * 2.3 + float(i) * 1.7) + 0.06 * sin(float(j) * 5.1 + float(i)))
		blob.append(p + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(blob, Color(WAX_DARK, a))
	draw_circle(p + Vector2(-0.6, -0.8) * s, r * 0.82, Color(WAX, a))
	draw_arc(p, r * 0.62, 0.0, TAU, 24, Color(WAX_DARK, a), 1.4 * s, true)
	var star := PackedVector2Array()                # el signo: una estrella de cinco puntas
	for j in 6:
		var ang := -PI / 2.0 + TAU * float(j * 2 % 5) / 5.0
		star.append(p + Vector2(cos(ang), sin(ang)) * r * 0.42)
	draw_polyline(star, Color(WAX_DARK, a), 1.3 * s, true)
	draw_arc(p + Vector2(-1.5, -1.5) * s, r * 0.72, PI * 1.05, PI * 1.55, 8, Color(WAX_LIT, a * 0.8), 1.6 * s, true)   # brillo arriba a la izquierda

## Lo visto del mapa (para no repetir la animación): {"open": [ids], "won": [ids]}.
class Seen:
	static func get_seen(save: SaveData) -> Dictionary:
		var d: Variant = save.records.get("map_ink", {}) if save != null else {}
		if not d is Dictionary: d = {}
		return {"open": Array((d as Dictionary).get("open", [])), "won": Array((d as Dictionary).get("won", []))}

	static func mark(save: SaveData, opened: Array, beaten: Array) -> bool:
		if save == null: return false
		var d := {"open": opened.duplicate(), "won": beaten.duplicate()}
		var changed: bool = save.records.get("map_ink", {}) != d
		save.records["map_ink"] = d
		return changed
