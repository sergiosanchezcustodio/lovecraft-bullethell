class_name Hallucinations
extends Node3D
## Alucinaciones con poca cordura (hito 13.4, fase 13; D-43). Por debajo de `THRESHOLD` de cordura
## (más a menudo cuanto más baja, y a cero, todo el rato) cada jugador de este PC ve cosas que no
## están: criaturas que salen a unos metros y se le acercan andando (copias de las que hay vivas)
## y que se deshacen en niebla al tocarlas o al rato; gemas que se desvanecen al acercarse; y su
## panel del HUD, que por un momento marca la vida o la cordura que no tiene (`Player.hud_lie`).
## Solo se ve: nada de esto entra en `CombatWorld` ni viaja por la red. En cooperativo las ven
## todos, pero salen junto al que alucina y llevan un leve tinte de su color (D-43).
## Configuración > Juego > Accesibilidad > «Alucinaciones» las quita. Datos en
## `data/hallucinations.json`. Pruebas: `san=5` (cordura baja) y `halluc=fantasma|gema|hud` (solo
## esa, cada 2 s).

const DATA := "res://data/hallucinations.json"
const THRESHOLD := 0.3

var game: Node
var _cfg := {}
var _next := {}                                ## índice del jugador -> s hasta la siguiente
var _items: Array = []                         ## [{kind, node, owner, t, life, ...}]
var _gem_mesh: Mesh
var _gem_mat: Material
var _only := ""

func setup(p_game: Node) -> Hallucinations:
	game = p_game
	name = "Hallucinations"
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	_cfg = d if d is Dictionary else {}
	var a = game.get("args")
	if a != null: _only = a.get_str("halluc", "")
	return self

static func enabled() -> bool:
	return bool(Auto.setting("hallucinations", true))

## Cuánto alucina (0: nada; 1: en crisis o a cero).
static func strength(sanity_frac: float) -> float:
	return clampf(1.0 - sanity_frac / THRESHOLD, 0.0, 1.0)

func _players() -> Array:
	var ps = game.get("players")
	return ps if ps is Array else []

func _process(delta: float) -> void:
	_items_step(delta)
	if not enabled() and _only == "": return
	if get_tree().paused: return
	for q: Player in _players():
		if q.remote or q.health <= 0.0: continue
		var k := strength(q.sanity / maxf(q.data.max_sanity, 1.0))
		if k <= 0.0 and _only == "":
			_next.erase(q.index)
			continue
		if not _next.has(q.index): _next[q.index] = randf_range(1.0, 3.0)
		_next[q.index] = float(_next[q.index]) - delta
		if float(_next[q.index]) > 0.0: continue
		var every: Array = _cfg.get("every", [12.0, 3.0])
		_next[q.index] = 2.0 if _only != "" else lerpf(float(every[0]), float(every[1]), k) * randf_range(0.7, 1.3)
		_spawn(q, _pick())

func _pick() -> String:
	if _only != "": return {"fantasma": "phantom", "gema": "gem", "hud": "hud"}.get(_only, "phantom")
	var w: Dictionary = _cfg.get("weights", {"phantom": 5, "gem": 3, "hud": 2})
	var total := 0.0
	for k in w: total += float(w[k])
	var r := randf() * total
	for k in w:
		r -= float(w[k])
		if r <= 0.0: return k
	return "phantom"

func _spawn(q: Player, kind: String) -> void:
	match kind:
		"phantom": _phantom(q)
		"gem": _gem(q)
		"hud": _hud(q)

# ---------------------------------------------------------------- criaturas que no están

func _phantom(q: Player) -> void:
	var mine := 0
	for it: Dictionary in _items:
		if it.kind == "phantom" and it.owner == q: mine += 1
	if mine >= int(_cfg.get("max_phantoms", 3)): return
	var dir: WaveDirector = game.get("director")
	if dir == null: return
	var pool: Array = []                             # copias de las que hay (sin las grandes)
	for e in dir.alive:
		if is_instance_valid(e) and not e.data.unique and e.model_scale <= 1.5 and e.data.attack == null:
			pool.append(e)
	if pool.is_empty():
		for e in dir.alive:
			if is_instance_valid(e) and not e.data.unique and e.model_scale <= 1.5: pool.append(e)
	if pool.is_empty(): return
	var src: Enemy = pool.pick_random()
	var a := randf() * TAU
	var dist := randf_range(5.5, 8.0)
	var pos := q.global_position + Vector3(cos(a), 0, sin(a)) * dist
	var w: CombatWorld = game.get("world")
	if w != null and w.obstacles != null and w.obstacles.is_blocked(Vector2(pos.x, pos.z), 0.5): return   # dentro del decorado, no
	var root := Node3D.new()
	root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(root)
	root.global_position = Vector3(pos.x, 0.0, pos.z)
	root.scale = Vector3.ONE * src.model_scale
	var model := VoxelBuilder.load_model("res://models/%s.json" % src.model_name)
	root.add_child(model)
	if _players().size() > 1:                         # cooperativo: un leve tinte del que alucina
		var over := StandardMaterial3D.new()
		over.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		over.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		over.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		over.albedo_color = Color(q.color.r, q.color.g, q.color.b, float(_cfg.get("tint", 0.22)))
		for mi: MeshInstance3D in model.get_meta("meshes", []):
			mi.material_overlay = over
	var life := randf_range(6.0, 10.0)
	var speed := float(_cfg.get("phantom_speed", 2.4)) * randf_range(0.8, 1.15)
	_items.append({"kind": "phantom", "node": root, "model": model, "name": src.model_name, "owner": q,
		"t": 0.0, "life": life, "speed": speed, "anim_t": randf()})

func _phantom_step(it: Dictionary, delta: float) -> bool:
	var root: Node3D = it.node
	var q: Player = it.owner
	if not is_instance_valid(q): return false
	var to := q.global_position - root.global_position
	to.y = 0.0
	var d := to.length()
	if d < 0.9 + q.data.hurt_radius:                  # al tocarlo, niebla
		return false
	if d > 0.01:
		var step := to / d * float(it.speed) * delta
		root.global_position += step
		root.rotation.y = atan2(to.x, to.z)
	it.anim_t = fposmod(float(it.anim_t) + delta / Anims.duration(String(it.name), "walk"), 1.0)
	Anims.pose(String(it.name), "walk", it.model, it.anim_t)
	return float(it.t) < float(it.life)

# ---------------------------------------------------------------- gemas que no están

func _gem(q: Player) -> void:
	var gems = game.get("gems")
	if gems == null: return
	if _gem_mesh == null:
		_gem_mesh = gems._gem_mesh()
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://scripts/progression/gem.gdshader")
		mat.set_shader_parameter("srgb", VoxelBuilder.colors_are_srgb())
		_gem_mat = mat
	var n := randi_range(2, 4)
	var a := randf() * TAU
	var center := q.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(2.5, 4.5)
	for i in n:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _gem_mesh
		mm.instance_count = 1
		var col: Color = GemManager.TIER_COLORS[randi_range(0, mini(1, GemManager.TIER_COLORS.size() - 1))]
		mm.set_instance_transform(0, Transform3D.IDENTITY)   # sin ella, a cero: no se ve
		mm.set_instance_color(0, col)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = _gem_mat
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(mmi)
		mmi.global_position = center + Vector3(randf_range(-0.8, 0.8), 0.3, randf_range(-0.8, 0.8))
		_items.append({"kind": "gem", "node": mmi, "owner": q, "t": 0.0, "life": randf_range(8.0, 12.0), "spin": randf() * TAU})

func _gem_step(it: Dictionary, delta: float) -> bool:
	var node: Node3D = it.node
	var q: Player = it.owner
	it.spin = float(it.spin) + delta * 2.5
	node.basis = Basis(Vector3.UP, float(it.spin))
	node.position.y = 0.3 + sin(float(it.t) * 3.0) * 0.05
	if is_instance_valid(q):
		var off := q.global_position - node.global_position
		off.y = 0.0
		if off.length() < 1.6: return false               # al ir a cogerla, ya no está
	return float(it.t) < float(it.life)

# ---------------------------------------------------------------- el HUD que miente

func _hud(q: Player) -> void:
	var fake := Vector2(-1, -1)
	if randf() < 0.5: fake.x = randf_range(0.05, 0.15) if randf() < 0.7 else 1.0
	else: fake.y = randf_range(0.0, 0.08) if randf() < 0.6 else 1.0
	q.hud_lie = fake
	_items.append({"kind": "hud", "node": null, "owner": q, "t": 0.0, "life": randf_range(0.9, 1.6)})

# ---------------------------------------------------------------- vida de cada una

func _items_step(delta: float) -> void:
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		it.t = float(it.t) + delta
		var keep := true
		match String(it.kind):
			"phantom": keep = _phantom_step(it, delta)
			"gem": keep = _gem_step(it, delta)
			"hud": keep = float(it.t) < float(it.life)
		if not keep:
			_items.remove_at(i)
			_vanish(it)

func _vanish(it: Dictionary) -> void:
	if it.kind == "hud":
		if is_instance_valid(it.owner): (it.owner as Player).hud_lie = Vector2(-1, -1)
		return
	var node: Node3D = it.node
	if not is_instance_valid(node): return
	var fx = game.get("world")
	var parent: Node = fx.fx if fx != null else self
	VoxelFx.puff(parent, node.global_position + Vector3(0, 0.6, 0), "pet_mist", 0.8 if it.kind == "phantom" else 0.3,
		Color(0.62, 0.58, 0.72))
	if it.kind == "phantom": Auto.sfx_at("rise_fog", node.global_position)
	node.queue_free()

## Lo que hay ahora (tests y capturas): cuántas de cada tipo.
func count(kind: String) -> int:
	var n := 0
	for it: Dictionary in _items:
		if it.kind == kind: n += 1
	return n
