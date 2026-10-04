class_name CombatWorld
extends Node3D
## Punto de encuentro del combate: registra jugadores y enemigos, reconstruye la
## rejilla espacial de enemigos en cada paso de física y contiene las balas y los
## efectos. Armas, balas y enemigos lo consultan en lugar de buscarse entre sí.
##
## Un "objetivo" (enemigo o muñeco) es cualquier Node3D con:
##   var hit_radius: float, func take_damage(d: Damage) -> void, func is_alive() -> bool

var bullets: BulletManager
## Estadísticas de la partida por etiqueta de arma ("J1:webly"): [daño hecho, enemigos abatidos].
var stats := {}
var breakables: Array[Node3D] = []           ## objetos rompibles: se golpean, no se apuntan
var flow: FlowField                          ## mapa de flujo hacia los jugadores (rodear el decorado)
var freeze_t := 0.0                          ## s de tiempo congelado (recompensa): enemigos y sus balas quietos
var fx: Node3D                               ## efectos visuales (explosiones, avisos)
var players: Array[Player] = []
var enemies: Array[Node3D] = []
var grid := SpatialGrid.new(2.0)
var _grid_targets: Array[Node3D] = []        ## índice de la rejilla -> objetivo
var bounds := Rect2(-40, -40, 80, 80)        ## límites para eliminar balas perdidas
var obstacles: ObstacleMap                   ## decorado: lo que no se atraviesa (jugadores, mascotas, balas)

func _init() -> void:
	name = "CombatWorld"
	process_physics_priority = -10           # antes que jugadores, armas y balas

func _ready() -> void:
	bullets = BulletManager.new()
	bullets.world = self
	add_child(bullets)
	fx = Node3D.new()
	fx.name = "FX"
	add_child(fx)

func add_player(p: Player) -> void:
	players.append(p)

func add_enemy(e: Node3D) -> void:
	enemies.append(e)

func remove_enemy(e: Node3D) -> void:
	enemies.erase(e)

func _physics_process(delta: float) -> void:
	if freeze_t > 0.0: freeze_t -= delta
	rebuild_grid()
	if flow == null and obstacles != null and obstacles.has_mask() and not OS.get_cmdline_user_args().has("noflow=true"):
		flow = FlowField.new().setup(obstacles, bounds)
	if flow != null:
		var t0 := Prof.start()
		var targets: Array[Vector2] = []
		for p in players:
			if p.health > 0.0: targets.append(Vector2(p.global_position.x, p.global_position.z))
		flow.tick(delta, targets)
		Prof.stop("flujo", t0)

func freeze_time(seconds: float) -> void:
	freeze_t = maxf(freeze_t, seconds)

func add_breakable(b: Node3D) -> void:
	breakables.append(b)

func remove_breakable(b: Node3D) -> void:
	breakables.erase(b)

static func is_enemy(t: Node3D) -> bool:
	return not t.is_in_group(&"breakable")

func rebuild_grid() -> void:
	var t0 := Prof.start()
	grid.clear()
	_grid_targets.clear()
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive(): continue
		var p := e.global_position
		grid.insert(Vector2(p.x, p.z), e.hit_radius)
		_grid_targets.append(e)
	for b in breakables:
		if not is_instance_valid(b): continue
		grid.insert(Vector2(b.global_position.x, b.global_position.z), b.hit_radius)
		_grid_targets.append(b)
	Prof.stop("rejilla", t0)

func target_at(grid_id: int) -> Node3D:
	return _grid_targets[grid_id]

## Enemigo vivo más cercano a pos dentro de max_r, o null.
func nearest_enemy(pos: Vector3, max_r: float) -> Node3D:
	var id := grid.nearest(Vector2(pos.x, pos.z), max_r)
	if id < 0: return null
	if is_enemy(_grid_targets[id]): return _grid_targets[id]
	# lo más cercano es un rompible: el enemigo más cercano de verdad (rara vez pasa)
	var best: Node3D = null
	var bd := INF
	for t in enemies_in_circle(pos, max_r):
		if not is_enemy(t): continue
		var d := t.global_position.distance_squared_to(pos)
		if d < bd: bd = d; best = t
	return best

## Enemigo en el centro de la zona más poblada a menos de max_r (radio de grupo r), o null.
func densest_enemy(pos: Vector3, max_r: float, r: float) -> Node3D:
	var id := grid.densest(Vector2(pos.x, pos.z), max_r, r)
	if id < 0: return null
	return _grid_targets[id] if is_enemy(_grid_targets[id]) else nearest_enemy(pos, max_r)

## La élite más cercana a menos de max_r o, si no hay ninguna, el enemigo con más vida.
func strongest_enemy(pos: Vector3, max_r: float) -> Node3D:
	var best: Node3D = null
	var best_score := -INF
	for e in enemies_in_circle(pos, max_r):
		if not is_enemy(e): continue
		var elite: bool = "data" in e and e.data.elite
		var hp: float = e.health if "health" in e else 0.0
		var score: float = (1e6 - e.global_position.distance_to(pos)) if elite else hp
		if score > best_score:
			best_score = score
			best = e
	return best

## Objetivos vivos que tocan un círculo (para explosiones y áreas).
func record_damage(tag: StringName, amount: float) -> void:
	if tag == &"" or amount <= 0.0: return
	var s: Array = stats.get(tag, [0.0, 0])
	s[0] += amount
	stats[tag] = s

func record_kill(tag: StringName) -> void:
	if tag == &"": return
	var s: Array = stats.get(tag, [0.0, 0])
	s[1] += 1
	stats[tag] = s

## Daño y abatidos de un jugador (índice 0..3): {arma: [daño, abatidos]} y los totales.
func stats_of(index: int) -> Dictionary:
	var prefix := "J%d:" % (index + 1)
	var out := {}
	var total := [0.0, 0]
	for k in stats:
		var ks := String(k)
		if not ks.begins_with(prefix): continue
		out[ks.substr(prefix.length())] = stats[k]
		total[0] += stats[k][0]; total[1] += stats[k][1]
	return {"weapons": out, "total": total}

func enemies_in_circle(pos: Vector3, r: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for id in grid.query_circle(Vector2(pos.x, pos.z), r):
		out.append(_grid_targets[id])
	return out
