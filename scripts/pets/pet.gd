class_name Pet
extends Node3D
## Compañero en partida (D-20, D-36): acompaña a su jugador toda la partida y sube de nivel
## con él. Aquí va lo común (seguirlo, volar, animarse); lo que hace cada uno está en su
## comportamiento (`PetBehavior.make(data.kind)`, en scripts/pets/behaviors/).
## No recibe daño ni lo buscan los enemigos (no está en CombatWorld).

var data: PetData
var owner_player: Player
var world: CombatWorld
var game: Node                               ## la partida (dólares, director); puede faltar en tests
var behavior: PetBehavior
var hits := 0                                ## ataques o balas comidas (tests)
var found_money := 0                         ## dólares encontrados (rata)
var facing := Vector3.FORWARD
var goal := Vector3.ZERO                     ## adónde va este paso (el comportamiento lo cambia)
var speed := 0.0
var target: Node3D = null                    ## a quién mira
var cooldown := 0.0
var bristle := 0.0                           ## 1 = erizado (gato enfadado)
var lift := 1.0                              ## fracción de la altura de vuelo (0 = en el suelo: picado)
var hidden := false                          ## bajo tierra (dhole): no se dibuja
var rush := false                            ## embestida: va a `speed` sin frenar al acercarse
var _model: Node3D
var _visual: Node3D
var _velocity := Vector3.ZERO
var _anim := "idle"
var _anim_t := 0.0
var _act_t := -1.0
var _bristle_k := 0.0

const LEASH := 8.0                           ## más lejos del jugador que esto, deja lo que hace

func setup(p_data: PetData, p_owner: Player, p_world: CombatWorld, p_game: Node = null) -> Pet:
	data = p_data
	owner_player = p_owner
	world = p_world
	game = p_game
	name = "Pet_%s" % data.id
	position = p_owner.global_position + Vector3(-1.2, 0, -0.6)
	behavior = PetBehavior.make(data.kind)
	behavior.pet = self
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
	behavior.start()
	owner_player.progress.leveled_up.connect(func(_l: int) -> void: behavior.leveled())
	reset_physics_interpolation.call_deferred()

## Anillo fino del color de su jugador, en el suelo: se ve a quién acompaña y dónde está.
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
	mi.set_meta("ground", true)
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

## Ataca (o traga, o escarba): pone la animación de ataque.
func act() -> void:
	_act_t = 0.0

## Golpe con los datos del compañero: daño (por defecto el de su nivel), empuje desde él y
## aturdimiento.
func strike(e: Node3D, dmg := -1.0) -> void:
	if e == null or not is_instance_valid(e) or not e.is_alive(): return
	var d := Damage.new(data.attack_at(level()) if dmg < 0.0 else dmg, 0.0)
	var away := e.global_position - global_position
	away.y = 0.0
	d.knockback = (away.normalized() if away.length() > 0.01 else facing) * data.knockback
	d.bonus = owner_player.data.bonus_tags
	e.take_damage(d)
	if data.stun > 0.0 and e.is_alive() and e.has_method("stun"): e.stun(data.stun)
	hits += 1

## Aparece de golpe en otro sitio (araña de Tíndalos, dhole).
func teleport(pos: Vector3) -> void:
	global_position = Vector3(pos.x, 0.0, pos.z)
	_velocity = Vector3.ZERO
	reset_physics_interpolation()

## Aviso flotante sobre el compañero ("+12 $").
func popup(text: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.8)
	l.font_size = 40
	l.outline_size = 10
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = global_position + Vector3(0, 1.0 + data.fly_height, 0)
	(world.fx if world != null else get_parent()).add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.8, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.tween_callback(l.queue_free)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_player): return
	cooldown -= delta
	target = null
	var home := owner_player.global_position
	var side := facing_of_owner().cross(Vector3.UP)
	goal = home - facing_of_owner() * data.follow_gap + side * 0.9 * signf(data.follow_gap)
	# se da prisa cuanto más lejos está: un poco más rápido que el jugador cuando lo sigue
	var far := clampf((global_position.distance_to(home) - 2.0) / 3.0, 0.0, 1.0)
	speed = owner_player.data.move_speed * (1.1 + 0.9 * far)
	behavior.step(delta)
	var to := goal - global_position
	to.y = 0.0
	var stop := 0.5 if target != null else 0.35
	if rush:
		_velocity = to.normalized() * speed if to.length() > 0.05 else Vector3.ZERO
	elif to.length() > stop and speed > 0.0:
		_velocity = _velocity.lerp(to.normalized() * speed * clampf(to.length() / 1.5, 0.3, 1.0), 1.0 - exp(-10.0 * delta))
	else:
		_velocity = _velocity.lerp(Vector3.ZERO, 1.0 - exp(-12.0 * delta))
	if global_position.distance_to(home) > LEASH * 2.0 and not rush:          # se quedó muy atrás: aparece junto a él
		global_position = goal
		_velocity = Vector3.ZERO
	position += _velocity * delta
	position.y = 0.0
	if _velocity.length() > 0.2: facing = facing.slerp(_velocity.normalized(), 1.0 - exp(-12.0 * delta)).normalized()
	elif target != null and is_instance_valid(target):
		var f := target.global_position - global_position
		f.y = 0.0
		if f.length() > 0.01: facing = f.normalized()

func facing_of_owner() -> Vector3:
	return owner_player.motor.facing

func _process(delta: float) -> void:
	if _model == null: return
	var p := get_global_transform_interpolated().origin
	_visual.visible = not hidden
	var fly := data.fly_height * lift
	if fly > 0.0: fly += sin(Time.get_ticks_msec() * 0.0025) * 0.08 * lift    # flota
	_visual.global_position = p
	_visual.rotation.y = atan2(facing.x, facing.z)
	_bristle_k = move_toward(_bristle_k, bristle, delta * 6.0)
	var anim := "idle"
	var v := _velocity.length()
	if _act_t >= 0.0:
		anim = "bite"
		_act_t += delta
		if _act_t >= Anims.duration(data.model, "bite"): _act_t = -1.0
	elif v > owner_player.data.move_speed * 1.2: anim = "run"
	elif v > 0.3: anim = "walk"
	if anim != _anim:
		_anim = anim
		_anim_t = 0.0
	var dur := Anims.duration(data.model, anim)
	if anim == "bite": _anim_t = clampf(_act_t / dur, 0.0, 1.0)
	else: _anim_t = fposmod(_anim_t + delta / dur * (clampf(v / 2.5, 0.6, 1.6) if anim != "idle" else 1.0), 1.0)
	Anims.pose(data.model, anim, _model, _anim_t)
	_model.position.y += fly                    # la animación pone la raíz; el vuelo y el erizado van encima
	_model.scale *= 1.0 + 0.15 * _bristle_k
