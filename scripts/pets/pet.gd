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
var _blend_snap: Array = []                 ## pose de la que se parte al cambiar de animación
var _blend_t := 1.0
var _blend_len := 0.0
var _fidget := ""                           ## gesto de reposo en curso (Anims.fidgets)
var _fidget_t := 0.0
var _still_t := 0.0
var _fidget_at := 4.0
var _last_fidget := ""
const FIDGET_GAP := Vector2(4.0, 9.0)       ## s quieto entre un gesto y el siguiente
var _anim_t := 0.0
var _act_t := -1.0
var _bristle_k := 0.0

## Reacciones (hito 12.9): se esconde detrás de su jugador con un jefe cerca, celebra su subida de
## nivel, gime tumbado junto a él si cae, se olfatea con otros compañeros (el gato le bufa al perro)
## y el cuervo se posa en su hombro cuando está quieto. Las calcula cada PC con lo que ve.
const BOSS_NEAR := 11.0
const BUDDY_NEAR := 4.5                     ## m a los que va a olfatear a otro compañero (con su jugador quieto)
const PERCH_AFTER := 2.0                     ## s quieto su jugador hasta que el cuervo se posa
const CHEER_TIME := 1.0
const MOOD_POSE := {&"hide": "cower", &"mourn": "whine", &"hiss": "hiss", &"perch": "perch"}
var mood := &""                              ## hide, mourn, sniff, hiss, perch o nada
var _shown := &""                            ## la reacción que se ve (funde al cambiar)
var _mood_k := 0.0
var _cheer_t := -1.0
var _buddy: Pet = null
var _owner_still := 0.0
var _boss_t := 0.0
var _boss: Node3D = null
var _perch_k := 0.0
var _ring_mi: MeshInstance3D
var _trail: GPUParticles3D                   ## estela (hito 12.10), si tiene y la calidad la deja
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
	_ring_mi = _ring()
	_visual.add_child(_ring_mi)
	if data.trail != "" and bool(Quality.value("pet_trails", true)):
		_trail = VoxelFx.emitter("pet_" + data.trail, 0.18, false, false, data.trail_color)
		_trail.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_visual.add_child(_trail)
	behavior.start()
	owner_player.progress.leveled_up.connect(func(_l: int) -> void:
		behavior.leveled()
		_cheer_t = 0.0)
	add_to_group("pets")
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
	var d := Damage.new((data.attack_at(level()) if dmg < 0.0 else dmg) * owner_player.data.pet_mult, 0.0)
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
	if owner_player != null: Damage.ctx = StringName("J%d:mascota" % (owner_player.index + 1))
	if not is_instance_valid(owner_player): return
	cooldown -= delta
	target = null
	var home := owner_player.global_position
	var side := facing_of_owner().cross(Vector3.UP)
	goal = home - facing_of_owner() * data.follow_gap + side * 0.9 * signf(data.follow_gap)
	# se da prisa cuanto más lejos está: un poco más rápido que el jugador cuando lo sigue
	var far := clampf((global_position.distance_to(home) - 2.0) / 3.0, 0.0, 1.0)
	speed = owner_player.data.move_speed * (1.1 + 0.9 * far) * owner_player.data.pet_mult   # Silbato de Lake
	if not Pacts.has("pet_idle"): behavior.step(delta)   # Solo ante el horror (hito 13.6): solo sigue
	_react(delta)
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
	if world != null and world.obstacles != null and data.fly_height <= 0.0:   # los que vuelan pasan por encima
		var p2 := world.obstacles.push_out(Vector2(position.x, position.z), 0.3)
		position.x = p2.x; position.z = p2.y
	if (mood == &"sniff" or mood == &"hiss") and is_instance_valid(_buddy) and _velocity.length() < 0.4:
		var b := _buddy.global_position - global_position
		b.y = 0.0
		if b.length() > 0.01: facing = facing.slerp(b.normalized(), 1.0 - exp(-8.0 * delta)).normalized()
	elif _velocity.length() > 0.2: facing = facing.slerp(_velocity.normalized(), 1.0 - exp(-12.0 * delta)).normalized()
	elif target != null and is_instance_valid(target):
		var f := target.global_position - global_position
		f.y = 0.0
		if f.length() > 0.01: facing = f.normalized()

## Elige la reacción de este paso y, si hace falta, adónde ir. No interrumpe lo que hace su
## comportamiento (atacar, embestir, esconderse bajo tierra).
func _react(delta: float) -> void:
	mood = &""
	_owner_still = _owner_still + delta if owner_player.motor.velocity.length() < 0.3 else 0.0
	_boss_t -= delta
	if _boss_t <= 0.0:
		_boss_t = 0.25
		_boss = _boss_near(owner_player.global_position)
	if target != null or rush or hidden: return
	var home := owner_player.global_position
	if owner_player.health <= 0.0:
		mood = &"mourn"
		goal = home + facing_of_owner().cross(Vector3.UP) * 0.7
		return
	if is_instance_valid(_boss):
		mood = &"hide"
		var away := home - _boss.global_position
		away.y = 0.0
		goal = home + away.normalized() * 0.9
		speed = maxf(speed, owner_player.data.move_speed * 1.6)
		return
	if data.model == "cuervo" and _owner_still > PERCH_AFTER:
		mood = &"perch"
		goal = home
		return
	_buddy = _buddy_near() if _owner_still > 1.0 else null
	if _buddy != null:                           # se acerca a olfatearlo (o a bufarle, a distancia)
		mood = &"hiss" if data.model == "gato" and _buddy.data.model == "perro" else &"sniff"
		var gap := 1.4 if mood == &"hiss" else 0.7
		var off := global_position - _buddy.global_position
		off.y = 0.0
		goal = _buddy.global_position + off.normalized() * gap if off.length() > 0.01 else global_position
		speed = minf(speed, owner_player.data.move_speed * 0.6)

func _boss_near(home: Vector3) -> Node3D:
	if world == null: return null
	for e in world.enemies:
		if is_instance_valid(e) and e.data.unique and e.is_alive() and e.global_position.distance_to(home) < BOSS_NEAR: return e
	return null

func _buddy_near() -> Pet:
	for p in get_tree().get_nodes_in_group("pets"):
		if p != self and not (p as Pet).hidden and (p as Pet).global_position.distance_to(global_position) < BUDDY_NEAR: return p
	return null

## Las reacciones encima de la pose: la de su familia si la tiene (cower, whine, hiss, perch,
## cheer en su script de animación) o una genérica (agacharse, saltar).
func _react_pose(delta: float) -> float:
	var t := Time.get_ticks_msec() * 0.001
	if mood != _shown:
		_mood_k = move_toward(_mood_k, 0.0, delta * 4.0)
		if _mood_k <= 0.0: _shown = mood
	elif mood != &"":
		_mood_k = move_toward(_mood_k, 1.0, delta * 4.0)
	var s := Anims.script_for(data.model)
	var k := Anims.ease(_mood_k)
	var fly_k := 1.0
	if _shown != &"" and k > 0.0 and MOOD_POSE.has(_shown):
		var fn: String = MOOD_POSE[_shown]
		if s != null and s.has_method(fn): s.call(fn, _model, k, t)
		elif _shown == &"hide" or _shown == &"mourn": _model.scale.y *= 1.0 - 0.18 * k
		if _shown == &"hide": fly_k = 1.0 - 0.55 * k             # los que vuelan, bajos y pegados a él
		elif _shown == &"mourn": fly_k = 1.0 - k                  # en el suelo, a su lado
	if _cheer_t >= 0.0:
		_cheer_t += delta
		var c := clampf(_cheer_t / CHEER_TIME, 0.0, 1.0)
		var ck := minf(1.0, minf(c, 1.0 - c) * 8.0)
		if s != null and s.has_method("cheer"): s.call("cheer", _model, ck, c)
		else: _model.position.y += 0.15 * absf(sin(c * TAU)) * ck
		if _cheer_t >= CHEER_TIME: _cheer_t = -1.0
	return fly_k

## Gestos de reposo: tras unos segundos quieto, olfatea, se lame una pata, se acicala…
## (Anims.fidgets), sin repetir el anterior. Moverse o atacar lo corta.
func _fidget_step(anim: String, delta: float) -> String:
	if anim != "idle" or hidden:
		_still_t = 0.0
		_fidget = ""
		_fidget_at = randf_range(FIDGET_GAP.x, FIDGET_GAP.y)
		return anim
	_still_t += delta
	if _fidget == "" and _still_t >= _fidget_at:
		var pool := Anims.fidgets(data.model).filter(func(f: String) -> bool: return f != _last_fidget)
		if not pool.is_empty():
			_fidget = pool[randi() % pool.size()]
			_last_fidget = _fidget
			_fidget_t = 0.0
		_fidget_at = _still_t + randf_range(FIDGET_GAP.x, FIDGET_GAP.y)
	if _fidget == "": return anim
	_fidget_t += delta
	if _fidget_t >= Anims.duration(data.model, _fidget):
		_fidget = ""
		_fidget_at = _still_t + randf_range(FIDGET_GAP.x, FIDGET_GAP.y)
		return anim
	return _fidget

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
	anim = _fidget_step(anim, delta)
	if mood == &"sniff" and anim == "idle" and Anims.has_anim(data.model, "fidget_sniff"): anim = "fidget_sniff"
	if anim != _anim:
		_blend_snap = Anims.snapshot(_model)               # funde desde la pose de ahora
		_blend_t = 0.0
		_blend_len = 0.08 if anim == "bite" else 0.2
		_anim = anim
		_anim_t = 0.0
	var dur := Anims.duration(data.model, anim)
	if anim == "bite": _anim_t = clampf(_act_t / dur, 0.0, 1.0)
	elif anim == _fidget and _fidget != "": _anim_t = clampf(_fidget_t / dur, 0.0, 1.0)
	else: _anim_t = fposmod(_anim_t + delta / dur * (clampf(v / 2.5, 0.6, 1.6) if anim != "idle" else 1.0), 1.0)
	Anims.pose(data.model, anim, _model, _anim_t)
	if _blend_t < _blend_len:
		_blend_t += delta
		Anims.blend_from(_model, _blend_snap, Anims.ease(_blend_t / _blend_len))
	var fly_k := _react_pose(delta)
	_model.position.y += fly * fly_k            # la animación pone la raíz; el vuelo y el erizado van encima
	_model.scale *= 1.0 + 0.15 * maxf(_bristle_k, 0.5 * Anims.ease(_mood_k) if _shown == &"hiss" else 0.0)
	_perch_step(delta, p + Vector3(0, fly * fly_k, 0))
	_trail_step(v)

## La estela: sale de donde va el cuerpo (en vuelo, a su altura) y más cuanto más deprisa va. Las
## plumas solo al aletear (moviéndose o celebrando), no posado; las chispas y el polvo, siempre
## algo; la bruma, sobre todo al moverse.
func _trail_step(v: float) -> void:
	if _trail == null: return
	_trail.position = _model.position + Vector3(0.0, 0.2, 0.0)
	var run := clampf(v / maxf(0.1, owner_player.data.move_speed), 0.0, 1.5)
	var r := 0.0
	match data.trail:
		"feathers": r = 0.0 if _perch_k > 0.0 else clampf(run * 0.6 + (0.8 if _cheer_t >= 0.0 else 0.0), 0.0, 1.0)
		"sparks", "dust": r = 0.35 + 0.65 * minf(run, 1.0)
		"mist": r = 0.45 + 0.55 * minf(run, 1.0)
	_trail.emitting = r > 0.02 and not hidden
	_trail.amount_ratio = clampf(r, 0.0, 1.0)

## El cuervo en el hombro derecho de su jugador: vuela hasta él, se posa mirando hacia donde
## mira el jugador y se va al echar a andar.
func _perch_step(delta: float, free_pos: Vector3) -> void:
	_perch_k = move_toward(_perch_k, 1.0 if mood == &"perch" else 0.0, delta * 2.0)
	if _ring_mi: _ring_mi.visible = _perch_k < 0.5
	if _perch_k <= 0.0 or owner_player.model == null: return
	var parts: Dictionary = owner_player.model.get_meta("part_nodes")
	if not parts.has("arm_r"): return
	var shoulder := (parts["arm_r"] as Node3D).global_position
	var out := shoulder - (parts["torso"] as Node3D).global_position     # hacia fuera, lejos de la cabeza
	out.y = 0.0
	shoulder += out.normalized() * 0.07 + Vector3(0.0, 0.07, 0.0)
	var k := Anims.ease(_perch_k)
	var arc := sin(k * PI) * 0.35                    # llega en un pequeño arco
	_visual.global_position = free_pos.lerp(shoulder, k) + Vector3(0.0, arc, 0.0)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, owner_player.visual.rotation.y, k)
	_model.position.y -= data.fly_height * lift * k   # la altura de vuelo ya va en la posición
	_model.scale *= lerpf(1.0, 0.7, k)               # en el hombro, algo más pequeño (tapaba la cabeza)
