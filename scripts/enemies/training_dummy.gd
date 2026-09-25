class_name TrainingDummy
extends Node3D
## Criatura de práctica: recibe daño, parpadea en blanco al impacto, retrocede un poco,
## cae al llegar a cero y reaparece al rato. Sirve para probar las armas antes de que
## lleguen los enemigos del hito 1.5, y como referencia de la interfaz de objetivo.

var kind := "pinguino"
var hit_radius := 0.5
var max_health := 60.0
var health := 60.0
var respawn_time := 2.5
var world: CombatWorld
var model: Node3D
var _flash_mat: StandardMaterial3D
var _flash := 0.0
var _dead_t := -1.0
var _t := 0.0
var _home := Vector3.ZERO

func setup(p_world: CombatWorld, p_kind: String) -> TrainingDummy:
	world = p_world
	kind = p_kind
	hit_radius = {"pinguino": 0.45, "fragmento": 0.55, "acechador": 0.7}.get(kind, 0.5)
	return self

func _ready() -> void:
	model = VoxelBuilder.load_model("res://models/%s.json" % kind)
	add_child(model)
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.albedo_color = Color(1, 1, 1, 0.75)
	_home = position
	_t = randf() * 3.0
	world.add_enemy(self)

func _exit_tree() -> void:
	if world != null: world.remove_enemy(self)

func is_alive() -> bool:
	return health > 0.0

func take_damage(d: Damage) -> void:
	if not is_alive(): return
	health -= d.physical
	_flash = 0.08
	position += Vector3(d.knockback.x, 0, d.knockback.z) * 0.12
	if health <= 0.0:
		_dead_t = 0.0
		visible = false

func _process(delta: float) -> void:
	_t += delta
	if _dead_t >= 0.0:
		_dead_t += delta
		if _dead_t >= respawn_time:
			_dead_t = -1.0
			health = max_health
			position = _home
			visible = true
		return
	position = position.lerp(_home, 1.0 - exp(-2.0 * delta))
	var anim := "idle" if kind == "acechador" else "walk"
	Anims.pose(kind, anim, model, fposmod(_t / Anims.duration(kind, anim), 1.0))
	_flash -= delta
	var overlay: Material = _flash_mat if _flash > 0.0 else null
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = overlay
