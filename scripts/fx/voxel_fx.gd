class_name VoxelFx
## Emisores de partículas en cubitos, a juego con el voxel (11-10-2026): llamas que suben y
## se apagan en humo, chispas, humo, burbujas de ácido que se hinchan y revientan y cascotes
## que rebotan. Todos dibujan el mismo cubo (malla y materiales compartidos) y salen de
## `emitter()` con una receta; los usan las explosiones y las zonas de fuego y ácido.

static var _cube_add: BoxMesh
static var _cube_mix: BoxMesh
static var _cube_lit: BoxMesh
static var _ground_shader: Shader
static var _tex_cache := {}                   ## rampas y curvas ya creadas (por sus puntos)
static var _mat_cache := {}                   ## receta|radio -> material de proceso compartido

## Cubo sin iluminar: aditivo (fuego, chispas), mezclado (humo, burbujas) o iluminado (cascotes).
static func cube(kind: String) -> BoxMesh:
	if _cube_add == null:
		_cube_add = _make_cube(BaseMaterial3D.BLEND_MODE_ADD, false)
		_cube_mix = _make_cube(BaseMaterial3D.BLEND_MODE_MIX, false)
		_cube_lit = _make_cube(BaseMaterial3D.BLEND_MODE_MIX, true)
	return {"add": _cube_add, "mix": _cube_mix, "lit": _cube_lit}[kind]

static func _make_cube(blend: int, lit: bool) -> BoxMesh:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	if not lit:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = blend
	m.disable_receive_shadows = true
	box.material = m
	return box

## Un único suelo para que reboten cascotes y trozos, compartido por todos los efectos que
## cuelgan de `parent` (con una caja por efecto, cada sistema de partículas comprobaba
## todas: con muchas muertes seguidas se notaba).
static func ensure_floor(parent: Node) -> void:
	if parent == null or parent.has_meta("fx_floor"): return
	parent.set_meta("fx_floor", true)
	var box := GPUParticlesCollisionBox3D.new()
	box.size = Vector3(400.0, 0.4, 400.0)
	box.position.y = -0.2
	parent.add_child.call_deferred(box)

## Mancha animada del suelo (`ground_fx.gdshader`): 0 fuego, 1 ácido, 2 quemado.
static func ground(mode: int, radius: float) -> MeshInstance3D:
	if _ground_shader == null: _ground_shader = preload("res://scripts/fx/ground_fx.gdshader")
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = _ground_shader
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("seed", randf() * 100.0)
	mi.material_override = m
	mi.scale = Vector3(radius, 1.0, radius)
	mi.position.y = 0.04
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func _ramp(stops: Array) -> GradientTexture1D:
	var key := "r" + var_to_str(stops)
	if _tex_cache.has(key): return _tex_cache[key]
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for s in stops:
		offs.append(s[0]); cols.append(s[1])
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture1D.new()
	t.gradient = g
	_tex_cache[key] = t
	return t

static func _curve(points: Array) -> CurveTexture:
	var key := "c" + var_to_str(points)
	if _tex_cache.has(key): return _tex_cache[key]
	var c := Curve.new()
	for p in points: c.add_point(Vector2(p[0], p[1]))
	var t := CurveTexture.new()
	t.curve = c
	_tex_cache[key] = t
	return t

## Receta -> GPUParticles3D listo para añadir; empieza a emitir al entrar en la escena.
## `r` es el radio del efecto (m). El material de proceso se comparte entre emisores de la
## misma receta y radio (crearlo con sus texturas en cada muerte costaba fotogramas): quien
## vaya a cambiarlo (caja, dispersión…) pide `own = true` y recibe una copia. `tint` tiñe la
## receta (forma parte de la clave de la caché).
static func emitter(recipe: String, r: float, one_shot := false, own := false,
		tint := Color.WHITE) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var m := ParticleProcessMaterial.new()
	p.process_material = m
	p.one_shot = one_shot
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.direction = Vector3.UP
	match recipe:
		"flames":                 # lenguas de fuego: suben, se encogen y acaban en humo
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 18.0, 12.0, 36.0))
			p.lifetime = 0.75
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.75
			m.spread = 8.0
			m.initial_velocity_min = 1.2; m.initial_velocity_max = 2.6
			m.gravity = Vector3(0, 1.8, 0)
			m.damping_min = 0.5; m.damping_max = 1.0
			m.scale_min = 0.12; m.scale_max = 0.26
			m.scale_curve = _curve([[0.0, 0.6], [0.2, 1.0], [1.0, 0.15]])
			m.color_ramp = _ramp([[0.0, Color(0.75, 0.6, 0.3, 1.0)], [0.25, Color(0.75, 0.38, 0.08, 1.0)],
				[0.6, Color(0.55, 0.1, 0.02, 0.9)], [1.0, Color(0.15, 0.03, 0.01, 0.0)]])
		"smoke":                  # humo: cubos grandes que suben despacio y se abren
			p.draw_pass_1 = cube("mix")
			p.amount = int(clampf(r * 4.0, 4.0, 12.0))
			p.lifetime = 1.6
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.6
			m.spread = 20.0
			m.initial_velocity_min = 0.4; m.initial_velocity_max = 0.9
			m.gravity = Vector3(0, 0.3, 0)
			m.angle_min = -30.0; m.angle_max = 30.0
			m.scale_min = 0.2; m.scale_max = 0.38
			m.scale_curve = _curve([[0.0, 0.4], [1.0, 1.0]])
			m.color_ramp = _ramp([[0.0, Color(0.22, 0.2, 0.19, 0.0)], [0.2, Color(0.2, 0.18, 0.17, 0.55)],
				[1.0, Color(0.35, 0.33, 0.32, 0.0)]])
		"embers":                 # chispas que saltan y caen
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 4.0, 3.0, 10.0))
			p.lifetime = 1.0
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.7
			m.spread = 35.0
			m.initial_velocity_min = 1.5; m.initial_velocity_max = 3.2
			m.gravity = Vector3(0, -3.0, 0)
			m.scale_min = 0.035; m.scale_max = 0.06
			m.color_ramp = _ramp([[0.0, Color(1.0, 0.85, 0.4, 1.0)], [1.0, Color(1.0, 0.3, 0.05, 0.0)]])
		"bubbles":                # burbujas de ácido: brotan, se hinchan y revientan
			p.draw_pass_1 = cube("mix")
			p.amount = int(clampf(r * 10.0, 8.0, 24.0))
			p.lifetime = 0.9
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.7
			m.spread = 5.0
			m.initial_velocity_min = 0.15; m.initial_velocity_max = 0.45
			m.gravity = Vector3(0, 0.0, 0)
			m.scale_min = 0.07; m.scale_max = 0.15
			m.scale_curve = _curve([[0.0, 0.1], [0.75, 1.0], [0.8, 1.25], [0.85, 0.0], [1.0, 0.0]])
			m.color_ramp = _ramp([[0.0, Color(0.25, 0.5, 0.08, 0.95)], [0.7, Color(0.4, 0.7, 0.15, 0.95)],
				[0.82, Color(0.65, 0.85, 0.4, 1.0)], [1.0, Color(0.6, 0.8, 0.4, 0.0)]])
		"vapor":                  # vapor del ácido: jirones verdes que suben
			p.draw_pass_1 = cube("mix")
			p.amount = int(clampf(r * 3.0, 3.0, 8.0))
			p.lifetime = 1.5
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.6
			m.spread = 15.0
			m.initial_velocity_min = 0.3; m.initial_velocity_max = 0.6
			m.gravity = Vector3(0, 0.2, 0)
			m.scale_min = 0.12; m.scale_max = 0.24
			m.scale_curve = _curve([[0.0, 0.5], [1.0, 1.0]])
			m.color_ramp = _ramp([[0.0, Color(0.6, 0.95, 0.3, 0.0)], [0.25, Color(0.35, 0.6, 0.12, 0.4)],
				[1.0, Color(0.5, 0.7, 0.3, 0.0)]])
		"fireball":               # bola de fuego de la explosión: estalla hacia fuera y se apaga
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 22.0, 30.0, 70.0))
			p.lifetime = 0.55
			p.explosiveness = 0.95
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.2
			m.spread = 180.0
			m.initial_velocity_min = r * 2.0; m.initial_velocity_max = r * 4.2
			m.damping_min = r * 5.0; m.damping_max = r * 8.0
			m.gravity = Vector3(0, 2.0, 0)
			m.scale_min = 0.18; m.scale_max = 0.4
			m.scale_curve = _curve([[0.0, 1.0], [0.4, 0.8], [1.0, 0.0]])
			m.color_ramp = _ramp([[0.0, Color(1.0, 1.0, 0.85, 1.0)], [0.15, Color(1.0, 0.8, 0.3, 1.0)],
				[0.5, Color(1.0, 0.4, 0.08, 1.0)], [1.0, Color(0.4, 0.06, 0.02, 0.0)]])
		"blast_smoke":            # humo que queda tras la explosión
			p.draw_pass_1 = cube("mix")
			p.amount = int(clampf(r * 7.0, 10.0, 22.0))
			p.lifetime = 1.8
			p.explosiveness = 0.85
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.4
			m.spread = 180.0
			m.initial_velocity_min = r * 0.8; m.initial_velocity_max = r * 1.6
			m.damping_min = r * 1.2; m.damping_max = r * 2.0
			m.gravity = Vector3(0, 0.7, 0)
			m.angle_min = -40.0; m.angle_max = 40.0
			m.scale_min = 0.3; m.scale_max = 0.55
			m.scale_curve = _curve([[0.0, 0.3], [0.3, 0.9], [1.0, 1.2]])
			m.color_ramp = _ramp([[0.0, Color(0.35, 0.18, 0.08, 0.0)], [0.12, Color(0.18, 0.15, 0.13, 0.7)],
				[1.0, Color(0.3, 0.29, 0.28, 0.0)]])
		"debris":                 # cascotes y tierra que rebotan
			p.draw_pass_1 = cube("lit")
			p.amount = int(clampf(r * 12.0, 16.0, 34.0))
			p.lifetime = 1.1
			p.explosiveness = 1.0
			m.spread = 60.0
			m.initial_velocity_min = 3.0; m.initial_velocity_max = 7.0
			m.gravity = Vector3(0, -16, 0)
			m.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
			m.collision_bounce = 0.35
			m.collision_friction = 0.6
			m.collision_use_scale = true
			m.angular_velocity_min = -400.0; m.angular_velocity_max = 400.0
			m.scale_min = 0.05; m.scale_max = 0.13
			m.color_ramp = _ramp([[0.0, Color(0.32, 0.27, 0.22, 1.0)], [0.85, Color(0.2, 0.17, 0.15, 1.0)],
				[1.0, Color(0.2, 0.17, 0.15, 0.0)]])
		"sparks":                 # chispas rápidas de la explosión
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 10.0, 14.0, 30.0))
			p.lifetime = 0.7
			p.explosiveness = 1.0
			m.spread = 80.0
			m.initial_velocity_min = 5.0; m.initial_velocity_max = 10.0
			m.damping_min = 4.0; m.damping_max = 7.0
			m.gravity = Vector3(0, -9.0, 0)
			m.scale_min = 0.03; m.scale_max = 0.06
			m.color_ramp = _ramp([[0.0, Color(1.0, 0.95, 0.7, 1.0)], [1.0, Color(1.0, 0.45, 0.1, 0.0)]])
		"chunks":                 # trozos de un enemigo al morir (el color lo pone quien lo usa)
			p.draw_pass_1 = cube("lit")
			p.amount = int(clampf(r * 32.0, 12.0, 44.0))
			p.lifetime = 1.2
			p.explosiveness = 1.0
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.6
			m.spread = 75.0
			m.initial_velocity_min = 1.8; m.initial_velocity_max = 4.8
			m.gravity = Vector3(0, -14.0, 0)
			m.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
			m.collision_bounce = 0.3
			m.collision_friction = 0.7
			m.collision_use_scale = true
			m.angular_velocity_min = -500.0; m.angular_velocity_max = 500.0
			m.scale_min = 0.06; m.scale_max = 0.14
			m.scale_curve = _curve([[0.0, 1.0], [0.75, 1.0], [1.0, 0.0]])
		"death_puff":             # fogonazo breve al morir (color de quien lo usa)
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 16.0, 8.0, 24.0))
			p.lifetime = 0.35
			p.explosiveness = 1.0
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.5
			m.spread = 180.0
			m.initial_velocity_min = r * 2.0; m.initial_velocity_max = r * 4.0
			m.damping_min = r * 6.0; m.damping_max = r * 9.0
			m.scale_min = 0.08; m.scale_max = 0.16
			m.scale_curve = _curve([[0.0, 1.0], [1.0, 0.0]])
			m.color_ramp = _ramp([[0.0, Color(0.6, 0.6, 0.6, 1.0)], [1.0, Color(0.3, 0.3, 0.3, 0.0)]])
		"zap":                    # chispas de impacto de un rayo (color: m.color de quien lo usa)
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 14.0, 8.0, 20.0))
			p.lifetime = 0.4
			p.explosiveness = 0.9
			m.spread = 180.0
			m.initial_velocity_min = 2.0; m.initial_velocity_max = 5.0
			m.damping_min = 6.0; m.damping_max = 10.0
			m.gravity = Vector3(0, -4.0, 0)
			m.scale_min = 0.035; m.scale_max = 0.07
			m.color_ramp = _ramp([[0.0, Color(1, 1, 1, 1)], [1.0, Color(0.6, 0.6, 0.6, 0.0)]])
		"beam_motes":             # motas que se desprenden a lo largo de un haz (caja: la pone quien lo usa)
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 6.0, 10.0, 40.0))
			p.lifetime = 0.45
			p.local_coords = true
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(0.1, 0.1, r * 0.5)
			m.spread = 180.0
			m.initial_velocity_min = 0.4; m.initial_velocity_max = 1.4
			m.gravity = Vector3(0, 0.8, 0)
			m.scale_min = 0.04; m.scale_max = 0.09
			m.scale_curve = _curve([[0.0, 1.0], [1.0, 0.0]])
			m.color_ramp = _ramp([[0.0, Color(1, 1, 1, 1)], [1.0, Color(0.7, 0.7, 0.7, 0.0)]])
		"gas":                    # gas de cloro: bocanadas lentas, turbias, que suben poco
			p.draw_pass_1 = cube("mix")
			p.amount = int(clampf(r * 8.0, 8.0, 22.0))
			p.lifetime = 1.8
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.8
			m.spread = 60.0
			m.initial_velocity_min = 0.1; m.initial_velocity_max = 0.35
			m.gravity = Vector3(0, 0.12, 0)
			m.angle_min = -45.0; m.angle_max = 45.0
			m.scale_min = 0.32; m.scale_max = 0.6
			m.scale_curve = _curve([[0.0, 0.4], [1.0, 1.0]])
			m.color_ramp = _ramp([[0.0, Color(0.45, 0.5, 0.1, 0.0)], [0.25, Color(0.36, 0.42, 0.08, 0.65)],
				[1.0, Color(0.3, 0.34, 0.1, 0.0)]])
		"dust":                   # polvo: nube sepia baja
			p.draw_pass_1 = cube("mix")
			p.amount = int(clampf(r * 5.0, 5.0, 14.0))
			p.lifetime = 1.6
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.8
			m.spread = 80.0
			m.initial_velocity_min = 0.1; m.initial_velocity_max = 0.3
			m.gravity = Vector3(0, 0.05, 0)
			m.scale_min = 0.18; m.scale_max = 0.32
			m.scale_curve = _curve([[0.0, 0.5], [1.0, 1.0]])
			m.color_ramp = _ramp([[0.0, Color(0.4, 0.28, 0.1, 0.0)], [0.3, Color(0.4, 0.28, 0.1, 0.4)],
				[1.0, Color(0.35, 0.25, 0.1, 0.0)]])
		"motes":                  # motas doradas que flotan y destellan
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 10.0, 10.0, 30.0))
			p.lifetime = 1.8
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.85
			m.spread = 90.0
			m.initial_velocity_min = 0.05; m.initial_velocity_max = 0.3
			m.gravity = Vector3(0, 0.1, 0)
			m.scale_min = 0.03; m.scale_max = 0.06
			m.color_ramp = _ramp([[0.0, Color(0.8, 0.6, 0.25, 0.0)], [0.4, Color(0.85, 0.68, 0.3, 1.0)],
				[1.0, Color(0.6, 0.4, 0.15, 0.0)]])
		"jet":                    # chorro del lanzallamas (sale por +Z local, lo orienta quien lo usa)
			p.draw_pass_1 = cube("add")
			p.amount = 170
			p.lifetime = r / 9.0
			m.direction = Vector3(0, 0, 1)
			m.spread = 12.0
			m.initial_velocity_min = 8.5; m.initial_velocity_max = 11.0
			m.damping_min = 2.0; m.damping_max = 4.0
			m.gravity = Vector3(0, 1.6, 0)
			m.angle_min = -45.0; m.angle_max = 45.0
			m.scale_min = 0.12; m.scale_max = 0.22
			m.scale_curve = _curve([[0.0, 0.4], [0.4, 1.8], [1.0, 3.0]])
			m.color_ramp = _ramp([[0.0, Color(0.6, 0.45, 0.2, 1.0)], [0.12, Color(0.65, 0.32, 0.06, 1.0)],
				[0.5, Color(0.6, 0.2, 0.03, 0.9)], [0.85, Color(0.4, 0.06, 0.01, 0.6)], [1.0, Color(0.1, 0.02, 0.0, 0.0)]])
		"jet_smoke":              # humo negro que se escapa por arriba del chorro
			p.draw_pass_1 = cube("mix")
			p.amount = 24
			p.lifetime = r / 5.0
			m.direction = Vector3(0, 0.25, 1)
			m.spread = 18.0
			m.initial_velocity_min = 4.0; m.initial_velocity_max = 6.0
			m.damping_min = 3.0; m.damping_max = 5.0
			m.gravity = Vector3(0, 1.4, 0)
			m.scale_min = 0.2; m.scale_max = 0.35
			m.scale_curve = _curve([[0.0, 0.3], [1.0, 1.3]])
			m.color_ramp = _ramp([[0.0, Color(0.1, 0.08, 0.07, 0.0)], [0.4, Color(0.12, 0.1, 0.09, 0.5)],
				[1.0, Color(0.25, 0.24, 0.23, 0.0)]])
		"trail":                  # estela de fuego de la bola de Cthugha
			p.draw_pass_1 = cube("add")
			p.amount = int(clampf(r * 90.0, 30.0, 70.0))
			p.lifetime = 0.45
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = r * 0.55
			m.spread = 180.0
			m.initial_velocity_min = 0.2; m.initial_velocity_max = 0.9
			m.gravity = Vector3(0, 2.0, 0)
			m.angle_min = -45.0; m.angle_max = 45.0
			m.scale_min = 0.1; m.scale_max = 0.22
			m.scale_curve = _curve([[0.0, 1.0], [1.0, 0.1]])
			m.color_ramp = _ramp([[0.0, Color(0.85, 0.75, 0.4, 1.0)], [0.3, Color(0.8, 0.4, 0.08, 1.0)],
				[0.75, Color(0.5, 0.08, 0.02, 0.8)], [1.0, Color(0.15, 0.04, 0.02, 0.0)]])
		"ring_dust":              # polvo y nieve levantados por la onda (anillo hacia fuera)
			p.draw_pass_1 = cube("mix")
			p.amount = int(clampf(r * 10.0, 20.0, 50.0))
			p.lifetime = 0.8
			p.explosiveness = 1.0
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			m.emission_ring_axis = Vector3.UP
			m.emission_ring_radius = 0.4
			m.emission_ring_inner_radius = 0.3
			m.emission_ring_height = 0.05
			m.direction = Vector3(1, 0.3, 0)
			m.spread = 180.0
			m.flatness = 0.85
			m.radial_velocity_min = r * 2.0; m.radial_velocity_max = r * 3.0
			m.damping_min = r * 2.0; m.damping_max = r * 3.0
			m.gravity = Vector3(0, -2.0, 0)
			m.scale_min = 0.08; m.scale_max = 0.18
			m.color_ramp = _ramp([[0.0, Color(0.85, 0.85, 0.9, 0.7)], [1.0, Color(0.8, 0.8, 0.85, 0.0)]])
	m.color = tint
	var key := "%s|%.1f|%s" % [recipe, r, tint.to_html()]
	if _mat_cache.has(key): p.process_material = _mat_cache[key]
	else: _mat_cache[key] = m
	if own: p.process_material = p.process_material.duplicate()
	# empieza ya colocado en la escena: emitiendo desde antes, la primera partícula salía en
	# el origen del mundo (un cubo suelto lejos del efecto)
	p.emitting = false
	p.ready.connect(p.restart, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	return p
