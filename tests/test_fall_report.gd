extends GutTest
## Informe al caer (hito 13.1): cada golpe apunta de quién y por qué vía, y el informe lo resume.

const DT := 1.0 / 60.0
var world: CombatWorld
var player: Player

func before_each() -> void:
	Difficulty.forced = 0                                  # multiplicadores a 1 (como pre_run.gd)
	world = CombatWorld.new()
	add_child_autofree(world)
	player = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(player)
	world.add_player(player)

func test_la_bala_enemiga_apunta_quien_la_disparo() -> void:
	var d := Damage.new(10, 4)
	d.tag = &"cultista"                                   # lo pone PatternRunner con el id del enemigo
	world.bullets.spawn(BulletManager.Team.ENEMY, BulletManager.Style.MIXED, player.position + Vector3(0.1, 0, 0),
		Vector3.ZERO, 0.1, 0.2, d, 5.0)
	world.rebuild_grid()
	world.bullets._physics_process(DT)
	assert_true(player.received_via.has("cultista|bala"), "origen y vía: %s" % [player.received_via])
	assert_almost_eq(float(player.received_via["cultista|bala"][0]), 10.0, 0.01)
	assert_eq(player.last_hit.get("via"), &"bala")

func test_sin_via_es_golpe_o_otro_y_la_presencia_se_apunta() -> void:
	var z := Damage.new(5, 0)
	z.via = &"zona"; z.who = &"antiguo"
	player.take_damage(z)
	player._hurt_time = 99.0                              # sin la invulnerabilidad tras el golpe
	player.take_damage(Damage.new(3, 0))
	assert_true(player.received_via.has("antiguo|zona"))
	assert_true(player.received_via.has("otro|otro"), "sin origen ni vía: %s" % [player.received_via])
	player.drain_sanity(6.0, "presencia", &"presencia")
	assert_true(float(player.received_via["presencia|presencia"][1]) > 0.0)
	player.drain_sanity(6.0)                             # sin origen: no se apunta (como antes)
	assert_eq(player.received_via.size(), 3)

func test_el_informe_ordena_y_reparte_por_via() -> void:
	var rv := {"pinguino|contacto": [120.0, 0.0], "acechador|golpe": [60.0, 0.0], "cultista|bala": [20.0, 30.0],
		"presencia|presencia": [0.0, 90.0]}
	var falls := [{"t": 192.0, "hit": {"src": "pinguino", "via": &"contacto", "ph": 14.0, "me": 0.0}}]
	var hist := PackedVector2Array()
	for i in 90: hist.append(Vector2(1.0 - i / 90.0, 0.8))
	var r := FallReport.build("J1 · Dyer", Color.YELLOW, rv, falls, hist, PackedInt32Array([10, 20, 30]))
	assert_almost_eq(float(r.hp), 200.0, 0.01)
	assert_almost_eq(float(r.san), 120.0, 0.01)
	assert_eq(String(r.top_hp[0].src), "pinguino", "el que más vida quitó, primero")
	assert_eq(String(r.top_san[0].src), "presencia")
	assert_eq((r.hist as PackedVector2Array).size(), FallReport.HIST, "solo el último minuto")
	assert_eq(int(r.alive_max), 30)
	assert_almost_eq(float(r.alive_avg), 20.0, 0.01)
	var text := "\n".join(FallReport.lines(r))
	assert_string_contains(text, "Te abatió")
	assert_string_contains(text, "3:12")
	assert_string_contains(text, "contacto 60 %")
	assert_string_contains(text, "Vida perdida 200")
	assert_string_contains(text, "Cordura perdida 120")

func test_nombres_de_enemigos_y_de_lo_demas() -> void:
	assert_ne(FallReport.name_of("pinguino"), "pinguino", "el nombre del enemigo, no su id")
	assert_eq(FallReport.name_of("presencia"), "La presencia de las criaturas")
	assert_eq(FallReport.via_name("bala"), "balas")

func test_el_panel_se_monta_con_cuatro() -> void:
	var reports: Array = []
	for i in 4:
		reports.append(FallReport.build("J%d" % (i + 1), Color.WHITE, {"pinguino|contacto": [10.0, 0.0]}, [], PackedVector2Array(), PackedInt32Array()))
	var p := FallReport.panel(reports)
	add_child_autofree(p)
	var grid: GridContainer = null
	for c in p.get_children(): if c is GridContainer: grid = c
	assert_not_null(grid)
	assert_eq(grid.columns, 2, "con tres o cuatro, en dos columnas")
	assert_eq(grid.get_child_count(), 4)
