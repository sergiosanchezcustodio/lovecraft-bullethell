extends GutTest
## Menú de depuración: los ajustes se pueden subir y bajar sin dejar restos, y el director
## respeta el número de enemigos y el tipo elegidos.

const DT := 1.0 / 60.0
var world: CombatWorld
var player: Player
var root: Node3D
var obstacles: ObstacleMap

func before_each() -> void:
	DebugOptions.clear()
	world = CombatWorld.new()
	add_child_autofree(world)
	player = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(player)
	world.add_player(player)
	player.weapons = WeaponSystem.new().setup(player, world)
	player.add_child(player.weapons)
	player.weapons.add_weapon(load("res://data/weapons/granada.tres"))
	for f in ["velocidad", "vida", "reflejos"]:
		player.progress.upgrade_pool.append(load("res://data/upgrades/%s.tres" % f))
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)

func after_each() -> void:
	DebugOptions.clear()

func test_las_pasivas_suben_y_vuelven_a_su_valor() -> void:
	var speed0 := player.data.move_speed
	var cd0 := player.data.dodge_cooldown
	DebugOptions.set_value("passives", {"velocidad": 3, "reflejos": 2})
	DebugOptions.rebuild_stats(player)
	assert_gt(player.data.move_speed, speed0)
	assert_ne(player.data.dodge_cooldown, cd0)
	DebugOptions.rebuild_stats(player)            # rehacer dos veces no acumula
	var twice := player.data.move_speed
	DebugOptions.rebuild_stats(player)
	assert_almost_eq(player.data.move_speed, twice, 0.0001)
	DebugOptions.set_value("passives", {"velocidad": 0, "reflejos": 0})
	DebugOptions.rebuild_stats(player)
	assert_almost_eq(player.data.move_speed, speed0, 0.0001, "bajar a 0 devuelve el valor original")
	assert_almost_eq(player.data.dodge_cooldown, cd0, 0.0001)

func test_la_vida_ganada_se_rellena_y_al_bajar_no_pasa_del_maximo() -> void:
	var base := player.data.max_health
	DebugOptions.set_value("passives", {"vida": 2})
	DebugOptions.rebuild_stats(player)
	assert_eq(player.health, player.data.max_health)
	DebugOptions.set_value("passives", {"vida": 0})
	DebugOptions.rebuild_stats(player)
	assert_eq(player.health, player.data.max_health)
	assert_eq(player.data.max_health, base)

func test_velocidad_de_depuracion_se_suma_a_las_pasivas() -> void:
	var speed0 := player.data.move_speed
	DebugOptions.set_value("speed", 2.0)
	DebugOptions.rebuild_stats(player)
	assert_almost_eq(player.data.move_speed, speed0 * 2.0, 0.0001)

func test_armas_se_anaden_suben_y_quitan() -> void:
	DebugOptions.set_value("weapons", {"webly": 3, "granada": 0})
	DebugOptions.apply_weapons(player)
	assert_null(player.weapons.get_weapon(&"granada"))
	assert_eq(player.weapons.get_weapon(&"webly").level, 3)
	DebugOptions.set_value("weapons", {"webly": 99})
	DebugOptions.apply_weapons(player)
	var w := player.weapons.get_weapon(&"webly")
	assert_eq(w.level, w.data.max_level, "no pasa del nivel máximo")

func test_el_director_mantiene_el_numero_de_enemigos_y_el_tipo() -> void:
	var level := (load("res://data/levels/p1_n1.tres") as LevelData).duplicate()
	var d := WaveDirector.new().setup(level, world, obstacles, null, root)
	world.add_child(d)
	d.target_alive = 12
	d.pool_override.append(load("res://data/enemies/acechador.tres"))
	for i in 120: d._physics_process(DT)
	assert_eq(d.alive.size(), 12)
	for e in d.alive: assert_eq(e.data.id, &"acechador")
	d.spawning_paused = true
	d.target_alive = 40
	for i in 60: d._physics_process(DT)
	assert_eq(d.alive.size(), 12, "con las oleadas en pausa no aparece nadie")

# ---------------- el menú, sobre una partida mínima ----------------
class FakeGame extends Node:
	var player: Player
	var director: WaveDirector
	var camera: GameCamera
	var _t := 0.0

func _menu() -> Array:
	var g := FakeGame.new()
	g.player = player
	var level := (load("res://data/levels/p1_n1.tres") as LevelData).duplicate()
	g.director = WaveDirector.new().setup(level, world, obstacles, null, root)
	world.add_child(g.director)
	g.camera = GameCamera.new()
	g.add_child(g.camera)
	add_child_autofree(g)
	var m := DebugMenu.new(g)
	add_child_autofree(m)
	return [g, m]

func _row(m: DebugMenu, title_start: String) -> OptionRow:
	for r in m.find_children("*", "Button", true, false):
		if r is OptionRow and ((r as OptionRow).title.begins_with(title_start)): return r
	return null

func test_el_menu_se_monta_y_sus_filas_cambian_la_partida() -> void:
	var gm := _menu()
	var g: FakeGame = gm[0]
	var m: DebugMenu = gm[1]
	var count := _row(m, "Enemigos en pantalla")
	assert_not_null(count)
	count.step(-1)                                   # desde "Los del nivel", hacia atrás: 300
	assert_eq(g.director.target_alive, 300)
	_row(m, "Invulnerable").step(1)
	assert_true(player.god)
	_row(m, "Esquive").step(1)
	assert_eq(String(player.data.dodge_style.id), DebugOptions.get_value("dodge", ""))
	_row(m, "Revólver Webly").step(2)                      # sin ella -> nivel 2
	assert_eq(player.weapons.get_weapon(&"webly").level, 2)
	_row(m, "Altura visible").step(1)
	assert_eq(g.camera.view_size, 20.0)
	_row(m, "Subir un nivel").pressed.emit()
	assert_eq(player.progress.level, 2)
	_row(m, "Vaciar la cordura").pressed.emit()
	assert_eq(player.sanity, 0.0)
