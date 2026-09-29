class_name Pet
extends Node3D
## Compañero en partida (D-20, hito 2.13c): acompaña a su jugador toda la partida y sube de
## nivel con él.
## - Perro de trineo (`kind = BITE`): sigue al jugador y, si hay un enemigo cerca de él,
##   corre a morderlo; no se aleja demasiado. El mordisco crece con el nivel del jugador.
## - Gato de Ulthar (`kind = WARD`): se queda a su lado y le quita parte del daño mental
##   (`Player.mental_resist`), más cuanto más nivel.
## No recibe daño ni lo buscan los enemigos (no está en CombatWorld).

var data: PetData
var owner_player: Player
var world: CombatWorld
var bites := 0                               ## mordiscos dados (tests)
var _model: Node3D
var _visual: Node3D
var _facing := Vector3.FORWARD
var _velocity := Vector3.ZERO
var _anim := "idle"
var _anim_t := 0.0
var _bite_t := -1.0
var _cooldown := 0.0
var _target: Node3D = null

const FOLLOW_GAP := 1.6                     ## se pone a esta distancia del jugador
const HUNT_RADIUS := 5.5                    ## enemigos a esta distancia del jugador: a por ellos
const LEASH := 8.0                          ## más lejos del jugador que esto, vuelve

func setup(p_data: PetData, p_owner: Player, p_world: CombatWorld) -> Pet:
	data = p_data
	owner_player = p_owner
	world = p_world
	name = "Pet_%s" % data.id
	position = p_owner.global_position + Vector3(-1.2, 0, -0.6)
	return self

func _ready() -> void:
	_visual = Node3D.new()
	_visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_visual.top_level = true
	add_child(_visual)
	if data.model != "":
		_model = VoxelBuilder.load_model("res://models/%s.json" % data.model)
		_visual.add_child(_model)
	_visual.add_child(_ring())
	if data.kind == PetData.Kind.WARD: _apply_ward()
	owner_player.progress.leveled_up.connect(func(_l: int) -> void: _apply_ward())
	reset_physics_interpolation.call_deferred()

## Anillo fino del color de su jugador: se ve a quién acompaña y dónde está.
func _ring() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.34
	tm.outer_radius = 0.4
	tm.rings = 24
	tm.ring_segments = 4
	mi.mesh = tm
	mi.scale = Vector3(1, 0.08, 1)
	mi.position.y = 0.03
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(owner_player.color, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Nivel del compañero: el de su jugador.
func level() -> int:
	return owner_player.progress.level

## Gato: fracción del daño mental que recibe el jugador (menos cuanto más nivel).
func ward_factor() -> float:
	return 1.0 - minf(data.ward + data.ward_per_level * (level() - 1), data.ward_max)

func _apply_ward() -> void:
	if data.kind == PetData.Kind.WARD: owner_player.mental_resist = ward_factor()

func bite_damage() -> float:
	return data.bite_damage + data.bite_per_level * (level() - 1)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_player): return
	_cooldown -= delta
	var home := owner_player.global_position
	var goal := home - owner_player.motor.facing * FOLLOW_GAP + owner_player.motor.facing.cross(Vector3.UP) * 0.9
	# se da prisa cuanto más lejos está: un poco más rápido que el jugador cuando lo sigue
	var far := clampf((global_position.distance_to(home) - 2.0) / 3.0, 0.0, 1.0)
	var speed := owner_player.data.move_speed * (1.1 + 0.9 * far)
	if data.kind == PetData.Kind.BITE:
		if _target == null or not is_instance_valid(_target) or not _target.is_alive() \
				or _target.global_position.distance_to(home) > LEASH:
			_target = world.nearest_enemy(home, HUNT_RADIUS) if world != null else null
		if _target != null and global_position.distance_to(home) < LEASH:
			goal = _target.global_position
			speed = owner_player.data.move_speed * 1.45
			var reach := float(_target.hit_radius) + 0.55
			if global_position.distance_to(_target.global_position) <= reach and _cooldown <= 0.0:
				_bite()
	var to := goal - global_position
	to.y = 0.0
	var stop := 0.5 if _target != null else 0.35
	if to.length() > stop:
		_velocity = _velocity.lerp(to.normalized() * speed * clampf(to.length() / 1.5, 0.3, 1.0), 1.0 - exp(-10.0 * delta))
	else:
		_velocity = _velocity.lerp(Vector3.ZERO, 1.0 - exp(-12.0 * delta))
	if global_position.distance_to(home) > LEASH * 2.0:          # se quedó muy atrás: aparece junto a él
		global_position = goal
		_velocity = Vector3.ZERO
	position += _velocity * delta
	position.y = 0.0
	if _velocity.length() > 0.2: _facing = _facing.slerp(_velocity.normalized(), 1.0 - exp(-12.0 * delta)).normalized()
	elif _target != null: _facing = (_target.global_position - global_position).normalized()

func _bite() -> void:
	_cooldown = data.bite_every
	_bite_t = 0.0
	var d := Damage.new(bite_damage(), 0.0)
	d.knockback = _facing * 0.8
	d.bonus = owner_player.data.bonus_tags
	_target.take_damage(d)
	bites += 1

func _process(delta: float) -> void:
	if _model == null: return
	_visual.global_position = get_global_transform_interpolated().origin
	_visual.rotation.y = atan2(_facing.x, _facing.z)
	var anim := "idle"
	var v := _velocity.length()
	if _bite_t >= 0.0:
		anim = "bite"
		_bite_t += delta
		if _bite_t >= Anims.duration(data.model, "bite"): _bite_t = -1.0
	elif v > owner_player.data.move_speed * 1.2: anim = "run"
	elif v > 0.3: anim = "walk"
	if anim != _anim:
		_anim = anim
		_anim_t = 0.0
	var dur := Anims.duration(data.model, anim)
	_anim_t = (_bite_t / dur) if anim == "bite" else fposmod(_anim_t + delta / dur * (clampf(v / 2.5, 0.6, 1.6) if anim != "idle" else 1.0), 1.0)
	Anims.pose(data.model, anim, _model, _anim_t)
