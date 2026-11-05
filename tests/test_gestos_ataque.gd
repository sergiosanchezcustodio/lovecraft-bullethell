extends GutTest
## Gestos al atacar (hito 17.1): cada arma tiene el suyo, encadenarlos no hace saltar ninguna
## parte del cuerpo y las hordas no graban los que solo hacen los jugadores.

const DT := 1.0 / 120.0
const PA := preload("res://tests/test_player_anim.gd")

class RunInput extends PlayerInput:
	var t := 0.0
	var dodge_at := 99.0
	func update(delta: float) -> void:
		t += delta
		super.update(delta)
	func _read_move(_d: float) -> Vector2:
		return Vector2(1, 0) if t < 2.6 else Vector2.ZERO
	func _read_action(a: StringName) -> bool:
		return a == InputBindings.DODGE and t >= dodge_at and t < dodge_at + 0.03

func test_cada_arma_tiene_su_gesto() -> void:
	var want := {"webly": "shot", "springfield": "shot2", "carabina_mauser": "shot2", "thompson": "shot2",
		"machete": "swing", "latigo": "swing", "estoque": "thrust", "martillo": "slam", "signo": "cast",
		"granada": "throw", "bisturis": "throw", "necronomicon": "", "flammenwerfer": "shot2"}
	for id: String in want:
		var d: WeaponData = load("res://data/weapons/%s.tres" % id)
		assert_eq(d.gesture_of(), want[id], id)
	var dir := DirAccess.open("res://data/weapons")
	for f in dir.get_files():
		if not f.ends_with(".tres"): continue
		var g := (load("res://data/weapons/" + f) as WeaponData).gesture_of()
		assert_true(g == "" or Player.GESTURES.has(g), "%s: gesto %s" % [f, g])
		if g != "" and g != "shot" and g != "shot2":
			assert_true(Anims.has_anim("dyer", g), "%s: %s está en anim_humano" % [f, g])

## Corre disparando (ráfagas de una y dos manos), da tajos que se interrumpen unos a otros,
## conjura y esquiva a mitad de apuntar: ninguna parte salta de golpe.
func test_encadenar_gestos_sin_saltos() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var inp := RunInput.new()
	inp.dodge_at = 1.9
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), inp, Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	var pa: GutTest = PA.new()
	var prev: Array = pa._pose(p)
	var worst := 0.0
	var worst_t := 0.0
	var t := 0.0
	var next := 0.3
	while t < 3.2:
		if t >= next:
			var side := Vector3(-1, 0, 0.3)          # dispara de lado: el tronco gira
			if t < 0.9: p.gesture("shot", side, 1.0, 0.1); next += 0.1
			elif t < 1.3: p.gesture("shot2", side, 1.0, 0.12); next += 0.12
			elif t < 1.8: p.gesture("swing", side); next += 0.2   # cada tajo corta al anterior
			elif t < 2.2: p.gesture("shot", side, 1.0, 0.1); next += 0.1   # y esquiva apuntando
			else: p.gesture("cast", side); next += 0.35
		if fmod(t, 1.0 / 60.0) < DT: p._physics_process(1.0 / 60.0)
		p._process(DT)
		var cur: Array = pa._pose(p)
		var j: float = pa._max_jump(prev, cur)
		if j > worst:
			worst = j
			worst_t = t
		prev = cur
		t += DT
	pa.free()
	# el culatazo sube el brazo de golpe a propósito (unos 15 cm en la mano); una pose que
	# cambia de golpe pasa de 0,3 m
	assert_lt(worst, 0.25, "mayor desplazamiento entre fotogramas %.3f m en t=%.2f s" % [worst, worst_t])

func test_apunta_hacia_el_disparo_y_baja_el_brazo() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), PlayerInput.new(), Color.YELLOW)
	p.world = world
	world.add_child(p)
	for i in 10: p._process(1.0 / 60.0)
	var arm := Anims.part(p.model, "arm_r")
	var rest := arm.rotation.x
	p.gesture("shot", Vector3(0, 0, 1), 1.0, 0.2)
	for i in 12: p._process(1.0 / 60.0)
	assert_lt(arm.rotation.x, rest - 1.0, "el brazo, estirado hacia delante")
	for i in 90: p._process(1.0 / 60.0)
	assert_almost_eq(arm.rotation.x, rest, 0.3, "sin disparar, vuelve a su sitio")

func test_las_hordas_no_graban_los_gestos_del_jugador() -> void:
	var h := HordeMesh.build("cultista")
	assert_not_null(h)
	for g in ["cast", "swing", "thrust", "slam"]:
		assert_false(h.anim_rows.has(g), g)
	assert_true(h.anim_rows.has("walk"))
	assert_true(h.anim_rows.has("throw"), "throw sí: lo usan los enemigos que lanzan")

## Frenada (hito 17.2): tras correr, pararse en seco planta los pies y baja el cuerpo; un paso
## corto no frena.
class StopInput extends PlayerInput:
	var t := 0.0
	var run_for := 1.0
	func update(delta: float) -> void:
		t += delta
		super.update(delta)
	func _read_move(_d: float) -> Vector2:
		return Vector2(1, 0) if t < run_for else Vector2.ZERO

func _run_and_stop(run_for: float) -> Player:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var inp := StopInput.new()
	inp.run_for = run_for
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), inp, Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	var t := 0.0
	while t < run_for + 0.12:
		p._physics_process(1.0 / 60.0)
		p._process(1.0 / 60.0)
		t += 1.0 / 60.0
	return p

func test_frena_al_pararse_tras_correr() -> void:
	var p := _run_and_stop(1.0)
	assert_gte(p._brake_t, 0.0, "frena")
	assert_true(p._brake_full, "parada: con las piernas")
	assert_lt(p.model.position.y, -0.03, "y baja el cuerpo para no flotar")

func test_un_paso_corto_no_frena() -> void:
	var p := _run_and_stop(0.2)
	assert_lt(p._brake_t, 0.0)

## Mirar al peligro (hito 17.3): la cabeza se vuelve hacia el enemigo cercano y vuelve al frente
## cuando ya no está.
func test_mira_al_enemigo_cercano() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), PlayerInput.new(), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	var e := Enemy.new().setup(load("res://data/enemies/cultista.tres"), world, null)
	world.add_child(e)
	e.global_position = Vector3(4, 0, 0.5)              # a su izquierda (mira hacia +Z)
	world.add_enemy(e)
	for i in 4: world._physics_process(1.0 / 60.0)      # la rejilla, al día
	for i in 60:
		p._physics_process(1.0 / 60.0)
		p._process(1.0 / 60.0)
	var head := Anims.part(p.model, "head")
	assert_gt(head.rotation.y, 0.6, "la cabeza se vuelve hacia él")
	e.queue_free()
	await get_tree().process_frame
	for i in 90:
		p._physics_process(1.0 / 60.0)
		p._process(1.0 / 60.0)
	assert_lt(absf(head.rotation.y), 0.2, "y vuelve al frente")

## Celebraciones (hito 17.4): subir de nivel, evolucionar y abrir un baúl tienen su gesto, y un
## disparo no lo corta.
func test_una_celebracion_no_la_corta_un_ataque() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), PlayerInput.new(), Color.YELLOW)
	p.world = world
	world.add_child(p)
	for g in ["cheer", "marvel", "open_chest"]: assert_true(Anims.has_anim("dyer", g), g)
	p.play_once("cheer", true)
	p._process(0.1)
	p.gesture("swing", Vector3(1, 0, 0))
	assert_eq(p._override, "cheer", "el tajo espera")
	for i in 60: p._process(1.0 / 60.0)
	p.gesture("swing", Vector3(1, 0, 0))
	assert_eq(p._override, "swing", "acabada la celebración, vuelve a atacar")

## Victoria (hito 17.5): cada investigador tiene su pose y existe.
func test_cada_investigador_tiene_su_pose_de_victoria() -> void:
	var seen := {}
	for f in DirAccess.open("res://data/characters").get_files():
		if not f.ends_with(".tres"): continue
		var c: CharacterData = load("res://data/characters/" + f)
		assert_ne(c.victory, "", f)
		assert_true(Anims.has_anim(c.model, c.victory), "%s: %s" % [f, c.victory])
		seen[c.victory] = true
	assert_eq(seen.size(), 5, "las cinco poses se usan")

## Según el suelo (hito 17.6): vadeando, las manos van más altas; en el barro, el tronco más
## adelante y las rodillas más dobladas.
func test_vadear_y_barro_cambian_el_paso() -> void:
	var m := VoxelBuilder.load_model("res://models/johansen.json")
	add_child_autofree(m)
	var hand := func() -> float:
		var fore: Node3D = (m.get_meta("part_nodes") as Dictionary)["fore_r"]
		return (fore.global_transform * Vector3(0, -0.25, 0)).y
	var dry := 0.0
	var wet := 0.0
	for t in [0.0, 0.25, 0.5, 0.75]:                    # a lo largo del paso
		Anims.pose("johansen", "walk", m, t)
		dry += hand.call() / 4.0
		Anims.pose("johansen", "walk", m, t)
		Anims.script_for("johansen").call("terrain", m, t, 1.0, 0.0)
		wet += hand.call() / 4.0
	assert_gt(wet, dry + 0.1, "vadeando, la mano fuera del agua (%.2f → %.2f m)" % [dry, wet])
	Anims.pose("johansen", "walk", m, 0.3)
	var torso := Anims.part(m, "torso").rotation.x
	Anims.pose("johansen", "walk", m, 0.3)
	Anims.script_for("johansen").call("terrain", m, 0.3, 0.0, 1.0)
	assert_gt(Anims.part(m, "torso").rotation.x, torso + 0.1, "en el barro, echado adelante")
