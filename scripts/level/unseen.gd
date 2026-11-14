class_name Unseen
extends Node
## Lo que no se ve (hito 21.14, «El horror de Dunwich»):
## - Huellas: cada enemigo con `unseen` que no se ve (el modelo escondido) deja un hoyo redondo cada
##   `print_step` m, a un lado y a otro, con un golpe sordo, un temblor de cámara cerca y lo que pisa se
##   rompe (DecorBreak.blast, en el anfitrión). Las hace cada PC con lo que ve (también con las
##   marionetas del invitado), así que no viajan por la red.
## - El polvo de Ibn Ghazi: pulverizadores de latón que aparecen cerca de los jugadores cada
##   `LevelData.powder_every` s (más a menudo con el jefe vivo, `powder_final_every`). Quien pasa por
##   encima lo suelta en una nube de `powder_radius` m: lo que no es de este mundo que hay dentro se
##   descubre `powder_reveal` s (Enemy.reveal: lo oculto sale y recibe un 25 % más de daño; los humanos,
##   no). Armitage, que lo preparó en el relato, lo suelta más lejos y le dura más (×1,5).
## - Los chotacabras (`soul_eater`) se llevan a los caídos: cada uno a menos de SOUL_R m de un caído
##   hace que su tiempo corra un 60 % más deprisa (Player.down_haste, hasta el triple); si se le acaba
##   con ellos alrededor, se llevan su alma (un grito y una luz que sube).
## En red, los pulverizadores y quién los recoge los decide el anfitrión (suceso "powder"); las huellas
## y lo de los caídos, cada PC con sus jugadores.

const PRINT_STEP := 1.5                ## m entre huellas, si el enemigo no dice otra cosa
const PRINT_LIFE := 14.0
const MAX_PRINTS := 64
const TICK := 0.25
const PICK_R := 1.0                    ## m para recoger un pulverizador
const SOUL_R := 2.2
const SOUL_HASTE := 0.6
const SOUL_MAX := 2.0
const ARMITAGE := 1.5
const VULN := 0.25
const POWDER := Color(0.95, 0.88, 0.62)
const PRINT_DUST := Color(0.3, 0.28, 0.22)
const BOLT := Color(0.85, 0.9, 1.0)

static var current: Unseen

var world: CombatWorld
var level: LevelData
var host := true
var game: Node                         ## para la red (su `net_game`, que se crea después)
var sprayers: Array[Dictionary] = []   ## {id, pos: Vector2, age, node}
var prints: Array[Dictionary] = []     ## {pos: Vector2, r, age, seed}
var sprays := 0                        ## veces que se ha soltado el polvo (tests)
var souls_taken := 0                   ## almas que se han llevado los chotacabras (tests)
var bolts := 0                         ## rayos del final (tests)
var _next := 0.0
var _id := 0
var _tick := 0.0
var _fx_t := 0.0
var _tracks := {}                      ## Enemy -> [Vector2 de la última huella, lado]
var _downed := {}                      ## Player -> estaba caído en el último tic
var _mm: MultiMeshInstance3D
var _rng := RandomNumberGenerator.new()

func setup(p_world: CombatWorld, p_level: LevelData, p_host: bool, p_game: Node = null) -> Unseen:
	name = "Unseen"
	world = p_world; level = p_level; host = p_host; game = p_game
	_next = (level.powder_every if level != null else 0.0) * 0.6
	_rng.randomize()
	current = self
	return self

func _exit_tree() -> void:
	if current == self: current = null

## s hasta el próximo pulverizador: más a menudo con lo invisible suelto.
func every() -> float:
	if level == null: return 0.0
	if level.powder_final_every > 0.0 and unseen_alive(): return level.powder_final_every
	return level.powder_every

func unseen_alive() -> bool:
	for e in world.enemies:
		if e is Enemy and is_instance_valid(e) and e.is_alive() and bool((e as Enemy).data.param("unseen", false)): return true
	return false

func _physics_process(delta: float) -> void:
	for s in sprayers: s.age = float(s.age) + delta
	var life := level.powder_life if level != null else 30.0
	if host:
		var ev := every()
		if ev > 0.0:
			_next -= delta
			if _next <= 0.0:
				_next = ev * _rng.randf_range(0.8, 1.2)
				if sprayers.size() < (level.powder_max if level != null else 2): _spawn_near_players()
		for s in sprayers.duplicate():
			if float(s.age) > life:
				_remove(s)
				continue
			for q in world.players:
				if q.health <= 0.0: continue
				if Vector2(q.global_position.x, q.global_position.z).distance_to(s.pos) < PICK_R:
					use(s, q)
					break
	else:
		for s in sprayers.duplicate():                # el invitado los quita solo al acabarse
			if float(s.age) > life + 1.0: _remove(s)
	_tick -= delta
	if _tick > 0.0: return
	_tick = TICK
	_souls()

# ------------------------------------------------------------------ el polvo de Ibn Ghazi

## Un pulverizador nuevo cerca de un jugador al azar, en un sitio por donde se pasa (anfitrión).
func _spawn_near_players() -> void:
	var alive := world.players.filter(func(q: Player) -> bool: return q.health > 0.0)
	if alive.is_empty(): return
	var q: Player = alive[_rng.randi() % alive.size()]
	var b := world.bounds.grow(-3.0)
	for i in 12:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(4.0, 9.0)
		var at := Vector2(q.global_position.x + cos(a) * d, q.global_position.z + sin(a) * d)
		at = Vector2(clampf(at.x, b.position.x, b.end.x), clampf(at.y, b.position.y, b.end.y))
		if world.obstacles != null and world.obstacles.is_blocked(at, 0.8): continue
		spawn_at(at)
		return

## Pone un pulverizador en `at` y lo cuenta a los invitados (anfitrión; también para las pruebas).
func spawn_at(at: Vector2) -> void:
	if not host: return
	_id += 1
	_add(_id, at)
	_net({"a": "add", "id": _id, "x": snappedf(at.x, 0.01), "z": snappedf(at.y, 0.01)})

func _add(id: int, at: Vector2) -> void:
	var node := Node3D.new()
	node.name = "Pulverizador"
	node.position = Vector3(at.x, 0.0, at.y)
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	node.add_to_group(&"pickups")                      # los bots van a por él (SmartBot)
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * 1.35
	holder.rotation.y = _rng.randf() * TAU
	holder.add_child(VoxelBuilder.load_model("res://models/dun_pulverizador.json"))
	node.add_child(holder)
	var ring := MeshInstance3D.new()                   # anillo en el suelo para verlo de lejos
	var tm := TorusMesh.new()
	tm.inner_radius = 0.6; tm.outer_radius = 0.7
	ring.mesh = tm
	var m := VoxelFx.std()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = POWDER
	ring.material_override = m
	ring.position.y = 0.04
	ring.scale = Vector3(1, 0.2, 1)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(ring)
	world.fx.add_child(node)
	sprayers.append({"id": id, "pos": at, "age": 0.0, "node": node})
	VoxelFx.puff(world.fx, Vector3(at.x, 0.3, at.y), "sparkle", 0.5, POWDER)

func _remove(s: Dictionary) -> void:
	sprayers.erase(s)
	var n: Node = s.get("node")
	if is_instance_valid(n): n.queue_free()

## `q` pisa el pulverizador `s` (anfitrión): lo suelta y descubre lo que hay en la nube.
func use(s: Dictionary, q: Player) -> void:
	var r := level.powder_radius if level != null else 8.0
	var t := level.powder_reveal if level != null else 7.0
	if q != null and q.data != null and q.data.id == &"armitage":
		r *= ARMITAGE
		t *= ARMITAGE
	_net({"a": "use", "id": int(s.id), "r": snappedf(r, 0.1), "p": q.index if q != null else -1})
	_remove(s)
	_spray(s.pos, r, q)
	for e in world.enemies:
		if not (e is Enemy) or not is_instance_valid(e) or not e.is_alive(): continue
		var en := e as Enemy
		if en.data.tags.has(&"humana"): continue                 # las devotas son de este mundo
		if Vector2(en.global_position.x, en.global_position.z).distance_to(s.pos) > r: continue
		en.reveal(t, VULN)

## La nube de polvo (en todos los PC).
func _spray(at: Vector2, r: float, q: Player) -> void:
	sprays += 1
	var p := Vector3(at.x, 0.0, at.y)
	Auto.sfx_at("powder_spray", p)
	VoxelFx.puff(world.fx, p + Vector3(0, 1.0, 0), "sparkle", r * 0.3, POWDER, 2.2)
	for i in 10:
		var a := float(i) / 10.0 * TAU
		VoxelFx.puff(world.fx, p + Vector3(cos(a) * r * 0.7, 0.6, sin(a) * r * 0.7), "dust", 0.9, POWDER, 1.6)
	if q != null and not q.remote:
		world._shout("El polvo de Ibn Ghazi", q.global_position + Vector3(0, 2.4, 0), POWDER, 60, 1.0, 1.6)

## Invitado: lo que decidió el anfitrión.
func remote(d: Dictionary) -> void:
	match String(d.get("a", "")):
		"add": _add(int(d.get("id", 0)), Vector2(float(d.get("x", 0.0)), float(d.get("z", 0.0))))
		"bolt": bolt(Vector3(float(d.get("x", 0.0)), 0.0, float(d.get("z", 0.0))))
		"use":
			for s in sprayers:
				if int(s.id) != int(d.get("id", -1)): continue
				_remove(s)
				var by: Player = null
				for q in world.players:
					if q.index == int(d.get("p", -1)): by = q
				_spray(s.pos, float(d.get("r", 8.0)), by)
				return

## El rayo que cae sobre lo que no se ve al morir (HorrorBehavior): el destello del clima y un rayo de
## tramos que zigzaguean del cielo al suelo. El anfitrión lo cuenta a los invitados.
func bolt(at: Vector3) -> void:
	bolts += 1
	if host: _net({"a": "bolt", "x": snappedf(at.x, 0.01), "z": snappedf(at.z, 0.01)})
	var w: Variant = game.get("weather") if game != null else null
	if w is Weather: (w as Weather).strike_now()
	var m := VoxelFx.std()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(BOLT, 0.95)
	var node := Node3D.new()
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var p := at + Vector3(_rng.randf_range(-1.5, 1.5), 32.0, _rng.randf_range(-1.5, 1.5))
	for i in 10:
		var q := at + Vector3(_rng.randf_range(-1.2, 1.2), 32.0 * (1.0 - float(i + 1) / 10.0), _rng.randf_range(-1.2, 1.2))
		if i == 9: q = at
		var seg := MeshInstance3D.new()
		seg.mesh = VoxelFx.box1()                      # de tamaño variable: el tamaño, en la escala
		seg.material_override = m
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seg.position = (p + q) * 0.5
		var up := (p - q).normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		seg.basis = Basis(side, up, side.cross(up)).orthonormalized() * Basis.from_scale(Vector3(0.35, p.distance_to(q), 0.35))
		node.add_child(seg)
		p = q
	world.fx.add_child(node)
	var tw := node.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.7).set_delay(0.15)
	tw.tween_callback(node.queue_free)
	VoxelFx.ground_hit(world.fx, at, 3.0, Color(0.1, 0.1, 0.12))

func _net(d: Dictionary) -> void:
	var net: Variant = game.get("net_game") if game != null else null
	if net is NetGame:
		d["k"] = "powder"
		(net as NetGame)._event(d)

# ------------------------------------------------------------------ los chotacabras y los caídos

## ¿Ningún chotacabras ha tocado a nadie de este PC? (los bots no cuentan): el logro «Ningún alma
## para los chotacabras».
func birds_untouched() -> bool:
	for q in world.players:
		if q.remote or q.input is BotInput: continue
		for src: String in q.received.keys():
			var ed: EnemyData = _soul_eaters.get(src)
			if ed != null: return false
	return true

var _soul_eaters := {}                 ## id -> EnemyData de los que se llevan almas (los que han salido)

func _souls() -> void:
	var eaters: Array[Node3D] = []
	for e in world.enemies:
		if e is Enemy and is_instance_valid(e) and e.is_alive() and bool((e as Enemy).data.param("soul_eater", false)):
			eaters.append(e)
			_soul_eaters[String((e as Enemy).data.id)] = (e as Enemy).data
	for q in world.players:
		var was: bool = _downed.get(q, false)
		var down := q.is_downed()
		var n := 0
		if down or (was and q.is_eliminated):
			for e in eaters:
				if Vector2(e.global_position.x - q.global_position.x, e.global_position.z - q.global_position.z).length() < SOUL_R: n += 1
		if not q.remote: q.down_haste = minf(n * SOUL_HASTE, SOUL_MAX) if down else 0.0
		if was and q.is_eliminated and n > 0: _taken(q)
		_downed[q] = down

## Se acabó el tiempo de un caído con los chotacabras alrededor: se llevan su alma.
func _taken(q: Player) -> void:
	souls_taken += 1
	var at := q.global_position
	world._shout("Los chotacabras se llevan su alma", at + Vector3(0, 2.6, 0), Color(0.82, 0.86, 1.0), 64, 1.6, 2.4)
	Auto.sfx_at("whippoorwill", at)
	for i in 6:
		VoxelFx.puff(world.fx, at + Vector3(0, 0.8 + i * 0.9, 0), "sparkle", 0.4, Color(0.8, 0.86, 1.0), 1.4 + i * 0.2)

# ------------------------------------------------------------------ huellas

func _process(delta: float) -> void:
	for p in prints: p.age = float(p.age) + delta
	if not prints.is_empty() and float(prints[0].age) > PRINT_LIFE:
		prints.assign(prints.filter(func(p: Dictionary) -> bool: return float(p.age) < PRINT_LIFE))
	for e in world.enemies:
		if not (e is Enemy) or not is_instance_valid(e) or not e.is_alive(): continue
		var en := e as Enemy
		if not bool(en.data.param("unseen", false)): continue
		var at := Vector2(en.global_position.x, en.global_position.z)
		var tr: Array = _tracks.get(en, [])
		if tr.is_empty() or (en.visual != null and en.visual.visible):   # se ve: sin huellas, pero sigue la cuenta
			_tracks[en] = [at, 1.0 if tr.is_empty() else float(tr[1])]
			continue
		var last: Vector2 = tr[0]
		var mv := at - last
		var step := float(en.data.param("print_step", PRINT_STEP))
		if mv.length() < step: continue
		var side: float = tr[1]
		var perp := Vector2(-mv.y, mv.x).normalized() * float(en.data.param("print_side", 0.9)) * side
		var spot := last + mv * 0.5 + perp
		add_print(spot, float(en.data.param("print_size", 0.6)))
		_tracks[en] = [at, -side]
		_step_fx(Vector3(spot.x, 0.0, spot.y))
	for s in sprayers:                                 # el polvo brilla un poco
		var n: Node3D = s.get("node")
		if is_instance_valid(n): n.get_child(1).scale = Vector3.ONE * (1.0 + 0.08 * sin(float(s.age) * 4.0)) * Vector3(1, 0.2, 1)
	_fx_t -= delta
	if _fx_t <= 0.0 and not sprayers.is_empty():
		_fx_t = 0.8
		var s: Dictionary = sprayers[_rng.randi() % sprayers.size()]
		VoxelFx.puff(world.fx, Vector3(s.pos.x, 0.7, s.pos.y), "sparkle", 0.25, POWDER, 1.0)
	_draw()

func add_print(at: Vector2, r: float) -> void:
	if prints.size() >= MAX_PRINTS: prints.pop_front()
	prints.append({"pos": at, "r": r, "age": 0.0, "seed": _rng.randi() % 997})

## El paso: un golpe sordo, polvo, un temblor si está cerca de alguien de este PC y lo que pisa se rompe.
func _step_fx(at: Vector3) -> void:
	var near := INF
	for q in world.players:
		if not q.remote: near = minf(near, q.global_position.distance_to(at))
	if near < 22.0:
		Auto.sfx_at("horror_step", at)
		var cam := get_viewport().get_camera_3d() as GameCamera if is_inside_tree() else null
		if cam != null: cam.shake(0.18 * clampf(1.0 - near / 22.0, 0.15, 1.0))
	VoxelFx.puff(world.fx, at + Vector3(0, 0.1, 0), "dust", 0.6, PRINT_DUST, 1.0)
	if host: DecorBreak.blast(at, 1.4)

func _draw() -> void:
	if _mm == null: _make_mesh()
	var mm := _mm.multimesh
	var n := 0
	for p in prints:
		if n >= MAX_PRINTS: break
		var r := float(p.r) * 1.35
		var b := Basis.IDENTITY.scaled(Vector3(r * 2.0, 1.0, r * 2.0))
		mm.set_instance_transform(n, Transform3D(b, Vector3(p.pos.x, 0.035 + 0.002 * (n % 6), p.pos.y)))
		mm.set_instance_custom_data(n, Color(float(p.seed) * 0.013, float(p.r), 1.0 - float(p.age) / PRINT_LIFE, 0.0))
		n += 1
	mm.visible_instance_count = n

func _make_mesh() -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/level/unseen_print.gdshader")
	quad.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = MAX_PRINTS
	mm.visible_instance_count = 0
	_mm = MultiMeshInstance3D.new()
	_mm.name = "Huellas"
	_mm.multimesh = mm
	_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mm.custom_aabb = AABB(Vector3(-200, -2, -200), Vector3(400, 4, 400))
	_mm.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_mm)
