extends GutTest
## Hito 22.2: topes por fotograma a las muertes en masa (Crumble y DeathBurst).

func before_each() -> void:
	Crumble._frame = -1
	Crumble.budgeted = true
	DeathBurst._frame = -1
	DeathBurst.budgeted = true

func after_each() -> void:
	before_each()

func _models(fx: Node3D, n: int) -> Array:
	var out := []
	for i in n:
		var at := Node3D.new()
		at.position = Vector3(i, 0, 2)
		fx.add_child(at)
		var m := VoxelBuilder.load_model("res://models/pinguino.json")
		at.add_child(m)
		out.append(m)
	return out

func test_los_que_sobran_esperan_su_turno() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var ms := _models(fx, Crumble.PER_FRAME + 2)
	for m: Node3D in ms: assert_true(Crumble.start(fx, m, Color.ORANGE), "todos se deshacen")
	var waiting := ms.filter(func(m: Node3D) -> bool: return m.get_parent() == null)
	assert_eq(waiting.size(), 2, "los que pasan del tope esperan fuera de la escena")
	assert_eq(Crumble._pending.items.size(), 2)
	Crumble._frame = -1                              # otro fotograma
	Crumble._pending._process(0.016)
	for m: Node3D in waiting:
		assert_true(m.get_parent() != null and m.get_parent().get_parent() is Crumble, "y empiezan en el siguiente")
		var holder := m.get_parent() as Node3D
		assert_almost_eq(holder.global_position.z, 2.0, 0.01, "donde murieron")

func test_tarde_estalla_sin_quedarse() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var ms := _models(fx, Crumble.PER_FRAME + 1)
	for m: Node3D in ms: Crumble.start(fx, m, Color.ORANGE)
	var last: Node3D = ms[ms.size() - 1]
	Crumble._pending.items[0][6] = Time.get_ticks_msec() - 1000
	Crumble._frame = -1
	Crumble._pending._process(0.016)
	assert_true(last.is_queued_for_deletion(), "lleva demasiado esperando: se va")

func test_las_elites_no_esperan() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var ms := _models(fx, Crumble.PER_FRAME + 1)
	for i in ms.size(): Crumble.start(fx, ms[i], Color.ORANGE, i == ms.size() - 1)
	assert_true(ms[ms.size() - 1].get_parent().get_parent() is Crumble, "la élite, en el acto")

func test_sin_topes_para_comparar() -> void:
	Crumble.budgeted = false
	var fx := Node3D.new()
	add_child_autofree(fx)
	var ms := _models(fx, Crumble.PER_FRAME + 2)
	for m: Node3D in ms: Crumble.start(fx, m, Color.ORANGE)
	assert_eq(ms.filter(func(m: Node3D) -> bool: return m.get_parent() == null).size(), 0)
	Crumble.budgeted = true

func test_los_trozos_de_seis_en_seis() -> void:
	var fx := Node3D.new()
	add_child_autofree(fx)
	var bs := []
	for i in DeathBurst.PER_FRAME + 3:
		var b := DeathBurst.new()
		b.setup("pinguino", 0.4)
		fx.add_child(b)
		bs.append(b)
	assert_eq(bs.filter(func(b: DeathBurst) -> bool: return b._burst_done).size(), DeathBurst.PER_FRAME, "seis en este fotograma")
	DeathBurst._frame = -1
	for b: DeathBurst in bs: b._process(0.016)
	assert_eq(bs.filter(func(b: DeathBurst) -> bool: return b._burst_done).size(), bs.size(), "el resto, en el siguiente")
