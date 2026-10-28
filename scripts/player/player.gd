class_name Player
extends CharacterBody3D
## Personaje jugable: aplica el PlayerMotor con la física, orienta y anima el modelo
## y dibuja el anillo del color del jugador bajo sus pies.

signal dodged
signal damaged(d: Damage)
signal downed                    ## vida a cero
signal revived                   ## un compañero lo ha levantado (cooperativo)
signal eliminated                ## se acabó su tiempo derribado: fuera hasta el siguiente nivel
signal stepped                   ## un pie toca el suelo al andar (pasos: Ambient)

const LAYER_WORLD := 1
const LAYER_PLAYERS := 2
## Capa de dibujo de los modelos de los jugadores: el farol propio no los ilumina (de tan cerca les
## quemaba la cara y el pecho); los ilumina una luz suave aparte (CarryFill), solo en esta capa.
const VIS_PLAYER := 1 << 1

var data: CharacterData
var input: PlayerInput
var motor: PlayerMotor
var color := Color(1.0, 0.82, 0.3)
var index := 0                   ## J1 = 0 … J4 = 3
## En red (hito 9.3a): lo maneja otro PC. No lee su entrada ni recibe daño aquí; su posición,
## vida, cordura y estado llegan por la red (`net_apply`). Cada PC manda en sus jugadores (D-10).
var remote := false
var dodge_count := 0             ## esquives empezados (la red lo usa para repetirlos en los demás PC)
var _net_flags := 0              ## jugador remoto: estado que no se calcula aquí (ver `net_flags`)
## Correa del cooperativo (hito 2.9): recoloca al jugador para que no salga del encuadre
## máximo de la cámara compartida. Sin asignar, no hace nada.
var leash := Callable()
## Reanimación (hito 2.10, GDD 4.6): en cooperativo, con la vida a cero queda derribado
## `rules.down_time` s; un compañero en pie a menos de `revive_radius` lo levanta en
## `revive_time` s (más rápido si reanima Whipple). Si nadie lo hace, queda eliminado.
var revivable := false
var down_left := -1.0            ## s que le quedan derribado (-1: no lo está)
var revive_progress := 0.0       ## s de reanimación acumulados
var is_eliminated := false
var rules: ProgressionData
var _down_ring: MeshInstance3D
var _down_mat: ShaderMaterial
var _elim_t := 0.0
## Cordura completa (hito 2.11)
var lights: Array[Node3D] = []   ## luces del escenario (recuperan cordura cerca)
var madness := true              ## locura acumulada activada (configuración)
var _wander := 0.0               ## rumbo del vagar sin rumbo (rad)
## Potenciadores comprados en la tienda (Shop.bonuses): multiplicadores de vida, cordura,
## daño y velocidad. Vacío: sin tienda.
var shop := {}
var mental_resist := 1.0         ## fracción del daño mental que recibe
var pet: Node                    ## su compañero (Pet), si lleva
var pet_xp_mult := 1.0          ## experiencia extra por gema (búho de los sueños)
var visual: Node3D          ## contenedor que gira hacia donde mira; dentro, el modelo voxel
var model: Node3D
var _crisis_look: CrisisLook
var _face: FaceLook              ## parpadeo y mueca de dolor
var health := 0.0
var sanity := 0.0
var weapons: WeaponSystem
var world: CombatWorld
var progress: PlayerProgress
const CALM_RADIUS := 4.0
const ARMOR_FLOOR := 0.2         ## parte del golpe físico que siempre pasa la armadura
const ELITE_TAG := "elite"       ## rasgo de daño contra élites y seres únicos (Enemy.take_damage)
## Estadísticas de los objetos (D-38) que rebuild_stats rehace desde la base del personaje.
const ITEM_STATS: Array[String] = ["proj_count_add", "range_mult", "proj_speed_mult", "area_mult",
	"weapon_cooldown_mult", "duration_mult", "pierce_add", "crit_chance", "crit_bonus", "damage_mult",
	"firearm_mult", "physical_mult", "magic_mult", "elite_mult", "knockback_mult", "armor", "mental_mult",
	"health_regen", "sanity_regen", "heal_on_kill", "sanity_on_kill", "crisis_mult", "money_mult",
	"chest_mult", "pickup_heal_mult", "pet_mult", "hit_iframes", "arcane_cost_mult", "thorns", "nodens_level",
	"ankh", "dodge_charges", "decoy_time", "dodge_blast", "dodge_fury", "rerolls", "kill_blast", "hit_slow",
	"hit_burn", "low_hp_bonus", "idol_mult"]
## Objetos con mecánica (hito 8.7)
const LOW_HP := 0.3              ## por debajo de esta parte de la vida cuenta el Diente de shoggoth
const FURY_TIME := 2.0           ## s de daño extra tras esquivar (Elixir de Curwen)
const ANKH_HEALTH := 0.3         ## vida con la que se levanta (Ankh de Nephren)
const BLAST_RADIUS := 2.0        ## estallidos de la Tablilla de Eltdown y de los Petardos
const KILL_BLAST_DAMAGE := 14.0
const HIT_SLOW := Vector2(1.5, 0.5)   ## s y velocidad del Cristal de Ithaqua
const HIT_BURN := Vector2(3.0, 6.0)   ## s y daño por segundo de los Fósforos de Cthugha
const DECOY_RADIUS := 7.0
## Tienda (17-10-2026)
const LANTERN_RANGE := 1.4       ## farol propio con la Linterna de queroseno
const LANTERN_SANITY := 1.5      ## y la cordura vuelve más deprisa
const FILL_POS := Vector3(0.9, 2.3, 1.1)   ## luz de los jugadores (CarryFill), respecto al cuerpo
const FILL_ENERGY := 1.2
const SECOND_LIFE_HEALTH := 0.5  ## vida con la que te levanta la Medalla de San Cristóbal
var second_lives_used := 0       ## Medalla de San Cristóbal gastadas en este nivel
var banishes_used := 0           ## descartes de las Cartas del tarot en este nivel
var _nodens_t := 0.0             ## s cargando el Escudo de Nodens
var _nodens_fx: MeshInstance3D
var _ankh_used := false
var _fury_t := 0.0
var rerolls_used := 0            ## cambios de opciones gastados en este nivel (Llave de plata)
var sanity_state: SanityState
var god := false                 ## depuración: no recibe daño
var attrs_level1 := {}           ## atributos del nivel 1 (fijan las probabilidades de subida)
var attrs := {}                  ## atributos actuales
var last_attr := ""              ## el que subió en la última subida de nivel
var debug_speed := 1.0           ## menú de depuración: multiplica la velocidad
var _attr_rng := RandomNumberGenerator.new()
var _anim := "idle"
var _anim_t := 0.0
var _hurt_time := -1.0           ## tiempo desde el último golpe (-1 = nunca)
var _fidget := ""                ## gesto de reposo en curso (anim_humano.FIDGETS)
var _fidget_t := 0.0
var _still_t := 0.0              ## s quieto, sin esquivar ni lanzar
var _fidget_at := 6.0            ## s quieto hasta el siguiente gesto (al azar en FIDGET_GAP)
const FIDGET_GAP := Vector2(5.0, 10.0)
var _override := ""              ## gesto del tren superior (lanzar) que se suma a la animación
var _override_t := 0.0
var _action := ""                ## animación de acción en curso (el esquive) y su tiempo
var _action_t := 0.0
var _ghost_t := 0.0
var _blend_snap: Array = []      ## pose de la que se parte al cambiar de animación
var _blend_t := 1.0
var _blend_len := 0.0
var _snow: GPUParticles3D        ## nieve que levanta al deslizarse
const UPPER_BODY: Array[String] = ["arm_r", "arm_l", "torso", "fore_r", "fore_l"]
var _ring_mat: StandardMaterial3D
var _ring: MeshInstance3D
const MUZZLE_TIME := 0.07
var _muzzle: OmniLight3D
var _muzzle_t := 0.0
var _gem_pulse := 0.0                         ## el anillo se ensancha y aclara al recoger gemas (hito 11.2)
var _frozen_mat: StandardMaterial3D
var _frozen_on := false
var _xray: ShaderMaterial
var push := Vector3.ZERO         ## velocidad externa de este paso (peligros: Ángulos que atraen, olas); se consume
var _wade := 0.0                 ## 0..1: cuánto está metido en el agua somera (pantano)
var _splash: GPUParticles3D      ## salpicaduras al vadear
var _ground_lift := 0.0          ## cuánto se sube el modelo para no hundirse en el suelo
const GROUND_EASE := 1.5         ## m/s a los que baja cuando ya no hace falta

func setup(p_data: CharacterData, p_input: PlayerInput, p_color: Color) -> Player:
	data = p_data.duplicate()        # copia propia: los atributos y las pasivas la modifican
	attrs_level1 = Attributes.initial(p_data)
	attrs = attrs_level1.duplicate()
	_attr_rng.randomize()
	input = p_input
	color = p_color
	motor = PlayerMotor.new(data)
	rules = load("res://data/progression/default.tres")
	progress = PlayerProgress.new(rules)
	progress.color = color
	progress.leveled_up.connect(func(_l: int) -> void: gain_attribute())
	rebuild_stats()
	health = data.max_health
	sanity = data.max_sanity
	sanity_state = SanityState.new(rules)
	sanity_state.weights = data.crisis_weights          # pesos propios de las crisis (si los tiene)
	name = "Player_%s" % data.id
	return self

func _ready() -> void:
	collision_layer = LAYER_PLAYERS
	collision_mask = LAYER_WORLD
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING   # juego cenital: sin gravedad ni suelos
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = data.collision_radius
	cyl.height = 1.6
	shape.shape = cyl
	shape.position.y = 0.8
	add_child(shape)
	visual = Node3D.new()
	visual.name = "Visual"
	# El cuerpo se mueve con la física (interpolado); el modelo se orienta y se anima en
	# _process, así que queda fuera de la interpolación. Pero un nodo sin interpolación
	# dentro del cuerpo se dibuja en la posición del último paso de física, no en la
	# interpolada: a 120 Hz el modelo avanzaba a saltos y vibraba contra la cámara. Por eso
	# va suelto (top_level) y en cada fotograma se coloca en la posición interpolada.
	visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visual.top_level = true
	add_child(visual)
	model = VoxelBuilder.load_model("res://models/%s.json" % data.model)
	OutfitData.apply(model, data.model, OutfitData.worn_for(String(data.id)))   # vestuario (D-34)
	_face = FaceLook.new().setup(model, VoxelBuilder.variant_path("res://models/%s.json" % data.model))
	add_child(_face)
	_set_vis_layer(model)
	visual.add_child(model)
	# Silueta del color del jugador cuando lo tapa el decorado
	_xray = ShaderMaterial.new()
	_xray.shader = preload("res://scripts/player/occluded_silhouette.gdshader")
	_xray.set_shader_parameter("color", Color(color, 0.6))
	for mi: MeshInstance3D in model.get_meta("meshes"):
		mi.material_overlay = _xray
	_ring = _make_ring()
	add_child(_ring)
	_crisis_look = CrisisLook.new().setup(model)      # aura morada y cara de pánico en las crisis
	add_child(_crisis_look)
	_snow = _make_snow_spray()
	add_child(_snow)
	_splash = WadeSplash.make()
	add_child(_splash)
	_frozen_mat = StandardMaterial3D.new()          # tinte violeta durante las congelaciones
	_frozen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_frozen_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_frozen_mat.albedo_color = Color(UiKit.SANITY * 0.6, 0.45)
	# Farol propio: luz cálida y corta que destaca al jugador en la oscuridad (pilar de legibilidad)
	var lamp := OmniLight3D.new()
	lamp.name = "CarryLight"
	lamp.position = Vector3(0.25, 1.5, 0.35)
	lamp.light_color = Color(1.0, 0.8, 0.55)
	lamp.light_energy = 1.1
	lamp.omni_range = 4.5
	lamp.omni_attenuation = 1.4
	lamp.light_cull_mask = 0xFFFFF & ~VIS_PLAYER       # el mundo y las criaturas, no los jugadores
	add_child(lamp)
	# Luz de los jugadores: más lejos (hacia la cámara y más alta) y repartida, para que la cara
	# y el pecho no salgan blancos a tamaño de juego (27-10-2026)
	var fill := OmniLight3D.new()
	fill.name = "CarryFill"
	fill.position = FILL_POS
	fill.light_color = lamp.light_color
	fill.light_energy = FILL_ENERGY
	fill.omni_range = 4.0
	fill.omni_attenuation = 1.0
	fill.light_cull_mask = VIS_PLAYER
	add_child(fill)
	reset_physics_interpolation.call_deferred()      # no interpolar desde el origen al aparecer

## Pasa el modelo (con su vestuario) a la capa de los jugadores.
static func _set_vis_layer(node: Node) -> void:
	if node is VisualInstance3D: (node as VisualInstance3D).layers = VIS_PLAYER
	for c in node.get_children(): _set_vis_layer(c)

func _physics_process(delta: float) -> void:
	# el anillo late al recoger gemas: su escala, en la física (va dentro del jugador, que se
	# interpola; cambiarla en _process avisaba «Interpolated instance triggered…»)
	var rs := Vector3.ONE * (1.0 + 0.22 * _gem_pulse)
	if _ring != null and _ring.scale != rs: _ring.scale = rs
	var t0 := Prof.start()
	_physics_process_step(delta)
	Prof.stop("jugadores_fisica", t0)

func _physics_process_step(delta: float) -> void:
	if remote:                                   # lo mueve la red (NetGame)
		if _hurt_time >= 0.0: _hurt_time += delta
		if health <= 0.0 and down_left > 0.0: down_left = maxf(down_left - delta, 0.0)
		return
	if health <= 0.0:
		_downed_step(delta)
		return
	input.update(delta)
	var near := world != null and world.nearest_enemy(global_position, sanity_state.rules.horror_radius) != null
	_sanity_context()
	var before := sanity_state.crises
	sanity = sanity_state.update(delta, sanity, data.max_sanity, near)
	if sanity_state.crises != before and madness: rebuild_stats()      # locura acumulada
	_presence_step(delta)
	if data.calm_aura > 0.0 and world != null:       # rasgo de Iwanicki: calma a sí mismo y a los cercanos
		for p in world.players:
			if p.health > 0.0 and p.global_position.distance_to(global_position) <= CALM_RADIUS:
				p.sanity = minf(p.data.max_sanity, p.sanity + data.calm_aura * delta)
	if data.health_regen > 0.0: health = minf(data.max_health, health + data.health_regen * delta)   # Botiquín
	if data.sanity_regen > 0.0: sanity = minf(data.max_sanity, sanity + data.sanity_regen * delta)   # Pipa
	if _fury_t > 0.0: _fury_t -= delta
	_nodens_step(delta)
	motor.locked = sanity_state.is_frozen()
	var was_dodging := motor.is_dodging()
	var ss := sanity_state
	var move := _crisis_move(delta, input.move)
	var dodge := input.just_pressed(InputBindings.DODGE) and not (ss.is_kind(&"huida") or ss.is_kind(&"vagar"))
	velocity = motor.step(delta, move, dodge)
	if in_water() and not motor.is_dodging(): velocity *= WadeSplash.SLOW   # agua somera: frena
	velocity += push
	push = Vector3.ZERO
	if ss.is_kind(&"huida"): velocity *= rules.flee_speed
	elif ss.is_kind(&"vagar"): velocity *= rules.wander_speed
	move_and_slide()
	position.y = 0.0
	if world != null and world.obstacles != null and world.obstacles.has_mask():   # límites y decorado dibujados
		var p2 := world.obstacles.push_out(Vector2(position.x, position.z), data.hurt_radius + 0.05)
		position.x = p2.x; position.z = p2.y
	if leash.is_valid(): global_position = leash.call(global_position)
	if motor.is_dodging() and not was_dodging:
		Auto.sfx_at("dodge", global_position)
		if world != null: Gusts.push(world.fx, global_position, 0.07, 2.2)   # lo que roza se mueve (hito 11.4)
		_action = data.dodge_anim         # la animación del esquive empieza con el impulso
		_action_t = 0.0
		_on_dodge()
		dodge_count += 1
		dodged.emit()
	if _hurt_time >= 0.0: _hurt_time += delta

## Lo que rodea al jugador para su cordura: luces y compañeros cerca aceleran la
## recuperación; compañeros al lado que no estén en crisis la acortan (calmar).
func _sanity_context() -> void:
	var ss := sanity_state
	var k := 1.0
	var here := global_position
	for l in lights:
		if is_instance_valid(l) and Vector2(l.global_position.x - here.x, l.global_position.z - here.z).length() <= rules.light_radius:
			k *= rules.regen_near_light
			break
	if float(shop.get("lantern", 0.0)) > 0.0: k *= LANTERN_SANITY         # Linterna de queroseno (tienda)
	var calm := 0.0
	if world != null:
		var mate := false
		for q in world.players:
			if q == self or q.health <= 0.0: continue
			var d := q.global_position.distance_to(here)
			if d <= rules.mate_radius: mate = true
			if d <= rules.revive_radius and not q.sanity_state.in_crisis: calm = maxf(calm, q.data.revive_speed)
		if mate: k *= rules.regen_near_mate
	ss.regen_mult = k
	ss.calm_speed = calm

## Movimiento durante una crisis: huida (lejos del horror más cercano, sin control),
## vagar (rumbo errático, obedece poco) o delirio (controles invertidos).
func _crisis_move(delta: float, move: Vector2) -> Vector2:
	var ss := sanity_state
	if ss.is_kind(&"delirio"): return -move
	if ss.is_kind(&"huida"):
		var e := world.nearest_enemy(global_position, 14.0) if world != null else null
		var away := (global_position - e.global_position) if e != null else motor.facing
		away.y = 0.0
		return _to_screen(_free_heading(away.normalized()))
	if ss.is_kind(&"vagar"):
		_wander += (sin(ss.crisis_time * 1.7) * 2.0 + sin(ss.crisis_time * 4.3)) * delta
		var w := Vector2(cos(_wander), sin(_wander))
		return (w * (1.0 - rules.wander_obey) + move * rules.wander_obey).limit_length(1.0)
	return move

## Rumbo de huida que no choca (12-10-2026): en línea recta se quedaba pegado a una pared
## de 4 a 6 s sin control y parecía enganchado al decorado. Prueba el rumbo pedido y otros
## cada vez más abiertos, a los dos lados, y se queda con el primero libre a 1,2 m.
func _free_heading(dir: Vector3) -> Vector3:
	var obs: ObstacleMap = world.obstacles if world != null else null
	if obs == null: return dir
	var here := Vector2(global_position.x, global_position.z)
	for ang in [0.0, 0.5, -0.5, 1.0, -1.0, 1.6, -1.6, 2.2, -2.2, PI]:
		var d := dir.rotated(Vector3.UP, ang)
		if not obs.is_blocked(here + Vector2(d.x, d.z) * 1.2, data.hurt_radius):
			return d
	return dir

## Del suelo al espacio de la pantalla (inverso de PlayerMotor.screen_to_world).
static func _to_screen(d: Vector3) -> Vector2:
	return Vector2(d.dot(PlayerMotor.screen_to_world(Vector2(1, 0))), d.dot(PlayerMotor.screen_to_world(Vector2(0, 1))))

## Presencia de una élite o un jefe: drena cordura sin contar como golpe.
## Presencia (12-10-2026): los enemigos cercanos drenan cordura, más cuanto más cerca, cuantos
## más y cuanto más alto su escalón (las élites y los seres únicos, mucho). Se mira cada
## PRESENCE_EVERY s; tope PRESENCE_MAX por segundo. Aparte de las auras de algunos enemigos.
const PRESENCE_RADIUS := 5.0
const PRESENCE_BASE := 0.16                 ## cordura/s por enemigo corriente pegado al jugador
const PRESENCE_MAX := 4.5
const PRESENCE_EVERY := 0.2
const PRESENCE_GRACE := 6.0                ## s sin drenar al acabar una crisis (que no se encadenen)
var _presence_t := 0.0
var presence := 0.0                         ## cordura/s que drena ahora mismo (HUD, tests)

func _presence_step(delta: float) -> void:
	_presence_t -= delta
	if _presence_t <= 0.0:
		_presence_t = PRESENCE_EVERY
		presence = 0.0
		if world != null and not god and not sanity_state.in_crisis and sanity_state.since_crisis >= PRESENCE_GRACE:
			var w := 0.0
			for e in world.enemies_in_circle(global_position, PRESENCE_RADIUS):
				if not (e is Enemy) or not e.is_alive(): continue
				var ed: EnemyData = (e as Enemy).data
				var k := 8.0 if ed.unique else (3.0 if ed.elite else 0.6 + 0.25 * ed.tier)
				var near := 1.0 - clampf(global_position.distance_to(e.global_position) / PRESENCE_RADIUS, 0.0, 1.0)
				w += k * near
			presence = minf(w * PRESENCE_BASE * Difficulty.horror(), PRESENCE_MAX)
	if presence > 0.0:
		drain_sanity(presence * delta)
		recv_add("presencia", 0.0, presence * delta)

## Daño recibido por origen (simulaciones de equilibrio: "RECIBIDO J1 {...}" con log=true):
## id del enemigo -> [vida, cordura].
var received := {}
static var bench_immortal := OS.get_cmdline_user_args().has("immortal=true")
func recv_add(src: String, ph: float, me: float) -> void:
	if not received.has(src): received[src] = [0.0, 0.0]
	received[src][0] += ph
	received[src][1] += me
	min_hp = minf(min_hp, health / maxf(data.max_health, 1.0))   # take_damage ya ha restado el golpe
var min_hp := 1.0                       ## la vida más baja del nivel, en fracción (simulaciones)

## Vibración suave del mando al recibir daño (12-10-2026), según lo fuerte del golpe. Respeta
## Configuración > Juego > Vibración del mando y no se repite más de una vez cada 0,15 s.
var _rumble_ms := 0

func _rumble(amount: float) -> void:
	if input == null or amount <= 0.0: return
	var dev := input.joy_device()
	if dev < 0 or not bool(Auto.setting("vibration", false)): return
	var now := Time.get_ticks_msec()
	if now - _rumble_ms < 150: return
	_rumble_ms = now
	var k := clampf(amount / 30.0, 0.0, 1.0)
	Input.start_joy_vibration(dev, 0.2 + 0.3 * k, 0.25 * k, 0.12 + 0.12 * k)

func drain_sanity(amount: float) -> void:
	if health <= 0.0 or god or remote: return
	sanity = maxf(0.0, sanity - amount * mental_resist * data.mental_mult)

## Derribado: corre el tiempo y avanza la reanimación si hay un compañero al lado (si se
## aparta, lo avanzado se va perdiendo despacio).
func _downed_step(delta: float) -> void:
	if not revivable or is_eliminated or down_left < 0.0: return
	down_left -= delta
	var speed := 0.0
	if world != null:
		for q in world.players:
			if q == self or q.health <= 0.0: continue
			if q.global_position.distance_to(global_position) <= rules.revive_radius:
				speed = maxf(speed, q.data.revive_speed)
	if speed > 0.0: revive_progress += delta * speed
	else: revive_progress = maxf(0.0, revive_progress - delta * 0.5)
	if revive_progress >= rules.revive_time:
		revive()
	elif down_left <= 0.0:
		is_eliminated = true
		down_left = 0.0
		eliminated.emit()

## Vuelve a la lucha con parte de la vida y un momento de invulnerabilidad.
func revive() -> void:
	health = data.max_health * rules.revive_health
	down_left = -1.0
	revive_progress = 0.0
	motor.locked = false
	_hurt_time = 0.0
	Anims.reset(model)
	if _down_ring: _down_ring.visible = false
	revived.emit()

func is_downed() -> bool:
	return health <= 0.0 and not is_eliminated

## Tendido boca abajo con el anillo de la reanimación; eliminado, se hunde y desaparece.
func _downed_visual(delta: float) -> void:
	var here := get_global_transform_interpolated().origin
	Anims.reset(model)
	model.rotation.x = PI * 0.47                      # de bruces, hacia donde miraba
	model.position.y = 0.22
	visual.global_position = here
	_snow.emitting = false
	if not revivable: return
	if _down_ring == null:
		_down_ring = MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(rules.revive_radius * 2.0, rules.revive_radius * 2.0)
		_down_ring.mesh = pm
		_down_mat = ShaderMaterial.new()
		_down_mat.shader = preload("res://scripts/fx/revive_ring.gdshader")
		_down_ring.material_override = _down_mat
		_down_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_down_ring.top_level = true
		_down_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(_down_ring)
	_down_ring.global_position = Vector3(here.x, 0.06, here.z)
	if is_eliminated:
		_elim_t += delta
		_down_ring.visible = false
		model.position.y = 0.22 - _elim_t * 0.5
		visual.visible = _elim_t < 1.2
		return
	_down_ring.visible = true
	_down_mat.set_shader_parameter("bleed", clampf(down_left / rules.down_time, 0.0, 1.0))
	_down_mat.set_shader_parameter("revive", clampf(revive_progress / rules.revive_time, 0.0, 1.0))

func _process(delta: float) -> void:
	var t0 := Prof.start()
	_process_step(delta)
	Prof.stop("jugadores_anim", t0)

func _process_step(delta: float) -> void:
	if health <= 0.0:
		visual.rotation.x = 0.0; visual.rotation.z = 0.0
		_lean = Vector2.ZERO; _lean_vel = Vector2.ZERO
		_downed_visual(delta)
		return
	visual.visible = true
	var here := get_global_transform_interpolated().origin
	_xray.set_shader_parameter("center_world", here + Vector3(0, 0.85, 0))
	# Girar el modelo hacia donde mira (el modelo mira hacia +Z)
	var target := atan2(motor.facing.x, motor.facing.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target, 1.0 - exp(-data.turn_speed * delta))
	# Animación según el estado
	# Crisis de locura: anillo violeta que late y tinte violeta en cada congelación
	var ss := sanity_state
	if _crisis_look and ss.in_crisis != _crisis_look._on: _crisis_look.set_on(ss.in_crisis)
	_face.suppressed = ss.in_crisis
	var frozen := (_net_flags & NET_FROZEN) != 0 if remote else ss.is_frozen()
	var trembling := (_net_flags & NET_TREMBLING) != 0 if remote else ss.is_trembling()
	if ss.in_crisis:
		_ring_mat.albedo_color = UiKit.SANITY.lerp(Color.WHITE, 0.25 + 0.25 * sin(Time.get_ticks_msec() * 0.012))
	else:
		_ring_mat.albedo_color = color.lerp(Color.WHITE, 0.6 * _gem_pulse)
	_gem_pulse = move_toward(_gem_pulse, 0.0, delta * 4.0)
	if _muzzle != null:
		_muzzle.visible = _muzzle_t > 0.0
		_muzzle.light_energy = 3.0 * maxf(_muzzle_t / MUZZLE_TIME, 0.0)
		_muzzle_t -= delta
	if frozen != _frozen_on:
		_frozen_on = frozen
		for mi: MeshInstance3D in model.get_meta("meshes"):
			mi.material_overlay = _frozen_mat if frozen else _xray
	# Temblor de aviso antes de cada congelación de la parálisis
	var shake := Vector3(randf_range(-0.04, 0.04), 0, randf_range(-0.04, 0.04)) if trembling else Vector3.ZERO
	visual.global_position = here + shake
	_lean_step(here, delta, frozen)
	# Parpadeo durante la invulnerabilidad tras un golpe
	visual.visible = not (_hurt_time >= 0.0 and _hurt_time < data.hit_iframes and fmod(_hurt_time, 0.12) < 0.06)
	_animate(delta)
	_keep_above_ground(delta)
	_wade = move_toward(_wade, 1.0 if in_water() else 0.0, WadeSplash.EASE * delta)
	visual.position.y -= _wade * WadeSplash.SINK        # metido en el agua hasta los tobillos
	_splash.emitting = _wade > 0.5 and motor.velocity.length() > 0.3
	_ripple_step()
	var style := data.dodge_style
	_snow.emitting = _action != "" and (style == null or style.snow_spray)
	# Destello: el modelo desaparece en su tramo y deja una estela de imágenes fantasma
	if _action != "" and style != null:
		var u := _action_t / Anims.duration(data.model, _action)
		if u >= style.hidden_from and u < style.hidden_to:
			visual.visible = false
		if style.afterimages and u >= 0.1 and u < style.hidden_to:       # estela breve y tenue
			_ghost_t -= delta
			if _ghost_t <= 0.0 and world != null:
				_ghost_t = 0.05
				world.fx.add_child(Afterimage.new().setup(model, color.lerp(Color(0.85, 0.95, 1.0), 0.6), 0.28))

## Inclinación (hito 11.1): hacia donde acelera, atrás al frenar (con un pequeño rebote: un
## muelle poco amortiguado) y hacia dentro en las curvas. La aceleración sale de la posición
## dibujada (la diferencia entre su velocidad, apenas suavizada, y la misma muy suavizada), así
## que vale también para los jugadores de otros PC. En el contenedor, como el giro.
const LEAN_K := 0.045                          ## rad por m/s de diferencia
const LEAN_MAX := 0.2
var _lean := Vector2.ZERO                      ## x: adelante; y: de lado (rotation.z)
var _lean_vel := Vector2.ZERO
var _lean_prev := Vector3.INF
var _v_fast := Vector3.ZERO
var _v_slow := Vector3.ZERO

func _lean_step(here: Vector3, delta: float, frozen: bool) -> void:
	if delta <= 0.0: return
	var v := Vector3.ZERO if _lean_prev == Vector3.INF else (here - _lean_prev) / delta
	_lean_prev = here
	v.y = 0.0
	if v.length() > 25.0: v = _v_fast                # reaparece o la colocan: no es un acelerón
	_v_fast = _v_fast.lerp(v, 1.0 - exp(-25.0 * delta))
	_v_slow = _v_slow.lerp(_v_fast, 1.0 - exp(-7.0 * delta))
	var target := Vector2.ZERO
	if _action == "" and not frozen:
		var d := _v_fast - _v_slow
		var yaw := visual.rotation.y
		var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
		var right := Vector3(cos(yaw), 0.0, -sin(yaw))
		target = Vector2(clampf(d.dot(fwd) * LEAN_K, -LEAN_MAX, LEAN_MAX), clampf(-d.dot(right) * LEAN_K, -LEAN_MAX, LEAN_MAX))
	var dt := minf(delta, 1.0 / 30.0)
	_lean_vel += ((target - _lean) * 160.0 - _lean_vel * 13.0) * dt
	_lean += _lean_vel * dt
	visual.rotation.x = _lean.x
	visual.rotation.z = _lean.y

## Animación por capas: una base (reposo, andar o esquive) que se funde al cambiar y,
## encima, el gesto de lanzar solo en brazos y torso, con entrada y salida suaves.
func _animate(delta: float) -> void:
	# El esquive dura lo que su animación (una voltereta necesita algo más que el impulso)
	if _action != "":
		# reloj propio a ritmo de fotograma: motor.dodge_time avanza en pasos de física
		# (60 Hz) y en monitores más rápidos la pose iría a saltos
		_action_t += delta
		if _action_t >= Anims.duration(data.model, _action): _action = ""
	var anim := "idle"
	if _action != "": anim = _action
	elif motor.velocity.length() > 0.1: anim = "walk"
	anim = _fidget_step(anim, delta)
	if anim != _anim:
		var was_action := _anim in ["slide", "roll", "dive", "jump", "flash"]
		_blend_snap = Anims.snapshot(model)
		_blend_t = 0.0
		# entrar en el esquive, rápido; salir de él (incorporarse), algo más lento
		_blend_len = 0.06 if anim == _action and _action != "" else (0.22 if was_action else 0.15)
		_anim = anim
		if anim != "walk": _anim_t = 0.0
	var t: float
	if _action != "":
		t = _action_t / Anims.duration(data.model, _action)
	elif _fidget != "":
		t = _fidget_t / Anims.duration(data.model, _fidget)
	elif anim == "walk":
		# cadencia proporcional a la velocidad real: los pies no patinan
		var before := _anim_t
		_anim_t += delta * (motor.velocity.length() / data.move_speed) / Anims.duration(data.model, "walk")
		if floorf(_anim_t * 2.0 - 0.5) != floorf(before * 2.0 - 0.5): stepped.emit()   # pies abajo en 0,25 y 0,75
		t = fposmod(_anim_t, 1.0)
	else:
		_anim_t += delta / Anims.duration(data.model, anim)
		t = fposmod(_anim_t, 1.0)
	Anims.pose(data.model, anim, model, t)
	if _blend_t < _blend_len:
		_blend_t += delta
		Anims.blend_from(model, _blend_snap, Anims.ease(_blend_t / _blend_len))
	if _override != "":
		_override_t += delta / Anims.duration(data.model, _override)
		if _override_t >= 1.0:
			_override = ""
		elif _action == "":
			var w := smoothstep(0.0, 0.2, _override_t) * (1.0 - smoothstep(0.7, 1.0, _override_t))
			Anims.overlay(data.model, _override, model, _override_t, w, UPPER_BODY)

## Gestos de reposo (28-10-2026): tras unos segundos quieto (sin andar, esquivar ni lanzar,
## y fuera de una crisis), un gesto al azar de los que tenga su juego de animaciones (mirar
## alrededor, estirarse, revisar el arma, cambiar el peso). Moverse lo corta (con fundido).
func _fidget_step(anim: String, delta: float) -> String:
	var calm := anim == "idle" and _override == "" and not sanity_state.in_crisis and not is_downed()
	if not calm:
		_still_t = 0.0
		_fidget = ""
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
var _last_fidget := ""

## Su cara (parpadeo y mueca), para que el retrato del HUD la copie.
func face_look() -> FaceLook:
	return _face

## ¿Está en agua somera? (capa "water" del mapa de la arena, hito 6.4)
func in_water() -> bool:
	return world != null and world.obstacles != null and world.obstacles.water_at(Vector2(position.x, position.z)) > 0.5

## Ninguna pose puede meter el cuerpo en el suelo: tras animar, se mide el punto más bajo
## del modelo (las cajas de sus mallas, en el espacio de Visual) y, si queda por debajo de
## la nieve, se sube el modelo lo justo. Vale para cualquier esquive o animación.
## Sube al instante lo que haga falta, pero baja poco a poco (GROUND_EASE m/s): en la
## voltereta el punto más bajo cambia de golpe al rodar y, bajando de golpe, daba tirones.
func _keep_above_ground(delta: float) -> void:
	# altura sobre los pies medida en el mundo: el contenedor puede ir inclinado (hito 11.1)
	var inv := Transform3D(Basis(), -visual.global_position)
	var lowest := INF
	for mi: MeshInstance3D in model.get_meta("meshes"):
		var xf := inv * mi.global_transform
		# puntos reales de la pieza (no las esquinas de su caja: al inclinarse quedan muy por
		# debajo del voxel más bajo y lo levantaban de más, y el deslizamiento no se tumbaba)
		for v: Vector3 in _extremes(mi):
			lowest = minf(lowest, (xf * v).y)
	var needed := maxf(-lowest, 0.0)
	_ground_lift = maxf(needed, _ground_lift - GROUND_EASE * delta)
	# en el contenedor (se recoloca cada fotograma), no en el modelo: la pose del modelo se
	# captura para los fundidos y la subida se sumaría dos veces
	visual.position.y += _ground_lift

## Vértices extremos de una malla en 98 direcciones (se calculan una vez por malla): bastan
## para saber el punto más bajo de la pieza girada como se quiera.
static func _extremes(mi: MeshInstance3D) -> PackedVector3Array:
	var mesh := mi.mesh
	if mesh.has_meta("extremes"): return mesh.get_meta("extremes")
	var out := PackedVector3Array()
	var dirs: Array[Vector3] = []
	for x in [-2, -1, 0, 1, 2]:
		for y in [-2, -1, 0, 1, 2]:
			for z in [-2, -1, 0, 1, 2]:
				if maxi(maxi(absi(x), absi(y)), absi(z)) == 2: dirs.append(Vector3(x, y, z).normalized())
	var best: Array[float] = []
	best.resize(dirs.size())
	best.fill(-INF)
	out.resize(dirs.size())
	for s in mesh.get_surface_count():
		var verts: PackedVector3Array = mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
		for v in verts:
			for k in dirs.size():
				var d := v.dot(dirs[k])
				if d > best[k]:
					best[k] = d
					out[k] = v
	mesh.set_meta("extremes", out)
	return out

## Nieve que salta de los pies al deslizarse: cubitos blancos que quedan atrás.
func _make_snow_spray() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "SnowSpray"
	p.amount = 36
	p.lifetime = 0.55
	p.emitting = false
	p.local_coords = false
	p.position = Vector3(0, 0.1, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	pm.direction = Vector3.UP
	pm.spread = 55.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.045
	pm.scale_max = 0.09
	var fade := Gradient.new()
	fade.set_color(0, Color(0.95, 0.97, 1.0, 1.0))
	fade.set_color(1, Color(0.85, 0.9, 0.97, 0.0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	p.process_material = pm
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = bm
	p.draw_pass_1 = box
	return p

## Aplica un estilo de esquive (animación, velocidad, duración, invulnerabilidad, recarga
## y efectos). Lo usa la depuración y la tecla F1 de pruebas.
func apply_dodge_style(style: DodgeStyle) -> void:
	data.dodge_style = style
	rebuild_stats()

## Rehace desde cero las estadísticas que dependen de atributos, esquive y pasivas (así se
## pueden subir y bajar sin acumular errores): la base del personaje, por los multiplicadores
## de sus atributos (Attributes), el estilo de esquive y, encima, las mejoras pasivas.
## La vida y la cordura ganadas se rellenan; si bajan, no pasan del nuevo máximo.
func rebuild_stats() -> void:
	var base: CharacterData = load(data.resource_path) if data.resource_path != "" else null
	if base == null: base = load("res://data/characters/%s.tres" % data.id)
	var old_health := data.max_health
	var old_sanity := data.max_sanity
	var style := data.dodge_style
	if style != null:
		data.dodge_anim = style.anim
		data.dodge_speed = style.speed
	var v := {
		"max_health": base.max_health * Attributes.mult(attrs, "health") * float(shop.get("health", 1.0)),
		"max_sanity": base.max_sanity * Attributes.mult(attrs, "sanity") * _madness_factor() * float(shop.get("sanity", 1.0)),
		"move_speed": base.move_speed * Attributes.mult(attrs, "speed") * float(shop.get("speed", 1.0)),
		"dodge_duration": (style.duration if style else base.dodge_duration) * data.dodge_length,
		"dodge_iframes": (style.iframes if style else base.dodge_iframes) * data.dodge_length,
		"dodge_cooldown": (style.cooldown if style else base.dodge_cooldown) * data.dodge_cooldown_mult / Attributes.mult(attrs, "dodge") / float(shop.get("reflex", 1.0)),
		"pickup_radius": base.pickup_radius * float(shop.get("magnet", 1.0)),     # Imán (tienda)
		"xp_mult": base.xp_mult * float(shop.get("insight", 1.0)),                # Erudición (tienda)
		"luck": base.luck * float(shop.get("fortune", 1.0)),                      # Fortuna (tienda)
	}
	v["dodge_speed"] = style.speed if style else base.dodge_speed   # Crampones lo multiplican
	for k in ITEM_STATS: v[k] = base.get(k)              # objetos (D-38): desde la base cada vez
	# tienda (17-10-2026): Amuleto de Kadath, Metrónomo de Zann, Lente de Wilmarth, Arena de Irem,
	# Teodolito de Lake, Sales de amoníaco y Mira telescópica
	v["mental_mult"] *= 1.0 - float(shop.get("ward", 0.0))
	v["weapon_cooldown_mult"] *= 1.0 - float(shop.get("haste", 0.0))
	v["area_mult"] *= float(shop.get("area", 1.0))
	v["duration_mult"] *= float(shop.get("duration", 1.0))
	v["range_mult"] *= float(shop.get("reach", 1.0))
	v["health_regen"] += float(shop.get("regen", 0.0))
	v["crit_chance"] += float(shop.get("crit", 0.0))
	for up in progress.upgrade_pool if progress else []:
		up.apply_levels(v, base, int(progress.passives.get(up.id, 0)))
	v["move_speed"] *= debug_speed
	for k in v: data.set(k, v[k])
	var tags := base.bonus_tags.duplicate()                  # Medallón del cazador: contra élites y únicos
	if data.elite_mult != 1.0: tags[ELITE_TAG] = data.elite_mult
	if tags != data.bonus_tags:
		data.bonus_tags = tags
		if weapons: weapons.bonus_changed()
	if sanity_state: sanity_state.duration_mult = data.crisis_mult
	if motor: motor.data = data
	var lamp := get_node_or_null("CarryLight") as OmniLight3D      # Linterna de queroseno (tienda)
	if lamp != null: lamp.omni_range = 4.5 * (LANTERN_RANGE if float(shop.get("lantern", 0.0)) > 0.0 else 1.0)
	# derribado o eliminado (la experiencia es común: sube igual), no: se levantaba sin que lo reanimaran
	if health > 0.0: health = minf(health + maxf(data.max_health - old_health, 0.0), data.max_health)
	sanity = minf(sanity + maxf(data.max_sanity - old_sanity, 0.0), data.max_sanity)

## Locura acumulada (GDD 4.5): cada crisis del nivel quita un poco de cordura máxima.
func _madness_factor() -> float:
	if not madness or sanity_state == null or rules == null: return 1.0
	return maxf(rules.madness_floor, 1.0 - rules.madness_step * sanity_state.crises)

## Subida de nivel: +1 en un atributo, al azar con las probabilidades del nivel 1 (D-27).
func gain_attribute() -> String:
	last_attr = Attributes.roll_point(attrs_level1, _attr_rng)
	attrs[last_attr] = int(attrs[last_attr]) + 1
	progress.attr_gains.append(last_attr)
	rebuild_stats()
	return last_attr

## Multiplicador de daño de un arma según su tipo y los atributos (D-27).
func damage_mult(category: int) -> float:
	var k := float(shop.get("damage", 1.0)) * data.damage_mult   # Puntería (tienda) y objetos
	if _fury_t > 0.0: k *= 1.0 + data.dodge_fury                  # Elixir de Curwen
	if data.low_hp_bonus > 0.0 and health < data.max_health * LOW_HP: k *= 1.0 + data.low_hp_bonus   # Diente de shoggoth
	match category:
		WeaponData.Category.PHYSICAL: return Attributes.mult(attrs, "physical") * data.physical_mult * k
		WeaponData.Category.MAGIC: return Attributes.mult(attrs, "magic") * data.magic_mult * k
	return Attributes.mult(attrs, "firearm") * data.firearm_mult * k

func is_invulnerable() -> bool:
	return motor.is_invulnerable() or (_hurt_time >= 0.0 and _hurt_time < data.hit_iframes)

## ¿Puede recibir un impacto ahora? (Uno de otro PC, aquí nunca: lo decide su PC.)
func is_hittable() -> bool:
	return health > 0.0 and not god and not remote and not is_invulnerable()

## Recibe un ataque: la parte física resta vida y la mental, cordura.
func take_damage(d: Damage) -> void:
	if not is_hittable(): return
	if nodens_ready() and (d.physical > 0.0 or d.mental > 0.0):   # Escudo de Nodens: absorbe el golpe entero
		_nodens_t = 0.0
		_hurt_time = 0.0
		Auto.sfx_at("magic", global_position)
		return
	if Difficulty.damage() != 1.0 or Difficulty.mental() != 1.0:    # dificultad (12-10-2026)
		var sd := Damage.new(d.physical * Difficulty.damage(), d.mental * Difficulty.mental())
		sd.knockback = d.knockback; sd.source = d.source; sd.bonus = d.bonus; sd.tag = d.tag
		d = sd
	if d.source is Enemy and data.thorns > 0.0 and d.physical > 0.0 and (d.source as Enemy).is_alive():
		_item_hit(d.source, d.physical * data.thorns, "escamas")     # Escamas de Profundo
	if d.source is Enemy and not data.resist_tags.is_empty():   # rasgos: resistencia a ciertas criaturas
		var k := 1.0
		for tag in (d.source as Enemy).data.tags: k *= float(data.resist_tags.get(tag, 1.0))
		if k != 1.0: d = d.scaled(k)
	var guard := 1.0 - float(shop.get("guard", 0.0))              # Coraza de Pabodie (tienda)
	if (data.physical_resist != 1.0 or data.armor > 0.0 or guard != 1.0) and d.physical > 0.0:   # aguante físico y armadura
		var ph := d.physical * data.physical_resist * guard
		ph = maxf(ph - data.armor, ph * ARMOR_FLOOR)          # la armadura nunca quita más del 80 %
		var r := Damage.new(ph, d.mental)
		r.knockback = d.knockback; r.source = d.source; r.bonus = d.bonus
		d = r
	health = maxf(0.0, health - d.physical)
	if bench_immortal: health = maxf(health, 1.0)        # banco de objetos: recibe el daño pero no cae
	var src := "otro"
	if d.source is Enemy and is_instance_valid(d.source): src = String((d.source as Enemy).data.id)
	recv_add(src, d.physical, d.mental * mental_resist * data.mental_mult)
	Auto.sfx_at("hit_player" if d.physical > 0.0 else "chant", global_position)
	_rumble(d.physical + d.mental * 0.5)
	if d.physical >= data.max_health * 0.12:
		if not (input is BotInput): HitStop.hit(45, true)   # golpe fuerte (hito 11.1)
		var cam := get_viewport().get_camera_3d() as GameCamera   # y tiembla la cámara de este PC (hito 11.2)
		if cam != null: cam.shake(clampf(d.physical / data.max_health, 0.12, 0.4) * 0.6)
	if d.mental > 0.0:
		sanity = maxf(0.0, sanity - d.mental * mental_resist * data.mental_mult)
		sanity_state.on_mental_damage()
	_hurt_time = 0.0
	_face.hurt()
	damaged.emit(d)
	if health <= 0.0 and data.ankh > 0.0 and not _ankh_used:       # Ankh de Nephren: se levanta una vez
		_ankh_used = true
		health = data.max_health * ANKH_HEALTH
		Auto.sfx("level_up")
		var game := get_tree().current_scene if is_inside_tree() else null
		if game != null and game.has_method("announce"): game.announce("El ankh de Nephren te devuelve a la vida", 2.0)
		return
	if health <= 0.0 and second_lives_used < int(shop.get("second_life", 0.0)):   # Medalla de San Cristóbal (tienda)
		second_lives_used += 1
		health = data.max_health * SECOND_LIFE_HEALTH
		_hurt_time = 0.0
		Auto.sfx("level_up")
		var game2 := get_tree().current_scene if is_inside_tree() else null
		if game2 != null and game2.has_method("announce"): game2.announce("La medalla de San Cristóbal te protege", 2.0)
		return
	if health <= 0.0:
		motor.locked = true
		if revivable:
			down_left = rules.down_time
			revive_progress = 0.0
		Auto.sfx_at("down", global_position)
		downed.emit()

## Ha abatido a un enemigo (CombatWorld.record_kill): Colmillo de ghoul, Salterio y Tablilla
## de Eltdown (sus propios estallidos no encadenan otros).
func on_kill(tag: StringName = &"", pos := Vector3.INF) -> void:
	if health <= 0.0: return
	if data.heal_on_kill > 0.0: health = minf(data.max_health, health + data.heal_on_kill)
	if data.sanity_on_kill > 0.0: sanity = minf(data.max_sanity, sanity + data.sanity_on_kill)
	if data.kill_blast > 0.0 and pos != Vector3.INF and not String(tag).ends_with(":tablilla") and randf() < data.kill_blast:
		blast(pos, KILL_BLAST_DAMAGE, "tablilla")

## Ha golpeado a un enemigo (Enemy.take_damage): Cristal de Ithaqua y Fósforos de Cthugha.
func on_hit(e: Node3D) -> void:
	if data.hit_slow > 0.0 and e.has_method("slow") and randf() < data.hit_slow: e.slow(HIT_SLOW.x, HIT_SLOW.y)
	if data.hit_burn > 0.0 and e.has_method("ignite") and randf() < data.hit_burn:
		var prev := Damage.ctx
		Damage.ctx = item_tag("fosforos")
		e.ignite(HIT_BURN.x, HIT_BURN.y * damage_mult(WeaponData.Category.PHYSICAL), data.bonus_tags)
		Damage.ctx = prev

## Etiqueta de las estadísticas para lo que hace un objeto: "J1:tablilla".
func item_tag(item: String) -> StringName:
	return StringName("J%d:%s" % [index + 1, item])

## Explosión de un objeto (Tablilla, Petardos): daña y empuja a los de alrededor.
func blast(pos: Vector3, dmg: float, item: String) -> void:
	if world == null: return
	var r := BLAST_RADIUS * data.area_mult
	var prev := Damage.ctx
	Damage.ctx = item_tag(item)
	var fx := Explosion.new()
	fx.radius = r
	fx.position = Vector3(pos.x, 0, pos.z)
	world.fx.add_child(fx)
	for t in world.enemies_in_circle(pos, r):
		var d := Damage.new(dmg * damage_mult(WeaponData.Category.PHYSICAL), 0.0)
		var away := t.global_position - pos
		d.knockback = Vector3(away.x, 0, away.z).normalized() * 1.5
		d.bonus = data.bonus_tags
		t.take_damage(d)
	Damage.ctx = prev

## Daño directo de un objeto a un enemigo (Escamas).
func _item_hit(e: Node3D, dmg: float, item: String) -> void:
	var prev := Damage.ctx
	Damage.ctx = item_tag(item)
	var d := Damage.new(dmg, 0.0)
	d.bonus = data.bonus_tags
	e.take_damage(d)
	Damage.ctx = prev

## Al empezar un esquive: señuelo, petardos y furia.
func _on_dodge() -> void:
	var from := global_position - motor.dodge_dir * 0.3
	if world != null: VoxelFx.puff(world.fx, from + Vector3(0, 0.1, 0), "ring_dust", 0.5, Color(0.8, 0.8, 0.85), 1.0)
	if data.decoy_time > 0.0 and world != null:              # Capa del Hombre Negro
		world.fx.add_child(Flare.new().setup(world, from, data.decoy_time, DECOY_RADIUS))
	if data.dodge_blast > 0.0: blast(from, data.dodge_blast, "petardos")
	if data.dodge_fury > 0.0: _fury_t = FURY_TIME

## Escudo de Nodens: s entre dos golpes absorbidos (25 a nivel 1, −3 por nivel).
func nodens_every() -> float:
	return 28.0 - 3.0 * data.nodens_level

func nodens_ready() -> bool:
	return data.nodens_level > 0.0 and _nodens_t >= nodens_every()

func _nodens_step(delta: float) -> void:
	if data.nodens_level <= 0.0: return
	_nodens_t = minf(_nodens_t + delta, nodens_every())
	if _nodens_fx == null and visual != null:
		_nodens_fx = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.75; sm.height = 1.5; sm.radial_segments = 24; sm.rings = 12
		_nodens_fx.mesh = sm
		var m := ShaderMaterial.new()
		m.shader = preload("res://scripts/fx/nodens_shield.gdshader")
		_nodens_fx.material_override = m
		_nodens_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_nodens_fx.position.y = 0.85
		visual.add_child(_nodens_fx)
	if _nodens_fx != null: _nodens_fx.visible = nodens_ready()

## Descartes que le quedan en este nivel (Cartas del tarot, tienda).
func banishes_left() -> int:
	return maxi(int(shop.get("banish", 0.0)) - banishes_used, 0)

## Cambios de opciones que le quedan en este nivel (Llave de plata).
func rerolls_left() -> int:
	return maxi(int(data.rerolls) - rerolls_used, 0)

## Reproduce una animación puntual (p. ej. "throw") por encima de andar o estar quieto.
func play_once(anim: String) -> void:
	if Anims.has_anim(data.model, anim):
		_override = anim
		_override_t = 0.0

## Anillo plano del color del jugador, sin sombreado, para distinguirlo siempre.
## Fogonazo de luz al disparar un arma de fuego (hito 11.3): una luz por jugador que se reutiliza,
## así que nunca hay más de cuatro.
func muzzle_flash(dir: Vector3) -> void:
	if _muzzle == null:
		_muzzle = OmniLight3D.new()
		_muzzle.name = "MuzzleLight"
		_muzzle.light_color = Color(1.0, 0.72, 0.38)
		_muzzle.omni_range = 4.0
		_muzzle.omni_attenuation = 1.6
		_muzzle.shadow_enabled = false
		add_child(_muzzle)
	_muzzle.position = dir * 0.6 + Vector3(0.0, 0.9, 0.0)
	_muzzle_t = MUZZLE_TIME

## Ondas al andar por el agua somera (hito 11.4): una cada RIPPLE_STEP m recorridos.
const RIPPLE_STEP := 0.45
var _ripple_from := Vector3.INF

func _ripple_step() -> void:
	if _wade < 0.5 or world == null:
		_ripple_from = Vector3.INF
		return
	var here := visual.global_position
	if _ripple_from == Vector3.INF or here.distance_to(_ripple_from) >= RIPPLE_STEP:
		_ripple_from = here
		Ripples.add(world.fx, here, 0.8 if _action == "" else 1.3, 0.55)

## Ha recogido una gema: el anillo late (se suman, con tope).
func gem_pulse() -> void:
	_gem_pulse = minf(_gem_pulse + 0.45, 1.0)

func _make_ring() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	var r0 := 0.44; var r1 := 0.60
	for i in n:
		var a0 := TAU * i / n; var a1 := TAU * (i + 1) / n
		var p := [Vector3(cos(a0) * r0, 0, sin(a0) * r0), Vector3(cos(a0) * r1, 0, sin(a0) * r1),
			Vector3(cos(a1) * r1, 0, sin(a1) * r1), Vector3(cos(a1) * r0, 0, sin(a1) * r0)]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.UP)
			st.add_vertex(p[k])
	var mi := MeshInstance3D.new()
	mi.name = "Ring"
	mi.mesh = st.commit()
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.albedo_color = color
	_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = _ring_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.03
	return mi

# ---------------- red (hito 9.3a) ----------------
const NET_CRISIS := 1
const NET_FROZEN := 2
const NET_TREMBLING := 4
const NET_HURT := 8                  ## parpadea tras un golpe
const NET_ELIMINATED := 16
const NET_INVULN := 32               ## esquivando o recién golpeado: las balas lo atraviesan

## Lo que los demás PC no pueden calcular de este jugador (crisis, parálisis, golpe reciente).
func net_flags() -> int:
	if remote: return _net_flags                 # el anfitrión reenvía lo que le llega
	var f := 0
	if sanity_state.in_crisis: f |= NET_CRISIS
	if sanity_state.is_frozen(): f |= NET_FROZEN
	if sanity_state.is_trembling(): f |= NET_TREMBLING
	if _hurt_time >= 0.0 and _hurt_time < data.hit_iframes: f |= NET_HURT
	if is_eliminated: f |= NET_ELIMINATED
	if god or is_invulnerable(): f |= NET_INVULN
	return f

## Jugador de otro PC: ¿para aquí las balas enemigas? (en pie y sin invulnerabilidad; el daño
## lo decide su PC, aquí la bala solo desaparece)
func net_solid() -> bool:
	return health > 0.0 and (_net_flags & NET_INVULN) == 0

## Jugador de otro PC: aplica su estado (posición interpolada y lo demás de la foto más
## reciente). Los cambios de vida dan las mismas señales que en su PC (derribado, levantado,
## eliminado), para que cada partida los anuncie y cuente.
func net_apply(pos: Vector3, yaw: float, vel: Vector3, dodges: int, hp: float, san: float, flags: int, revive := 0.0) -> void:
	position = Vector3(pos.x, 0.0, pos.z)
	motor.facing = Vector3(sin(yaw), 0.0, cos(yaw))
	motor.velocity = vel
	velocity = vel
	if dodges != dodge_count:
		dodge_count = dodges
		if hp > 0.0 and data.dodge_anim != "":
			_action = data.dodge_anim
			_action_t = 0.0
			Auto.sfx_at("dodge", global_position)
	var was := health
	health = hp
	sanity = san
	_net_flags = flags
	sanity_state.in_crisis = (flags & NET_CRISIS) != 0
	if flags & NET_HURT:
		if _hurt_time < 0.0 or _hurt_time >= data.hit_iframes:
			_hurt_time = 0.0
			_face.hurt()
	else: _hurt_time = -1.0
	if was > 0.0 and hp <= 0.0:
		motor.locked = true
		if revivable:
			down_left = rules.down_time
			revive_progress = 0.0
		downed.emit()
	elif was <= 0.0 and hp > 0.0:
		down_left = -1.0
		revive_progress = 0.0
		motor.locked = false
		Anims.reset(model)
		if _down_ring: _down_ring.visible = false
		revived.emit()
	if hp <= 0.0 and rules != null: revive_progress = revive * rules.revive_time   # la lleva su PC; aquí, para el HUD y el anillo
	if flags & NET_ELIMINATED and not is_eliminated:
		is_eliminated = true
		down_left = 0.0
		eliminated.emit()

## Deja de llegar su estado (su PC se ha ido): lo lleva este PC con `input` (un bot).
func net_release(new_input: PlayerInput) -> void:
	remote = false
	input = new_input
	_net_flags = 0
	motor.locked = health <= 0.0
