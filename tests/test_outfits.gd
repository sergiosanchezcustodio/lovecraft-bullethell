extends GutTest
## Vestuario (D-34, hito 2.16).

func test_cada_prenda_tiene_modelo_para_cada_personaje() -> void:
	for o in OutfitData.all():
		for c in DebugOptions.list_resources("res://data/characters"):
			assert_true(FileAccess.file_exists(o.model_path((c as CharacterData).model)),
				"falta %s" % o.model_path((c as CharacterData).model))

func test_comprar_y_llevar() -> void:
	var s := SaveData.create()
	s.money = 100000
	var e: Shop.Entry = Shop.in_section(ShopItem.Section.OUTFIT)[0]
	s.worn["dyer"] = {"head": e.id}
	assert_eq(s.worn_by("dyer"), {}, "lo que no se ha comprado no se lleva")
	assert_true(Shop.buy(s, e))
	assert_true(s.has_outfit(e.id))
	assert_eq(s.worn_by("dyer"), {"head": e.id})
	var back := SaveData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(back.worn_by("dyer"), {"head": e.id}, "se guarda")

func test_vestir_oculta_el_sombrero() -> void:
	var m := VoxelBuilder.load_model("res://models/dyer.json")
	var hat: Node3D = m.get_meta("part_nodes")["hat"]
	var n := (m.get_meta("meshes") as Array).size()
	OutfitData.apply(m, "dyer", {"head": "bombin", "feet": "botas_nieve"})
	assert_false(hat.visible)
	assert_gt((m.get_meta("meshes") as Array).size(), n, "las mallas de las prendas cuelgan del modelo")
	m.free()
