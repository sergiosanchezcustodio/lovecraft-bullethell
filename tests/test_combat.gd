extends GutTest

const DT := 1.0 / 60.0
var world: CombatWorld
var player: Player

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	player = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(player)
	world.add_player(player)

func _dummy(pos: Vector3, health: float = 60.0) -> TrainingDummy:
	var d := TrainingDummy.new().setup(world, "pinguino")
	d.position = pos
	d.max_health = health
	d.health = health
	world.add_child(d)
	return d

func _step(n: int = 1) -> void:
	for i in n:
		world.rebuild_grid()
		world.bullets._physics_process(DT)

# ---------------- armas ----------------
func test_estadisticas_por_nivel() -> void:
	var rev: WeaponData = load("res://data/weapons/revolver.tres")
	assert_almost_eq(rev.stat("damage", 1), 12.0, 0.001)
	assert_almost_eq(rev.stat("damage", 2), 15.0, 0.001)
	assert_almost_eq(rev.stat("cooldown", 3), 0.64, 0.001)
	assert_eq(int(rev.stat("count", 3)), 1)
	assert_eq(int(rev.stat("count", 4)), 2)
	assert_eq(int(rev.stat("pierce", 5)), 1)
	var dyn: WeaponData = load("res://data/weapons/dinamita.tres")
	assert_almost_eq(dyn.stat("aoe_radius", 2), 2.64, 0.001)
	assert_eq(int(dyn.stat("count", 5)), 3)
	assert_eq(rev.level_text.size(), rev.max_level - 1, "un texto por mejora")

# ---------------- patrones ----------------
func test_patron_radial_reparte_y_gira() -> void:
	var p := BulletPattern.new()
	p.shape = BulletPattern.Shape.RADIAL
	p.count = 8
	p.aimed = false
	p.spin_deg = 10.0
	var d0 := p.directions(Vector3.ZERO, 0)
	assert_eq(d0.size(), 8)
	assert_almost_eq(d0[0].angle_to(d0[1]), deg_to_rad(45.0), 0.001)
	var d1 := p.directions(Vector3.ZERO, 1)
	assert_almost_eq(d0[0].angle_to(d1[0]), deg_to_rad(10.0), 0.001)

func test_patron_abanico_centrado_en_el_objetivo() -> void:
	var p := BulletPattern.new()
	p.shape = BulletPattern.Shape.FAN
	p.count = 3
	p.spread_deg = 60.0
	var d := p.directions(Vector3(1, 0, 0), 0)
	assert_almost_eq(d[1], Vector3(1, 0, 0), Vector3.ONE * 0.001)
	assert_almost_eq(d[0].angle_to(d[2]), deg_to_rad(60.0), 0.001)

func test_estilo_segun_el_danio() -> void:
	var p := BulletPattern.new()
	p.damage_physical = 5; p.damage_mental = 0
	assert_eq(p.style(), BulletManager.Style.PHYSICAL)
	p.damage_physical = 0; p.damage_mental = 5
	assert_eq(p.style(), BulletManager.Style.MENTAL)
	p.damage_physical = 5
	assert_eq(p.style(), BulletManager.Style.MIXED)

# ---------------- balas ----------------
func test_bala_enemiga_hiere_al_jugador_segun_el_tipo() -> void:
	world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.MIXED, player.position + Vector3(0.1, 0, 0),
		Vector3.ZERO, 0.1, 0.2, Damage.new(10, 7), 5.0)
	_step()
	assert_eq(player.health, player.data.max_health - 10)
	assert_eq(player.sanity, player.data.max_sanity - 7)
	assert_eq(world.bullets.count, 0, "la bala desaparece al impactar")

func test_invulnerable_al_esquivar_y_tras_un_golpe() -> void:
	player.motor.step(DT, Vector2.ZERO, true)          # esquiva
	world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, player.position, Vector3.ZERO,
		0.1, 0.2, Damage.new(10, 0), 5.0)
	_step()
	assert_eq(player.health, player.data.max_health, "durante el esquive no recibe daño")
	assert_eq(world.bullets.count, 1, "la bala sigue: se puede atravesar esquivando")

func test_bala_del_jugador_hiere_y_atraviesa() -> void:
	var a := _dummy(Vector3(3, 0, 0))
	var b := _dummy(Vector3(4.2, 0, 0))
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.PLAYER, Vector3(1.5, 0, 0), Vector3(20, 0, 0),
		0.2, 0.17, Damage.new(12, 0), 2.0, 1)
	_step(12)
	assert_eq(a.health, 48.0)
	assert_eq(b.health, 48.0, "pierce = 1: atraviesa al primero y da al segundo")
	assert_eq(world.bullets.count, 0)

func test_objetivos_para_las_armas() -> void:
	var near := _dummy(Vector3(2, 0, 1))
	_dummy(Vector3(-9, 0, 0))
	var c := _dummy(Vector3(6, 0, 6))
	_dummy(Vector3(6.8, 0, 6)); _dummy(Vector3(6, 0, 6.8))
	world.rebuild_grid()
	assert_eq(world.nearest_enemy(Vector3.ZERO, 12.0), near)
	assert_eq(world.densest_enemy(Vector3.ZERO, 12.0, 1.2), c)
	assert_null(world.nearest_enemy(Vector3.ZERO, 1.0))

func test_explosion_hiere_mas_en_el_centro() -> void:
	var center := _dummy(Vector3(5, 0, 0))
	var edge := _dummy(Vector3(6.8, 0, 0))
	var far := _dummy(Vector3(9, 0, 0))
	world.rebuild_grid()
	var e := ThrownExplosive.new()
	e.setup(world, Vector3.ZERO, Vector3(5, 0, 0), 0.1, 0.0, 2.0, 30.0, Color.YELLOW)
	world.fx.add_child(e)
	e._explode()
	assert_almost_eq(center.health, 30.0, 0.01, "daño completo en el centro")
	assert_between(edge.health, 30.0, 50.0, "algo de daño en el borde")
	assert_eq(far.health, 60.0, "fuera del radio no le afecta")
