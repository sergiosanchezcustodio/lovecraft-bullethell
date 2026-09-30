extends GutTest
## Los proyectiles heredan la velocidad del jugador en la dirección del disparo: al correr y
## disparar hacia delante no los alcanza; de lado o hacia atrás no cambian.

var world: CombatWorld
var p: Player
var ws: WeaponSystem

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	p = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	ws = WeaponSystem.new().setup(p, world)
	p.add_child(ws)

func test_hacia_delante_suma_la_velocidad_del_jugador() -> void:
	p.velocity = Vector3(4, 0, 0)
	assert_almost_eq(ws.inherited_speed(Vector3(1, 0, 0)), 4.0, 0.001)

func test_de_lado_o_hacia_atras_no_cambia() -> void:
	p.velocity = Vector3(4, 0, 0)
	assert_almost_eq(ws.inherited_speed(Vector3(0, 0, 1)), 0.0, 0.001, "de lado")
	assert_almost_eq(ws.inherited_speed(Vector3(-1, 0, 0)), 0.0, 0.001, "hacia atrás")

func test_en_el_esquive_no_pasa_de_la_velocidad_al_andar() -> void:
	p.velocity = Vector3(15, 0, 0)
	assert_almost_eq(ws.inherited_speed(Vector3(1, 0, 0)), p.data.move_speed, 0.001)

func test_la_bala_sale_mas_rapida_y_llega_igual_de_lejos() -> void:
	var w := ws.add_weapon(load("res://data/weapons/webly.tres"))
	var base := w.stat("projectile_speed")
	p.velocity = Vector3(4, 0, 0)
	ws._spawn_bullet(w, Vector3(1, 0, 0))
	var b := world.bullets
	assert_eq(b.count, 1)
	assert_almost_eq(b._vel[0].length(), base + 4.0, 0.01)
	assert_almost_eq(b._life[0] * b._vel[0].length(), w.stat("range") * 1.15, 0.05, "mismo alcance")
