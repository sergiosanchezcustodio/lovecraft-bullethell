extends GutTest
## Ficha y mapa por jugador (hito 2.12, D-16): en solitario pausan; en cooperativo se abren
## en el cuadrante sin pausar. La ficha tiene tres páginas; el mapa, la orientación de la
## cámara.

class FakeGame extends Node3D:
	var players: Array[Player] = []
	var arena: Node3D
	var world: CombatWorld
	var director: WaveDirector

var game: FakeGame

func before_each() -> void:
	game = FakeGame.new()
	add_child_autofree(game)
	game.world = CombatWorld.new()
	game.add_child(game.world)

func after_each() -> void:
	get_tree().paused = false

func _player(i: int) -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % ["dyer", "olmstead"][i]), BotInput.new("idle"), Devices.COLORS[i])
	p.index = i
	p.world = game.world
	game.add_child(p)
	p.weapons = WeaponSystem.new().setup(p, game.world)
	p.add_child(p.weapons)
	p.weapons.add_weapon(load("res://data/weapons/webly.tres"))
	game.players.append(p)
	return p

func _menus() -> PlayerMenus:
	var m := PlayerMenus.new().setup(game, game.players)
	add_child_autofree(m)
	return m

func test_en_solitario_la_ficha_pausa_y_al_cerrar_se_reanuda() -> void:
	var p := _player(0)
	var m := _menus()
	m.toggle(p, &"sheet")
	assert_eq(m.open_kind(p), &"sheet")
	assert_true(get_tree().paused)
	m.toggle(p, &"sheet")
	assert_false(m.is_open(p))
	assert_false(get_tree().paused)

func test_en_cooperativo_no_pausa() -> void:
	var a := _player(0)
	var b := _player(1)
	var m := _menus()
	m.toggle(b, &"map")
	assert_eq(m.open_kind(b), &"map")
	assert_false(m.is_open(a))
	assert_false(get_tree().paused, "los demás siguen jugando")
	var c: Control = m._open[b]
	assert_gt(c.anchor_left, 0.49, "en el cuadrante de J2 (derecha)")

func test_cambiar_de_ficha_a_mapa() -> void:
	var p := _player(0)
	var m := _menus()
	m.toggle(p, &"sheet")
	m.toggle(p, &"map")
	assert_eq(m.open_kind(p), &"map")
	assert_true(get_tree().paused)
	assert_true(m.close_all())
	assert_false(get_tree().paused)

func test_la_ficha_pasa_sus_tres_paginas() -> void:
	var p := _player(0)
	var s := PlayerMenus.Sheet.new(p, game)
	add_child_autofree(s)
	assert_eq(s.page, 0)
	s.turn(1)
	assert_eq(s.page, 1)
	s.turn(1)
	s.turn(1)
	assert_eq(s.page, 0, "vuelve a la primera")
	s.turn(-1)
	assert_eq(s.page, 2)

func test_el_mapa_mira_como_la_camara() -> void:
	var right := PlayerMotor.screen_to_world(Vector2(1, 0))
	var up := PlayerMotor.screen_to_world(Vector2(0, 1))
	assert_gt(PlayerMenus.ArenaMap.project(right * 5.0).x, 4.9, "derecha en pantalla, derecha en el mapa")
	assert_lt(PlayerMenus.ArenaMap.project(up * 5.0).y, -4.9, "arriba en pantalla, arriba en el mapa")

func test_todas_las_armas_tienen_descripcion() -> void:
	for wd: WeaponData in DebugOptions.list_resources("res://data/weapons"):
		assert_ne(wd.description, "", String(wd.id))
