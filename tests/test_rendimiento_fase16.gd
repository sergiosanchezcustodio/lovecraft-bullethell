extends GutTest
## Fase 16, bloque A (rendimiento): calentamiento del nivel, reserva de modelos, destello
## compartido y lanzador de patrones parado mientras no dispara.

func after_each() -> void:
	ModelPool.clear()

func test_el_calentamiento_lista_cada_modelo_una_vez() -> void:
	var lv: LevelData = load("res://data/levels/p1_n2.tres")
	var list := LevelWarmup.enemies_of(lv)
	assert_gt(list.size(), 0, "el nivel tiene enemigos")
	var seen := {}
	for d in list:
		assert_false(seen.has(d.model), "sin repetir modelo: %s" % d.model)
		seen[d.model] = true
	for d in lv.pool:
		assert_true(seen.has(d.model), "están los de las oleadas: %s" % d.model)
	if lv.final_enemy != null: assert_true(seen.has(lv.final_enemy.model), "y el del evento final")

func test_la_reserva_sirve_modelos_hechos_y_se_repone() -> void:
	var path := "res://models/pinguino.json"
	ModelPool.stock(path, 2)
	ModelPool.fill_now()
	assert_eq(ModelPool.spare_count(), 2)
	var hits := ModelPool.hits
	var m := ModelPool.take(path)
	assert_not_null(m)
	assert_true(m.has_meta("meshes"), "un modelo completo")
	assert_eq(ModelPool.hits, hits + 1, "salió de la reserva")
	assert_eq(ModelPool.spare_count(), 1)
	ModelPool.refill()
	assert_eq(ModelPool.spare_count(), 2, "se repone (uno por fotograma)")
	m.free()

func test_sin_reserva_se_monta_al_momento() -> void:
	var misses := ModelPool.misses
	var m := ModelPool.take("res://models/fragmento.json")
	assert_not_null(m)
	assert_eq(ModelPool.misses, misses + 1)
	m.free()

func test_al_salir_se_borran_los_de_reserva() -> void:
	ModelPool.stock("res://models/pinguino.json", 1)
	ModelPool.fill_now()
	ModelPool.clear()
	assert_eq(ModelPool.spare_count(), 0)

func test_el_destello_es_compartido() -> void:
	var a := Enemy._shared_flash(false)
	assert_same(a, Enemy._shared_flash(false), "el mismo material para todos")
	assert_ne(a, Enemy._shared_flash(true), "el de los jefes, otro")
	assert_eq(Enemy._shared_flash(true).blend_mode, BaseMaterial3D.BLEND_MODE_ADD, "que suma luz")

func test_el_lanzador_no_corre_hasta_que_dispara() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var r := PatternRunner.new().setup(world)
	world.add_child(r)
	assert_false(r.is_physics_processing(), "parado al entrar en la escena")
	r._begin()
	assert_true(r.is_physics_processing(), "corre mientras dispara")
