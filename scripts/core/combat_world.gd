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

# ---------------------------------------------------------------- lo que hacen los enemigos (hito 9.3c)
## Golpes en un círculo, sonidos, salpicaduras, polvo y temblores de los ataques de los enemigos
## pasan por aquí. En red, en el anfitrión, `on_net` recibe cada uno (tipo y datos) y NetGame lo
## repite en los invitados con `apply_net`; los golpes solo dañan a los jugadores de cada PC.
var on_net := Callable()

## Golpe en un círculo: daña (y empuja hacia fuera) a los jugadores en pie de este PC que estén
## dentro. `dmg.source` es el enemigo que golpea.
func strike(at: Vector3, r: float, dmg: Damage, push := true) -> void:
	_strike(at, r, dmg, push)
	if on_net.is_valid(): on_net.call("strike", [at, r, dmg.physical, dmg.mental, dmg.source, push])

func _strike(at: Vector3, r: float, dmg: Damage, push: bool) -> void:
	for p in players:
		if p.remote or p.health <= 0.0: continue
		var off := Vector2(p.global_position.x - at.x, p.global_position.z - at.z)
		if off.length() < r + p.data.hurt_radius:
			var d := Damage.new(dmg.physical, dmg.mental)
			d.source = dmg.source
			d.tag = dmg.tag
			if push: d.knockback = Vector3(off.x, 0.0, off.y).normalized()
			p.take_damage(d)

func sfx(sound: String, at: Vector3) -> void:
	Auto.sfx_at(sound, at)
	if on_net.is_valid(): on_net.call("sfx", [sound, at])

func splash(at: Vector3, size := 1.0, tint := Color(0, 0, 0, 0), sound := "auto", mark := true) -> void:
	WadeSplash.burst(fx, at, size, tint, sound, mark)
	if on_net.is_valid(): on_net.call("splash", [at, size, tint, sound, mark])

func ground_hit(at: Vector3, r: float, tint: Color) -> void:
	VoxelFx.ground_hit(fx, at, r, tint)
	if on_net.is_valid(): on_net.call("ground", [at, r, tint])

func shake(amount: float) -> void:
	var cam := get_viewport().get_camera_3d() as GameCamera if is_inside_tree() else null
	if cam != null: cam.shake(amount)
	if on_net.is_valid(): on_net.call("shake", [amount])

## Que la cámara de cada PC abarque al menos esto (los jefes grandes).
func view_at_least(size: float) -> void:
	var cam := get_viewport().get_camera_3d() as GameCamera if is_inside_tree() else null
	if cam != null: cam.view_size = maxf(cam.view_size, size)
	if on_net.is_valid(): on_net.call("view", [size])

## Grito que sube y se desvanece encima de algo (jefes que llaman a los suyos).
func shout(text: String, at: Vector3, tint: Color, size := 90, rise := 1.2, time := 1.6) -> void:
	_shout(text, at, tint, size, rise, time)
	if on_net.is_valid(): on_net.call("shout", [text, at, tint, size, rise, time])

func _shout(text: String, at: Vector3, tint: Color, size: int, rise: float, time: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = int(size * 0.17)
	l.modulate = tint
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = at
	fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + rise, time)
	tw.parallel().tween_property(l, "modulate:a", 0.0, time).set_ease(Tween.EASE_IN)
	tw.tween_callback(l.queue_free)

## En red, invitado: repite lo que ha hecho el anfitrión (`source`: la marioneta, o null).
func apply_net(kind: String, a: Array, source: Node3D = null) -> void:
	match kind:
		"strike":
			var d := Damage.new(float(a[2]), float(a[3]))
			d.source = source
			_strike(a[0], float(a[1]), d, bool(a[5]))
		"sfx": Auto.sfx_at(String(a[0]), a[1])
		"splash": WadeSplash.burst(fx, a[0], float(a[1]), a[2], String(a[3]), bool(a[4]))
		"ground": VoxelFx.ground_hit(fx, a[0], float(a[1]), a[2])
		"shake":
			var cam := get_viewport().get_camera_3d() as GameCamera
			if cam != null: cam.shake(float(a[0]))
		"view":
			var cam := get_viewport().get_camera_3d() as GameCamera
			if cam != null: cam.view_size = maxf(cam.view_size, float(a[0]))
		"shout": _shout(String(a[0]), a[1], a[2], int(a[3]), float(a[4]), float(a[5]))

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
## Jefe al que se apunta con prioridad (hito 6.6, Padre Dagon: desde su sima casi nunca es el
## más cercano). nearest_enemy lo elige si está a tiro y no hay nadie a menos de FOCUS_NEAR m.
var focus: Node3D
const FOCUS_NEAR := 3.0

func nearest_enemy(pos: Vector3, max_r: float) -> Node3D:
	if focus != null and (not is_instance_valid(focus) or not focus.is_alive()): focus = null
	if focus != null and focus.global_position.distance_to(pos) - float(focus.hit_radius) < max_r 			and grid.nearest(Vector2(pos.x, pos.z), FOCUS_NEAR) < 0:
		return focus
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

func record_kill(tag: StringName, pos := Vector3.INF) -> void:
	if tag == &"": return
	var s: Array = stats.get(tag, [0.0, 0])
	s[1] += 1
	stats[tag] = s
	var p := player_of(tag)                      # avisa al jugador (objetos al abatir)
	if p != null: p.on_kill(tag, pos)

## Jugador al que pertenece una etiqueta "J1:webly" (null si no es de nadie).
func player_of(tag: StringName) -> Player:
	var t := String(tag)
	if t.length() < 3 or t[0] != "J" or t[2] != ":": return null
	var i := int(t[1]) - 1
	for p in players:
		if p.index == i: return p
	return null

## Un enemigo ha recibido un golpe de un jugador: Cristal de Ithaqua y Fósforos de Cthugha.
func player_hit(tag: StringName, e: Node3D) -> void:
	if tag == &"": return
	if not players.any(func(q: Player) -> bool: return q.data.hit_slow > 0.0 or q.data.hit_burn > 0.0): return
	var p := player_of(tag)
	if p != null and (p.data.hit_slow > 0.0 or p.data.hit_burn > 0.0): p.on_hit(e)

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
