class_name DecorBreak
extends Node3D
## Decorado que se rompe con las explosiones (hito 16.34): cajas, barriles, sacos, muros bajos,
## columnas, estatuas y estalagmitas de la arena aguantan unas explosiones (`hp`; cada una tiembla
## y destella), y a la última se desmoronan en voxels de arriba abajo (el material de `Crumble`),
## saltan trozos (`DeathBurst`), quedan astillas (`Debris`) y un montón de cascotes que ya no se va.
## Su huella se borra del mapa de lo transitable (`ObstacleMap.clear_box`): por donde había una
## pared se pasa, y las balas también. Datos en `data/decor_break.json`.
## Romperse no depende de la calidad (cambia por dónde se anda): solo los cascotes que quedan
## (`Quality` "decor_rubble") y si se deshace o desaparece (`Crumble.enabled`). En red decide el
## anfitrión (que ve todas las explosiones: cada PC simula las armas de todos) y lo cuenta a los
## invitados (`NetGame` EVENT "decor").

signal piece_broken(index: int)

const CONFIG := "res://data/decor_break.json"
const CRUMBLE_TIME := 0.8
const SHAKE_TIME := 0.25

class Piece:
	var index := 0
	var holder: Node3D
	var model: Node3D
	var id := ""
	var material := "wood"
	var hp := 1.0
	var inv: Transform3D                        ## del mundo al contenedor de la pieza
	var lo := Vector2.ZERO                      ## su caja (x, z) en el contenedor
	var hi := Vector2.ZERO
	var broken := false
	var shake := 0.0
	var base: Transform3D

	func center() -> Vector3:
		var c := (lo + hi) * 0.5
		return holder.transform * Vector3(c.x, 0.0, c.y)

	## Distancia (m) de un punto del suelo a la huella de la pieza.
	func distance_to(p: Vector3) -> float:
		var l := inv * Vector3(p.x, 0.0, p.z)
		var q := Vector3(clampf(l.x, lo.x, hi.x), 0.0, clampf(l.z, lo.y, hi.y))
		var w := holder.transform * q
		return Vector2(w.x, w.z).distance_to(Vector2(p.x, p.z))

static var current: DecorBreak
static var _cfg: Dictionary = {}
static var _flash_mat: StandardMaterial3D

static func config() -> Dictionary:
	if _cfg.is_empty():
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		_cfg = j if j is Dictionary else {"models": {}, "materials": {}}
	return _cfg

static func material_of(model_id: String) -> String:
	return String((config().get("models", {}) as Dictionary).get(model_id, ""))

## Una explosión (Explosion._ready): daña lo que toca.
static func blast(pos: Vector3, radius: float) -> void:
	if current != null and is_instance_valid(current): current._blast(pos, radius)

## Las piezas que se pueden romper: de un material conocido, lejos del borde y sin tocar otra pieza.
static func candidates(arena: Node3D) -> Array[Piece]:
	var out: Array[Piece] = []
	var props := arena.get_node_or_null("Props")
	if props == null: return out
	var size: Vector2 = arena.get_meta("size", Vector2(64, 64))
	var edge := float(config().get("edge", 2.0))
	var rects: Array[Rect2] = []
	var all: Array = []
	for holder: Node3D in props.get_children():
		if holder.get_child_count() == 0 or not (holder.get_child(0) is Node3D):
			rects.append(Rect2())
			all.append(null)
			continue
		var m := holder.get_child(0) as Node3D
		var box := ArenaBuilder._model_aabb(m)
		var r := Rect2()
		for k in 4:
			var p := holder.transform * Vector3(box.position.x if k & 1 == 0 else box.end.x, 0.0, box.position.z if k & 2 == 0 else box.end.z)
			r = Rect2(Vector2(p.x, p.z), Vector2.ZERO) if k == 0 else r.expand(Vector2(p.x, p.z))
		rects.append(r)
		all.append([holder, m, box])
	for i in all.size():
		if all[i] == null: continue
		var holder: Node3D = all[i][0]
		var m: Node3D = all[i][1]
		var mat := material_of(String(m.name))
		if mat == "" or not m.has_meta("meshes"): continue
		var r := rects[i]
		if absf(r.get_center().x) > size.x * 0.5 - edge or absf(r.get_center().y) > size.y * 0.5 - edge: continue
		var touches := false
		var grown := r.grow(0.2)
		for j in rects.size():
			if j != i and rects[j].has_area() and grown.intersects(rects[j]):
				touches = true
				break
		if touches: continue
		var box: AABB = all[i][2]
		var p := Piece.new()
		p.index = out.size()
		p.holder = holder
		p.model = m
		p.id = String(m.name)
		p.material = mat
		p.hp = float(((config().materials as Dictionary).get(mat, {}) as Dictionary).get("hp", 1))
		p.inv = holder.transform.affine_inverse()
		p.lo = Vector2(box.position.x, box.position.z)
		p.hi = Vector2(box.end.x, box.end.z)
		p.base = holder.transform
		out.append(p)
	return out

var arena: Node3D
var world: CombatWorld
var mirror := false                              ## invitado en red: lo rompe el anfitrión
var pieces: Array[Piece] = []
var _crumbling: Array = []                       ## [pieza, vestida, t]
var _rubble_n := 40
var _warm: Array[Piece] = []

func setup(p_arena: Node3D, p_world: CombatWorld, p_mirror := false) -> DecorBreak:
	name = "DecorBreak"
	arena = p_arena
	world = p_world
	mirror = p_mirror
	pieces = candidates(arena)
	return self

func _ready() -> void:
	current = self
	_rubble_n = int(Quality.value("decor_rubble", 40))
	if _flash_mat == null:
		_flash_mat = StandardMaterial3D.new()
		_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_mat.albedo_color = Color(1, 0.86, 0.66, 0.22)
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if LaunchArgs.from_cmdline().get_bool("log"): print("DECORADO ROMPIBLE %d piezas" % pieces.size())
	# la paleta de cada modelo (para trozos y cascotes) se calcula de sus mallas la primera vez: hasta
	# 15 ms. Se adelanta, un modelo por fotograma, en cuanto empieza el nivel
	var seen := {}
	for p in pieces:
		if not seen.has(p.id):
			seen[p.id] = true
			_warm.append(p)
	# pruebas: decor_blast=t hace estallar, desde t s, una explosión cada 0,7 s en las piezas más
	# cercanas al J1 (dos en cada una, para ver el temblor y la caída)
	var at := LaunchArgs.from_cmdline().get_float("decor_blast", -1.0)
	if at >= 0.0: get_tree().create_timer(at).timeout.connect(_test_blasts)

func _test_blasts() -> void:
	var from := Vector3.ZERO
	if world != null and not world.players.is_empty(): from = (world.players[0] as Node3D).global_position
	var near := pieces.duplicate()
	near.sort_custom(func(a: Piece, b: Piece) -> bool: return a.center().distance_to(from) < b.center().distance_to(from))
	var t := 0.0
	for p: Piece in near.slice(0, 4):
		for k in int(ceil(p.hp)):
			get_tree().create_timer(t).timeout.connect(func() -> void:
				var fx := Explosion.new()
				fx.radius = 2.0
				fx.position = p.center() + Vector3(0.6, 0.0, 0.6)
				(world.fx if world != null else self).add_child(fx))
			t += 0.7

func _exit_tree() -> void:
	if current == self: current = null

func _blast(pos: Vector3, radius: float) -> void:
	if mirror: return
	for p in pieces:
		if p.broken: continue
		var d := p.distance_to(pos)
		if d > radius: continue
		p.hp -= 1.0 if d < radius * 0.5 else 0.5
		if p.hp <= 0.001:
			crumble(p.index)
			piece_broken.emit(p.index)
		else:
			p.shake = SHAKE_TIME
			Auto.sfx_at(String(_mat(p).get("sfx", "gravel")), p.center())

## Rompe la pieza `i` (también la que llega del anfitrión).
func crumble(i: int) -> void:
	if i < 0 or i >= pieces.size() or pieces[i].broken: return
	var p := pieces[i]
	var t0 := Time.get_ticks_usec()
	p.broken = true
	p.shake = 0.0
	p.holder.transform = p.base
	var c := p.center()
	var m := _mat(p)
	Auto.sfx_at(String(m.get("sfx", "gravel")), c)
	# lo que bloqueaba deja de hacerlo: el mapa y, sin él, el cuerpo de la pieza
	var obstacles: ObstacleMap = arena.get_meta("obstacles", null)
	if obstacles != null: obstacles.clear_box(p.inv, p.lo, p.hi)
	var t_map := Time.get_ticks_usec()
	for b in p.holder.find_children("*", "StaticBody3D", true, false): b.queue_free()
	if world != null:
		var burst := DeathBurst.new()
		burst.setup(p.id, maxf((p.hi - p.lo).length() * 0.35, 0.4), p.model, true)
		burst.position = c
		world.fx.add_child(burst)
		Debris.scatter(world.fx, c, DeathBurst.palette_of(p.id, p.model), 12, maxf((p.hi - p.lo).length() * 0.4, 0.5))
	var t_fx := Time.get_ticks_usec()
	_rubble(p)
	if LaunchArgs.from_cmdline().get_bool("log"): print("DECORADO ROTO %s %.2f ms (mapa %.2f, trozos %.2f, cascotes %.2f)" % [p.id, (Time.get_ticks_usec() - t0) / 1000.0, (t_map - t0) / 1000.0, (t_fx - t_map) / 1000.0, (Time.get_ticks_usec() - t_fx) / 1000.0])
	if Crumble.enabled:
		var dc: Array = m.get("dust", [0.5, 0.48, 0.45])
		_crumbling.append([p, Crumble.dress(p.model, Color(dc[0], dc[1], dc[2])), 0.0])
	else:
		p.holder.visible = false

func _mat(p: Piece) -> Dictionary:
	return ((config().get("materials", {}) as Dictionary).get(p.material, {}) as Dictionary)

## Montón de cascotes de los colores de la pieza, en su huella: se queda todo el nivel.
func _rubble(p: Piece) -> void:
	if _rubble_n <= 0: return
	var pal := DeathBurst.palette_of(p.id, p.model)
	if pal.is_empty(): return
	var ch: Array = _mat(p).get("chunk", [0.06, 0.16])
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = VoxelBuilder.colors_are_srgb()
	mat.roughness = 0.95
	bm.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = bm
	var area := (p.hi - p.lo).x * (p.hi - p.lo).y * p.holder.scale.x * p.holder.scale.x
	var n := clampi(int(_rubble_n * clampf(area / 1.2, 0.6, 1.6)), 8, _rubble_n * 2)
	mm.instance_count = n
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p.index * 7919 + int(p.center().x * 100.0))
	var mid := (p.lo + p.hi) * 0.5
	var half := (p.hi - p.lo) * 0.5
	for k in n:
		# más en el centro: un montón, no una alfombra
		var u := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		u *= sqrt(rng.randf())
		var lp := Vector3(mid.x + u.x * half.x * 1.1, 0.0, mid.y + u.y * half.y * 1.1)
		var wp := p.holder.transform * lp
		var s := rng.randf_range(float(ch[0]), float(ch[1])) * (1.0 + 0.9 * (1.0 - u.length()))
		var size := Vector3(s, s * rng.randf_range(0.5, 0.9), s * rng.randf_range(0.7, 1.3))
		var y := size.y * 0.35 + (1.0 - u.length()) * s * 0.8
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.4, 0.4))
		mm.set_instance_transform(k, Transform3D(b * Basis.from_scale(size), Vector3(wp.x, y, wp.z)))
		var c: Color = pal[rng.randi() % pal.size()]
		mm.set_instance_color(k, c.darkened(rng.randf() * 0.3))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.name = "Rubble_%d" % p.index
	add_child(mi)

func _process(delta: float) -> void:
	if not _warm.is_empty():
		var w: Piece = _warm.pop_back()
		DeathBurst.palette_of(w.id, w.model)
	for p in pieces:
		if p.shake <= 0.0: continue
		p.shake -= delta
		var k := maxf(p.shake, 0.0) / SHAKE_TIME
		var off := Vector3(sin(p.shake * 90.0), 0.0, cos(p.shake * 77.0)) * 0.035 * k
		p.holder.transform = Transform3D(p.base.basis, p.base.origin + off)
		for mi: MeshInstance3D in p.model.get_meta("meshes"):
			if is_instance_valid(mi): mi.material_overlay = _flash_mat if p.shake > SHAKE_TIME * 0.7 else null
		if p.shake <= 0.0: p.holder.transform = p.base
	for i in range(_crumbling.size() - 1, -1, -1):
		var it: Array = _crumbling[i]
		it[2] += delta
		var k := clampf(float(it[2]) / CRUMBLE_TIME, 0.0, 1.0)
		Crumble.set_cut(it[1], k * k * (3.0 - 2.0 * k) * 1.02)
		if k >= 1.0:
			(it[0] as Piece).holder.visible = false
			_crumbling.remove_at(i)
