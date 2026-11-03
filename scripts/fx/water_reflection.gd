class_name WaterReflection
extends Node
## Reflejos en el agua (hito 16.31): los investigadores y los faroles se reflejan en los charcos,
## el agua del pantano y el mar. Reflejo plano barato: una segunda cámara, espejo de la de la
## partida bajo el plano del suelo (y = 0), dibuja a media resolución solo la capa de los jugadores
## y la de los faroles (VIS_REFLECT) en un SubViewport con fondo transparente. Los shaders del
## agua (town_ground: charcos y ciénaga; sea) lo leen con los globales `refl_tex`, `refl_vp` (la
## matriz de esa cámara) y `refl_on`: cada fragmento de agua a la altura h busca su reflejo en el
## punto simétrico respecto al suelo (x, -h, z) proyectado con esa matriz (para el mar, más bajo
## que el suelo, sale igual de bien: es el mismo espejo desplazado).
## Solo en Alta y Ultra (`Quality` "reflections") y en las arenas con agua; `reflections=false`
## lo quita y `reflections=true` lo fuerza para comparar.

const VIS_REFLECT := 1 << 12                     ## capa de dibujo de lo que se refleja además de los jugadores
const SCALE := 0.5                               ## resolución respecto a la pantalla

var camera: Camera3D
var _vp: SubViewport
var _cam: Camera3D
var _plane_y := 0.0
var _env_t := 0.0

## ¿Hay agua en la que reflejarse? (mar, agua somera o suelo mojado)
static func has_water(arena: Node3D) -> bool:
	if arena == null: return false
	if arena.find_child("Sea", true, false) != null: return true
	var obs: Variant = arena.get_meta("obstacles", null)
	if obs != null and (obs as ObstacleMap).has_water(): return true
	var g := arena.find_child("Ground", true, false) as MeshInstance3D
	if g != null and g.material_override is ShaderMaterial:
		var w: Variant = (g.material_override as ShaderMaterial).get_shader_parameter("wet")
		if w != null and float(w) > 0.05: return true
	return false

## Los faroles de la arena pasan también a la capa del reflejo.
static func mark_lanterns(arena: Node3D) -> void:
	for lamp: OmniLight3D in arena.get_meta("lights", []):
		var holder := lamp.get_parent()
		if holder == null: continue
		for c in holder.get_children():                # solo el modelo voxel: sin halos ni haces (se veían como columnas)
			if not c.has_meta("meshes"): continue
			for mi: MeshInstance3D in c.get_meta("meshes"): mi.layers |= VIS_REFLECT

func setup(p_camera: Camera3D, arena: Node3D) -> WaterReflection:
	camera = p_camera
	mark_lanterns(arena)
	return self

func _ready() -> void:
	process_priority = 1000                      # después de que la cámara de la partida se mueva
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.world_3d = get_viewport().world_3d
	_vp.msaa_3d = Viewport.MSAA_DISABLED
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.cull_mask = Player.VIS_PLAYER | VIS_REFLECT
	_cam.current = true
	_vp.add_child(_cam)
	_resize()
	get_viewport().size_changed.connect(_resize)
	# la máscara de la cámara también deja fuera las luces que no están en sus capas: sin esto, en
	# el reflejo no había ni luna ni faroles y todo salía negro
	var scene := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	for l in scene.find_children("*", "Light3D", true, false): (l as Light3D).layers |= VIS_REFLECT
	RenderingServer.global_shader_parameter_set("refl_tex", _vp.get_texture())
	RenderingServer.global_shader_parameter_set("refl_on", 1.0)
	if LaunchArgs.from_cmdline().get_bool("refl_debug"):       # pruebas: la imagen del reflejo en una esquina y en todo el suelo
		RenderingServer.global_shader_parameter_set("refl_on", 2.0)
		var layer := CanvasLayer.new()
		layer.layer = 90
		add_child(layer)
		var bg := ColorRect.new()
		bg.color = Color(0.3, 0, 0.3)
		bg.position = Vector2(20, 640); bg.size = Vector2(640, 360)
		layer.add_child(bg)
		var tr := TextureRect.new()
		tr.texture = _vp.get_texture()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.position = bg.position; tr.size = bg.size
		layer.add_child(tr)

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set("refl_on", 0.0)

func _resize() -> void:
	var s := get_viewport().get_visible_rect().size
	_vp.size = Vector2i(maxi(int(s.x * SCALE), 16), maxi(int(s.y * SCALE), 16))

## La cámara espejo de `t` respecto al plano y = `plane_y`, girada en x para que sea un giro de verdad.
static func mirrored(t: Transform3D, plane_y := 0.0) -> Transform3D:
	var mirror := Basis(Vector3(1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1))
	var b := mirror * t.basis * Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	return Transform3D(b, Vector3(t.origin.x, 2.0 * plane_y - t.origin.y, t.origin.z))

## Su propio entorno: el de la partida sin niebla volumétrica (los halos de los faroles salían como
## columnas de luz: en ortográfica se estiran a lo largo de la vista), ni resplandor ni SSAO. Se
## copia cada segundo: la atmósfera cambia durante el nivel.
## Lo que la cámara espejo no lleva (los halos de la niebla volumétrica salían como columnas).
const ENV_OFF := ["volumetric_fog_enabled", "glow_enabled", "ssao_enabled", "ssr_enabled", "ssil_enabled"]

## Su entorno es una copia del de la escena, hecha una vez; después solo se copian los valores que
## cambian (la noche, 16.33, y los relámpagos los mueven sin parar). Antes se duplicaba entero cada
## segundo y cada copia nueva compilaba un shader: un tirón de 16-20 ms cada 2,25 s en Luisiana.
func _sync_env() -> void:
	var src: Environment = get_viewport().find_world_3d().environment
	if src != null: _sync_from(src)

func _sync_from(src: Environment) -> void:
	var e := _cam.environment
	if e == null or _env_src != src:
		_env_src = src
		e = src.duplicate() as Environment
		for k: String in ENV_OFF: e.set(k, false)
		_cam.environment = e
		return
	for pr in _env_props(src):
		var k: String = pr
		var v: Variant = src.get(k)
		if e.get(k) != v: e.set(k, v)

var _env_src: Environment
var _props: PackedStringArray = []

func _env_props(src: Environment) -> PackedStringArray:
	if _props.is_empty():
		for d in src.get_property_list():
			if int(d.usage) & PROPERTY_USAGE_STORAGE and not ENV_OFF.has(String(d.name)) and String(d.name) != "resource_name" 					and int(d.type) != TYPE_OBJECT:
				_props.append(String(d.name))
	return _props

func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera): return
	_env_t -= delta
	if _env_t <= 0.0:
		_env_t = 1.0
		_sync_env()
	_cam.projection = camera.projection
	_cam.size = camera.size
	_cam.fov = camera.fov
	_cam.near = camera.near
	_cam.far = camera.far
	_cam.keep_aspect = camera.keep_aspect
	# espejo de la cámara respecto al plano y = _plane_y. El espejo invierte la orientación, así que
	# se le da la vuelta en x para que sea un giro de verdad: la imagen queda al revés de izquierda a
	# derecha, pero los shaders la leen con la matriz de esta cámara y no importa.
	_cam.global_transform = mirrored(camera.get_camera_transform(), _plane_y)
	var vp := _cam.get_camera_projection() * Projection(_cam.get_camera_transform().affine_inverse())
	RenderingServer.global_shader_parameter_set("refl_vp", vp)
