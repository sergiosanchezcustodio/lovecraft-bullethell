class_name Breakable
extends Node3D
## Objeto rompible (04-10-2026): barril o caja pequeños que las armas rompen al pasar (están en
## la rejilla de objetivos, pero CombatWorld no los da como objetivo al apuntar). Al romperse
## sueltan una recompensa (Pickup). Tienen las mismas funciones de estado que un enemigo, vacías,
## para que ningún arma falle al tocarlos.

signal broken(b: Breakable)

var world: CombatWorld
var hit_radius := 0.45
var health := 18.0
var _model: Node3D
var _flash := 0.0
var _mat: StandardMaterial3D
const MODELS := [["rompible_vasija", 1.0], ["rompible_suministros", 1.1]]

func setup(p_world: CombatWorld, pos: Vector3) -> Breakable:
	world = p_world
	position = pos
	add_to_group(&"breakable")
	return self

func _ready() -> void:
	var m: Array = MODELS[randi() % MODELS.size()]
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * float(m[1])
	holder.rotation.y = randf() * TAU
	add_child(holder)
	_model = VoxelBuilder.load_model("res://models/%s.json" % m[0])
	holder.add_child(_model)
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = Color(1, 1, 1, 0.8)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	world.add_breakable(self)

func is_alive() -> bool:
	return health > 0.0

func take_damage(d: Damage) -> void:
	if health <= 0.0: return
	health -= d.physical + d.mental
	_flash = 0.08
	if health <= 0.0: _break()

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		for mi: MeshInstance3D in _model.get_meta("meshes"): mi.material_overlay = _mat if _flash > 0.0 else null

func _break() -> void:
	world.remove_breakable(self)
	var fx := DeathBurst.new()
	fx.setup("atrezo_caja", 0.4)
	fx.position = global_position
	world.fx.add_child(fx)
	world.fx.add_child(Pickup.new().setup(world, global_position, Pickup.roll()))
	broken.emit(self)
	queue_free()

# estados de los enemigos: un barril no se aturde ni se maldice
func stun(_s: float) -> void: pass
func make_vulnerable(_s: float) -> void: pass
func lure(_p: Vector3, _s: float) -> void: pass
func slow(_k: float, _s: float) -> void: pass
func weaken(_k: float, _s: float) -> void: pass
func curse(_a = null, _b = null, _c = null, _d = null) -> void: pass
func root(_s: float) -> void: pass
func confuse(_s: float) -> void: pass
func poison(_a = null, _b = null, _c = null) -> void: pass
func stasis(_s: float) -> void: pass
func inject(_a = null, _b = null) -> void: pass
