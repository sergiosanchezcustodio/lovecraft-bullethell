class_name TitleRaven
extends TextureRect
## Cuervo de la portada (17-10-2026; animación rehecha el 18-10-2026 y otra vez el 28-10-2026):
## entra desde el balcón de la izquierda con rachas de aleteo y planeos que se funden, se
## endereza para frenar con aletazos hacia delante, la cola abierta y las patas a por la
## calavera, y se posa: las patas caen justo en la calavera y no se mueven de ahí (se coloca por
## los dedos, no por un punto fijo del render), el cuerpo se agacha con el golpe y se balancea,
## mantiene un momento las alas en alto para equilibrarse y las pliega poco a poco hasta el
## costado. Posado mira a golpes de cabeza, la ladea, cambia el peso de pata, a veces levanta una
## o da un saltito para girarse, se ahueca y grazna inclinándose. Al rato se va (se agacha,
## despliega las alas y salta con el primer aletazo) y vuelve más tarde; al pulsar un botón
## (scare) sale volando asustado.
## Es el modelo voxel `cuervo_portada` (tools/gen_cuervo_portada.py): el ala abierta va en cuatro
## piezas encadenadas (hombro, codo, muñeca y punta) para que se doble al aletear: en la bajada,
## extendida y con las puntas curvadas hacia arriba por el aire; en la subida, recogida por el
## codo y la muñeca, con la punta rezagada. Las alas plegadas son otras piezas (fold_*): el ala
## abierta se lleva hasta su sitio y entonces se cambia una por otra.
## Se renderiza en su propio SubViewport con la luz de la escena (vela cálida a la izquierda,
## contraluz azul del ventanal y luz fría de arriba) y se mueve en 2D sobre la ilustración,
## dentro del escenario que se acerca.

const MODEL := "cuervo_portada"
const VIEW_M := 0.95                         ## metros que caben en el render (cámara ortográfica)
const SIZE := 400.0                          ## tamaño en pantalla (px de 1920×1080) del render
const PERCH := Vector2(330, 770)             ## patas sobre la calavera (escenario de 1920×1080)
const START := Vector2(-160, 330)            ## de dónde llega: el balcón de la izquierda
const FLY_IN := 3.8                          ## s de vuelo hasta posarse
const FLY_OUT := 2.4
const CROUCH_OUT := 0.26                     ## s que se agacha y despliega las alas antes de saltar
const CAM_Y := 0.3                           ## altura a la que mira la cámara (centro del cuerpo)
const CAM_PITCH := 22.0                      ## grados: la ilustración se ve algo desde arriba
const PERCH_YAW := 52.0                      ## de tres cuartos, mirando a la sala
const LAND_T := 1.4                          ## s del aterrizaje: golpe, equilibrio y plegado
const FOLD_FROM := 0.5                       ## ... cuándo empieza a plegar
const FOLD_TO := 1.05                        ## ... y cuándo las tiene plegadas
const TOE := Vector3(0.0, -0.09, 0.015)      ## dedos respecto al talón (pivote de la pata), en m
const WING := ["arm", "fore", "hand", "tip"]
## Ala plegada (pieza arm, lado derecho): el largo va hacia atrás y abajo, por el costado, y el
## borde de salida hacia abajo. Coincide con fold_* para cambiar una por otra sin que se note.
const FOLD_SPAN := Vector3(-0.05, -0.34, -0.94)
const FOLD_TRAIL := Vector3(0.1, -1.0, 0.1)
const FOLD_SIZE := Vector3(0.64, 1.0, 0.6)    ## el ala plegada es más corta y estrecha: las plumas se solapan
const FOLD_TURN := [0.0, 0.3, 0.15]           ## codo, muñeca y punta, hacia delante al plegar (y la mano, estrecha)
## Posturas del ala: [subir, adelante, girar] de hombro, codo, muñeca y punta (rad). Subir: el ala
## arriba; adelante: hacia la cabeza; girar: el borde de ataque abajo.
const GLIDE := [0.1, 0.0, 0.05, 0.02, 0.0, 0.0, 0.0, -0.06, 0.0, 0.14, 0.0, 0.0]
const BALANCE := [1.25, -0.1, 0.1, -0.1, -0.2, 0.0, -0.3, -0.3, 0.1, -0.1, -0.1, 0.0]

enum State { AWAY, IN, PERCHED, OUT }

var state := State.AWAY
var st := 0.0                                ## tiempo en el estado
var wait := 0.0                              ## cuándo llega o se va
var view_px := 0                             ## resolución del render (0: la de la pantalla)
var _vp: SubViewport
var _cam: Camera3D
var _model: Node3D
var _pivot: Node3D                           ## giro y posición del modelo (la raíz la reinicia Anims)
var _parts := {}
var _head_rest := Vector3.ZERO
var _rim: DirectionalLight3D
var _moon: DirectionalLight3D
var _rng := RandomNumberGenerator.new()
var _leave_dir := Vector2(1, -1)
var _out_from := Vector2.ZERO
var _yaw := PERCH_YAW                        ## orientación posado (cambia con los saltitos)
var _plant := Vector2.ONE                    ## cuánto se apoya cada pata (0: en el aire), para colocarlo
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
	# a la resolución con que se ve (algo más, por el acercamiento): reducido a la mitad, las
	# plumas finas parpadeaban al moverse
	var px := view_px
	if px <= 0:
		var k := float(DisplayServer.window_get_size().y) / 1080.0 if DisplayServer.get_name() != "headless" else 1.0
		px = clampi(int(SIZE * k * 1.15 / 16.0) * 16, 320, 1024)
	_vp.size = Vector2i(px, px)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_8X
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.24, 0.42)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.3
	var we := WorldEnvironment.new(); we.environment = env; _vp.add_child(we)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = VIEW_M
	_vp.add_child(_cam)
	var a := deg_to_rad(CAM_PITCH)
	_cam.look_at_from_position(Vector3(0, CAM_Y + 3.0 * sin(a), 3.0 * cos(a)), Vector3(0, CAM_Y, 0))
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
	for n in ["body", "head", "jaw", "tail", "leg_l", "leg_r", "fold_l", "fold_r"]:
		_parts[n] = Anims.part(_model, n)
	for w in WING:
		for sfx in ["_l", "_r"]: _parts[w + sfx] = Anims.part(_model, w + sfx)
	_head_rest = _p("head").position
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
	var open := state == State.IN or state == State.OUT or (state == State.PERCHED and st < FOLD_TO)
	_rim.light_energy = lerpf(_rim.light_energy, 0.25 if open else 1.0, minf(1.0, delta * 6.0))
	_moon.light_energy = lerpf(_moon.light_energy, 0.06 if open else 0.32, minf(1.0, delta * 6.0))
	match state:
		State.AWAY:
			if st >= wait: _go(State.IN)
		State.IN: _fly_in()
		State.PERCHED: _perched(delta)
		State.OUT: _fly_out()

func _go(s: State, settled := false) -> void:
	state = s
	st = LAND_T + 0.5 if settled else 0.0
	visible = s != State.AWAY
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	if s == State.PERCHED:
		wait = _rng.randf_range(22.0, 40.0) + st     # cuánto se queda
		_next_caw = _rng.randf_range(3.0, 7.0) + LAND_T
		_next_hop = _rng.randf_range(12.0, 24.0)
		_next_ruffle = _rng.randf_range(9.0, 16.0)
		_yaw = PERCH_YAW
	elif s == State.AWAY:
		wait = _rng.randf_range(18.0, 34.0)        # cuánto tarda en volver

func _leave() -> void:
	_out_from = PERCH
	_leave_dir = Vector2(-1.0, -0.75).normalized() if _rng.randf() < 0.5 else Vector2(0.55, -1.0).normalized()
	_go(State.OUT)

## Coloca el render, a escala `k`, para que los dedos caigan en `p` (coordenadas del escenario).
## Se miran los dedos de verdad (con el giro del cuerpo y de las patas), pero no el
## desplazamiento del pivote: lo que sube o baja el cuervo (saltos, aleteo) sí se ve. Una pata
## levantada (`_plant` a 0) cuenta en su sitio de reposo, para que no arrastre al cuerpo.
func _place(p: Vector2, k: float) -> void:
	scale = Vector2.ONE * k
	var foot := Vector3.ZERO
	for i in 2:
		var leg := _p("leg_l" if i == 0 else "leg_r")
		var real := leg.global_transform * TOE
		var rest := (leg.get_parent() as Node3D).global_transform * (leg.position + TOE)
		foot += rest.lerp(real, _plant[i]) * 0.5
	foot -= _pivot.position
	var px := _cam.unproject_position(foot) / float(_vp.size.x)
	position = p - px * SIZE * k

static func _bezier(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var s := 1.0 - t
	return a * s * s * s + b * 3.0 * s * s * t + c * 3.0 * s * t * t + d * t * t * t

## 0 fuera de [a, b], 1 dentro, con bordes suaves de `edge`.
static func _window(u: float, a: float, b: float, edge := 0.04) -> float:
	return smoothstep(a - edge, a + edge, u) * (1.0 - smoothstep(b - edge, b + edge, u))

# ------------------------------------------------------------------ piezas

func _p(n: String) -> Node3D:
	return _parts[n] as Node3D

func _reset() -> void:
	for n in _parts:
		_p(n).transform.basis = Basis.IDENTITY
	_p("head").position = _head_rest
	_pivot.position = Vector3.ZERO
	_pivot.rotation = Vector3.ZERO
	_plant = Vector2.ONE
	_show_folded(false)

func _show_folded(on: bool) -> void:
	for sfx in ["_l", "_r"]: _p("arm" + sfx).visible = not on      # el resto del ala cuelga del brazo
	for n in ["fold_l", "fold_r"]: _p(n).visible = on

## Una articulación del ala, en este orden: gira el borde de ataque (`twist`, sobre el largo del
## ala), sube (`elev`) y la lleva hacia delante (`sweep`). El lado izquierdo, en espejo.
func _joint(n: Node3D, side: float, elev: float, sweep: float, twist: float) -> void:
	n.transform.basis = Basis(Vector3.UP, -side * sweep) * Basis(Vector3.BACK, side * elev) * Basis(Vector3.RIGHT, twist)

func _wings(pose: Array) -> void:
	for side in [-1.0, 1.0]:
		var sfx := "_l" if side < 0.0 else "_r"
		for j in 4:
			_joint(_p(WING[j] + sfx), side, pose[j * 3], pose[j * 3 + 1], pose[j * 3 + 2])

static func _mix(a: Array, b: Array, k: float) -> Array:
	var out := []
	for i in a.size(): out.append(lerpf(a[i], b[i], k))
	return out

## Lleva el ala (ya puesta en una postura) hacia la plegada: el brazo a su sitio junto al
## costado y el resto estirado detrás de él, más corto. Con k = 1 coincide con fold_*.
func _toward_fold(k: float) -> void:
	if k <= 0.0: return
	for side in [-1.0, 1.0]:
		var sfx := "_l" if side < 0.0 else "_r"
		var arm := _p("arm" + sfx)
		var b := arm.transform.basis.orthonormalized().slerp(_fold_basis(side), k)
		arm.transform.basis = b * Basis.from_scale(Vector3.ONE.lerp(FOLD_SIZE, k))
		# la mano gira hacia delante en el plano del ala: las primarias, que en abanico apuntan
		# hacia fuera, quedan a lo largo del ala, hacia atrás
		for j in 3:
			var n := _p(WING[j + 1] + sfx)
			var to := Basis(Vector3.UP, -side * FOLD_TURN[j])
			n.transform.basis = n.transform.basis.orthonormalized().slerp(to, k) 				* Basis.from_scale(Vector3(1.0, 1.0, lerpf(1.0, 0.45, k) if j > 0 else 1.0))

static func _fold_basis(side: float) -> Basis:
	var x := FOLD_SPAN.normalized()
	var trail := (FOLD_TRAIL - x * FOLD_TRAIL.dot(x)).normalized()
	var z := -trail                                   # +Z del ala: el borde de ataque, arriba
	var b := Basis(x, z.cross(x), z)
	if side < 0.0:
		var m := Basis(Vector3(-1, 0, 0), Vector3.UP, Vector3.BACK)
		b = m * b * m
	return b

## Un aletazo (fase 0..1, 0 = alas arriba): la bajada (56 %) con el ala extendida, el borde de
## ataque algo abajo y las puntas curvadas hacia arriba por el aire; la subida, más rápida, con
## el codo y la muñeca recogidos hacia atrás y la punta rezagada abajo. `power` (0..1) agranda el
## gesto (frenada, despegue). Devuelve la postura y sube el cuerpo con cada golpe.
func _flap(p: float, power := 0.6) -> Array:
	var d := 0.56
	var down := p < d
	var s := p / d if down else (p - d) / (1.0 - d)
	var e := (1.0 - cos(PI * s)) * 0.5
	var top := 0.9 + 0.35 * power
	var bot := -0.55 - 0.3 * power
	var b := sin(PI * s)
	var bob := 0.008 * (1.0 + power) * sin(TAU * p - 2.2)
	_pivot.position.y += bob
	_p("head").position.y -= bob * 0.7               # la cabeza se queda quieta: los pájaros la estabilizan
	if down:
		return [lerpf(top, bot, e), 0.12 * b, 0.28 * b, 0.0, 0.0, 0.0,
			-0.1 * b, 0.05 * b, 0.12 * b, 0.32 * b, 0.0, 0.0]
	return [lerpf(bot, top, e), -0.3 * b, -0.22 * b, -0.12 * b, -0.45 * b, 0.0,
		-0.4 * b, -0.7 * b, -0.3 * b, -0.3 * b, -0.3 * b, 0.0]

## Planeo: alas extendidas en una V suave, las puntas algo levantadas y temblando.
static func _glide(time: float) -> Array:
	var g := GLIDE.duplicate()
	g[0] += 0.03 * sin(time * 2.3)
	g[9] += 0.04 * sin(time * 11.0) + 0.02 * sin(time * 17.0)
	return g

## Patas: positivo las lleva atrás (recogidas en vuelo), negativo adelante (a por la percha).
func _legs(rot_l: float, rot_r: float) -> void:
	_p("leg_l").rotation.x = rot_l
	_p("leg_r").rotation.x = rot_r

# ------------------------------------------------------------------ vuelo

func _fly_in() -> void:
	var u := clampf(st / FLY_IN, 0.0, 1.0)
	_reset()
	var e := 1.0 - pow(1.0 - u, 2.2)                 # frena al llegar
	var c1 := Vector2(40, 380); var c2 := Vector2(200, 650)
	var p := _bezier(START, c1, c2, PERCH, e)
	var ahead := _bezier(START, c1, c2, PERCH, minf(e + 0.02, 1.0))
	var brake := smoothstep(0.76, 0.93, u)           # se endereza y frena
	var touch := smoothstep(0.93, 1.0, u)            # las alas pasan a la postura de equilibrio
	var dir := ahead - p
	var side := 1.0 if dir.x >= 0.0 else -1.0
	var slope := clampf(dir.y / maxf(absf(dir.x), 0.001), -1.2, 1.2)
	# de perfil hacia donde va, inclinado según baja; al frenar se endereza (morro arriba) y gira
	# hacia la sala; al tocar ya va recuperando la horizontal
	var turn := smoothstep(0.68, 0.9, u)             # se vuelve hacia la sala antes de frenar: se le ven las alas
	var yaw := side * deg_to_rad(lerpf(82.0, PERCH_YAW + 4.0, turn))
	var pitch := slope * 0.28 * (1.0 - brake) - lerpf(0.8, 0.45, touch) * brake
	_pivot.rotation = Vector3(pitch, yaw, 0.0)
	# rachas de aleteo con planeos entre medias, fundidas; al frenar, aletazos hacia delante
	var w := maxf(_window(u, 0.0, 0.3), _window(u, 0.44, 0.62))
	var cruise := _mix(_glide(st), _flap(fmod(st * 3.1, 1.0), 0.5), w) if w > 0.0 else _glide(st)
	var pose := cruise
	if brake > 0.0:
		var f := _flap(fmod(st * 4.0, 1.0), 1.0)
		f[1] += 0.4; f[2] -= 0.3; f[4] += 0.15; f[9] += 0.2   # hacia delante y ahuecadas: frenan
		pose = _mix(cruise, f, brake)
	_wings(_mix(pose, BALANCE, touch))
	# patas recogidas atrás; al frenar se adelantan a por la calavera y al tocar ya van debajo
	var leg := lerpf(1.25, -0.6, smoothstep(0.74, 0.9, u))
	leg = lerpf(leg, -0.3, touch)
	_legs(leg, leg + 0.06 * (1.0 - touch))
	# cola: plegada en vuelo; al frenar baja y se abre en abanico
	_p("tail").rotation.x = lerpf(0.05, -0.45, brake)
	_p("tail").scale = Vector3(lerpf(1.0, 1.3, brake), 1.0, 1.0)
	_p("head").rotation.x = -pitch * 0.8 - 0.1       # la cabeza sigue mirando adelante
	_place(p, lerpf(0.55, 1.0, e))                   # se acerca: crece
	if u >= 1.0: _go(State.PERCHED)

func _fly_out() -> void:
	_reset()
	if st < CROUCH_OUT:                               # se agacha y despliega las alas en alto
		var k := smoothstep(0.0, 1.0, st / CROUCH_OUT)
		_wings(_flap(0.0, 1.0))
		_pivot.position.y = -0.012 * k                   # (sin el bote del aletazo)
		_p("head").position = _head_rest
		_pivot.rotation = Vector3(0.3 * k, deg_to_rad(_yaw), 0.0)
		_toward_fold(1.0 - k)
		_legs(-0.35 * k, -0.35 * k)
		_p("tail").rotation.x = 0.3 * k
		_p("head").rotation.x = -0.2 * k
		_place(_out_from, 1.0)
		return
	var t := st - CROUCH_OUT
	var u := clampf(t / FLY_OUT, 0.0, 1.0)
	var side := 1.0 if _leave_dir.x >= 0.0 else -1.0
	var pitch := lerpf(-0.6, -0.15, smoothstep(0.0, 0.4, u))     # salta con el morro arriba
	_pivot.rotation = Vector3(pitch, side * deg_to_rad(lerpf(_yaw, 82.0, smoothstep(0.0, 0.3, u))), 0.0)
	_wings(_flap(fmod(t * 4.0, 1.0), lerpf(1.0, 0.6, u)))       # el primer aletazo, con el salto
	var leg := lerpf(-0.35, 1.25, smoothstep(0.03, 0.3, u))     # empujan, cuelgan y se recogen
	_legs(leg, leg + 0.1)
	_p("tail").rotation.x = lerpf(-0.35, 0.05, u)
	_p("tail").scale = Vector3(lerpf(1.25, 1.0, u), 1.0, 1.0)
	_p("head").rotation.x = -pitch * 0.7
	_plant = Vector2.ZERO
	var d := _leave_dir * (u * u * 1500.0 + u * 220.0) + Vector2(0, -50.0 * smoothstep(0.0, 0.15, u))
	_place(_out_from + d, lerpf(1.0, 0.6, u))
	if u >= 1.0: _go(State.AWAY)

# ------------------------------------------------------------------ posado

func _perched(delta: float) -> void:
	_reset()
	var head := _p("head")
	# el aterrizaje: el golpe lo agacha y lo echa adelante (viene con el morro arriba) y se
	# balancea hasta quedarse quieto; las alas en alto un momento, un aletazo corto para
	# equilibrarse, y se pliegan despacio hasta el costado
	var landing := st < LAND_T
	var crouch := 0.0
	var sway := 0.0
	if landing:
		crouch = sin(clampf(st / 0.45, 0.0, 1.0) * PI) * 0.9
		sway = -0.45 * exp(-5.0 * st) * cos(8.0 * st)              # de morro arriba a quieto
		var pose := BALANCE.duplicate()
		var fw := _window(st, 0.1, 0.42, 0.06)
		if fw > 0.0: pose = _mix(pose, _flap(fmod(st * 3.0 + 0.6, 1.0), 0.4), fw * 0.45)
		_wings(pose)
		var fk := smoothstep(FOLD_FROM, FOLD_TO, st)
		_toward_fold(fk)
		if fk >= 1.0: _show_folded(true)
	else:
		_show_folded(true)
	# peso: el cuerpo se balancea de una pata a otra; a veces levanta una y la vuelve a posar
	_shift_t -= delta
	if _shift_t <= 0.0:
		_shift_to = _rng.randf_range(-1.0, 1.0)
		_shift_t = _rng.randf_range(1.5, 4.0)
	_shift = lerpf(_shift, _shift_to, minf(1.0, delta * 2.5))
	var leg_l := -0.08 + 0.06 * _shift - 0.3 * crouch
	var leg_r := -0.08 - 0.06 * _shift - 0.3 * crouch
	if landing: leg_l = lerpf(-0.3, leg_l, smoothstep(0.0, 0.2, st)); leg_r = lerpf(-0.3, leg_r, smoothstep(0.0, 0.2, st))
	_next_lift -= delta
	if _next_lift <= 0.0 and not landing:
		_lift_t = 0.0
		_lift_side = 1.0 if _rng.randf() < 0.5 else -1.0
		_next_lift = _rng.randf_range(8.0, 16.0)
	var lift := 0.0
	if _lift_t >= 0.0:
		_lift_t += delta
		lift = sin(clampf(_lift_t / 0.6, 0.0, 1.0) * PI)
		if _lift_t > 0.6: _lift_t = -10.0
	if _lift_side > 0.0:
		leg_r -= 0.6 * lift; _plant.y = 1.0 - lift
	else:
		leg_l -= 0.6 * lift; _plant.x = 1.0 - lift
	_legs(leg_l, leg_r)
	# saltito para girarse: se agacha, salta un palmo abriendo un poco las alas y cae mirando a
	# otro lado, agachándose otra vez con el golpe
	_next_hop -= delta
	if _next_hop <= 0.0 and not landing and _caw_t < 0.0:
		_hop_t = 0.0
		_hop_from = _yaw
		_hop_to = clampf(_yaw + _rng.randf_range(-35.0, 35.0), 20.0, 80.0)
		_next_hop = _rng.randf_range(12.0, 24.0)
	var hop_y := 0.0
	if _hop_t >= 0.0:
		_hop_t += delta
		var q := clampf(_hop_t / 0.5, 0.0, 1.0)
		crouch += sin(clampf(q / 0.22, 0.0, 1.0) * PI) * 0.6 + sin(clampf((q - 0.78) / 0.22, 0.0, 1.0) * PI) * 0.5
		var air := clampf((q - 0.18) / 0.6, 0.0, 1.0)
		hop_y = sin(air * PI) * 0.04
		_yaw = lerpf(_hop_from, _hop_to, smoothstep(0.0, 1.0, air))
		if air > 0.0 and air < 1.0:
			_show_folded(false)                          # abre un poco las alas para equilibrarse
			_wings(BALANCE)
			_toward_fold(1.0 - 0.55 * sin(air * PI))
			_legs(0.45 * sin(air * PI), 0.45 * sin(air * PI))
			_plant = Vector2.ZERO
		if q >= 1.0: _hop_t = -10.0
	_pivot.position.y += -0.006 * crouch + hop_y
	_pivot.rotation = Vector3(0.14 * crouch + sway, deg_to_rad(_yaw), 0.035 * _shift)
	# mira a un lado y a otro a golpes de cabeza (los pájaros no giran despacio)
	_look_t -= delta
	if _look_t <= 0.0:
		_look_to = _rng.randf_range(-1.1, 0.9)
		_tilt_to = _rng.randf_range(-0.35, 0.35) if _rng.randf() < 0.4 else 0.0
		_look_t = _rng.randf_range(0.6, 2.4)
	_look = lerpf(_look, _look_to, minf(1.0, delta * 18.0))
	_tilt = lerpf(_tilt, _tilt_to, minf(1.0, delta * 10.0))
	head.rotation = Vector3(-sway * 0.8 - 0.1 * crouch, _look, _tilt)
	# respira; la cola acompaña y, al posarse, se cierra y sube
	var breath := sin(st * 2.4)
	_p("body").scale = Vector3.ONE * (1.0 + 0.012 * breath)
	var land_k := smoothstep(0.0, 0.7, st)
	_p("tail").rotation.x = 0.03 * breath + lerpf(-0.4, 0.0, land_k) + 0.12 * crouch
	_p("tail").scale = Vector3(lerpf(1.3, 1.0, land_k), 1.0, 1.0)
	# al plegar, se sacude un poco y se ahueca, como colocándose las plumas
	if landing and st > FOLD_TO - 0.05:
		var k0 := sin(clampf((st - FOLD_TO + 0.05) / (LAND_T - FOLD_TO + 0.05), 0.0, 1.0) * PI)
		var sh := sin(st * 38.0) * k0
		_p("body").scale *= Vector3(1.0 + 0.04 * k0, 1.0 + 0.025 * k0, 1.0 + 0.025 * k0)
		_p("fold_l").rotation.z = -0.07 * absf(sh)
		_p("fold_r").rotation.z = 0.07 * absf(sh)
		_p("tail").rotation.y = 0.1 * sh
	# se ahueca: las plumas se erizan, sacude las alas y la cola
	_next_ruffle -= delta
	if _next_ruffle <= 0.0 and not landing:
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
	if _next_caw <= 0.0 and not landing and _hop_t < 0.0:
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
	_place(PERCH, 1.0)
	if st >= wait and _hop_t < 0.0 and _caw_t < 0.0: _leave()

func _caw() -> void:
	_caw_t = 0.0
	var sfx := get_node_or_null("/root/Sfx")
	if sfx: sfx.call("play", "bird_crow")
