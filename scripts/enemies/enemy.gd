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
var _touched := false                    ## ya ha recibido daño (Aldaba de los Derby, hito 20.21)
var health_scale := 1.0                  ## multiplicador de vida (cooperativo): vida máxima = data.max_health × esto
var shield_t := 0.0
var ward := 0                              ## escudo de icor: golpes que para (grados de locura, 16.14)
var small := false                         ## nacida de partirse otra: más pequeña y no se parte
var buried := false                        ## bajo tierra (shoggoth excavador, 16.16): fuera de la rejilla, no se le da
var _ward_mesh: MeshInstance3D
var _path_t := 0.0                      ## s hasta volver a mirar si hay línea libre al jugador
var _stuck_ref := Vector2.INF               ## dónde estaba en la última comprobación de atasco
var _stuck_t := 0.0
var _detour_t := 0.0                         ## s yendo por el flujo aunque haya línea libre (se atascó)
var _path_clear := true                      ## s de invulnerabilidad (cambio de fase de un jefe)
var velocity := Vector3.ZERO
var facing := Vector3(0, 0, 1)
var anim := "walk"
var anim_t := 0.0                        ## fase de la animación (0..1)
## Hordas menos clónicas (hito 17.12): cada uno algo distinto, solo en lo que se ve (la vida, la
## velocidad y el choque no cambian). Van en el contenedor del modelo: valen con la horda.
var var_size := 1.0                       ## tamaño (±6 %; las élites y los únicos, 1)
var var_tempo := 1.0                      ## ritmo de la animación (±9 %)
var var_lean := 0.0                       ## echado adelante (rad, hasta 0,07)
var var_roll := 0.0                       ## contoneo al andar (rad, hasta 0,06)
static var variety := true                ## variety=false para comparar
var anim_hold := false                   ## el comportamiento controla anim_t directamente
var _knock := Vector3.ZERO
var _stun := 0.0                            ## s que le quedan aturdido (no se mueve ni ataca)
var _vulnerable := 0.0                      ## s que recibe +25 % de daño (ácido)
var _reveal_t := 0.0                         ## s revelado (Máquina del más allá, 20.20): recibe +_reveal_k de daño
var _reveal_k := 0.0
var _reveal_chain := 0.0                     ## daño con que revienta si muere revelado (Medusas del más allá)
var _reveal_tag := &""
var _dream_t := 0.0                         ## s que sigue soñando (zonas de Kuranes, 20.22)
var _blight_t := 0.0                        ## s que sigue gris y quebradizo (el color, 21.13)
var _blight_k := 0.0                        ## daño de más que recibe mientras tanto
const REVEAL_BURST_R := 2.0
var _lure_t := 0.0                          ## s que le atrae una bengala
var _lure_pos := Vector3.ZERO
const VULNERABLE_MULT := 1.25
# Arsenal II (hito 2.7)
var giant: GiantMoves                        ## salto y erupciones de los grandes (o null)
var pace_mult := 1.0                         ## ritmo propio (la dificultad va aparte, en vivo: Difficulty)
## Hito 15.3. Expedicionario (`EnemyData.revive`): caído en el suelo (s que le quedan; cualquier
## golpe lo remata) y levantándose (s). Tamborilero (`drum_radius`): `drum_t`, s que le quedan
## al ritmo del tambor de uno cercano (`DRUM_SPEED`).
const DRUM_SPEED := 1.35
const FLASH_BIG := 0.06                     ## destello de jefes y gigantes (s)
const FLASH_BIG_GAP := 0.2                  ## y su pausa mínima entre uno y otro (s)
const FLASH_BIG_ADD := 0.2                  ## luz que suman (los demás, blanco al 75 %)
const DRUM_EVERY := 0.6
## Ídolo vivo (hito 16.18): los que están cerca de él (`idol_t` > 0) reciben menos daño.
const IDOL_GUARD := 0.6
var idol_t := 0.0
## Élites con rasgos (hito 16.20, EliteTraits): máscara, icono y relojes de los rasgos.
var traits := 0
var trait_icon: Sprite3D
var trait_t := 0.0
var trait_fx := 0.0
var trait_from := Vector3.INF
var drum_t := 0.0
var _drum_next := 0.0
var _revived := false
var killed_by: StringName = &""               ## etiqueta del golpe que lo abatió («J1:webly»; bestiario, hito 15.4)
var killed_how := &""                         ## cómo lo mató el último golpe (Damage.how, hito 17.9)
var _down_t := 0.0
var _getup_t := 0.0
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
var _inject_power := 1.0                    ## daño de su aliado (Frasco de los Custodes, hito 20.18)
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
var _mark_mat: ShaderMaterial               ## élites (hito 12.6): disco del color de la parte a sus pies
## Élites y heridas (hito 12.6): el color de la parte (lo pone la partida), algo más grandes, y
## grietas que crecen con la vida perdida en élites, únicos y grandes.
static var part_tint := Color(0.45, 0.2, 0.7)
## Avisa de cada enemigo que aparece (las élites de fuera de cámara, `OffscreenCues`, hito 13.13).
static var on_appear := Callable()
const PART_TINTS := {"p1": Color(0.1, 0.42, 1.0), "p2": Color(0.1, 0.85, 0.35), "p3": Color(0.85, 0.25, 0.1)}
const ELITE_SIZE := 1.1
const ELITE_EYES := 1.4                     ## brillo de su capa de luz (ojos, bioluminiscencia)
static var wounds := true                   ## wounds=false: sin grietas (comparar)
static var tints := true                    ## tints=false: sin el destello del golpe ni los tintes de estado (tráiler, hito 13.16)
static var flash_hold := false              ## flash_hold=true: el destello del golpe, siempre encendido (capturas)
static var wounds_force := -1.0             ## wounds=0.7: grietas fijas a ese nivel (medir su coste)
static var _wound_mat: ShaderMaterial
static var _elite_glow := {}                ## material de luz -> su copia más brillante
static var _wounded := {}                   ## material del modelo -> su copia con las grietas (una para todos)
var _wound_meshes: Array = []
var _look := 0.0                            ## jefes vivos (hito 12.8): giro de la cabeza hacia el jugador más cercano
var _blink_at := 3.0                        ## s de _spawn_t en que parpadea
var _wound_k := -1.0
var _aura_mat: ShaderMaterial                ## presencia: disco violeta en el suelo (drena cordura)
var _flash := 0.0
var _flash_on := false
var _flash_mat: StandardMaterial3D
var _flash_big_mat: StandardMaterial3D        ## jefes y gigantes: aclara sin tapar el modelo
var _flash_cd := 0.0                          ## jefes y gigantes: pausa entre destellos
const HIT_POSE := 0.22                      ## s que dura el aplastado y la inclinación al recibir un golpe (hito 11.2)
var _hit_t := HIT_POSE
var _hit_len := HIT_POSE                    ## lo que dura su reacción (la de su familia, Anims.hit_time)
var _hit_own := false                       ## su juego de animaciones tiene reacción propia (Anims.hit)
var _hit_dir := Vector3.ZERO
var _hit_k := 0.5                           ## fuerza del golpe (hito 17.10): cuánto se echa atrás
const WINDUP_RELEASE := 0.32               ## s del golpe hacia delante al terminar la preparación (hito 12.5)
var _wu_t := -1.0                           ## preparación antes de un ataque con aviso: s desde que empezó; -1, ninguna
var _wu_len := 0.0                          ## lo que dura el aviso
var _ripple_from := Vector3.INF            ## dónde dejó la última onda en el agua (hito 11.4)
var _top_h := -1.0                          ## altura del modelo sin escalar (números de daño); -1, sin medir
var _attack_timer := 0.0
var _spawn_t := 0.0
const RISE_TIME := 0.5                      ## s que tarda en aparecer (hito 11.6); las élites y los grandes, RISE_BIG
const RISE_BIG := 0.85
const RISE_FOG := Color(0.55, 0.75, 1.0)    ## borde de lo que se materializa en la niebla
const RISE_FLY := 5.0                       ## m desde los que bajan los que vuelan
static var rise_enabled := true             ## rise=false: aparecen creciendo, como antes
enum Rise { NONE, GROUND, WATER, FOG, AIR }
var _rise := Rise.NONE
var _rise_t := 0.0
var _rise_wait := 0.0                       ## s de física que le quedan quieto (lo de jugar no depende del dibujo)
var _rise_life := RISE_TIME
var _rise_h := 1.5                          ## m que se hunde al empezar (su altura)
var _rise_mats: Array = []                  ## mallas con el material de deshacerse (niebla)
## Entradas por familia (hito 17.11): los profundos que salen del agua trepan (los brazos tiran de
## ellos) y al salir se sacuden el agua; los humanos salen de un jirón de niebla.
const SHAKE_TIME := 0.55
const RISE_MIST := Color(0.82, 0.86, 0.92)  ## borde de los que salen de la niebla (más gris que el de los etéreos)
var _climb := false
var _shake_t := -1.0
## Hordas con instancias (hito 16.3): si se puede, en cuanto acaba de aparecer se dibuja con el
## MultiMesh de su tipo (`HordeDraw`) y su modelo de nodos sale del árbol hasta que muere.
var _horde_ok := false
var _in_horde := false
var _horde: HordeMesh
var _hdraw: HordeDraw
var horde_cell := Vector2i.ZERO              ## su celda y su plaza en la horda (HordeMesh.Layer)
var horde_slot := -1
const LAND_TIME := 0.28                     ## s que dura el aplastado al aterrizar (hito 11.7)
var _prev_y := INF                          ## altura dibujada del fotograma anterior
var _vy := 0.0                              ## velocidad vertical dibujada (m/s)
var _land := 0.0                            ## fuerza del último aterrizaje (0 sin él)
var _land_t := LAND_TIME


## Gira la dirección `from` hacia `to` en el plano, la parte `w` del ángulo (0..1). Antes con
## `Vector3.slerp`, que con dos direcciones casi iguales saca un eje de giro mal normalizado en
## coma flotante («The axis … must be normalized», 06-11-2026). Las dos se miran en horizontal.
static func turn_flat(from: Vector3, to: Vector3, w: float) -> Vector3:
	if Vector2(to.x, to.z).length_squared() < 1e-8: return from
	if Vector2(from.x, from.z).length_squared() < 1e-8: return Vector3(to.x, 0.0, to.z).normalized()
	var a := lerp_angle(atan2(from.x, from.z), atan2(to.x, to.z), clampf(w, 0.0, 1.0))
	return Vector3(sin(a), 0.0, cos(a))

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
	_rise_end()
	if _in_horde: _leave_horde()
	if model != null: model.queue_free()
	model_name = new_model
	model_scale = new_scale
	model = ModelPool.take("res://models/%s.json" % model_name)   # de la reserva si hay (hito 16.1)
	visual.add_child(model)
	_spawn_t = 0.0                                 # vuelve a crecer desde pequeño
	anim_t = 0.0
	_top_h = -1.0
	_dress_model()
	_horde_ok = HordeDraw.eligible(self)

func _ready() -> void:
	visual = Node3D.new()
	# Se anima en _process (sin interpolación) y va suelto: en cada fotograma se coloca en la
	# posición interpolada del cuerpo (dentro de él se dibujaría a saltos; ver Player).
	visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visual.top_level = true
	add_child(visual)
	model_name = data.model
	model_scale = data.model_scale
	model = ModelPool.take("res://models/%s.json" % model_name)   # de la reserva si hay (hito 16.1)
	visual.add_child(model)
	if data.ethereal: _make_ethereal(model)
	_dress_model()
	_horde_ok = HordeDraw.eligible(self)
	runner = PatternRunner.new().setup(world)
	if GiantMoves.applies(data) and not puppet:
		giant = GiantMoves.new()
		runner.over_walls = true
	runner.position.y = 0.6
	add_child(runner)
	_flash_mat = _shared_flash(false)
	_attack_timer = data.attack_cooldown * randf_range(0.5, 1.0)
	anim_t = randf()
	if variety:                                  # 17.12
		var_tempo = randf_range(0.91, 1.09)
		if not data.elite and not data.unique:
			var_size = randf_range(0.94, 1.06)
			var_lean = randf_range(0.0, 0.07) if not data.ethereal else 0.0
			var_roll = randf_range(0.0, 0.06) if randf() < 0.6 else 0.0
	if data.aura_drain > 0.0 and data.aura_radius > 0.0:
		_aura_mat = _disc(Color(0.45, 0.2, 0.7, 0.18), data.aura_radius)
	if data.params.has("guard_radius"):            # ídolo vivo (16.18): el corro que protege, también en red
		_disc(Color(0.20, 0.55, 0.30, 0.07), float(data.params.guard_radius))
	if data.elite and data.body_radius * model_scale < 2.0:
		_mark_mat = _disc(Color(part_tint, 0.3), maxf(data.body_radius * model_scale * 2.0, 1.0))
	if puppet: anim_hold = true                # la fase de la animación llega con cada foto
	else: behavior.start(self)
	world.add_enemy(self)
	if on_appear.is_valid(): on_appear.call(self)
	_rise_start()
	reset_physics_interpolation.call_deferred()

# ---- aparición (hito 11.6, 28-10-2026) ----

## Cómo aparece: lo que diga su ficha o, si no, según dónde y qué es. Los únicos (jefes y
## minijefes) tienen su propia entrada.
func _rise_kind() -> Rise:
	if not rise_enabled or data.unique: return Rise.NONE
	match String(data.rise):
		"none": return Rise.NONE
		"ground": return Rise.GROUND
		"water": return Rise.WATER
		"fog": return Rise.FOG
		"air": return Rise.AIR
	if data.movement == &"dive": return Rise.AIR
	if data.ethereal: return Rise.FOG
	if obstacles != null and obstacles.water_at(Vector2(global_position.x, global_position.z)) > 0.3: return Rise.WATER
	if family() == "anim_humano": return Rise.FOG                # 17.11: los humanos, de la niebla
	return Rise.GROUND

## Familia de animación del modelo ("anim_humano", "anim_profundo"…).
func family() -> String:
	var s := Anims.script_for(model_name)
	return s.resource_path.get_file().get_basename() if s != null else ""

## Sale del suelo o del agua, baja del cielo o se materializa en la niebla en vez de crecer de
## golpe. Mientras dura no anda, no ataca ni hace daño por contacto (se le puede dar). Es solo
## de cada PC: en los invitados la marioneta hace lo mismo al nacer.
func _rise_start() -> void:
	_rise = _rise_kind()
	if _rise == Rise.NONE: return
	_spawn_t = 0.35                                 # sin crecer
	_rise_life = RISE_BIG if data.elite or model_scale > 1.5 else RISE_TIME
	_rise_wait = _rise_life
	_rise_h = (_model_height() + 0.1) * model_scale
	var at := Vector3(global_position.x, 0.0, global_position.z)
	var cam := get_viewport().get_camera_3d()
	var seen := cam != null and (cam.is_position_in_frustum(at) or cam.is_position_in_frustum(at + Vector3(0, _rise_h, 0)))
	_climb = _rise == Rise.WATER and family() == "anim_profundo" and not data.emerge   # 17.11: trepa y se sacude
	var mist := _rise == Rise.FOG and not data.ethereal         # un humano que sale de la niebla (17.11)
	if not seen and (_rise != Rise.FOG or mist): return       # polvo, agua y niebla solo a la vista (casi todos nacen fuera de cámara)
	match _rise:
		Rise.GROUND:
			VoxelFx.ground_hit(world.fx, at, 0.5 + data.body_radius * 1.4, Ambient.dust_tint(), false)
		Rise.WATER:                                 # espuma y ondas (también lo que sale del mar)
			Ripples.add(world.fx, at, 0.8 + data.body_radius * 1.5, 0.9, 1.4)
			Ripples.add(world.fx, at, 0.4 + data.body_radius, 0.8, 0.9)
			if not data.emerge: WadeSplash.burst(world.fx, at, 0.5 + data.body_radius * 0.6, Color(0, 0, 0, 0), "auto", false)
		Rise.FOG:
			_rise_mats = Crumble.dress(model, RISE_MIST if mist else RISE_FOG)
			Crumble.set_cut(_rise_mats, 1.02)
			if mist: VoxelFx.puff(world.fx, at + Vector3(0, 0.35, 0), "pet_mist", 0.5 + data.body_radius, Color(0.78, 0.82, 0.9), 1.6)   # el jirón de niebla
	if not seen: return
	match _rise:                                    # y su sonido, también solo a la vista (en el agua, el de la salpicadura)
		Rise.GROUND: Auto.sfx_at("rise_" + Ambient.ground, at)
		Rise.FOG: Auto.sfx_at("rise_fog", at)
		Rise.AIR: Auto.sfx_at("rise_air", at + Vector3(0, RISE_FLY, 0))

## Altura del modelo sin escalar (m), de sus mallas.
func _model_height() -> float:
	if not model.has_meta("meshes"): return 1.5
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in model.get_meta("meshes"):
		if not is_instance_valid(mi) or mi.mesh == null: continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.end.y - visual.global_position.y if not first else 1.5

func rising() -> bool:
	return _rise_wait > 0.0

func _rise_step(delta: float) -> void:
	_rise_t += delta
	var k := clampf(_rise_t / _rise_life, 0.0, 1.0)
	var out := 1.0 - pow(1.0 - k, 3.0)              # deprisa al principio y se asienta
	match _rise:
		Rise.GROUND, Rise.WATER:
			visual.global_position.y -= _rise_h * (1.0 - out)
			var st := sin(k * PI)                     # se estira al salir
			visual.scale *= Vector3(1.0 - 0.12 * st, 1.0 + 0.15 * st, 1.0 - 0.12 * st)
		Rise.AIR:
			visual.global_position.y += RISE_FLY * (1.0 - out)
		Rise.FOG:
			Crumble.set_cut(_rise_mats, 1.02 * (1.0 - k * k * (3.0 - 2.0 * k)))
	if k >= 1.0: _rise_end()

## Se sacude el agua como un perro (hito 17.11): giros rápidos que se calman y gotas al principio.
## En el contenedor del modelo: vale también con la horda.
func _shake_step(delta: float) -> void:
	var k := _shake_t / SHAKE_TIME
	if _shake_t == 0.0 and world != null:
		WadeSplash.burst(world.fx, global_position + Vector3(0, 0.6, 0), 0.35 + data.body_radius * 0.4, Color(0, 0, 0, 0), "auto", false)
	_shake_t += delta
	if k >= 1.0:
		_shake_t = -1.0
		return
	var a := sin(_shake_t * TAU * 7.0) * 0.32 * (1.0 - k) * (0.5 if model_scale > 1.5 else 1.0)
	visual.basis = Basis(Vector3.UP, a) * Basis(visual.basis.z.normalized() if visual.basis.z.length_squared() > 0.0001 else Vector3.FORWARD, a * 0.3) * visual.basis

## Trepa al salir del agua (hito 17.11): los brazos arriba y delante, agarrándose, que tiran hacia
## abajo según sube; el tronco echado adelante.
func _climb_pose() -> void:
	var k := clampf(_rise_t / _rise_life, 0.0, 1.0)
	var pull := Anims.ease(k / 0.8)
	var reach := -2.6 + 1.9 * pull + sin(k * PI * 4.0) * 0.18          # brazo a brazo
	var parts: Dictionary = model.get_meta("part_nodes", {})
	if parts.has("arm_l"): (parts["arm_l"] as Node3D).rotation.x = reach
	if parts.has("arm_r"): (parts["arm_r"] as Node3D).rotation.x = -2.6 + 1.9 * pull - sin(k * PI * 4.0) * 0.18
	if parts.has("torso"): (parts["torso"] as Node3D).rotation.x += 0.35 * (1.0 - pull)
	if parts.has("head"): (parts["head"] as Node3D).rotation.x -= 0.25 * (1.0 - pull)

## Estirar y aplastar con los saltos (hito 11.7): se estira al subir o caer deprisa y se aplasta
## al tocar el suelo, con rebote. Sale de la altura dibujada, así que vale para cualquier salto
## (acechador, gigantes, picados de los que vuelan) y para las marionetas de la red. Los blandos,
## el doble; los grandes y los únicos, menos.
func _air_step(delta: float) -> void:
	if delta <= 0.0: return
	var y := visual.global_position.y
	var vy := 0.0 if _prev_y == INF else (y - _prev_y) / delta
	_prev_y = y
	if _vy < -2.5 and vy > -0.6:                    # acaba de tocar el suelo
		_land = clampf(-_vy / 7.0, 0.35, 1.0)
		_land_t = 0.0
	_vy = vy
	var amp := (2.0 if data.soft else 1.0) * (0.4 if model_scale > 1.5 or data.unique else 1.0)
	var st := clampf(absf(vy) / 9.0, 0.0, 1.0) * 0.14 * amp
	var sq := 0.0
	if _land_t < LAND_TIME:
		var k := _land_t / LAND_TIME
		sq = sin(k * PI * 1.5) * (1.0 - k) * 0.22 * _land * amp
		_land_t += delta
	if st > 0.0 or sq != 0.0:
		var w := 1.0 - st * 0.5 + sq * 0.7
		visual.scale *= Vector3(w, 1.0 + st - sq, w)

func _rise_end() -> void:
	if _climb and _rise == Rise.WATER: _shake_t = 0.0      # 17.11: fuera del agua, se sacude
	_climb = false
	if not _rise_mats.is_empty():
		Crumble.undress(_rise_mats)
		_rise_mats = []
	_rise = Rise.NONE

func _exit_tree() -> void:
	if world != null: world.remove_enemy(self)
	if _in_horde and is_instance_valid(_hdraw): _hdraw.remove(self, _horde)   # su plaza en la horda

func _notification(what: int) -> void:
	# el modelo de nodos, fuera del árbol mientras va con la horda: nadie más lo borraría
	if what == NOTIFICATION_PREDELETE and model != null and is_instance_valid(model) and model.get_parent() == null:
		model.free()

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

## Revelado durante `seconds` (Máquina del más allá, hito 20.20): recibe `bonus` más de daño de
## todo y, si estaba oculto (enterrado o desvanecido), sale (EnemyBehavior.reveal). Con `chain`,
## si muere así revienta (_reveal_burst).
func reveal(seconds: float, bonus: float, chain := 0.0) -> void:
	if _reveal_t <= 0.0:
		_reveal_k = 0.0
		_reveal_chain = 0.0
	_reveal_t = maxf(_reveal_t, seconds)
	_reveal_k = maxf(_reveal_k, bonus)
	_reveal_chain = maxf(_reveal_chain, chain)
	_reveal_tag = Damage.ctx
	if buried and behavior != null: behavior.reveal(self)

## Sueña `seconds` (zona de sueño de Kuranes, 20.22): solo el tinte; el freno lo pone la zona.
func dream(seconds: float) -> void:
	_dream_t = maxf(_dream_t, seconds)

## Gris y quebradizo durante `seconds` (el color que cayó del cielo, 21.13): recibe `bonus` más de
## daño de todo. Los que nacen del color (`data.param("of_color")`) no se agrisan.
func blight(seconds: float, bonus: float) -> void:
	if bool(data.param("of_color", false)): return
	_blight_t = maxf(_blight_t, seconds)
	_blight_k = maxf(_blight_k, bonus)

func is_blighted() -> bool:
	return _blight_t > 0.0

## Despierta de golpe (Combos, pesadilla, 21.6): deja de soñar y, si dormía, de estar quieto.
func wake() -> void:
	if _dream_t > 0.0: _stun = 0.0
	_dream_t = 0.0

func is_dreaming() -> bool:
	return _dream_t > 0.0

func is_revealed() -> bool:
	return _reveal_t > 0.0

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
func inject(ally_time: float, bonus: Dictionary = {}, power := 1.0) -> void:
	_inject_t = INJECT_TIME
	_ally_time = ally_time
	_inject_bonus = bonus
	_inject_power = power

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
		if blocks(d):
			_block_fx()
			return
		_hit_flash()
		_hit_pose(d)
		var guess := d.physical                # la cifra, aproximada (sin las bonificaciones)
		for tag in data.tags: guess *= float(d.bonus.get(tag, 1.0))
		_number(guess, false, d.dot)
		return
	if shield_t > 0.0: return
	if not is_alive(): return
	if ward > 0 and not d.dot:                 # el escudo de icor para el golpe y revienta (16.14)
		set_ward(ward - 1)
		Auto.sfx_at("glass", global_position)
		VoxelFx.puff(world.fx, global_position + Vector3(0, 0.6 * model_scale, 0), "sparkle", 0.5, WARD_COLOR)
		_hit_flash()
		return
	if blocks(d):                              # el escudo del guardián para lo que llega de frente (16.17)
		_block_fx()
		return
	Auto.sfx_at("hit", global_position)
	var k := VULNERABLE_MULT if _vulnerable > 0.0 else 1.0
	if idol_t > 0.0: k *= IDOL_GUARD           # al amparo del ídolo vivo (16.18)
	if _reveal_t > 0.0: k *= 1.0 + _reveal_k   # revelado por la máquina (20.20)
	if _blight_t > 0.0: k *= 1.0 + _blight_k   # gris y quebradizo (el color, 21.13)
	if not _touched: k *= float(d.bonus.get(Player.FRESH_TAG, 1.0))   # ileso hasta ahora (Aldaba, 20.21)
	for tag in data.tags: k *= float(d.bonus.get(tag, 1.0))    # rasgos contra este tipo de enemigo
	if data.elite or data.unique: k *= float(d.bonus.get(Player.ELITE_TAG, 1.0))   # Medallón del cazador
	if _stun > 0.0 or _root_t > 0.0: k *= float(d.bonus.get(Player.HELD_TAG, 1.0))   # Signo de Tsathoggua (16.9)
	if _stasis_t > 0.0:                        # congelado: el daño se guarda para el final
		_stasis_store += d.physical * k
		_hit_flash()
		return
	var dealt := minf(d.physical * k, maxf(health, 0.0))
	health -= d.physical * k
	_touched = true
	if health <= 0.0 and data.revive > 0.0 and not _revived:   # expedicionario: cae, pero aún no está muerto
		_fall_down(d)
		return
	world.record_damage(d.tag, dealt)              # estadísticas de la ficha
	if not d.dot: world.player_hit(d.tag, self)    # objetos al impactar (hito 8.7)
	if health <= 0.0:
		killed_by = d.tag
		killed_how = d.how
		world.record_kill(d.tag, global_position)
	_hit_flash()
	HitSparks.hit(world, self, d, hit_radius * 0.8, 0.6 * model_scale)   # impacto según el daño (hito 18.3)
	_knock += Vector3(d.knockback.x, 0, d.knockback.z) * (2.5 if not data.elite else 0.6)
	_hit_pose(d, dealt)
	var big := data.elite or data.unique
	# en dorado: con bonificación (rasgos, vulnerable) o un golpe fuerte a una élite
	_number(d.physical * k, k > 1.05 or (big and not d.dot and dealt >= data.max_health * health_scale * 0.08), d.dot)
	if big and not d.dot and dealt >= data.max_health * health_scale * 0.08 and health > 0.0:
		HitStop.hit(30)                                # golpe fuerte a una élite: micro-pausa (hito 11.1)
	if health <= 0.0:
		if big: HitStop.hit(70, true)
		_die()

## Destello blanco del golpe. En los jefes y los gigantes (más de media pantalla) el blanco
## casi opaco de los demás se veía como una silueta plana y, a golpe continuo, no se iba: ahí
## aclara sumando luz (se ve el modelo debajo), dura menos y deja una pausa entre destellos,
## así que parpadea al ritmo de los golpes (02-11-2026).
func _hit_flash() -> void:
	if _flash_is_big():
		if _flash_cd > 0.0: return
		_flash_cd = FLASH_BIG_GAP
		_flash = FLASH_BIG
		return
	_flash = 0.07

func _flash_is_big() -> bool:
	return data.unique or model_scale > 1.5

func _big_flash_material() -> StandardMaterial3D:
	if _flash_big_mat == null: _flash_big_mat = _shared_flash(true)
	return _flash_big_mat

## Materiales del destello, compartidos por todos los enemigos (hito 16.5: antes, uno nuevo por
## enemigo al aparecer). Uno por tipo y por ajuste de accesibilidad (Destellos: normales o reducidos).
static var _flash_mats := {}
static func _shared_flash(big: bool) -> StandardMaterial3D:
	var full := int(Auto.setting("flashes", 1)) == 1
	var key := "%s|%s" % [big, full]
	if not _flash_mats.has(key):
		var m := VoxelFx.std()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if big:                                    # jefes y gigantes: suma luz
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			var v := FLASH_BIG_ADD if full else FLASH_BIG_ADD * 0.35
			m.albedo_color = Color(v, v, v)
		else:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(1, 1, 1, 0.75 if full else 0.2)
		_flash_mats[key] = m
	return _flash_mats[key]

## Expedicionario (hito 15.3): la primera vez que «muere» cae al suelo con un poco de vida; un
## golpe más lo remata y, si no llega, se levanta a los `revive_time` s con `revive` de su vida.
func _fall_down(d: Damage) -> void:
	_revived = true
	health = 0.01
	_down_t = data.revive_time
	_hit_flash()
	_hit_pose(d)
	anim = "down"
	anim_t = 0.0
	_wu_t = -1.0
	Auto.sfx_at("down", global_position)

func _down_step(delta: float) -> void:
	if _down_t > 0.0:
		_down_t -= delta
		if anim == "down" and _down_t < data.revive_time - Anims.duration(model_name, "down"):
			anim = "down_wait"
			anim_t = 0.0
		if _down_t <= 0.0:                            # nadie lo remató: se levanta
			health = data.max_health * health_scale * data.revive
			_getup_t = Anims.duration(model_name, "get_up")
			anim = "get_up"
			anim_t = 0.0
			Auto.sfx_at("ice_crack", global_position)
		return
	_getup_t -= delta
	if _getup_t <= 0.0: anim = "walk"

## Tamborilero (hito 15.3): cada DRUM_EVERY s, un golpe de tambor que acelera a los cercanos.
func _drum_step(delta: float) -> void:
	_drum_next -= delta
	if _drum_next > 0.0: return
	_drum_next = DRUM_EVERY
	var r2 := data.drum_radius * data.drum_radius
	for n in world.enemies:
		var e := n as Enemy
		if e != null and e != self and e.is_alive() and e.global_position.distance_squared_to(global_position) <= r2:
			e.drum_t = DRUM_EVERY + 0.2
	if not _far: Auto.sfx_at("heartbeat", global_position)

## Golpe recibido (hito 11.2): se aplasta un poco y se inclina hacia donde lo empujan.
func _hit_pose(d: Damage, dealt := -1.0) -> void:
	_hit_t = 0.0
	# reacción de su familia (doblarse, tambalearse, temblar); los colosales, solo aplastados
	_hit_own = model_scale <= 1.5 and Anims.has_hit(model_name)
	_hit_len = Anims.hit_time(model_name, HIT_POSE) if _hit_own else HIT_POSE
	var dir := Vector3(d.knockback.x, 0.0, d.knockback.z)
	if dir.length_squared() < 0.0001: dir = Vector3(d.dir.x, 0.0, d.dir.z)          # 17.10: la bala, aunque no empuje
	if dir.length_squared() < 0.0001 and d.source is Node3D:
		dir = global_position - (d.source as Node3D).global_position
		dir.y = 0.0
	if dir.length_squared() < 0.0001 and not d.dot:           # 17.10: lejos de quien lo causa (J1:…)
		var who := _player_of(d.tag)
		if who != null:
			dir = global_position - who.global_position
			dir.y = 0.0
	_hit_dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector3.ZERO
	# 17.10: cuánto se echa atrás, según lo que le quita (un 15 % de su vida o más, del todo)
	var full := data.max_health * health_scale * 0.15
	_hit_k = 0.4 if d.dot or dealt < 0.0 else clampf(dealt / maxf(full, 0.001), 0.4, 1.0)

## La cabeza da un latigazo hacia donde lo empujan (hito 17.10), encima de la pose: hacia atrás si
## el golpe llega de frente, de lado si llega de lado. Con la horda no (va en la textura).
func _head_snap() -> void:
	var parts: Dictionary = model.get_meta("part_nodes", {})
	if not parts.has("head"): return
	var hd: Node3D = parts["head"]
	var loc := visual.global_basis.orthonormalized().inverse() * _hit_dir       # en el espacio del modelo (mira a +Z)
	var hs := sin(clampf(_hit_t / HIT_POSE, 0.0, 1.0) * PI) * _hit_k
	hd.rotation.x += 0.5 * hs * loc.z
	hd.rotation.z += -0.4 * hs * loc.x

## El jugador de una etiqueta de daño («J2:webly» -> J2), o null.
func _player_of(tag: StringName) -> Player:
	var t := String(tag)
	if world == null or t.length() < 2 or t[0] != "J" or not t[1].is_valid_int(): return null
	var i := int(t[1]) - 1
	for p in world.players:
		if is_instance_valid(p) and p.index == i: return p
	return null

## Se prepara para un ataque con aviso en el suelo que llega dentro de `seconds` (hito 12.5): su
## familia se agazapa, se yergue o se hincha mientras dura el aviso y suelta el golpe al final.
## Lo llaman el lanzador de patrones y los saltos y erupciones de los grandes; en red, el anfitrión
## lo repite en los invitados (`net` = false: ya llega de la red).
func windup(seconds: float, net := true) -> void:
	if seconds < 0.1: return
	_wu_t = 0.0
	_wu_len = seconds
	if net and world != null and world.on_net.is_valid(): world.on_net.call("windup", [self, seconds])

## (preparación, golpe) en este momento: la preparación sube en el 60 % del aviso y aguanta; al
## terminar, baja en WINDUP_RELEASE s mientras el golpe va y vuelve.
func windup_amount() -> Vector2:
	if _wu_t < 0.0: return Vector2.ZERO
	if _wu_t < _wu_len: return Vector2(Anims.ease(_wu_t / (_wu_len * 0.6)), 0.0)
	var u := (_wu_t - _wu_len) / WINDUP_RELEASE
	if u >= 1.0: return Vector2.ZERO
	return Vector2(1.0 - Anims.ease(u * 1.6), Anims.jolt(u, 0.3))

## Mide la altura del modelo (sin escalar) la primera vez que hace falta.
func _number_height() -> void:
	if _top_h < 0.0 and _in_horde: _top_h = _horde.height
	if _top_h < 0.0 and _spawn_t > 0.35 and model != null and model.has_meta("meshes"):
		var inv := model.global_transform.affine_inverse()
		_top_h = 0.8
		for mi: MeshInstance3D in model.get_meta("meshes"):
			if is_instance_valid(mi) and mi.mesh != null:
				_top_h = maxf(_top_h, (inv * mi.global_transform * mi.get_aabb()).end.y)

## Altura del modelo ya escalado (m): donde van sus ojos en «Ojos tras los muros» (21.7).
func top_height() -> float:
	_number_height()
	return (_top_h if _top_h > 0.0 else 1.2) * model_scale

## Cifra de daño encima del modelo (DamageNumbers).
func _number(amount: float, strong: bool, dot: bool) -> void:
	if not DamageNumbers.enabled or world == null: return
	_number_height()
	var h := (_top_h if _top_h > 0.0 else 1.2) * model_scale
	DamageNumbers.add(world.fx, self, amount, global_position + Vector3(0.0, h + 0.25, 0.0), strong, dot)

func _die() -> void:
	Auto.sfx_at("die", global_position)
	if _curse_t > 0.0 and int(_curse.get("spread", 0)) > 0: _spread_curse()
	if _reveal_t > 0.0 and _reveal_chain > 0.0: _reveal_burst()
	if _inject_t > 0.0 and _ally_time > 0.0:            # se levanta como aliado
		var r := Reanimated.new().setup(world, data, global_position, facing, _ally_time, _inject_bonus)
		r.dps *= _inject_power
		world.fx.add_child(r)
	_leave_remains()
	if traits != 0: EliteTraits.on_death(self)
	_death_fx()

## Muerte de una marioneta (lo avisa el anfitrión).
func puppet_die() -> void:
	if is_queued_for_deletion(): return
	health = 0.0
	Auto.sfx_at("die", global_position)
	if bool(data.param("unseen", false)) and visual != null:   # lo que no se ve (21.14) se ve al caer, como en el anfitrión
		buried = false
		visual.visible = true
	_leave_remains()
	_death_fx()

## Sus restos, para las Sales esenciales de Ward (hito 20.18). Los únicos y los grandes, no.
func _leave_remains() -> void:
	if world != null and not data.unique and data.model_scale <= 1.5: world.add_remains(data, global_position)

func _death_fx() -> void:
	var t0 := Prof.start()
	# cae y se deshace con su modelo de nodos; de la horda, posado pero aún fuera del árbol: entra
	# una sola vez, en Crumble (06-11-2026)
	if _in_horde: _leave_horde(false)
	_rise_end()
	# cae a su manera (hito 12.7: de rodillas, derrumbado, derretido, de lado) y luego se deshace;
	# los trozos saltan cuando empieza a deshacerse
	var fall := model_name if data.death != &"crumble" and not data.ethereal and Anims.death_time(model_name) > 0.0 else ""
	var light: Color = DeathBurst.palette_of(model_name, model)[0]
	for c: Color in DeathBurst.palette_of(model_name, model): if c.get_luminance() > light.get_luminance(): light = c
	var how := killed_how if not data.unique and not data.ethereal else &""   # los jefes, a su manera (17.9)
	var fx := DeathBurst.new()
	fx.setup(model_name, data.body_radius, model, data.elite or data.unique)
	fx.puddle = Anims.death_kind(fall) in ["puddle", "melt"] and _wade <= 0.5 and how != &"burn" and how != &"blast"
	fx.position = global_position
	if how == &"burn": fx.ashen()
	# el modelo se queda y se deshace en cubos (hito 11.1); la brasa, de su color más claro
	if Crumble.start(world.fx, model, light.lerp(Color(1.0, 0.45, 0.15), 0.55), data.elite or data.unique, fall, how, visual):
		fx.delay = Crumble.delay_for(fall, how)
	elif model != null and is_instance_valid(model) and model.get_parent() == null:
		model.queue_free()                            # no cuelga de nadie: no se iría con el enemigo
	world.fx.add_child(fx)
	if _wade > 0.5:                                   # cae al agua: ondas grandes (hito 11.4)
		Ripples.add(world.fx, global_position, 1.4 + data.body_radius * 2.0, 0.8, 1.6)
		Ripples.add(world.fx, global_position, 0.8 + data.body_radius, 0.6, 1.2)
	died.emit(self)
	queue_free()
	Prof.stop("muerte", t0)

## La maldición salta a los más cercanos que aún no la llevan.
## Medusas del más allá (hito 20.20): el revelado que muere revienta en un picotazo violeta que
## daña y revela a los de REVEAL_BURST_R. Los que solo revela él no revientan a su vez (los que ya
## había revelado la máquina, sí): la cadena se acaba.
func _reveal_burst() -> void:
	var chain := _reveal_chain
	_reveal_chain = 0.0
	var prev := Damage.ctx
	Damage.ctx = _reveal_tag
	for e in world.enemies_in_circle(global_position, REVEAL_BURST_R):
		if e == self or not e.has_method("reveal") or not e.is_alive(): continue
		e.reveal(maxf(_reveal_t, 1.5), _reveal_k)
		e.take_damage(Damage.new(chain, 0.0))
	Damage.ctx = prev
	VoxelFx.puff(world.fx, global_position, "beyond", REVEAL_BURST_R * 0.5, Color.WHITE, 0.6)
	if FxShade.on(): HitSparks.burst("glint_violet", global_position + Vector3(0, 0.4, 0))

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

const CROWD := 120                         ## enemigos: con más, piensan en pasos alternos y la pose va a medio ritmo
const POSE_HZ := 60.0                      ## la pose, como mucho a este ritmo aunque el monitor vaya a 120 o 144 Hz (hito 16.2)
const CROWD_POSE := 50                     ## con más enemigos, los pequeños se posan a `crowd_hz`
static var crowd_hz := 30.0                ## lo pone la calidad gráfica (`anim_crowd_hz`; en Ultra, 60)
static var anim_lod := true                ## anim_lod=false: la pose en cada fotograma, como antes (comparar)
var _pose_acc := 1.0                       ## tiempo desde la última pose (empieza vencido: la primera, enseguida)
var _posed_once := false
const FAR := 16.0                          ## m: más lejos de todos los jugadores, piensa a medio ritmo
var _far := false
var _ai_vel := Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_alive(): return
	if puppet:
		_spawn_t += delta
		_wade = move_toward(_wade, 1.0 if wades() else 0.0, WadeSplash.EASE * delta)
		if _rise_wait > 0.0: _rise_wait -= delta
		else: _puppet_touch(delta)
		behavior.puppet_step(self, delta)
		if traits != 0: EliteTraits.step(self, delta)
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
	if _rise_wait > 0.0:                             # apareciendo: quieto y sin hacer daño (los estados sí cuentan)
		_rise_wait -= delta
		velocity = Vector3.ZERO
		Prof.stop("enemigos_fisica", t0)
		return
	if _down_t > 0.0 or _getup_t > 0.0:              # caído o levantándose (expedicionario, 15.3)
		_down_step(delta)
		velocity = Vector3.ZERO
		Prof.stop("enemigos_fisica", t0)
		return
	if data.drum_radius > 0.0: _drum_step(delta)
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
		velocity = behavior.update(self, target, delta) * pace_mult 			* (Difficulty.melee_speed() if data.attack == null else Difficulty.shooter_speed()) * Pacts.value("enemy_speed") * NightEvents.speed_of(data)   # en vivo (D-42; Furia del abismo, hito 13.6; sucesos, 21.4)
		_ai_vel = velocity
	if Engine.get_physics_frames() % 15 == get_instance_id() % 15: _far = _far_from_players()
	if _slow_t > 0.0: velocity *= _slow_k
	if traits & EliteTraits.FAST: velocity *= EliteTraits.FAST_MULT   # élite rápida (16.20)
	if idol_t > 0.0: idol_t -= delta
	if drum_t > 0.0:                                  # al ritmo del tambor (15.3)
		drum_t -= delta
		velocity *= DRUM_SPEED
	var wet := wades()
	if wet: velocity *= WadeSplash.SLOW                # agua somera: los marinos nadan, los demás vadean
	_wade = move_toward(_wade, 1.0 if wet else 0.0, WadeSplash.EASE * delta)
	if _root_t > 0.0: velocity = Vector3.ZERO
	if _vulnerable > 0.0: _vulnerable -= delta
	if _reveal_t > 0.0: _reveal_t -= delta
	if _dream_t > 0.0: _dream_t -= delta
	if _blight_t > 0.0: _blight_t -= delta
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
		facing = turn_flat(facing, velocity, 1.0 - exp(-float(data.params.get("turn", 10.0)) * delta))   # turn: el guardián gira despacio (16.17)
	if guard_ring != null: guard_ring.rotation.y += 0.05
	if traits != 0: EliteTraits.step(self, delta)
	# Contacto con los jugadores
	if data.aura_drain > 0.0:                   # presencia: drena cordura a los de dentro del aura
		for p in world.players:
			if p.global_position.distance_to(global_position) <= data.aura_radius: p.drain_sanity(data.aura_drain * delta, String(data.id))
	for p in world.players if behavior.touches(self) and _madden_t <= 0.0 else []:
		if p.remote: continue                       # en red: lo decide su PC (marioneta, _puppet_touch)
		var r := data.body_radius + p.data.hurt_radius
		var pp := p.global_position
		if Vector2(pp.x - position.x, pp.z - position.z).length_squared() < r * r:
			var cd := behavior.contact_damage(self)
			p.take_damage(cd.scaled(_weak_k) if _weak_t > 0.0 else cd)
	# Ataque a distancia
	if data.attack != null and target != null and _stun <= 0.0 and _confuse_t <= 0.0 and _madden_t <= 0.0 and behavior.can_shoot(self):
		_attack_timer -= delta * Difficulty.attack()                 # agresividad (D-42)
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
	if trait_icon != null:                            # icono de los rasgos sobre la cabeza (16.20)
		trait_icon.visible = visual.visible
		if _top_h < 0.0: _number_height()
		trait_icon.global_position = visual.global_position + Vector3(0.0, ((_top_h if _top_h > 0.0 else 1.2) * ELITE_SIZE + 0.35) * model_scale + 0.1 * sin(_spawn_t * 2.5), 0.0)
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
	visual.scale = Vector3.ONE * clampf(_spawn_t / 0.35, 0.2, 1.0) * model_scale * (ELITE_SIZE if data.elite else 1.0) * var_size   # aparece creciendo (al cambiar de forma)
	if (var_lean > 0.0 or var_roll > 0.0) and facing.length_squared() > 0.0001:   # su manera de andar (17.12)
		var fw := Vector3(facing.x, 0.0, facing.z).normalized()
		var roll := sin(anim_t * TAU) * var_roll if anim == "walk" else 0.0
		visual.basis = Basis(fw, roll) * Basis(Vector3(fw.z, 0.0, -fw.x), var_lean) * visual.basis
	_air_step(delta)
	if _rise != Rise.NONE: _rise_step(delta)
	if _shake_t >= 0.0: _shake_step(delta)
	if _hit_t < _hit_len:                             # golpe: se aplasta y se inclina, y vuelve con rebote (hito 11.2)
		var hk := clampf(_hit_t / HIT_POSE, 0.0, 1.0)
		var s := sin(hk * PI * 1.5) * (1.0 - hk) * (0.35 if model_scale > 1.5 or data.unique else 1.0) * (1.5 if data.soft else 1.0)
		if not _hit_own:                              # la familia sin reacción propia, aplastada entera
			visual.scale *= Vector3(1.0 + 0.1 * s, 1.0 - 0.12 * s, 1.0 + 0.1 * s)
		if _hit_dir != Vector3.ZERO:                  # se echa atrás hacia donde lo empujan (17.10: según la fuerza)
			visual.basis = Basis(Vector3.UP.cross(_hit_dir), (0.12 + 0.26 * _hit_k) * s) * visual.basis
			visual.global_position += _hit_dir * 0.08 * _hit_k * maxf(s, 0.0) * (0.4 if model_scale > 1.5 or data.unique else 1.0)
		_hit_t += delta
	var wu := Vector2.ZERO
	var wu_own := false
	if _wu_t >= 0.0:                                  # preparándose para atacar (hito 12.5)
		wu = windup_amount()
		_wu_t += delta
		if _wu_t >= _wu_len + WINDUP_RELEASE: _wu_t = -1.0
		wu_own = Anims.has_windup(model_name)
		if not wu_own:                                # sin gesto propio: se agacha entero y se echa atrás
			var big := 0.5 if model_scale > 1.5 else 1.0
			visual.scale *= Vector3(1.0 + (0.08 * wu.x - 0.05 * wu.y) * big, 1.0 - (0.12 * wu.x - 0.1 * wu.y) * big, 1.0 + (0.08 * wu.x - 0.05 * wu.y) * big)
			visual.basis = Basis(Vector3(facing.z, 0.0, -facing.x).normalized() if facing.length_squared() > 0.0001 else Vector3.RIGHT, (-0.1 * wu.x + 0.14 * wu.y) * big) * visual.basis
	if _aura_mat: _aura_mat.set_shader_parameter("color", Color(0.45, 0.2, 0.7, 0.14 + 0.07 * sin(_spawn_t * 2.5)))
	if _mark_mat: _mark_mat.set_shader_parameter("color", Color(part_tint, 0.26 + 0.1 * sin(_spawn_t * 3.0)))
	if not _wound_meshes.is_empty():                  # heridas que crecen con la vida perdida (hito 12.6)
		var hk := wounds_force if wounds_force >= 0.0 else clampf(1.0 - health / maxf(data.max_health * health_scale, 0.001), 0.0, 1.0)
		if absf(hk - _wound_k) > 0.01:
			_wound_k = hk
			for mi: MeshInstance3D in _wound_meshes:
				if is_instance_valid(mi): mi.set_instance_shader_parameter("hurt", hk)
	if not anim_hold and _stasis_t <= 0.0 and world.freeze_t <= 0.0:   # congelado: la animación se detiene
		anim_t = fposmod(anim_t + delta / Anims.duration(model_name, anim) * var_tempo, 1.0)
	if _horde_ok and _spawn_t >= 0.35 and _rise_wait <= 0.0 and _rise_mats.is_empty() and visual.visible:
		_horde_step(delta, wu, wu_own)
		Prof.stop("enemigos_anim", t0)
		return
	if _in_horde: _leave_horde()
	# fuera de la vista no se aplica la pose (la animación sigue corriendo): con 200 enemigos
	# era una cuarta parte de su coste
	var cam := get_viewport().get_camera_3d()
	# animación por niveles de detalle (hito 16.2): la pose, como mucho a 60 Hz (a más no se nota
	# y el monitor puede ir a 120 o 144), y con mucha gente los pequeños a 30 (`crowd_hz`); con más
	# de CROWD, a la mitad. La posición sigue yendo en cada fotograma; solo la pose de las partes
	# se queda quieta entre una y otra. Los grandes, los jefes y las élites, siempre.
	_pose_acc += delta
	var big_one := model_scale > 1.5 or data.unique
	var hz := POSE_HZ
	var n := world.enemies.size()
	if not big_one and not data.elite and n > CROWD_POSE: hz = minf(hz, crowd_hz)
	if not big_one and n > CROWD: hz *= 0.5
	if not anim_lod: hz = 100000.0
	var period := 1.0 / hz
	var due := big_one or _pose_acc >= period
	if due and not big_one and (cam == null or cam.is_position_in_frustum(visual.global_position + Vector3(0, 1.0, 0))):
		if _posed_once: _pose_acc = fmod(_pose_acc, period)
		else:                                      # la primera pose, ya; luego, desfasados entre sí
			_posed_once = true
			_pose_acc = randf() * period
	elif not big_one: due = false
	if due:
		var tp := Prof.start()
		Anims.pose(model_name, anim, model, anim_t)
		Prof.stop("enemigos_pose", tp)
		if wu_own and wu != Vector2.ZERO: Anims.windup(model_name, model, wu.x, wu.y, _spawn_t)
		if data.alive: _alive_step(delta)
		# la reacción de su familia, encima de la pose (que la deshace en el siguiente fotograma)
		if _hit_own and _hit_t < _hit_len:
			Anims.hit(model_name, model, clampf(_hit_t / _hit_len, 0.0, 1.0))
		if _hit_t < HIT_POSE and _hit_dir != Vector3.ZERO: _head_snap()
		if _climb and _rise == Rise.WATER: _climb_pose()
	_flash -= delta
	_flash_cd -= delta
	if flash_hold: _flash = 1.0
	# tinte: destello al recibir daño; si no, turquesa en estasis o violeta maldito.
	# Solo se toca el material al cambiar.
	var want: Material = null
	var sc := _status_color() if tints and _flash <= 0.0 else Color(0, 0, 0, 0)
	if not tints: pass
	elif _flash > 0.0: want = _big_flash_material() if _flash_is_big() else _flash_mat
	elif sc.a > 0.0: want = _status(sc)
	if want != _overlay:
		_overlay = want
		for mi: MeshInstance3D in model.get_meta("meshes"):
			mi.material_overlay = want
	Prof.stop("enemigos_anim", t0)

## Jefes vivos (hito 12.8): respiran, parpadean despacio cada pocos segundos y la cabeza sigue
## al jugador más cercano, con retraso (hasta 0,55 rad a cada lado). Cada PC con sus jugadores.
func _alive_step(delta: float) -> void:
	var to := Vector3.ZERO
	var bd := INF
	for q in world.players:
		if q.health <= 0.0: continue
		var d := q.global_position - global_position
		if d.length_squared() < bd:
			bd = d.length_squared()
			to = d
	var want := 0.0
	if bd < INF: want = clampf(wrapf(atan2(to.x, to.z) - visual.rotation.y, -PI, PI), -0.55, 0.55)
	_look = lerpf(_look, want, 1.0 - exp(-delta * 2.5))
	if _spawn_t > _blink_at + 0.22: _blink_at = _spawn_t + randf_range(3.5, 7.0)
	Anims.alive(model, _spawn_t, _look, _spawn_t > _blink_at)

## Élites (hito 12.6): ojos y luces más vivos y grietas que crecen con la vida perdida (también
## en los únicos y los grandes). Las grietas, una segunda pasada (wounds.gdshader) en una copia
## de su material; los demás enemigos no la llevan (serían 150 modelos dibujados dos veces).
func _dress_model() -> void:
	_wound_meshes = []
	_wound_k = -1.0
	if data.elite:
		for mi: MeshInstance3D in model.get_meta("meshes"):
			var base := mi.material_override as StandardMaterial3D
			if base == null or int(mi.get_meta("kind", 0)) != 1: continue
			if not _elite_glow.has(base):
				var g := base.duplicate() as StandardMaterial3D
				g.albedo_color = Color(ELITE_EYES, ELITE_EYES, ELITE_EYES)
				_elite_glow[base] = g
			mi.material_override = _elite_glow[base]
	if wounds and (data.elite or data.unique or model_scale > 1.5) and not data.ethereal:
		_wound_meshes = wound_dress(model, model_name)

## Pone las grietas a un modelo (también en el visor, `hurt=`): devuelve sus mallas, a las que se
## les cambia `hurt` (0..1). Sangre roja en los humanos, icor verde en las masas y verdoso en los demás.
static func wound_dress(m: Node3D, mname: String) -> Array:
	if _wound_mat == null:
		_wound_mat = ShaderMaterial.new()
		_wound_mat.shader = preload("res://scripts/fx/wounds.gdshader")
	var kind := Anims.death_kind(mname)
	var blood := Color(0.55, 0.04, 0.03) if kind == "kneel" else (Color(0.42, 0.62, 0.1) if kind == "melt" else Color(0.3, 0.42, 0.2))
	var vs := float(m.get_meta("voxel_size", VoxelBuilder.VOXEL))
	var out := []
	for mi: MeshInstance3D in m.get_meta("meshes"):
		var base := mi.material_override as StandardMaterial3D
		if base == null or int(mi.get_meta("kind", 0)) != 0: continue
		if not _wounded.has(base):
			var m2 := base.duplicate() as StandardMaterial3D
			m2.next_pass = _wound_mat
			_wounded[base] = m2
		mi.material_override = _wounded[base]
		mi.set_instance_shader_parameter("vox", vs)
		mi.set_instance_shader_parameter("tint", blood)
		mi.set_instance_shader_parameter("hurt", 0.0)
		out.append(mi)
	return out

## Disco difuminado que late en el suelo: el aura de presencia (GDD 4.4, violeta, de su radio) o
## la marca de las élites (hito 12.6, del color de la parte, bajo sus pies).
func _disc(c: Color, radius: float) -> ShaderMaterial:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/fx/telegraph.gdshader")
	mat.set_shader_parameter("fill", true)
	mat.set_shader_parameter("soft", true)
	mat.set_shader_parameter("color", c)
	mi.material_override = mat
	# cuelga del modelo, que va a model_scale (y más si es élite): sin descontarlo, el aura de un jefe
	# grande se dibujaba hasta el triple de su radio de verdad (21.14)
	var base := model_scale * (ELITE_SIZE if data.elite else 1.0) * var_size
	mi.scale = Vector3.ONE * radius / maxf(base, 0.01)
	mi.position.y = 0.05 / maxf(base, 0.01)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(mi)
	return mat

## Material de tinte de estado (uno por enemigo, se cambia su color).
## Tinte de estado (alfa 0 si no hay): turquesa en estasis, violeta maldito, fuego, veneno…
func _status_color() -> Color:
	if _stasis_t > 0.0 or world.freeze_t > 0.0: return Color(0.35, 0.95, 1.0, 0.5)
	if _curse_t > 0.0: return Color(0.55, 0.12, 0.7, 0.35 + 0.1 * sin(_spawn_t * 9.0))
	if _burn_t > 0.0: return Color(1.0, 0.5, 0.12, 0.3 + 0.1 * sin(_spawn_t * 13.0))
	if _poison_t > 0.0: return Color(0.35, 0.85, 0.15, 0.3 + 0.08 * sin(_spawn_t * 7.0))
	if _madden_t > 0.0: return Color(1.0, 0.85, 0.15, 0.3 + 0.12 * sin(_spawn_t * 10.0))
	if _confuse_t > 0.0: return Color(0.95, 0.75, 0.95, 0.22 + 0.1 * sin(_spawn_t * 11.0))
	if _inject_t > 0.0: return Color(0.8, 0.95, 0.25, 0.14 + 0.06 * sin(_spawn_t * 12.0))   # suero: tenue (el aliado, verde intenso)
	if _reveal_t > 0.0: return Color(0.72, 0.64, 1.0, (0.2 + 0.08 * sin(_spawn_t * 4.0)) * float(data.param("reveal_tint", 1.0)))     # revelado: luz violeta pálida (20.20; `reveal_tint` la templa)
	if _blight_t > 0.0: return Color(0.55, 0.55, 0.53, 0.55 + 0.06 * sin(_spawn_t * 3.0))   # gris de ceniza (21.13)
	if _dream_t > 0.0: return Color(0.62, 0.84, 0.95, 0.2 + 0.08 * sin(_spawn_t * 2.5)).lerp(Color(0.95, 0.68, 0.84, 0.24), 0.5 + 0.5 * sin(_spawn_t * 1.3))   # soñando (20.22)
	return Color(0, 0, 0, 0)

## Con la horda (hito 16.3): la fila de la pose (el golpe y la preparación del ataque, si la
## familia los tiene, sustituyen a la animación mientras duran) y el destello o el tinte.
func _horde_step(delta: float, wu: Vector2, wu_own: bool) -> void:
	if not _in_horde: _enter_horde()
	var row: int
	if _hit_own and _hit_t < _hit_len and _horde.has_anim("_hit"):
		row = _horde.row("_hit", clampf(_hit_t / _hit_len, 0.0, 1.0))
	elif wu_own and wu != Vector2.ZERO and _horde.has_anim("_windup"):
		row = _horde.row("_strike", wu.y) if wu.y > 0.01 else _horde.row("_windup", wu.x)
	else:
		row = _horde.row(anim, anim_t)
	_flash -= delta
	_flash_cd -= delta
	if flash_hold: _flash = 1.0
	var tint := Color(0, 0, 0, 0)
	if tints:
		if _flash > 0.0: tint = _flash_mat.albedo_color
		else: tint = _status_color()
	_hdraw.place(self, _horde, visual.global_transform, row, tint)

func _enter_horde() -> void:
	_in_horde = true
	_horde = HordeMesh.get_type(model_name)
	_hdraw = HordeDraw.of(world)
	if _overlay != null:                              # que al volver no lleve un tinte viejo
		_overlay = null
		for mi: MeshInstance3D in model.get_meta("meshes"): mi.material_overlay = null
	if model.get_parent() == visual: visual.remove_child(model)

## `attach` false: lo posa sin meterlo en el árbol (al morir, lo mete Crumble).
func _leave_horde(attach := true) -> void:
	_in_horde = false
	if is_instance_valid(_hdraw): _hdraw.remove(self, _horde)
	if model != null and is_instance_valid(model) and model.get_parent() == null:
		if attach: visual.add_child(model)
		Anims.pose(model_name, anim, model, anim_t)
	_pose_acc = 1.0                                   # que se pose en seguida

func _status(c: Color) -> StandardMaterial3D:
	if _status_mat == null:
		_status_mat = VoxelFx.std()
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
	if f & 1 and _flash <= 0.0: _hit_flash()
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
	if ward > 0: f |= 4
	if small: f |= 8
	if buried: f |= 16
	if _reveal_t > 0.0: f |= 32
	if _dream_t > 0.0: f |= 64
	return f

func net_apply_flags2(f: int) -> void:
	if visual != null: visual.visible = (f & 1) == 0
	if ((f & 2) != 0) != (guard_ring != null): set_guard_ring((f & 2) != 0)
	if ((f & 4) != 0) != (ward > 0): set_ward(1 if (f & 4) != 0 else 0)
	if (f & 8) != 0 and not small: set_small()
	buried = (f & 16) != 0
	_reveal_t = 1.0 if (f & 32) != 0 else 0.0
	_dream_t = 1.0 if (f & 64) != 0 else 0.0

## Escudo de icor (grados de locura, 16.14): una burbuja verdinegra que para `n` golpes.
const WARD_COLOR := Color(0.45, 0.95, 0.55)
static var _ward_mat: ShaderMaterial              ## uno para todos
func set_ward(n: int) -> void:
	ward = maxi(n, 0)
	if ward <= 0:
		if _ward_mesh != null: _ward_mesh.queue_free()
		_ward_mesh = null
		return
	if _ward_mesh != null: return
	_ward_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	var r := maxf(data.body_radius * model_scale * 1.5, 0.45)
	sm.radius = r
	sm.height = maxf(r * 2.0, _model_height() * model_scale * 1.15)
	sm.radial_segments = 16
	sm.rings = 8
	_ward_mesh.mesh = sm
	if _ward_mat == null:
		_ward_mat = ShaderMaterial.new()
		_ward_mat.shader = preload("res://scripts/fx/ward.gdshader")
	_ward_mesh.material_override = _ward_mat
	_ward_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ward_mesh.position.y = sm.height * 0.5
	add_child(_ward_mesh)

## Escudo frontal (guardián de la Orden, hito 16.17, `params.front_shield` = medio ángulo en
## grados): para lo que llega de frente (balas, tajos, empujones); por los lados, por detrás, las
## zonas y los daños continuos, no. La dirección sale de `Damage.dir`, del empuje o de quién lo da.
const SHIELD_COLOR := Color(0.85, 0.62, 0.30)
var _block_cd := 0.0
func blocks(d: Damage) -> bool:
	var arc := float(data.params.get("front_shield", 0.0))
	if arc <= 0.0 or d.dot or buried: return false
	var dir := d.dir if d.dir != Vector3.ZERO else d.knockback
	if dir == Vector3.ZERO and d.source is Node3D and is_instance_valid(d.source):
		dir = global_position - (d.source as Node3D).global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001: return false
	return dir.normalized().dot(facing) < -cos(deg_to_rad(arc))

func _block_fx() -> void:
	var at := global_position + facing * (data.body_radius * model_scale + 0.1) + Vector3(0, 0.85 * model_scale, 0)
	var now := Time.get_ticks_msec() / 1000.0
	if now < _block_cd: return
	_block_cd = now + 0.12
	VoxelFx.puff(world.fx, at, "sparkle", 0.35, SHIELD_COLOR, 0.6)
	Auto.sfx_at("bell", at)

## Nacida de partirse otra (grado III): más pequeña.
func set_small() -> void:
	small = true
	model_scale *= WaveDirector.SPLIT_SCALE

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
	var m := VoxelFx.std()
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
			p.drain_sanity(data.aura_drain * delta, String(data.id))
		if net_contact <= 0: continue
		var r := data.body_radius + p.data.hurt_radius
		var pp := p.global_position
		if Vector2(pp.x - position.x, pp.z - position.z).length_squared() < r * r:
			var d := Damage.new(data.contact_physical, data.contact_mental).scaled(net_contact / 50.0)
			d.source = self
			d.via = &"contacto"
			p.take_damage(d)
