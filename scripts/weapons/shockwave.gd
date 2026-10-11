class_name Shockwave
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Onda de la fórmula de expulsión: un anillo de luz pálida que se expande desde el
## personaje hasta su radio. Cada enemigo que alcanza recibe el daño una sola vez, sale
## empujado hacia fuera y queda aturdido. Nace donde está el jugador y no le sigue.

var world: CombatWorld
var _radius := 4.5
var _grow := 0.5
var _damage := 10.0
var _push := 4.0
var _stun := 0.8
var _bonus := {}
var _t := 0.0
var _hit := {}                               ## ids ya alcanzados
var _mat: ShaderMaterial
var _disc: MeshInstance3D
var clears := false                          ## Resonador: deshace las balas enemigas que alcanza
var color := COLOR
var cleared := 0                             ## balas deshechas (tests)

const FADE := 0.25
const COLOR := Color(1.0, 0.84, 0.46, 0.95)        # dorado: un blanco pálido se perdía sobre la nieve

func setup(p: Player, p_world: CombatWorld, radius: float, grow: float, damage: float, push: float,
		stun_s: float, bonus: Dictionary) -> Shockwave:
	world = p_world
	_radius = radius; _grow = maxf(grow, 0.05); _damage = damage; _push = push; _stun = stun_s; _bonus = bonus
	position = Vector3(p.global_position.x, 0.0, p.global_position.z)
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	# anillo de celdas con runas que se abre, y polvo levantado hacia fuera (11-10-2026)
	_disc = VoxelFx.ground(3, _radius)
	_disc.position.y = 0.06
	add_child(_disc)
	_mat = _disc.material_override
	_mat.set_shader_parameter("tint", Color(color.r, color.g, color.b))
	var dust := VoxelFx.emitter("ring_dust", _radius, true)
	dust.position.y = 0.1
	add_child(dust)
	_process(0.0)

func current_radius() -> float:
	var u := clampf(_t / _grow, 0.0, 1.0)
	return _radius * (1.0 - pow(1.0 - u, 2.0))

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t > _grow: return
	var r := current_radius()
	if Engine.get_physics_frames() % 3 == 0: world.bullets.clear_enemy_bullets(global_position, r * 0.6)   # la onda aparta balas
	if clears: cleared += world.bullets.clear_enemy_bullets(global_position, r)
	for e in world.enemies_in_circle(global_position, r):
		var id := e.get_instance_id()
		if _hit.has(id): continue
		_hit[id] = true
		var d := Damage.new(_damage, 0.0)
		var away := e.global_position - global_position
		d.knockback = Vector3(away.x, 0, away.z).normalized() * _push
		d.bonus = _bonus
		e.take_damage(d)
		if e.has_method("stun") and e.is_alive(): e.stun(_stun)

func _process(_delta: float) -> void:
	Damage.ctx = _wtag
	_mat.set_shader_parameter("wave_r", maxf(current_radius(), 0.3) / _radius)
	var fade := 1.0 - smoothstep(_grow, _grow + FADE, _t)
	_mat.set_shader_parameter("fade", fade)
	if _t > _grow + FADE + 0.6: queue_free()               # deja acabar el polvo
