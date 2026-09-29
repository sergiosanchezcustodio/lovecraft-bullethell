class_name ShopBackdrop
extends SubViewportContainer
## Fondo del menú de la tienda (D-31, hito 2.13d): la tienda de antigüedades en voxel con el
## anciano detrás del mostrador, en su propio mundo 3D. La luz sale del quinqué (cálida, que
## titila), de la bola de cristal (violeta) y de dos velas; el resto queda en penumbra. La
## cámara encuadra la escena en la mitad izquierda: la ventana de la tienda va a la derecha.

var _vp: SubViewport
var _keeper: Node3D
var _lamp: OmniLight3D
var _ball: OmniLight3D
var _t := 0.0

const VOXEL := 1.0 / 32.0                   ## la tienda está a 32 voxels por metro
const KEEPER_AT := Vector3(80, 2, 40)       ## el anciano, en voxels de la tienda (tras el mostrador)
const LAMP_AT := Vector3(115, 50, 58)
const BALL_AT := Vector3(44.5, 43, 57.5)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.018, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.40, 0.42)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var room := VoxelBuilder.load_model("res://models/tienda_antiguedades.json")
	_vp.add_child(room)
	_keeper = VoxelBuilder.load_model("res://models/anciano.json")
	var holder := Node3D.new()                   # el giro va en un contenedor, no en la raíz
	holder.position = KEEPER_AT * VOXEL
	holder.rotation_degrees.y = 12.0             # mira hacia el cliente (la cámara)
	holder.add_child(_keeper)
	_vp.add_child(holder)
	_lamp = _light(LAMP_AT, Color(1.0, 0.72, 0.42), 2.6, 5.5)
	_ball = _light(BALL_AT, Color(0.7, 0.4, 1.0), 0.9, 2.2)
	_light(Vector3(20, 80, 12), Color(1.0, 0.75, 0.45), 0.6, 3.0)   # velas de las estanterías
	_light(Vector3(130, 80, 12), Color(1.0, 0.75, 0.45), 0.6, 3.0)
	var fill := DirectionalLight3D.new()        # un poco de luna por la izquierda: que no sea todo negro
	fill.rotation_degrees = Vector3(-40, -60, 0)
	fill.light_color = Color(0.55, 0.62, 0.8)
	fill.light_energy = 0.18
	_vp.add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 38.0
	cam.position = Vector3(5.4, 2.5, 7.0)
	cam.look_at_from_position(cam.position, Vector3(2.2, 1.15, 1.2))
	cam.h_offset = 1.25                          # la escena, a la izquierda de la pantalla
	_vp.add_child(cam)

func _light(at: Vector3, c: Color, energy: float, reach: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = at * VOXEL
	l.light_color = c
	l.light_energy = energy
	l.omni_range = reach
	l.shadow_enabled = energy > 1.0
	_vp.add_child(l)
	return l

func _process(delta: float) -> void:
	_t += delta
	_lamp.light_energy = 2.6 * (0.93 + 0.05 * sin(_t * 7.3) + 0.03 * sin(_t * 17.1))   # la llama titila
	_ball.light_energy = 0.9 * (0.8 + 0.2 * sin(_t * 1.3))
	Anims.pose("anciano", "idle", _keeper, fposmod(_t / Anims.duration("anciano", "idle"), 1.0))
