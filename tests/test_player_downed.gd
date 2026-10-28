extends GutTest
## Abatido y en pie (hito 12.1): la caída acaba donde empieza la espera, la espera es donde
## empieza a levantarse y al levantarse acaba de pie, sin saltos entre una y otra.

var m: Node3D

func before_all() -> void:
	m = VoxelBuilder.load_model("res://models/dyer.json")
	add_child(m)

func after_all() -> void:
	m.free()

## Posición de cada parte (en el espacio de su padre: cuenta también el giro de la raíz).
func _points() -> Array:
	var out := []
	for n: Node3D in m.get_meta("parts"):
		out.append(n.global_transform.origin)
	return out

func _max_gap(a: Array, b: Array) -> float:
	var g := 0.0
	for i in a.size(): g = maxf(g, (a[i] as Vector3).distance_to(b[i]))
	return g

func test_se_encadenan_sin_saltos() -> void:
	Anims.reset(m)
	var standing := _points()
	Anims.pose("dyer", "down", m, 1.0)
	var fallen := _points()
	Anims.reset(m)
	Anims.script_for("dyer").call("down_wait", m, 0.0, 0.0, 0.0)
	var waiting := _points()
	assert_lt(_max_gap(fallen, waiting), 0.03, "la caída acaba en la espera")
	Anims.pose("dyer", "get_up", m, 0.0)
	assert_lt(_max_gap(waiting, _points()), 0.03, "se levanta desde la espera")
	Anims.pose("dyer", "get_up", m, 1.0)
	assert_lt(_max_gap(standing, _points()), 0.03, "y acaba de pie")
	assert_gt(_max_gap(standing, waiting), 0.5, "tendido, lejos de la pose de pie")

func test_caida_continua() -> void:
	var prev := []
	var worst := 0.0
	for i in 61:
		Anims.pose("dyer", "down", m, i / 60.0)
		var p := _points()
		if not prev.is_empty(): worst = maxf(worst, _max_gap(prev, p))
		prev = p
	assert_lt(worst, 0.12, "ninguna parte salta entre fotogramas")
