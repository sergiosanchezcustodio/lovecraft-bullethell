class_name GroundTraces
extends Node
## Rastros que se quedan (hito 17.20): cada mancha que pasa a GroundMarks (la salpicadura de una
## muerte, el icor, la ceniza, lo quemado de una explosión) deja además su huella, más tenue, en
## una textura que cubre la arena (`PX_PER_M` píxeles por metro) y que leen los suelos
## (ground_traces.gdshaderinc). La mancha se desvanece como antes; el rastro se queda el resto del
## nivel. El tope es la propia textura: memoria fija, y lo que cae encima tapa lo de debajo hasta
## `MAX_A` (lo pone el sombreador). La sube a la GPU como mucho cada `UPLOAD_EVERY` s. `traces` en data/quality.json.

const PX_PER_M := 8.0
const MAX_A := 0.62                             ## lo más que tapa el suelo
const UPLOAD_EVERY := 2.0
static var current: GroundTraces                ## el de la arena en juego (null: sin rastros)

var img: Image
var tex: ImageTexture
var origin := Vector2.ZERO
var extent := 0.0
var _dirty := false
var _t := 0.0
var stamps := 0                                 ## (pruebas)

## Rastros para el suelo con material `mat` que cubre `bounds` (m).
static func make(mat: ShaderMaterial, bounds: Rect2) -> GroundTraces:
	var g := GroundTraces.new()
	g.name = "GroundTraces"
	var side := maxf(bounds.size.x, bounds.size.y)
	g.origin = bounds.position
	g.extent = side
	var px := clampi(int(side * PX_PER_M), 64, 1024)
	g.img = Image.create(px, px, false, Image.FORMAT_RGBA8)
	g.img.fill(Color(0, 0, 0, 0))
	g.tex = ImageTexture.create_from_image(g.img)
	if mat != null:
		mat.set_shader_parameter("trace_tex", g.tex)
		mat.set_shader_parameter("trace_origin", g.origin)
		mat.set_shader_parameter("trace_extent", g.extent)
	return g

func _enter_tree() -> void:
	current = self

func _exit_tree() -> void:
	if current == self: current = null

## Deja en el suelo, en `pos`, un rastro de `r` m del color `col` y opacidad `a`: una mancha de
## borde irregular y unas gotas alrededor. Se estampa con pinceles ya hechos (`_brush`, por
## tamaño, forma y color) y `blend_rect`, que es nativo: pintarlos píxel a píxel costaba en las
## hordas. El tope de opacidad lo pone el sombreador (TRACE_MAX).
func stamp(pos: Vector3, r: float, col: Color, a: float) -> void:
	var n := img.get_width()
	var k := n / extent
	var cx := (pos.x - origin.x) * k
	var cy := (pos.z - origin.y) * k
	var rp := clampi(int(round(r * k)), 2, 28)
	if cx < -rp * 2 or cy < -rp * 2 or cx > n + rp * 2 or cy > n + rp * 2: return
	_put(_brush(rp, randi() % SHAPES, col, a), cx, cy)
	for i in randi_range(2, 4):
		var ang := randf() * TAU
		var dist := rp * randf_range(1.15, 1.7)
		_put(_brush(clampi(int(round(rp * randf_range(0.15, 0.3))), 1, 6), SHAPES, col, a * 0.85), cx + cos(ang) * dist, cy + sin(ang) * dist)
	stamps += 1
	_dirty = true

func _put(b: Image, cx: float, cy: float) -> void:
	img.blend_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(int(cx) - b.get_width() / 2, int(cy) - b.get_height() / 2))

const SHAPES := 4                               ## formas de mancha (la SHAPES, redonda: las gotas)
static var _brushes := {}
static func _brush(rp: int, shape: int, col: Color, a: float) -> Image:
	var key := "%d|%d|%s|%d" % [rp, shape, col.to_html(false).left(6), int(a * 20.0)]
	if _brushes.has(key): return _brushes[key]
	if _brushes.size() > 400: _brushes.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = shape * 7919 + rp
	var lobes: Array[float] = []
	for i in 8: lobes.append(1.0 if shape >= SHAPES else rng.randf_range(0.6, 1.0))
	var side := rp * 2 + 2
	var b := Image.create(side, side, false, Image.FORMAT_RGBA8)
	b.fill(Color(col.r, col.g, col.b, 0.0))
	var c := side * 0.5
	for y in side:
		for x in side:
			var d := Vector2(x + 0.5 - c, y + 0.5 - c)
			var u := fposmod(atan2(d.y, d.x) / TAU * 8.0, 8.0)
			var i0 := int(u) % 8
			var edge := rp * lerpf(lobes[i0], lobes[(i0 + 1) % 8], u - floorf(u))
			if d.length() > edge: continue
			b.set_pixel(x, y, Color(col.r, col.g, col.b, a * (0.8 + 0.2 * (1.0 - d.length() / maxf(edge, 0.01)))))
	_brushes[key] = b
	return b

func _process(delta: float) -> void:
	_t -= delta
	if _dirty and _t <= 0.0:
		_t = UPLOAD_EVERY
		_dirty = false
		tex.update(img)

## Lo que deja una mancha de GroundMarks: su color según el tipo (ground_fx.gdshader, `mode`).
static func from_mark(mark: MeshInstance3D) -> void:
	if current == null or not is_instance_valid(current) or mark == null: return
	var m := mark.material_override as ShaderMaterial
	if m == null: return
	var mode := int(m.get_shader_parameter("mode"))
	var r := mark.global_basis.get_scale().x * 0.9
	match mode:
		2:                                                               # quemado de una explosión
			current.stamp(mark.global_position, r, Color(0.05, 0.045, 0.04), 0.5)
		6, 10:                                                           # salpicadura, icor, limo, ceniza
			var t: Color = m.get_shader_parameter("tint")
			current.stamp(mark.global_position, r, Color(t.r, t.g, t.b), 0.5)
