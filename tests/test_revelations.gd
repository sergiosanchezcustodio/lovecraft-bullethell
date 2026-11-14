extends GutTest
## Hito 21.7: revelaciones. Quien sale de una crisis de locura elige entre dos (data/revelations.json),
## que le duran lo que queda del nivel: estadísticas o un efecto (Revelations).

const DT := 1.0 / 60.0
const EFFECTS := ["", "eyes", "walls", "reveal", "aura"]
var world: CombatWorld

## Decorado de prueba: para las balas a partir de x = 2.
class _Wall extends ObstacleMap:
	func has_mask() -> bool: return true
	func stops_bullet(pos: Vector2) -> bool: return pos.x > 2.0

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)

func _player(id := "dyer") -> Player:
	var p := Player.new().setup(load("res://data/characters/%s.tres" % id), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	return p

func _dummy(at: Vector3) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/pinguino.tres") as EnemyData).duplicate()
	d.max_health = 1000.0
	d.move_speed = 0.0
	var e := Enemy.new().setup(d, world, null)
	e.position = at
	world.add_child(e)
	return e

func _node(authority := true) -> Revelations:
	var r := Revelations.new().setup(world, authority)
	add_child_autofree(r)
	return r

func _step(r: Revelations, secs: float) -> void:
	for i in int(secs / DT):
		world.rebuild_grid()
		r._physics_process(DT)

func test_las_revelaciones_estan_bien_hechas() -> void:
	var fields := CharacterData.new()
	var seen := {}
	assert_gt(Revelations.all().size(), Revelations.OPTIONS, "más de las que se ofrecen")
	for r: Dictionary in Revelations.all():
		var id := String(r.id)
		assert_false(seen.has(id), "%s repetida" % id)
		seen[id] = true
		assert_ne(String(r.get("nombre", "")), "", id)
		assert_ne(String(r.get("texto", "")), "", id)
		assert_eq((r.get("color", []) as Array).size(), 3, "%s: color" % id)
		var fx := String(r.get("efecto", ""))
		var st: Dictionary = r.get("stats", {})
		assert_true(fx in EFFECTS, "%s: efecto %s" % [id, fx])
		assert_true(fx != "" or not st.is_empty(), "%s hace algo" % id)
		for k: String in st:
			assert_true(k.ends_with("*") or k.ends_with("+"), "%s: %s" % [id, k])
			assert_true(k.trim_suffix("*").trim_suffix("+") in fields, "%s: %s no es de CharacterData" % [id, k])
		assert_not_null(Revelations.icon(id), "%s: icono (tools/render_revelaciones.gd)" % id)
		assert_true(FileAccess.file_exists("res://models/revelacion_%s.json" % id), "%s: modelo" % id)

func test_se_sortean_dos_que_no_lleva() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var all: Array = Revelations.all().map(func(r: Dictionary) -> String: return String(r.id))
	for i in 20:
		var got := Revelations.roll([all[0], all[1]], rng)
		assert_eq(got.size(), 2)
		assert_ne(got[0], got[1])
		assert_false(got.has(all[0]) or got.has(all[1]), "no repite las que lleva")
	assert_eq(Revelations.roll(all.slice(1), rng), [all[0]] as Array[String], "solo queda una")
	assert_true(Revelations.roll(all, rng).is_empty(), "las tiene todas")

func test_la_revelacion_no_gasta_la_subida() -> void:
	var p := _player()
	var pr := p.progress
	pr.pending = 1
	pr.revelations_pending = 1
	assert_true(pr.has_special(p.weapons))
	var opts := pr.next_options(p.weapons, RandomNumberGenerator.new())
	assert_eq(opts.size(), 2)
	for o in opts:
		assert_eq(o.kind, PlayerProgress.Option.Kind.REVELATION)
		assert_not_null(o.icon, "con su icono")
		assert_ne(o.title(), "")
		assert_eq(PlayerProgress.key_of(o), "r:" + String(o.revelation.id))
	pr.choose(opts[0], p)
	assert_eq(pr.revelations, [String(opts[0].revelation.id)] as Array[String])
	assert_eq(pr.revelations_pending, 0)
	assert_eq(pr.pending, 1, "la subida sigue ahí")
	assert_false(pr.has_special(p.weapons))
	for o in pr.next_options(p.weapons, RandomNumberGenerator.new()):
		assert_ne(o.kind, PlayerProgress.Option.Kind.REVELATION, "ya no quedan por elegir")

func test_option_for_valida_la_revelacion_que_llega_por_la_red() -> void:
	var p := _player()
	var pr := p.progress
	assert_null(pr.option_for("r:calma", p.weapons), "sin pendientes, no vale")
	pr.revelations_pending = 1
	var o := pr.option_for("r:calma", p.weapons)
	assert_not_null(o)
	assert_eq(o.kind, PlayerProgress.Option.Kind.REVELATION)
	assert_null(pr.option_for("r:no_existe", p.weapons))
	pr.choose(o, p)
	pr.revelations_pending = 1
	assert_null(pr.option_for("r:calma", p.weapons), "ya la lleva")

func test_las_estadisticas_se_aplican_y_se_quitan() -> void:
	var p := _player()
	var dmg := p.data.damage_mult
	var mental := p.data.mental_mult
	var dodge := p.data.dodge_cooldown
	var regen := p.data.sanity_regen
	p.progress.revelations.assign(["conocimiento", "entre_angulos", "lenguas_muertas", "calma"])
	p.rebuild_stats()
	assert_almost_eq(p.data.damage_mult, dmg * 1.3, 0.001)
	assert_almost_eq(p.data.mental_mult, mental * 1.3, 0.001)
	assert_almost_eq(p.data.dodge_cooldown, dodge * 0.65, 0.001)
	assert_eq(p.data.arcane_cost_mult, 0.0)
	assert_almost_eq(p.data.sanity_regen, regen + 0.5, 0.001)
	assert_almost_eq(p.sanity_state.duration_mult, p.data.crisis_mult, 0.001, "las crisis, más cortas")
	p.progress.revelations.clear()
	p.rebuild_stats()
	assert_almost_eq(p.data.damage_mult, dmg, 0.001)
	assert_almost_eq(p.data.dodge_cooldown, dodge, 0.001)

func test_no_pasan_de_nivel_pero_viajan_por_la_red() -> void:
	var p := _player()
	p.progress.revelations.assign(["mirada"])
	assert_false(GameSession.snapshot(p).has("rev"), "la foto del nivel siguiente no las lleva")
	var d := NetGame.progress_of(p)
	assert_eq(d.rev, ["mirada"])
	var q := _player("legrasse")
	NetGame.apply_progress(q, d)
	assert_eq(q.progress.revelations, ["mirada"] as Array[String])

func test_nada_los_detiene_las_balas_atraviesan_el_decorado() -> void:
	world.obstacles = _Wall.new()
	world.bounds = Rect2(-50, -50, 100, 100)
	var p := _player()
	var r := _node()
	var shoot := func() -> void:
		world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.PLAYER, Vector3.ZERO, Vector3(10, 0, 0),
			0.1, 0.2, Damage.new(1.0, 0.0), 2.0, 0, 1.0, -1, 0, 0.0, BulletManager.Effect.NONE, 0.0, p.index)
	shoot.call()
	for i in 30: world.bullets._physics_process(DT)
	assert_eq(world.bullets.count, 0, "sin la revelación, el decorado la para")
	p.progress.revelations.assign(["sin_muros"])
	r._physics_process(DT)
	assert_eq(world.bullets.walls_free, 1)
	shoot.call()
	for i in 30: world.bullets._physics_process(DT)
	assert_eq(world.bullets.count, 1, "con ella, sigue")
	p.progress.revelations.clear()
	r._physics_process(DT)
	assert_eq(world.bullets.walls_free, 0)

func test_lo_oculto_revela_a_los_de_alrededor() -> void:
	var p := _player()
	p.progress.revelations.assign(["lo_oculto"])
	var near := _dummy(Vector3(3, 0, 0))
	var far := _dummy(Vector3(12, 0, 0))
	var r := _node()
	_step(r, 0.1)
	assert_gt(near._reveal_t, 0.0, "el de cerca, revelado")
	assert_almost_eq(near._reveal_k, 0.25, 0.001)
	assert_eq(far._reveal_t, 0.0, "el de lejos, no")

func test_la_mirada_que_hiere_y_su_fila_en_la_tabla() -> void:
	var p := _player()
	p.progress.revelations.assign(["mirada"])
	var near := _dummy(Vector3(2, 0, 0))
	var far := _dummy(Vector3(6, 0, 0))
	var r := _node()
	_step(r, 1.05)
	assert_almost_eq(near.data.max_health - near.health, 15.0, 0.5, "10 por segundo, a medios segundos (tres pasadas)")
	assert_eq(far.health, far.data.max_health)
	var st: Dictionary = world.stats_of(0).weapons
	assert_true(st.has("revelacion"), "a cuenta de las revelaciones")

func test_en_el_invitado_no_hieren_ni_revelan() -> void:
	var p := _player()
	p.progress.revelations.assign(["mirada", "lo_oculto"])
	var e := _dummy(Vector3(2, 0, 0))
	var r := _node(false)
	_step(r, 1.1)
	assert_eq(e.health, e.data.max_health, "los enemigos los lleva el anfitrión")
	assert_eq(e._reveal_t, 0.0)

func test_al_llegar_una_hace_su_gesto() -> void:
	var p := _player("gilman")
	var r := _node()
	r._physics_process(DT)
	p.progress.revelations.assign(["calma"])
	r._physics_process(DT)
	assert_eq(p._override, "revelation", "manos a las sienes y los brazos abiertos")
	assert_eq(r._seen[p.index], 1)
	var anim: GDScript = load("res://scripts/anim/anim_humano.gd")
	assert_true((anim.get("DURATION") as Dictionary).has("revelation"))
	assert_true((anim.get("HORDE_SKIP") as Array).has("revelation"), "las hordas no lo graban")

func test_ojos_en_la_oscuridad_dos_por_enemigo_cercano_y_el_farol() -> void:
	var cam := Camera3D.new()
	cam.rotation_degrees = Vector3(-30, 45, 0)
	add_child_autofree(cam)
	cam.make_current()
	var p := _player()
	var lamp := p.get_node_or_null("CarryLight") as OmniLight3D
	var before := lamp.omni_range if lamp != null else 0.0
	p.progress.revelations.assign(["ojos_muros"])
	p.rebuild_stats()
	if lamp != null: assert_almost_eq(lamp.omni_range, before * 2.0, 0.01, "el farol, el doble")
	_dummy(Vector3(4, 0, 0))
	_dummy(Vector3(0, 0, 6))
	_dummy(Vector3(30, 0, 0))
	var r := _node()
	world.rebuild_grid()
	r._process(DT)
	assert_not_null(r._eyes)
	assert_eq(r._eyes.multimesh.visible_instance_count, 4, "dos ojos por cada uno de los dos cercanos")
	p.progress.revelations.clear()
	r._process(DT)
	assert_false(r._eyes.visible, "sin la revelación, nada")
