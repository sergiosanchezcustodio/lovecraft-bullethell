class_name WaveDirector
extends Node
## Dirige las oleadas de un nivel: hace aparecer enemigos fuera de cámara al ritmo
## marcado, elegidos por peso 2^(N - t) y con tope de vivos y de élites; lanza el evento
## final y da el nivel por superado cuando muere su enemigo.

signal enemy_spawned(e: Enemy)
signal final_event(e: Enemy)
signal mid_event(e: Enemy, text: String)
signal boss_event(e: Enemy, text: String)
signal level_completed
signal chest_spawned(chest: ArcaneChest)

var level: LevelData
var world: CombatWorld
var obstacles: ObstacleMap
var camera: GameCamera
var enemies_root: Node3D
var time := 0.0
var alive: Array[Enemy] = []
var spawned_total := 0
var killed_total := 0
var rng := RandomNumberGenerator.new()
var max_alive_override := -1
var players := 1                           ## jugadores: escala vida y aparición (GDD 4.6)
## Depuración (menú de pausa > Depuración):
var target_alive := -1                     ## > 0: mantiene exactamente tantos enemigos vivos
var spawning_paused := false               ## no aparece nadie (el evento final tampoco)
var pool_override: Array[EnemyData] = []   ## no vacío: solo aparecen estos, con el mismo peso
var _acc := 0.0
var _final: Enemy
var _final_done := false
var _mid_done := 0                          ## eventos intermedios ya lanzados
var mid_alive: Array[Enemy] = []            ## minijefes intermedios vivos (HUD)
var completed := false
var _chest_t := -1.0                       ## s hasta el próximo baúl arcano

func setup(p_level: LevelData, p_world: CombatWorld, p_obstacles: ObstacleMap, p_camera: GameCamera, p_root: Node3D) -> WaveDirector:
	level = p_level; world = p_world; obstacles = p_obstacles; camera = p_camera; enemies_root = p_root
	name = "WaveDirector"
	return self

func max_alive() -> int:
	if max_alive_override > 0: return max_alive_override
	return int(round(level.max_alive * LevelData.coop(level.coop_spawn, players)))

func _physics_process(delta: float) -> void:
	if completed: return
	time += delta
	_chest_step(delta)
	if spawning_paused: return
	if target_alive > 0:
		_keep_alive(delta)
		return
	_mid_step()
	if level.is_survival():
		if _survival_step(delta): return
	elif not _final_done and level.final_enemy != null and time >= level.final_time:
		_final_done = true
		_final = spawn(level.final_enemy, spawn_point(level.final_enemy.body_radius))
		for i in level.final_wave:
			var d := pick()
			if d != null: spawn(d, spawn_point(d.body_radius))
		final_event.emit(_final)
	var scale := level.final_spawn_scale if _final_done else 1.0
	if _boss_on: scale *= BOSS_SPAWN_SCALE         # con el jefe en pantalla, las oleadas casi paran
	_acc += level.rate_at(time) * scale * LevelData.coop(level.coop_spawn, players) * delta
	while _acc >= 1.0:
		if alive.size() + _emerging >= max_alive():
			_acc = 1.0
			break
		_acc -= 1.0
		var d := pick()
		if d == null: break
		if d.emerge and _emerge(d): continue
		spawn(d, spawn_point(d.body_radius))

## Evento de supervivencia (hito 6.3): de final_time a final_time + final_survive llega la
## horda a su ritmo; al acabar, nivel superado. Devuelve true mientras dura (sustituye a las
## oleadas normales).
func _survival_step(delta: float) -> bool:
	if time < level.final_time: return false
	if not _final_done:
		_final_done = true
		_acc = 0.0
		spawn_chest()                                   # un baúl para aguantar la horda
		final_event.emit(null)
	if time >= level.final_time + level.final_survive:
		if not completed:
			completed = true
			level_completed.emit()
		return true
	var cap := level.final_cap if level.final_cap > 0 else max_alive()
	cap = int(round(cap * LevelData.coop(level.coop_spawn, players)))
	_acc += level.final_rate * LevelData.coop(level.coop_spawn, players) * delta
	while _acc >= 1.0:
		if alive.size() >= cap:
			_acc = 1.0
			break
		_acc -= 1.0
		var d := _pick_final()
		if d == null: break
		spawn(d, spawn_point(d.body_radius))
	return true

func _pick_final() -> EnemyData:
	if level.final_pool.is_empty(): return pick()
	return level.final_pool[rng.randi() % level.final_pool.size()]

## Segundos que quedan de la horda (0 si no hay o no ha empezado).
func survive_left() -> float:
	if not level.is_survival() or time < level.final_time: return 0.0
	return maxf(0.0, level.final_time + level.final_survive - time)

## Baúles arcanos (D-31): uno cada `chest_every` s (±25 %), como mucho `chest_max` cerrados,
## en un sitio libre a 6-12 m de un jugador en pie.
func _chest_step(delta: float) -> void:
	if level.chest_every <= 0.0: return
	if _chest_t < 0.0: _chest_t = level.chest_every * rng.randf_range(0.75, 1.25)
	_chest_t -= delta
	if _chest_t > 0.0: return
	_chest_t = level.chest_every * rng.randf_range(0.75, 1.25)
	if get_tree().get_nodes_in_group(&"chests").filter(func(c: Node) -> bool: return not c.is_open).size() >= level.chest_max: return
	spawn_chest()

func spawn_chest() -> ArcaneChest:
	var alive := world.players.filter(func(p: Player) -> bool: return p.health > 0.0)
	var center: Vector3 = alive[rng.randi() % alive.size()].global_position if not alive.is_empty() else Vector3.ZERO
	var pos := center
	for i in 24:
		var a := rng.randf() * TAU
		var c := center + Vector3(cos(a), 0, sin(a)) * rng.randf_range(6.0, 12.0)
		var p2 := Vector2(c.x, c.z)
		if obstacles != null and (not obstacles.bounds.grow(-2.0).has_point(p2) or obstacles.is_blocked(p2, 0.9)): continue
		pos = c
		break
	var chest := ArcaneChest.new().setup(world, pos, rng.randi_range(level.chest_money.x, level.chest_money.y), level.chest_heal)
	world.fx.add_child(chest)
	chest_spawned.emit(chest)
	return chest

## Depuración: repone enemigos deprisa hasta tener `target_alive` vivos.
func _keep_alive(delta: float) -> void:
	_acc += maxf(target_alive / 2.0, 15.0) * delta
	while _acc >= 1.0 and alive.size() < target_alive:
		_acc -= 1.0
		var d := pick()
		if d == null: break
		spawn(d, spawn_point(d.body_radius))
	_acc = minf(_acc, 1.0)

## Eventos intermedios (hito 6.5): cada minijefe a su segundo, una sola vez.
func _mid_step() -> void:
	while _mid_done < level.mid_enemies.size() and _mid_done < level.mid_times.size() and time >= level.mid_times[_mid_done]:
		var d := level.mid_enemies[_mid_done]
		var text := level.mid_texts[_mid_done] if _mid_done < level.mid_texts.size() else ""
		_mid_done += 1
		var e := spawn(d, spawn_point(d.body_radius))
		mid_alive.append(e)
		e.died.connect(func(x: Enemy) -> void: mid_alive.erase(x))
		mid_event.emit(e, text)

## El enemigo que hay que matar ahora para superar el nivel (el final, o el jefe tras él).
func final_target() -> Enemy:
	return _final if is_instance_valid(_final) and _final.is_alive() else null

## Lanza ya el evento final (depuración).
func trigger_final() -> void:
	if level.is_survival():
		time = maxf(time, level.final_time)
		return
	if _final_done or level.final_enemy == null: return
	time = maxf(time, level.final_time)
	_final_done = true
	_final = spawn(level.final_enemy, spawn_point(level.final_enemy.body_radius))
	final_event.emit(_final)

## Elige un enemigo del grupo por peso, respetando el tope de élites.
func pick() -> EnemyData:
	if not pool_override.is_empty():
		return pool_override[rng.randi_range(0, pool_override.size() - 1)]
	var elites := alive.filter(func(e: Enemy) -> bool: return e.data.tier >= 4).size()
	var total := 0.0
	var cands: Array[EnemyData] = []
	var weights: Array[float] = []
	for d in level.pool:
		if d.tier >= 4 and elites >= level.elite_cap: continue
		if d.unique: continue                       # seres únicos (D-04): solo como evento
		var w := LevelData.weight(d.tier, level.number) * d.spawn_weight
		if w <= 0.0: continue
		cands.append(d)
		weights.append(w)
		total += w
	if cands.is_empty(): return null
	var r := rng.randf() * total
	for i in cands.size():
		r -= weights[i]
		if r <= 0.0: return cands[i]
	return cands[cands.size() - 1]

var _emerging := 0
var _boss_on := false
const BOSS_SPAWN_SCALE := 0.5          ## sobre final_spawn_scale (0,3): un 15 % del ritmo con el jefe
const EMERGE_WARN := 0.9          ## s de aviso antes de salir del agua

## Sale del agua (hito 6.4): en una poza a 5-9 m de un jugador en pie, con un aro en el
## suelo y un estallido de agua. false si no hay agua cerca (aparece como siempre).
func _emerge(d: EnemyData) -> bool:
	if obstacles == null or not obstacles.has_water() or world == null: return false
	var standing := world.players.filter(func(p: Player) -> bool: return p.health > 0.0)
	if standing.is_empty(): return false
	var who: Player = standing[rng.randi() % standing.size()]
	var w := obstacles.random_water(rng, Vector2(who.global_position.x, who.global_position.z), 5.0, 9.0, d.body_radius)
	if w == Vector2.INF: return false
	var pos := Vector3(w.x, 0, w.y)
	var tg := Telegraph.new().setup(d.body_radius + 0.5, EMERGE_WARN, Color(0.35, 0.75, 0.85, 0.7), false)
	tg.position = pos
	world.fx.add_child(tg)
	_emerging += 1                     # cuenta para el tope mientras sale
	tg.finished.connect(func() -> void:
		_emerging -= 1
		if completed: return
		WadeSplash.burst(world.fx, pos)
		spawn(d, pos))
	return true

## Punto de aparición fuera de cámara, dentro de la arena y lejos de obstáculos.
func spawn_point(radius: float) -> Vector3:
	var center := camera.center() if camera != null else Vector3.ZERO
	var half_h := (camera.view_size if camera != null else 15.0) / sin(deg_to_rad(30.0)) * 0.5
	var half_w := (camera.view_size if camera != null else 15.0) * 16.0 / 9.0 * 0.5
	var ring := sqrt(half_h * half_h + half_w * half_w) * 0.75 + 2.0
	for attempt in 30:
		var a := rng.randf() * TAU
		var p := Vector2(center.x, center.z) + Vector2(cos(a), sin(a)) * rng.randf_range(ring, ring + 5.0)
		if obstacles == null or not obstacles.is_blocked(p, radius + 0.2):
			return Vector3(p.x, 0, p.y)
	# arena pequeña respecto a la cámara: cualquier punto libre
	for attempt in 60:
		var b := obstacles.bounds.grow(-2.0) if obstacles != null else Rect2(-30, -30, 60, 60)
		var p := Vector2(rng.randf_range(b.position.x, b.end.x), rng.randf_range(b.position.y, b.end.y))
		if (obstacles == null or not obstacles.is_blocked(p, radius + 0.2)) and p.distance_to(Vector2(center.x, center.z)) > 6.0:
			return Vector3(p.x, 0, p.y)
	return Vector3(center.x + 20.0, 0, center.z)

func spawn(d: EnemyData, pos: Vector3) -> Enemy:
	var e := Enemy.new().setup(d, world, obstacles)
	e.health_scale = LevelData.coop(level.coop_health, players)     # más jugadores, más aguante
	if d.unique: e.health_scale = 1.0 + (e.health_scale - 1.0) * 0.5   # los únicos, la mitad (con 4: ×1,65)
	e.health_scale *= level.health_mult
	e.health *= e.health_scale
	e.position = pos
	e.died.connect(_on_died)
	enemies_root.add_child(e)
	alive.append(e)
	spawned_total += 1
	enemy_spawned.emit(e)
	return e

func _on_died(e: Enemy) -> void:
	alive.erase(e)
	killed_total += 1
	if e == _final and not completed:
		if level.final_next != null and _final.data != level.final_next:   # tras el final, el jefe
			_final = spawn(level.final_next, spawn_point(level.final_next.body_radius))
			_boss_on = true
			boss_event.emit(_final, level.final_next_text)
			return
		completed = true
		level_completed.emit()
