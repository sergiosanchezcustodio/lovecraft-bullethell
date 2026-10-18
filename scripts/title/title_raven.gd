class_name TitleRaven
extends TextureRect
## Cuervo de la portada (17-10-2026; animación rehecha el 18-10-2026): entra planeando desde el
## balcón de la izquierda con rachas de aleteo, se endereza para frenar con aletazos grandes, las
## patas por delante y la cola abierta, y se posa en la calavera del escritorio con las alas en
## alto antes de plegarlas. Posado mira a golpes de cabeza, la ladea, cambia el peso de pata, a
## veces da un saltito para girarse, se ahueca y grazna inclinándose. Al rato se va (se agacha y
## salta batiendo) y vuelve más tarde; al pulsar un botón (scare) sale volando asustado.
## Es el modelo voxel `cuervo_portada` (tools/gen_cuervo_portada.py), con alas articuladas en la
## muñeca, patas y cola propias, renderizado en su propio SubViewport con la luz de la escena
## (vela cálida a la izquierda, contraluz azul del ventanal y luz fría de arriba) y movido en 2D
## sobre la ilustración, dentro del escenario que se acerca.

const MODEL := "cuervo_portada"
const VIEW_PX := 768                         ## resolución del render
const VIEW_M := 0.95                         ## metros que caben en el render (cámara ortográfica)
const SIZE := 400.0                          ## tamaño en pantalla (px de 1920×1080) del render
const PERCH := Vector2(330, 770)             ## patas sobre la calavera (escenario de 1920×1080)
const FOOT := Vector2(0.465, 0.823)            ## dónde caen las patas dentro del render (fracción)
const START := Vector2(-160, 330)            ## de dónde llega: el balcón de la izquierda
const FLY_IN := 3.6                          ## s de vuelo hasta posarse
const FLY_OUT := 2.4
const CAM_Y := 0.3                           ## altura a la que mira la cámara (centro del cuerpo)
const CAM_PITCH := 22.0                      ## grados: la ilustración se ve algo desde arriba
const PERCH_YAW := 52.0                      ## de tres cuartos, mirando a la sala
const FOLD_T := 0.4                          ## s que tarda en plegar las alas al posarse

enum State { AWAY, IN, PERCHED, OUT }

var state := State.AWAY
var st := 0.0                                ## tiempo en el estado
var wait := 0.0                              ## cuándo llega o se va
var _vp: SubViewport
var _model: Node3D
var _pivot: Node3D                           ## giro y posición del modelo (la raíz la reinicia Anims)
var _parts := {}
var _rim: DirectionalLight3D
var _moon: DirectionalLight3D
var _rng := RandomNumberGenerator.new()
var _leave_dir := Vector2(1, -1)
var _out_from := Vector2.ZERO
var _yaw := PERCH_YAW                        ## orientación posado (cambia con los saltitos)
var _look := 0.0; var _look_to := 0.0; var _look_t := 0.0
var _tilt := 0.0; var _tilt_to := 0.0
var _caw_t := -10.0; var _next_caw := 6.0
var _ruffle_t := -10.0; var _next_ruffle := 9.0
var _hop_t := -10.0; var _next_hop := 12.0; var _hop_from := 0.0; var _hop_to := 0.0
var _shift := 0.0; var _shift_to := 0.0; var _shift_t := 2.0      ## peso sobre una pata u otra
var _lift_t := -10.0; var _lift_side := 1.0; var _next_lift := 7.0  ## levanta una pata un momento

func _init(first_arrival := 4.0) -> void:
	wait = first_arrival
	_rng.randomize()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	size = Vector2(SIZE, SIZE)
	_vp = SubViewport.new()
	_vp.size = Vector2i(VIEW_PX, VIEW_PX)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.24, 0.42)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.3
	var we := WorldEnvironment.new(); we.environment = env; _vp.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = VIEW_M
	_vp.add_child(cam)
	var a := deg_to_rad(CAM_PITCH)
	cam.look_at_from_position(Vector3(0, CAM_Y + 3.0 * sin(a), 3.0 * cos(a)), Vector3(0, CAM_Y, 0))
	var candle := OmniLight3D.new()                 # la vela grande, a la izquierda y algo delante
	candle.light_color = Color(1.0, 0.7, 0.45)
	candle.light_energy = 0.6
	candle.omni_range = 6.0
	candle.position = Vector3(-1.6, 0.9, 1.0)
	_vp.add_child(candle)
	var rim := DirectionalLight3D.new()            # contraluz azul del ventanal
	_rim = rim
	rim.light_color = Color(0.45, 0.6, 1.0)
	rim.light_energy = 1.0
	rim.rotation_degrees = Vector3(-20, 150, 0)
	_vp.add_child(rim)
	var moon := DirectionalLight3D.new()           # luz fría de arriba: saca el brillo azulado del plumaje
	_moon = moon
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 0.32
	moon.rotation_degrees = Vector3(-60, 20, 0)
	_vp.add_child(moon)
	_pivot = Node3D.new()
	_vp.add_child(_pivot)
	_model = VoxelBuilder.load_model("res://models/%s.json" % MODEL)
	_pivot.add_child(_model)
	for n in ["body", "head", "jaw", "tail", "leg_l", "leg_r", "arm_l", "arm_r", "hand_l", "hand_r", "fold_l", "fold_r"]:
		_parts[n] = Anims.part(_model, n)
	texture = _vp.get_texture()
	visible = false
	if wait < 0.0: _go(State.PERCHED, true)        # raven=-1: ya posado (capturas)

## Al pulsar: si está posado, sale volando asustado (y grazna).
func scare() -> void:
	if state == State.PERCHED:
		_caw()
		_leave()

func _process(delta: float) -> void:
	st += delta
	# en vuelo, el contraluz y la luz de arriba dan de lleno en las alas abiertas y su reflejo
	# las volvía azul claro: se atenúan hasta que las pliega
	var open := state == State.IN or state == State.OUT or (state == State.PERCHED and st < FOLD_T)
	_rim.light_energy = lerpf(_rim.light_energy, 0.35 if open else 1.0, minf(1.0, delta * 6.0))
	_moon.light_energy = lerpf(_moon.light_energy, 0.12 if open else 0.32, minf(1.0, delta * 6.0))
	match state:
		State.AWAY:
			if st >= wait: _go(State.IN)
		State.IN: _fly_in()
		State.PERCHED: _perched(delta)
		State.OUT: _fly_out()

func _go(s: State, settled := false) -> void:
	state = s
	st = FOLD_T + 0.5 if settled else 0.0
	visible = s != State.AWAY
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	if s == State.PERCHED:
		wait = _rng.randf_range(22.0, 40.0) + st     # cuánto se queda
		_next_caw = _rng.randf_range(3.0, 7.0)
		_yaw = PERCH_YAW
	elif s == State.AWAY:
		wait = _rng.randf_range(18.0, 34.0)        # cuánto tarda en volver

func _leave() -> void:
	_out_from = PERCH
	_leave_dir = Vector2(-1.0, -0.75).normalized() if _rng.randf() < 0.5 else Vector2(0.55, -1.0).normalized()
	_go(State.OUT)

## Coloca el render para que las patas caigan en `p` (coordenadas del escenario), a escala `k`.
func _place(p: Vector2, k: float) -> void:
	scale = Vector2.ONE * k
	position = p - FOOT * SIZE * k

static func _bezier(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var s := 1.0 - t
	return a * s * s * s + b * 3.0 * s * s * t + c * 3.0 * s * t * t + d * t * t * t

# ------------------------------------------------------------------ piezas

func _p(n: String) -> Node3D:
	return _parts[n] as Node3D

func _reset() -> void:
	for n in _parts:
		_p(n).rotation = Vector3.ZERO
		_p(n).scale = Vector3.ONE
	_pivot.position = Vector3.ZERO
	_show_folded(false)

func _show_folded(on: bool) -> void:
	for n in ["arm_l", "arm_r"]: _p(n).visible = not on      # la mano cuelga del brazo
	for n in ["fold_l", "fold_r"]: _p(n).visible = on

## Ala abierta derecha y su espejo. `up`: sube el brazo desde el hombro; `hand`: dobla la muñeca
## (negativo: la punta cae); `sweep`: lleva la mano hacia atrás; `back`: lleva el brazo hacia
## atrás; `twist`: baja el borde de ataque (al batir hacia abajo el ala se tuerce y empuja).
func _wing(up: float, hand: float, sweep: float, back := 0.0, twist := 0.0) -> void:
	for side in [-1.0, 1.0]:
		var arm := _p("arm_l" if side < 0.0 else "arm_r")
		var hd := _p("hand_l" if side < 0.0 else "hand_r")
		arm.rotation = Vector3(twist, side * back, side * up)
		hd.rotation = Vector3(twist * 0.6, side * sweep, side * hand)

## Un aleteo de verdad (fase 0..1): la bajada, más larga, con el ala extendida y torcida; la
## subida con la muñeca doblada y la mano recogida hacia atrás, la punta rezagada. El cuerpo
## sube con cada golpe. `power` (0..1) agranda el gesto (frenada, despegue).
func _flap(p: float, power := 0.6) -> void:
	var w := TAU * p
	var up := 0.2 + (0.75 + 0.35 * power) * cos(w)
	var rising := maxf(0.0, -sin(w))                    # 1 a mitad de la subida
	var hand := 0.12 * cos(w - 0.9) - 0.55 * rising
	var sweep := 0.18 + 0.85 * rising
	_wing(up, hand, sweep, 0.15 * rising, 0.3 * sin(w))
	_pivot.position.y += 0.012 * (1.0 + power) * sin(w)

## Planeo: alas algo levantadas, la mano un poco atrás, con un temblor de las puntas.
func _glide(time: float) -> void:
	_wing(0.14 + 0.03 * sin(time * 9.0), -0.06 + 0.04 * sin(time * 13.0), 0.32, 0.0, 0.05)

## Patas: positivo las lleva atrás (recogidas en vuelo), negativo adelante (a por la percha).
func _legs(rot_l: float, rot_r: float) -> void:
	_p("leg_l").rotation.x = rot_l
	_p("leg_r").rotation.x = rot_r

# ------------------------------------------------------------------ vuelo

func _fly_in() -> void:
	var u := clampf(st / FLY_IN, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - u, 2.0)                 # frena al llegar
	var c1 := Vector2(40, 380); var c2 := Vector2(200, 650)
	var p := _bezier(START, c1, c2, PERCH, e)
	var ahead := _bezier(START, c1, c2, PERCH, minf(e + 0.02, 1.0))
	_place(p, lerpf(0.55, 1.0, e))                   # se acerca: crece
	_reset()
	var brake := smoothstep(0.7, 1.0, u)
	var dir := ahead - p
	var side := 1.0 if dir.x >= 0.0 else -1.0
	var slope := clampf(dir.y / maxf(absf(dir.x), 0.001), -1.2, 1.2)
	# de perfil hacia donde va; al frenar se endereza (morro arriba) y gira hacia la sala
	var yaw := side * deg_to_rad(lerpf(82.0, PERCH_YAW + 6.0, brake))
	_pivot.rotation = Vector3(slope * 0.3 * (1.0 - brake) - 0.95 * brake * (1.0 - smoothstep(0.93, 1.0, u)), yaw, 0.0)
	# rachas de aleteo con planeos entre medias; al frenar, aletazos grandes y rápidos
	var flapping := u < 0.28 or (u > 0.45 and u < 0.6) or u > 0.7
	if flapping:
		_flap(fmod(st * lerpf(2.8, 4.0, brake), 1.0), lerpf(0.5, 1.0, brake))
	else:
		_glide(st)
	# patas recogidas atrás; al frenar se adelantan a por la calavera
	var leg := lerpf(1.25, -0.55, smoothstep(0.72, 0.95, u))
	_legs(leg, leg + 0.08)
	# cola: plegada en vuelo; al frenar baja y se abre en abanico
	_p("tail").rotation.x = lerpf(0.05, -0.45, brake)
	_p("tail").scale = Vector3(lerpf(1.0, 1.5, brake), 1.0, 1.0)
	_p("head").rotation.x = lerpf(-0.15, 0.5, brake)   # la cabeza sigue mirando al frente al enderezarse
	if u >= 1.0: _go(State.PERCHED)

func _fly_out() -> void:
	_reset()
	var crouch_t := 0.18
	if st < crouch_t:                                 # se agacha y abre las alas en alto
		_place(_out_from, 1.0)
		var k := st / crouch_t
		_pivot.rotation = Vector3(0.25 * k, deg_to_rad(_yaw), 0.0)
		_pivot.position.y = -0.03 * k
		_wing(lerpf(0.4, 1.3, k), 0.4, lerpf(1.6, 0.6, k), lerpf(1.0, 0.0, k))
		_legs(-0.3 * k, -0.3 * k)
		_p("tail").rotation.x = 0.25 * k
		return
	var u := clampf((st - crouch_t) / FLY_OUT, 0.0, 1.0)
	var d := _leave_dir * (u * u * 1500.0 + u * 220.0) + Vector2(0, -50.0 * smoothstep(0.0, 0.15, u))
	_place(_out_from + d, lerpf(1.0, 0.6, u))
	var side := 1.0 if _leave_dir.x >= 0.0 else -1.0
	_pivot.rotation = Vector3(-0.5 * (1.0 - u) - 0.2, side * deg_to_rad(lerpf(_yaw, 82.0, smoothstep(0.0, 0.3, u))), 0.0)
	_flap(fmod((st - crouch_t) * 4.2, 1.0), lerpf(1.0, 0.6, u))
	var leg := lerpf(-0.2, 1.25, smoothstep(0.05, 0.35, u))   # cuelgan al saltar y se recogen
	_legs(leg, leg + 0.1)
	_p("tail").rotation.x = lerpf(-0.3, 0.05, u)
	if u >= 1.0: _go(State.AWAY)

# ------------------------------------------------------------------ posado

func _perched(delta: float) -> void:
	_place(PERCH, 1.0)
	_reset()
	var head := _p("head")
	# al tocar la percha: se agacha con el golpe, las alas en alto y luego las pliega hacia abajo
	var land := clampf(st / FOLD_T, 0.0, 1.0)
	var bounce := sin(clampf(st / 0.35, 0.0, 1.0) * PI) * (1.0 - land * 0.5)
	if land < 1.0:
		var k := smoothstep(0.0, 1.0, land)
		var flick := sin(st * 26.0) * (1.0 - k) * 0.15        # últimos aleteos cortos
		_wing(lerpf(1.25, -0.2, k) + flick, lerpf(0.5, -0.4, k), lerpf(0.4, 1.7, k), lerpf(0.0, 1.0, k), 0.0)
		if land > 0.6: _show_folded(true)
	else:
		_show_folded(true)
	# peso: el cuerpo se balancea de una pata a otra; a veces levanta una y la vuelve a posar
	_shift_t -= delta
	if _shift_t <= 0.0:
		_shift_to = _rng.randf_range(-1.0, 1.0)
		_shift_t = _rng.randf_range(1.5, 4.0)
	_shift = lerpf(_shift, _shift_to, minf(1.0, delta * 2.5))
	var leg_l := -0.08 + 0.06 * _shift
	var leg_r := -0.08 - 0.06 * _shift
	_next_lift -= delta
	if _next_lift <= 0.0 and land >= 1.0:
		_lift_t = 0.0
		_lift_side = 1.0 if _rng.randf() < 0.5 else -1.0
		_next_lift = _rng.randf_range(8.0, 16.0)
	var lift := 0.0
	if _lift_t >= 0.0:
		_lift_t += delta
		lift = sin(clampf(_lift_t / 0.5, 0.0, 1.0) * PI)
		if _lift_t > 0.5: _lift_t = -10.0
	if _lift_side > 0.0: leg_r -= 0.5 * lift
	else: leg_l -= 0.5 * lift
	_legs(leg_l, leg_r)
	# saltito para girarse: se agacha, salta un palmo y cae mirando a otro lado
	_next_hop -= delta
	if _next_hop <= 0.0 and land >= 1.0 and _caw_t < 0.0:
		_hop_t = 0.0
		_hop_from = _yaw
		_hop_to = clampf(_yaw + _rng.randf_range(-35.0, 35.0), 20.0, 80.0)
		_next_hop = _rng.randf_range(12.0, 24.0)
	var hop_y := 0.0; var hop_crouch := 0.0
	if _hop_t >= 0.0:
		_hop_t += delta
		var q := clampf(_hop_t / 0.42, 0.0, 1.0)
		hop_crouch = sin(clampf(q / 0.25, 0.0, 1.0) * PI) * 0.6 + sin(clampf((q - 0.8) / 0.2, 0.0, 1.0) * PI) * 0.5
		var air := clampf((q - 0.2) / 0.6, 0.0, 1.0)
		hop_y = sin(air * PI) * 0.035
		_yaw = lerpf(_hop_from, _hop_to, smoothstep(0.0, 1.0, air))
		if air > 0.0 and air < 1.0:
			_show_folded(false)                          # abre un poco las alas para equilibrarse
			_wing(0.5 * sin(air * PI), -0.2, 1.4, 1.0)
			_legs(0.5 * sin(air * PI), 0.5 * sin(air * PI))
		if q >= 1.0: _hop_t = -10.0
	var crouch := bounce * 0.8 + hop_crouch
	_pivot.position.y += -0.018 * crouch + hop_y
	_pivot.rotation = Vector3(0.12 * crouch, deg_to_rad(_yaw), 0.035 * _shift)
	# mira a un lado y a otro a golpes de cabeza (los pájaros no giran despacio)
	_look_t -= delta
	if _look_t <= 0.0:
		_look_to = _rng.randf_range(-1.1, 0.9)
		_tilt_to = _rng.randf_range(-0.35, 0.35) if _rng.randf() < 0.4 else 0.0
		_look_t = _rng.randf_range(0.6, 2.4)
	_look = lerpf(_look, _look_to, minf(1.0, delta * 18.0))
	_tilt = lerpf(_tilt, _tilt_to, minf(1.0, delta * 10.0))
	head.rotation = Vector3(0.0, _look, _tilt)
	# respira; la cola acompaña
	var breath := sin(st * 2.4)
	_p("body").scale = Vector3.ONE * (1.0 + 0.012 * breath)
	_p("tail").rotation.x = 0.03 * breath - 0.05 * _shift * 0.0
	# se ahueca: las plumas se erizan, sacude las alas y la cola
	_next_ruffle -= delta
	if _next_ruffle <= 0.0 and land >= 1.0:
		_ruffle_t = 0.0
		_next_ruffle = _rng.randf_range(9.0, 16.0)
	if _ruffle_t >= 0.0:
		_ruffle_t += delta
		var k := sin(clampf(_ruffle_t / 0.6, 0.0, 1.0) * PI)
		_p("body").scale = Vector3(1.0 + 0.08 * k, 1.0 + 0.05 * k, 1.0 + 0.05 * k)
		head.scale = Vector3.ONE * (1.0 + 0.06 * k)
		var shake := sin(_ruffle_t * 40.0) * k
		_p("fold_l").rotation.z = -0.12 * absf(shake)
		_p("fold_r").rotation.z = 0.12 * absf(shake)
		_p("tail").rotation.y = 0.12 * shake
		if _ruffle_t > 0.6: _ruffle_t = -10.0
	# grazna: se inclina adelante, estira el cuello, abre el pico, baja algo las alas y sacude la cola
	_next_caw -= delta
	if _next_caw <= 0.0 and land >= 1.0 and _hop_t < 0.0:
		_caw()
		_next_caw = _rng.randf_range(7.0, 15.0)
	if _caw_t >= 0.0:
		_caw_t += delta
		var ph := _caw_t / 0.45
		if ph < 2.0:
			var k2 := sin(fmod(ph, 1.0) * PI)
			var bow := sin(clampf(_caw_t / 0.9, 0.0, 1.0) * PI)
			_p("jaw").rotation.x = 0.6 * k2
			head.rotation.x = -0.3 * k2 + 0.15 * bow
			_pivot.rotation.x += 0.28 * bow + 0.08 * k2
			_p("tail").rotation.x += 0.35 * k2
			_p("fold_l").rotation.z = -0.15 * bow
			_p("fold_r").rotation.z = 0.15 * bow
		else:
			_caw_t = -10.0
	if st >= wait and _hop_t < 0.0 and _caw_t < 0.0: _leave()

func _caw() -> void:
	_caw_t = 0.0
	var sfx := get_node_or_null("/root/Sfx")
	if sfx: sfx.call("play", "bird_crow")
