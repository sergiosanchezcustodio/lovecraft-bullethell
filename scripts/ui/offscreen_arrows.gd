class_name OffscreenArrows
extends Control
## En red (hito 9.4b): cada PC tiene su cámara (D-10), así que los jugadores de otros PC
## pueden quedar fuera de la vista. Para cada uno, una flecha de su color en el borde de la
## pantalla que apunta hacia él, con "J2" y la distancia. Si está derribado, la flecha late
## (necesita que lo reanimen); los eliminados no la llevan.

var players: Array[Player] = []
var camera: Camera3D
var _t := 0.0

const EDGE := 56.0                           ## px desde el borde de la pantalla
const TOP_EDGE := 225.0                      ## arriba, por debajo de los paneles del HUD (y su fila del PC)
const SIZE := 22.0                           ## largo de la flecha
const FONT := 18

func setup(p_players: Array[Player], p_camera: Camera3D) -> OffscreenArrows:
	players = p_players
	camera = p_camera
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

## Dónde y hacia dónde va la flecha de un punto de la pantalla, o null si se ve. Pura (tests).
static func place(p: Vector2, view: Vector2, edge := EDGE, top := TOP_EDGE) -> Variant:
	var inner := Rect2(Vector2(edge, top), view - Vector2(edge * 2.0, top + edge))
	if Rect2(Vector2.ZERO, view).grow(-8.0).has_point(p): return null
	var c := inner.get_center()
	var d := p - c
	if d.length() < 0.001: return null
	# corta la recta del centro al jugador con el rectángulo interior
	var k := INF
	if absf(d.x) > 0.001: k = minf(k, (inner.size.x * 0.5) / absf(d.x))
	if absf(d.y) > 0.001: k = minf(k, (inner.size.y * 0.5) / absf(d.y))
	return [c + d * minf(k, 1.0), d.normalized()]

func _draw() -> void:
	if camera == null or not camera.is_inside_tree(): return
	var view := get_viewport_rect().size
	var font := get_theme_default_font()
	var me := Vector3.ZERO
	var mine := 0
	for q in players:
		if not q.remote and not q.is_eliminated:
			me += q.global_position
			mine += 1
	for q in players:
		if not q.remote or q.is_eliminated: continue
		var w := q.get_global_transform_interpolated().origin + Vector3(0, 0.9, 0)
		var at: Variant = place(camera.unproject_position(w), view)
		if at == null: continue
		var pos: Vector2 = at[0]
		var dir: Vector2 = at[1]
		var col := q.color
		if q.health <= 0.0: col.a = 0.45 + 0.55 * absf(sin(_t * 5.0))   # derribado: late
		var side := Vector2(-dir.y, dir.x)
		# larga y estrecha (con la anchura igual al largo, no se sabía hacia dónde apuntaba)
		var tip := pos + dir * SIZE * 0.7
		var back := pos - dir * SIZE * 0.3
		var pts := PackedVector2Array([tip, back + side * SIZE * 0.3, pos - dir * SIZE * 0.1, back - side * SIZE * 0.3])
		var shade := PackedVector2Array()
		for v in pts: shade.append(v + (v - pos).normalized() * 3.0)
		draw_colored_polygon(shade, Color(0, 0, 0, 0.7 * col.a))
		draw_colored_polygon(pts, col)
		var text := "J%d" % (q.index + 1)
		if mine > 0: text += " · %d m" % roundi((me / mine).distance_to(q.global_position))
		var tsz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT)
		var tp := pos - dir * (SIZE + tsz.length() * 0.45) - Vector2(tsz.x * 0.5, -FONT * 0.35)
		draw_string_outline(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT, 5, Color(0, 0, 0, 0.85 * col.a))
		draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT, Color(col, col.a))
