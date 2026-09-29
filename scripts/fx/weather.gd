class_name Weather
extends Node3D
## Clima estético de la partida (D-33), según un WeatherData. Todo sigue a la cámara (las
## partículas viven en coordenadas del mundo y los sombreados usan la posición en el mundo,
## así que la niebla y las nubes avanzan con el viento, no con la cámara):
## - precipitación: nieve, ceniza con brasas o lluvia con salpicaduras en el suelo;
## - ventisca: rachas de nieve a ras de suelo;
## - niebla: dos capas de bancos bajos (weather_mist.gdshader);
## - sombras de nubes sobre el suelo (weather_clouds.gdshader, mezcla multiplicativa);
## - rayos: destello de una luz direccional y de la luz ambiental.
## No toca a jugadores ni enemigos.

var data: WeatherData
var camera: GameCamera
var amount := 1.0                            ## 1 completo, 0,5 reducido (configuración)
var env: Environment
var lightning_count := 0                     ## rayos caídos (tests)
var _t := 0.0
var _precip: GPUParticles3D
var _precip_mat: ParticleProcessMaterial
var _extra: GPUParticles3D                   ## salpicaduras (lluvia) o brasas (ceniza)
var _drift: GPUParticles3D
var _drift_mat: ParticleProcessMaterial
var _mist: Array[ShaderMaterial] = []
var _mist_nodes: Array[MeshInstance3D] = []
var _clouds: MeshInstance3D
var _cloud_mat: ShaderMaterial
var _flash: DirectionalLight3D
var _base_ambient := 0.35
var _next_bolt := 0.0
var _bolt_t := -1.0
var _rng := RandomNumberGenerator.new()

const AREA := 24.0                           ## medio lado de la zona cubierta (m)
const TOP := 9.0                             ## altura a la que nace la precipitación
const BIG_AABB := AABB(Vector3(-200, -20, -200), Vector3(400, 60, 400))
const FLASH_LIGHT := 0.45                    ## energía de la luz del rayo en su pico
const FLASH_AMBIENT := 0.18                 ## subida de la luz ambiental en el pico

func setup(p_data: WeatherData, p_camera: GameCamera, p_env: Environment, p_amount: float = 1.0) -> Weather:
	data = p_data
	amount = p_amount
	camera = p_camera
	env = p_env
	name = "Weather"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rng.seed = hash(String(data.id))
	return self

func _ready() -> void:
	if env != null:
		_base_ambient = env.ambient_light_energy
		if data.fog_density >= 0.0: env.fog_density = data.fog_density
	match data.precip:
		WeatherData.Precip.SNOW: _make_precip(false)
		WeatherData.Precip.ASH: _make_precip(false); _make_embers()
		WeatherData.Precip.RAIN: _make_precip(true); _make_splashes()
	if data.drift > 0.0: _make_drift()
	if data.mist > 0.0:
		_make_mist(0.3, 1.0, 1.0)
		_make_mist(0.95, 0.55, 1.9)
	if data.clouds > 0.0: _make_clouds()
	if data.lightning_every > 0.0:
		_flash = DirectionalLight3D.new()
		_flash.rotation_degrees = Vector3(-70, -30, 0)
		_flash.light_color = data.lightning_color
		_flash.light_energy = 0.0
		_flash.shadow_enabled = false
		add_child(_flash)
		_next_bolt = data.lightning_every * _rng.randf_range(0.3, 0.8)
	_process(0.0)

## Punto del suelo al que mira la cámara (el centro de sus objetivos).
func focus() -> Vector3:
	if camera == null or not is_instance_valid(camera): return Vector3.ZERO
	var c := camera.center()
	return Vector3(c.x, 0.0, c.z)

# ---------------- precipitación ----------------

func _particles(n: int, lifetime: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = maxi(int(n * amount), 1)
	p.lifetime = lifetime
	p.preprocess = lifetime                      # la escena ya empieza nevando
	p.local_coords = false
	p.visibility_aabb = BIG_AABB
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(p)
	return p

func _unshaded(c: Color, billboard: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_color = c
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true            # sin esto, todos los copos miden 1 m
	return m

func _fade_ramp(c: Color) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.85, 1.0])
	g.colors = PackedColorArray([Color(c, 0.0), c, c, Color(c, 0.0)])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t

func _make_precip(rain: bool) -> void:
	var speed := data.fall_speed
	var life := TOP / maxf(speed, 0.1) * 1.05
	var base := 2600 if rain else 2200
	_precip = _particles(int(base * data.precip_amount), life)
	_precip_mat = ParticleProcessMaterial.new()
	_precip_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_precip_mat.emission_box_extents = Vector3(AREA, 0.5, AREA)
	_precip_mat.spread = 4.0 if rain else 12.0
	_precip_mat.gravity = Vector3.ZERO
	_precip_mat.color_ramp = _fade_ramp(data.precip_color)
	if rain:
		_precip_mat.particle_flag_align_y = true        # la gota se alarga en su dirección
		_precip_mat.scale_min = 0.8
		_precip_mat.scale_max = 1.2
		var drop := BoxMesh.new()
		drop.size = Vector3(0.018, 0.5, 0.018)
		drop.material = _unshaded(Color.WHITE, false)
		_precip.draw_pass_1 = drop
	else:
		_precip_mat.scale_min = data.flake_size * 0.6
		_precip_mat.scale_max = data.flake_size * 1.4
		_precip_mat.angle_min = -180.0
		_precip_mat.angle_max = 180.0
		_precip_mat.angular_velocity_min = -90.0 if data.precip == WeatherData.Precip.ASH else -20.0
		_precip_mat.angular_velocity_max = 90.0 if data.precip == WeatherData.Precip.ASH else 20.0
		_precip_mat.turbulence_enabled = true            # revoloteo; influencia baja: si no, se paran
		_precip_mat.turbulence_noise_scale = 4.0
		_precip_mat.turbulence_influence_min = 0.003
		_precip_mat.turbulence_influence_max = 0.008
		var flake := QuadMesh.new()
		flake.size = Vector2.ONE
		flake.material = _unshaded(Color.WHITE, true)
		_precip.draw_pass_1 = flake
	_precip.process_material = _precip_mat

## Lluvia: salpicaduras que se abren en el suelo.
func _make_splashes() -> void:
	_extra = _particles(int(500 * data.precip_amount), 0.28)
	_extra.preprocess = 0.0
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(AREA * 0.8, 0.0, AREA * 0.8)
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = 0.0
	m.initial_velocity_max = 0.0
	m.scale_min = 0.08
	m.scale_max = 0.16
	var sc := CurveTexture.new()
	var cv := Curve.new()
	cv.add_point(Vector2(0, 0.3)); cv.add_point(Vector2(1, 1.0))
	sc.curve = cv
	m.scale_curve = sc
	m.color_ramp = _fade_ramp(Color(data.precip_color, 0.6))
	_extra.process_material = m
	var ring := QuadMesh.new()
	ring.size = Vector2.ONE
	ring.orientation = PlaneMesh.FACE_Y                # plana sobre el suelo
	ring.material = _unshaded(Color.WHITE, false)
	_extra.draw_pass_1 = ring

## Ceniza: unas pocas brasas que suben despacio y parpadean.
func _make_embers() -> void:
	_extra = _particles(int(90 * data.precip_amount), 4.0)
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(AREA, 0.3, AREA)
	m.direction = Vector3.UP
	m.spread = 30.0
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = 0.2
	m.initial_velocity_max = 0.6
	m.scale_min = 0.035
	m.scale_max = 0.07
	m.turbulence_enabled = true
	m.turbulence_noise_scale = 3.0
	m.turbulence_influence_min = 0.01
	m.turbulence_influence_max = 0.02
	m.color_ramp = _fade_ramp(Color(1.0, 0.45, 0.12) * 0.8)   # atenuado: el tonemapper lo quemaría
	_extra.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = _unshaded(Color.WHITE, true)
	_extra.draw_pass_1 = q

# ---------------- ventisca ----------------

func _make_drift() -> void:
	_drift = _particles(int(700 * data.drift), 1.6)
	_drift_mat = ParticleProcessMaterial.new()
	_drift_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_drift_mat.emission_box_extents = Vector3(AREA, 0.35, AREA)
	_drift_mat.gravity = Vector3.ZERO
	_drift_mat.spread = 6.0
	_drift_mat.particle_flag_align_y = true
	_drift_mat.scale_min = 0.6
	_drift_mat.scale_max = 1.4
	_drift_mat.color_ramp = _fade_ramp(data.drift_color)
	_drift.process_material = _drift_mat
	var streak := BoxMesh.new()                        # hebra alargada en el sentido del viento
	streak.size = Vector3(0.025, 0.6, 0.025)
	streak.material = _unshaded(Color.WHITE, false)
	_drift.draw_pass_1 = streak

# ---------------- niebla y nubes ----------------

func _plane(size: float, y: float, mat: ShaderMaterial) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	mi.mesh = pm
	mi.material_override = mat
	mi.position.y = y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = BIG_AABB
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mi

func _make_mist(y: float, k: float, scale: float) -> void:
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/weather_mist.gdshader")
	m.set_shader_parameter("tint", data.mist_color)
	m.set_shader_parameter("opacity", data.mist * k)
	m.set_shader_parameter("scale", 9.0 * scale)
	_mist.append(m)
	_mist_nodes.append(_plane(AREA * 2.6, y, m))

func _make_clouds() -> void:
	_cloud_mat = ShaderMaterial.new()
	_cloud_mat.shader = preload("res://scripts/fx/weather_clouds.gdshader")
	_cloud_mat.set_shader_parameter("strength", data.clouds)
	_cloud_mat.set_shader_parameter("scale", data.cloud_scale)
	_clouds = _plane(AREA * 2.6, 0.02, _cloud_mat)

# ---------------- cada fotograma ----------------

func _process(delta: float) -> void:
	_t += delta
	var f := focus()
	var wv := data.wind_vector()
	var w := data.wind_at(_t)
	if _precip:
		# nace a barlovento para que, al caer inclinada, cubra la vista
		var lead := wv * w * (TOP / maxf(data.fall_speed, 0.1)) * 0.5
		_precip.global_position = f + Vector3(0, TOP, 0) - lead
		var v := Vector3(wv.x * w, -data.fall_speed, wv.z * w)
		_precip_mat.direction = v.normalized()
		_precip_mat.initial_velocity_min = v.length() * 0.85
		_precip_mat.initial_velocity_max = v.length() * 1.15
	if _extra: _extra.global_position = f + Vector3(0, 0.05, 0)
	if _drift:
		_drift.global_position = f + Vector3(0, 0.4, 0) - wv * w * 1.2
		_drift_mat.direction = wv
		_drift_mat.initial_velocity_min = w * 2.2
		_drift_mat.initial_velocity_max = w * 3.4
	var wind_off := Vector2(wv.x, wv.z) * _wind_travel()
	for i in _mist.size():
		_mist_nodes[i].global_position = Vector3(f.x, _mist_nodes[i].position.y, f.z)
		_mist[i].set_shader_parameter("offset", wind_off * (1.0 + i * 0.6))
	if _clouds:
		_clouds.global_position = Vector3(f.x, 0.02, f.z)
		_cloud_mat.set_shader_parameter("offset", wind_off * 0.8)
	if data.lightning_every > 0.0: _lightning(delta)

## Distancia recorrida por el viento hasta ahora (integral aproximada de la fuerza media).
func _wind_travel() -> float:
	return _t * data.wind * (1.0 + data.gusts * 0.5)

## Rayos: dos o tres destellos seguidos que iluminan la escena y se apagan.
func _lightning(delta: float) -> void:
	if _bolt_t < 0.0:
		_next_bolt -= delta
		if _next_bolt <= 0.0:
			_bolt_t = 0.0
			lightning_count += 1
			_next_bolt = data.lightning_every * _rng.randf_range(0.5, 1.5)
	else:
		_bolt_t += delta
	var k := flash_at(_bolt_t)
	if _bolt_t > 0.7: _bolt_t = -1.0
	# destello contenido: con más, la escena se quemaba en blanco y la noche parecía de día
	if _flash: _flash.light_energy = k * FLASH_LIGHT
	if env: env.ambient_light_energy = _base_ambient + k * FLASH_AMBIENT
	for m in _mist: m.set_shader_parameter("flash", k)

## Brillo del rayo t s después de caer: un destello fuerte, otro más flojo y un tercero.
static func flash_at(t: float) -> float:
	if t < 0.0: return 0.0
	var k := 0.0
	for p: Vector3 in [Vector3(0.0, 1.0, 0.07), Vector3(0.16, 0.55, 0.06), Vector3(0.32, 0.8, 0.12)]:
		var u := (t - p.x) / p.z
		if u >= 0.0 and u <= 1.0: k = maxf(k, p.y * (1.0 - u))
	return k
