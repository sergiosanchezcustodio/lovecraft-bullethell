class_name CombatWorld
extends Node3D
## Punto de encuentro del combate: registra jugadores y enemigos, reconstruye la
## rejilla espacial de enemigos en cada paso de física y contiene las balas y los
## efectos. Armas, balas y enemigos lo consultan en lugar de buscarse entre sí.
##
## Un "objetivo" (enemigo o muñeco) es cualquier Node3D con:
##   var hit_radius: float, func take_damage(d: Damage) -> void, func is_alive() -> bool

var bullets: BulletManager
var fx: Node3D                               ## efectos visuales (explosiones, avisos)
var players: Array[Player] = []
var enemies: Array[Node3D] = []
var grid := SpatialGrid.new(2.0)
var _grid_targets: Array[Node3D] = []        ## índice de la rejilla -> objetivo
var bounds := Rect2(-40, -40, 80, 80)        ## límites para eliminar balas perdidas

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

func _physics_process(_delta: float) -> void:
	rebuild_grid()

func rebuild_grid() -> void:
	var t0 := Prof.start()
	grid.clear()
	_grid_targets.clear()
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive(): continue
		var p := e.global_position
		grid.insert(Vector2(p.x, p.z), e.hit_radius)
		_grid_targets.append(e)
	Prof.stop("rejilla", t0)

func target_at(grid_id: int) -> Node3D:
	return _grid_targets[grid_id]

## Enemigo vivo más cercano a pos dentro de max_r, o null.
func nearest_enemy(pos: Vector3, max_r: float) -> Node3D:
	var id := grid.nearest(Vector2(pos.x, pos.z), max_r)
	return null if id < 0 else _grid_targets[id]

## Enemigo en el centro de la zona más poblada a menos de max_r (radio de grupo r), o null.
func densest_enemy(pos: Vector3, max_r: float, r: float) -> Node3D:
	var id := grid.densest(Vector2(pos.x, pos.z), max_r, r)
	return null if id < 0 else _grid_targets[id]

## Objetivos vivos que tocan un círculo (para explosiones y áreas).
func enemies_in_circle(pos: Vector3, r: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for id in grid.query_circle(Vector2(pos.x, pos.z), r):
		out.append(_grid_targets[id])
	return out
