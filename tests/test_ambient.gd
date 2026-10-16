extends GutTest
## Ambiente de los escenarios (16-10-2026): que los datos apunten a cosas que existen, que cada
## ventana tenga su número y que la luz real siga la misma cuenta que el brillo de su capa.

func test_las_piezas_y_las_arenas_del_ambiente_existen() -> void:
	var cfg := Ambient.config()
	assert_false(cfg.is_empty(), "data/ambient.json")
	for m: String in cfg.get("models", {}):
		assert_true(VoxelBuilder.model_exists("res://models/%s.json" % m), "pieza " + m)
		var c: Dictionary = cfg.models[m]
		if c.has("glow"): assert_true(Ambient.MODES.has(String(c.glow)), "modo de brillo de " + m)
		if c.has("swing"):                                          # la parte que cuelga existe en el modelo
			var piv: Dictionary = JSON.parse_string(VoxelBuilder.read_text("res://models/%s.json" % m)).get("pivots", {})
			assert_true(piv.has(String(c.swing.part)), "parte que se mece de " + m)
	for a: String in cfg.get("arenas", {}):
		assert_true(FileAccess.file_exists("res://data/arenas/%s.json" % a), "arena " + a)
		for m: String in cfg.arenas[a].get("spills", {}).get("models", []):   # nieve que cae: la pieza tiene sus bordes
			var piv: Dictionary = JSON.parse_string(VoxelBuilder.read_text("res://models/%s.json" % m)).get("pivots", {})
			assert_true(piv.keys().any(func(k: String) -> bool: return k.begins_with("spill")), "bordes con nieve de " + m)
		if cfg.arenas[a].has("spray"):
			assert_true(VoxelBuilder.model_exists("res://models/%s.json" % cfg.arenas[a].spray.model), "borda de " + a)
		var birds: Dictionary = cfg.arenas[a].get("birds", {})
		for k: String in birds.get("kinds", []):
			assert_true(VoxelBuilder.model_exists("res://models/amb_%s.json" % k), "ave " + k)
			assert_true(Ambient.BIRD_SPEED.has(k), "velocidad de " + k)

func test_cada_ventana_tiene_su_numero() -> void:
	# dos ventanas de 3x3 separadas por 4 voxels, la segunda con un parteluz de 1 voxel en medio
	var vox := []
	for x in 3:
		for y in 3: vox.append([Vector3i(x, y, 0), Color.WHITE])
	for x in [7, 9]:
		for y in 3: vox.append([Vector3i(x, y, 0), Color.WHITE])
	var comp := VoxelBuilder._components(vox)
	assert_eq(comp[Vector3i(0, 0, 0)], comp[Vector3i(2, 2, 0)], "la misma ventana")
	assert_eq(comp[Vector3i(7, 0, 0)], comp[Vector3i(9, 2, 0)], "el parteluz no la parte en dos")
	assert_ne(comp[Vector3i(0, 0, 0)], comp[Vector3i(7, 0, 0)], "otra ventana, otro número")

func test_la_llama_tiembla_y_la_bombilla_falla_a_ratos() -> void:
	var lo := INF
	var hi := -INF
	for i in 400:
		var k := Ambient.anim_k(2, 0.3, 1.0, i * 0.05, 7.0)
		lo = minf(lo, k); hi = maxf(hi, k)
	assert_lt(lo, 0.85, "la llama baja")
	assert_gt(hi, 1.15, "y sube")
	var off := 0
	for i in 2000:
		if Ambient.anim_k(3, 0.3, 1.0, i * 0.05, 3.0) < 0.5: off += 1
	assert_gt(off, 0, "la bombilla se apaga alguna vez")
	assert_lt(off, 200, "pero casi siempre luce")
