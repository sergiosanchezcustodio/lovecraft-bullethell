class_name TitleMoths
extends Node2D
## Polillas de la portada (18-10-2026): dos o tres dan vueltas erráticas alrededor de la llama de
## la vela grande del escritorio, aleteando deprisa; se iluminan al pasar cerca de la llama y se
## apagan al pasar por detrás. La vela, a la izquierda, proyecta su sombra agrandada y borrosa
## sobre el pergamino. Coordenadas de la ilustración (1920×1080).

const FLAME := Vector2(226, 693)              ## llama de la vela grande
const PAPER := Rect2(330, 852, 330, 62)       ## pergamino donde caen las sombras
const DESK_Y := 884.0                          ## altura media del papel

var count := 3
var gust := 0.0                                ## la ráfaga las aparta de la llama (TitleGust)
var _m: Array[Dictionary] = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _shadow: Texture2D

func _init(n := 3) -> void:
	count = n
	_rng.randomize()

func _ready() -> void:
	for i in count:
		_m.append({"a": _rng.randf() * TAU, "w": _rng.randf_range(1.6, 2.8) * (1.0 if _rng.randf() < 0.6 else -1.0),
			"r": _rng.randf_range(16.0, 34.0), "ry": _rng.randf_range(0.35, 0.7), "seed": _rng.randf() * 100.0,
			"flap": _rng.randf_range(26.0, 34.0), "size": _rng.randf_range(1.5, 2.1), "pos": FLAME})
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0, 0, 0, 1), Color(0, 0, 0, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5); tex.fill_to = Vector2(1, 0.5)
	tex.width = 32; tex.height = 32
	_shadow = tex

func _process(delta: float) -> void:
	_t += delta
	for m in _m:
		var s: float = m.seed
		m.a += delta * m.w * (1.0 + 0.6 * sin(_t * 0.9 + s))                      # cambia de ritmo
		var r: float = m.r * (1.0 + 0.35 * sin(_t * 1.3 + s * 2.0)) + gust * 70.0
		var jitter := Vector2(sin(_t * 7.1 + s), cos(_t * 6.3 + s * 1.7)) * 3.0     # vuelo nervioso
		var target := FLAME + Vector2(cos(m.a) * r, sin(m.a) * r * m.ry - 6.0 + 9.0 * sin(_t * 0.7 + s)) + jitter
		target += Vector2(gust * 60.0, -gust * 15.0)
		m.pos = (m.pos as Vector2).lerp(target, minf(1.0, delta * 10.0))
	queue_redraw()

func _draw() -> void:
	# sombras primero (sobre el papel), luego las polillas
	for m in _m:
		var p: Vector2 = m.pos
		var off := p - FLAME
		# la llama está a la izquierda y algo por encima: la sombra cae a la derecha, agrandada
		var sh := Vector2(FLAME.x + 150.0 + off.x * 5.0, DESK_Y + off.y * 1.6)
		var k := 1.6 + absf(off.x) * 0.05
		if not PAPER.has_point(sh): continue
		var flap := absf(sin(_t * float(m.flap) + float(m.seed)))
		var w := (5.0 + 7.0 * flap) * k * float(m.size)
		draw_texture_rect(_shadow, Rect2(sh - Vector2(w, w * 0.45), Vector2(w * 2.0, w * 0.9)), false, Color(0, 0, 0, 0.32))
	for m in _m:
		var p: Vector2 = m.pos
		var off := p - FLAME
		var behind := sin(float(m.a)) < -0.25                    # pasa por detrás de la llama
		var near := 1.0 - clampf(off.length() / 70.0, 0.0, 1.0)
		var lit := Color(0.95, 0.78, 0.55).lerp(Color(0.28, 0.22, 0.18), 1.0 - near)
		lit.a = 0.45 if behind else 1.0
		var flap := sin(_t * float(m.flap) + float(m.seed))
		var sz: float = m.size
		var wing := (2.2 + 2.0 * absf(flap)) * sz
		var dir := 1.0 if cos(float(m.a)) * float(m.w) < 0.0 else -1.0
		# dos pares de alas triangulares que se abren y cierran, cuerpo alargado
		for sgn in [-1.0, 1.0]:
			var tip := p + Vector2(dir * -1.2 * sz, sgn * wing)
			draw_colored_polygon(PackedVector2Array([p + Vector2(dir * 1.6 * sz, 0), tip, p + Vector2(dir * -2.4 * sz, sgn * 0.6)]), lit)
		draw_line(p - Vector2(dir * 2.2 * sz, 0), p + Vector2(dir * 2.0 * sz, 0), lit.darkened(0.35), 1.2 * sz)
