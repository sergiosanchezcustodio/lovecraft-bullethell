class_name GameCamera
extends Camera3D
## Cámara ortográfica isométrica fija (X -30°, Y 45°) que sigue al centro de sus
## objetivos con suavizado. En cooperativo (hito 2.9) abre el zoom para que quepan todos,
## entre `view_size` y `max_view_size`; más allá, la correa (leash) no deja que nadie se
## salga del encuadre.

@export var view_size := 16.0      ## altura visible en metros (tamaño ortográfico)
@export var follow_speed := 6.0
@export var distance := 40.0
@export var max_view_size := 24.0  ## tope del zoom en cooperativo
@export var margin := 2.6          ## m libres alrededor de los jugadores más alejados
@export var zoom_speed := 2.5

var targets: Array[Node3D] = []

func _ready() -> void:
	# La cámara se mueve en _process siguiendo la posición INTERPOLADA de sus objetivos
	# (interpolación de física): si siguiera la posición de física, que cambia a 60 Hz,
	# en monitores más rápidos todo vibraría.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	projection = Camera3D.PROJECTION_ORTHOGONAL
	rotation_degrees = Vector3(-30, 45, 0)
	size = view_size
	_size = view_size
	near = 0.5
	far = distance * 2.0 + 40.0
	snap()

var _size := 0.0

## En el suelo, eje de la pantalla hacia la derecha y hacia arriba (este último se ve a la
## mitad: la cámara mira 30° hacia abajo).
const SCREEN_Y_K := 0.5

static func ground_axes() -> Array[Vector3]:
	return [PlayerMotor.screen_to_world(Vector2(1, 0)), PlayerMotor.screen_to_world(Vector2(0, 1))]

func _aspect() -> float:
	var vs := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(16, 9)
	return vs.x / maxf(vs.y, 1.0)

## Tamaño (alto visible) que hace falta para que quepan todos los objetivos con margen.
func needed_size() -> float:
	if targets.size() < 2: return view_size
	var c := center()
	var ax := ground_axes()
	var mx := 0.0
	var my := 0.0
	for t in targets:
		var rel := t.get_global_transform_interpolated().origin - c
		mx = maxf(mx, absf(rel.dot(ax[0])))
		my = maxf(my, absf(rel.dot(ax[1])) * SCREEN_Y_K)
	var need_h := 2.0 * my + 2.0 * margin + 1.0          # +1: la cabeza por encima de los pies
	var need_w := 2.0 * mx + 2.0 * margin
	return clampf(maxf(need_h, need_w / _aspect()), view_size, max_view_size)

## Correa: devuelve `pos` recolocada dentro del encuadre máximo alrededor del centro.
func leash(pos: Vector3) -> Vector3:
	if targets.size() < 2: return pos
	var c := center()
	var ax := ground_axes()
	var rel := pos - c
	var half_h := max_view_size * 0.5 - margin * 0.6
	var half_w := half_h * _aspect()
	var u := clampf(rel.dot(ax[0]), -half_w, half_w)
	var v := clampf(rel.dot(ax[1]), -half_h / SCREEN_Y_K, half_h / SCREEN_Y_K)
	var out := c + ax[0] * u + ax[1] * v
	return Vector3(out.x, pos.y, out.z)

func center() -> Vector3:
	if targets.is_empty(): return Vector3.ZERO
	var c := Vector3.ZERO
	for t in targets: c += t.get_global_transform_interpolated().origin
	return c / targets.size()

func desired_position() -> Vector3:
	return center() + Vector3(0, 0.8, 0) + transform.basis.z * distance

func snap() -> void:
	position = desired_position()

var _shake := 0.0                  ## m de temblor (jefes: rugidos y golpes); se apaga solo

## Tiembla la cámara (hito 6.6): amount en metros; se suma y decae en unas décimas.
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _process(delta: float) -> void:
	_size = lerpf(_size, needed_size(), 1.0 - exp(-zoom_speed * delta))
	size = maxf(_size, view_size)
	position = position.lerp(desired_position(), 1.0 - exp(-follow_speed * delta))
	if _shake > 0.001:
		position += (transform.basis.x * randf_range(-1, 1) + transform.basis.y * randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, delta * maxf(_shake * 3.0, 0.2))
