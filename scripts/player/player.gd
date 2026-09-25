class_name Player
extends CharacterBody3D
## Personaje jugable: aplica el PlayerMotor con la física, orienta y anima el modelo
## y dibuja el anillo del color del jugador bajo sus pies.

signal dodged
signal damaged(d: Damage)

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
var god := false                 ## depuración: no recibe daño
var _anim := "idle"
var _anim_t := 0.0
var _hurt_time := -1.0           ## tiempo desde el último golpe (-1 = nunca)
var _override := ""              ## animación puntual (lanzar) que se impone un momento
var _override_t := 0.0

func setup(p_data: CharacterData, p_input: PlayerInput, p_color: Color) -> Player:
	data = p_data
	input = p_input
	color = p_color
	motor = PlayerMotor.new(data)
	health = data.max_health
	sanity = data.max_sanity
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
	add_child(visual)
	model = VoxelBuilder.load_model("res://models/%s.json" % data.model)
	visual.add_child(model)
	# Silueta del color del jugador cuando lo tapa el decorado
	var xray := ShaderMaterial.new()
	xray.shader = preload("res://scripts/player/occluded_silhouette.gdshader")
	xray.set_shader_parameter("color", Color(color, 0.6))
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = xray
	add_child(_make_ring())
	# Farol propio: luz cálida y corta que destaca al jugador en la oscuridad (pilar de legibilidad)
	var lamp := OmniLight3D.new()
	lamp.name = "CarryLight"
	lamp.position = Vector3(0.25, 1.5, 0.35)
	lamp.light_color = Color(1.0, 0.8, 0.55)
	lamp.light_energy = 1.1
	lamp.omni_range = 4.5
	lamp.omni_attenuation = 1.4
	add_child(lamp)

func _physics_process(delta: float) -> void:
	input.update(delta)
	var was_dodging := motor.is_dodging()
	velocity = motor.step(delta, input.move, input.just_pressed(InputBindings.DODGE))
	move_and_slide()
	position.y = 0.0
	if motor.is_dodging() and not was_dodging: dodged.emit()
	if _hurt_time >= 0.0: _hurt_time += delta

func _process(delta: float) -> void:
	# Girar el modelo hacia donde mira (el modelo mira hacia +Z)
	var target := atan2(motor.facing.x, motor.facing.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target, 1.0 - exp(-data.turn_speed * delta))
	# Animación según el estado
	# Parpadeo durante la invulnerabilidad tras un golpe
	visual.visible = not (_hurt_time >= 0.0 and _hurt_time < data.hit_iframes and fmod(_hurt_time, 0.12) < 0.06)
	var anim := "idle"
	if motor.is_dodging(): anim = "dodge"
	elif motor.velocity.length() > 0.1: anim = "walk"
	if _override != "":
		_override_t += delta / Anims.duration(data.model, _override)
		if _override_t >= 1.0: _override = ""
		elif not motor.is_dodging():
			Anims.pose(data.model, _override, model, _override_t)
			return
	if anim != _anim:
		_anim = anim
		_anim_t = 0.0
	var t: float
	if anim == "dodge":
		t = motor.dodge_time / data.dodge_duration
	else:
		_anim_t += delta / Anims.duration(data.model, anim)
		t = fposmod(_anim_t, 1.0)
	Anims.pose(data.model, anim, model, t)

func is_invulnerable() -> bool:
	return motor.is_invulnerable() or (_hurt_time >= 0.0 and _hurt_time < data.hit_iframes)

## ¿Puede recibir un impacto ahora?
func is_hittable() -> bool:
	return health > 0.0 and not god and not is_invulnerable()

## Recibe un ataque: la parte física resta vida y la mental, cordura.
func take_damage(d: Damage) -> void:
	if not is_hittable(): return
	health = maxf(0.0, health - d.physical)
	sanity = maxf(0.0, sanity - d.mental)
	_hurt_time = 0.0
	damaged.emit(d)

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
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.03
	return mi
