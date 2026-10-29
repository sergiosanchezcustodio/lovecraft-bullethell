extends GutTest
## Objetivos a mitad de nivel (hito 13.5): cuándo salen y cómo se cumple cada tipo.

var world: CombatWorld
var p: Player

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	p = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)

func _obj(kind: String, a: Vector3, b: Vector3) -> Objective:
	var o := Objective.new().setup(kind, world, null, a, b)
	if kind == "rescue": o.model_name = "olmstead"
	world.fx.add_child(o)
	return o

func _run(o: Objective, secs: float) -> void:
	var dt := 1.0 / 60.0
	for i in int(secs * 60.0):
		o._physics_process(dt)
		o._process(dt)
		if o.is_over(): return

func test_plan_uno_o_dos_y_antes_del_final() -> void:
	var rng := RandomNumberGenerator.new()
	var c := {"per_level": [1, 2], "first": [50.0, 90.0], "gap": [70.0, 110.0], "before_final": 40.0}
	for s in 30:
		rng.seed = s
		var t := ObjectiveDirector.plan(c, 240.0, rng)
		assert_between(t.size(), 1, 2)
		for at in t: assert_true(at <= 200.0, "ninguno a menos de 40 s del final")
	rng.seed = 1
	assert_eq(ObjectiveDirector.plan(c, 60.0, rng).size(), 0, "nivel corto: ninguno")

func test_rescate_se_levanta_y_llega_a_la_bengala() -> void:
	var o := _obj("rescue", Vector3(5, 0, 0), Vector3(8, 0, 0))
	_run(o, 1.0)
	assert_eq(o.state, Objective.State.WAIT, "espera hasta que llega alguien")
	p.global_position = Vector3(5.5, 0, 0)
	_run(o, 0.1)
	assert_eq(o.state, Objective.State.ACTIVE)
	p.global_position = Vector3(8.5, 0, 0)                 # el jugador, en la bengala: le sigue
	_run(o, 5.0)
	assert_eq(o.state, Objective.State.DONE)

func test_ritual_hay_que_quedarse_dentro() -> void:
	var o := _obj("ritual", Vector3.ZERO, Vector3.ZERO)
	o.need = 3.0
	p.global_position = Vector3(10, 0, 0)
	_run(o, 1.0)
	assert_eq(o.progress, 0.0, "fuera no avanza")
	p.global_position = Vector3(1, 0, 0)
	_run(o, 2.0)
	assert_almost_eq(o.progress, 2.0, 0.05)
	p.global_position = Vector3(10, 0, 0)
	_run(o, 2.0)
	assert_almost_eq(o.progress, 1.5, 0.05, "fuera se pierde despacio")
	p.global_position = Vector3(1, 0, 0)
	_run(o, 2.0)
	assert_eq(o.state, Objective.State.DONE)

func test_reliquia_frena_se_suelta_al_caer_y_se_entrega() -> void:
	var o := _obj("relic", Vector3(3, 0, 0), Vector3(12, 0, 0))
	p.global_position = Vector3(3, 0, 0)
	_run(o, 0.1)
	assert_eq(o.carrier, p.index, "la coge quien la toca")
	assert_eq(p.carry_slow, Objective.CARRY_SLOW, "y va más lento")
	p.global_position = Vector3(6, 0, 0)
	p.health = 0.0
	_run(o, 0.1)
	assert_eq(o.carrier, -1, "al caer la suelta")
	assert_almost_eq(o.body.x, 6.0, 0.01, "donde estaba")
	assert_eq(p.carry_slow, 1.0)
	p.health = p.data.max_health
	_run(o, 0.1)
	p.global_position = Vector3(12, 0, 0)
	_run(o, 0.1)
	assert_eq(o.state, Objective.State.DONE)
	assert_eq(p.carry_slow, 1.0, "al entregarla, a su velocidad")

func test_se_acaba_el_tiempo() -> void:
	var o := _obj("relic", Vector3(3, 0, 0), Vector3(12, 0, 0))
	o.limit = 1.0
	p.global_position = Vector3(-10, 0, 0)
	_run(o, 1.5)
	assert_eq(o.state, Objective.State.FAILED)

func test_red_ida_y_vuelta() -> void:
	var o := _obj("relic", Vector3(3, 0, 0), Vector3(12, 0, 0))
	o.reward = ["chest", 1]
	var m := Objective.from_net(world, o.net_args())
	assert_true(m.mirror)
	assert_eq(m.kind, "relic")
	assert_eq(m.b, o.b)
	assert_eq(m.reward, ["chest", 1])
	o.carrier = 0
	o.state = Objective.State.ACTIVE
	m.apply_state(o.net_state())
	assert_eq(m.carrier, 0)
	assert_eq(m.state, Objective.State.ACTIVE)
	m.free()
