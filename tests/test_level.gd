extends GutTest

const DT := 1.0 / 60.0
var world: CombatWorld
var player: Player
var root: Node3D
var obstacles: ObstacleMap

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	player = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(player)
	world.add_player(player)
	root = Node3D.new()
	world.add_child(root)
	obstacles = ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)

func _director(level: LevelData) -> WaveDirector:
	var d := WaveDirector.new().setup(level, world, obstacles, null, root)
	d.rng.seed = 5
	world.add_child(d)
	return d

func _level() -> LevelData:
	return (load("res://data/levels/p1_n1.tres") as LevelData).duplicate()

# ---------------- datos del nivel ----------------
func test_pesos_de_aparicion() -> void:
	assert_eq(LevelData.weight(1, 1), 1.0)
	assert_eq(LevelData.weight(1, 3), 4.0, "en el nivel 3, el escalón 1 pesa 2^2")
	assert_eq(LevelData.weight(3, 3), 1.0)
	assert_eq(LevelData.weight(4, 3), 0.0, "escalones por encima del nivel no aparecen")

func test_ritmo_interpolado() -> void:
	var l := _level()
	assert_almost_eq(l.rate_at(0.0), 0.6, 0.001)
	assert_almost_eq(l.rate_at(30.0), 0.85, 0.001)
	assert_almost_eq(l.rate_at(999.0), 3.0, 0.001)

func test_el_nivel_1_carga_con_su_grupo_y_evento() -> void:
	var l := _level()
	assert_eq(l.pool.size(), 2)
	assert_eq(l.final_enemy.id, &"acechador")
	for e in l.pool: assert_eq(e.tier, 1)

# ---------------- director de oleadas ----------------
func test_respeta_el_tope_de_vivos() -> void:
	var l := _level()
	l.spawn_rate = [Vector2(0, 200.0)] as Array[Vector2]
	l.max_alive = 7
	l.final_enemy = null
	var d := _director(l)
	for i in 30: d._physics_process(DT)
	assert_eq(d.alive.size(), 7)

func test_evento_final_y_nivel_superado() -> void:
	var l := _level()
	l.spawn_rate = [Vector2(0, 0.0)] as Array[Vector2]
	l.final_time = 0.05
	l.final_wave = 3
	var d := _director(l)
	watch_signals(d)
	for i in 6: d._physics_process(DT)
	assert_signal_emitted(d, "final_event")
	assert_eq(d.alive.size(), 4, "el Acechador y tres enemigos de acompañamiento")
	var boss: Enemy = d.alive.filter(func(e: Enemy) -> bool: return e.data.id == &"acechador")[0]
	boss.take_damage(Damage.new(9999, 0))
	assert_signal_emitted(d, "level_completed")
	assert_true(d.completed)

func test_aparece_fuera_del_decorado_y_lejos_del_jugador() -> void:
	obstacles.add_circle(Vector2(20, 0), 3.0)
	var d := _director(_level())
	for i in 40:
		var p := d.spawn_point(0.5)
		assert_false(obstacles.is_blocked(Vector2(p.x, p.z), 0.5), "punto bloqueado: " + str(p))
		assert_gt(Vector2(p.x, p.z).length(), 6.0)

# ---------------- obstáculos ----------------
func test_obstaculos_empujan_fuera_y_limites() -> void:
	obstacles.add_circle(Vector2(0, 0), 1.0)
	var p := obstacles.push_out(Vector2(0.5, 0), 0.4)
	assert_almost_eq(p.length(), 1.4, 0.001)
	p = obstacles.push_out(Vector2(40, 0), 0.4)
	assert_almost_eq(p.x, 31.6, 0.001, "dentro de la arena")
	assert_true(obstacles.is_blocked(Vector2(1.2, 0), 0.4))
	assert_false(obstacles.is_blocked(Vector2(3, 0), 0.4))

# ---------------- patrones con huecos ----------------
func test_patron_con_huecos() -> void:
	var p: BulletPattern = load("res://data/patterns/acechador_croar.tres")
	var dirs := p.directions(Vector3.FORWARD, 0)
	assert_eq(dirs.size(), p.count - p.gap_count * p.gap_width, "30 balas menos 3 huecos de 3")

# ---------------- comportamientos ----------------
func _enemy(id: String, pos: Vector3) -> Enemy:
	var e := Enemy.new().setup(load("res://data/enemies/%s.tres" % id), world, obstacles)
	e.position = pos
	root.add_child(e)
	return e

func test_el_pinguino_va_hacia_donde_oyo() -> void:
	var e := _enemy("pinguino", Vector3(8, 0, 0))
	var b := e.behavior as BlindBehavior
	b._hear_t = 0.0
	player.position = Vector3(0, 0, 0)
	world.rebuild_grid()
	var v := b.update(e, player, DT)
	assert_lt(b.heard.distance_to(player.position), 1.5, "lo oído está cerca del jugador")
	assert_lt(v.x, 0.0, "camina hacia el jugador")
	player.position = Vector3(0, 0, 10)          # el jugador se aparta de lado
	v = b.update(e, player, DT)
	assert_lt(v.x, 0.0, "hasta volver a oír, sigue yendo a lo que oyó")

func test_el_fragmento_muere_y_avisa() -> void:
	var e := _enemy("fragmento", Vector3(5, 0, 0))
	world.rebuild_grid()
	assert_true(e in world.enemies)
	watch_signals(e)
	e.take_damage(Damage.new(e.data.max_health + 1, 0))
	assert_signal_emitted(e, "died")
	assert_false(e.is_alive())

func test_el_salto_del_acechador_hiere_dentro_del_radio() -> void:
	var e := _enemy("acechador", Vector3(0, 0, 0))
	var b := e.behavior as StalkBehavior
	player.position = Vector3(1.0, 0, 0)
	b._land(e)
	assert_eq(player.health, player.data.max_health - float(e.data.param("land_damage", 0)))
	player._hurt_time = -1.0
	player.health = player.data.max_health
	player.position = Vector3(5, 0, 0)
	b._land(e)
	assert_eq(player.health, player.data.max_health, "fuera del radio no le da")
