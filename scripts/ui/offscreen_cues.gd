class_name OffscreenCues
extends Control
## Avisos de lo que llega de fuera de cámara (hito 13.13): cuando aparece una élite o un enemigo
## avisa un ataque fuerte (un aviso relleno de `MIN_RADIUS` m o más) donde no se ve, suena por su
## lado (izquierda o derecha: `cue_elite` o `cue_attack`, a `SIDE` m del centro de la vista) y
## una marca late un momento en el borde de la pantalla, en la dirección de donde viene. Con tope
## (`MAX_MARKS` a la vez y `GAP` s entre dos del mismo tipo). «Avisos de lo que llega de fuera de
## la pantalla» en Configuración > Audio. Cada PC los suyos (en los invitados, las marionetas y
## los avisos repetidos también llaman).

const MIN_RADIUS := 1.8
const LIFE := 1.6                            ## s que dura la marca
const MAX_MARKS := 4
const GAP := {"elite": 2.5, "attack": 0.8}
const SIDE := 12.0                           ## m a un lado del centro: se oye claramente por ese lado
const COLORS := {"attack": Color(1.0, 0.42, 0.22)}

var camera: GameCamera
var _marks: Array[Dictionary] = []          ## {pos (mundo), kind, t}
var _last := {}                             ## tipo -> ms del último

func setup(p_camera: GameCamera) -> OffscreenCues:
	camera = p_camera
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self

func _ready() -> void:
	Enemy.on_appear = func(e: Enemy) -> void: _enemy.call_deferred(e)
	Telegraph.on_warning = func(t: Telegraph) -> void: _warning.call_deferred(t)

func _exit_tree() -> void:
	Enemy.on_appear = Callable()
	Telegraph.on_warning = Callable()

func _enemy(e: Enemy) -> void:
	if is_instance_valid(e) and e.data != null and e.data.elite and not e.data.unique: cue("elite", e.global_position)

func _warning(t: Telegraph) -> void:
	if is_instance_valid(t) and t.fill and t.radius >= MIN_RADIUS: cue("attack", t.global_position)

## Avisa de algo en `pos` si no se ve. Devuelve si ha avisado (tests).
func cue(kind: String, pos: Vector3) -> bool:
	if not bool(Auto.setting("offscreen_cues", true)) or camera == null or not camera.is_inside_tree(): return false
	if camera.is_position_in_frustum(pos) or camera.is_position_in_frustum(pos + Vector3(0, 1.5, 0)): return false
	var now := Time.get_ticks_msec()
	if now - int(_last.get(kind, -100000)) < int(float(GAP[kind]) * 1000.0): return false
	_last[kind] = now
	if _marks.size() >= MAX_MARKS: _marks.pop_front()
	_marks.append({"pos": pos, "kind": kind, "t": 0.0})
	var right := GameCamera.ground_axes()[0]
	var side := signf((pos - camera.center()).dot(right))
	Auto.sfx_at("cue_" + kind, camera.center() + right * side * SIDE)
	return true

func _process(delta: float) -> void:
	if _marks.is_empty(): return
	for m in _marks: m.t += delta
	_marks = _marks.filter(func(m: Dictionary) -> bool: return m.t < LIFE)
	queue_redraw()

func _draw() -> void:
	if camera == null: return
	var view := get_viewport_rect().size
	for m in _marks:
		var at: Variant = OffscreenArrows.place(camera.unproject_position(m.pos), view, OffscreenArrows.EDGE, OffscreenArrows.TOP_EDGE)
		if at == null: continue
		var p: Vector2 = at[0]
		var dir: Vector2 = at[1]
		var k: float = m.t / LIFE
		var a := clampf(k / 0.1, 0.0, 1.0) * clampf((1.0 - k) / 0.35, 0.0, 1.0)
		var pulse := 1.0 + 0.25 * sin(m.t * 14.0)
		var col: Color = COLORS.get(m.kind, Color.from_hsv(Enemy.part_tint.h, 0.6, 1.0))   # la élite, del color de la parte, viva
		var perp := Vector2(-dir.y, dir.x)
		# un disco oscuro con un aro del color del aviso y, por fuera, la punta hacia donde está
		draw_circle(p, 30.0 * pulse, Color(0.02, 0.02, 0.04, 0.5 * a))      # fondo oscuro: se ve también sobre la nieve
		draw_circle(p, 22.0 * pulse, Color(col, 0.35 * a))
		draw_arc(p, 30.0 * pulse, 0.0, TAU, 40, Color(col, 0.95 * a), 4.0, true)
		var base := p + dir * 34.0 * pulse
		draw_colored_polygon(PackedVector2Array([base + dir * 20.0, base + perp * 13.0, base - perp * 13.0]), Color(col, 0.95 * a))
		draw_string(get_theme_default_font(), p + Vector2(-6, 9), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.95 * a))
