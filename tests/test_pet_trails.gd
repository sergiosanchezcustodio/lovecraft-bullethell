extends GutTest
## Rastro de los compañeros (hito 12.10): estelas de partículas y huellas en la nieve y el barro.

## Un compañero de mentira con lo que mira Ambient (data, hidden, facing), sin jugador.
func _fake(id: String, pos := Vector3.ZERO) -> Node3D:
	var sc := GDScript.new()
	sc.source_code = "extends Node3D\nvar data\nvar hidden := false\nvar facing := Vector3.FORWARD\n"
	sc.reload()
	var n: Node3D = sc.new()
	n.set("data", load("res://data/pets/%s.tres" % id))
	add_child_autofree(n)
	n.global_position = pos
	return n

func _count(a: Ambient) -> int:
	var fp: Footprints = a.get_meta("footprints") if a.has_meta("footprints") else null
	return fp.count() if fp != null else 0

func _walk(a: Ambient, pet: Node3D, metres: float, kind := "snow") -> void:
	var steps := int(metres / 0.05)
	for i in steps + 1:
		pet.global_position = Vector3(0, 0, i * 0.05)
		a._pet_print(pet, null, kind)

func test_cada_estela_tiene_su_receta() -> void:
	for id in ["buho", "byakhee", "cuervo", "gaviota", "migo", "polilla", "tindalos"]:
		var d: PetData = load("res://data/pets/%s.tres" % id)
		assert_ne(d.trail, "", id)
		var p := VoxelFx.emitter("pet_" + d.trail, 0.18, false, false, d.trail_color)
		assert_not_null(p, d.trail)
		if p != null: p.free()
	for id in ["buho", "byakhee", "cuervo", "gaviota"]:
		assert_eq((load("res://data/pets/%s.tres" % id) as PetData).trail, "feathers", id + ": plumas")

func test_en_baja_sin_estelas() -> void:
	assert_false(bool(Quality.presets()[0].pet_trails), "Baja")
	assert_true(bool(Quality.presets()[Quality.DEFAULT].pet_trails), "Alta")

func test_el_perro_deja_patas_a_pares_en_la_nieve() -> void:
	var a := Ambient.new()
	var dog := _fake("perro")
	_walk(a, dog, 2.0)
	var n := _count(a)
	assert_gt(n, 4, "deja huellas al andar")
	assert_eq(n % 2, 0, "de dos en dos: delante y detrás")
	a.free()

func test_los_que_reptan_dejan_un_rastro() -> void:
	var a := Ambient.new()
	var yig := _fake("yig")
	_walk(a, yig, 2.0)
	var n := _count(a)
	assert_gt(n, 1, "rastro")
	var dog_a := Ambient.new()
	_walk(dog_a, _fake("perro"), 2.0)
	assert_lt(n, _count(dog_a), "una mancha por zancada, no patas a pares")
	a.free()
	dog_a.free()

func test_los_voladores_y_los_de_bajo_tierra_no() -> void:
	var a := Ambient.new()
	_walk(a, _fake("cuervo"), 2.0)
	assert_eq(_count(a), 0, "el cuervo vuela")
	var dhole := _fake("dhole")
	dhole.hidden = true
	_walk(a, dhole, 2.0)
	assert_eq(_count(a), 0, "el dhole, bajo tierra")
	a.free()

func test_en_la_piedra_seca_nada() -> void:
	var a := Ambient.new()
	_walk(a, _fake("perro"), 2.0, "stone")
	assert_eq(_count(a), 0)
	a.free()
