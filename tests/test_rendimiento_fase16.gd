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

# --- 16.3: hordas con instancias ---

func test_la_horda_graba_las_poses_de_su_familia() -> void:
	var h := HordeMesh.get_type("pinguino")
	if h == null:
		pending("sin servidor de dibujo no se pueden leer las mallas")
		return
	assert_true(h.has_anim("walk") and h.has_anim("charge"), "sus animaciones")
	assert_true(h.has_anim("_hit"), "y el golpe de su familia")
	var a := h.row("walk", 0.0)
	assert_eq(h.row("walk", 0.999), a + int(h.anim_rows["walk"][1]) - 1, "una fila por fotograma")
	assert_ne(h.row("charge", 0.0), a, "cada animación en sus filas")
	assert_same(h, HordeMesh.get_type("pinguino"), "se graba una vez")

func _horde_enemy() -> Array:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var obstacles := ObstacleMap.new()
	obstacles.bounds = Rect2(-32, -32, 64, 64)
	var e := Enemy.new().setup(load("res://data/enemies/pinguino.tres"), world, obstacles)
	world.add_child(e)
	e._rise_wait = 0.0
	e._spawn_t = 1.0
	return [world, e]

func test_un_enemigo_corriente_va_con_la_horda_y_vuelve_a_su_modelo_al_morir() -> void:
	if HordeMesh.get_type("pinguino") == null:
		pending("sin servidor de dibujo")
		return
	HordeDraw.enabled = true
	var we := _horde_enemy()
	var e: Enemy = we[1]
	assert_true(e._horde_ok)
	e._process(1.0 / 60.0)
	assert_true(e._in_horde, "con la horda")
	assert_null(e.model.get_parent(), "su modelo, fuera del árbol")
	var m := e.model
	e.take_damage(Damage.new(1e5, 0.0))
	assert_not_null(m.get_parent(), "al morir vuelve a su modelo (que cae y se deshace)")

func test_si_se_borra_sin_morir_su_modelo_no_se_queda_suelto() -> void:
	if HordeMesh.get_type("pinguino") == null:
		pending("sin servidor de dibujo")
		return
	HordeDraw.enabled = true
	var we := _horde_enemy()
	var e: Enemy = we[1]
	e._process(1.0 / 60.0)
	var ref := weakref(e.model)
	e.free()
	assert_null(ref.get_ref(), "borrado con él")

func test_jefes_elites_y_grandes_siguen_con_nodos() -> void:
	HordeDraw.enabled = true
	var we := _horde_enemy()
	var e: Enemy = we[1]
	e.data = e.data.duplicate()
	e.data.elite = true
	assert_false(HordeDraw.eligible(e), "élite")
	e.data.elite = false
	e.model_scale = 2.0
	assert_false(HordeDraw.eligible(e), "grande")
	HordeDraw.enabled = false
	e.model_scale = 1.0
	assert_false(HordeDraw.eligible(e), "horde=false")
	HordeDraw.enabled = true

## Las piezas de lo que se lanza (granada, dinamita…) comparten malla y material: con unos nuevos
## en cada lanzamiento, Godot compilaba un shader cada vez (16.1, 03-11-2026).
func test_lo_lanzado_comparte_mallas() -> void:
	var a := ThrownExplosive.new()
	var b := ThrownExplosive.new()
	a.look = "granada"
	b.look = "granada"
	add_child_autofree(a)
	add_child_autofree(b)
	var ma := (a.get_child(0).get_child(0) as MeshInstance3D)
	var mb := (b.get_child(0).get_child(0) as MeshInstance3D)
	assert_same(ma.mesh, mb.mesh)
	assert_same(ma.material_override, mb.material_override)
