class_name MoonShafts
extends Node3D
## Haces de luna (hito 16.32): la luz de la luna entra por los ventanales del estudio de Wilcox y
## cae por las grietas del techo de los túneles. Cada haz es el conjunto de puntos
## W0 + a·U + b·V + t·D: la abertura (a, b en 0..1, de lados U y V) barrida en la dirección de la luz
## D hasta el suelo. Tres piezas por haz:
## - el haz en el aire (`moon_shaft.gdshader`): su contorno, con el rayo de la vista recortado en
##   el shader y la luz sumada a lo largo del tramo (el parteluz deja franjas);
## - un foco (`SpotLight3D` con proyector) que dibuja la forma de la abertura en el suelo y alumbra
##   a quien pasa por el haz;
## - motas de polvo que solo se ven dentro (`moon_mote.gdshader`).
## Las nubes pasan: la intensidad sube y baja despacio. Datos en `data/moon_shafts.json`; solo en
## Alta y Ultra (`Quality` "moon_shafts"; `moon_shafts=true|false` para comparar).

const CONFIG := "res://data/moon_shafts.json"
const SHAPE_WINDOW := 0
const SHAPE_GAP := 1
const LIGHT_DIST := 30.0                         ## a qué distancia de la abertura va el foco
const PROJ_PX := 96                              ## lado de la textura del proyector

class Shaft:
	var w0: Vector3                              ## esquina de la abertura
	var u: Vector3                               ## lados de la abertura
	var v: Vector3
	var d: Vector3                               ## dirección de la luz (unitaria, hacia abajo)
	var shape := SHAPE_WINDOW
	var frame := true
	var seed := 0.0
	var phase := 0.0
	var mat: ShaderMaterial
	var mote_mat: ShaderMaterial
	var light: SpotLight3D

	## del mundo a (a, b, t)
	func to_local() -> Transform3D: return Transform3D(Basis(u, v, d), w0).affine_inverse()
	func floor_c() -> Vector4: return Vector4(w0.y, u.y, v.y, -d.y)
	func center() -> Vector3: return w0 + (u + v) * 0.5
	## las cuatro esquinas de la abertura y, detrás, dónde caen en el suelo
	func corners() -> Array[Vector3]:
		var out: Array[Vector3] = []
		for k in 2:
			for j in 2:
				for i in 2:
					var c := w0 + u * i + v * j
					out.append(c if k == 0 else c + d * (c.y / -d.y))
		return out
	## centro de la mancha en el suelo
	func landing() -> Vector3:
		var c := center()
		return c + d * (c.y / -d.y)

static var _cfg: Dictionary = {}

static func config() -> Dictionary:
	if _cfg.is_empty():
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		_cfg = j if j is Dictionary else {"_doc": ""}
	return _cfg

static func has_shafts(arena_id: String) -> bool: return config().has(arena_id)

## La forma de la abertura en (a, b): la misma que `shaft_mask` del shader.
static func mask(shape: int, frame: bool, seed: float, a: float, b: float) -> float:
	if a < 0.0 or a > 1.0 or b < 0.0 or b > 1.0: return 0.0
	if shape == SHAPE_WINDOW:
		var u := a * 32.0
		var y := 22.0 + b * 82.0
		var inside := y < 88.0 or (u - 16.0) * (u - 16.0) + (y - 88.0) * (y - 88.0) <= 256.0
		if not inside: return 0.0
		if frame and (u < 2.0 or (u >= 15.0 and u < 17.0) or u >= 30.0 or fposmod(y - 22.0, 20.0) < 2.0): return 0.0
		return 1.0
	var p := Vector2(a, b) * 2.0 - Vector2.ONE
	var ang := atan2(p.y, p.x)
	var rr := 0.78 + 0.10 * sin(3.0 * ang + seed) + 0.07 * sin(5.0 * ang + 2.0 * seed) + 0.04 * sin(9.0 * ang + 3.0 * seed)
	return 1.0 - smoothstep(rr - 0.16, rr, p.length())

## Dirección de la luna de la arena (su luz direccional).
static func moon_dir(arena: Node3D) -> Vector3:
	var l: Dictionary = arena.get_meta("light", {})
	var r: Array = l.get("sun_rot", [-50, 30])
	return (Basis.from_euler(Vector3(deg_to_rad(r[0]), deg_to_rad(r[1]), 0)) * Vector3.FORWARD).normalized()

## Los haces de una arena (sin crear nada: se puede probar).
static func plan(arena: Node3D, arena_id: String) -> Array[Shaft]:
	var out: Array[Shaft] = []
	var c: Dictionary = config().get(arena_id, {})
	if c.is_empty(): return out
	var d := moon_dir(arena)
	if c.has("dir"): d = Vector3(c.dir[0], c.dir[1], c.dir[2]).normalized()
	if d.y > -0.05: return out                   # luz rasante o de abajo: no cae al suelo
	var size: Vector2 = arena.get_meta("size", Vector2(64, 64))
	var half := size * 0.5 - Vector2(0.5, 0.5)
	if c.has("windows"):
		var wn: Dictionary = c.windows
		var w := float(wn.get("w", 1.0))
		var y0 := float(wn.get("y0", 0.7))
		var y1 := float(wn.get("y1", 3.2))
		var props := arena.get_node_or_null("Props")
		if props != null:
			for holder: Node3D in props.get_children():
				if holder.get_child_count() == 0: continue
				var m: Dictionary = (wn.models as Dictionary).get(String(holder.get_child(0).name), {})
				if m.is_empty(): continue
				var t := holder.transform
				if d.dot(t.basis.z.normalized()) < 0.3: continue     # la luz no entra (o entra rasante) por esta cara
				for lx: float in m.get("x", []):
					var s := Shaft.new()
					s.w0 = t * Vector3(lx - w * 0.5, y0, 0.0)
					s.u = t.basis * Vector3(w, 0, 0)
					s.v = t.basis * Vector3(0, y1 - y0, 0)
					s.d = d
					s.frame = bool(m.get("frame", true))
					var f := s.landing()
					if absf(f.x) > half.x or absf(f.z) > half.y: continue
					out.append(s)
	var height := float(c.get("height", 10.0))
	for g: Dictionary in c.get("gaps", []):
		var s := Shaft.new()
		var r := float(g.get("r", 1.0))
		var at := Vector3(g.at[0], 0, g.at[1])
		var top := at - d * (height / -d.y)
		s.u = Vector3(2.0 * r, 0, 0)
		s.v = Vector3(0, 0, 2.0 * r)
		s.w0 = top - (s.u + s.v) * 0.5
		s.d = d
		s.shape = SHAPE_GAP
		s.frame = false
		s.seed = fposmod(at.x * 1.37 + at.z * 2.11, TAU)
		out.append(s)
	for s in out: s.phase = s.center().x * 0.09 + s.center().z * 0.05
	return out

var shafts: Array[Shaft] = []
var _c: Dictionary
var _t := 0.0

func setup(arena: Node3D, arena_id: String) -> MoonShafts:
	name = "MoonShafts"
	_c = config().get(arena_id, {})
	shafts = plan(arena, arena_id)
	return self

func _ready() -> void:
	var t0 := Time.get_ticks_usec()
	var shader: Shader = load("res://scripts/fx/moon_shaft.gdshader")
	var mote_shader: Shader = load("res://scripts/fx/moon_mote.gdshader")
	var col := _color("color", Color(0.62, 0.72, 1.0))
	var texs := {}
	for s in shafts:
		s.mat = ShaderMaterial.new()
		s.mat.shader = shader
		_shaft_params(s.mat, s)
		s.mat.set_shader_parameter("color", col)
		s.mat.set_shader_parameter("density", float(_c.get("density", 0.8)))
		s.mat.set_shader_parameter("fade_top", float(_c.get("fade", 2.5)) if s.shape == SHAPE_GAP else 0.15)
		var mi := MeshInstance3D.new()
		mi.mesh = _hull(s)
		mi.material_override = s.mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		# el foco: la forma de la abertura en el suelo y en lo que cruza el haz
		s.light = SpotLight3D.new()
		var ang := _aim(s)
		# los ventanales iguales en la misma pared comparten textura
		var key := "%d_%s_%.2f_%s_%s_%s" % [s.shape, s.frame, s.seed, s.u.snappedf(0.01), s.v.snappedf(0.01), s.d]
		if not texs.has(key): texs[key] = _projector(s, ang)
		s.light.light_projector = texs[key]
		s.light.spot_angle = rad_to_deg(ang)
		s.light.spot_angle_attenuation = 0.05
		s.light.spot_attenuation = 0.0
		s.light.spot_range = LIGHT_DIST + s.center().y / -s.d.y + 6.0
		s.light.light_color = col
		s.light.light_energy = float(_c.get("light", 2.0))
		s.light.light_specular = 0.2
		# el proyector usa la matriz de sombra: sin sombras no sale. Solo hacen sombra los
		# investigadores (la pared, con el foco detrás, lo taparía todo)
		s.light.shadow_enabled = true
		s.light.shadow_caster_mask = Player.VIS_PLAYER
		add_child(s.light)
		# motas
		var n := int(_c.get("motes", 40))
		if n > 0:
			s.mote_mat = ShaderMaterial.new()
			s.mote_mat.shader = mote_shader
			_shaft_params(s.mote_mat, s)
			s.mote_mat.set_shader_parameter("color", col)
			add_child(_motes(s, n))
	if LaunchArgs.from_cmdline().get_bool("log"):
		print("HACES DE LUNA %d haces, %d texturas, %.1f ms" % [shafts.size(), texs.size(), (Time.get_ticks_usec() - t0) / 1000.0])

func _color(key: String, def: Color) -> Color:
	var a: Array = _c.get(key, [])
	return Color(a[0], a[1], a[2]) if a.size() >= 3 else def

func _shaft_params(m: ShaderMaterial, s: Shaft) -> void:
	m.set_shader_parameter("shaft_to_local", Projection(s.to_local()))
	m.set_shader_parameter("shaft_floor", s.floor_c())
	m.set_shader_parameter("shaft_shape", s.shape)
	m.set_shader_parameter("shaft_frame", s.frame)
	m.set_shader_parameter("shaft_seed", s.seed)

## Contorno del haz: un hexaedro con la abertura y su mancha en el suelo.
func _hull(s: Shaft) -> ArrayMesh:
	var c := s.corners()
	# un poco más grande: el shader recorta lo justo
	var mid := Vector3.ZERO
	for p in c: mid += p / 8.0
	for i in 8: c[i] = mid + (c[i] - mid) * 1.04
	var faces := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]
	var verts := PackedVector3Array()
	for f: Array in faces:
		for k: int in [0, 1, 2, 0, 2, 3]: verts.append(c[f[k]])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh

## Pone el foco detrás de la abertura mirando en la dirección de la luz; devuelve su medio ángulo.
func _aim(s: Shaft) -> float:
	var c := s.center()
	var lp := c - s.d * LIGHT_DIST
	var up := Vector3.UP if absf(s.d.y) < 0.98 else Vector3.FORWARD
	s.light.transform = Transform3D(Basis.looking_at(s.d, up), lp)
	var ang := 0.0
	for i in 4:
		ang = maxf(ang, s.d.angle_to(s.corners()[i] - lp))
	return ang * 1.05

## La abertura vista desde el foco: para cada texel, su rayo hasta el plano de la abertura.
func _projector(s: Shaft, ang: float) -> ImageTexture:
	var img := Image.create(PROJ_PX, PROJ_PX, false, Image.FORMAT_RGBA8)
	var lb := s.light.transform.basis
	var lp := s.light.transform.origin
	var n := s.u.cross(s.v)
	var inv := s.to_local()
	var ta := tan(ang)
	for j in PROJ_PX:
		for i in PROJ_PX:
			var x := ((i + 0.5) / PROJ_PX * 2.0 - 1.0) * ta
			var y := (1.0 - (j + 0.5) / PROJ_PX * 2.0) * ta
			var dir := lb * Vector3(x, y, -1.0)
			var den := dir.dot(n)
			var m := 0.0
			if absf(den) > 1e-6:
				var p := lp + dir * ((s.w0 - lp).dot(n) / den)
				var l := inv * p
				m = mask(s.shape, s.frame, s.seed, l.x, l.y)
			img.set_pixel(i, j, Color(m, m, m))
	return ImageTexture.create_from_image(img)

func _motes(s: Shaft, n: int) -> GPUParticles3D:
	var box := AABB(s.corners()[0], Vector3.ZERO)
	for p in s.corners(): box = box.expand(p)
	var p := GPUParticles3D.new()
	p.amount = n
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.local_coords = false
	p.position = box.get_center()
	p.visibility_aabb = AABB(-box.size * 0.5 - Vector3.ONE, box.size + Vector3.ONE * 2.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box.size * 0.5
	pm.gravity = Vector3(0, -0.01, 0)
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.08
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.25, Color(1, 1, 1, 1))
	g.add_point(0.75, Color(1, 1, 1, 1))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.04, 0.04)
	q.material = s.mote_mat
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p

## Las nubes pasan delante de la luna.
func _process(delta: float) -> void:
	_t += delta
	var e := float(_c.get("energy", 1.0))
	var le := float(_c.get("light", 2.0))
	for s in shafts:
		var k := 0.8 + 0.2 * (0.6 * sin(_t * 0.21 + s.phase) + 0.4 * sin(_t * 0.53 + s.phase * 1.7))
		s.mat.set_shader_parameter("energy", e * k)
		if s.mote_mat != null: s.mote_mat.set_shader_parameter("energy", e * k)
		s.light.light_energy = le * k
