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
