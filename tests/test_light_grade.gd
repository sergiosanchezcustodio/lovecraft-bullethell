extends GutTest
## Hito 11.3: gradación de color por parte (Atmosphere.set_grade, data/grades.json), tope de
## explosiones con luz y fogonazo de luz del jugador.

func _curve(env: Environment, x: float) -> Color:
	var g := (env.adjustment_color_correction as GradientTexture1D).gradient
	return g.sample(x)

func test_cada_parte_tiene_su_gradacion() -> void:
	for k in ["p1", "p2", "p3"]:
		var gr := Atmosphere.grade_for(k)
		assert_false(gr.is_empty(), k)
		assert_eq((gr.get("shadows", []) as Array).size(), 3, k)

func test_la_gradacion_tine_sin_tocar_negro_ni_blanco() -> void:
	var env := Environment.new()
	Atmosphere.set_grade(env, 1.0, Atmosphere.grade_for("p2"))
	assert_true(env.adjustment_enabled)
	var mid := _curve(env, 0.3)
	assert_gt(mid.g, mid.r, "Innsmouth: sombras verdosas")
	assert_almost_eq(_curve(env, 0.0).r, 0.0, 0.001, "el negro sigue negro")
	assert_almost_eq(_curve(env, 1.0).b, 1.0, 0.001, "el blanco sigue blanco")
	Atmosphere.set_grade(env, 1.0, {})
	assert_false(env.adjustment_enabled, "sin gradación ni gamma, nada")

func test_tope_de_explosiones_con_luz() -> void:
	var start := Explosion.lit
	var made: Array[Explosion] = []
	for i in Explosion.MAX_LIT + 3:
		var e := Explosion.new()
		add_child_autofree(e)
		made.append(e)
	assert_eq(Explosion.lit, Explosion.MAX_LIT, "las que sobran, sin luz")
	for e in made: e._process(0.35)
	assert_eq(Explosion.lit, start, "apagada la luz, se quita")

func test_fogonazo_del_jugador() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	p.muzzle_flash(Vector3.RIGHT)
	p.muzzle_flash(Vector3.RIGHT)
	assert_eq(p.find_children("MuzzleLight", "OmniLight3D", false, false).size(), 1, "una sola luz, reutilizada")

# ---- hito 11.4: ondas en el agua y ráfagas ----

func test_ondas_con_tope_y_que_se_van() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	for i in Ripples.MAX + 5:
		Ripples.add(fx, Vector3(i, 0, 0), 1.0)
	var r: Ripples = fx.get_meta("ripples")
	assert_eq(r.count(), Ripples.MAX, "como mucho MAX")
	r._process(Ripples.LIFE + 0.01)
	assert_eq(r.count(), 0, "se van al acabar")

func test_rafagas_en_dos_huecos() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	Gusts.push(fx, Vector3(1, 0, 2), 0.2, 3.0)
	Gusts.push(fx, Vector3(5, 0, 5), 0.1, 3.0)
	var g: Gusts = fx.get_meta("gusts")
	assert_eq(g._g[0], Vector4(1, 2, 0.2, 3.0))
	Gusts.push(fx, Vector3(9, 0, 9), 0.3, 3.0)
	assert_eq(g._g[1].x, 9.0, "la nueva ocupa el hueco de la más débil")
	g._process(3.0)
	assert_lt(g._g[0].z, 0.01, "y se apagan")

# ---- hito 11.5: calidad gráfica ----

func test_cuatro_preajustes_completos() -> void:
	var p := Quality.presets()
	assert_eq(p.size(), 4)
	for q: Dictionary in p:
		for k in ["name", "msaa", "fxaa", "ssao", "shadow", "shadow_soft", "shadow_dist", "fogvol", "crumble", "marks", "lights"]:
			assert_true(q.has(k), "%s: %s" % [q.get("name"), k])

func test_alta_es_como_antes() -> void:
	var alta: Dictionary = Quality.presets()[Quality.DEFAULT]
	assert_eq(int(alta.msaa), int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")), "el mismo suavizado")
	assert_eq(int(alta.shadow), int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size")), "las mismas sombras")
	assert_eq(int(alta.shadow_soft), int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality")))
	assert_false(bool(alta.ssao))
	assert_eq(int(alta.marks), 24)
	assert_eq(int(alta.lights), Explosion.MAX_LIT)
