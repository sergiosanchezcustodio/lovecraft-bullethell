extends GutTest
## Peligros del escenario (hito 7.4): los Ángulos devoradores atraen y engullen a quien queda
## en el centro; las olas empujan y dañan a quien está en su franja.

const DT := 1.0 / 60.0
var world: CombatWorld
var p: Player

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	p = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)

func _level() -> LevelData:
	var l := LevelData.new()
	l.angle_every = 0.0
	l.wave_every = 0.0
	return l

func test_los_angulos_atraen_hacia_su_centro_y_engullen() -> void:
	var h := Hazards.new().setup(_level(), world, null)
	world.add_child(h)
	p.position = Vector3(2.0, 0, 0)
	h._open_angle(Vector3.ZERO, 1.8)
	await wait_physics_frames(30)
	h._physics_process(DT)
	assert_lt(p.push.x, 0.0, "tira hacia el centro (x negativa)")
	var before := p.health
	p.position = Vector3(0.2, 0, 0)
	for i in 60: h._physics_process(DT)
	assert_lt(p.health, before, "en el centro, engulle")

func test_la_ola_empuja_y_dana_en_su_franja() -> void:
	var l := _level()
	var h := Hazards.new().setup(l, world, null)
	world.add_child(h)
	p.position = Vector3(0, 0, 3.0)
	h._waves.append({"z": 3.0, "half": 2.0, "t": 0.0, "node": MeshInstance3D.new(), "hit": false})
	(h._waves[0].node as MeshInstance3D).material_override = StandardMaterial3D.new()
	world.fx.add_child(h._waves[0].node)
	var before := p.health
	h._physics_process(DT)
	assert_lt(p.health, before, "la ola daña")
	assert_gt(p.push.z, 0.0, "y empuja hacia el sur")
