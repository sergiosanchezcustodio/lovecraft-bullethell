class_name BearTrap
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Cepo de trampero (hito 8.8): queda abierto en el suelo `life` s; el primer enemigo que
## entra en su radio recibe el golpe, queda atrapado `hold` s (las élites solo se frenan) y el
## cepo se cierra y desaparece.

var world: CombatWorld
var radius := 0.7
var life := 12.0
var damage := 20.0
var hold := 2.0
var bonus := {}
var sprung := false
var _t := 0.0
var _model: Node3D

const CLOSE_LIFE := 0.8

func setup(p_world: CombatWorld, pos: Vector3, p_radius: float, p_life: float, p_damage: float, p_hold: float,
		p_bonus: Dictionary) -> BearTrap:
	world = p_world; radius = p_radius; life = p_life; damage = p_damage; hold = p_hold; bonus = p_bonus
	position = Vector3(pos.x, 0.0, pos.z)
	rotation.y = randf() * TAU
	return self

func _ready() -> void:
	_model = VoxelBuilder.load_model("res://models/proj_cepo.json")
	add_child(_model)

func _physics_process(delta: float) -> void:
	_t += delta
	if sprung:
		if _t >= CLOSE_LIFE: queue_free()
		return
	if _t >= life:
		queue_free()
		return
	for e in world.enemies_in_circle(global_position, radius):
		if not e.is_alive(): continue
		Damage.ctx = _wtag
		var d := Damage.new(damage, 0.0)
		d.bonus = bonus
		e.take_damage(d)
		if e.is_alive() and e.has_method("root"): e.root(hold)
		_spring()
		return

func _spring() -> void:
	sprung = true
	_t = 0.0
	Sfx.play("hit")
	_model.queue_free()
	_model = VoxelBuilder.load_model("res://models/proj_cepo_cerrado.json")
	add_child(_model)

func _process(_delta: float) -> void:
	if sprung: _model.scale = Vector3.ONE * (1.0 - smoothstep(CLOSE_LIFE * 0.6, CLOSE_LIFE, _t))
	elif _t > life - 1.0: visible = fmod(_t, 0.25) < 0.15           # parpadea antes de irse
