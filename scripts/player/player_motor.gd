class_name PlayerMotor
extends RefCounted
## Lógica de movimiento y esquive de un jugador, sin nodos: recibe la entrada y el
## tiempo, y devuelve la velocidad deseada. El nodo Player la aplica con la física.

## Orientación de la cámara isométrica (grados en Y). Arriba en pantalla = alejarse de la cámara.
const CAMERA_YAW := 45.0

var data: CharacterData
var facing := Vector3(0, 0, 1)       ## hacia dónde mira el personaje (plano XZ, unitario)
var dodge_dir := Vector3.ZERO
var dodge_time := -1.0               ## tiempo desde el inicio del esquive (-1 = sin esquivar nunca)
var velocity := Vector3.ZERO
var locked := false                  ## sin control (p. ej. parálisis): no se mueve ni esquiva

func _init(p_data: CharacterData) -> void:
	data = p_data

## Convierte un vector de pantalla (x derecha, y arriba) en una dirección del suelo.
static func screen_to_world(v: Vector2, yaw_deg: float = CAMERA_YAW) -> Vector3:
	var yaw := deg_to_rad(yaw_deg)
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))   # hacia donde mira la cámara, sobre el suelo
	return right * v.x + forward * v.y

func is_dodging() -> bool:
	return dodge_time >= 0.0 and dodge_time < data.dodge_duration

func is_invulnerable() -> bool:
	return dodge_time >= 0.0 and dodge_time < data.dodge_iframes

func can_dodge() -> bool:
	return not locked and (dodge_time < 0.0 or dodge_time >= data.dodge_cooldown)

## Fracción de recarga del esquive (1 = listo), para el HUD.
func dodge_ready_fraction() -> float:
	if dodge_time < 0.0: return 1.0
	return clampf(dodge_time / data.dodge_cooldown, 0.0, 1.0)

## Avanza un paso. `move` es el vector de pantalla de la entrada; `dodge_pressed`,
## si se acaba de pulsar esquivar. Devuelve la velocidad a aplicar (m/s).
func step(delta: float, move: Vector2, dodge_pressed: bool) -> Vector3:
	if dodge_time >= 0.0: dodge_time += delta
	var dir := screen_to_world(move)
	if locked:
		velocity = Vector3.ZERO
		return velocity
	if dodge_pressed and can_dodge():
		dodge_dir = dir.normalized() if dir.length() > 0.1 else facing
		dodge_time = 0.0
	if is_dodging():
		# Frena de forma progresiva hasta la velocidad de andar: al acabar el esquive no hay
		# cambio brusco de velocidad.
		var u := dodge_time / data.dodge_duration
		velocity = dodge_dir * lerpf(data.dodge_speed, data.move_speed, u * u)
		facing = dodge_dir
	else:
		velocity = dir * data.move_speed
		if dir.length() > 0.1: facing = dir.normalized()
	return velocity
