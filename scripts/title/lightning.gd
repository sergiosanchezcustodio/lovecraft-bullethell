class_name TitleLightning
extends Node3D
## Relámpagos de la portada, entre las montañas del fondo. Cada descarga es un rayo
## quebrado con alguna rama que dura un instante, con una réplica: nunca más de dos
## destellos seguidos, y entre descargas pasan varios segundos (sin destellos
## estroboscópicos; la intensidad se puede bajar o quitar con `strength`).
## Emite `flashed(intensity, world_position)` cada fotograma para que la escena
## ilumine el cielo, la niebla y el contraluz.

signal flashed(intensity: float, at: Vector3)

@export var min_interval := 5.5
@export var max_interval := 11.0
@export var strength := 1.0                 ## 0 = sin relámpagos (accesibilidad)
@export var area := Rect2(-170, -290, 340, 70)   ## x, z donde puede caer

var camera: Camera3D
var _next := 3.0
var _t := -1.0
var _at := Vector3.ZERO
var _bolt: MeshInstance3D
var _mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rng.randomize()
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = Color(0.85, 0.9, 1.0)
	_mat.emission_enabled = true
	_mat.emission = Color(0.75, 0.85, 1.0)
	_mat.emission_energy_multiplier = 6.0
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_bolt = MeshInstance3D.new()
	_bolt.material_override = _mat
	_bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bolt.visible = false
	add_child(_bolt)

## Fuerza una descarga ya (capturas y pruebas).
func strike_now() -> void:
	_next = 0.0

## Intensidad de una descarga en el instante t (s): subida brusca, caída, réplica y cola.
static func envelope(t: float) -> float:
	if t < 0.0: return 0.0
	if t < 0.03: return t / 0.03
	if t < 0.09: return lerpf(1.0, 0.25, (t - 0.03) / 0.06)
	if t < 0.13: return lerpf(0.25, 0.8, (t - 0.09) / 0.04)
	if t < 0.5: return 0.8 * pow(1.0 - (t - 0.13) / 0.37, 2.0)
	return 0.0

func _process(delta: float) -> void:
	if strength <= 0.0:
		flashed.emit(0.0, _at)
		return
	_next -= delta
	if _next <= 0.0 and _t < 0.0:
		_strike()
	var k := 0.0
	if _t >= 0.0:
		_t += delta
		k = envelope(_t)
		_bolt.visible = _t < 0.16 or (k > 0.3 and _t < 0.3)
		_mat.emission_energy_multiplier = 3.0 + 8.0 * k
		if _t > 0.5:
			_t = -1.0
			_bolt.visible = false
			_next = _rng.randf_range(min_interval, max_interval)
	flashed.emit(k * strength, _at)

func _strike() -> void:
	_t = 0.0
	var x := _rng.randf_range(area.position.x, area.end.x)
	var z := _rng.randf_range(area.position.y, area.end.y)
	var top := Vector3(x + _rng.randf_range(-20, 20), 210.0, z - 20.0)
	var bottom := Vector3(x, _rng.randf_range(55.0, 95.0), z)
	_at = bottom
	_bolt.mesh = _build_bolt(top, bottom)

## Rayo: línea quebrada del cielo a la montaña, con una o dos ramas, como tiras planas
## orientadas hacia la cámara.
func _build_bolt(a: Vector3, b: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var main := _jagged(a, b, 14, 9.0)
	_ribbon(st, main, 1.6)
	for k in _rng.randi_range(1, 2):
		var i := _rng.randi_range(3, main.size() - 5)
		var start := main[i]
		var dir := (b - a).normalized().rotated(Vector3.FORWARD, _rng.randf_range(-0.9, 0.9))
		var end := start + dir * _rng.randf_range(35.0, 60.0) + Vector3(_rng.randf_range(-20, 20), 0, 0)
		_ribbon(st, _jagged(start, end, 7, 6.0), 0.8)
	return st.commit()

func _jagged(a: Vector3, b: Vector3, n: int, amp: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t)
		if i > 0 and i < n:
			p += Vector3(_rng.randf_range(-amp, amp), _rng.randf_range(-amp * 0.3, amp * 0.3), _rng.randf_range(-amp * 0.5, amp * 0.5))
		pts.append(p)
	return pts

func _ribbon(st: SurfaceTool, pts: PackedVector3Array, width: float) -> void:
	var view := Vector3(0, 0, 1)
	if camera != null: view = (camera.global_position - pts[0]).normalized()
	for i in pts.size() - 1:
		var d := (pts[i + 1] - pts[i]).normalized()
		var side := d.cross(view).normalized() * width * 0.5
		var w := 1.0 - float(i) / pts.size() * 0.5
		var q := [pts[i] - side * w, pts[i] + side * w, pts[i + 1] + side * w, pts[i + 1] - side * w]
		for k in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(q[k])
