class_name Player
extends CharacterBody3D
## Personaje jugable: aplica el PlayerMotor con la física, orienta y anima el modelo
## y dibuja el anillo del color del jugador bajo sus pies.

signal dodged
signal damaged(d: Damage)
signal downed                    ## vida a cero

const LAYER_WORLD := 1
const LAYER_PLAYERS := 2

var data: CharacterData
var input: PlayerInput
var motor: PlayerMotor
var color := Color(1.0, 0.82, 0.3)
var visual: Node3D          ## contenedor que gira hacia donde mira; dentro, el modelo voxel
var model: Node3D
var health := 0.0
var sanity := 0.0
var weapons: WeaponSystem
var world: CombatWorld
var progress: PlayerProgress
var sanity_state: SanityState
var god := false                 ## depuración: no recibe daño
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
const UPPER_BODY: Array[String] = ["arm_r", "arm_l", "torso"]
var _ring_mat: StandardMaterial3D
var _frozen_mat: StandardMaterial3D
var _frozen_on := false
var _xray: ShaderMaterial

func setup(p_data: CharacterData, p_input: PlayerInput, p_color: Color) -> Player:
	data = p_data.duplicate()        # copia propia: las mejoras pasivas la modifican
	if data.dodge_style != null: apply_dodge_style(data.dodge_style)
	input = p_input
	color = p_color
	motor = PlayerMotor.new(data)
	health = data.max_health
	sanity = data.max_sanity
	var rules: ProgressionData = load("res://data/progression/default.tres")
	progress = PlayerProgress.new(rules)
	sanity_state = SanityState.new(rules)
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
	if health <= 0.0: return
	input.update(delta)
	var near := world != null and world.nearest_enemy(global_position, sanity_state.rules.horror_radius) != null
	sanity = sanity_state.update(delta, sanity, data.max_sanity, near)
	motor.locked = sanity_state.is_frozen()
	var was_dodging := motor.is_dodging()
	velocity = motor.step(delta, input.move, input.just_pressed(InputBindings.DODGE))
	move_and_slide()
	position.y = 0.0
	if motor.is_dodging() and not was_dodging:
		_action = data.dodge_anim         # la animación del esquive empieza con el impulso
		_action_t = 0.0
		dodged.emit()
	if _hurt_time >= 0.0: _hurt_time += delta

func _process(delta: float) -> void:
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
## y efectos). Lo usa la creación del jugador y la tecla F1 de pruebas.
func apply_dodge_style(style: DodgeStyle) -> void:
	data.dodge_style = style
	data.dodge_anim = style.anim
	data.dodge_speed = style.speed
	data.dodge_duration = style.duration * data.dodge_length
	data.dodge_iframes = style.iframes * data.dodge_length
	data.dodge_cooldown = style.cooldown

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
	health = maxf(0.0, health - d.physical)
	if d.mental > 0.0:
		sanity = maxf(0.0, sanity - d.mental)
		sanity_state.on_mental_damage()
	_hurt_time = 0.0
	damaged.emit(d)
	if health <= 0.0:
		motor.locked = true
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
