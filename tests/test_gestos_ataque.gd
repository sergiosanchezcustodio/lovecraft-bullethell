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

## Gestos de reposo del shoggoth y la serpiente (hito 17.7): existen y se mueven; la lengua de
## Yig va dentro de la cabeza salvo cuando la saca, y el brote del shoggoth sale y vuelve.
func test_gestos_de_reposo_del_shoggoth_y_la_serpiente() -> void:
	for n in ["shoggoth", "yig"]:
		assert_eq(Anims.fidgets(n).size(), 2, n)
		for f: String in Anims.fidgets(n): assert_true(Anims.has_anim(n, f), "%s: %s" % [n, f])
	var y := VoxelBuilder.load_model("res://models/yig.json")
	add_child_autofree(y)
	var tongue: Node3D = (y.get_meta("part_nodes") as Dictionary)["tongue"]
	Anims.pose("yig", "idle", y, 0.3)
	var hidden := tongue.position.z
	var out := -99.0
	for i in 40:
		Anims.pose("yig", "fidget_tongue", y, i / 40.0)
		out = maxf(out, tongue.position.z)
	assert_gt(out, hidden + 0.12, "la saca")
	Anims.pose("yig", "fidget_coil", y, 0.5)
	var s4 := Anims.part(y, "s4").position
	Anims.pose("yig", "idle", y, 0.5)
	assert_gt(s4.distance_to(Anims.part(y, "s4").position), 0.2, "enroscada, la cola se acerca")
	var s := VoxelBuilder.load_model("res://models/shoggoth.json")
	add_child_autofree(s)
	Anims.pose("shoggoth", "fidget_split", s, 0.5)
	assert_gt(Anims.part(s, "bud").position.x, 0.3, "el brote, fuera")
	Anims.pose("shoggoth", "fidget_split", s, 1.0)
	assert_almost_eq(Anims.part(s, "bud").position.x, 0.0, 0.01, "y otra vez dentro")

## Muertes según el daño (hito 17.9): el golpe que mata dice cómo; la explosión lanza las piezas,
## el fuego ennegrece y el rayo hace temblar antes de caer.
func test_muere_segun_el_dano() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var e := Enemy.new().setup(load("res://data/enemies/cultista.tres"), world, null)
	world.add_child(e)
	var d := Damage.new(1e6, 0.0)
	d.how = &"burn"
	e.take_damage(d)
	assert_eq(e.killed_how, &"burn")
	assert_eq(d.scaled(0.5).how, &"burn", "scaled lo conserva")
	assert_eq(Crumble.delay_for("cultista", &"burn"), Crumble.CHAR_TIME)
	assert_gt(Crumble.delay_for("cultista", &"shock"), Crumble.delay_for("cultista"))
	var fx := Node3D.new()
	add_child_autofree(fx)
	var m := VoxelBuilder.load_model("res://models/cultista.json")
	fx.add_child(m)
	var head := Anims.part(m, "head")
	var y0 := head.global_position.y
	assert_true(Crumble.start(fx, m, Color.ORANGE, false, "", &"blast"))
	var c: Crumble = fx.get_child(fx.get_child_count() - 1)
	for i in 12: c._process(1.0 / 60.0)
	assert_gt(head.global_position.y, y0 + 0.3, "la cabeza sale volando")

## Golpe según la dirección (hito 17.10): sin empuje, se echa atrás lejos de quien lo causa, y más
## cuanto más le quita; el daño continuo no lo inclina.
func test_golpe_segun_la_direccion() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), PlayerInput.new(), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.global_position = Vector3(0, 0, -3)
	var e := Enemy.new().setup(load("res://data/enemies/cultista.tres"), world, null)
	world.add_child(e)
	e.global_position = Vector3.ZERO
	var d := Damage.new(1.0, 0.0)
	d.tag = &"J1:webly"
	e.take_damage(d)
	assert_almost_eq(e._hit_dir.z, 1.0, 0.01, "lejos de J1")
	var small := e._hit_k
	var big := Damage.new(e.health * 0.5, 0.0)
	big.tag = &"J1:webly"
	e.take_damage(big)
	assert_gt(e._hit_k, small, "un golpe fuerte lo echa más atrás")
	var burn := Damage.new(0.5, 0.0)
	burn.dot = true
	burn.tag = &"J1:flammenwerfer"
	e.take_damage(burn)
	assert_eq(e._hit_dir, Vector3.ZERO, "el fuego no lo inclina")

## Hito 17.10: lo que se ve. Golpeado desde J1 (detrás de él en -Z), la cabeza va hacia +Z.
func test_el_golpe_echa_atras_la_cabeza() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), PlayerInput.new(), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.global_position = Vector3(0, 0, -3)
	var e := Enemy.new().setup(load("res://data/enemies/cultista.tres"), world, null)
	world.add_child(e)
	e.global_position = Vector3.ZERO
	for i in 30: e._process(1.0 / 60.0)
	var head := Anims.part(e.model, "head")
	var z0 := head.global_position.z
	var d := Damage.new(e.health * 0.3, 0.0)
	d.tag = &"J1:webly"
	e.take_damage(d)
	var most := 0.0
	for i in 12:
		e._process(1.0 / 60.0)
		most = maxf(most, head.global_position.z - z0)
	assert_gt(most, 0.05, "la cabeza se echa atrás %.3f m" % most)

## Entradas por familia (hito 17.11): los humanos salen de la niebla; el expedicionario, de la
## nieve; un profundo que sale del agua trepa y, al salir, se sacude.
func test_entradas_por_familia() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var c := Enemy.new().setup(load("res://data/enemies/cultista.tres"), world, null)
	world.add_child(c)
	assert_eq(c._rise_kind(), Enemy.Rise.FOG, "el cultista, de la niebla")
	var x := Enemy.new().setup(load("res://data/enemies/expedicionario.tres"), world, null)
	world.add_child(x)
	assert_eq(x._rise_kind(), Enemy.Rise.GROUND, "el expedicionario, de la nieve")
	var d: EnemyData = (load("res://data/enemies/profundo.tres") as EnemyData).duplicate()
	d.rise = &"water"
	var p := Enemy.new().setup(d, world, null)
	world.add_child(p)
	assert_eq(p.family(), "anim_profundo")
	p._rise_start()
	assert_true(p._climb, "trepa")
	var arm := Anims.part(p.model, "arm_l")
	var most := 0.0
	var shook := false
	for i in 90:
		p._process(1.0 / 60.0)
		most = minf(most, arm.rotation.x)
		if p._shake_t > 0.0: shook = true
	assert_lt(most, -1.5, "los brazos arriba, agarrándose")
	assert_true(shook, "y al salir se sacude")

## Hordas menos clónicas (hito 17.12): cada uno con su tamaño, ritmo y manera de andar, en
## pequeño; las élites, del tamaño de siempre; la vida y la velocidad, iguales.
func test_hordas_menos_clonicas() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var sizes := {}
	var tempos := {}
	for i in 12:
		var e := Enemy.new().setup(load("res://data/enemies/cultista.tres"), world, null)
		world.add_child(e)
		assert_between(e.var_size, 0.94, 1.06)
		assert_between(e.var_tempo, 0.91, 1.09)
		assert_between(e.var_lean, 0.0, 0.07)
		assert_eq(e.health, e.data.max_health * e.health_scale, "la vida no cambia")
		sizes[snappedf(e.var_size, 0.01)] = true
		tempos[snappedf(e.var_tempo, 0.01)] = true
	assert_gt(sizes.size(), 4, "tamaños distintos")
	assert_gt(tempos.size(), 4, "ritmos distintos")
	var d: EnemyData = (load("res://data/enemies/cultista.tres") as EnemyData).duplicate()
	d.elite = true
	var el := Enemy.new().setup(d, world, null)
	world.add_child(el)
	assert_eq(el.var_size, 1.0, "la élite, de su tamaño")

## Más objetos con viento (hito 17.13): las tiendas de lona ondean, el bote del muelle flota y el
## toldo de la tienda del puerto es tela que cuelga de la pared.
func test_objetos_con_viento() -> void:
	for m in ["atrezo_tienda", "atrezo_tienda_rota"]:
		var c := Ambient.model_cfg(m)
		assert_true(c.has("sway") and float(c.get("flutter", 0.0)) > 0.0, "%s ondea" % m)
	assert_true(Ambient.model_cfg("alr_bote").has("bob"), "el bote flota")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://models/prt_tienda.json"))
	assert_true((d.pivots as Dictionary).has("cloth"), "el toldo cuelga de su pivote")
	assert_true((d.voxels as Array).any(func(v: Array) -> bool: return v[3] == "cloth"), "el toldo es tela")

## Vapor en las alcantarillas (hito 17.14): tapas en sitios libres de la calle, siempre las mismas,
## con su vapor; en Baja, no.
func test_vapor_alcantarillas() -> void:
	var p: Array = Quality.presets()
	assert_false(bool(p[0].vents), "en Baja no")
	assert_true(bool(p[2].vents), "en Alta sí")
	var e := VoxelFx.emitter("steam", 0.45)
	assert_gt(e.amount, 0)
	e.free()
	var arena := Node3D.new()
	var obs := ObstacleMap.new()
	obs.bounds = Rect2(-20, -20, 40, 40)
	arena.set_meta("obstacles", obs)
	add_child_autofree(arena)
	var a := Ambient.new()
	a.arena = arena
	a._vents({"count": 4, "seed": 3})
	assert_eq(a.vents.size(), 4)
	for i in a.vents.size():
		for j in range(i + 1, a.vents.size()):
			assert_gt(a.vents[i].distance_to(a.vents[j]), 7.0, "separadas")
	var b := Ambient.new()
	b.arena = arena
	b._vents({"count": 4, "seed": 3})
	assert_eq(b.vents, a.vents, "las mismas en cada partida")
	a.free(); b.free()

## La fuente de Innsmouth (hito 17.15): el pilón lleva una lámina de agua con ondas desde donde
## cae el chorro, a la altura del agua del modelo.
func test_fuente_con_ondas() -> void:
	var c := Ambient.model_cfg("inn_fuente")
	assert_true(c.has("pool"))
	var mi := Ambient._pool(c.pool)
	assert_almost_eq(mi.position.y, 0.535, 0.01)
	var m := mi.material_override as ShaderMaterial
	assert_almost_eq(float(m.get_shader_parameter("radius")), 3.22, 0.01)
	assert_ne(m.get_shader_parameter("center"), Vector2.ZERO, "las ondas salen del chorro, no del centro")
	mi.free()

## Siluetas en las ventanas (hito 17.16): la capa de las ventanas lleva su ancho en UV.y y en UV2
## dónde cae cada vértice dentro de la ventana, de 0 a su ancho.
func test_ventanas_con_ancho_y_sitio() -> void:
	var m := VoxelBuilder.load_model("res://models/prt_casa.json")
	add_child_autofree(m)
	var found := false
	for mi: MeshInstance3D in m.get_meta("meshes"):
		if int(mi.get_meta("kind", 0)) != VoxelBuilder.KIND_WINDOW: continue
		var arr := mi.mesh.surface_get_arrays(0)
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
		assert_eq(uv2.size(), uv.size(), "UV2 en todos los vértices")
		for i in range(0, uv.size(), 7):
			assert_gt(uv[i].y, 0.0, "ancho de la ventana")
			assert_between(uv2[i].x, 0.0, uv[i].y + 0.01)
			assert_gte(uv2[i].y, 0.0)
		found = true
	assert_true(found, "la casa tiene ventanas que se encienden")

## Decorado que reacciona (hito 17.17): una explosión al lado tambalea un barril sobre su base y
## vuelve a quedarse quieto; los juncos se apartan de los jugadores.
func test_decorado_que_reacciona() -> void:
	assert_gt(float(Ambient.model_cfg("inn_juncos").get("part", 0.0)), 0.0, "los juncos se apartan")
	assert_true(Ambient.model_cfg("inn_barril").has("wobble"))
	var a := Ambient.new()
	var h := Node3D.new()
	add_child_autofree(h)
	h.rotation.y = 0.7
	var base := h.basis
	a._wobbles.append({"h": h, "base": base, "d": Vector2.ZERO, "v": Vector2.ZERO, "max": deg_to_rad(8.0)})
	var keep := Gusts.current.duplicate()
	Gusts.current = [Vector4(1.0, 0.0, 0.3, 4.0), Vector4(0, 0, 0, 1)]   # una explosión a 1 m
	var most := 0.0
	for i in 20:
		a._wobble_step(1.0 / 60.0)
		most = maxf(most, (a._wobbles[0].d as Vector2).length())
	assert_gt(most, deg_to_rad(2.0), "se tambalea")
	assert_lt((a._wobbles[0].d as Vector2).x, 0.0, "hacia el lado contrario a la explosión")
	Gusts.current = [Vector4(0, 0, 0, 1), Vector4(0, 0, 0, 1)]
	for i in 240: a._wobble_step(1.0 / 60.0)
	assert_lt((a._wobbles[0].d as Vector2).length(), 0.002, "y se queda quieto")
	assert_almost_eq(h.position, Vector3.ZERO, Vector3.ONE * 0.001, "sobre su base")
	Gusts.current = keep
	a.free()

## Sucesos lejanos (hito 17.18): uno en cada arena; lo que sube del agua sube, se queda y se hunde;
## la silueta solo se ve con el relámpago; las esculturas se giran cuando no se las mira.
func test_sucesos_lejanos() -> void:
	var arenas: Dictionary = Ambient.config().arenas
	for ar in ["campamento", "lake", "paso", "ciudad", "tuneles", "carretera", "calles", "tejados", "pantano", "arrecife", "ritual", "muelle", "tormenta", "rlyeh"]:
		assert_true((arenas[ar] as Dictionary).has("distant"), "suceso lejano en " + ar)
	assert_true(Ambient.model_cfg("prv_escultura_1").get("turn", false), "las esculturas del estudio se giran")
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 15.0
	cam.rotation_degrees = Vector3(-30, 45, 0)
	cam.position = cam.basis.z * 30.0
	add_child_autofree(cam)
	cam.make_current()
	var fake := Node3D.new()
	add_child_autofree(fake)
	var statue := Node3D.new()
	statue.position = Vector3(40, 0, 40)             # fuera de la pantalla
	add_child_autofree(statue)
	var de := DistantEvents.new().setup([
		{"kind": "rise", "model": "lejano_tentaculo", "spots": [[0, 0]], "y": 0.0, "depth": 8, "dur": 4, "every": [100, 100]},
		{"kind": "flash", "model": "lejano_tentaculo", "spots": [[0, 0]], "chance": 1.0}], cam, fake, [statue])
	add_child_autofree(de)
	var rise: Dictionary = de._ev[0]
	assert_true(de._try_start(rise), "se ve: empieza")
	var h: Node3D = rise.node
	var low := h.position.y
	for i in 120: de._process(1.0 / 60.0)            # a los 2 s, arriba
	assert_gt(h.position.y, low + 7.0, "ha subido")
	for i in 150: de._process(1.0 / 60.0)
	assert_false(h.visible, "y se ha hundido")
	assert_gt(float(rise.wait), 50.0, "hasta el siguiente")
	var fl: Dictionary = de._ev[1]
	assert_true(de._try_start(fl))
	assert_false((fl.node as Node3D).visible, "sin relámpago no se ve")
	de._flash_step(fl, 0.8)
	assert_true((fl.node as Node3D).visible, "con el relámpago, sí")
	# la escultura, sin jugadores cerca, no se gira; con uno a 5 m y sin mirarla, se gira hacia él
	var p := Node3D.new()
	p.position = Vector3(40, 0, 45)
	add_child_autofree(p)
	fake.set_meta("x", 0)
	var g := GameStub.new()
	g.players = [p]
	add_child_autofree(g)
	de.game = g
	de._turn_step()
	assert_almost_eq(statue.rotation.y, 0.0, 0.01, "mira hacia +Z, donde está él")
	p.position = Vector3(45, 0, 40)
	de._turn_step()
	assert_almost_eq(statue.rotation.y, 0.0, 0.01, "no se vuelve a girar hasta que se la vea")
	de._turners[0].seen = true
	de._turn_step()
	assert_almost_eq(statue.rotation.y, PI / 2.0, 0.01, "y ahora mira a +X")

class GameStub extends Node:
	var players: Array = []
	var weather = null

## Fogonazo de los disparos (hito 17.19): las balas encienden un instante la luz del jugador y se
## apaga sola; las armas que no son de balas, no; en Baja y Media no hay luz.
func test_fogonazo_de_los_disparos() -> void:
	var p: Array = Quality.presets()
	assert_false(bool(p[1].shot_light), "en Media no")
	assert_true(bool(p[2].shot_light), "en Alta sí")
	var holder := Node3D.new()
	add_child_autofree(holder)
	var ws := WeaponSystem.new()
	holder.add_child(ws)
	var l := MuzzleLight.attach(holder, ws, true)
	assert_not_null(l)
	var w := WeaponSystem.Weapon.new(load("res://data/weapons/webly.tres"))
	ws.fired.emit(w)
	l._process(1.0 / 60.0)
	assert_true(l.visible)
	assert_gt(l.light_energy, 1.0, "se enciende")
	for i in 20: l._process(1.0 / 60.0)
	assert_false(l.visible, "y se apaga sola en un tercio de segundo")
	var t := WeaponSystem.Weapon.new(load("res://data/weapons/bengalas.tres"))
	ws.fired.emit(t)
	assert_false(l.visible, "lo que se lanza no da fogonazo")
