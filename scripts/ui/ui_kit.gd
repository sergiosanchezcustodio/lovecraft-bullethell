class_name UiKit
extends RefCounted
## Estilo común de la interfaz: paneles oscuros translúcidos, texto color hueso y acentos
## del color del jugador. Las barras de vida y cordura usan los colores del lenguaje de
## daños (rojo = físico, violeta = mental).

const TEXT := Color(0.9, 0.86, 0.78)
const TEXT_DIM := Color(0.62, 0.6, 0.56)
const PANEL := Color(0.03, 0.035, 0.05, 0.62)
const HEALTH := Color(0.86, 0.22, 0.18)
const SANITY := Color(0.62, 0.36, 0.98)
const XP := Color(0.35, 0.95, 0.9)
const GOLD := Color(1.0, 0.82, 0.3)

static func panel(color: Color = PANEL, border: Color = Color(0, 0, 0, 0), radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(2)
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	return sb

static func label(text: String, size: int = 18, color: Color = TEXT, outline: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.02))
		l.add_theme_constant_override("outline_size", maxi(2, size / 6))
	return l

static func button(text: String, accent: Color = GOLD, size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", panel(Color(0.06, 0.065, 0.085, 0.9), Color(accent, 0.35)))
	b.add_theme_stylebox_override("hover", panel(Color(0.1, 0.1, 0.13, 0.95), accent))
	b.add_theme_stylebox_override("focus", panel(Color(0.1, 0.1, 0.13, 0.95), accent))
	b.add_theme_stylebox_override("pressed", panel(Color(0.14, 0.13, 0.1, 0.95), accent))
	return b

## Barra de progreso sencilla: fondo, relleno y una estela clara que baja con retraso
## (se ve cuánto se acaba de perder).
class Bar extends Control:
	var fill_color := Color.RED
	var value := 1.0          ## 0..1
	var _shown := 1.0
	var _ghost := 1.0
	func _init(c: Color, w: float, h: float) -> void:
		fill_color = c
		custom_minimum_size = Vector2(w, h)
	func _process(delta: float) -> void:
		_shown = lerpf(_shown, value, 1.0 - exp(-18.0 * delta))
		_ghost = value if value > _ghost else lerpf(_ghost, value, 1.0 - exp(-3.0 * delta))
		queue_redraw()
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.0, 0.0, 0.0, 0.55))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(_ghost, 0, 1), size.y)), Color(1, 1, 1, 0.35))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(_shown, 0, 1), size.y)), fill_color)
		draw_rect(r, Color(0, 0, 0, 0.8), false, 1.0)
