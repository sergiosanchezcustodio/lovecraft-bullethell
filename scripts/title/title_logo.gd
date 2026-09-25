class_name TitleLogo
extends Node3D
## Título "Lovecraft Library: Surviving Cthulhu" en voxel 3D (tools/gen_titulo.py). Se
## coloca como hijo de la cámara, en la franja superior de la vista, y tiene su propia
## capa de render (LAYER) con luces propias: una principal fría desde arriba a la
## izquierda, un relleno verdoso desde abajo y un contraluz que se enciende con cada
## relámpago. Las luces de la escena no le afectan (así su aspecto no depende del fondo).
## Los tentáculos están troceados en segmentos: aquí se encadenan y se mecen despacio,
## más cuanto más cerca de la punta.

const LAYER := 2                               ## capa de render del título (bit 2)
const MODELS := ["titulo_linea2", "titulo_linea1", "titulo_tentaculos"]
const WIDTH_M := 37.4                          ## anchura del título en metros (para encajarlo)

var distance := 27.0                           ## a qué distancia de la cámara está
var screen_baseline := 0.25                    ## altura de la línea base de "Surviving Cthulhu" (0 arriba, 1 abajo)
var max_width := 0.86                          ## fracción máxima del ancho de pantalla
var _chains := {}                              ## nombre del tentáculo -> Array[Node3D] de segmentos
var _rim: DirectionalLight3D
var _key: DirectionalLight3D
var _t := 0.0

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for m in MODELS:
		var model := VoxelBuilder.load_model("res://models/%s.json" % m)
		add_child(model)
		# Material propio sin niebla: la niebla entre la cámara y el título le quitaba contraste
		var own := {}
		for mi: MeshInstance3D in model.get_meta("meshes"):
			mi.layers = 1 << (LAYER - 1)
			mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			var mat := mi.material_override as BaseMaterial3D
			if not own.has(mat):
				var m2 := mat.duplicate() as BaseMaterial3D
				m2.disable_fog = true
				own[mat] = m2
			mi.material_override = own[mat]
		if m == "titulo_tentaculos": _build_chains(model)
	rotation_degrees.x = -7.0                  # inclinado hacia atrás: se ven los biseles de arriba
	# Luz principal cálida (como la del farol): la piedra se lee color hueso y el oro, oro;
	# con luz fría todo salía plateado. Contrasta con el azul de la tormenta.
	_key = _light(Vector3(-37, -30, 0), Color(1.0, 0.86, 0.68), 1.0, true)
	_light(Vector3(28, 150, 0), Color(0.35, 0.75, 0.6), 0.35, false)      # relleno verdoso desde abajo
	_rim = _light(Vector3(-20, 175, 0), Color(0.7, 0.8, 1.0), 0.35, false)   # contraluz desde atrás
	get_viewport().size_changed.connect(_fit)
	_fit()

func _light(rot: Vector3, color: Color, energy: float, shadows: bool) -> DirectionalLight3D:
	var l := DirectionalLight3D.new()
	l.rotation_degrees = rot
	l.light_color = color
	l.light_energy = energy
	l.light_cull_mask = 1 << (LAYER - 1)
	l.shadow_enabled = shadows
	l.light_volumetric_fog_energy = 0.0
	add_child(l)
	return l

## Encadena los segmentos "tX_00", "tX_01"… para que cada uno cuelgue del anterior.
func _build_chains(model: Node3D) -> void:
	var vs := float(model.get_meta("voxel_size"))
	var pivots: Dictionary = model.get_meta("pivots")
	var names: Array = pivots.keys()
	names.sort()
	for n: String in names:
		var chain := n.get_slice("_", 0)
		if not _chains.has(chain): _chains[chain] = []
		_chains[chain].append(model.get_node(n))
	for chain: String in _chains:
		var segs: Array = _chains[chain]
		for k in range(1, segs.size()):
			var node: Node3D = segs[k]
			var prev: Node3D = segs[k - 1]
			var p: Array = pivots[String(node.name)]
			var q: Array = pivots[String(prev.name)]
			model.remove_child(node)
			prev.add_child(node)
			node.position = (Vector3(p[0], p[1], p[2]) - Vector3(q[0], q[1], q[2])) * vs

## Coloca el título en la franja superior y lo aleja si la pantalla es más estrecha.
func _fit() -> void:
	var cam := get_parent() as Camera3D
	if cam == null: return
	var aspect := get_viewport().get_visible_rect().size.aspect()
	var half_h := tan(deg_to_rad(cam.fov * 0.5))
	var d := maxf(distance, WIDTH_M / max_width / (2.0 * half_h * aspect))
	position = Vector3(0.0, (0.5 - screen_baseline) * 2.0 * d * half_h, -d)

## Intensidad del relámpago (0..1): enciende el contraluz y aviva la luz principal.
func flash(k: float) -> void:
	_rim.light_energy = 0.35 + 3.2 * k
	_key.light_energy = 1.0 + 0.6 * k

func _process(delta: float) -> void:
	_t += delta
	for chain: String in _chains:
		var segs: Array = _chains[chain]
		var n := segs.size()
		var seed := float(chain.hash() % 100) * 0.1
		for k in n:
			var f := pow(float(k + 1) / n, 2.2)               # la punta se mueve, la base apenas
			var node: Node3D = segs[k]
			node.rotation = Vector3(
				sin(_t * 0.9 + k * 0.55 + seed) * 0.05 * f,
				sin(_t * 0.6 + k * 0.4 + seed * 1.3) * 0.04 * f,
				sin(_t * 1.1 + k * 0.7 + seed * 0.7) * 0.11 * f)
