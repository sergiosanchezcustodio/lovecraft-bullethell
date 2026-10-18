class_name TitleDrips
extends ColorRect
## Gotas de la bóveda en la portada (18-10-2026): cada pocos segundos cae una gota al suelo
## mojado, salpica y abre anillos que deforman los reflejos de las velas (title_drips.gdshader).
## Suenan muy bajo (`drip`). Este nodo es el rectángulo del suelo (1920×1080).

const RECT := Rect2(600, 520, 1100, 560)       ## suelo mojado con los reflejos y el aire por donde caen
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
	material = m
	return self

## Deja caer una gota en `at` (o en un sitio al azar del suelo).
func drop(at := Vector2(-1, -1)) -> void:
	for i in N:
		if _d[i].w > 0.0: continue
		if at.x < 0.0:
			# más cerca (abajo), más grandes; el suelo se ve más estrecho al fondo
			var y := _rng.randf_range(818.0, 1060.0)
			var near := inverse_lerp(818.0, 1060.0, y)
			at = Vector2(_rng.randf_range(lerpf(760.0, 640.0, near), lerpf(1560.0, 1690.0, near)), y)
		var size := lerpf(0.7, 1.35, inverse_lerp(818.0, 1060.0, at.y))
		_d[i] = Vector4(at.x, at.y, -FALL, size)
		return

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
