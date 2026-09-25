class_name GameCamera
extends Camera3D
## Cámara ortográfica isométrica fija (X -30°, Y 45°) que sigue al centro de sus
## objetivos con suavizado. En cooperativo (fase 2) ajustará el zoom entre un mínimo
## y un máximo; en la fase 1 sigue al J1 con un tamaño fijo.

@export var view_size := 16.0      ## altura visible en metros (tamaño ortográfico)
@export var follow_speed := 6.0
@export var distance := 40.0

var targets: Array[Node3D] = []

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	rotation_degrees = Vector3(-30, 45, 0)
	size = view_size
	near = 0.5
	far = distance * 2.0 + 40.0
	snap()

func center() -> Vector3:
	if targets.is_empty(): return Vector3.ZERO
	var c := Vector3.ZERO
	for t in targets: c += t.global_position
	return c / targets.size()

func desired_position() -> Vector3:
	return center() + Vector3(0, 0.8, 0) + transform.basis.z * distance

func snap() -> void:
	position = desired_position()

func _process(delta: float) -> void:
	size = view_size
	position = position.lerp(desired_position(), 1.0 - exp(-follow_speed * delta))
