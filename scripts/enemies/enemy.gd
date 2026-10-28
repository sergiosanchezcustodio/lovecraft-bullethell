class_name Enemy
extends Node3D
## Enemigo genérico: se configura con un EnemyData. Movimiento según su comportamiento,
## separación del resto, rodeo de obstáculos, daño por contacto, ataque a distancia con
## su patrón, destello y retroceso al recibir daño, y muerte con efecto.
## Cumple la interfaz de objetivo de CombatWorld (hit_radius, take_damage, is_alive).

signal died(enemy: Enemy)

var data: EnemyData
## Marioneta (hito 9.3a): en el PC de un invitado, el enemigo solo se dibuja. No piensa, no
## ataca y no pierde vida: su posición, animación y estado llegan del anfitrión (NetGame).
var puppet := false
var world: CombatWorld
var obstacles: ObstacleMap
var behavior: EnemyBehavior
var model: Node3D
var model_name := ""                        ## modelo que lleva ahora (el mimético cambia de forma)
var model_scale := 1.0
var visual: Node3D
var runner: PatternRunner
var hit_radius := 0.5
var health := 1.0
var health_scale := 1.0                  ## multiplicador de vida (cooperativo): vida máxima = data.max_health × esto
var shield_t := 0.0
var _path_t := 0.0                      ## s hasta volver a mirar si hay línea libre al jugador
var _stuck_ref := Vector2.INF               ## dónde estaba en la última comprobación de atasco
var _stuck_t := 0.0
var _detour_t := 0.0                         ## s yendo por el flujo aunque haya línea libre (se atascó)
var _path_clear := true                      ## s de invulnerabilidad (cambio de fase de un jefe)
var velocity := Vector3.ZERO
var facing := Vector3(0, 0, 1)
var anim := "walk"
var anim_t := 0.0                        ## fase de la animación (0..1)
var anim_hold := false                   ## el comportamiento controla anim_t directamente
var _knock := Vector3.ZERO
var _stun := 0.0                            ## s que le quedan aturdido (no se mueve ni ataca)
var _vulnerable := 0.0                      ## s que recibe +25 % de daño (ácido)
var _lure_t := 0.0                          ## s que le atrae una bengala
var _lure_pos := Vector3.ZERO
const VULNERABLE_MULT := 1.25
# Arsenal II (hito 2.7)
var giant: GiantMoves                        ## salto y erupciones de los grandes (o null)
var pace_mult := 1.0                         ## dificultad: los de cuerpo a cuerpo, más rápidos
var anchored := false                       ## no se mueve ni lo empujan (Dagon, en la orilla)
var _wade := 0.0                            ## 0..1: metido en agua somera (hunde el modelo)
var _slow_t := 0.0                          ## s que va más lento (Polvo de Ibn-Ghazi)
var _slow_k := 1.0                          ## factor de velocidad mientras dura
var _weak_t := 0.0                          ## s que hace menos daño (Polvo de Ibn-Ghazi)
var _weak_k := 1.0
var _stasis_t := 0.0                        ## s congelado en el tiempo (Rayo de Yith)
var _stasis_store := 0.0                    ## daño recibido durante la estasis, aplazado
var _curse_t := 0.0                         ## s maldito (Daga ritual): daño continuo
var _curse := {}                            ## {len, dps, spread, bonus}: para contagiarla al morir
var _curse_tick := 0.0
const STASIS_MULT := 1.5                    ## el daño aplazado sale un 50 % mayor
const CURSE_TICK := 0.5
const CURSE_JUMP := 3.5                     ## m a los que salta la maldición
var _root_t := 0.0                          ## s inmóvil (red de pesca); puede seguir atacando
var _inject_t := 0.0                        ## s con el suero de West dentro
var _ally_time := 0.0                       ## s que se levanta como aliado si muere inyectado
var _inject_bonus := {}
const INJECT_TIME := 4.0
# Compañeros (hito 2.15, D-36)
var _poison_t := 0.0                        ## s envenenado (serpiente de Yig): daño continuo
var _poison_dps := 0.0
var _poison_bonus := {}
var _poison_tick := 0.0
var _burn_t := 0.0                          ## s ardiendo (objetos y armas de fuego vivo)
var _burn_dps := 0.0
var _burn_bonus := {}
var _burn_tag := &""
var _burn_tick := 0.0
var _madden_t := 0.0                        ## s enloquecido (Signo Amarillo): ataca a los suyos
var _madden_dps := 0.0
var _madden_hit := 0.0
var _madden_tag := &""
var _madden_bonus := {}
var _confuse_t := 0.0                       ## s confundido (polilla de Leng): vaga sin rumbo y no dispara
var _wander := Vector3.ZERO
var _wander_t := 0.0
var _status_mat: StandardMaterial3D         ## tinte de la estasis o la maldición
var _overlay: Material = null               ## el que lleva puesto el modelo ahora
var _aura: MeshInstance3D                   ## presencia: disco violeta en el suelo
var _aura_mat: ShaderMaterial
var _flash := 0.0
var _flash_on := false
var _flash_mat: StandardMaterial3D
const HIT_POSE := 0.22                      ## s que dura el aplastado y la inclinación al recibir un golpe (hito 11.2)
var _hit_t := HIT_POSE
var _hit_dir := Vector3.ZERO
var _ripple_from := Vector3.INF            ## dónde dejó la última onda en el agua (hito 11.4)
var _top_h := -1.0                          ## altura del modelo sin escalar (números de daño); -1, sin medir
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

## Semitransparente y sin sombra (pesadillas): copia el material de cada malla con alfa.
static func _make_ethereal(m: Node3D) -> void:
	for mi: MeshInstance3D in m.get_meta("meshes"):
		var mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.7
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Cambia de forma (shoggoth mimético): otro modelo y otra escala, con un destello.
func swap_model(new_model: String, new_scale: float = 1.0) -> void:
	if model != null: model.queue_free()
	model_name = new_model
	model_scale = new_scale
	model = VoxelBuilder.load_model("res://models/%s.json" % model_name)
	visual.add_child(model)
	_spawn_t = 0.0                                 # vuelve a crecer desde pequeño
	anim_t = 0.0
	_top_h = -1.0

func _ready() -> void:
	visual = Node3D.new()
	# Se anima en _process (sin interpolación) y va suelto: en cada fotograma se coloca en la
	# posición interpolada del cuerpo (dentro de él se dibujaría a saltos; ver Player).
	visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visual.top_level = true
	add_child(visual)
	model_name = data.model
	model_scale = data.model_scale
	model = VoxelBuilder.load_model("res://models/%s.json" % model_name)
	visual.add_child(model)
	if data.ethereal: _make_ethereal(model)
	runner = PatternRunner.new().setup(world)
	if GiantMoves.applies(data) and not puppet:
		giant = GiantMoves.new()
		runner.over_walls = true
	if data.attack == null: pace_mult = Difficulty.melee_speed()
	runner.position.y = 0.6
	add_child(runner)
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.albedo_color = Color(1, 1, 1, 0.75 if int(Auto.setting("flashes", 1)) == 1 else 0.2)   # accesibilidad
	_attack_timer = data.attack_cooldown * randf_range(0.5, 1.0)
	anim_t = randf()
	if data.aura_drain > 0.0 and data.aura_radius > 0.0: _make_aura()
	if puppet: anim_hold = true                # la fase de la animación llega con cada foto
	else: behavior.start(self)
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

## Vulnerable (+25 % de daño) durante `seconds`.
func make_vulnerable(seconds: float) -> void:
	_vulnerable = maxf(_vulnerable, seconds)

## Atraído hacia un punto (bengala) durante `seconds`. Las élites no se dejan engañar.
func lure(pos: Vector3, seconds: float) -> void:
	if data.elite: return
	_lure_pos = pos
	_lure_t = maxf(_lure_t, seconds)

func is_vulnerable() -> bool:
	return _vulnerable > 0.0

## Más lento durante `seconds`: la velocidad pasa a `factor` (las élites, la mitad de efecto).
func slow(seconds: float, factor: float) -> void:
	_slow_t = maxf(_slow_t, seconds)
	_slow_k = lerpf(1.0, factor, 0.5 if data.elite else 1.0)

## Debilitado durante `seconds`: su contacto y sus balas hacen `factor` del daño.
func weaken(seconds: float, factor: float) -> void:
	_weak_t = maxf(_weak_t, seconds)
	_weak_k = factor

## Congelado en el tiempo (las élites, la mitad): ni se mueve ni ataca, y el daño que recibe
## se guarda y se aplica al terminar, un 50 % mayor.
func stasis(seconds: float) -> void:
	if _stasis_t > 0.0: return
	_stasis_t = seconds * (0.5 if data.elite else 1.0)
	_stasis_store = 0.0

func in_stasis() -> bool:
	return _stasis_t > 0.0

## Maldito durante `seconds`: pierde `dps` por segundo y, si muere así, la maldición salta a
## los `spread` enemigos más cercanos.
func curse(seconds: float, dps: float, spread: int, bonus: Dictionary = {}) -> void:
	_curse_t = maxf(_curse_t, seconds)
	_curse = {"len": seconds, "dps": dps, "spread": spread, "bonus": bonus}

func is_cursed() -> bool:
	return _curse_t > 0.0

## Inmóvil `seconds` (red de pesca): no anda pero sí ataca. Las élites solo se frenan.
func root(seconds: float) -> void:
	if data.elite:
		slow(seconds, 0.5)
		return
	_root_t = maxf(_root_t, seconds)

func is_rooted() -> bool:
	return _root_t > 0.0

## Suero de Herbert West: si muere en los próximos segundos, se levanta `ally_time` s como aliado.
func inject(ally_time: float, bonus: Dictionary = {}) -> void:
	_inject_t = INJECT_TIME
	_ally_time = ally_time
	_inject_bonus = bonus

func is_injected() -> bool:
	return _inject_t > 0.0

## Velocidad actual (con el ralentizado aplicado): para los tests.
## ¿Vadea agua somera? Los marinos (Profundos) no: nadan.
func wades() -> bool:
	if obstacles == null or data.swims or data.ethereal: return false
	return obstacles.water_at(Vector2(position.x, position.z)) > 0.5

func speed_mult() -> float:
	return _slow_k if _slow_t > 0.0 else 1.0

## Envenenado durante `seconds`: pierde `dps` por segundo (serpiente de Yig). Un veneno nuevo
## renueva el tiempo y se queda con el daño mayor.
func poison(seconds: float, dps: float, bonus: Dictionary = {}) -> void:
	_poison_t = maxf(_poison_t, seconds)
	_poison_dps = maxf(_poison_dps if _poison_t > 0.0 else 0.0, dps)
	_poison_bonus = bonus

## Ardiendo durante `seconds` (Fósforos de Cthugha, Llama de Cthugha): daño continuo.
func ignite(seconds: float, dps: float, bonus: Dictionary = {}) -> void:
	_burn_dps = maxf(_burn_dps if _burn_t > 0.0 else 0.0, dps)
	_burn_t = maxf(_burn_t, seconds)
	_burn_bonus = bonus
	_burn_tag = Damage.ctx

func is_burning() -> bool:
	return _burn_t > 0.0

func is_poisoned() -> bool:
	return _poison_t > 0.0

## Confundido durante `seconds` (polilla de Leng; las élites, la mitad): vaga sin rumbo, a
## ratos hacia un lado y a ratos hacia otro, y no dispara.
func confuse(seconds: float) -> void:
	_confuse_t = maxf(_confuse_t, seconds * (0.5 if data.elite else 1.0))

## Enloquecido `seconds` (Signo Amarillo; las élites, la mitad): va a por el enemigo más cercano
## y le hace `dps`; no dispara ni daña a los jugadores.
func madden(seconds: float, dps: float, bonus: Dictionary = {}) -> void:
	_madden_t = maxf(_madden_t, seconds * (0.5 if data.elite else 1.0))
	_madden_dps = dps
	_madden_tag = Damage.ctx
	_madden_bonus = bonus

func is_maddened() -> bool:
	return _madden_t > 0.0

## Empujón externo (Esfera de Yog-Sothoth): se suma al retroceso; las élites lo notan menos.
func nudge(v: Vector3) -> void:
	if anchored: return
	_knock += Vector3(v.x, 0, v.z) * (0.3 if data.elite or data.unique else 1.0)

func is_confused() -> bool:
	return _confuse_t > 0.0

## Aturdido durante `seconds` (las élites, la mitad).
func stun(seconds: float) -> void:
	_stun = maxf(_stun, seconds * (0.5 if data.elite else 1.0))

func take_damage(d: Damage) -> void:
	if puppet:                                 # el daño de verdad lo cuenta el anfitrión
		_flash = 0.07
		_hit_pose(d)
		var guess := d.physical                # la cifra, aproximada (sin las bonificaciones)
		for tag in data.tags: guess *= float(d.bonus.get(tag, 1.0))
		_number(guess, false, d.dot)
		return
	if shield_t > 0.0: return
	if not is_alive(): return
	Auto.sfx_at("hit", global_position)
	var k := VULNERABLE_MULT if _vulnerable > 0.0 else 1.0
	for tag in data.tags: k *= float(d.bonus.get(tag, 1.0))    # rasgos contra este tipo de enemigo
	if data.elite or data.unique: k *= float(d.bonus.get(Player.ELITE_TAG, 1.0))   # Medallón del cazador
	if _stasis_t > 0.0:                        # congelado: el daño se guarda para el final
		_stasis_store += d.physical * k
		_flash = 0.07
		return
	var dealt := minf(d.physical * k, maxf(health, 0.0))
	health -= d.physical * k
	world.record_damage(d.tag, dealt)              # estadísticas de la ficha
	if not d.dot: world.player_hit(d.tag, self)    # objetos al impactar (hito 8.7)
	if health <= 0.0: world.record_kill(d.tag, global_position)
	_flash = 0.07
	_knock += Vector3(d.knockback.x, 0, d.knockback.z) * (2.5 if not data.elite else 0.6)
	_hit_pose(d)
	var big := data.elite or data.unique
	# en dorado: con bonificación (rasgos, vulnerable) o un golpe fuerte a una élite
	_number(d.physical * k, k > 1.05 or (big and not d.dot and dealt >= data.max_health * health_scale * 0.08), d.dot)
	if big and not d.dot and dealt >= data.max_health * health_scale * 0.08 and health > 0.0:
		HitStop.hit(30)                                # golpe fuerte a una élite: micro-pausa (hito 11.1)
	if health <= 0.0:
		if big: HitStop.hit(70, true)
		_die()

## Golpe recibido (hito 11.2): se aplasta un poco y se inclina hacia donde lo empujan.
func _hit_pose(d: Damage) -> void:
	_hit_t = 0.0
	var dir := Vector3(d.knockback.x, 0.0, d.knockback.z)
	if dir.length_squared() < 0.0001 and d.source is Node3D:
		dir = global_position - (d.source as Node3D).global_position
		dir.y = 0.0
	_hit_dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector3.ZERO

## Cifra de daño encima del modelo (DamageNumbers).
func _number(amount: float, strong: bool, dot: bool) -> void:
	if not DamageNumbers.enabled or world == null: return
	if _top_h < 0.0 and _spawn_t > 0.35 and model != null and model.has_meta("meshes"):
		var inv := model.global_transform.affine_inverse()
		_top_h = 0.8
		for mi: MeshInstance3D in model.get_meta("meshes"):
			if is_instance_valid(mi) and mi.mesh != null:
				_top_h = maxf(_top_h, (inv * mi.global_transform * mi.get_aabb()).end.y)
	var h := (_top_h if _top_h > 0.0 else 1.2) * model_scale
	DamageNumbers.add(world.fx, self, amount, global_position + Vector3(0.0, h + 0.25, 0.0), strong, dot)

func _die() -> void:
	Auto.sfx_at("die", global_position)
	if _curse_t > 0.0 and int(_curse.get("spread", 0)) > 0: _spread_curse()
	if _inject_t > 0.0 and _ally_time > 0.0:            # se levanta como aliado
		world.fx.add_child(Reanimated.new().setup(world, data, global_position, facing, _ally_time, _inject_bonus))
	_death_fx()

## Muerte de una marioneta (lo avisa el anfitrión).
func puppet_die() -> void:
	if is_queued_for_deletion(): return
	health = 0.0
	Auto.sfx_at("die", global_position)
	_death_fx()

func _death_fx() -> void:
	var fx := DeathBurst.new()
	fx.setup(model_name, data.body_radius, model, data.elite or data.unique)
	fx.position = global_position
	world.fx.add_child(fx)
	if _wade > 0.5:                                   # cae al agua: ondas grandes (hito 11.4)
		Ripples.add(world.fx, global_position, 1.4 + data.body_radius * 2.0, 0.8, 1.6)
		Ripples.add(world.fx, global_position, 0.8 + data.body_radius, 0.6, 1.2)
	# el modelo se queda y se deshace en cubos (hito 11.1); la brasa, de su color más claro
	var light: Color = DeathBurst.palette_of(model_name, model)[0]
	for c: Color in DeathBurst.palette_of(model_name, model): if c.get_luminance() > light.get_luminance(): light = c
	Crumble.start(world.fx, model, light.lerp(Color(1.0, 0.45, 0.15), 0.55), data.elite or data.unique)
	died.emit(self)
	queue_free()

## La maldición salta a los más cercanos que aún no la llevan.
func _spread_curse() -> void:
	var near := world.enemies_in_circle(global_position, CURSE_JUMP)
	near.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
	var left := int(_curse.spread)
	for e in near:
		if left <= 0: break
		if e == self or not e.has_method("curse") or not e.has_method("is_cursed") or e.is_cursed(): continue   # los rompibles no se maldicen
		e.curse(_curse.len, _curse.dps, _curse.spread, _curse.bonus)
		var fx := CurseJump.new().setup(global_position, e.global_position)
		world.fx.add_child(fx)
		left -= 1

## Estados del arsenal II: estasis (y su daño aplazado), maldición, ralentizado y debilitado.
## Devuelve true si está congelado (no se mueve ni ataca este paso).
func _update_status(delta: float) -> bool:
	if _slow_t > 0.0: _slow_t -= delta
	if _root_t > 0.0: _root_t -= delta
	if _inject_t > 0.0: _inject_t -= delta
	if _weak_t > 0.0: _weak_t -= delta
	runner.damage_mult = _weak_k if _weak_t > 0.0 else 1.0
	if _curse_t > 0.0:
		_curse_t -= delta
		_curse_tick -= delta
		if _curse_tick <= 0.0:
			_curse_tick = CURSE_TICK
			var d := Damage.new(float(_curse.dps) * CURSE_TICK, 0.0)
			d.bonus = _curse.bonus
			take_damage(d)
			if not is_alive(): return true
	if _poison_t > 0.0:
		_poison_t -= delta
		_poison_tick -= delta
		if _poison_tick <= 0.0:
			_poison_tick = CURSE_TICK
			var d := Damage.new(_poison_dps * CURSE_TICK, 0.0)
			d.bonus = _poison_bonus
			take_damage(d)
			if not is_alive(): return true
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = CURSE_TICK
			var prev := Damage.ctx
			Damage.ctx = _burn_tag
			var d := Damage.new(_burn_dps * CURSE_TICK, 0.0)
			Damage.ctx = prev
			d.bonus = _burn_bonus
			d.dot = true
			take_damage(d)
			if not is_alive(): return true
	if _stasis_t > 0.0:
		_stasis_t -= delta
		if _stasis_t <= 0.0 and _stasis_store > 0.0:
			var d := Damage.new(_stasis_store * STASIS_MULT, 0.0)
			_stasis_store = 0.0
			take_damage(d)
		return true
	return false

## Enloquecido: persigue al enemigo vivo más cercano y le golpea cada MADDEN_HIT s.
const MADDEN_HIT := 0.5
func _madden_step(delta: float) -> void:
	_madden_t -= delta
	_madden_hit -= delta
	var best: Node3D = null
	var best_d := INF
	for e in world.enemies_in_circle(global_position, 7.0):
		if e == self or not e.is_alive(): continue
		var dd := global_position.distance_squared_to(e.global_position)
		if dd < best_d:
			best_d = dd
			best = e
	if best == null:
		velocity = Vector3.ZERO
		return
	var to := Vector3(best.global_position.x - position.x, 0, best.global_position.z - position.z)
	velocity = to.normalized() * data.move_speed * 1.1
	if to.length() <= data.body_radius + float(best.hit_radius) + 0.25 and _madden_hit <= 0.0:
		_madden_hit = MADDEN_HIT
		var prev := Damage.ctx
		Damage.ctx = _madden_tag
		var d := Damage.new(_madden_dps * MADDEN_HIT, 0.0)
		Damage.ctx = prev
		d.bonus = _madden_bonus
		d.knockback = to.normalized()
		best.take_damage(d)

const CROWD := 120                         ## enemigos: con más, la pose va en fotogramas alternos
const FAR := 16.0                          ## m: más lejos de todos los jugadores, piensa a medio ritmo
var _far := false
var _ai_vel := Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_alive(): return
	if puppet:
		_spawn_t += delta
		_wade = move_toward(_wade, 1.0 if wades() else 0.0, WadeSplash.EASE * delta)
		_puppet_touch(delta)
		behavior.puppet_step(self, delta)
		if guard_ring != null: guard_ring.rotation.y += 0.05
		return
	var t0 := Prof.start()
	_spawn_t += delta
	if world.freeze_t > 0.0:                         # tiempo congelado (recompensa): ni se mueve ni ataca
		Prof.stop("enemigos_fisica", t0)
		return
	if shield_t > 0.0: shield_t -= delta
	if _update_status(delta):                  # congelado en el tiempo (o muerto por la maldición)
		Prof.stop("enemigos_fisica", t0)
		return
	var target := target_player()
	if giant != null and giant.step(self, target, delta):   # agachado o saltando: no anda
		velocity = Vector3.ZERO
		Prof.stop("enemigos_fisica", t0)
		return
	# lejos de todos los jugadores, o con mucha gente, piensa en pasos alternos y mantiene la
	# velocidad (12-10-2026)
	if (_far or world.enemies.size() > CROWD) and (Engine.get_physics_frames() + get_instance_id()) % 2 == 1:
		velocity = _ai_vel
	else:
		velocity = behavior.update(self, target, delta) * pace_mult
		_ai_vel = velocity
	if Engine.get_physics_frames() % 15 == get_instance_id() % 15: _far = _far_from_players()
	if _slow_t > 0.0: velocity *= _slow_k
	var wet := wades()
	if wet: velocity *= WadeSplash.SLOW                # agua somera: los marinos nadan, los demás vadean
	_wade = move_toward(_wade, 1.0 if wet else 0.0, WadeSplash.EASE * delta)
	if _root_t > 0.0: velocity = Vector3.ZERO
	if _vulnerable > 0.0: _vulnerable -= delta
	if _lure_t > 0.0:                          # bengala: va hacia la luz en lugar del jugador
		_lure_t -= delta
		var to := Vector3(_lure_pos.x - position.x, 0, _lure_pos.z - position.z)
		velocity = to.normalized() * data.move_speed if to.length() > 0.6 else Vector3.ZERO
	if _confuse_t > 0.0:                       # polilla: da vueltas sin rumbo
		_confuse_t -= delta
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(0.4, 0.9)
			var a := randf() * TAU
			_wander = Vector3(cos(a), 0, sin(a))
		velocity = _wander * data.move_speed * 0.6
	if _madden_t > 0.0: _madden_step(delta)
	if _stun > 0.0:
		_stun -= delta
		velocity = Vector3.ZERO
	# Separación: no amontonarse con los enemigos cercanos
	var pos2 := Vector2(global_position.x, global_position.z)
	var push := Vector2.ZERO
	# en pasos alternos (la mitad de cada enemigo en cada paso) y con el doble de fuerza
	var sep_turn := (Engine.get_physics_frames() + get_instance_id()) % 2 == 0
	for id in (world.grid.query_circle(pos2, data.body_radius) if sep_turn else PackedInt32Array()):
		var other := world.target_at(id)
		if other == self: continue
		var off := pos2 - Vector2(other.global_position.x, other.global_position.z)
		var dist := off.length()
		var min_d: float = data.body_radius + float(other.hit_radius)
		if dist > 0.001 and dist < min_d: push += off / dist * (min_d - dist)
	var move := velocity * delta + _knock * delta + Vector3(push.x, 0, push.y)
	_knock = _knock.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))
	if not anchored:
		var np := Vector2(position.x + move.x, position.z + move.z)
		if obstacles != null and data.ethereal:          # atraviesa el decorado, pero no sale de la arena
			var b := obstacles.bounds.grow(-data.body_radius)
			np = Vector2(clampf(np.x, b.position.x, b.end.x), clampf(np.y, b.position.y, b.end.y))
		elif obstacles != null: np = obstacles.push_out(np, data.body_radius)
		position = Vector3(np.x, position.y, np.y)
	if velocity.length() > 0.1:
		facing = facing.slerp(velocity.normalized(), 1.0 - exp(-10.0 * delta)).normalized()
	if guard_ring != null: guard_ring.rotation.y += 0.05
	# Contacto con los jugadores
	if data.aura_drain > 0.0:                   # presencia: drena cordura a los de dentro del aura
		for p in world.players:
			if p.global_position.distance_to(global_position) <= data.aura_radius: p.drain_sanity(data.aura_drain * delta)
	for p in world.players if behavior.touches(self) and _madden_t <= 0.0 else []:
		if p.remote: continue                       # en red: lo decide su PC (marioneta, _puppet_touch)
		var r := data.body_radius + p.data.hurt_radius
		var pp := p.global_position
		if Vector2(pp.x - position.x, pp.z - position.z).length_squared() < r * r:
			var cd := behavior.contact_damage(self)
			p.take_damage(cd.scaled(_weak_k) if _weak_t > 0.0 else cd)
	# Ataque a distancia
	if data.attack != null and target != null and _stun <= 0.0 and _confuse_t <= 0.0 and _madden_t <= 0.0 and behavior.can_shoot(self):
		_attack_timer -= delta
		if _attack_timer <= 0.0 and not runner.busy and target.global_position.distance_to(global_position) < data.attack_range:
			runner.fire(data.attack, func() -> Vector3: return target.global_position if is_instance_valid(target) else global_position)
			if data.attack_anim != "": behavior.play_attack_anim(self, data.attack_anim)
			_attack_timer = data.attack_cooldown * randf_range(0.85, 1.15)
	Prof.stop("enemigos_fisica", t0)

## ¿Lejos de todos los jugadores? (se mira cada 15 pasos)
func _far_from_players() -> bool:
	for p in world.players:
		if p.global_position.distance_squared_to(global_position) < FAR * FAR: return false
	return true

func _process(delta: float) -> void:
	if is_queued_for_deletion(): return               # muerto: su modelo, si se desmorona, ya es de Crumble
	var t0 := Prof.start()
	visual.global_position = get_global_transform_interpolated().origin - Vector3(0, _wade * WadeSplash.SINK, 0)
	if _wade > 0.5:                                   # ondas al vadear, cada tanto recorrido (hito 11.4)
		if _ripple_from == Vector3.INF or visual.global_position.distance_to(_ripple_from) >= 0.6 + data.body_radius:
			_ripple_from = visual.global_position
			Ripples.add(world.fx, _ripple_from, 0.6 + data.body_radius * 1.2, 0.45)
	else:
		_ripple_from = Vector3.INF
	if _flash > 0.0:                                   # tiembla un instante al recibir el golpe (hito 11.1)
		var a := 0.035 * clampf(data.body_radius, 0.4, 1.5)
		visual.global_position += Vector3(randf_range(-a, a), 0.0, randf_range(-a, a))
	visual.rotation = Vector3(0.0, atan2(facing.x, facing.z), 0.0)
	visual.scale = Vector3.ONE * clampf(_spawn_t / 0.35, 0.2, 1.0) * model_scale   # aparece creciendo
	if _hit_t < HIT_POSE:                             # golpe: se aplasta y se inclina, y vuelve con rebote (hito 11.2)
		var hk := _hit_t / HIT_POSE
		var s := sin(hk * PI * 1.5) * (1.0 - hk) * (0.35 if model_scale > 1.5 or data.unique else 1.0)
		visual.scale *= Vector3(1.0 + 0.1 * s, 1.0 - 0.12 * s, 1.0 + 0.1 * s)
		if _hit_dir != Vector3.ZERO:
			visual.basis = Basis(Vector3.UP.cross(_hit_dir), 0.2 * s) * visual.basis
		_hit_t += delta
	if _aura_mat: _aura_mat.set_shader_parameter("color", Color(0.45, 0.2, 0.7, 0.14 + 0.07 * sin(_spawn_t * 2.5)))
	if not anim_hold and _stasis_t <= 0.0 and world.freeze_t <= 0.0:   # congelado: la animación se detiene
		anim_t = fposmod(anim_t + delta / Anims.duration(model_name, anim), 1.0)
	# fuera de la vista no se aplica la pose (la animación sigue corriendo): con 200 enemigos
	# era una cuarta parte de su coste
	var cam := get_viewport().get_camera_3d()
	# con muchos en pantalla, la pose en fotogramas alternos (a más de 60 FPS no se nota)
	var crowd := world.enemies.size() > CROWD and (Engine.get_process_frames() + get_instance_id()) % 2 == 1
	if model_scale > 1.5 or (not crowd and (cam == null or cam.is_position_in_frustum(visual.global_position + Vector3(0, 1.0, 0)))):
		Anims.pose(model_name, anim, model, anim_t)
	_flash -= delta
	# tinte: destello al recibir daño; si no, turquesa en estasis o violeta maldito.
	# Solo se toca el material al cambiar.
	var want: Material = null
	if _flash > 0.0: want = _flash_mat
	elif _stasis_t > 0.0 or world.freeze_t > 0.0: want = _status(Color(0.35, 0.95, 1.0, 0.5))
	elif _curse_t > 0.0: want = _status(Color(0.55, 0.12, 0.7, 0.35 + 0.1 * sin(_spawn_t * 9.0)))
	elif _burn_t > 0.0: want = _status(Color(1.0, 0.5, 0.12, 0.3 + 0.1 * sin(_spawn_t * 13.0)))
	elif _poison_t > 0.0: want = _status(Color(0.35, 0.85, 0.15, 0.3 + 0.08 * sin(_spawn_t * 7.0)))
	elif _madden_t > 0.0: want = _status(Color(1.0, 0.85, 0.15, 0.3 + 0.12 * sin(_spawn_t * 10.0)))
	elif _confuse_t > 0.0: want = _status(Color(0.95, 0.75, 0.95, 0.22 + 0.1 * sin(_spawn_t * 11.0)))
	elif _inject_t > 0.0: want = _status(Color(0.8, 0.95, 0.25, 0.14 + 0.06 * sin(_spawn_t * 12.0)))   # suero: tenue (el aliado, verde intenso)
	if want != _overlay:
		_overlay = want
		for mi: MeshInstance3D in model.get_meta("meshes"):
			mi.material_overlay = want
	Prof.stop("enemigos_anim", t0)

## Aura de presencia (GDD 4.4): disco violeta tenue que late alrededor de la élite.
func _make_aura() -> void:
	_aura = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	_aura.mesh = pm
	_aura_mat = ShaderMaterial.new()
	_aura_mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	_aura_mat.set_shader_parameter("fill", true)
	_aura_mat.set_shader_parameter("soft", true)
	_aura_mat.set_shader_parameter("color", Color(0.45, 0.2, 0.7, 0.18))
	_aura.material_override = _aura_mat
	_aura.scale = Vector3.ONE * data.aura_radius
	_aura.position.y = 0.05
	_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(_aura)

## Material de tinte de estado (uno por enemigo, se cambia su color).
func _status(c: Color) -> StandardMaterial3D:
	if _status_mat == null:
		_status_mat = StandardMaterial3D.new()
		_status_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_status_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_status_mat.albedo_color = c
	return _status_mat

# ---------------- red (hito 9.3a) ----------------
## Estado visible que viaja con cada foto: destello y tintes de estado.
func net_flags() -> int:
	var f := 0
	if _flash > 0.0: f |= 1
	if _stasis_t > 0.0 or world.freeze_t > 0.0: f |= 2
	if _curse_t > 0.0: f |= 4
	if _burn_t > 0.0: f |= 8
	if _poison_t > 0.0: f |= 16
	if _madden_t > 0.0: f |= 32
	if _confuse_t > 0.0: f |= 64
	if _inject_t > 0.0: f |= 128
	return f

## Marioneta: pone los tintes de la foto (los relojes no corren aquí: la foto los enciende o apaga).
func net_apply_flags(f: int) -> void:
	if f & 1: _flash = maxf(_flash, 0.07)
	_stasis_t = 1.0 if f & 2 else 0.0
	_curse_t = 1.0 if f & 4 else 0.0
	_burn_t = 1.0 if f & 8 else 0.0
	_poison_t = 1.0 if f & 16 else 0.0
	_madden_t = 1.0 if f & 32 else 0.0
	_confuse_t = 1.0 if f & 64 else 0.0
	_inject_t = 1.0 if f & 128 else 0.0

## Más estado para la foto (hito 9.3c): 1 oculto (bajo el agua), 2 anillo de los guardianes.
func net_flags2() -> int:
	var f := 0
	if visual != null and not visual.visible: f |= 1
	if guard_ring != null: f |= 2
	return f

func net_apply_flags2(f: int) -> void:
	if visual != null: visual.visible = (f & 1) == 0
	if ((f & 2) != 0) != (guard_ring != null): set_guard_ring((f & 2) != 0)

## Anillo dorado que gira mientras le protegen sus guardianes (Guardián del faro).
var guard_ring: MeshInstance3D

func set_guard_ring(on: bool) -> void:
	if not on:
		if guard_ring != null: guard_ring.queue_free()
		guard_ring = null
		return
	if guard_ring != null: return
	guard_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.1; tm.outer_radius = 1.3
	guard_ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.85, 0.70, 0.30) * 0.8
	guard_ring.material_override = m
	guard_ring.position.y = 1.2
	add_child(guard_ring)

## Contacto que viaja en la foto: 0 si ahora no daña al tocar; si no, el daño de contacto de
## su ficha multiplicado por esto / 50 (embestidas, debilitado).
var net_contact := 0

func net_contact_byte() -> int:
	if not behavior.touches(self) or _madden_t > 0.0: return 0
	var cd := behavior.contact_damage(self)
	if _weak_t > 0.0: cd = cd.scaled(_weak_k)
	var base := data.contact_physical if data.contact_physical > 0.0 else data.contact_mental
	if base <= 0.0: return 0
	var k := (cd.physical if data.contact_physical > 0.0 else cd.mental) / base
	return clampi(roundi(k * 50.0), 1, 255)

## Marioneta: golpea por contacto (y drena con su aura) a los jugadores de este PC, que son los
## que deciden aquí lo que les pasa (D-10).
func _puppet_touch(delta: float) -> void:
	for p in world.players:
		if p.remote: continue
		if data.aura_drain > 0.0 and p.global_position.distance_to(global_position) <= data.aura_radius:
			p.drain_sanity(data.aura_drain * delta)
		if net_contact <= 0: continue
		var r := data.body_radius + p.data.hurt_radius
		var pp := p.global_position
		if Vector2(pp.x - position.x, pp.z - position.z).length_squared() < r * r:
			var d := Damage.new(data.contact_physical, data.contact_mental).scaled(net_contact / 50.0)
			d.source = self
			p.take_damage(d)
