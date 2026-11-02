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

# --- 16.6: carga durante el relato ---

func test_el_suelo_son_pocas_losas_con_los_mismos_bordes() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/pantano.json"))
	var size := Vector2(data.size[0], data.size[1])
	var g := ArenaBuilder._ground(data, size)
	var n := (g.mesh as ArrayMesh).surface_get_array_len(0)
	assert_lt(n, 20000, "losas grandes, no una por cada 0,5 m (%d vértices)" % n)
	var ab := g.mesh.get_aabb()
	assert_lt(ab.position.x, -size.x * 0.5, "llega al borde oeste y lo pasa")
	assert_gt(ab.end.z, size.y * 0.5 - 0.01, "y al sur")
	g.free()

func test_la_arena_se_monta_en_un_hilo_y_la_partida_se_la_lleva() -> void:
	LevelPreload.enabled = true
	LevelPreload.begin("p2_n4")
	var path := LevelPreload.arena_of("p2_n4")
	assert_eq(path, (load("res://data/levels/p2_n4.tres") as LevelData).arena)
	var a := LevelPreload.take(path, LevelPreload.fog_volumes())
	assert_not_null(a, "montada")
	assert_true(LevelPreload.last_hit)
	assert_true(a.has_meta("obstacles") and a.get_node_or_null("Props") != null, "entera")
	a.free()
	LevelPreload.game_scene()
	LevelPreload.release()
	assert_false(LevelPreload.pending())

func test_si_la_partida_pide_otra_arena_se_tira() -> void:
	LevelPreload.begin("p1_n2")
	assert_null(LevelPreload.take("res://data/arenas/pantano.json", LevelPreload.fog_volumes()), "otra arena: la monta la partida")
	assert_false(LevelPreload.last_hit)
	assert_false(LevelPreload.pending(), "y la montada no se queda colgando")
	LevelPreload.game_scene()
	LevelPreload.release()

func test_fuera_del_hilo_principal_la_configuracion_sale_de_la_copia() -> void:
	Auto.snapshot()
	var main_q: Variant = Auto.setting("quality", -1)
	var got := {}
	var id := WorkerThreadPool.add_task(func() -> void:
		got["off"] = Auto.off_main()
		got["q"] = Auto.setting("quality", -1)
		got["node"] = Auto.node("Settings"))
	WorkerThreadPool.wait_for_task_completion(id)
	assert_false(Auto.off_main())
	assert_true(got.off, "en el hilo se sabe")
	assert_eq(got.q, main_q, "la misma calidad que en el hilo principal")
	assert_null(got.node, "y no busca en el árbol")
