extends GutTest
## Hitos 11.6 y 11.7: los enemigos aparecen (salen del suelo o del agua, bajan del cielo o se
## materializan) sin moverse ni hacer daño mientras tanto, y se estiran y aplastan con los saltos.

const DT := 1.0 / 60.0
var world: CombatWorld
var root: Node3D

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	root = Node3D.new()
	world.add_child(root)

func _enemy(id: String, pos := Vector3.ZERO) -> Enemy:
	var d: EnemyData = (load("res://data/enemies/%s.tres" % id) as EnemyData).duplicate()
	var e := Enemy.new().setup(d, world, null)
	e.position = pos
	root.add_child(e)
	return e

func test_cada_uno_aparece_a_su_manera() -> void:
	assert_eq(_enemy("pinguino")._rise, Enemy.Rise.GROUND)
	assert_eq(_enemy("pesadilla")._rise, Enemy.Rise.FOG, "las etéreas, en la niebla")
	assert_eq(_enemy("antiguo_alado")._rise, Enemy.Rise.AIR, "las que vuelan, del cielo")
	assert_eq(_enemy("dagon")._rise, Enemy.Rise.NONE, "los únicos tienen su entrada")

func test_quieto_mientras_aparece() -> void:
	var e := _enemy("pinguino")
	assert_true(e.rising())
	for i in int(Enemy.RISE_TIME / DT) - 2: e._physics_process(DT)
	assert_true(e.rising())
	assert_eq(e.velocity, Vector3.ZERO)
	for i in 4: e._physics_process(DT)
	assert_false(e.rising(), "acaba por la física, aunque no se dibuje")

func test_en_la_niebla_vuelve_a_su_material() -> void:
	var e := _enemy("pesadilla")
	var mi: MeshInstance3D = e.model.get_meta("meshes")[0]
	assert_true(mi.material_override is ShaderMaterial, "materializándose")
	e._process(Enemy.RISE_TIME + 0.01)
	assert_true(mi.material_override is StandardMaterial3D, "y después, el suyo")
	assert_eq(e._rise, Enemy.Rise.NONE)

func test_se_aplasta_al_aterrizar() -> void:
	var e := _enemy("fragmento")
	e._rise_end()
	for y in [1.2, 0.9, 0.5, 0.1, 0.0, 0.0]:            # cae deprisa y toca el suelo
		e.visual.global_position.y = y
		e.visual.scale = Vector3.ONE
		e._air_step(DT)
	assert_gt(e._land, 0.0, "nota el aterrizaje")
	e.visual.scale = Vector3.ONE
	e._land_t = Enemy.LAND_TIME * 0.25
	e._air_step(DT)
	assert_lt(e.visual.scale.y, 1.0, "aplastado")
	assert_gt(e.visual.scale.x, 1.0, "y ensanchado")

func test_los_blandos_mas() -> void:
	assert_true((load("res://data/enemies/fragmento.tres") as EnemyData).soft)
	assert_false((load("res://data/enemies/pinguino.tres") as EnemyData).soft)

# ---- hito 11.8: huellas ----

func test_huellas_con_tope_y_que_se_van() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	for i in Footprints.MAX + 10:
		Footprints.add(fx, Vector3(i * 0.1, 0, 0), 0.0, Vector2(0.1, 0.2), "snow")
	var fp: Footprints = fx.get_meta("footprints")
	assert_eq(fp.count(), Footprints.MAX, "como mucho MAX")
	fp._process(30.0)
	assert_eq(fp.count(), 0, "se borran")

func test_al_salir_del_agua_mojadas_y_se_secan() -> void:
	var a := Ambient.new()
	a.cfg = {"step": "stone"}
	assert_eq(a._print_kind("stone", 1), [], "en la piedra seca, nada")
	assert_eq(a._print_kind("water", 1), [], "en el agua, ninguna")
	var pk := a._print_kind("stone", 1)
	assert_eq(pk[0], "wet", "al salir, mojadas")
	a._print_clock += Ambient.WET_TIME * 0.5
	assert_almost_eq(float(a._print_kind("stone", 1)[1]), 0.5, 0.01, "cada vez más tenues")
	a._print_clock += Ambient.WET_TIME
	assert_eq(a._print_kind("stone", 1), [], "y secas")
	assert_eq(a._print_kind("mud", 2)[0], "mud")
	a.cfg = {"footprints": false}
	assert_eq(a._print_kind("snow", 3), [], "se pueden quitar por arena")
	a.free()

func test_en_baja_sin_huellas_de_enemigos() -> void:
	assert_false(bool(Quality.presets()[0].enemy_prints), "Baja")
	assert_true(bool(Quality.presets()[Quality.DEFAULT].enemy_prints), "Alta")
	var a := Ambient.new()
	a._enemy_prints_on = false
	a._walk_t = 0.0
	a._enemy_prints(0.1)
	assert_eq(a._walk_t, 0.0, "ni mira a los enemigos")
	a.free()

func test_cada_suelo_tiene_su_sonido_al_aparecer() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
	for g in ["snow", "mud", "stone", "wood"]:
		assert_true((d.eventos as Dictionary).has("rise_" + g), g)
	for k in ["rise_fog", "rise_air"]:
		assert_true((d.eventos as Dictionary).has(k), k)
	for st in (JSON.parse_string(FileAccess.get_file_as_string("res://data/ambient.json")).arenas as Dictionary).values():
		assert_true((d.eventos as Dictionary).has("rise_" + String(st.get("step", "snow"))), "suelo de alguna arena sin sonido")
