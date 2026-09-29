extends GutTest
## Partida de 1 a 4 jugadores (hito 2.9): cámara compartida con zoom y correa, bots que
## acompañan y un panel del HUD por jugador en su esquina.

func _cam(targets: Array[Node3D]) -> GameCamera:
	var cam := GameCamera.new()
	cam.view_size = 15.0
	cam.max_view_size = 24.0
	for t in targets: cam.targets.append(t)
	add_child_autofree(cam)
	return cam

func _dot(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # la cámara lee la posición interpolada
	add_child_autofree(n)
	n.global_position = pos
	n.reset_physics_interpolation()
	return n

## Mueve un punto sin interpolar (la cámara lee la posición interpolada).
func _move(n: Node3D, pos: Vector3) -> void:
	n.global_position = pos
	n.reset_physics_interpolation()

func test_con_un_jugador_no_hay_zoom_ni_correa() -> void:
	var a := _dot(Vector3.ZERO)
	var cam := _cam([a])
	assert_eq(cam.needed_size(), 15.0)
	assert_eq(cam.leash(Vector3(100, 0, 0)), Vector3(100, 0, 0))

func test_el_zoom_se_abre_al_separarse_y_tiene_tope() -> void:
	var a := _dot(Vector3.ZERO)
	var b := _dot(Vector3(2, 0, 0))
	var cam := _cam([a, b])
	assert_eq(cam.needed_size(), 15.0, "juntos: el tamaño normal")
	var right := PlayerMotor.screen_to_world(Vector2(1, 0))
	_move(b, right * 30.0)
	var s := cam.needed_size()
	assert_gt(s, 15.0)
	_move(b, right * 300.0)
	assert_eq(cam.needed_size(), 24.0, "tope")

func test_la_correa_no_deja_salir_del_encuadre_maximo() -> void:
	var a := _dot(Vector3.ZERO)
	var b := _dot(Vector3.ZERO)
	var cam := _cam([a, b])
	var right := PlayerMotor.screen_to_world(Vector2(1, 0))
	var far := right * 200.0
	var held := cam.leash(far)
	assert_lt(held.length(), 40.0, "recolocado dentro")
	var near := right * 3.0
	assert_eq(cam.leash(near), near, "cerca: no se toca")

func test_el_bot_acompanante_va_hacia_el_lider() -> void:
	var leader := _dot(Vector3(20, 0, 0))
	var me := _dot(Vector3.ZERO)
	var bot := BotInput.new("follow")
	bot.body = me
	bot.leader = leader
	bot.update(0.016)
	var world_dir := PlayerMotor.screen_to_world(bot.move)
	assert_gt(world_dir.x, 0.5, "se mueve hacia el líder")

func test_un_panel_por_jugador_en_su_esquina() -> void:
	var players: Array[Player] = []
	for i in 3:
		var p := Player.new().setup(load("res://data/characters/%s.tres" % ["dyer", "olmstead", "peaslee"][i]), BotInput.new("idle"), Devices.COLORS[i])
		p.index = i
		add_child_autofree(p)
		p.weapons = WeaponSystem.new()
		players.append(p)
	var hud := Hud.new().setup(players, null)
	add_child_autofree(hud)
	assert_eq(hud.panels.size(), 3)
	assert_eq(hud.panels[1].grow_horizontal, Control.GROW_DIRECTION_BEGIN, "J2 a la derecha")
	assert_eq(hud.panels[2].grow_vertical, Control.GROW_DIRECTION_BEGIN, "J3 abajo")
	assert_eq(hud.player, players[0])
