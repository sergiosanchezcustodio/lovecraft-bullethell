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
var _ear: AudioListener3D                  ## oído (16-10-2026): sobre el centro de la vista, para el lado de los sonidos
const EAR_BACK := 10.0                     ## m hacia la cámara: lo cercano suena casi al centro

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
	_ear = AudioListener3D.new()
	_ear.top_level = true
	add_child(_ear)
	_ear.make_current()

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
	return _framed_center() + Vector3(0, 0.8, 0) + transform.basis.z * distance

# ---------------------------------------------------------------- encuadre de un jefe

var _focus: Node3D = null
var _focus_left := 0.0                     ## s reales que le quedan
var _focus_w := 0.0                        ## 0: encuadre normal; 1: jugadores y jefe a la vez
var _focus_h := 2.0                        ## m de alto del jefe (Madre Hydra, Dagon: muchos)
const FOCUS_IN := 0.5                      ## s reales para ir y para volver
const FOCUS_MAX := 1.25                    ## el encuadre, hasta max_view_size por esto

## Encuadra a la vez a los jugadores y a `who` (de `height` m de alto) durante `secs` s de tiempo
## real (BossIntro).
func focus(who: Node3D, secs: float, height := 2.0) -> void:
	_focus = who
	_focus_left = secs
	_focus_h = maxf(height, 1.0)

## Centro de la vista: el de los jugadores o, encuadrando a un jefe, el punto medio con él.
func _framed_center() -> Vector3:
	var c := center()
	if _focus_w <= 0.0 or not is_instance_valid(_focus): return c
	var b := _focus.get_global_transform_interpolated().origin
	b += global_basis.y * (_focus_h * 0.25)              # un poco arriba: que quepa su cabeza
	return c.lerp((c + Vector3(b.x, c.y, b.z)) * 0.5, Anims.ease(_focus_w))

## Alto visible encuadrando a un jefe: el que hace falta para que quepan él y los jugadores.
func _framed_size(normal: float) -> float:
	if _focus_w <= 0.0 or not is_instance_valid(_focus): return normal
	var c := center()
	var rel := _focus.get_global_transform_interpolated().origin - c
	var ax := ground_axes()
	var need_h := absf(rel.dot(ax[1])) * SCREEN_Y_K + 2.0 * margin + _focus_h * 0.9   # y su altura
	var need_w := absf(rel.dot(ax[0])) + 2.0 * margin
	var s := clampf(maxf(need_h, need_w / _aspect()), normal, max_view_size * FOCUS_MAX)
	return lerpf(normal, s, Anims.ease(_focus_w))

func _focus_step(delta: float) -> float:
	var rd := delta / maxf(Engine.time_scale, 0.05)       # tiempo real: la cámara lenta no la frena
	_focus_left -= rd
	var on := _focus_left > 0.0 and is_instance_valid(_focus)
	_focus_w = move_toward(_focus_w, 1.0 if on else 0.0, rd / FOCUS_IN)
	if _focus_w <= 0.0: _focus = null
	return rd if _focus_w > 0.0 else delta

func snap() -> void:
	position = desired_position()

var _shake := 0.0                  ## m de temblor (jefes: rugidos y golpes); se apaga solo
var tilt := 0.0                    ## rad de giro alrededor de la vista (R'lyeh que se inclina, hito 12.13; Ambient)

## Tiembla la cámara (hito 6.6): amount en metros; se suma y decae en unas décimas.
const SHAKE_SCALE := 0.45                  ## los temblores, a menos de la mitad
const SHAKE_MAX := 0.12                    ## m: ninguno pasa de aquí
const SHAKE_FREQ := 22.0                   ## cambios de dirección por segundo (ruido suave)
const SHAKE_ROLL := 0.35                   ## rad de giro por metro de temblor (0,12 m: 2,4°)
var _shake_t := 0.0

func shake(amount: float) -> void:
	# a la mitad (12-10-2026: resultaba incómodo) y con techo; la configuración lo reduce o lo quita
	_shake = maxf(_shake, minf(amount * SHAKE_SCALE, SHAKE_MAX) * float(Auto.setting("shake", 1.0)))

func _process(delta: float) -> void:
	var fd := _focus_step(delta) if _focus != null else delta    # encuadrando a un jefe, en tiempo real
	_size = lerpf(_size, _framed_size(needed_size()), 1.0 - exp(-zoom_speed * fd))
	size = maxf(_size, view_size)
	position = position.lerp(desired_position(), 1.0 - exp(-follow_speed * fd))
	if _ear != null: _ear.global_transform = Transform3D(global_basis, center() + global_basis.z * EAR_BACK)
	if _shake > 0.001:
		# ruido suave (hito 11.2) en vez de un salto al azar en cada fotograma, que según la
		# frecuencia del monitor vibraba más o menos; y un giro mínimo alrededor de la vista
		_shake_t += delta * SHAKE_FREQ
		var n := Vector3(_noise(_shake_t, 0), _noise(_shake_t, 101), _noise(_shake_t, 211))
		position += (transform.basis.x * n.x + transform.basis.y * n.y) * _shake
		rotation.z = tilt + n.z * _shake * SHAKE_ROLL
		_shake = move_toward(_shake, 0.0, delta * maxf(_shake * 3.0, 0.2))
	elif rotation.z != tilt:
		rotation.z = tilt

## Ruido suave de -1 a 1 (valores al azar en los enteros, unidos con una curva).
static func _noise(t: float, seed: int) -> float:
	var i := floori(t)
	var f := t - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_rand(i + seed), _rand(i + 1 + seed), f)

static func _rand(i: int) -> float:
	return float(hash(i * 7919) & 0xffff) / 32767.5 - 1.0
