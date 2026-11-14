class_name DreamLands
extends Node
## Lo propio de cada nivel de la parte 4, *La búsqueda onírica de la desconocida Kadath* (hito 21.10;
## datos en LevelData, grupo «Las Tierras del Sueño»):
## - Nivel 1, el bosque encantado: **los gatos de Ulthar**. Cada `cats_every` s (×0,7 si alguien lleva
##   al gato de compañero) baja del pueblo una manada de `cats_count` gatos (`cats_from` en el JSON de la
##   arena; si no, el centro del borde norte) que corre a por los zoogs: el que alcanzan, cae (al anciano
##   solo le arañan). A los `cats_life` s vuelven al pueblo. **Los hongos que brillan** (`sue_hongos`)
##   devuelven `mushroom_sanity` de cordura por segundo a quien está a `mushroom_radius` m.
## En red, la manada la decide el anfitrión (suceso "dream"); los gatos cazan en todos los PC, pero solo
## el anfitrión hace daño (los enemigos son suyos).

const CAT_SPEED := 7.5
const CAT_REACH := 0.75                ## m: a esta distancia atrapa
const CAT_SCRATCH := 25.0              ## daño al anciano (o a otro único) por zarpazo
const CAT_SCRATCH_EVERY := 1.0
const CAT_SCALE := 1.0
const PET_HASTE := 0.7                 ## con el gato de compañero, la manada llega antes
const MUSHROOMS := ["sue_hongos"]

static var current: DreamLands

var world: CombatWorld
var level: LevelData
var host := true
var game: Node
var cats: Array[Dictionary] = []       ## {node, model, target, t, life, home: Vector3, scratch, ph}
var packs := 0                         ## manadas que han bajado (tests)
var caught := 0                        ## zoogs que han atrapado (tests)
var cats_from := Vector3.INF
var mushrooms: Array[Vector2] = []
var _next := 0.0
var _rng := RandomNumberGenerator.new()

func setup(p_world: CombatWorld, p_level: LevelData, p_host: bool, p_game: Node = null) -> DreamLands:
	name = "DreamLands"
	world = p_world; level = p_level; host = p_host; game = p_game
	_rng.randomize()
	current = self
	var layout := {}
	if level != null and FileAccess.file_exists(level.arena):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(level.arena))
		if j is Dictionary: layout = j
	var cf: Array = layout.get("cats_from", [])
	var half := float((layout.get("size", [64, 64]) as Array)[1]) * 0.5
	cats_from = Vector3(float(cf[0]), 0.0, float(cf[1])) if cf.size() == 2 else Vector3(0, 0, -half + 1.0)
	for p: Dictionary in layout.get("props", []):
		if String(p.model) in MUSHROOMS: mushrooms.append(Vector2(float(p.pos[0]), float(p.pos[1])))
	_next = cats_every() * 0.6
	return self

func _exit_tree() -> void:
	if current == self: current = null

## s hasta la próxima manada (0: sin gatos).
func cats_every() -> float:
	if level == null or level.cats_every <= 0.0: return 0.0
	for q in world.players:
		var pt: Variant = q.get("pet")
		if pt != null and is_instance_valid(pt) and pt.get("data") != null and String(pt.data.id) == "gato":
			return level.cats_every * PET_HASTE
	return level.cats_every

func _physics_process(delta: float) -> void:
	if world == null or level == null: return
	if host and cats_every() > 0.0:
		_next -= delta
		if _next <= 0.0:
			_next = cats_every() * _rng.randf_range(0.85, 1.15)
			release_cats(_rng.randi())
	_cats_step(delta)
	_mushroom_step(delta)

# ------------------------------------------------------------------ los gatos de Ulthar

## Baja una manada (en el invitado, cuando lo dice el anfitrión).
func release_cats(seed_v: int) -> void:
	packs += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in level.cats_count:
		var holder := Node3D.new()
		holder.name = "GatoDeUlthar"
		holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var m := VoxelBuilder.load_model("res://models/gato.json")
		m.scale = Vector3.ONE * CAT_SCALE * rng.randf_range(0.9, 1.1)
		holder.add_child(m)
		holder.position = cats_from + Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-1.0, 1.5))
		world.fx.add_child(holder)
		cats.append({"node": holder, "model": m, "target": null, "t": 0.0, "life": level.cats_life * rng.randf_range(0.9, 1.1),
			"home": holder.position, "scratch": 0.0, "ph": rng.randf()})
	if game != null and game.has_method("announce"): game.announce("Bajan los gatos de Ulthar…", 2.5)
	world.sfx("growl", cats_from)
	if host: _net({"a": "cats", "s": seed_v})

func _cats_step(delta: float) -> void:
	for c in cats.duplicate():
		var n: Node3D = c.node
		if not is_instance_valid(n):
			cats.erase(c)
			continue
		c.t += delta
		c.scratch -= delta
		var goal := Vector3.INF
		if c.t < c.life:
			var tg: Variant = c.target
			if tg == null or not is_instance_valid(tg) or not (tg as Enemy).is_alive() or (tg as Enemy).buried:
				c.target = _prey(n.position)
				tg = c.target
			if tg != null: goal = (tg as Node3D).global_position
		if goal == Vector3.INF: goal = c.home                          # vuelve al pueblo
		var to := goal - n.position
		to.y = 0.0
		var d := to.length()
		if c.t >= c.life and d < 0.6:
			n.queue_free()
			cats.erase(c)
			continue
		if d > 0.05:
			var step := minf(d, CAT_SPEED * delta)
			n.position += to / d * step
			n.rotation.y = atan2(to.x, to.z)
		Anims.pose("gato", "run" if d > 0.3 else "bite", c.model, fmod(c.t / Anims.duration("gato", "run") + c.ph, 1.0))
		if host and c.t < c.life: _catch(c, n.position)

## El zoog más cercano (los únicos, al final).
func _prey(at: Vector3) -> Enemy:
	var best: Enemy = null
	var bd := INF
	for e in world.enemies:
		if not (e is Enemy) or not is_instance_valid(e): continue
		var en := e as Enemy
		if not en.is_alive() or en.buried or not en.data.tags.has(&"zoog"): continue
		var d := at.distance_to(en.global_position) + (30.0 if en.data.unique else 0.0)
		if d < bd:
			bd = d
			best = en
	return best

func _catch(c: Dictionary, at: Vector3) -> void:
	for o in world.enemies_in_circle(at, CAT_REACH):
		if not (o is Enemy) or not o.is_alive(): continue
		var en := o as Enemy
		if not en.data.tags.has(&"zoog"): continue
		if en.data.unique:
			if c.scratch > 0.0: continue
			c.scratch = CAT_SCRATCH_EVERY
			en.take_damage(Damage.new(CAT_SCRATCH, 0.0))
			continue
		en.take_damage(Damage.new(en.health * 2.0 + 999.0, 0.0))
		caught += 1
		world.sfx("rat", at)

# ------------------------------------------------------------------ los hongos

func _mushroom_step(delta: float) -> void:
	if level.mushroom_sanity <= 0.0 or mushrooms.is_empty(): return
	for q in world.players:
		if q.remote or q.health <= 0.0: continue
		var p := Vector2(q.global_position.x, q.global_position.z)
		for m in mushrooms:
			if p.distance_to(m) <= level.mushroom_radius:
				q.sanity = minf(q.data.max_sanity, q.sanity + level.mushroom_sanity * delta)
				break

## ¿Está `q` junto a unos hongos? (el consejo y las pruebas)
func near_mushroom(at: Vector3) -> bool:
	var p := Vector2(at.x, at.z)
	for m in mushrooms:
		if p.distance_to(m) <= level.mushroom_radius: return true
	return false

# ------------------------------------------------------------------ red

func remote(d: Dictionary) -> void:
	match String(d.get("a", "")):
		"cats": release_cats(int(d.get("s", 0)))

func _net(d: Dictionary) -> void:
	var net: Variant = game.get("net_game") if game != null else null
	if net is NetGame:
		d["k"] = "dream"
		(net as NetGame)._event(d)
