class_name TitleDrips
extends ColorRect
## Gotas de la bóveda en la portada (18-10-2026): cada pocos segundos cae una gota al suelo
## mojado, salpica y abre anillos que deforman los reflejos de las velas (title_drips.gdshader).
## Suenan muy bajo (`drip`). Este nodo es el rectángulo del suelo (1920×1080).
## Solo caen en el suelo de piedra (FLOOR, revisado a mano sobre la ilustración: entre el
## escritorio de la izquierda y el mueble de la derecha), y los anillos no pasan de ahí: se
## cortan al llegar a los muebles (28-10-2026; antes caían también sobre el escritorio).

const RECT := Rect2(600, 520, 1100, 560)       ## suelo mojado con los reflejos y el aire por donde caen
const FLOOR := [Vector2(805, 826), Vector2(1370, 826), Vector2(1352, 1060), Vector2(890, 1060),
	Vector2(872, 950), Vector2(845, 905)]       ## suelo a la vista (px de 1920×1080)
const MARGIN := 22.0                           ## px que deja hasta el borde del suelo
const N := 6
const FALL := 0.35

var every_min := 2.5
var every_max := 6.0
var sound := true
var _d: Array[Vector4] = []
var _next := 1.5
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()
	position = RECT.position
	size = RECT.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in N: _d.append(Vector4.ZERO)

func setup(art: Texture2D) -> TitleDrips:
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/title/title_drips.gdshader")
	m.set_shader_parameter("art", art)
	m.set_shader_parameter("rect", Vector4(RECT.position.x, RECT.position.y, RECT.size.x, RECT.size.y))
	m.set_shader_parameter("fall_time", FALL)
	m.set_shader_parameter("floor_poly", PackedVector2Array(FLOOR))
	material = m
	return self

## Deja caer una gota en `at` (o en un sitio al azar del suelo).
func drop(at := Vector2(-1, -1)) -> void:
	for i in N:
		if _d[i].w > 0.0: continue
		if at.x < 0.0: at = random_spot()
		var size := lerpf(0.7, 1.35, inverse_lerp(818.0, 1060.0, at.y))
		_d[i] = Vector4(at.x, at.y, -FALL, size)
		return

## Un sitio al azar del suelo, lejos de sus bordes.
func random_spot() -> Vector2:
	var poly := PackedVector2Array(FLOOR)
	var box := Rect2(poly[0], Vector2.ZERO)
	for v in poly: box = box.expand(v)
	for tries in 200:
		var p := Vector2(_rng.randf_range(box.position.x, box.end.x), _rng.randf_range(box.position.y, box.end.y))
		if on_floor(p): return p
	return box.get_center()

## Si `p` está en el suelo con su margen (a los lados y por delante; los anillos se ven aplastados).
static func on_floor(p: Vector2) -> bool:
	var poly := PackedVector2Array(FLOOR)
	for o in [Vector2.ZERO, Vector2(MARGIN, 0), Vector2(-MARGIN, 0), Vector2(0, MARGIN * 0.4), Vector2(0, -MARGIN * 0.4)]:
		if not Geometry2D.is_point_in_polygon(p + o, poly): return false
	return true

func _process(delta: float) -> void:
	_next -= delta
	if _next <= 0.0:
		drop()
		_next = _rng.randf_range(every_min, every_max)
	for i in N:
		var d := _d[i]
		if d.w <= 0.0: continue
		var was := d.z
		d.z += delta
		if was < 0.0 and d.z >= 0.0 and sound:
			var sfx := get_node_or_null("/root/Sfx")
			if sfx: sfx.call("play", "drip", -12.0 + 4.0 * d.w)
		if d.z > 2.6: d = Vector4.ZERO
		_d[i] = d
	(material as ShaderMaterial).set_shader_parameter("drips", PackedVector4Array(_d))
