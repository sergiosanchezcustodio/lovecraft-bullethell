class_name WaveDirector
extends Node
## Dirige las oleadas de un nivel: hace aparecer enemigos fuera de cámara al ritmo
## marcado, elegidos por peso 2^(N - t) y con tope de vivos y de élites; lanza el evento
## final y da el nivel por superado cuando muere su enemigo.

signal enemy_spawned(e: Enemy)
signal final_event(e: Enemy)
signal level_completed

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
var completed := false

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
	if spawning_paused: return
	if target_alive > 0:
		_keep_alive(delta)
		return
	if not _final_done and level.final_enemy != null and time >= level.final_time:
		_final_done = true
		_final = spawn(level.final_enemy, spawn_point(level.final_enemy.body_radius))
		for i in level.final_wave:
			var d := pick()
			if d != null: spawn(d, spawn_point(d.body_radius))
		final_event.emit(_final)
	var scale := level.final_spawn_scale if _final_done else 1.0
	_acc += level.rate_at(time) * scale * LevelData.coop(level.coop_spawn, players) * delta
	while _acc >= 1.0:
		if alive.size() >= max_alive():
			_acc = 1.0
			break
		_acc -= 1.0
		var d := pick()
		if d == null: break
		spawn(d, spawn_point(d.body_radius))

## Depuración: repone enemigos deprisa hasta tener `target_alive` vivos.
func _keep_alive(delta: float) -> void:
	_acc += maxf(target_alive / 2.0, 15.0) * delta
	while _acc >= 1.0 and alive.size() < target_alive:
		_acc -= 1.0
		var d := pick()
		if d == null: break
		spawn(d, spawn_point(d.body_radius))
	_acc = minf(_acc, 1.0)

## Lanza ya el evento final (depuración).
func trigger_final() -> void:
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
	e.health *= LevelData.coop(level.coop_health, players)          # más jugadores, más aguante
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
		completed = true
		level_completed.emit()
