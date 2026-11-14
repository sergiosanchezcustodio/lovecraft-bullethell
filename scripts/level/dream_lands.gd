class_name DreamLands
extends Node
## Lo propio de cada nivel de la parte 4, *La búsqueda onírica de la desconocida Kadath* (hito 21.10;
## datos en LevelData, grupo «Las Tierras del Sueño»):
## - Nivel 1, el bosque encantado: **los gatos de Ulthar**. Cada `cats_every` s (×0,7 si alguien lleva
##   al gato de compañero) baja del pueblo una manada de `cats_count` gatos (`cats_from` en el JSON de la
##   arena; si no, el centro del borde norte) que corre a por los zoogs: el que alcanzan, cae (al anciano
##   solo le arañan). A los `cats_life` s vuelven al pueblo. **Los hongos que brillan** (`sue_hongos`)
##   devuelven `mushroom_sanity` de cordura por segundo a quien está a `mushroom_radius` m.
## - Nivel 2, el puerto de Dylath-Leen: **la galera negra** atraca cada `galley_every` s: avisa en el pie
##   de la pasarela (`galley` en el JSON) y bajan `galley_count` remeros lunares, uno tras otro. Su
##   **escotilla** (`hatch_enemy`, en `hatch`: x, z, y) es un objetivo quieto: al reventarla, la galera deja
##   de desembarcar y suelta experiencia en la pasarela. **Los rubíes**: los de `ruby_tag` (mercaderes de
##   Leng) sueltan a veces uno al caer (`Pickup.Kind.RUBY`: el doble de dólares, pero quita cordura).
## - Nivel 3, la meseta de Leng: **el viento de Leng** sopla a rachas (`gust_every`): avisa, y durante
##   `gust_time` s empuja a todos hacia un lado (al azar) a `gust_push` m/s, con más fuerza a mitad.
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
var galley_at := Vector3.INF           ## el pie de la pasarela
var hatch_at := Vector3.INF
var hatch: Enemy
var hatch_broken := false
var landings := 0                      ## desembarcos (tests)
var rubies := 0                        ## rubíes soltados (tests)
var spawner: Callable                  ## pruebas: en lugar del director, spawner.call(d, pos) -> Enemy
var _galley_next := 0.0
var _queue: Array[float] = []          ## s hasta cada remero del desembarco en curso
var gusts := 0                         ## rachas (tests)
var gust_dir := Vector3.ZERO           ## hacia dónde empuja la racha en curso
var _gust_next := 0.0
var _gust_t := -1.0                    ## s desde que empezó el aviso de la racha en curso (-1: ninguna)
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
	var g: Array = layout.get("galley", [])
	if g.size() >= 2: galley_at = Vector3(float(g[0]), 0.0, float(g[1]))
	var h: Array = layout.get("hatch", [])
	if h.size() >= 2: hatch_at = Vector3(float(h[0]), float(h[2]) if h.size() > 2 else 0.0, float(h[1]))
	_galley_next = level.galley_every * 0.5 if level != null else 0.0
	_gust_next = level.gust_every * 0.6 if level != null else 0.0
	var dir: Variant = game.get("director") if game != null else null
	if host and dir is WaveDirector and level != null and level.ruby_chance > 0.0:
		(dir as WaveDirector).enemy_spawned.connect(watch_ruby)
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
	if host: _galley_step(delta)
	_gust_step(delta)

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

# ------------------------------------------------------------------ la galera negra

func _galley_step(delta: float) -> void:
	if level.galley_every <= 0.0 or galley_at == Vector3.INF: return
	if hatch == null and not hatch_broken and level.hatch_enemy != null and hatch_at != Vector3.INF:
		place_hatch()
	for i in range(_queue.size() - 1, -1, -1):
		_queue[i] -= delta
		if _queue[i] > 0.0: continue
		_queue.remove_at(i)
		var off := Vector3(_rng.randf_range(-1.2, 1.2), 0.0, _rng.randf_range(0.0, 1.5))
		_spawn(level.galley_enemy, galley_at + off)
	if hatch_broken: return
	_galley_next -= delta
	if _galley_next <= 0.0:
		_galley_next = level.galley_every * _rng.randf_range(0.85, 1.15)
		land()

## Atraca y desembarca (en el anfitrión): el aviso en la pasarela y los remeros, uno tras otro.
func land() -> void:
	landings += 1
	var tg := Telegraph.enemy(2.4, level.galley_warn, Color(0.55, 1.0, 0.5, 0.8))
	tg.position = galley_at
	world.fx.add_child(tg)
	for i in level.galley_count: _queue.append(level.galley_warn + i * 0.55)
	_say_galley()
	_net({"a": "galley"})

func _say_galley() -> void:
	if game != null and game.has_method("announce"): game.announce("Atraca la galera negra: bajan los remeros lunares", 2.5)
	world.sfx("slam", galley_at)

## La escotilla, en su sitio de la cubierta.
func place_hatch() -> void:
	hatch = _spawn(level.hatch_enemy, hatch_at)
	if hatch == null: return
	hatch.position = hatch_at
	hatch.reset_physics_interpolation()
	hatch.died.connect(_on_hatch_died)

func _on_hatch_died(_e: Enemy) -> void:
	if hatch_broken: return
	hatch_broken = true
	_queue.clear()
	var gm: Variant = game.get("gems") if game != null else null
	if gm != null and gm.has_method("drop"):
		for i in 6: gm.drop(galley_at + Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(0.0, 2.0)), 3.0, 2)
	_say_hatch()
	_net({"a": "hatch"})

func _say_hatch() -> void:
	if game != null and game.has_method("announce"): game.announce("Revienta la escotilla: la galera ya no desembarca", 2.5)
	world.sfx("slam", hatch_at)
	world.ground_hit(Vector3(hatch_at.x, 0.0, hatch_at.z), 1.6, Color(0.45, 1.0, 0.45))

func _spawn(d: EnemyData, pos: Vector3) -> Enemy:
	if d == null: return null
	if spawner.is_valid(): return spawner.call(d, pos)
	var dir: Variant = game.get("director") if game != null else null
	if dir is WaveDirector: return (dir as WaveDirector).spawn(d, pos)
	return null

# ------------------------------------------------------------------ el viento de Leng

func _gust_step(delta: float) -> void:
	if level.gust_every <= 0.0: return
	if host and _gust_t < 0.0:
		_gust_next -= delta
		if _gust_next <= 0.0:
			_gust_next = level.gust_every * _rng.randf_range(0.85, 1.15)
			gust(_rng.randf() * TAU)
	if _gust_t < 0.0: return
	_gust_t += delta
	var t := _gust_t - level.gust_warn
	if t >= level.gust_time:
		_gust_t = -1.0
		return
	if t < 0.0: return
	var k := sin(clampf(t / level.gust_time, 0.0, 1.0) * PI)
	for q in world.players:
		if q.remote or q.health <= 0.0: continue
		q.push += gust_dir * level.gust_push * k
	if fmod(t, 0.5) < delta:
		for q in world.players: Gusts.push(world.fx, q.global_position - gust_dir * 4.0, 0.5 * k, 9.0)

## Empieza una racha hacia el ángulo `a` (en el invitado, cuando lo dice el anfitrión).
func gust(a: float) -> void:
	gusts += 1
	gust_dir = Vector3(cos(a), 0.0, sin(a))
	_gust_t = 0.0
	if game != null and game.has_method("announce"): game.announce("Se levanta el viento de Leng…", 2.0)
	var at := world.players[0].global_position if not world.players.is_empty() else Vector3.ZERO
	Auto.sfx_at("trap_wind", at)
	if host: _net({"a": "gust", "r": a})

# ------------------------------------------------------------------ los rubíes

## Vigila a un enemigo que acaba de aparecer: si es de los que llevan rubíes, puede soltar uno al caer.
func watch_ruby(e: Enemy) -> void:
	if level.ruby_chance > 0.0 and e.data.tags.has(level.ruby_tag): e.died.connect(_on_ruby_died)

func _on_ruby_died(e: Enemy) -> void:
	if _rng.randf() < level.ruby_chance: drop_ruby(e.global_position)

func drop_ruby(at: Vector3) -> Pickup:
	var p := Pickup.new().setup(world, at, Pickup.Kind.RUBY)
	world.fx.add_child(p)
	rubies += 1
	return p

# ------------------------------------------------------------------ red

func remote(d: Dictionary) -> void:
	match String(d.get("a", "")):
		"cats": release_cats(int(d.get("s", 0)))
		"galley": _say_galley()
		"gust": gust(float(d.get("r", 0.0)))
		"hatch":
			hatch_broken = true
			_say_hatch()

func _net(d: Dictionary) -> void:
	var net: Variant = game.get("net_game") if game != null else null
	if net is NetGame:
		d["k"] = "dream"
		(net as NetGame)._event(d)
