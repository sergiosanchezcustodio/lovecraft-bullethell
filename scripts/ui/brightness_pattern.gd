class_name BrightnessPattern
extends Control
## Patrón de calibración del brillo (Configuración > Vídeo): dos ojos sobre negro, uno casi negro
## (debe verse apenas) y otro oscuro (debe verse bien). Se dibujan con la misma curva que
## Atmosphere.set_lift aplica a la partida con el brillo elegido.

const FAINT := 0.035        ## tono tras el tono de la escena (0..1): sombra profunda
const DARK := 0.11          ## sombra normal de un escenario de noche

func _init() -> void:
	custom_minimum_size = Vector2(0, 96)

func _draw() -> void:
	var g := Settings.brightness_gamma()
	var w := size.x
	draw_rect(Rect2(0, 0, w, size.y), Color.BLACK)
	for k in 2:
		var v := pow(FAINT if k == 0 else DARK, 1.0 / g)
		_eye(Vector2(w * (0.3 if k == 0 else 0.7), size.y * 0.5), Color(v, v, v))

## Ojo de Innsmouth: almendra con pupila de rendija.
func _eye(c: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * 46.0, sin(a) * 22.0 * (1.0 - 0.35 * absf(cos(a)))))
	draw_colored_polygon(pts, col)
	draw_rect(Rect2(c - Vector2(4, 18), Vector2(8, 36)), Color.BLACK)
