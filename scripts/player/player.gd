class_name Player
extends CharacterBody3D
## Personaje jugable: aplica el PlayerMotor con la física, orienta y anima el modelo
## y dibuja el anillo del color del jugador bajo sus pies.

signal dodged
signal damaged(d: Damage)
signal downed                    ## vida a cero
signal revived                   ## un compañero lo ha levantado (cooperativo)
signal eliminated                ## se acabó su tiempo derribado: fuera hasta el siguiente nivel

const LAYER_WORLD := 1
const LAYER_PLAYERS := 2

var data: CharacterData
var input: PlayerInput
var motor: PlayerMotor
var color := Color(1.0, 0.82, 0.3)
var index := 0                   ## J1 = 0 … J4 = 3
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
var pet_xp_mult := 1.0          ## experiencia extra por gema (búho de los sueños)
var visual: Node3D          ## contenedor que gira hacia donde mira; dentro, el modelo voxel
var model: Node3D
var health := 0.0
var sanity := 0.0
var weapons: WeaponSystem
var world: CombatWorld
var progress: PlayerProgress
const CALM_RADIUS := 4.0
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
var _frozen_mat: StandardMaterial3D
var _frozen_on := false
var _xray: ShaderMaterial
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
	visual.add_child(model)
	# Silueta del color del jugador cuando lo tapa el decorado
	_xray = ShaderMaterial.new()
	_xray.shader = preload("res://scripts/player/occluded_silhouette.gdshader")
	_xray.set_shader_parameter("color", Color(color, 0.6))
	for mi: MeshInstance3D in model.get_meta("meshes"):
		mi.material_overlay = _xray
	add_child(_make_ring())
	_snow = _make_snow_spray()
	add_child(_snow)
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
	add_child(lamp)
	reset_physics_interpolation.call_deferred()      # no interpolar desde el origen al aparecer

func _physics_process(delta: float) -> void:
	var t0 := Prof.start()
	_physics_process_step(delta)
	Prof.stop("jugadores_fisica", t0)

func _physics_process_step(delta: float) -> void:
	if health <= 0.0:
		_downed_step(delta)
		return
	input.update(delta)
	var near := world != null and world.nearest_enemy(global_position, sanity_state.rules.horror_radius) != null
	_sanity_context()
	var before := sanity_state.crises
	sanity = sanity_state.update(delta, sanity, data.max_sanity, near)
	if sanity_state.crises != before and madness: rebuild_stats()      # locura acumulada
	if data.calm_aura > 0.0 and world != null:       # rasgo de Iwanicki: calma a sí mismo y a los cercanos
		for p in world.players:
			if p.health > 0.0 and p.global_position.distance_to(global_position) <= CALM_RADIUS:
				p.sanity = minf(p.data.max_sanity, p.sanity + data.calm_aura * delta)
	motor.locked = sanity_state.is_frozen()
	var was_dodging := motor.is_dodging()
	var ss := sanity_state
	var move := _crisis_move(delta, input.move)
	var dodge := input.just_pressed(InputBindings.DODGE) and not (ss.is_kind(&"huida") or ss.is_kind(&"vagar"))
	velocity = motor.step(delta, move, dodge)
	if ss.is_kind(&"huida"): velocity *= rules.flee_speed
	elif ss.is_kind(&"vagar"): velocity *= rules.wander_speed
	move_and_slide()
	position.y = 0.0
	if world != null and world.obstacles != null and world.obstacles.has_mask():   # límites y decorado dibujados
		var p2 := world.obstacles.push_out(Vector2(position.x, position.z), data.hurt_radius + 0.05)
		position.x = p2.x; position.z = p2.y
	if leash.is_valid(): global_position = leash.call(global_position)
	if motor.is_dodging() and not was_dodging:
		_action = data.dodge_anim         # la animación del esquive empieza con el impulso
		_action_t = 0.0
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
		return _to_screen(away.normalized())
	if ss.is_kind(&"vagar"):
		_wander += (sin(ss.crisis_time * 1.7) * 2.0 + sin(ss.crisis_time * 4.3)) * delta
		var w := Vector2(cos(_wander), sin(_wander))
		return (w * (1.0 - rules.wander_obey) + move * rules.wander_obey).limit_length(1.0)
	return move

## Del suelo al espacio de la pantalla (inverso de PlayerMotor.screen_to_world).
static func _to_screen(d: Vector3) -> Vector2:
	return Vector2(d.dot(PlayerMotor.screen_to_world(Vector2(1, 0))), d.dot(PlayerMotor.screen_to_world(Vector2(0, 1))))

## Presencia de una élite o un jefe: drena cordura sin contar como golpe.
func drain_sanity(amount: float) -> void:
	if health <= 0.0 or god: return
	sanity = maxf(0.0, sanity - amount * mental_resist)

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
	if ss.in_crisis:
		_ring_mat.albedo_color = UiKit.SANITY.lerp(Color.WHITE, 0.25 + 0.25 * sin(Time.get_ticks_msec() * 0.012))
	else:
		_ring_mat.albedo_color = color
	var frozen := ss.is_frozen()
	if frozen != _frozen_on:
		_frozen_on = frozen
		for mi: MeshInstance3D in model.get_meta("meshes"):
			mi.material_overlay = _frozen_mat if frozen else _xray
	# Temblor de aviso antes de cada congelación de la parálisis
	var shake := Vector3(randf_range(-0.04, 0.04), 0, randf_range(-0.04, 0.04)) if sanity_state.is_trembling() else Vector3.ZERO
	visual.global_position = here + shake
	# Parpadeo durante la invulnerabilidad tras un golpe
	visual.visible = not (_hurt_time >= 0.0 and _hurt_time < data.hit_iframes and fmod(_hurt_time, 0.12) < 0.06)
	_animate(delta)
	_keep_above_ground(delta)
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
	elif anim == "walk":
		# cadencia proporcional a la velocidad real: los pies no patinan
		_anim_t += delta * (motor.velocity.length() / data.move_speed) / Anims.duration(data.model, "walk")
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

## Ninguna pose puede meter el cuerpo en el suelo: tras animar, se mide el punto más bajo
## del modelo (las cajas de sus mallas, en el espacio de Visual) y, si queda por debajo de
## la nieve, se sube el modelo lo justo. Vale para cualquier esquive o animación.
## Sube al instante lo que haga falta, pero baja poco a poco (GROUND_EASE m/s): en la
## voltereta el punto más bajo cambia de golpe al rodar y, bajando de golpe, daba tirones.
func _keep_above_ground(delta: float) -> void:
	var inv := visual.global_transform.affine_inverse()
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
		"dodge_cooldown": (style.cooldown if style else base.dodge_cooldown) * data.dodge_cooldown_mult / Attributes.mult(attrs, "dodge"),
		"pickup_radius": base.pickup_radius,
	}
	for up in progress.upgrade_pool if progress else []:
		if not v.has(up.stat): v[up.stat] = base.get(up.stat)
		for i in int(progress.passives.get(up.id, 0)): v[up.stat] = v[up.stat] * up.multiply + up.add
	v["move_speed"] *= debug_speed
	for k in v: data.set(k, v[k])
	if motor: motor.data = data
	health = minf(health + maxf(data.max_health - old_health, 0.0), data.max_health)
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
	var k := float(shop.get("damage", 1.0))                  # Puntería (tienda)
	match category:
		WeaponData.Category.PHYSICAL: return Attributes.mult(attrs, "physical") * k
		WeaponData.Category.MAGIC: return Attributes.mult(attrs, "magic") * k
	return Attributes.mult(attrs, "firearm") * k

func is_invulnerable() -> bool:
	return motor.is_invulnerable() or (_hurt_time >= 0.0 and _hurt_time < data.hit_iframes)

## ¿Puede recibir un impacto ahora?
func is_hittable() -> bool:
	return health > 0.0 and not god and not is_invulnerable()

## Recibe un ataque: la parte física resta vida y la mental, cordura.
func take_damage(d: Damage) -> void:
	if not is_hittable(): return
	if d.source is Enemy and not data.resist_tags.is_empty():   # rasgos: resistencia a ciertas criaturas
		var k := 1.0
		for tag in (d.source as Enemy).data.tags: k *= float(data.resist_tags.get(tag, 1.0))
		if k != 1.0: d = d.scaled(k)
	if data.physical_resist != 1.0 and d.physical > 0.0:            # rasgo: aguante físico
		var r := Damage.new(d.physical * data.physical_resist, d.mental)
		r.knockback = d.knockback; r.source = d.source; r.bonus = d.bonus
		d = r
	health = maxf(0.0, health - d.physical)
	if d.mental > 0.0:
		sanity = maxf(0.0, sanity - d.mental * mental_resist)
		sanity_state.on_mental_damage()
	_hurt_time = 0.0
	damaged.emit(d)
	if health <= 0.0:
		motor.locked = true
		if revivable:
			down_left = rules.down_time
			revive_progress = 0.0
		downed.emit()

## Reproduce una animación puntual (p. ej. "throw") por encima de andar o estar quieto.
func play_once(anim: String) -> void:
	if Anims.has_anim(data.model, anim):
		_override = anim
		_override_t = 0.0

## Anillo plano del color del jugador, sin sombreado, para distinguirlo siempre.
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
