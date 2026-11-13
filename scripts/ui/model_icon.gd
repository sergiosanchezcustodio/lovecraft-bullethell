class_name ModelIcon
extends RefCounted
## Imagen de un modelo voxel para los menús: lo renderiza una vez en un SubViewport (hijo de
## `host`) y devuelve la textura. "head" encuadra la cabeza (retratos de personajes);
## "full", el modelo entero de tres cuartos (compañeros, iconos de la tienda), encajado con
## margen según lo que ocupa visto desde la cámara. Con `fixed` > 0 (m de alto del encuadre),
## todos a la misma escala y con los pies en el mismo sitio (bestiario de la Biblioteca).

const FULL_ROT := Vector3(-25, 35, 0)
const MARGIN := 1.12

## Lo que ocupa el modelo visto con la cámara de "full" (m, lo mayor de ancho y alto).
static func frame_size(model_name: String) -> float:
	var m := VoxelBuilder.load_model("res://models/%s.json" % model_name)
	var r := _projected(m, Basis.from_euler(FULL_ROT * PI / 180.0))
	m.free()
	return maxf(r.size.x, r.size.y)

## Caja del modelo proyectada en el plano de la cámara (x a la derecha, y arriba).
static func _projected(m: Node3D, basis: Basis) -> Rect2:
	var r := Rect2()
	var first := true
	for mi: MeshInstance3D in m.get_meta("meshes"):
		var xf := Transform3D()                    # de la malla a la raíz del modelo (cuelga de su parte)
		var n: Node = mi
		while n != m and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b: AABB = xf * mi.get_aabb()
		for i in 8:
			var c := b.get_endpoint(i)
			var p := Vector2(c.dot(basis.x), c.dot(basis.y))
			r = Rect2(p, Vector2.ZERO) if first else r.expand(p)
			first = false
	return r

## hold: postura del brazo (OutfitData.HOLDS) para las prendas que se sostienen (fase 14);
## worn: el vestuario puesto ({hueco: prenda}), en la ficha y en la Biblioteca.
static func make(host: Node, model_name: String, mode: String = "full", px: int = 128, fixed := 0.0, hold := "",
		worn := {}) -> Texture2D:
	var vp := SubViewport.new()
	# se renderiza una sola vez: sin interpolación, o saldría a medio camino desde el origen
	vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	vp.size = Vector2i(px, px)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(vp)
	var m := VoxelBuilder.load_model("res://models/%s.json" % model_name)
	vp.add_child(m)
	if not worn.is_empty(): OutfitData.apply(m, model_name, worn)
	OutfitData.pose_hold(m, hold, 1.0)
	_stage(vp, m, mode, fixed)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.add_child(_Settle.new(vp))
	return vp.get_texture()

## Dibuja la vista unos fotogramas y luego la para (13-11-2026). Con UPDATE_ONCE, un material que
## aún no se había dibujado en una vista así compila su pipeline en segundo plano y ese primer y
## único fotograma salía vacío: en partida, el gato, la cabra y el dhole (los trucos, 21.5).
class _Settle extends Node:
	const SETTLE_MS := 400
	var vp: SubViewport
	var _until := 0
	func _init(p_vp: SubViewport) -> void:
		vp = p_vp
		name = "Settle"
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _ready() -> void:
		_until = Time.get_ticks_msec() + SETTLE_MS
	func _process(_delta: float) -> void:
		if Time.get_ticks_msec() < _until: return
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE   # uno más, ya compilado, y se queda
		queue_free()

## Modelo vivo (hito 15.4, bestiario): como `make` con "full", pero se dibuja en cada fotograma,
## gira despacio y hace su animación de reposo (o de andar). Devuelve el SubViewport (su textura
## es la imagen); hay que colgarlo de algo que se libere con la página. Con `mode` "head" (el
## retrato de la tienda, hito 20.7) no da la vuelta: respira con su reposo y mira a un lado y a otro.
static func make_live(model_name: String, px: int = 128, fixed := 0.0, mode := "full") -> SubViewport:
	var vp := SubViewport.new()
	vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	vp.size = Vector2i(px, px)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var m := VoxelBuilder.load_model("res://models/%s.json" % model_name)
	var turn := Node3D.new()                       # el giro, en un contenedor (nunca en la raíz del modelo)
	turn.name = "Turn"
	vp.add_child(turn)
	turn.add_child(m)
	_stage(vp, m, mode, fixed)
	var spin := Spin.new()
	spin.sway = mode == "head"
	spin.model_name = model_name
	spin.model = m
	spin.turn = turn
	vp.add_child(spin)
	return vp

## Gira el modelo y le pone su animación de reposo (o de andar, si no tiene).
class Spin extends Node:
	const SPEED := 0.6                             ## rad/s
	const SWAY := 0.32                             ## rad a cada lado, con `sway`
	const SWAY_PERIOD := 7.0                       ## s de un lado al otro y vuelta
	var sway := false
	var model_name := ""
	var model: Node3D
	var turn: Node3D
	var _t := 0.0
	var _anim := ""
	func _ready() -> void:
		_anim = "idle" if Anims.has_anim(model_name, "idle") else ("walk" if Anims.has_anim(model_name, "walk") else "")
		turn.rotation.y = 0.0 if sway else -0.6
	var _clock := 0.0
	func _process(delta: float) -> void:
		_clock += delta
		if sway: turn.rotation.y = SWAY * sin(TAU * _clock / SWAY_PERIOD)
		else: turn.rotation.y += SPEED * delta
		if _anim == "": return
		_t = fposmod(_t + delta / Anims.duration(model_name, _anim), 1.0)
		Anims.pose(model_name, _anim, model, _t)

## Cámara de tres cuartos y luces de estudio para `make` y `make_live`.
static func _stage(vp: SubViewport, m: Node3D, mode: String, fixed: float) -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	if mode == "head":
		var head: Vector3 = Anims.rest(m, "head") + Vector3(0, 0.2, 0)
		cam.size = 0.62
		cam.rotation_degrees = Vector3(-12, 25, 0)
		cam.position = head + cam.transform.basis.z * 3.0
	else:
		cam.rotation_degrees = FULL_ROT
		var bs := cam.transform.basis
		var r := _projected(m, bs)
		var c := r.get_center()
		if fixed > 0.0:
			cam.size = fixed
			c.y = r.position.y + fixed * 0.5 * 0.9          # pies abajo, todos a la misma altura
		else:
			cam.size = maxf(r.size.x, r.size.y) * MARGIN
		var far := 0.0
		for mi: MeshInstance3D in m.get_meta("meshes"): far = maxf(far, mi.get_aabb().size.length())
		cam.position = bs.x * c.x + bs.y * c.y + bs.z * (far + 4.0)
	vp.add_child(cam)
	# iluminación de estudio: luz principal cálida, relleno frío suave y poco ambiente. Con un
	# ambiente gris fuerte y una sola luz, el modelo salía plano y lavado, como tras una niebla.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, 50, 0)
	key.light_energy = 1.35
	key.light_color = Color(1.0, 0.95, 0.88)
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -60, 0)
	fill.light_energy = 0.4
	fill.light_color = Color(0.75, 0.82, 1.0)
	vp.add_child(fill)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.14, 0.16)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	we.environment = env
	vp.add_child(we)
