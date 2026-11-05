class_name GroundTraces
extends Node
## Rastros que se quedan (hito 17.20): cada mancha que pasa a GroundMarks (la salpicadura de una
## muerte, el icor, la ceniza, lo quemado de una explosión) deja además su huella, más tenue, en
## una textura que cubre la arena (`PX_PER_M` píxeles por metro) y que leen los suelos
## (ground_traces.gdshaderinc). La mancha se desvanece como antes; el rastro se queda el resto del
## nivel. El tope es la propia textura: memoria fija, y lo que cae encima tapa lo de debajo hasta
## `MAX_A`. La sube a la GPU como mucho cada `UPLOAD_EVERY` s. `traces` en data/quality.json.

const PX_PER_M := 8.0
const MAX_A := 0.62                             ## lo más que tapa el suelo
const UPLOAD_EVERY := 0.3
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

## Deja en el suelo, en `pos`, un rastro de `r` m del color `col` y opacidad `a`, de borde irregular.
func stamp(pos: Vector3, r: float, col: Color, a: float) -> void:
	var n := img.get_width()
	var k := n / extent
	var cx := (pos.x - origin.x) * k
	var cy := (pos.z - origin.y) * k
	var rp := maxf(r * k, 1.5)
	if cx < -rp * 2.0 or cy < -rp * 2.0 or cx > n + rp * 2.0 or cy > n + rp * 2.0: return
	# la mancha, de borde irregular (ocho lóbulos al azar), y unas gotas alrededor
	var lobes: Array[float] = []
	for i in 8: lobes.append(randf_range(0.6, 1.0))
	_blob(cx, cy, rp, lobes, col, a)
	for i in randi_range(2, 4):
		var ang := randf() * TAU
		var dist := rp * randf_range(1.15, 1.7)
		_blob(cx + cos(ang) * dist, cy + sin(ang) * dist, maxf(rp * randf_range(0.15, 0.3), 0.6), [1.0], col, a * 0.85)
	stamps += 1
	_dirty = true

func _blob(cx: float, cy: float, rp: float, lobes: Array, col: Color, a: float) -> void:
	var n := img.get_width()
	var nl := lobes.size()
	for y in range(maxi(int(cy - rp - 1), 0), mini(int(cy + rp + 2), n)):
		for x in range(maxi(int(cx - rp - 1), 0), mini(int(cx + rp + 2), n)):
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy)
			var u := fposmod(atan2(d.y, d.x) / TAU * nl, float(nl))
			var i0 := int(u) % nl
			var edge := rp * lerpf(float(lobes[i0]), float(lobes[(i0 + 1) % nl]), u - floorf(u))
			if d.length() > edge: continue
			var f := a * (0.8 + 0.2 * (1.0 - d.length() / maxf(edge, 0.01)))
			var old := img.get_pixel(x, y)
			var na := minf(old.a + f * (1.0 - old.a), MAX_A)
			var c := old.lerp(col, f / maxf(na, 0.001)) if old.a > 0.0 else col
			img.set_pixel(x, y, Color(c.r, c.g, c.b, na))

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
