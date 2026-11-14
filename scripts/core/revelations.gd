class_name Revelations
extends Node
## Revelaciones (hito 21.7, data/revelations.json): quien sale de una crisis de locura elige entre
## dos, al azar entre las que aún no tiene, y le duran lo que queda del nivel (van en
## PlayerProgress.revelations, que no pasa de nivel). Así la caída de la cordura también se busca.
## Unas cambian estadísticas (apply_stats, desde Player.rebuild_stats) y otras son un efecto que
## lleva este nodo, uno por partida:
## - "eyes": en este PC, brillan los ojos de los enemigos cercanos, también a través del decorado (y
##   el farol alumbra más: Player.rebuild_stats, "farol").
## - "walls": sus balas atraviesan el decorado (BulletManager.walls_free; en todos los PC).
## - "reveal" y "aura": revelar o herir a los de alrededor. Solo donde se manda en los enemigos
##   (sin red o en el anfitrión: `authority`).
## Al llegar una nueva (en cualquier PC, también por la red), su destello, su sonido y su gesto.

const PATH := "res://data/revelations.json"
const OPTIONS := 2                           ## las que se ofrecen
const TICK := 0.5                            ## s entre pasadas de "reveal" y "aura"
const COLOR := Color(0.78, 0.55, 1.0)        ## el de las cartas y la ficha
const EYE_MAX := 160                         ## ojos que se dibujan como mucho (dos por enemigo)
const EYE_SIZE := Vector2(0.1, 0.065)
const EYE_GAP := 0.075                       ## media distancia entre los dos ojos
const AURA_FX := 1.0                         ## s entre anillos del aura

static var _data := {}
static var _by_id := {}

var world: CombatWorld
var authority := true
var _t := 0.0
var _aura_fx := {}                           ## índice del jugador -> s hasta el siguiente anillo
var _seen := {}                              ## índice del jugador -> revelaciones ya vistas
var _eyes: MultiMeshInstance3D
var _eye_mat: ShaderMaterial
static var _eye_h := {}                      ## modelo -> altura de sus ojos sin escalar (m)

static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		_data = d if d is Dictionary else {"revelaciones": []}
		for r: Dictionary in _data.revelaciones: _by_id[String(r.id)] = r
	return _data

static func all() -> Array:
	return data().revelaciones

static func find(id: String) -> Dictionary:
	data()
	return _by_id.get(id, {})

static func icon(id: String) -> Texture2D:
	var path := "res://resources/revelations/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null

static func color_of(id: String) -> Color:
	var c: Array = find(id).get("color", [COLOR.r, COLOR.g, COLOR.b])
	return Color(float(c[0]), float(c[1]), float(c[2]))

## Hasta OPTIONS al azar entre las que no tiene.
static func roll(have: Array, rng: RandomNumberGenerator) -> Array[String]:
	var left: Array[String] = []
	for r: Dictionary in all():
		if not have.has(String(r.id)): left.append(String(r.id))
	var out: Array[String] = []
	while not left.is_empty() and out.size() < OPTIONS:
		out.append(left.pop_at(rng.randi() % left.size()))
	return out

## Las estadísticas de las que lleva ("campo*" multiplica, "campo+" suma), sobre `v` de rebuild_stats.
static func apply_stats(v: Dictionary, ids: Array) -> void:
	for id: String in ids:
		var st: Dictionary = find(id).get("stats", {})
		for k: String in st:
			var field := k.substr(0, k.length() - 1)
			if not v.has(field): continue
			if k.ends_with("*"): v[field] = float(v[field]) * float(st[k])
			elif k.ends_with("+"): v[field] = float(v[field]) + float(st[k])

## La primera que lleva con ese efecto ({} si ninguna).
static func with_effect(ids: Array, efecto: String) -> Dictionary:
	for id: String in ids:
		var r := find(id)
		if String(r.get("efecto", "")) == efecto: return r
	return {}

func setup(p_world: CombatWorld, p_authority: bool) -> Revelations:
	world = p_world
	authority = p_authority
	name = "Revelations"
	return self

func _physics_process(delta: float) -> void:
	if world == null: return
	var mask := 0
	for q: Player in world.players:
		if q.progress == null: continue
		var ids: Array = q.progress.revelations
		if ids.size() > int(_seen.get(q.index, 0)):      # una nueva: destello, sonido y gesto
			_flash(q, String(ids[ids.size() - 1]))
		_seen[q.index] = ids.size()
		if not with_effect(ids, "walls").is_empty(): mask |= 1 << q.index
	if world.bullets != null: world.bullets.walls_free = mask
	if not authority: return
	_t -= delta
	if _t > 0.0: return
	_t = TICK
	for q: Player in world.players:
		if q.progress == null or q.progress.revelations.is_empty() or q.health <= 0.0: continue
		var rv := with_effect(q.progress.revelations, "reveal")
		if not rv.is_empty():
			for e in world.enemies_in_circle(q.global_position, float(rv.get("radio", 7.0))):
				if e is Enemy and e.is_alive(): (e as Enemy).reveal(TICK * 2.5, float(rv.get("bonus", 0.25)))
		var au := with_effect(q.progress.revelations, "aura")
		if not au.is_empty(): _aura(q, au)

## «La mirada que hiere»: daño a los de alrededor, a cuenta de «J<n>:revelacion» (su fila en la
## tabla de daño), con un anillo y un latido de vez en cuando.
func _aura(q: Player, au: Dictionary) -> void:
	var r := float(au.get("radio", 3.0))
	var hit := false
	var prev := Damage.ctx
	Damage.ctx = StringName("J%d:revelacion" % (q.index + 1))
	for e in world.enemies_in_circle(q.global_position, r):
		if not (e is Enemy) or not e.is_alive(): continue
		e.take_damage(Damage.new(float(au.get("dps", 10.0)) * TICK, 0.0))
		hit = true
	Damage.ctx = prev
	_aura_fx[q.index] = float(_aura_fx.get(q.index, 0.0)) - TICK
	if hit and float(_aura_fx[q.index]) <= 0.0:
		_aura_fx[q.index] = AURA_FX
		VoxelFx.ground_hit(world.fx, q.global_position, r, Color(color_of(String(au.id)), 0.55), false)
		Auto.sfx_at("gaze_pulse", q.global_position)

## Al llegar una revelación: anillo y chispas de su color, el ojo que se abre sobre la cabeza,
## su sonido y el gesto (manos a las sienes y los brazos abiertos).
func _flash(q: Player, id: String) -> void:
	var c := color_of(id)
	VoxelFx.ground_hit(world.fx, q.global_position, 2.6, Color(c, 0.85), false)
	VoxelFx.puff(world.fx, q.global_position + Vector3(0, 1.0, 0), "sparkle", 1.1, c, 1.2)
	Auto.sfx_at("revelation", q.global_position)
	q.play_once("revelation", true)
	var tex := icon(id)
	if tex == null: return
	var s := Sprite3D.new()                           # el ojo, sobre la cabeza: crece y se apaga
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.no_depth_test = true
	s.render_priority = 10
	s.pixel_size = 0.9 / tex.get_width()
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.modulate = Color(1, 1, 1, 0)
	s.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# lo sigue: en su Visual (va en _process, a la posición que se dibuja); gira con él, pero está
	# sobre su eje y es un letrero que mira a la cámara
	var host: Node3D = q.visual if q.visual != null and is_instance_valid(q.visual) else world.fx
	host.add_child(s)
	s.position = Vector3(0, 2.3, 0) if host != world.fx else q.global_position + Vector3(0, 2.3, 0)
	s.scale = Vector3.ONE * 0.4
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 1.0, 0.2)
	tw.tween_property(s, "position:y", s.position.y + 0.3, 1.25)
	tw.chain().tween_property(s, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(s.queue_free)

## «Ojos en la oscuridad»: dos ojos por enemigo a menos de su radio de un jugador de este PC que la
## lleve, por encima de todo (un MultiMesh; revelation_eyes.gdshader). Escalan con el enemigo.
func _process(_delta: float) -> void:
	if world == null: return
	var who: Array[Player] = []
	var radius := 0.0
	for q: Player in world.players:
		if q.remote or q.progress == null or q.health <= 0.0: continue
		var ey := with_effect(q.progress.revelations, "eyes")
		if ey.is_empty(): continue
		who.append(q)
		radius = maxf(radius, float(ey.get("radio", 16.0)))
	if who.is_empty():
		if _eyes != null: _eyes.visible = false
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	if _eyes == null: _make_eyes()
	var mm := _eyes.multimesh
	var right := cam.global_basis.x.normalized()
	var face := Basis(right * EYE_SIZE.x / 0.1, cam.global_basis.y.normalized() * EYE_SIZE.y / 0.1, cam.global_basis.z)
	var toward := Vector3(cam.global_basis.z.x, 0.0, cam.global_basis.z.z).normalized()   # hacia la cámara, en el suelo
	var n := 0
	var done := {}
	for q in who:
		for e in world.enemies_in_circle(q.global_position, radius):
			if n + 2 > EYE_MAX: break
			if not (e is Enemy) or done.has(e) or not e.is_alive() or (e as Enemy).buried: continue
			done[e] = true
			var en := e as Enemy
			var k := clampf(en.model_scale, 0.6, 3.0)
			var at := en.get_global_transform_interpolated().origin   # (en la horda, su Visual no está en el árbol)
			at += Vector3(0, eye_height(en), 0)
			var f := Vector3(en.facing.x, 0.0, en.facing.z).normalized()
			var front := f.dot(toward)                 # 1 de cara, 0 de perfil, -1 de espaldas
			at += f * 0.12 * k                         # en la cara, no en el centro de la cabeza
			var gap := EYE_GAP * k * maxf(absf(front), 0.3)   # de perfil, juntos
			var fk := Basis(face.x * k, face.y * k, face.z)
			for side: float in [-1.0, 1.0]:
				mm.set_instance_transform(n, Transform3D(fk, at + right * gap * side))
				mm.set_instance_custom_data(n, Color(float(en.get_instance_id() % 97) * 0.37, 1.0 if front > -0.25 else 0.3, 0, 0))
				n += 1
	mm.visible_instance_count = n
	_eyes.visible = n > 0

## Altura de los ojos de un enemigo: el 86 % de lo alto de su modelo, medido una vez por modelo
## desde sus mallas (en la horda, su modelo de nodos sigue ahí, fuera del árbol; la altura de
## HordeMesh no vale para esto).
static func eye_height(en: Enemy) -> float:
	var key := String(en.data.model)
	if not _eye_h.has(key):
		var m := en.model
		if m == null or not m.has_meta("meshes"): return 1.2 * en.model_scale
		var top := 0.0
		for mi: MeshInstance3D in m.get_meta("meshes"):
			if not is_instance_valid(mi) or mi.mesh == null: continue
			var xf := Transform3D()
			var n: Node = mi
			while n != m and n is Node3D:
				xf = (n as Node3D).transform * xf
				n = n.get_parent()
			top = maxf(top, (xf * mi.get_aabb()).end.y)
		if top <= 0.0: return 1.2 * en.model_scale
		_eye_h[key] = top * 0.86
	return float(_eye_h[key]) * en.model_scale

func _make_eyes() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = EYE_MAX
	mm.visible_instance_count = 0
	_eye_mat = ShaderMaterial.new()
	_eye_mat.shader = preload("res://scripts/core/revelation_eyes.gdshader")
	_eye_mat.set_shader_parameter("color", Color(color_of("ojos_muros")))
	_eyes = MultiMeshInstance3D.new()
	_eyes.name = "RevelationEyes"
	_eyes.multimesh = mm
	_eyes.material_override = _eye_mat
	_eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_eyes.custom_aabb = AABB(Vector3(-5000, -50, -5000), Vector3(10000, 100, 10000))
	_eyes.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_eyes)
