class_name Enemy
extends Node3D
## Enemigo genérico: se configura con un EnemyData. Movimiento según su comportamiento,
## separación del resto, rodeo de obstáculos, daño por contacto, ataque a distancia con
## su patrón, destello y retroceso al recibir daño, y muerte con efecto.
## Cumple la interfaz de objetivo de CombatWorld (hit_radius, take_damage, is_alive).

signal died(enemy: Enemy)

var data: EnemyData
var world: CombatWorld
var obstacles: ObstacleMap
var behavior: EnemyBehavior
var model: Node3D
var visual: Node3D
var runner: PatternRunner
var hit_radius := 0.5
var health := 1.0
var velocity := Vector3.ZERO
var facing := Vector3(0, 0, 1)
var anim := "walk"
var anim_t := 0.0                        ## fase de la animación (0..1)
var anim_hold := false                   ## el comportamiento controla anim_t directamente
var _knock := Vector3.ZERO
var _flash := 0.0
var _flash_on := false
var _flash_mat: StandardMaterial3D
var _attack_timer := 0.0
var _spawn_t := 0.0

func setup(p_data: EnemyData, p_world: CombatWorld, p_obstacles: ObstacleMap) -> Enemy:
	data = p_data
	world = p_world
	obstacles = p_obstacles
	hit_radius = data.hit_radius
	health = data.max_health
	behavior = EnemyBehavior.create(data.movement)
	name = String(data.id)
	return self

func _ready() -> void:
	visual = Node3D.new()
	# Se anima en _process (sin interpolación) y va suelto: en cada fotograma se coloca en la
	# posición interpolada del cuerpo (dentro de él se dibujaría a saltos; ver Player).
	visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visual.top_level = true
	add_child(visual)
	model = VoxelBuilder.load_model("res://models/%s.json" % data.model)
	visual.add_child(model)
	runner = PatternRunner.new().setup(world)
	runner.position.y = 0.6
	add_child(runner)
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.albedo_color = Color(1, 1, 1, 0.75)
	_attack_timer = data.attack_cooldown * randf_range(0.5, 1.0)
	anim_t = randf()
	behavior.start(self)
	world.add_enemy(self)
	reset_physics_interpolation.call_deferred()

func _exit_tree() -> void:
	if world != null: world.remove_enemy(self)

func is_alive() -> bool:
	return health > 0.0

## Jugador vivo más cercano, o null.
func target_player() -> Player:
	var best: Player = null
	var best_d := INF
	for p in world.players:
		if p.health <= 0.0: continue
		var d := p.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = p
	return best

func take_damage(d: Damage) -> void:
	if not is_alive(): return
	health -= d.physical
	_flash = 0.07
	_knock += Vector3(d.knockback.x, 0, d.knockback.z) * (2.5 if not data.elite else 0.6)
	if health <= 0.0: _die()

func _die() -> void:
	var fx := DeathBurst.new()
	fx.setup(data.model, data.body_radius)
	fx.position = global_position
	world.fx.add_child(fx)
	died.emit(self)
	queue_free()

func _physics_process(delta: float) -> void:
	if not is_alive(): return
	var t0 := Prof.start()
	_spawn_t += delta
	var target := target_player()
	velocity = behavior.update(self, target, delta)
	# Separación: no amontonarse con los enemigos cercanos
	var pos2 := Vector2(global_position.x, global_position.z)
	var push := Vector2.ZERO
	for id in world.grid.query_circle(pos2, data.body_radius):
		var other := world.target_at(id)
		if other == self: continue
		var off := pos2 - Vector2(other.global_position.x, other.global_position.z)
		var dist := off.length()
		var min_d: float = data.body_radius + float(other.hit_radius)
		if dist > 0.001 and dist < min_d: push += off / dist * (min_d - dist)
	var move := velocity * delta + _knock * delta + Vector3(push.x, 0, push.y) * 0.5
	_knock = _knock.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))
	var np := Vector2(position.x + move.x, position.z + move.z)
	if obstacles != null: np = obstacles.push_out(np, data.body_radius)
	position = Vector3(np.x, position.y, np.y)
	if velocity.length() > 0.1:
		facing = facing.slerp(velocity.normalized(), 1.0 - exp(-10.0 * delta)).normalized()
	# Contacto con los jugadores
	for p in world.players:
		var r := data.body_radius + p.data.hurt_radius
		var pp := p.global_position
		if Vector2(pp.x - position.x, pp.z - position.z).length_squared() < r * r:
			p.take_damage(behavior.contact_damage(self))
	# Ataque a distancia
	if data.attack != null and target != null and behavior.can_shoot(self):
		_attack_timer -= delta
		if _attack_timer <= 0.0 and not runner.busy and target.global_position.distance_to(global_position) < data.attack_range:
			runner.fire(data.attack, func() -> Vector3: return target.global_position if is_instance_valid(target) else global_position)
			if data.attack_anim != "": behavior.play_attack_anim(self, data.attack_anim)
			_attack_timer = data.attack_cooldown * randf_range(0.85, 1.15)
	Prof.stop("enemigos_fisica", t0)

func _process(delta: float) -> void:
	var t0 := Prof.start()
	visual.global_position = get_global_transform_interpolated().origin
	visual.rotation.y = atan2(facing.x, facing.z)
	visual.scale = Vector3.ONE * clampf(_spawn_t / 0.35, 0.2, 1.0)       # aparece creciendo
	if not anim_hold:
		anim_t = fposmod(anim_t + delta / Anims.duration(data.model, anim), 1.0)
	Anims.pose(data.model, anim, model, anim_t)
	_flash -= delta
	var flashing := _flash > 0.0
	if flashing != _flash_on:          # solo se toca el material al cambiar
		_flash_on = flashing
		for mi: MeshInstance3D in model.get_meta("meshes"):
			mi.material_overlay = _flash_mat if flashing else null
	Prof.stop("enemigos_anim", t0)
