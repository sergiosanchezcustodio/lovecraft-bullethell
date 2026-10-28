extends GutTest
## Reacciones al golpe por familia y gestos de reposo (28-10-2026).

func test_familias_con_reaccion_propia() -> void:
	for m in ["pinguino", "fragmento", "shoggoth", "profundo", "cultista", "dyer"]:
		assert_true(Anims.has_hit(m), m)
		assert_gt(Anims.hit_time(m, 0.22), 0.3, m)
	assert_false(Anims.has_hit("antiguo"))            # sin la suya: se aplasta entero
	assert_eq(Anims.hit_time("antiguo", 0.22), 0.22)

func test_la_reaccion_vuelve_a_la_pose() -> void:
	for name in ["pinguino", "fragmento", "profundo", "cultista"]:
		var m := VoxelBuilder.load_model("res://models/%s.json" % name)
		add_child_autofree(m)
		Anims.pose(name, "idle", m, 0.0)
		var rest := Anims.snapshot(m)
		Anims.pose(name, "idle", m, 0.0)
		Anims.hit(name, m, 0.15)
		assert_ne(Anims.snapshot(m), rest, name + ": a mitad del golpe cambia")
		Anims.pose(name, "idle", m, 0.0)
		Anims.hit(name, m, 1.0)
		var end := Anims.snapshot(m)
		for i in rest.size():
			assert_almost_eq(_flat(end[i]), _flat(rest[i]), 0.02, name + ": al final, en reposo")

func test_gestos_de_reposo_empiezan_y_acaban_en_reposo() -> void:
	var s: Script = Anims.script_for("dyer")
	var fidgets: Array = s.get("FIDGETS")
	assert_eq(fidgets.size(), 4)
	var m := VoxelBuilder.load_model("res://models/dyer.json")
	add_child_autofree(m)
	for f: String in fidgets:
		assert_true(Anims.has_anim("dyer", f), f)
		for t in [0.0, 1.0]:
			Anims.pose("dyer", f, m, t)
			assert_lt(_pose_gap(m), 0.06, "%s en t=%.0f" % [f, t])

## Lo que se aparta del reposo (idle en t=0) la pose actual: el mayor giro de una parte.
func _pose_gap(m: Node3D) -> float:
	var now := Anims.snapshot(m)
	Anims.pose("dyer", "idle", m, 0.0)
	var rest := Anims.snapshot(m)
	var gap := 0.0
	for i in now.size(): gap = maxf(gap, absf(_flat(now[i]) - _flat(rest[i])))
	return gap

## Una entrada de Anims.snapshot reducida a un número (suma de giros, posición y escala).
func _flat(e: Variant) -> float:
	var out := 0.0
	if e is Array:
		for x in e: out += _flat(x)
	elif e is Vector3: out += e.x + e.y + e.z
	elif e is Transform3D: out += _flat(e.origin) + _flat(e.basis.get_euler())
	elif e is float or e is int: out += float(e)
	return out
